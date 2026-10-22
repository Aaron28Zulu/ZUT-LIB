import '../../core/clock.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/ids.dart';
import '../../core/permissions.dart';
import '../../core/rules.dart';
import '../../models/models.dart';
import '../loan_service.dart';
import 'mock_context.dart';

class MockLoanService implements LoanService {
  MockLoanService(this._ctx);

  final MockContext _ctx;

  static const _staff = {Role.librarian, Role.institutionAdmin};

  Loan _find(String tenantId, String loanId) {
    final l = _ctx.store.loans.find(tenantId, loanId);
    if (l == null) throw const NotFoundException('That loan could not be found.');
    return l;
  }

  Loan _own(AppUser student, String loanId) {
    final l = _find(student.tenantId, loanId);
    if (l.studentId != student.id) throw const PermissionDeniedException();
    return l;
  }

  void _release(Loan l) {
    if (l.copyId == null) return;
    _ctx.store.copies.find(l.tenantId, l.copyId!)?.status = CopyStatus.available;
  }

  String _label(Loan l) {
    final r = _ctx.store.resources.find(l.tenantId, l.resourceId);
    return r == null ? 'the paper' : _ctx.resourceLabel(r);
  }

  @override
  String? requestBlockReason(String resourceId) {
    final u = _ctx.require(Permission.borrow);
    final mine = _ctx.store.loans.of(u.tenantId).where((l) => l.studentId == u.id);
    final active = mine.where((l) => l.status.isActive).toList();
    if (active.any((l) => l.status == LoanStatus.overdue)) {
      return 'You have an overdue loan. Return it before requesting another copy.';
    }
    if (active.any((l) => l.resourceId == resourceId)) {
      return 'You already have an active loan for this paper.';
    }
    if (active.length >= Rules.maxActiveLoans) {
      return 'You already have ${Rules.maxActiveLoans} active loans. '
          'Return or cancel one to request another.';
    }
    final available = _ctx.store.copies
        .of(u.tenantId)
        .where((c) => c.resourceId == resourceId && c.status == CopyStatus.available)
        .length;
    if (available == 0) return 'No copies are available right now.';
    return null;
  }

  @override
  Future<Loan> request(String resourceId) async {
    final u = _ctx.require(Permission.borrow);
    final r = _ctx.resourceOrThrow(u.tenantId, resourceId);
    if (r.archived) throw const NotFoundException('This paper has been archived.');
    runScheduledChecks();
    final reason = requestBlockReason(resourceId);
    if (reason != null) throw RuleException(reason);

    final loan = Loan(
      id: newId('l'),
      tenantId: u.tenantId,
      studentId: u.id,
      resourceId: resourceId,
      status: LoanStatus.requested,
      requestedAt: Clock.now(),
    );
    _ctx.store.loans.add(loan);
    _ctx.logEvent(u.tenantId, UsageEventType.loan, refId: loan.id);
    _ctx.notifyRole(u.tenantId, _staff, NotificationCategory.request,
        'New borrowing request', '${u.fullName} requested ${_ctx.resourceLabel(r)}.',
        route: 'queue');
    _ctx.store.commit();
    return loan;
  }

  @override
  Future<void> cancel(String loanId) async {
    final u = _ctx.require(Permission.borrow);
    final l = _own(u, loanId);
    if (l.status != LoanStatus.requested && l.status != LoanStatus.approved) {
      throw const RuleException('Only requested or approved loans can be cancelled.');
    }
    l.status = LoanStatus.cancelled;
    _release(l);
    _ctx.store.commit();
  }

  @override
  Future<void> requestRenewal(String loanId) async {
    final u = _ctx.require(Permission.borrow);
    final l = _own(u, loanId);
    runScheduledChecks();
    if (l.status != LoanStatus.collected) {
      throw const RuleException('Only a collected loan that is not overdue can be renewed.');
    }
    if (l.renewalCount >= Rules.maxRenewals) {
      throw const RuleException('This loan has already been renewed once.');
    }
    if (l.renewalRequested) {
      throw const RuleException('A renewal request is already waiting for the librarian.');
    }
    l.renewalRequested = true;
    _ctx.notifyRole(u.tenantId, _staff, NotificationCategory.request,
        'Renewal requested', '${u.fullName} asked to renew ${_label(l)}.',
        route: 'queue');
    _ctx.store.commit();
  }

