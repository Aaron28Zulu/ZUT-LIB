import 'enums.dart';
import 'json.dart';

/// One student borrowing one physical copy (SRS 3.5). Holds no ID-document
/// fields by design (FR-BOR-13).
class Loan implements TenantScoped {
  Loan({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.resourceId,
    required this.status,
    required this.requestedAt,
    this.copyId,
    this.approvedBy,
    this.approvedAt,
    this.qrToken,
    this.qrUsed = false,
    this.collectedAt,
    this.dueAt,
    this.returnedAt,
    this.rejectionReason,
    this.renewalCount = 0,
    this.renewalRequested = false,
    this.notifiedDueSoon = false,
  });

  @override
  final String id;
  @override
  final String tenantId;
  final String studentId;
  final String resourceId;
  String? copyId;
  LoanStatus status;
  final DateTime requestedAt;
  String? approvedBy;
  DateTime? approvedAt;
  String? qrToken;
  bool qrUsed;
  DateTime? collectedAt;
  DateTime? dueAt;
  DateTime? returnedAt;
  String? rejectionReason;
  int renewalCount;
  bool renewalRequested;
  bool notifiedDueSoon;

  /// Payload encoded in the collection QR code (FR-BOR-05, NFR-08): no personal data.
  String? get qrPayload =>
      qrToken == null ? null : 'ZUTLIB|$tenantId|$id|$qrToken';

  factory Loan.fromJson(Map<String, dynamic> j) => Loan(
        id: j['id'],
        tenantId: j['tenantId'],
        studentId: j['studentId'],
        resourceId: j['resourceId'],
        copyId: j['copyId'],
        status: enumByName(LoanStatus.values, j['status']),
        requestedAt: parseDate(j['requestedAt'])!,
        approvedBy: j['approvedBy'],
        approvedAt: parseDate(j['approvedAt']),
        qrToken: j['qrToken'],
        qrUsed: j['qrUsed'] ?? false,
        collectedAt: parseDate(j['collectedAt']),
        dueAt: parseDate(j['dueAt']),
        returnedAt: parseDate(j['returnedAt']),
        rejectionReason: j['rejectionReason'],
        renewalCount: j['renewalCount'] ?? 0,
        renewalRequested: j['renewalRequested'] ?? false,
        notifiedDueSoon: j['notifiedDueSoon'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'studentId': studentId,
        'resourceId': resourceId,
        'copyId': copyId,
        'status': status.name,
        'requestedAt': dateToJson(requestedAt),
        'approvedBy': approvedBy,
        'approvedAt': dateToJson(approvedAt),
        'qrToken': qrToken,
        'qrUsed': qrUsed,
        'collectedAt': dateToJson(collectedAt),
        'dueAt': dateToJson(dueAt),
        'returnedAt': dateToJson(returnedAt),
        'rejectionReason': rejectionReason,
        'renewalCount': renewalCount,
        'renewalRequested': renewalRequested,
        'notifiedDueSoon': notifiedDueSoon,
      };
}
