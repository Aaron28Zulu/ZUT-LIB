import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/resource_service.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';

/// Upload or edit a paper (FR-RES-01 to 05). Mandatory fields show their
/// error next to the field (FR-RES-02); duplicates warn first (FR-RES-04).
class ResourceFormScreen extends StatefulWidget {
  const ResourceFormScreen({super.key, this.resourceId});

  final String? resourceId;

  @override
  State<ResourceFormScreen> createState() => _ResourceFormScreenState();
}

class _ResourceFormScreenState extends State<ResourceFormScreen> {
  final _draft = ResourceDraft();
  final _title = TextEditingController();
  final _year = TextEditingController();
  final _lecturer = TextEditingController();
  final _duration = TextEditingController();
  final _marks = TextEditingController();
  final _topic = TextEditingController();
  Map<String, String> _errors = {};
  Resource? _existing;

  bool get _editing => widget.resourceId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) {
      final res = context.read<AppState>().resources;
      final r = _existing = res.resource(widget.resourceId!);
      _draft
        ..title = r.title
        ..courseId = r.courseId
        ..departmentId = res.course(r.courseId)?.departmentId
        ..academicYear = r.academicYear
        ..semester = r.semester
        ..paperType = r.paperType
        ..topics = List.of(r.topics)
        ..hasMemo = r.hasMemo;
      _title.text = r.title;
      _year.text = '${r.academicYear}';
      _lecturer.text = r.lecturer ?? '';
      _duration.text = r.durationMinutes?.toString() ?? '';
      _marks.text = r.totalMarks?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _year, _lecturer, _duration, _marks, _topic]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFile() async {
    final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (files.isEmpty) return;
    final f = files.first;
    final bytes = await f.readAsBytes();
    setState(() {
      _draft
        ..fileName = f.name
        ..fileBytes = bytes;
      _errors.remove('file');
    });
  }

  void _collect() {
    _draft
      ..title = _title.text
      ..academicYear = int.tryParse(_year.text.trim())
      ..lecturer = _lecturer.text
      ..durationMinutes = int.tryParse(_duration.text.trim())
      ..totalMarks = int.tryParse(_marks.text.trim());
  }

  Future<void> _save() async {
    _collect();
    final app = context.read<AppState>();
    final res = app.resources;
    final duplicate = _draft.courseId == null ? null : res.findDuplicate(_draft, ignoreId: widget.resourceId);
    if (duplicate != null) {
      final proceed = await confirm(
        context,
        title: 'Possible duplicate',
        message: '"${duplicate.title}" already has the same course, year, semester and paper type.',
        action: 'Upload anyway',
      );
      if (!proceed || !mounted) return;
    }
    setState(() => _errors = {});
    final ok = await runAction(
      context,
      () => _editing ? res.update(widget.resourceId!, _draft) : res.upload(_draft),
      success: _editing ? 'Paper updated.' : 'Paper uploaded. Enrolled students have been notified.',
      onFieldErrors: (e) => setState(() => _errors = e),
    );
    if (ok && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final res = app.resources;
    final departments = res.departments();
    final courses = res.courses(departmentId: _draft.departmentId);
    final suggestions = _draft.courseId == null
        ? <String>[]
        : res.knownTopics(_draft.courseId!).where((t) => !_draft.topics.contains(t)).toList();
    final t = Theme.of(context).textTheme;
    const gap = SizedBox(height: Space.m);

    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit paper' : 'Upload paper')),
      body: Readable(child: ListView(
        padding: const EdgeInsets.all(Space.l),
        children: [
          Text('Required', style: t.titleSmall),
          gap,
          OutlinedButton.icon(
            icon: const Icon(AppIcons.attach),
            label: Text(_draft.fileName ?? (_editing ? 'Replace PDF file' : 'Choose PDF file')),
            onPressed: _pickFile,
          ),
          if (_errors['file'] != null)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text(_errors['file']!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          gap,
          TextField(controller: _title, decoration: InputDecoration(labelText: 'Title', errorText: _errors['title'])),
          gap,
          DropdownButtonFormField<String>(
            initialValue: _draft.departmentId,
            isExpanded: true,
            decoration: InputDecoration(labelText: 'Department', errorText: _errors['departmentId']),
            items: [for (final d in departments) DropdownMenuItem(value: d.id, child: Text(d.name))],
            onChanged: (v) => setState(() {
              _draft
                ..departmentId = v
                ..courseId = null;
            }),
          ),
          gap,
          DropdownButtonFormField<String>(
            key: ValueKey(_draft.departmentId),
            initialValue: _draft.courseId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Course code and name',
              errorText: _errors['courseId'],
              helperText: _draft.departmentId == null ? 'Choose a department first' : null,
            ),
            items: [for (final c in courses) DropdownMenuItem(value: c.id, child: Text(c.label))],
            onChanged: _draft.departmentId == null ? null : (v) => setState(() => _draft.courseId = v),
          ),
          gap,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _year,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Academic year', errorText: _errors['academicYear']),
                ),
              ),
              const SizedBox(width: Space.m),
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: _draft.semester,
                  decoration: InputDecoration(labelText: 'Semester', errorText: _errors['semester']),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('1')),
                    DropdownMenuItem(value: 2, child: Text('2')),
                  ],
                  onChanged: (v) => setState(() => _draft.semester = v),
                ),
              ),
            ],
          ),
          gap,
          DropdownButtonFormField<PaperType>(
            initialValue: _draft.paperType,
            decoration: InputDecoration(labelText: 'Paper type', errorText: _errors['paperType']),
            items: [for (final p in PaperType.values) DropdownMenuItem(value: p, child: Text(p.label))],
            onChanged: (v) => setState(() => _draft.paperType = v),
          ),
          const SizedBox(height: Space.xl),
          Text('Optional', style: t.titleSmall),
          gap,
          TextField(controller: _lecturer, decoration: const InputDecoration(labelText: 'Lecturer')),
          gap,
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _duration,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Duration (minutes)'),
                ),
              ),
              const SizedBox(width: Space.m),
              Expanded(
                child: TextField(
                  controller: _marks,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total marks'),
                ),
              ),
            ],
          ),
          gap,
          TextField(
            controller: _topic,
            decoration: InputDecoration(
              labelText: 'Add topic',
              suffixIcon: IconButton(
                tooltip: 'Add topic',
                icon: const Icon(AppIcons.add),
                onPressed: () => _addTopic(_topic.text),
              ),
            ),
            onSubmitted: _addTopic,
          ),
          const SizedBox(height: Space.s),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.xs,
            children: [
              for (final topic in _draft.topics)
                InputChip(label: Text(topic), onDeleted: () => setState(() => _draft.topics.remove(topic))),
              for (final s in suggestions.take(6))
                ActionChip(avatar: const Icon(AppIcons.add, size: 16), label: Text(s), onPressed: () => _addTopic(s)),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Memo or marking guide attached'),
            value: _draft.hasMemo,
            onChanged: (v) => setState(() => _draft.hasMemo = v),
          ),
          if (_existing != null) ...[
            const SizedBox(height: Space.s),
            OutlinedButton(
              onPressed: () => runAction(
                context,
                () async {
                  await res.setArchived(_existing!.id, !_existing!.archived);
                  if (context.mounted) Navigator.pop(context);
                },
                success: _existing!.archived ? 'Paper restored.' : 'Paper archived. Students can no longer see it.',
              ),
              child: Text(_existing!.archived ? 'Restore paper' : 'Archive paper'),
            ),
          ],
          const SizedBox(height: Space.xl),
          FilledButton(onPressed: _save, child: Text(_editing ? 'Save changes' : 'Upload')),
        ],
      )),
    );
  }

  void _addTopic(String value) {
    final v = value.trim();
    if (v.isEmpty || _draft.topics.contains(v)) return;
    setState(() {
      _draft.topics = [..._draft.topics, v];
      _topic.clear();
    });
  }
}
