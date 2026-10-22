import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'ask_assistant_screen.dart';
import 'flashcards_screen.dart';
import 'progress_screen.dart';
import 'quiz_setup_screen.dart';
import 'revision_plan_screen.dart';

/// Study hub (SRS 8).
class StudyTab extends StatelessWidget {
  const StudyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final study = app.study;
    final courses = study.enrolledCourses();
    final progress = study.planProgress();
    // Only topics with enough answers to mean something.
    final weak = study.topicStats().where((s) => s.percent < 60 && s.answered >= 3).take(3).toList();
    final codes = {for (final c in courses) c.id: c.code};

    void open(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    return ListView(
      padding: const EdgeInsets.only(bottom: Space.xl),
      children: [
        ListTile(
          leading: const Icon(Icons.quiz_outlined),
          title: const Text('Practice quiz'),
          subtitle: const Text('5, 10 or 20 questions from past papers'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => open(const QuizSetupScreen()),
        ),
        ListTile(
          leading: const Icon(Icons.style_outlined),
          title: const Text('Flashcards'),
          subtitle: const Text('Key terms; hard cards come back sooner'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => open(const FlashcardCoursePicker()),
        ),
        ListTile(
          leading: const Icon(Icons.event_note_outlined),
          title: const Text('Revision plan'),
          subtitle: Text('${(progress * 100).round()}% of planned sessions done'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => open(const RevisionPlanScreen()),
        ),
        ListTile(
          leading: const Icon(Icons.show_chart),
          title: const Text('Progress'),
          subtitle: const Text('Quiz scores and topic strengths'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => open(const ProgressScreen()),
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Ask the assistant'),
          subtitle: const Text('Common questions answered from the paper library'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => open(const AskAssistantScreen()),
        ),
        if (weak.isNotEmpty) ...[
          const SectionHeader('Topics to work on'),
          for (final w in weak)
            ListTile(
              dense: true,
              title: Text('${codes[w.courseId] ?? ''} ${w.topic}'),
              trailing: Text('${w.percent}%', style: AppText.code(context)),
              onTap: () => open(QuizSetupScreen(courseId: w.courseId, topic: w.topic)),
            ),
        ],
      ],
    );
  }
}
