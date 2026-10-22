import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
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
        icon: Icons.assignment_outlined,
        message: 'No loans yet. Open a paper and tap Request copy to borrow a printed copy.',
        actionLabel: 'Search papers',
        onAction: () => StudentShell.goToTab(context, 1),
      );
    }
    return ListView(
      children: [
        const SectionHeader('Active'),
        if (active.isEmpty) const ListTile(title: Text('No active loans.')),
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
    return ListTile(
      title: Text(course == null ? r.title : '${course.code} ${r.paperType.label} ${r.academicYear}'),
      subtitle: Text(detail),
      trailing: StatusChip(loan.status),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoanDetailsScreen(loanId: loan.id))),
    );
  }
}
