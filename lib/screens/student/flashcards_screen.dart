import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      body: courses.isEmpty
          ? const EmptyState(icon: Icons.style_outlined, message: 'None of your courses has flashcards yet.')
          : ListView(
              children: [
                for (final c in courses)
                  ListTile(
                    title: Text(c.label),
                    subtitle: Text('${study.flashcardCount(c.id)} cards'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FlashcardsScreen(course: c))),
                  ),
              ],
            ),
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
      body: card == null
          ? EmptyState(
              icon: Icons.check_circle_outline,
              message: 'Session complete. You reviewed ${_queue.reviewed} cards.',
              actionLabel: 'Done',
              onAction: () => Navigator.pop(context),
            )
          : Padding(
              padding: const EdgeInsets.all(Space.l),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${card.topic} · ${_queue.remaining} left', style: AppText.overline(context)),
                  const SizedBox(height: Space.m),
                  Expanded(
                    child: Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _showBack = !_showBack),
                        child: Padding(
                          padding: const EdgeInsets.all(Space.xl),
                          child: Center(
                            child: SingleChildScrollView(
                              child: Text(
                                _showBack ? card.back : card.front,
                                textAlign: TextAlign.center,
                                style: _showBack ? t.bodyLarge : t.headlineSmall,
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
            ),
    );
  }
}
