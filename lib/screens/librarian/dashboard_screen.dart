import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/format.dart';
import '../../core/permissions.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../common/loan_details_screen.dart';
import '../common/paper_details_screen.dart';
import 'loans_list_screen.dart';
import 'request_queue_screen.dart';

/// Librarian dashboard (pending, due today, overdue) and, for institution
/// administrators, the full tenant report (FR-ADM-03).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final d = app.admin.dashboard();
    final full = roleAllows(app.user!.role, Permission.viewTenantReports);
    final overdue = app.loans.tenantLoans(status: LoanStatus.overdue);

    void open(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    return ListView(
      padding: const EdgeInsets.only(top: Space.l, bottom: Space.xl),
      children: [
        StatGrid([
          StatTile('Pending requests', d.pendingRequests, onTap: () => open(const RequestQueueScreen())),
          StatTile('Due today', d.dueToday),
          StatTile('Overdue loans', d.overdueLoans, highlight: true,
              onTap: () => open(const LoansListScreen(initialStatus: LoanStatus.overdue, standalone: true))),
          StatTile('Active loans', d.activeLoans, onTap: () => open(const LoansListScreen(standalone: true))),
          StatTile('Papers in library', d.totalResources),
          StatTile('Paper views', d.views),
          if (full) ...[
            StatTile('Searches', d.searches),
            StatTile('Quiz attempts', d.quizAttempts),
          ],
        ]),
        if (overdue.isNotEmpty) ...[
          const SectionHeader('Overdue'),
          for (final l in overdue)
            ListTile(
              title: Text(app.loans.resourceFor(l).title, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${app.loans.studentName(l)} · due ${formatRelative(l.dueAt!)}'),
              trailing: const StatusChip(LoanStatus.overdue),
              onTap: () => open(LoanDetailsScreen(loanId: l.id)),
            ),
        ],
        const SectionHeader('Most viewed papers'),
        if (d.mostViewed.isEmpty) const ListTile(title: Text('No views recorded yet.')),
        for (final (i, item) in d.mostViewed.indexed)
          ListTile(
            leading: Text('${i + 1}', style: AppText.code(context)),
            title: Text(item.label),
            trailing: Text('${item.count}', style: AppText.code(context)),
            onTap: item.refId == null ? null : () => open(PaperDetailsScreen(resourceId: item.refId!)),
          ),
        if (full) ...[
          const SectionHeader('Most frequent unmet searches'),
          if (d.unmetSearches.isEmpty) const ListTile(title: Text('Every search found at least one paper.')),
          for (final item in d.unmetSearches)
            ListTile(
              leading: const Icon(AppIcons.noResults),
              title: Text(item.label),
              trailing: Text('${item.count}', style: AppText.code(context)),
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
            child: Text('Unmet searches show which papers students look for but the library does not have.'),
          ),
        ],
      ],
    );
  }
}
