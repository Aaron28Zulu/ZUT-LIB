import '../../core/clock.dart';
import '../../core/errors.dart';
import '../../core/hashing.dart';
import '../../core/ids.dart';
import '../../core/permissions.dart';
import '../../models/models.dart';
import '../admin_service.dart';
import 'mock_context.dart';

class MockAdminService implements AdminService {
  MockAdminService(this._ctx);

  final MockContext _ctx;

  /// Accounts added by an administrator start with this password (demo only).
  static const defaultPassword = 'demo1234';

  AppUser get _admin => _ctx.require(Permission.manageUsers);

  AppUser _findUser(AppUser admin, String id) {
    final u = _ctx.store.users.find(admin.tenantId, id);
    if (u == null) throw const NotFoundException('That user could not be found.');
    return u;
  }

  @override
  List<AppUser> users({String query = '', Role? role}) {
    final a = _admin;
    final q = query.trim().toLowerCase();
    return _ctx.store.users
        .of(a.tenantId)
        .where((u) =>
            (role == null || u.role == role) &&
            (q.isEmpty ||
                u.fullName.toLowerCase().contains(q) ||
                u.email.toLowerCase().contains(q) ||
                (u.studentNumber ?? '').toLowerCase().contains(q)))
        .toList()
      ..sort((x, y) => x.fullName.compareTo(y.fullName));
  }

  @override
  AppUser user(String id) => _findUser(_admin, id);

