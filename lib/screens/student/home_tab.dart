import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/clock.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/resource_tile.dart';
import '../common/loan_details_screen.dart';
import 'revision_plan_screen.dart';
import 'student_shell.dart';

/// Recommendations, active loans and today's study sessions (demo step 1).
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.user!;
    final recs = app.study.recommendations();
    final active = app.loans.myLoans().where((l) => l.status.isActive).toList();
    final today = app.study.todaysSessions();
    final courses = {for (final c in app.study.enrolledCourses()) c.id: c};
    final t = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.only(bottom: Space.xl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
          child: Text('Hello ${user.firstName}. ${_examLine(app)}', style: t.bodyLarge),
        ),
        const SectionHeader('Recommended papers'),
        if (recs.isEmpty)
          const Padding(
            padding: Space.screen,
            child: Text('Add your courses and exam dates in your profile to get recommendations.'),
          )
        else
          for (final r in recs) ResourceTile(r.resource, subtitle: r.reason, showAvailability: false),
        SectionHeader(
          'Active loans',
          trailing: TextButton(onPressed: () => StudentShell.goToTab(context, 3), child: const Text('All loans')),
        ),
        if (active.isEmpty)
          const Padding(padding: Space.screen, child: Text('No active loans.'))
        else
          for (final l in active)
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: Text(app.loans.resourceFor(l).title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(l.dueAt == null ? 'Requested ${formatRelative(l.requestedAt)}' : 'Due ${formatRelative(l.dueAt!)}'),
              trailing: StatusChip(l.status),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LoanDetailsScreen(loanId: l.id)),
              ),
            ),
        SectionHeader(
          "Today's study sessions",
          trailing: TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RevisionPlanScreen())),
            child: const Text('Revision plan'),
          ),
        ),
        if (today.isEmpty)
          const Padding(padding: Space.screen, child: Text('No sessions planned for today.'))
        else
          for (final s in today)
            CheckboxListTile(
              value: s.done,
              onChanged: (v) => app.study.setSessionDone(s.id, v ?? false),
              title: Text('${courses[s.courseId]?.code ?? ''}: ${s.topic}'),
              subtitle: Text('${formatTime(s.scheduledAt)}, ${s.durationMinutes} minutes'),
            ),
      ],
    );
  }

  String _examLine(AppState app) {
    final u = app.user!;
    final upcoming = u.examDates.entries.where((e) => e.value.isAfter(Clock.now())).toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (upcoming.isEmpty) return '';
    final course = app.study.enrolledCourses().where((c) => c.id == upcoming.first.key).firstOrNull;
    if (course == null) return '';
    return 'Your next exam is ${course.code}, ${formatRelative(upcoming.first.value)}.';
  }
}
