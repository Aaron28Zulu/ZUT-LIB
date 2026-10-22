import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/study_assistant_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

class FlashcardCoursePicker extends StatelessWidget {
  const FlashcardCoursePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final study = context.watch<AppState>().study;
    final courses = study.enrolledCourses().where((c) => study.flashcardCount(c.id) > 0).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
      body: Readable(child: courses.isEmpty
          ? const EmptyState(icon: AppIcons.flashcards, message: 'None of your courses has flashcards yet.')
          : ListView(
              children: [
                for (final c in courses)
                  ListTile(
                    title: Text(c.label),
                    subtitle: Text('${study.flashcardCount(c.id)} cards'),
                    trailing: const Icon(AppIcons.next),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardsScreen(course: c))),
                  ),
              ],
            )),
    );
  }
}

/// FR-SSA-06: Easy, Good or Hard; Hard cards reappear in this session and
/// lead the next one.
class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key, required this.course});

  final Course course;

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  late final FlashcardQueue _queue;
  bool _showBack = false;

  @override
  void initState() {
    super.initState();
    _queue = FlashcardQueue(context.read<AppState>().study.flashcardSession(widget.course.id));
  }

  void _rate(CardRating r) {
    final card = _queue.current!;
    context.read<AppState>().study.rateCard(card, r);
    setState(() {
      _queue.rate(r);
      _showBack = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = _queue.current;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.course.code)),
      body: Readable(child: card == null
          ? EmptyState(
              icon: AppIcons.done,
              message: 'Session complete. You reviewed ${_queue.reviewed} cards.',
              actionLabel: 'Done',
              onAction: () => Navigator.pop(context),
            )
          : Padding(
              padding: const EdgeInsets.all(Space.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${card.topic.toUpperCase()} · ${_queue.remaining} LEFT', style: AppText.overline(context)),
                  const SizedBox(height: Space.s),
                  ClipRRect(
                    borderRadius: Radii.tagRadius,
                    child: LinearProgressIndicator(
                      value: _queue.reviewed / (_queue.reviewed + _queue.remaining),
                      semanticsLabel: 'Session progress',
                    ),
                  ),
                  const SizedBox(height: Space.l),
                  Expanded(
                    child: Card(
                      child: InkWell(
                        borderRadius: Radii.panelRadius,
                        onTap: () => setState(() => _showBack = !_showBack),
                        child: Padding(
                          padding: const EdgeInsets.all(Space.xl),
                          child: Center(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  Text(_showBack ? 'ANSWER' : 'TERM', style: AppText.overline(context)),
                                  const SizedBox(height: Space.m),
                                  Text(
                                    _showBack ? card.back : card.front,
                                    textAlign: TextAlign.center,
                                    style: _showBack ? t.bodyLarge : t.headlineSmall,
                                  ),
                                  if (!_showBack) ...[
                                    const SizedBox(height: Space.l),
                                    Text('Tap the card to turn it over', style: t.bodySmall),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.l),
                  if (!_showBack)
                    FilledButton(onPressed: () => setState(() => _showBack = true), child: const Text('Show answer'))
                  else
                    Row(
                      spacing: Space.s,
                      children: [
                        Expanded(child: OutlinedButton(onPressed: () => _rate(CardRating.hard), child: const Text('Hard'))),
                        Expanded(child: OutlinedButton(onPressed: () => _rate(CardRating.good), child: const Text('Good'))),
                        Expanded(child: FilledButton(onPressed: () => _rate(CardRating.easy), child: const Text('Easy'))),
                      ],
                    ),
                ],
              ),
            )),
    );
  }
}
