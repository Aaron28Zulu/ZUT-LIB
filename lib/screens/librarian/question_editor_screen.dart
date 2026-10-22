import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';

/// Add or edit a practice question. Works on a copy so cancelling changes nothing.
class QuestionEditorScreen extends StatefulWidget {
  const QuestionEditorScreen({super.key, required this.question, this.existing = false});

  final Question question;
  final bool existing;

  @override
  State<QuestionEditorScreen> createState() => _QuestionEditorScreenState();
}

class _QuestionEditorScreenState extends State<QuestionEditorScreen> {
  late QuestionType _type = widget.question.type;
  late final _text = TextEditingController(text: widget.question.text);
  late final _topic = TextEditingController(text: widget.question.topic);
  late final _explanation = TextEditingController(text: widget.question.explanation);
  late final _answer = TextEditingController(text: widget.question.correctAnswer);
  late final _keywords = TextEditingController(text: widget.question.acceptedKeywords.join(', '));
  late final List<TextEditingController> _options = [
    for (var i = 0; i < 4; i++)
      TextEditingController(text: i < widget.question.options.length ? widget.question.options[i] : ''),
  ];
  late String? _correctOption = widget.question.type == QuestionType.multipleChoice ? widget.question.correctAnswer : null;
  late String _tfAnswer = widget.question.type == QuestionType.trueFalse ? widget.question.correctAnswer : 'True';
  Map<String, String> _errors = {};

  @override
  void dispose() {
    for (final c in [_text, _topic, _explanation, _answer, _keywords, ..._options]) {
      c.dispose();
    }
    super.dispose();
  }

  Question _build() {
    final options = switch (_type) {
      QuestionType.multipleChoice => [for (final o in _options) o.text.trim()],
      QuestionType.trueFalse => ['True', 'False'],
      QuestionType.shortAnswer => <String>[],
    };
    final correct = switch (_type) {
      QuestionType.multipleChoice => _correctOption ?? '',
      QuestionType.trueFalse => _tfAnswer,
      QuestionType.shortAnswer => _answer.text.trim(),
    };
    return Question(
      id: widget.question.id,
      tenantId: widget.question.tenantId,
      courseId: widget.question.courseId,
      sourceResourceId: widget.question.sourceResourceId,
      topic: _topic.text.trim(),
      type: _type,
      text: _text.text.trim(),
      options: options,
      correctAnswer: correct,
      acceptedKeywords: _type == QuestionType.shortAnswer
          ? _keywords.text.split(',').map((k) => k.trim()).where((k) => k.isNotEmpty).toList()
          : [],
      explanation: _explanation.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final study = context.read<AppState>().study;
    final errorStyle = TextStyle(color: Theme.of(context).colorScheme.error);
    const gap = SizedBox(height: Space.m);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing ? 'Edit question' : 'New question'),
        actions: [
          if (widget.existing)
            IconButton(
              tooltip: 'Delete question',
              icon: const Icon(AppIcons.delete),
              onPressed: () async {
                if (await confirm(context, title: 'Delete this question?', message: 'It will be removed from future quizzes.', action: 'Delete', destructive: true) &&
                    context.mounted) {
                  final ok = await runAction(context, () => study.deleteQuestion(widget.question.id), success: 'Question deleted.');
                  if (ok && context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Readable(child: ListView(
        padding: const EdgeInsets.all(Space.l),
        children: [
          SegmentedButton<QuestionType>(
            segments: [for (final t in QuestionType.values) ButtonSegment(value: t, label: Text(t.label))],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          gap,
          TextField(controller: _topic, decoration: InputDecoration(labelText: 'Topic', errorText: _errors['topic'])),
          gap,
          TextField(
            controller: _text,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(labelText: 'Question', errorText: _errors['text']),
          ),
          gap,
          if (_type == QuestionType.multipleChoice) ...[
            Text('Options: select the correct one', style: Theme.of(context).textTheme.titleSmall),
            if (_errors['options'] != null) Text(_errors['options']!, style: errorStyle),
            RadioGroup<String>(
              groupValue: _correctOption,
              onChanged: (v) => setState(() => _correctOption = v),
              child: Column(
                children: [
                  for (var i = 0; i < _options.length; i++)
                    Row(
                      children: [
                        Radio<String>(value: _options[i].text.trim()),
                        Expanded(
                          child: TextField(
                            controller: _options[i],
                            decoration: InputDecoration(labelText: 'Option ${i + 1}'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
          if (_type == QuestionType.trueFalse)
            SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'True', label: Text('True')), ButtonSegment(value: 'False', label: Text('False'))],
              selected: {_tfAnswer},
              onSelectionChanged: (s) => setState(() => _tfAnswer = s.first),
            ),
          if (_type == QuestionType.shortAnswer) ...[
            TextField(controller: _answer, decoration: const InputDecoration(labelText: 'Model answer')),
            gap,
            TextField(
              controller: _keywords,
              decoration: InputDecoration(
                labelText: 'Accepted keywords',
                helperText: 'Comma separated. An answer containing any keyword is marked correct.',
                errorText: _errors['acceptedKeywords'],
              ),
            ),
          ],
          if (_errors['correctAnswer'] != null) Text(_errors['correctAnswer']!, style: errorStyle),
          gap,
          TextField(
            controller: _explanation,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Explanation shown after answering'),
          ),
          const SizedBox(height: Space.xl),
          FilledButton(
            onPressed: () async {
              setState(() => _errors = {});
              final ok = await runAction(context, () => study.saveQuestion(_build()),
                  success: 'Question saved.', onFieldErrors: (e) => setState(() => _errors = e));
              if (ok && context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      )),
    );
  }
}
