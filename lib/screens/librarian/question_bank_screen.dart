import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';
import 'question_editor_screen.dart';

/// Question bank and flashcard editor (SRS 8, permissions matrix).
class QuestionBankScreen extends StatefulWidget {
  const QuestionBankScreen({super.key});

  @override
  State<QuestionBankScreen> createState() => _QuestionBankScreenState();
}

class _QuestionBankScreenState extends State<QuestionBankScreen> {
  String? _courseId;
  bool _cards = false;

  @override
  Widget build(BuildContext context) {
    final study = context.watch<AppState>().study;
    final courses = study.manageableCourses();
    _courseId ??= courses.firstOrNull?.id;
    if (_courseId == null) {
      return const EmptyState(icon: Icons.quiz_outlined, message: 'Add a course first.');
    }
    final questions = _cards ? <Question>[] : study.questionBank(_courseId!);
    final cards = _cards ? study.flashcards(_courseId!) : <Flashcard>[];

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'bank',
        icon: const Icon(Icons.add),
        label: Text(_cards ? 'Add flashcard' : 'Add question'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _cards
                ? FlashcardEditorScreen(card: study.newFlashcard(_courseId!))
                : QuestionEditorScreen(question: study.newQuestion(_courseId!)),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.s),
            child: DropdownButtonFormField<String>(
              initialValue: _courseId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Course'),
              items: [for (final c in courses) DropdownMenuItem(value: c.id, child: Text(c.label))],
              onChanged: (v) => setState(() => _courseId = v),
            ),
          ),
          Padding(
            padding: Space.screen,
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Questions')),
                ButtonSegment(value: true, label: Text('Flashcards')),
              ],
              selected: {_cards},
              onSelectionChanged: (s) => setState(() => _cards = s.first),
            ),
          ),
          Expanded(
            child: _cards
                ? (cards.isEmpty
                    ? const EmptyState(icon: Icons.style_outlined, message: 'No flashcards for this course.')
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 88),
                        children: [
                          for (final f in cards)
                            ListTile(
                              title: Text(f.front),
                              subtitle: Text('${f.topic} · ${f.back}', maxLines: 2, overflow: TextOverflow.ellipsis),
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => FlashcardEditorScreen(card: f, existing: true))),
                            ),
                        ],
                      ))
                : (questions.isEmpty
                    ? const EmptyState(icon: Icons.quiz_outlined, message: 'No questions for this course.')
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 88),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(Space.l, Space.m, Space.l, 0),
                            child: Text('${questions.length} questions', style: Theme.of(context).textTheme.labelLarge),
                          ),
                          for (final q in questions)
                            ListTile(
                              title: Text(q.text, maxLines: 2, overflow: TextOverflow.ellipsis),
                              subtitle: Text('${q.topic} · ${q.type.label}'),
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => QuestionEditorScreen(question: q, existing: true))),
                            ),
                        ],
                      )),
          ),
        ],
      ),
    );
  }
}

class FlashcardEditorScreen extends StatefulWidget {
  const FlashcardEditorScreen({super.key, required this.card, this.existing = false});

  final Flashcard card;
  final bool existing;

  @override
  State<FlashcardEditorScreen> createState() => _FlashcardEditorScreenState();
}

class _FlashcardEditorScreenState extends State<FlashcardEditorScreen> {
  late final _front = TextEditingController(text: widget.card.front);
  late final _back = TextEditingController(text: widget.card.back);
  late final _topic = TextEditingController(text: widget.card.topic);
  Map<String, String> _errors = {};

  @override
  void dispose() {
    for (final c in [_front, _back, _topic]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final study = context.read<AppState>().study;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing ? 'Edit flashcard' : 'New flashcard'),
        actions: [
          if (widget.existing)
            IconButton(
              tooltip: 'Delete flashcard',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                if (await confirm(context, title: 'Delete this flashcard?', message: 'Students will no longer see it.', action: 'Delete', destructive: true) &&
                    context.mounted) {
                  final ok = await runAction(context, () => study.deleteFlashcard(widget.card.id), success: 'Flashcard deleted.');
                  if (ok && context.mounted) Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(Space.l),
        children: [
          TextField(controller: _topic, decoration: InputDecoration(labelText: 'Topic', errorText: _errors['topic'])),
          const SizedBox(height: Space.m),
          TextField(controller: _front, decoration: InputDecoration(labelText: 'Front (term or question)', errorText: _errors['front'])),
          const SizedBox(height: Space.m),
          TextField(
            controller: _back,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(labelText: 'Back (answer)', errorText: _errors['back']),
          ),
          const SizedBox(height: Space.xl),
          FilledButton(
            onPressed: () async {
              final card = Flashcard(
                id: widget.card.id,
                tenantId: widget.card.tenantId,
                courseId: widget.card.courseId,
                front: _front.text.trim(),
                back: _back.text.trim(),
                topic: _topic.text.trim(),
              );
              setState(() => _errors = {});
              final ok = await runAction(context, () => study.saveFlashcard(card),
                  success: 'Flashcard saved.', onFieldErrors: (e) => setState(() => _errors = e));
              if (ok && context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