  @override
  Future<void> decideRenewal(String loanId, {required bool approve}) async {
    final u = _ctx.require(Permission.processLoans);
    final l = _find(u.tenantId, loanId);
    if (!l.renewalRequested) throw const RuleException('There is no renewal request for this loan.');
    l.renewalRequested = false;
    if (approve) {
      if (l.status != LoanStatus.collected) {
        throw const RuleException('Only a collected loan that is not overdue can be renewed.');
      }
      l
        ..dueAt = l.dueAt!.add(Rules.renewalPeriod)
        ..renewalCount += 1
        ..notifiedDueSoon = false;
    }
    _ctx.notify(
      tenantId: l.tenantId,
      userId: l.studentId,
      category: NotificationCategory.loan,
      title: approve ? 'Renewal approved' : 'Renewal declined',
      body: approve
          ? '${_label(l)} is now due on ${formatDate(l.dueAt!)}.'
          : '${_label(l)} is still due on ${formatDate(l.dueAt!)}.',
      route: 'loan:${l.id}',
    );
    _ctx.store.commit();
  }

  @override
  Future<void> approve(String loanId) async {
    final u = _ctx.require(Permission.processLoans);
    final l = _find(u.tenantId, loanId);
    if (l.status != LoanStatus.requested) {
      throw const RuleException('Only requested loans can be approved.');
    }
    PhysicalCopy? copy;
    for (final c in _ctx.store.copies.of(u.tenantId)) {
      if (c.resourceId == l.resourceId && c.status == CopyStatus.available) {
        copy = c;
        break;
      }
    }
    if (copy == null) {
      throw const RuleException('No copy is free to reserve. Reject the request or wait for a return.');
    }
    copy.status = CopyStatus.reserved;
    l
      ..status = LoanStatus.approved
      ..copyId = copy.id
      ..approvedBy = u.id
      ..approvedAt = Clock.now()
      ..qrToken = newCollectionToken(Rules.collectionCodeLength)
      ..qrUsed = false;
    _ctx.notify(
      tenantId: l.tenantId,
      userId: l.studentId,
      category: NotificationCategory.loan,
      title: 'Request approved',
      body: 'Collect ${_label(l)} within 48 hours. Show code ${l.qrToken} at the library.',
      route: 'loan:${l.id}',
    );
    _ctx.store.commit();
  }

  @override
  Future<void> reject(String loanId, String reason) async {
    final u = _ctx.require(Permission.processLoans);
    if (reason.trim().isEmpty) {
      throw const ValidationException({'reason': 'Give a reason so the student knows what to do.'});
    }
    final l = _find(u.tenantId, loanId);
    if (l.status != LoanStatus.requested) {
      throw const RuleException('Only requested loans can be rejected.');
    }
    l
      ..status = LoanStatus.rejected
      ..rejectionReason = reason.trim();
    _ctx.notify(
      tenantId: l.tenantId,
      userId: l.studentId,
      category: NotificationCategory.loan,
      title: 'Request rejected',
      body: '${_label(l)}: ${reason.trim()}',
      route: 'loan:${l.id}',
    );
    _ctx.store.commit();
  }

  /// Resolves a scanned QR payload or a typed 6-character code to a loan in
  /// the librarian's tenant (FR-BOR-06).
  Loan _resolveCode(AppUser u, String code) {
    final raw = code.trim();
    if (raw.startsWith('ZUTLIB|')) {
      final parts = raw.split('|');
      if (parts.length != 4) throw const RuleException('This QR code is not a ZutLib collection code.');
      if (parts[1] != u.tenantId) {
        throw const RuleException('This code belongs to another institution.');
      }
      final l = _ctx.store.loans.find(u.tenantId, parts[2]);
      if (l == null || l.qrToken != parts[3]) {
        throw const RuleException('No loan matches this code.');
      }
      return l;
    }
    final token = raw.toUpperCase();
    if (token.length != Rules.collectionCodeLength) {
      throw const RuleException('Enter the 6-character code shown on the student\'s loan.');
    }
    for (final l in _ctx.store.loans.of(u.tenantId)) {
      if (l.qrToken == token) return l;
    }
    throw const RuleException('No loan at your institution matches this code.');
  }

