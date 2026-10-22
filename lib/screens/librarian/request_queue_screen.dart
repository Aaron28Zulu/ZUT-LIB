import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';
import '../common/loan_details_screen.dart';

/// FR-BOR-04: approve or reject pending requests; rejection needs a reason.
class RequestQueueScreen extends StatelessWidget {
  const RequestQueueScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final pending = app.loans.pendingRequests();
    final renewals = app.loans.renewalRequests();

    final body = pending.isEmpty && renewals.isEmpty
        ? const EmptyState(icon: AppIcons.inbox, message: 'No requests waiting. New requests appear here.')
        : ListView(
            padding: const EdgeInsets.only(bottom: Space.xl),
            children: [
              if (pending.isNotEmpty) SectionHeader('Borrowing requests (${pending.length})'),
              for (final l in pending) _RequestCard(loan: l),
              if (renewals.isNotEmpty) SectionHeader('Renewal requests (${renewals.length})'),
              for (final l in renewals) _RenewalTile(loan: l),
            ],
          );
    return embedded ? body : Scaffold(appBar: AppBar(title: const Text('Request queue')), body: Readable(child: body));
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final r = app.loans.resourceFor(loan);
    final available = app.resources.availableCopies(r.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.s),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoanDetailsScreen(loanId: loan.id))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.title, style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: Space.xs),
                    Text('${app.loans.studentName(loan)} · requested ${formatRelative(loan.requestedAt)}'),
                    Text(available == 0 ? 'No copy free to reserve' : '$available ${available == 1 ? 'copy' : 'copies'} free'),
                  ],
                ),
              ),
              const SizedBox(height: Space.m),
              Row(
                children: [
                  FilledButton(
                    onPressed: available == 0
                        ? null
                        : () => runAction(context, () => app.loans.approve(loan.id),
                            success: 'Approved. The student has a collection code.'),
                    child: const Text('Approve'),
                  ),
                  const SizedBox(width: Space.s),
                  OutlinedButton(
                    onPressed: () async {
                      final reason = await promptText(context,
                          title: 'Reject request', label: 'Reason for the student', action: 'Reject');
                      if (reason != null && context.mounted) {
                        await runAction(context, () => app.loans.reject(loan.id, reason), success: 'Request rejected.');
                      }
                    },
                    child: const Text('Reject'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RenewalTile extends StatelessWidget {
  const _RenewalTile({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return ListTile(
      title: Text(app.loans.resourceFor(loan).title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text('${app.loans.studentName(loan)} · due ${formatDate(loan.dueAt!)}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Decline renewal',
            icon: const Icon(AppIcons.close),
            onPressed: () => runAction(context, () => app.loans.decideRenewal(loan.id, approve: false), success: 'Renewal declined.'),
          ),
          IconButton(
            tooltip: 'Approve renewal',
            icon: const Icon(AppIcons.check),
            onPressed: () => runAction(context, () => app.loans.decideRenewal(loan.id, approve: true), success: 'Renewal approved.'),
          ),
        ],
      ),
    );
  }
}
