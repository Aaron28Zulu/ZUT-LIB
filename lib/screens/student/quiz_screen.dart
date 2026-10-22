import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/study_assistant_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'quiz_setup_screen.dart';

/// One question at a time with feedback after each answer (FR-SSA-02, 03).
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.session});

  final QuizSession session;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _index = 0;
  String? _selected;
  AnswerFeedback? _feedback;
  final _shortAnswer = TextEditingController();

  @override
  void dispose() {
    _shortAnswer.dispose();
    super.dispose();
  }

  Question get _q => widget.session.questions[_index];

  void _check() {
    final answer = _q.type == QuestionType.shortAnswer ? _shortAnswer.text : _selected;
    if (answer == null || answer.trim().isEmpty) return;
    setState(() => _feedback = context.read<AppState>().study.answer(widget.session, _q, answer));
  }

  Future<void> _next() async {
    if (_index < widget.session.questions.length - 1) {
      setState(() {
        _index++;
        _selected = null;
        _feedback = null;
        _shortAnswer.clear();
      });
      return;
    }
    final attempt = await context.read<AppState>().study.finishQuiz(widget.session);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QuizResultsScreen(attempt: attempt)));
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.session.questions.length;
    final fb = _feedback;
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text('Question ${_index + 1} of $total')),
      body: ListView(
        padding: const EdgeInsets.all(Space.l),
        children: [
          LinearProgressIndicator(value: (_index + (fb == null ? 0 : 1)) / total),
          const SizedBox(height: Space.l),
          Text('${_q.topic} · ${_q.type.label}', style: AppText.overline(context)),
          const SizedBox(height: Space.s),
          Text(_q.text, style: t.titleMedium),
          const SizedBox(height: Space.l),
          if (_q.type == QuestionType.shortAnswer)
            TextField(
              controller: _shortAnswer,
              enabled: fb == null,
              decoration: const InputDecoration(labelText: 'Your answer'),
              onSubmitted: (_) => _check(),
            )
          else
            RadioGroup<String>(
              groupValue: _selected,
              onChanged: (v) {
                if (fb == null) setState(() => _selected = v);
              },
              child: Column(
                children: [
                  for (final o in _q.options)
                    RadioListTile<String>(
                      value: o,
                      enabled: fb == null,
                      title: Text(o),
                      secondary: fb == null
                          ? null
                          : o == fb.correctAnswer
                              ? Icon(Icons.check_circle_outline, color: scheme.primary, semanticLabel: 'Correct answer')
                              : o == _selected
                                  ? Icon(Icons.cancel_outlined, color: scheme.error, semanticLabel: 'Your answer')
                                  : null,
                    ),
                ],
              ),
            ),
          if (fb != null) ...[
            const SizedBox(height: Space.l),
            Card(
              color: fb.correct ? scheme.primaryContainer : scheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(Space.l),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fb.correct ? 'Correct' : 'Not quite', style: t.titleSmall),
                    if (!fb.correct) ...[
                      const SizedBox(height: Space.xs),
                      Text('Answer: ${fb.correctAnswer}'),
                    ],
                    const SizedBox(height: Space.s),
                    Text(fb.explanation),
                    const SizedBox(height: Space.s),
                    Text('From ${fb.sourceLabel}', style: t.bodySmall),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(Space.l),
          child: fb == null
              ? FilledButton(onPressed: _check, child: const Text('Check answer'))
              : FilledButton(
                  onPressed: _next,
                  child: Text(_index == total - 1 ? 'See results' : 'Next question'),
                ),
        ),
      ),
    );
  }
}

/// FR-SSA-05: score, time taken and per-topic breakdown.
class QuizResultsScreen extends StatelessWidget {
  const QuizResultsScreen({super.key, required this.attempt});

  final QuizAttempt attempt;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final topics = attempt.topicScores.entries.toList()..sort((a, b) => a.value.percent.compareTo(b.value.percent));
    final correct = attempt.topicScores.values.fold<int>(0, (s, e) => s + e.correct);
    return Scaffold(
      appBar: AppBar(title: const Text('Quiz results')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: Space.l),
        children: [
          Padding(
            padding: Space.screen,
            child: Text('${attempt.score}%', style: t.displaySmall),
          ),
          Padding(
            padding: Space.screen,
            child: Text('$correct of ${attempt.questionIds.length} correct in ${formatDuration(attempt.timeTaken)}'),
          ),
          const SectionHeader('By topic'),
          for (final e in topics)
            ListTile(
              title: Text(e.key),
              subtitle: LinearProgressIndicator(value: e.value.total == 0 ? 0 : e.value.correct / e.value.total),
              trailing: Text('${e.value.correct}/${e.value.total}', style: AppText.code(context)),
            ),
          const SizedBox(height: Space.l),
          Padding(
            padding: Space.screen,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
                ),
                const SizedBox(width: Space.s),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => QuizSetupScreen(courseId: attempt.courseId)),
                    ),
                    child: const Text('New quiz'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