  @override
  Future<ScanResult> collect(String code) async {
    final u = _ctx.require(Permission.processLoans);
    runScheduledChecks();
    final l = _resolveCode(u, code);
    switch (l.status) {
      case LoanStatus.approved when !l.qrUsed:
        break;
      case LoanStatus.expired:
        throw const RuleException('This code has expired. The student needs to request the paper again.');
      case LoanStatus.cancelled:
        throw const RuleException('This loan was cancelled by the student.');
      case LoanStatus.collected || LoanStatus.overdue || LoanStatus.returned:
        throw const RuleException('This code has already been used.');
      default:
        throw const RuleException('This loan is not ready for collection.');
    }
    final now = Clock.now();
    l
      ..status = LoanStatus.collected
      ..qrUsed = true
      ..collectedAt = now
      ..dueAt = now.add(Rules.loanPeriod);
    if (l.copyId != null) {
      _ctx.store.copies.find(l.tenantId, l.copyId!)?.status = CopyStatus.onLoan;
    }
    _ctx.notify(
      tenantId: l.tenantId,
      userId: l.studentId,
      category: NotificationCategory.loan,
      title: 'Copy collected',
      body: '${_label(l)} is due back on ${formatDate(l.dueAt!)}.',
      route: 'loan:${l.id}',
    );
    _ctx.store.commit();
    return ScanResult(l, 'Collected. Due back on ${formatDate(l.dueAt!)}.');
  }

  @override
  Future<ScanResult> returnByCode(String code) async {
    final u = _ctx.require(Permission.processLoans);
    final l = _resolveCode(u, code);
    await markReturned(l.id);
    return ScanResult(l, 'Returned. The copy is available again.');
  }

  @override
  Future<void> markReturned(String loanId) async {
    final u = _ctx.require(Permission.processLoans);
    final l = _find(u.tenantId, loanId);
    if (l.status == LoanStatus.returned) {
      throw const RuleException('This loan has already been returned.');
    }
    if (l.status != LoanStatus.collected && l.status != LoanStatus.overdue) {
      throw const RuleException('Only collected or overdue loans can be returned.');
    }
    l
      ..status = LoanStatus.returned
      ..returnedAt = Clock.now()
      ..renewalRequested = false;
    _release(l);
    _ctx.store.commit();
  }

