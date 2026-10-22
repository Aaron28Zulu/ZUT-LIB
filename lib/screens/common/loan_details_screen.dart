import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/app_icons.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/rules.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';
import 'paper_details_screen.dart';

/// Loan details with the collection QR for students and actions for staff.
class LoanDetailsScreen extends StatelessWidget {
  const LoanDetailsScreen({super.key, required this.loanId});

  final String loanId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final Loan l;
    try {
      l = app.loans.loan(loanId);
    } on AppException catch (e) {
      return Scaffold(appBar: AppBar(), body: Readable(child: EmptyState(icon: AppIcons.loans, message: e.message)));
    }
    final isStudent = app.user!.role == Role.student;
    final r = app.loans.resourceFor(l);
    final copy = app.loans.copyFor(l);
    final course = app.resources.course(r.courseId);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Loan')),
      body: Readable(child: ListView(
        padding: const EdgeInsets.only(bottom: Space.xxl),
        children: [
          ListTile(
            title: Text(r.title),
            subtitle: Text(course?.name ?? ''),
            trailing: const Icon(AppIcons.next),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PaperDetailsScreen(resourceId: r.id)),
            ),
          ),
          Padding(padding: Space.screen, child: Align(alignment: Alignment.centerLeft, child: StatusChip(l.status))),
          if (isStudent && l.status == LoanStatus.approved && l.qrToken != null) _CollectionCode(loan: l),
          if (l.status == LoanStatus.rejected && l.rejectionReason != null)
            Padding(
              padding: const EdgeInsets.all(Space.l),
              child: Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(Space.l),
                  child: Text('Reason: ${l.rejectionReason}'),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(Space.l),
            child: Column(
              children: [
                if (!isStudent) InfoRow('Student', app.loans.studentName(l)),
                InfoRow('Requested', formatDateTime(l.requestedAt)),
                if (l.approvedAt != null) InfoRow('Approved', formatDateTime(l.approvedAt!)),
                if (copy != null) InfoRow('Copy', 'Copy ${copy.copyNumber}, shelf ${copy.shelfLocation}'),
                if (l.collectedAt != null) InfoRow('Collected', formatDateTime(l.collectedAt!)),
                if (l.dueAt != null) InfoRow('Due', '${formatDate(l.dueAt!)} (${formatRelative(l.dueAt!)})'),
                if (l.returnedAt != null) InfoRow('Returned', formatDateTime(l.returnedAt!)),
                if (l.renewalCount > 0) const InfoRow('Renewed', 'Once'),
                if (l.renewalRequested) const InfoRow('Renewal', 'Waiting for the librarian'),
              ],
            ),
          ),
          if (isStudent) _StudentActions(loan: l) else _StaffActions(loan: l),
          if (!isStudent && l.qrToken != null)
            Padding(
              padding: Space.screen,
              child: Text('Collection code ${l.qrToken}${l.qrUsed ? ' (used)' : ''}', style: t.bodySmall),
            ),
        ],
      )),
    );
  }
}

class _CollectionCode extends StatelessWidget {
  const _CollectionCode({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final expires = loan.approvedAt!.add(Rules.collectionWindow);
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(Space.l),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Column(
            children: [
              Text('Show this at the library desk', style: t.titleSmall),
              const SizedBox(height: Space.m),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(Space.s),
                child: QrImageView(
                  data: loan.qrPayload!,
                  size: 200,
                  semanticsLabel: 'Collection QR code for this loan',
                ),
              ),
              const SizedBox(height: Space.m),
              SelectableText(loan.qrToken!, style: t.headlineSmall?.copyWith(letterSpacing: 4)),
              const SizedBox(height: Space.xs),
              Text('Collect by ${formatDateTime(expires)} (${formatRelative(expires)}). The code works once.',
                  textAlign: TextAlign.center, style: t.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentActions extends StatelessWidget {
  const _StudentActions({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final l = loan;
    final canCancel = l.status == LoanStatus.requested || l.status == LoanStatus.approved;
    final canRenew = l.status == LoanStatus.collected && l.renewalCount < Rules.maxRenewals && !l.renewalRequested;
    if (!canCancel && !canRenew) return const SizedBox.shrink();
    return Padding(
      padding: Space.screen,
      child: Wrap(
        spacing: Space.s,
        children: [
          if (canRenew)
            OutlinedButton(
              onPressed: () => runAction(context, () => app.loans.requestRenewal(l.id),
                  success: 'Renewal requested. The librarian will review it.'),
              child: const Text('Request 7-day renewal'),
            ),
          if (canCancel)
            TextButton(
              onPressed: () async {
                if (await confirm(context,
                        title: 'Cancel this loan?',
                        message: 'The copy will be released for other students.',
                        action: 'Cancel loan',
                        destructive: true) &&
                    context.mounted) {
                  await runAction(context, () => app.loans.cancel(l.id), success: 'Loan cancelled.');
                }
              },
              child: const Text('Cancel loan'),
            ),
        ],
      ),
    );
  }
}

class _StaffActions extends StatelessWidget {
  const _StaffActions({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final l = loan;
    final buttons = <Widget>[
      if (l.status == LoanStatus.requested) ...[
        FilledButton(
          onPressed: () => runAction(context, () => app.loans.approve(l.id), success: 'Approved. The student has a collection code.'),
          child: const Text('Approve'),
        ),
        OutlinedButton(
          onPressed: () async {
            final reason = await promptText(context, title: 'Reject request', label: 'Reason for the student', action: 'Reject');
            if (reason != null && context.mounted) {
              await runAction(context, () => app.loans.reject(l.id, reason), success: 'Request rejected.');
            }
          },
          child: const Text('Reject'),
        ),
      ],
      if (l.status == LoanStatus.collected || l.status == LoanStatus.overdue)
        FilledButton(
          onPressed: () => runAction(context, () => app.loans.markReturned(l.id), success: 'Marked returned.'),
          child: const Text('Mark returned'),
        ),
      if (l.renewalRequested) ...[
        FilledButton(
          onPressed: () => runAction(context, () => app.loans.decideRenewal(l.id, approve: true), success: 'Renewal approved.'),
          child: const Text('Approve renewal'),
        ),
        OutlinedButton(
          onPressed: () => runAction(context, () => app.loans.decideRenewal(l.id, approve: false), success: 'Renewal declined.'),
          child: const Text('Decline renewal'),
        ),
      ],
    ];
    if (buttons.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: Space.screen,
      child: Wrap(spacing: Space.s, runSpacing: Space.s, children: buttons),
    );
  }
}