  @override
  Future<AppUser> addUser(NewUserDraft d) async {
    final a = _admin;
    final e = <String, String>{};
    if (d.fullName.trim().isEmpty) e['fullName'] = 'Enter the full name.';
    final email = d.email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      e['email'] = 'Enter a valid email address.';
    } else if (_ctx.store.userByEmailInTenant(a.tenantId, email) != null) {
      e['email'] = 'An account with this email already exists.';
    }
    if (d.role == Role.platformAdmin) e['role'] = 'Choose a role at this institution.';
    if (d.role == Role.student && (d.studentNumber ?? '').trim().isEmpty) {
      e['studentNumber'] = 'Enter the student number.';
    }
    if (e.isNotEmpty) throw ValidationException(e);
    final user = AppUser(
      id: newId('u'),
      tenantId: a.tenantId,
      fullName: d.fullName.trim(),
      email: email,
      passwordHash: hashPassword(defaultPassword),
      role: d.role,
      roleGrantedAt: Clock.now(),
      studentNumber: d.studentNumber?.trim(),
      departmentId: d.departmentId,
      yearOfStudy: d.yearOfStudy,
      profileComplete: d.role != Role.student,
    );
    _ctx.store.users.add(user);
    _ctx.store.commit();
    return user;
  }

  @override
  Future<void> setActive(String userId, bool active) async {
    final a = _admin;
    if (userId == a.id) throw const RuleException('You cannot deactivate your own account.');
    _findUser(a, userId).active = active;
    _ctx.store.commit();
  }

  @override
  Future<void> changeRole(String userId, Role role) async {
    final a = _admin;
    if (role == Role.platformAdmin) throw const PermissionDeniedException();
    if (userId == a.id) throw const RuleException('Ask another administrator to change your role.');
    final u = _findUser(a, userId);
    // FR-ADM-04: takes effect at the user's next sign-in.
    u.pendingRole = role == u.role ? null : role;
    _ctx.store.commit();
  }

  @override
  List<AppUser> staffRoles() {
    final a = _admin;
    return _ctx.store.users
        .of(a.tenantId)
        .where((u) => u.role == Role.librarian || u.role == Role.institutionAdmin)
        .toList()
      ..sort((x, y) => x.roleGrantedAt.compareTo(y.roleGrantedAt));
  }

  @override
  Future<void> revokeRole(String userId) => changeRole(userId, Role.student);

  @override
  List<Department> departments() =>
      _ctx.store.departments.of(_admin.tenantId)..sort((a, b) => a.name.compareTo(b.name));

  @override
  List<Course> courses() =>
      _ctx.store.courses.of(_admin.tenantId)..sort((a, b) => a.code.compareTo(b.code));

  @override
  Future<void> saveDepartment({String? id, required String name, required String code}) async {
    final a = _admin;
    final e = <String, String>{};
    if (name.trim().isEmpty) e['name'] = 'Enter the department name.';
    if (code.trim().isEmpty) e['code'] = 'Enter a short code.';
    if (e.isNotEmpty) throw ValidationException(e);
    if (id == null) {
      _ctx.store.departments.add(Department(
          id: newId('d'), tenantId: a.tenantId, name: name.trim(), code: code.trim().toUpperCase()));
    } else {
      final d = _ctx.store.departments.find(a.tenantId, id);
      if (d == null) throw const NotFoundException('That department could not be found.');
      d
        ..name = name.trim()
        ..code = code.trim().toUpperCase();
    }
    _ctx.store.commit();
  }

  @override
  Future<void> saveCourse({
    String? id,
    required String departmentId,
    required String code,
    required String name,
    required int yearLevel,
  }) async {
    final a = _admin;
    final e = <String, String>{};
    if (_ctx.store.departments.find(a.tenantId, departmentId) == null) {
      e['departmentId'] = 'Choose a department.';
    }
    if (code.trim().isEmpty) e['code'] = 'Enter the course code.';
    if (name.trim().isEmpty) e['name'] = 'Enter the course name.';
    final clash = _ctx.store.courses
        .of(a.tenantId)
        .any((c) => c.id != id && c.code.toLowerCase() == code.trim().toLowerCase());
    if (clash) e['code'] = 'Another course already uses this code.';
    if (e.isNotEmpty) throw ValidationException(e);
    if (id == null) {
      _ctx.store.courses.add(Course(
        id: newId('c'),
        tenantId: a.tenantId,
        departmentId: departmentId,
        code: code.trim().toUpperCase(),
        name: name.trim(),
        yearLevel: yearLevel,
      ));
    } else {
      final c = _ctx.store.courses.find(a.tenantId, id);
      if (c == null) throw const NotFoundException('That course could not be found.');
      c
        ..departmentId = departmentId
        ..code = code.trim().toUpperCase()
        ..name = name.trim()
        ..yearLevel = yearLevel;
    }
    _ctx.store.commit();
  }

  @override
  Future<void> deleteDepartment(String id) async {
    final a = _admin;
    if (_ctx.store.courses.of(a.tenantId).any((c) => c.departmentId == id)) {
      throw const RuleException('Move or delete this department\'s courses first.');
    }
    _ctx.store.departments.remove(a.tenantId, id);
    _ctx.store.commit();
  }

  @override
  Future<void> deleteCourse(String id) async {
    final a = _admin;
    if (_ctx.store.resources.of(a.tenantId).any((r) => r.courseId == id)) {
      throw const RuleException('This course has papers. Archive or move them first.');
    }
    _ctx.store.courses.remove(a.tenantId, id);
    _ctx.store.commit();
  }

  @override
  TenantDashboard dashboard() {
    final u = _ctx.require(Permission.viewLibraryReports);
    final t = u.tenantId;
    final events = _ctx.store.usageEvents.of(t);
    final loans = _ctx.store.loans.of(t);
    final resources = {for (final r in _ctx.store.resources.of(t)) r.id: r};
    final now = Clock.now().toLocal();

    List<CountItem> top(Iterable<String?> keys, String Function(String) label) {
      final counts = <String, int>{};
      for (final k in keys) {
        if (k == null) continue;
        counts[k] = (counts[k] ?? 0) + 1;
      }
      final sorted = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      return [for (final e in sorted.take(5)) CountItem(label(e.key), e.value, refId: e.key)];
    }

    final fullReports = roleAllows(u.role, Permission.viewTenantReports);
    return TenantDashboard(
      totalResources: resources.values.where((r) => !r.archived).length,
      searches: fullReports
          ? events.where((e) => e.type == UsageEventType.search || e.type == UsageEventType.unmetSearch).length
          : 0,
      views: events.where((e) => e.type == UsageEventType.view).length,
      activeLoans: loans.where((l) => l.status.isActive).length,
      overdueLoans: loans.where((l) => l.status == LoanStatus.overdue).length,
      pendingRequests: loans.where((l) => l.status == LoanStatus.requested).length,
      dueToday: loans.where((l) {
        final d = l.dueAt?.toLocal();
        return l.status == LoanStatus.collected &&
            d != null &&
            d.year == now.year &&
            d.month == now.month &&
            d.day == now.day;
      }).length,
      quizAttempts: fullReports ? _ctx.store.quizAttempts.of(t).length : 0,
      mostViewed: top(
        events.where((e) => e.type == UsageEventType.view && resources.containsKey(e.refId)).map((e) => e.refId),
        (id) => resources[id]!.title,
      ),
      unmetSearches: fullReports
          ? top(events.where((e) => e.type == UsageEventType.unmetSearch).map((e) => e.term?.toLowerCase()), (k) => k)
          : const [],
    );
  }

  @override
  Future<void> sendFeedback(String message) async {
    final u = _ctx.require(Permission.sendFeedback);
    if (message.trim().isEmpty) {
      throw const ValidationException({'message': 'Write your feedback first.'});
    }
    _ctx.store.feedback.add(FeedbackEntry(
      id: newId('fb'),
      tenantId: u.tenantId,
      userId: u.id,
      message: message.trim(),
      createdAt: Clock.now(),
    ));
    _ctx.store.commit();
  }

  @override
  List<FeedbackEntry> feedback() {
    final u = _ctx.require(Permission.viewFeedback);
    return _ctx.store.feedback.of(u.tenantId)..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  String feedbackAuthor(FeedbackEntry f) {
    final u = _ctx.require(Permission.viewFeedback);
    return _ctx.store.users.find(u.tenantId, f.userId)?.fullName ?? 'Former user';
  }
}
