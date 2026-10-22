import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// FR-SSA-12: a fixed set of questions answered from the tagged library data.
class AskAssistantScreen extends StatefulWidget {
  const AskAssistantScreen({super.key});

  @override
  State<AskAssistantScreen> createState() => _AskAssistantScreenState();
}

class _AskAssistantScreenState extends State<AskAssistantScreen> {
  String? _courseId;
  final _answers = <(String, String)>[];

  @override
  Widget build(BuildContext context) {
    final study = context.watch<AppState>().study;
    final courses = study.enrolledCourses();
    _courseId ??= courses.firstOrNull?.id;
    final course = courses.where((c) => c.id == _courseId).firstOrNull;
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ask the assistant')),
      body: Readable(child: course == null
          ? const EmptyState(icon: AppIcons.assistant, message: 'Add courses to your profile to ask about them.')
          : ListView(
              padding: const EdgeInsets.only(bottom: Space.xl),
              children: [
                Padding(
                  padding: const EdgeInsets.all(Space.l),
                  child: DropdownButtonFormField<String>(
                    initialValue: _courseId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Course'),
                    items: [for (final c in courses) DropdownMenuItem(value: c.id, child: Text(c.label))],
                    onChanged: (v) => setState(() => _courseId = v),
                  ),
                ),
                for (final q in study.assistantQuestions())
                  ListTile(
                    leading: const Icon(AppIcons.chat),
                    title: Text(q.forCourse(course)),
                    onTap: () => setState(() => _answers.insert(0, (q.forCourse(course), study.ask(q.id, course.id)))),
                  ),
                if (_answers.isNotEmpty) const SectionHeader('Answers'),
                for (final (question, answer) in _answers)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.m),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(Space.l),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(question, style: t.labelLarge),
                            const SizedBox(height: Space.s),
                            Text(answer),
                          ],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: Space.screen,
                  child: Text(
                    'Answers are worked out from the papers and question bank in this library. They are not generated text.',
                    style: t.bodySmall,
                  ),
                ),
              ],
            )),
    );
  }
}
