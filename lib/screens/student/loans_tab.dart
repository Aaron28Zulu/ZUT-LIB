import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/format.dart';
import '../../core/rules.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../common/loan_details_screen.dart';
import 'student_shell.dart';

/// Active loans and history (FR-BOR-12).
class LoansTab extends StatelessWidget {
  const LoansTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final loans = app.loans.myLoans();
    final active = loans.where((l) => l.status.isActive).toList();
    final history = loans.where((l) => !l.status.isActive).toList();
    if (loans.isEmpty) {
      return EmptyState(
        icon: AppIcons.loans,
        message: 'No loans yet. Open a paper and tap Request copy to borrow a printed copy.',
        actionLabel: 'Search papers',
        onAction: () => StudentShell.goToTab(context, 1),
      );
    }
    return ListView(
      children: [
        PageHeader('My loans', subtitle: '${active.length} active · loans run for ${Rules.loanPeriod.inDays} days from collection'),
        const SectionHeader('Active'),
        if (active.isEmpty) Padding(padding: Space.screen, child: Text('No active loans.', style: AppText.muted(context))),
        for (final l in active) _LoanTile(l),
        if (history.isNotEmpty) ...[
          const SectionHeader('History'),
          for (final l in history) _LoanTile(l),
        ],
      ],
    );
  }
}

class _LoanTile extends StatelessWidget {
  const _LoanTile(this.loan);

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final r = app.loans.resourceFor(loan);
    final course = app.resources.course(r.courseId);
    final detail = switch (loan.status) {
      LoanStatus.requested => 'Requested ${formatRelative(loan.requestedAt)}',
      LoanStatus.approved => 'Ready to collect. Code ${loan.qrToken}',
      LoanStatus.collected || LoanStatus.overdue => 'Due ${formatDate(loan.dueAt!)}',
      LoanStatus.returned => 'Returned ${formatDate(loan.returnedAt!)}',
      LoanStatus.rejected => loan.rejectionReason ?? 'Rejected',
      _ => formatDate(loan.requestedAt),
    };
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoanDetailsScreen(loanId: loan.id))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PaperThumb(code: course?.code ?? '', caption: '${r.academicYear}', width: 48, height: 60),
                const SizedBox(width: Space.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course == null ? r.title : '${course.code} ${course.name}', style: t.titleSmall, maxLines: 2),
                      const SizedBox(height: 2),
                      Text('${r.paperType.label} ${r.academicYear}', style: AppText.muted(context)),
                      const SizedBox(height: Space.s),
                      Wrap(
                        spacing: Space.s,
                        runSpacing: Space.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [StatusChip(loan.status), Text(detail, style: t.bodySmall)],
                      ),
                    ],
                  ),
                ),
                const Padding(padding: EdgeInsets.only(top: Space.s), child: Icon(AppIcons.next, size: 18)),
              ],
            ),
          ),
        ),
        const Divider(indent: Space.l, endIndent: Space.l),
      ],
    );
  }
}
