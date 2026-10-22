import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';

/// FR-ADM-02: new courses appear in upload and filter lists.
class DepartmentsCoursesScreen extends StatelessWidget {
  const DepartmentsCoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final departments = app.admin.departments();
    final courses = app.admin.courses();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-dept',
        icon: const Icon(AppIcons.add),
        label: const Text('Add'),
        onPressed: () => showModalBottomSheet(
          context: context,
          showDragHandle: true,
          builder: (sheet) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(AppIcons.courses),
                  title: const Text('Department'),
                  onTap: () {
                    Navigator.pop(sheet);
                    _editDepartment(context, null);
                  },
                ),
                ListTile(
                  leading: const Icon(AppIcons.course),
                  title: const Text('Course'),
                  enabled: departments.isNotEmpty,
                  onTap: () {
                    Navigator.pop(sheet);
                    _editCourse(context, null, departments);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Readable(child: ListView(
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          for (final d in departments) ...[
            SectionHeader(
              '${d.name} (${d.code})',
              trailing: IconButton(
                tooltip: 'Edit department',
                icon: const Icon(AppIcons.edit),
                onPressed: () => _editDepartment(context, d),
              ),
            ),
            for (final c in courses.where((c) => c.departmentId == d.id))
              ListTile(
                title: Text(c.label),
                subtitle: Text('Year ${c.yearLevel}'),
                onTap: () => _editCourse(context, c, departments),
              ),
            if (!courses.any((c) => c.departmentId == d.id))
              ListTile(
                title: const Text('No courses yet.'),
                trailing: TextButton(
                  onPressed: () => runAction(context, () => app.admin.deleteDepartment(d.id), success: 'Department deleted.'),
                  child: const Text('Delete department'),
                ),
              ),
          ],
        ],
      )),
    );
  }

  Future<void> _editDepartment(BuildContext context, Department? d) async {
    final app = context.read<AppState>();
    final name = TextEditingController(text: d?.name);
    final code = TextEditingController(text: d?.code);
    await showDialog<void>(
      context: context,
      builder: (dialog) {
        Map<String, String> errors = {};
        return StatefulBuilder(
          builder: (dialog, setState) => AlertDialog(
            title: Text(d == null ? 'Add department' : 'Edit department'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: InputDecoration(labelText: 'Name', errorText: errors['name'])),
                const SizedBox(height: Space.m),
                TextField(controller: code, decoration: InputDecoration(labelText: 'Short code', errorText: errors['code'])),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final ok = await runAction(dialog, () => app.admin.saveDepartment(id: d?.id, name: name.text, code: code.text),
                      onFieldErrors: (e) => setState(() => errors = e));
                  if (ok && dialog.mounted) Navigator.pop(dialog);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editCourse(BuildContext context, Course? c, List<Department> departments) async {
    final app = context.read<AppState>();
    final code = TextEditingController(text: c?.code);
    final name = TextEditingController(text: c?.name);
    String deptId = c?.departmentId ?? departments.first.id;
    int year = c?.yearLevel ?? 1;
    await showDialog<void>(
      context: context,
      builder: (dialog) {
        Map<String, String> errors = {};
        return StatefulBuilder(
          builder: (dialog, setState) => AlertDialog(
            title: Text(c == null ? 'Add course' : 'Edit course'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: deptId,
                    isExpanded: true,
                    decoration: InputDecoration(labelText: 'Department', errorText: errors['departmentId']),
                    items: [for (final d in departments) DropdownMenuItem(value: d.id, child: Text(d.name))],
                    onChanged: (v) => setState(() => deptId = v ?? deptId),
                  ),
                  const SizedBox(height: Space.m),
                  TextField(controller: code, decoration: InputDecoration(labelText: 'Course code', errorText: errors['code'])),
                  const SizedBox(height: Space.m),
                  TextField(controller: name, decoration: InputDecoration(labelText: 'Course name', errorText: errors['name'])),
                  const SizedBox(height: Space.m),
                  DropdownButtonFormField<int>(
                    initialValue: year,
                    decoration: const InputDecoration(labelText: 'Year level'),
                    items: [for (var y = 1; y <= 5; y++) DropdownMenuItem(value: y, child: Text('Year $y'))],
                    onChanged: (v) => setState(() => year = v ?? year),
                  ),
                ],
              ),
            ),
            actions: [
              if (c != null)
                TextButton(
                  onPressed: () async {
                    final ok = await runAction(dialog, () => app.admin.deleteCourse(c.id), success: 'Course deleted.');
                    if (ok && dialog.mounted) Navigator.pop(dialog);
                  },
                  child: const Text('Delete'),
                ),
              TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final ok = await runAction(
                    dialog,
                    () => app.admin.saveCourse(id: c?.id, departmentId: deptId, code: code.text, name: name.text, yearLevel: year),
                    onFieldErrors: (e) => setState(() => errors = e),
                  );
                  if (ok && dialog.mounted) Navigator.pop(dialog);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}
