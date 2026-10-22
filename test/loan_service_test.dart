import 'package:flutter_test/flutter_test.dart';
import 'package:zutlib/core/errors.dart';
import 'package:zutlib/models/models.dart';

import 'helpers.dart';

const paper = 'r_ict2201_2023_final';

void main() {
  test('full demo flow: request, approve, collect, reuse code, overdue (SRS 11 steps 4-8)', () async {
    final env = await createEnv();
    final loans = env.services.loans;

    await env.signIn('student@zut.demo');
    final loan = await loans.request(paper);
    expect(loan.status, LoanStatus.requested);
    expect(loans.myLoans().first.id, loan.id);
    await env.services.auth.signOut();

    await env.signIn('librarian@zut.demo');
    expect(loans.pendingRequests().map((l) => l.id), contains(loan.id));
    await loans.approve(loan.id);
    expect(loan.status, LoanStatus.approved);
    expect(loan.qrToken, hasLength(6));
    expect(loan.qrPayload, 'ZUTLIB|t_zut|${loan.id}|${loan.qrToken}');
    expect(loans.copyFor(loan)!.status, CopyStatus.reserved);

    final result = await loans.collect(loan.qrPayload!);
    expect(result.loan.status, LoanStatus.collected);
    expect(loan.dueAt!.difference(loan.collectedAt!), const Duration(days: 7));
    expect(loans.copyFor(loan)!.status, CopyStatus.onLoan);

    expect(
      () => loans.collect(loan.qrToken!),
      throwsA(isA<RuleException>().having((e) => e.message, 'message', 'This code has already been used.')),
    );
    await env.services.auth.signOut();

    await env.signIn('platform@zutlib.demo');
    await env.services.platform.advanceClock(const Duration(days: 8));
    expect(loan.status, LoanStatus.overdue);
    await env.services.auth.signOut();

    await env.signIn('student@zut.demo');
    expect(env.services.notifications.mine().any((n) => n.title == 'Loan overdue'), isTrue);
    expect(() => loans.request('r_ict1101_2021_final'),
        throwsA(isA<RuleException>().having((e) => e.message, 'message', contains('overdue'))));
  });

  test('a student is limited to 3 active loans and one per paper (FR-BOR-02)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    final loans = env.services.loans;
    // Chanda starts with one collected loan in the seed.
    await loans.request('r_ict2201_2023_final');
    expect(() => loans.request('r_ict2201_2023_final'), throwsA(isA<RuleException>()));
    await loans.request('r_ict1101_2021_final');
    expect(
      () => loans.request('r_ict2205_2022_final'),
      throwsA(isA<RuleException>().having((e) => e.message, 'message', contains('3 active loans'))),
    );
  });

  test('approved loan expires after 48 hours and releases the copy (FR-BOR-07)', () async {
    final env = await createEnv();
    final loans = env.services.loans;
    await env.signIn('librarian@zut.demo');
    final l = env.store.loans.find('t_zut', 'l_zut_02')!;
    expect(l.status, LoanStatus.approved);
    final copyId = l.copyId!;
    await env.services.auth.signOut();
    await env.signIn('platform@zutlib.demo');
    await env.services.platform.advanceClock(const Duration(days: 2));
    expect(l.status, LoanStatus.expired);
    expect(env.store.copies.find('t_zut', copyId)!.status, CopyStatus.available);
    await env.services.auth.signOut();
    await env.signIn('librarian@zut.demo');
    expect(() => loans.collect(l.qrToken!),
        throwsA(isA<RuleException>().having((e) => e.message, 'message', contains('expired'))));
  });

  test('reject requires a reason that the student can see (FR-BOR-04)', () async {
    final env = await createEnv();
    await env.signIn('librarian@zut.demo');
    expect(() => env.services.loans.reject('l_zut_01', ' '), throwsA(isA<ValidationException>()));
    await env.services.loans.reject('l_zut_01', 'All copies are at the bindery.');
    final l = env.store.loans.find('t_zut', 'l_zut_01')!;
    expect(l.status, LoanStatus.rejected);
    expect(l.rejectionReason, 'All copies are at the bindery.');
  });

  test('student can cancel an approved loan and the copy is released (FR-BOR-10)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    final loan = await env.services.loans.request(paper);
    await env.services.auth.signOut();
    await env.signIn('librarian@zut.demo');
    await env.services.loans.approve(loan.id);
    final copyId = loan.copyId!;
    await env.services.auth.signOut();
    await env.signIn('student@zut.demo');
    await env.services.loans.cancel(loan.id);
    expect(loan.status, LoanStatus.cancelled);
    expect(env.store.copies.find('t_zut', copyId)!.status, CopyStatus.available);
  });

  test('another student cannot cancel my loan', () async {
    final env = await createEnv();
    await env.signIn('student2@zut.demo');
    expect(() => env.services.loans.cancel('l_zut_03'), throwsA(isA<PermissionDeniedException>()));
  });

  test('return by code and by button makes the copy available (FR-BOR-09)', () async {
    final env = await createEnv();
    await env.signIn('librarian@zut.demo');
    final l = env.store.loans.find('t_zut', 'l_zut_03')!;
    await env.services.loans.returnByCode(l.qrToken!);
    expect(l.status, LoanStatus.returned);
    expect(l.returnedAt, isNotNull);
    expect(env.store.copies.find('t_zut', l.copyId!)!.status, CopyStatus.available);
    await env.services.loans.markReturned('l_zut_05');
    expect(env.store.loans.find('t_zut', 'l_zut_05')!.status, LoanStatus.returned);
  });

  test('one renewal of 7 days after librarian approval (FR-BOR-11)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    final l = env.store.loans.find('t_zut', 'l_zut_03')!;
    final due = l.dueAt!;
    await env.services.loans.requestRenewal(l.id);
    await env.services.auth.signOut();
    await env.signIn('librarian@zut.demo');
    await env.services.loans.decideRenewal(l.id, approve: true);
    expect(l.dueAt, due.add(const Duration(days: 7)));
    await env.services.auth.signOut();
    await env.signIn('student@zut.demo');
    expect(() => env.services.loans.requestRenewal(l.id), throwsA(isA<RuleException>()));
  });

  test('loan records hold no ID document fields (FR-BOR-13)', () async {
    final env = await createEnv();
    final keys = env.store.loans.unscoped.first.toJson().keys.join(' ').toLowerCase();
    for (final banned in ['nrc', 'national', 'passport', 'idnumber']) {
      expect(keys.contains(banned), isFalse);
    }
  });

  test('librarians are notified of new requests (FR-NOT-04)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    await env.services.loans.request(paper);
    await env.services.auth.signOut();
    await env.signIn('librarian@zut.demo');
    expect(env.services.notifications.mine().first.title, 'New borrowing request');
    expect(env.notifier.shown, contains('New borrowing request'));
  });

  test('CSV export has a header and one row per loan (FR-ADM-07)', () async {
    final env = await createEnv();
    await env.signIn('admin@zut.demo');
    final lines = env.services.loans.exportCsv().split('\n');
    expect(lines.first, startsWith('Loan ID,Student,'));
    expect(lines.length, env.store.loans.of('t_zut').length + 1);
  });
}
