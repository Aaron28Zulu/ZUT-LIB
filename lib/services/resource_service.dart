import 'dart:typed_data';

import '../models/models.dart';

enum SortOrder {
  newest('Newest year'),
  oldest('Oldest year'),
  courseCode('Course code');

  const SortOrder(this.label);
  final String label;
}

/// FR-SRCH-01 to 03
class SearchQuery {
  const SearchQuery({
    this.text = '',
    this.departmentId,
    this.courseId,
    this.year,
    this.semester,
    this.paperType,
    this.sort = SortOrder.newest,
    this.includeArchived = false,
  });

  final String text;
  final String? departmentId;
  final String? courseId;
  final int? year;
  final int? semester;
  final PaperType? paperType;
  final SortOrder sort;

  /// Librarian view only (FR-RES-05).
  final bool includeArchived;

  bool get hasFilters =>
      departmentId != null ||
      courseId != null ||
      year != null ||
      semester != null ||
      paperType != null;

  SearchQuery copyWith({
    String? text,
    String? Function()? departmentId,
    String? Function()? courseId,
    int? Function()? year,
    int? Function()? semester,
    PaperType? Function()? paperType,
    SortOrder? sort,
    bool? includeArchived,
  }) =>
      SearchQuery(
        text: text ?? this.text,
        departmentId: departmentId != null ? departmentId() : this.departmentId,
        courseId: courseId != null ? courseId() : this.courseId,
        year: year != null ? year() : this.year,
        semester: semester != null ? semester() : this.semester,
        paperType: paperType != null ? paperType() : this.paperType,
        sort: sort ?? this.sort,
        includeArchived: includeArchived ?? this.includeArchived,
      );

  SearchQuery clearFilters() => SearchQuery(text: text, sort: sort);
}

/// Upload / edit form data (FR-RES-01 to 03).
class ResourceDraft {
  ResourceDraft({
    this.title = '',
    this.departmentId,
    this.courseId,
    this.academicYear,
    this.semester,
    this.paperType,
    this.lecturer,
    this.durationMinutes,
    this.totalMarks,
    this.topics = const [],
    this.hasMemo = false,
    this.fileName,
    this.fileBytes,
  });

  String title;
  String? departmentId;
  String? courseId;
  int? academicYear;
  int? semester;
  PaperType? paperType;
  String? lecturer;
  int? durationMinutes;
  int? totalMarks;
  List<String> topics;
  bool hasMemo;
  String? fileName;
  Uint8List? fileBytes;
}

/// Where the PDF for a resource comes from.
sealed class PaperFile {
  const PaperFile();
}

class AssetPaperFile extends PaperFile {
  const AssetPaperFile(this.assetPath);
  final String assetPath;
}

class BytesPaperFile extends PaperFile {
  const BytesPaperFile(this.bytes);
  final Uint8List bytes;
}

/// Repository, search and browse (SRS 3.3, 3.4).
abstract interface class ResourceService {
  List<Department> departments();
  List<Course> courses({String? departmentId});
  Course? course(String courseId);
  Department? department(String departmentId);

  /// FR-SRCH-01..03, FR-SRCH-05 (logs unmet searches when [log] is true).
  List<Resource> search(SearchQuery query, {bool log = false});

  /// FR-SRCH-04: only levels that contain resources.
  List<Department> browseDepartments();
  List<Course> browseCourses(String departmentId);
  List<int> browseYears(String courseId);
  List<Resource> resourcesFor(String courseId, {int? year});

  Resource resource(String id);
  List<PhysicalCopy> copies(String resourceId);
  int availableCopies(String resourceId);

  /// FR-RES-07; records a view event and recent view.
  Future<PaperFile?> openFile(String resourceId);

  /// FR-RES-04: returns the existing resource when the draft duplicates one.
  Resource? findDuplicate(ResourceDraft draft, {String? ignoreId});

  /// FR-RES-01/02. Throws [ValidationException] with per-field messages.
  Future<Resource> upload(ResourceDraft draft);
  Future<Resource> update(String resourceId, ResourceDraft draft);
  Future<void> setArchived(String resourceId, bool archived);

  /// FR-RES-06
  Future<PhysicalCopy> addCopy(String resourceId, String shelfLocation);
  Future<void> updateCopy(String copyId, String shelfLocation);
  Future<void> removeCopy(String copyId);

  /// FR-RES-08
  bool isBookmarked(String resourceId);
  Future<void> toggleBookmark(String resourceId);
  List<Resource> bookmarked();

  /// FR-SRCH-06, FR-RES-09
  List<String> recentSearches();
  Future<void> addRecentSearch(String term);
  List<Resource> recentlyViewed();

  /// Topic tags used in a course's resources (upload form suggestions).
  List<String> knownTopics(String courseId);
}