  List<Loan> _sorted(Iterable<Loan> loans) =>
      loans.toList()..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));

  @override
  List<Loan> myLoans() {
    final u = _ctx.require(Permission.borrow);
    return _sorted(_ctx.store.loans.of(u.tenantId).where((l) => l.studentId == u.id));
  }

  AppUser _staffViewer() {
    final u = _ctx.requireSignedIn();
    if (!roleAllows(u.role, Permission.processLoans) &&
        !roleAllows(u.role, Permission.viewLibraryReports)) {
      throw const PermissionDeniedException();
    }
    return u;
  }

  @override
  List<Loan> tenantLoans({LoanStatus? status}) {
    final u = _staffViewer();
    return _sorted(_ctx.store.loans
        .of(u.tenantId)
        .where((l) => status == null || l.status == status));
  }

  @override
  List<Loan> pendingRequests() {
    final u = _ctx.require(Permission.processLoans);
    return _ctx.store.loans
        .of(u.tenantId)
        .where((l) => l.status == LoanStatus.requested)
        .toList()
      ..sort((a, b) => a.requestedAt.compareTo(b.requestedAt));
  }

  @override
  List<Loan> renewalRequests() {
    final u = _ctx.require(Permission.processLoans);
    return _ctx.store.loans.of(u.tenantId).where((l) => l.renewalRequested).toList();
  }

  @override
  Loan loan(String loanId) {
    final u = _ctx.requireSignedIn();
    final l = _find(u.tenantId, loanId);
    if (u.role == Role.student && l.studentId != u.id) {
      throw const PermissionDeniedException();
    }
    if (u.role == Role.platformAdmin) throw const PermissionDeniedException();
    return l;
  }

  @override
  PhysicalCopy? copyFor(Loan l) =>
      l.copyId == null ? null : _ctx.store.copies.find(_ctx.requireSignedIn().tenantId, l.copyId!);

  @override
  Resource resourceFor(Loan l) => _ctx.resourceOrThrow(_ctx.requireSignedIn().tenantId, l.resourceId);

  @override
  String studentName(Loan l) {
    final u = _ctx.requireSignedIn();
    if (u.role == Role.student && l.studentId != u.id) throw const PermissionDeniedException();
    return _ctx.store.users.find(u.tenantId, l.studentId)?.fullName ?? 'Unknown student';
  }

  @override
  void runScheduledChecks() {
    final now = Clock.now();
    var changed = false;
    // System job across all tenants; each loan is handled within its own tenant.
    for (final l in _ctx.store.loans.unscoped) {
      if (l.status == LoanStatus.approved &&
          l.approvedAt != null &&
          !now.isBefore(l.approvedAt!.add(Rules.collectionWindow))) {
        l.status = LoanStatus.expired;
        _release(l);
        changed = true;
        _ctx.notify(
          tenantId: l.tenantId,
          userId: l.studentId,
          category: NotificationCategory.loan,
          title: 'Collection window expired',
          body: '${_label(l)} was not collected within 48 hours and has been released.',
          route: 'loan:${l.id}',
        );
      } else if (l.status == LoanStatus.collected && l.dueAt != null) {
        if (!now.isBefore(l.dueAt!)) {
          l.status = LoanStatus.overdue;
          changed = true;
          _ctx.notify(
            tenantId: l.tenantId,
            userId: l.studentId,
            category: NotificationCategory.loan,
            title: 'Loan overdue',
            body: '${_label(l)} was due on ${formatDate(l.dueAt!)}. Return it to the library.',
            route: 'loan:${l.id}',
          );
        } else if (!l.notifiedDueSoon && l.dueAt!.difference(now) <= Rules.dueSoonWindow) {
          l.notifiedDueSoon = true;
          changed = true;
          _ctx.notify(
            tenantId: l.tenantId,
            userId: l.studentId,
            category: NotificationCategory.loan,
            title: 'Due tomorrow',
            body: '${_label(l)} is due back ${formatRelative(l.dueAt!)}.',
            route: 'loan:${l.id}',
          );
        }
      }
    }
    if (changed) _ctx.store.commit();
  }

  @override
  String exportCsv() {
    final u = _ctx.require(Permission.processLoans);
    String cell(Object? v) {
      final s = v?.toString() ?? '';
      return s.contains(RegExp('[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
    }

    String d(DateTime? t) => t == null ? '' : t.toLocal().toIso8601String().substring(0, 16);
    final rows = <List<Object?>>[
      ['Loan ID', 'Student', 'Student number', 'Course', 'Paper', 'Copy', 'Status',
       'Requested', 'Collected', 'Due', 'Returned', 'Rejection reason'],
    ];
    for (final l in tenantLoans()) {
      final student = _ctx.store.users.find(u.tenantId, l.studentId);
      final r = _ctx.store.resources.find(u.tenantId, l.resourceId);
      final c = r == null ? null : _ctx.store.courses.find(u.tenantId, r.courseId);
      rows.add([
        l.id, student?.fullName, student?.studentNumber, c?.code, r?.title,
        copyFor(l)?.copyNumber, l.status.label, d(l.requestedAt), d(l.collectedAt),
        d(l.dueAt), d(l.returnedAt), l.rejectionReason,
      ]);
    }
    return rows.map((r) => r.map(cell).join(',')).join('\n');
  }
}
