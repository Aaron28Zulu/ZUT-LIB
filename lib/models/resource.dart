import 'enums.dart';
import 'json.dart';

/// FR-SSA-07
class ResourceSummary {
  ResourceSummary({
    required this.overview,
    required this.topics,
    required this.questionTypes,
    required this.markDistribution,
  });

  final String overview;
  final List<String> topics;
  final List<String> questionTypes;
  final List<({String section, int marks})> markDistribution;

  factory ResourceSummary.fromJson(Map<String, dynamic> j) => ResourceSummary(
        overview: j['overview'],
        topics: stringList(j['topics']),
        questionTypes: stringList(j['questionTypes']),
        markDistribution: (j['markDistribution'] as List)
            .map((m) => (section: m['section'] as String, marks: m['marks'] as int))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'overview': overview,
        'topics': topics,
        'questionTypes': questionTypes,
        'markDistribution': markDistribution
            .map((m) => {'section': m.section, 'marks': m.marks})
            .toList(),
      };
}

class Resource implements TenantScoped {
  Resource({
    required this.id,
    required this.tenantId,
    required this.courseId,
    required this.title,
    required this.academicYear,
    required this.semester,
    required this.paperType,
    required this.uploadedBy,
    required this.uploadedAt,
    this.fileAsset,
    this.lecturer,
    this.durationMinutes,
    this.totalMarks,
    List<String>? topics,
    this.hasMemo = false,
    this.summary,
    this.archived = false,
  }) : topics = topics ?? [];

  @override
  final String id;
  @override
  final String tenantId;
  String courseId;
  String title;
  int academicYear;
  int semester;
  PaperType paperType;
  String? lecturer;
  int? durationMinutes;
  int? totalMarks;
  List<String> topics;

  /// Either a bundled asset path (`assets/papers/...`) or `upload:<fileId>`.
  String? fileAsset;
  bool hasMemo;
  ResourceSummary? summary;
  bool archived;
  final String uploadedBy;
  DateTime uploadedAt;

  factory Resource.fromJson(Map<String, dynamic> j) => Resource(
        id: j['id'],
        tenantId: j['tenantId'],
        courseId: j['courseId'],
        title: j['title'],
        academicYear: j['academicYear'],
        semester: j['semester'],
        paperType: PaperType.fromKey(j['paperType']),
        lecturer: j['lecturer'],
        durationMinutes: j['durationMinutes'],
        totalMarks: j['totalMarks'],
        topics: stringList(j['topics']),
        fileAsset: j['fileAsset'],
        hasMemo: j['hasMemo'] ?? false,
        summary: j['summary'] == null
            ? null
            : ResourceSummary.fromJson(j['summary']),
        archived: j['archived'] ?? false,
        uploadedBy: j['uploadedBy'],
        uploadedAt: parseDate(j['uploadedAt'])!,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'courseId': courseId,
        'title': title,
        'academicYear': academicYear,
        'semester': semester,
        'paperType': paperType.key,
        'lecturer': lecturer,
        'durationMinutes': durationMinutes,
        'totalMarks': totalMarks,
        'topics': topics,
        'fileAsset': fileAsset,
        'hasMemo': hasMemo,
        'summary': summary?.toJson(),
        'archived': archived,
        'uploadedBy': uploadedBy,
        'uploadedAt': dateToJson(uploadedAt),
      };
}

class PhysicalCopy implements TenantScoped {
  PhysicalCopy({
    required this.id,
    required this.tenantId,
    required this.resourceId,
    required this.copyNumber,
    required this.shelfLocation,
    this.status = CopyStatus.available,
  });

  @override
  final String id;
  @override
  final String tenantId;
  final String resourceId;
  int copyNumber;
  String shelfLocation;
  CopyStatus status;

  factory PhysicalCopy.fromJson(Map<String, dynamic> j) => PhysicalCopy(
        id: j['id'],
        tenantId: j['tenantId'],
        resourceId: j['resourceId'],
        copyNumber: j['copyNumber'],
        shelfLocation: j['shelfLocation'],
        status: enumByName(CopyStatus.values, j['status']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'resourceId': resourceId,
        'copyNumber': copyNumber,
        'shelfLocation': shelfLocation,
        'status': status.name,
      };
}
