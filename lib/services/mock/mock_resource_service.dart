import '../../core/clock.dart';
import '../../core/errors.dart';
import '../../core/ids.dart';
import '../../core/permissions.dart';
import '../../core/rules.dart';
import '../../models/models.dart';
import '../resource_service.dart';
import 'mock_context.dart';

class MockResourceService implements ResourceService {
  MockResourceService(this._ctx);

  final MockContext _ctx;

  String get _tenant => _ctx.requireSignedIn().tenantId;

  bool get _canManage =>
      roleAllows(_ctx.requireSignedIn().role, Permission.manageResources);

  @override
  List<Department> departments() {
    final u = _ctx.require(Permission.viewResources);
    return _ctx.store.departments.of(u.tenantId)
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  List<Course> courses({String? departmentId}) {
    final u = _ctx.require(Permission.viewResources);
    return _ctx.store.courses
        .of(u.tenantId)
        .where((c) => departmentId == null || c.departmentId == departmentId)
        .toList()
      ..sort((a, b) => a.code.compareTo(b.code));
  }

  @override
  Course? course(String courseId) =>
      _ctx.store.courses.find(_tenant, courseId);

  @override
  Department? department(String departmentId) =>
      _ctx.store.departments.find(_tenant, departmentId);

  /// Students never see archived papers (FR-RES-05).
  List<Resource> _visible({bool includeArchived = false}) {
    final u = _ctx.require(Permission.viewResources);
    final showArchived = includeArchived && _canManage;
    return _ctx.store.resources
        .of(u.tenantId)
        .where((r) => showArchived || !r.archived)
        .toList();
  }

  @override
  List<Resource> search(SearchQuery q, {bool log = false}) {
    final u = _ctx.require(Permission.viewResources);
    final courses = {for (final c in _ctx.store.courses.of(u.tenantId)) c.id: c};
    final terms = q.text
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final compactQuery = q.text.toLowerCase().replaceAll(' ', '');

    bool matchesText(Resource r) {
      if (terms.isEmpty) return true;
      final c = courses[r.courseId];
      final haystack = [
        r.title,
        c?.code ?? '',
        c?.name ?? '',
        ...r.topics,
        '${r.academicYear}',
      ].join(' ').toLowerCase();
      // "ICT2201" and "ICT 2201" both match the course code.
      final codeCompact = (c?.code ?? '').toLowerCase().replaceAll(' ', '');
      if (compactQuery.isNotEmpty && codeCompact.contains(compactQuery)) {
        return true;
      }
      return terms.every(haystack.contains);
    }

    final results = _visible(includeArchived: q.includeArchived).where((r) {
      final c = courses[r.courseId];
      return matchesText(r) &&
          (q.departmentId == null || c?.departmentId == q.departmentId) &&
          (q.courseId == null || r.courseId == q.courseId) &&
          (q.year == null || r.academicYear == q.year) &&
          (q.semester == null || r.semester == q.semester) &&
          (q.paperType == null || r.paperType == q.paperType);
    }).toList();

    int byCode(Resource a, Resource b) =>
        (courses[a.courseId]?.code ?? '').compareTo(courses[b.courseId]?.code ?? '');
    switch (q.sort) {
      case SortOrder.newest:
        results.sort((a, b) {
          final y = b.academicYear.compareTo(a.academicYear);
          return y != 0 ? y : byCode(a, b);
        });
      case SortOrder.oldest:
        results.sort((a, b) {
          final y = a.academicYear.compareTo(b.academicYear);
          return y != 0 ? y : byCode(a, b);
        });
      case SortOrder.courseCode:
        results.sort((a, b) {
          final c = byCode(a, b);
          return c != 0 ? c : b.academicYear.compareTo(a.academicYear);
        });
    }

    if (log && q.text.trim().isNotEmpty) {
      _ctx.logEvent(
        u.tenantId,
        results.isEmpty ? UsageEventType.unmetSearch : UsageEventType.search,
        term: q.text.trim(),
      );
      _ctx.store.commit();
    }
    return results;
  }

  @override
  List<Department> browseDepartments() {
    final withResources = {
      for (final r in _visible()) course(r.courseId)?.departmentId,
    };
    return departments().where((d) => withResources.contains(d.id)).toList();
  }

  @override
  List<Course> browseCourses(String departmentId) {
    final withResources = {for (final r in _visible()) r.courseId};
    return courses(departmentId: departmentId)
        .where((c) => withResources.contains(c.id))
        .toList();
  }

  @override
  List<int> browseYears(String courseId) => {
        for (final r in _visible())
          if (r.courseId == courseId) r.academicYear,
      }.toList()
        ..sort((a, b) => b.compareTo(a));

  @override
  List<Resource> resourcesFor(String courseId, {int? year}) => _visible()
      .where((r) => r.courseId == courseId && (year == null || r.academicYear == year))
      .toList()
    ..sort((a, b) => b.academicYear.compareTo(a.academicYear));

  @override
  Resource resource(String id) {
    final u = _ctx.require(Permission.viewResources);
    final r = _ctx.resourceOrThrow(u.tenantId, id);
    if (r.archived && !_canManage) {
      throw const NotFoundException('This paper has been archived.');
    }
    return r;
  }

  @override
  List<PhysicalCopy> copies(String resourceId) {
    final u = _ctx.require(Permission.viewResources);
    return _ctx.store.copies
        .of(u.tenantId)
        .where((c) => c.resourceId == resourceId)
        .toList()
      ..sort((a, b) => a.copyNumber.compareTo(b.copyNumber));
  }

  @override
  int availableCopies(String resourceId) =>
      copies(resourceId).where((c) => c.status == CopyStatus.available).length;

  @override
  Future<PaperFile?> openFile(String resourceId) async {
    final u = _ctx.require(Permission.viewResources);
    final r = resource(resourceId);
    _ctx.logEvent(u.tenantId, UsageEventType.view, refId: r.id);
    final recent = _ctx.store.recentViews.putIfAbsent(u.id, () => <String>[]);
    recent
      ..remove(r.id)
      ..insert(0, r.id);
    if (recent.length > Rules.recentItems) recent.removeRange(Rules.recentItems, recent.length);
    final seen = _ctx.store.viewed.putIfAbsent(u.id, () => <String>[]);
    if (!seen.contains(r.id)) seen.add(r.id);
    _ctx.store.commit();

    final file = r.fileAsset;
    if (file == null) return null;
    if (file.startsWith('upload:')) {
      final bytes = await _ctx.store.readFile(file.substring('upload:'.length));
      return bytes == null ? null : BytesPaperFile(bytes);
    }
    return AssetPaperFile(file);
  }

  @override
  Resource? findDuplicate(ResourceDraft d, {String? ignoreId}) {
    final u = _ctx.require(Permission.manageResources);
    for (final r in _ctx.store.resources.of(u.tenantId)) {
      if (r.id != ignoreId &&
          r.courseId == d.courseId &&
          r.academicYear == d.academicYear &&
          r.semester == d.semester &&
          r.paperType == d.paperType) {
        return r;
      }
    }
    return null;
  }

  Map<String, String> _validate(ResourceDraft d, {required bool requireFile}) {
    final e = <String, String>{};
    final year = Clock.now().year;
    if (d.title.trim().isEmpty) e['title'] = 'Enter a title.';
    if (d.departmentId == null) e['departmentId'] = 'Choose a department.';
    if (d.courseId == null) e['courseId'] = 'Choose the course code.';
    if (d.academicYear == null) {
      e['academicYear'] = 'Enter the academic year.';
    } else if (d.academicYear! < 1990 || d.academicYear! > year) {
      e['academicYear'] = 'Enter a year between 1990 and $year.';
    }
    if (d.semester == null) e['semester'] = 'Choose the semester.';
    if (d.paperType == null) e['paperType'] = 'Choose the paper type.';
    if (requireFile && d.fileBytes == null) e['file'] = 'Choose a PDF file.';
    if (d.fileName != null && !d.fileName!.toLowerCase().endsWith('.pdf')) {
      e['file'] = 'The file must be a PDF.';
    }
    if (d.courseId != null && d.departmentId != null) {
      final c = _ctx.store.courses.find(_tenant, d.courseId!);
      if (c == null || c.departmentId != d.departmentId) {
        e['courseId'] = 'This course is not in the chosen department.';
      }
    }
    return e;
  }

  @override
  Future<Resource> upload(ResourceDraft d) async {
    final u = _ctx.require(Permission.manageResources);
    final errors = _validate(d, requireFile: true);
    if (errors.isNotEmpty) throw ValidationException(errors);

    final fileId = newId('file');
    await _ctx.store.saveFile(fileId, d.fileBytes!);
    final r = Resource(
      id: newId('r'),
      tenantId: u.tenantId,
      courseId: d.courseId!,
      title: d.title.trim(),
      academicYear: d.academicYear!,
      semester: d.semester!,
      paperType: d.paperType!,
      lecturer: _blankToNull(d.lecturer),
      durationMinutes: d.durationMinutes,
      totalMarks: d.totalMarks,
      topics: d.topics,
      hasMemo: d.hasMemo,
      fileAsset: 'upload:$fileId',
      uploadedBy: u.id,
      uploadedAt: Clock.now(),
    );
    _ctx.store.resources.add(r);

    // FR-NOT-02: only students enrolled in the course.
    final course = _ctx.store.courses.find(u.tenantId, r.courseId)!;
    for (final s in _ctx.store.users.of(u.tenantId)) {
      if (s.role == Role.student && s.enrolledCourseIds.contains(r.courseId)) {
        _ctx.notify(
          tenantId: u.tenantId,
          userId: s.id,
          category: NotificationCategory.newResource,
          title: 'New paper for ${course.code}',
          body: '${r.title} is now available.',
          route: 'resource:${r.id}',
        );
      }
    }
    _ctx.store.commit();
    return r;
  }

  @override
  Future<Resource> update(String resourceId, ResourceDraft d) async {
    final u = _ctx.require(Permission.manageResources);
    final r = _ctx.resourceOrThrow(u.tenantId, resourceId);
    final errors = _validate(d, requireFile: false);
    if (errors.isNotEmpty) throw ValidationException(errors);
    if (d.fileBytes != null) {
      final fileId = newId('file');
      await _ctx.store.saveFile(fileId, d.fileBytes!);
      r.fileAsset = 'upload:$fileId';
    }
    r
      ..title = d.title.trim()
      ..courseId = d.courseId!
      ..academicYear = d.academicYear!
      ..semester = d.semester!
      ..paperType = d.paperType!
      ..lecturer = _blankToNull(d.lecturer)
      ..durationMinutes = d.durationMinutes
      ..totalMarks = d.totalMarks
      ..topics = d.topics
      ..hasMemo = d.hasMemo;
    _ctx.store.commit();
    return r;
  }

  @override
  Future<void> setArchived(String resourceId, bool archived) async {
    final u = _ctx.require(Permission.manageResources);
    _ctx.resourceOrThrow(u.tenantId, resourceId).archived = archived;
    _ctx.store.commit();
  }

  @override
  Future<PhysicalCopy> addCopy(String resourceId, String shelfLocation) async {
    final u = _ctx.require(Permission.manageResources);
    _ctx.resourceOrThrow(u.tenantId, resourceId);
    if (shelfLocation.trim().isEmpty) {
      throw const ValidationException({'shelf': 'Enter a shelf location.'});
    }
    final existing = copies(resourceId);
    final next = existing.isEmpty
        ? 1
        : existing.map((c) => c.copyNumber).reduce((a, b) => a > b ? a : b) + 1;
    final copy = PhysicalCopy(
      id: newId('pc'),
      tenantId: u.tenantId,
      resourceId: resourceId,
      copyNumber: next,
      shelfLocation: shelfLocation.trim(),
    );
    _ctx.store.copies.add(copy);
    _ctx.store.commit();
    return copy;
  }

  @override
  Future<void> updateCopy(String copyId, String shelfLocation) async {
    final u = _ctx.require(Permission.manageResources);
    final c = _ctx.store.copies.find(u.tenantId, copyId);
    if (c == null) throw const NotFoundException('That copy could not be found.');
    if (shelfLocation.trim().isEmpty) {
      throw const ValidationException({'shelf': 'Enter a shelf location.'});
    }
    c.shelfLocation = shelfLocation.trim();
    _ctx.store.commit();
  }

  @override
  Future<void> removeCopy(String copyId) async {
    final u = _ctx.require(Permission.manageResources);
    final c = _ctx.store.copies.find(u.tenantId, copyId);
    if (c == null) throw const NotFoundException('That copy could not be found.');
    if (c.status != CopyStatus.available) {
      throw const RuleException(
          'This copy is reserved or on loan. Remove it after it is returned.');
    }
    _ctx.store.copies.remove(u.tenantId, copyId);
    _ctx.store.commit();
  }

  @override
  bool isBookmarked(String resourceId) {
    final u = _ctx.requireSignedIn();
    return _ctx.store.bookmarks[u.id]?.contains(resourceId) ?? false;
  }

  @override
  Future<void> toggleBookmark(String resourceId) async {
    final u = _ctx.require(Permission.viewResources);
    resource(resourceId);
    final list = _ctx.store.bookmarks.putIfAbsent(u.id, () => <String>[]);
    if (!list.remove(resourceId)) list.insert(0, resourceId);
    _ctx.store.commit();
  }

  List<Resource> _byIds(List<String>? ids) {
    final visible = {for (final r in _visible()) r.id: r};
    return [
      for (final id in ids ?? const <String>[])
        if (visible[id] != null) visible[id]!,
    ];
  }

  @override
  List<Resource> bookmarked() => _byIds(_ctx.store.bookmarks[_ctx.requireSignedIn().id]);

  @override
  List<String> recentSearches() =>
      List.of(_ctx.store.recentSearches[_ctx.requireSignedIn().id] ?? const []);

  @override
  Future<void> addRecentSearch(String term) async {
    final t = term.trim();
    if (t.isEmpty) return;
    final u = _ctx.requireSignedIn();
    final list = _ctx.store.recentSearches.putIfAbsent(u.id, () => <String>[]);
    list
      ..removeWhere((s) => s.toLowerCase() == t.toLowerCase())
      ..insert(0, t);
    if (list.length > Rules.recentItems) list.removeRange(Rules.recentItems, list.length);
    _ctx.store.commit();
  }

  @override
  List<Resource> recentlyViewed() => _byIds(_ctx.store.recentViews[_ctx.requireSignedIn().id]);

  @override
  List<String> knownTopics(String courseId) {
    final u = _ctx.require(Permission.viewResources);
    final topics = <String>{
      for (final r in _ctx.store.resources.of(u.tenantId))
        if (r.courseId == courseId) ...r.topics,
      for (final q in _ctx.store.questions.of(u.tenantId))
        if (q.courseId == courseId) q.topic,
    };
    return topics.toList()..sort();
  }

  String? _blankToNull(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();
}
