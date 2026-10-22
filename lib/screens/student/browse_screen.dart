import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/resource_tile.dart';

/// Department, then course, then year (FR-SRCH-04). Each level lists only
/// items that contain papers.
class BrowseScreen extends StatelessWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final depts = context.watch<AppState>().resources.browseDepartments();
    return Scaffold(
      appBar: AppBar(title: const Text('Browse by department')),
      body: depts.isEmpty
          ? const EmptyState(icon: Icons.account_tree_outlined, message: 'No papers have been added yet.')
          : ListView(
              children: [
                for (final d in depts)
                  ListTile(
                    title: Text(d.name),
                    subtitle: Text(d.code),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _CoursesScreen(department: d))),
                  ),
              ],
            ),
    );
  }
}

class _CoursesScreen extends StatelessWidget {
  const _CoursesScreen({required this.department});

  final Department department;

  @override
  Widget build(BuildContext context) {
    final courses = context.watch<AppState>().resources.browseCourses(department.id);
    return Scaffold(
      appBar: AppBar(title: Text(department.name)),
      body: ListView(
        children: [
          for (final c in courses)
            ListTile(
              title: Text(c.code),
              subtitle: Text(c.name),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => _YearsScreen(course: c))),
            ),
        ],
      ),
    );
  }
}

class _YearsScreen extends StatelessWidget {
  const _YearsScreen({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    final res = context.watch<AppState>().resources;
    final years = res.browseYears(course.id);
    return Scaffold(
      appBar: AppBar(title: Text(course.label)),
      body: ListView(
        children: [
          for (final y in years) ...[
            SectionHeader('$y'),
            for (final r in res.resourcesFor(course.id, year: y)) ResourceTile(r),
          ],
        ],
      ),
    );
  }
}
