import '../models/models.dart';

/// Result of scanning or typing a collection code (FR-BOR-06, FR-BOR-09).
class ScanResult {
  const ScanResult(this.loan, this.message);
  final Loan loan;
  final String message;
}

/// Borrowing workflow (SRS 3.5).
abstract interface class LoanService {
  /// Why the signed-in student cannot request [resourceId], or null if they can.
  String? requestBlockReason(String resourceId);

  /// FR-BOR-01..03
  Future<Loan> request(String resourceId);

  /// FR-BOR-10
  Future<void> cancel(String loanId);

  /// FR-BOR-11
  Future<void> requestRenewal(String loanId);
  Future<void> decideRenewal(String loanId, {required bool approve});

  /// FR-BOR-04, FR-BOR-05
  Future<void> approve(String loanId);
  Future<void> reject(String loanId, String reason);

  /// FR-BOR-06. Accepts the full QR payload or the 6-character code.
  Future<ScanResult> collect(String code);

  /// FR-BOR-09. By scanned code, or directly by loan id.
  Future<ScanResult> returnByCode(String code);
  Future<void> markReturned(String loanId);

  /// FR-BOR-12
  List<Loan> myLoans();
  List<Loan> tenantLoans({LoanStatus? status});
  List<Loan> pendingRequests();
  List<Loan> renewalRequests();
  Loan loan(String loanId);
  PhysicalCopy? copyFor(Loan loan);
  Resource resourceFor(Loan loan);
  String studentName(Loan loan);

  /// FR-BOR-07, FR-BOR-08, FR-NOT-01 due-soon. A system job: in production a
  /// scheduled Cloud Function. Runs on startup and whenever the demo clock moves.
  void runScheduledChecks();

  /// FR-ADM-07
  String exportCsv();
}
