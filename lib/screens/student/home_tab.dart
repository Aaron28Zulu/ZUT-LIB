import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/clock.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/resource_tile.dart';
import '../common/loan_details_screen.dart';
import 'quiz_setup_screen.dart';
import 'revision_plan_screen.dart';
import 'student_shell.dart';

/// Recommendations, active loans and today's study sessions (demo step 1).
/// Laid out like a course platform's home: greeting, "continue learning",
/// a shelf of recommendations, then the things that need attention.
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.user!;
    final recs = app.study.recommendations();
    final active = app.loans.myLoans().where((l) => l.status.isActive).toList();
    final today = app.study.todaysSessions();
    final progress = app.study.planProgress();
    final courses = {for (final c in app.study.enrolledCourses()) c.id: c};
    final t = Theme.of(context).textTheme;
    final s = Theme.of(context).colorScheme;
    void push(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    return ListView(
      padding: const EdgeInsets.only(bottom: Space.xxl),
      children: [
        PageHeader('Welcome back, ${user.firstName}', subtitle: _examLine(app)),

        // Continue studying: today's plan with a single clear next action.
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, 0),
          child: Panel(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, 0),
                  child: Text('TODAY\'S PLAN', style: AppText.overline(context)),
                ),
                ProgressRow(
                  label: today.isEmpty ? 'No sessions planned for today' : '${today.where((x) => x.done).length} of ${today.length} sessions done today',
                  value: today.isEmpty ? progress : today.where((x) => x.done).length / today.length,
                  caption: '${(progress * 100).round()}% of your whole revision plan is complete',
                ),
                for (final x in today)
                  CheckboxListTile(
                    value: x.done,
                    onChanged: (v) => app.study.setSessionDone(x.id, v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      '${courses[x.courseId]?.code ?? ''} · ${x.topic}',
                      style: t.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration: x.done ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text('${formatTime(x.scheduledAt)} · ${x.durationMinutes} min'),
                  ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(Space.s),
                  child: Wrap(
                    spacing: Space.s,
                    children: [
                      TextButton.icon(
                        onPressed: () => push(const QuizSetupScreen()),
                        icon: const Icon(AppIcons.quiz, size: 18),
                        label: const Text('Practice quiz'),
                      ),
                      TextButton.icon(
                        onPressed: () => push(const RevisionPlanScreen()),
                        icon: const Icon(AppIcons.plan, size: 18),
                        label: const Text('Revision plan'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        SectionHeader(
          'Recommended for you',
          subtitle: 'Based on your courses and exam dates',
          trailing: TextButton(onPressed: () => StudentShell.goToTab(context, 1), child: const Text('Browse')),
        ),
        if (recs.isEmpty)
          const Padding(
            padding: Space.screen,
            child: Text('Add your courses and exam dates in your profile to get recommendations.'),
          )
        else
          Shelf(children: [for (final r in recs) ResourceCard(r.resource, reason: r.reason)]),

        SectionHeader(
          'Your loans',
          trailing: TextButton(onPressed: () => StudentShell.goToTab(context, 3), child: const Text('See all')),
        ),
        if (active.isEmpty)
          Padding(
            padding: Space.screen,
            child: Text('No active loans. Request a printed copy from any paper page.', style: AppText.muted(context)),
          )
        else
          for (final (i, l) in active.indexed) ...[
            if (i > 0) const Divider(indent: Space.l, endIndent: Space.l),
            ListTile(
              title: Text(app.loans.resourceFor(l).title, maxLines: 2, style: t.titleSmall),
              subtitle: Text(
                l.dueAt == null ? 'Requested ${formatRelative(l.requestedAt)}' : 'Due ${formatRelative(l.dueAt!)}',
                style: AppText.muted(context),
              ),
              trailing: StatusChip(l.status),
              onTap: () => push(LoanDetailsScreen(loanId: l.id)),
            ),
          ],
        if (active.isEmpty && today.isEmpty && recs.isEmpty)
          Padding(
            padding: const EdgeInsets.all(Space.l),
            child: Text('Tip: search by course code, for example ICT 2201.', style: t.bodySmall?.copyWith(color: s.onSurfaceVariant)),
          ),
      ],
    );
  }

  String _examLine(AppState app) {
    final u = app.user!;
    final upcoming = u.examDates.entries.where((e) => e.value.isAfter(Clock.now())).toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    if (upcoming.isEmpty) return 'Pick up where you left off.';
    final course = app.study.enrolledCourses().where((c) => c.id == upcoming.first.key).firstOrNull;
    if (course == null) return 'Pick up where you left off.';
    return 'Your next exam is ${course.code}, ${formatRelative(upcoming.first.value)}.';
  }
}
