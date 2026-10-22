import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';
import 'profile_setup_screen.dart';

/// FR-SSA-09, FR-SSA-10: dated sessions per course with percentage complete.
class RevisionPlanScreen extends StatelessWidget {
  const RevisionPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final study = app.study;
    final plan = study.plan();
    final courses = {for (final c in study.enrolledCourses()) c.id: c};
    final progress = study.planProgress();
    final byDay = <String, List<StudyPlanSession>>{};
    for (final s in plan) {
      byDay.putIfAbsent(formatDay(s.scheduledAt), () => []).add(s);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revision plan'),
        actions: [
          IconButton(
            tooltip: 'Rebuild plan',
            icon: const Icon(Icons.refresh),
            onPressed: () => runAction(context, study.regeneratePlan,
                success: 'Plan rebuilt from your exam dates and study times.'),
          ),
        ],
      ),
      body: plan.isEmpty
          ? EmptyState(
              icon: Icons.event_note_outlined,
              message: 'No sessions planned. Add exam dates and preferred study times to build a plan.',
              actionLabel: 'Edit study profile',
              onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen())),
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: Space.xl),
              children: [
                Padding(
                  padding: const EdgeInsets.all(Space.l),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${(progress * 100).round()}% complete', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: Space.s),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: Space.s),
                      Text(
                        'Nearer exams and your weaker topics get more sessions.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                for (final entry in byDay.entries) ...[
                  SectionHeader(entry.key),
                  for (final s in entry.value)
                    CheckboxListTile(
                      value: s.done,
                      onChanged: (v) => study.setSessionDone(s.id, v ?? false),
                      title: Text('${courses[s.courseId]?.code ?? ''}: ${s.topic}'),
                      subtitle: Text('${formatTime(s.scheduledAt)}, ${s.durationMinutes} minutes'),
                    ),
                ],
              ],
            ),
    );
  }
}
