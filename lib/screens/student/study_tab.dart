import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'ask_assistant_screen.dart';
import 'flashcards_screen.dart';
import 'progress_screen.dart';
import 'quiz_setup_screen.dart';
import 'revision_plan_screen.dart';

/// Study hub (SRS 8), laid out like "My learning" on a course platform:
/// progress first, then the study tools, then what to work on next.
class StudyTab extends StatelessWidget {
  const StudyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final study = app.study;
    final courses = study.enrolledCourses();
    final progress = study.planProgress();
    final stats = study.topicStats();
    // Only topics with enough answers to mean something.
    final weak = stats.where((s) => s.percent < 60 && s.answered >= 3).take(3).toList();
    final codes = {for (final c in courses) c.id: c.code};
    final attempts = study.attempts();

    void open(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));

    return ListView(
      padding: const EdgeInsets.only(bottom: Space.xxl),
      children: [
        PageHeader(
          'My learning',
          subtitle: '${courses.length} ${courses.length == 1 ? 'course' : 'courses'} · '
              '${attempts.length} ${attempts.length == 1 ? 'quiz' : 'quizzes'} taken',
        ),
        ProgressRow(
          label: 'Revision plan',
          value: progress,
          caption: 'Planned sessions marked done',
        ),
        const SizedBox(height: Space.s),
        const Divider(),
        _Tool(
          icon: AppIcons.quiz,
          title: 'Practice quiz',
          subtitle: '5, 10 or 20 questions from past papers, with feedback on each answer',
          onTap: () => open(const QuizSetupScreen()),
        ),
        _Tool(
          icon: AppIcons.flashcards,
          title: 'Flashcards',
          subtitle: 'Key terms. Cards you mark hard come back sooner',
          onTap: () => open(const FlashcardCoursePicker()),
        ),
        _Tool(
          icon: AppIcons.plan,
          title: 'Revision plan',
          subtitle: 'Dated sessions for each course up to your exams',
          onTap: () => open(const RevisionPlanScreen()),
        ),
        _Tool(
          icon: AppIcons.progress,
          title: 'Progress',
          subtitle: 'Quiz scores over time and topic strengths',
          onTap: () => open(const ProgressScreen()),
        ),
        _Tool(
          icon: AppIcons.assistant,
          title: 'Ask the assistant',
          subtitle: 'Common questions answered from the paper library',
          onTap: () => open(const AskAssistantScreen()),
        ),
        if (weak.isNotEmpty) ...[
          const SectionHeader('Topics to work on', subtitle: 'Below 60% in your quizzes. Tap to practise'),
          for (final w in weak)
            InkWell(
              onTap: () => open(QuizSetupScreen(courseId: w.courseId, topic: w.topic)),
              child: ProgressRow(
                label: '${codes[w.courseId] ?? ''} · ${w.topic}',
                value: w.percent / 100,
                caption: '${w.answered} questions answered',
                colour: AppPalette.of(context).warning,
              ),
            ),
        ],
      ],
    );
  }
}

/// One study tool: tinted icon square, title, one-line description.
class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.xs),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: s.primaryContainer, borderRadius: Radii.controlRadius),
            child: Icon(icon, color: s.onPrimaryContainer, size: 20),
          ),
          title: Text(title, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text(subtitle),
          trailing: const Icon(AppIcons.next, size: 18),
          onTap: onTap,
        ),
        const Divider(indent: 76),
      ],
    );
  }
}
