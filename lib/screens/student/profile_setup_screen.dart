import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/clock.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';

/// FR-AUTH-05: enrolled courses, exam dates and preferred study times.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, this.firstRun = false});

  /// Shown on first sign-in instead of the home screen.
  final bool firstRun;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final Set<String> _courses;
  late final Map<String, DateTime> _exams;
  late final List<String> _times;
  Map<String, String> _errors = {};

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user!;
    _courses = {...u.enrolledCourseIds};
    _exams = {...u.examDates};
    _times = [...u.studyTimePreferences];
  }

  Future<void> _pickExam(String courseId) async {
    final now = Clock.now().toLocal();
    final d = await showDatePicker(
      context: context,
      initialDate: _exams[courseId]?.toLocal() ?? now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Examination date',
    );
    if (d != null) setState(() => _exams[courseId] = DateTime(d.year, d.month, d.day, 9).toUtc());
  }

  Future<void> _addTime() async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 18, minute: 0));
    if (t == null) return;
    final s = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (!_times.contains(s)) setState(() => _times.add(s));
  }

  Future<void> _save() async {
    final app = context.read<AppState>();
    setState(() => _errors = {});
    final ok = await runAction(
      context,
      () async {
        await app.auth.saveStudyProfile(StudyProfile(
          enrolledCourseIds: _courses.toList(),
          examDates: _exams,
          studyTimes: _times,
        ));
        await app.study.regeneratePlan();
      },
      success: widget.firstRun ? null : 'Study profile saved. Your revision plan has been rebuilt.',
      onFieldErrors: (e) => setState(() => _errors = e),
    );
    if (ok && mounted && !widget.firstRun) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final courses = app.auth.coursesForCurrentTenant();
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.firstRun ? 'Set up your studies' : 'Study profile'),
        actions: [
          if (widget.firstRun) TextButton(onPressed: app.auth.signOut, child: const Text('Sign out')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Space.xxl),
        children: [
          if (widget.firstRun)
            Padding(
              padding: const EdgeInsets.all(Space.l),
              child: Text(
                'Choose your courses and exam dates. ZutLib uses them to recommend papers and plan revision.',
                style: t.bodyLarge,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.s),
            child: Text('Courses this semester', style: t.titleSmall),
          ),
          if (_errors['courses'] != null)
            Padding(padding: Space.screen, child: Text(_errors['courses']!, style: TextStyle(color: scheme.error))),
          for (final c in courses) ...[
            CheckboxListTile(
              value: _courses.contains(c.id),
              title: Text(c.label),
              onChanged: (v) => setState(() => v == true ? _courses.add(c.id) : _courses.remove(c.id)),
            ),
            if (_courses.contains(c.id))
              Padding(
                padding: const EdgeInsets.only(left: 56, right: Space.l, bottom: Space.s),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event_outlined),
                    label: Text(_exams[c.id] == null ? 'Set exam date' : 'Exam ${formatDate(_exams[c.id]!)}'),
                    onPressed: () => _pickExam(c.id),
                  ),
                ),
              ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.xl, Space.l, Space.s),
            child: Text('Preferred study times', style: t.titleSmall),
          ),
          if (_errors['studyTimes'] != null)
            Padding(padding: Space.screen, child: Text(_errors['studyTimes']!, style: TextStyle(color: scheme.error))),
          Padding(
            padding: Space.screen,
            child: Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                for (final time in _times..sort())
                  InputChip(label: Text(time), onDeleted: () => setState(() => _times.remove(time))),
                ActionChip(avatar: const Icon(Icons.add, size: 18), label: const Text('Add time'), onPressed: _addTime),
              ],
            ),
          ),
          const SizedBox(height: Space.xl),
          Padding(
            padding: Space.screen,
            child: FilledButton(onPressed: _save, child: Text(widget.firstRun ? 'Save and continue' : 'Save')),
          ),
        ],
      ),
    );
  }
}
