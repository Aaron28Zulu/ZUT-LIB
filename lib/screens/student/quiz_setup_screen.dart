import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors.dart';
import '../../core/rules.dart';
import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';
import 'quiz_screen.dart';

/// FR-SSA-01: course, length and optional topic.
class QuizSetupScreen extends StatefulWidget {
  const QuizSetupScreen({super.key, this.courseId, this.topic});

  final String? courseId;
  final String? topic;

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  String? _courseId;
  String? _topic;
  int _count = 5;

  @override
  void initState() {
    super.initState();
    _courseId = widget.courseId;
    _topic = widget.topic;
  }

  @override
  Widget build(BuildContext context) {
    final study = context.watch<AppState>().study;
    final courses = study.enrolledCourses().where((c) => study.questionCount(c.id) > 0).toList();
    _courseId ??= courses.firstOrNull?.id;
    final topics = _courseId == null ? <String>[] : study.topicsFor(_courseId!);
    final available = _courseId == null ? 0 : study.questionCount(_courseId!, topic: _topic);

    return Scaffold(
      appBar: AppBar(title: const Text('Practice quiz')),
      body: courses.isEmpty
          ? const EmptyState(
              icon: Icons.quiz_outlined,
              message: 'None of your courses has practice questions yet. Add courses in your profile.',
            )
          : ListView(
              padding: const EdgeInsets.all(Space.l),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _courseId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Course'),
                  items: [for (final c in courses) DropdownMenuItem(value: c.id, child: Text(c.label))],
                  onChanged: (v) => setState(() {
                    _courseId = v;
                    _topic = null;
                  }),
                ),
                const SizedBox(height: Space.l),
                DropdownButtonFormField<String?>(
                  initialValue: _topic,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Topic',
                    helperText: 'All topics favours the ones you score lowest on',
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All topics')),
                    for (final t in topics) DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: (v) => setState(() => _topic = v),
                ),
                const SizedBox(height: Space.xl),
                Text('Number of questions', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: Space.s),
                SegmentedButton<int>(
                  segments: [for (final n in Rules.quizLengths) ButtonSegment(value: n, label: Text('$n'))],
                  selected: {_count},
                  onSelectionChanged: (s) => setState(() => _count = s.first),
                ),
                if (available < _count)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.s),
                    child: Text('Only $available questions are available, so the quiz will be shorter.'),
                  ),
                const SizedBox(height: Space.xl),
                FilledButton(
                  onPressed: _courseId == null
                      ? null
                      : () {
                          try {
                            final session = study.startQuiz(_courseId!, _count, topic: _topic);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => QuizScreen(session: session)),
                            );
                          } on AppException catch (e) {
                            showMessage(context, e.message);
                          }
                        },
                  child: const Text('Start quiz'),
                ),
              ],
            ),
    );
  }
}
