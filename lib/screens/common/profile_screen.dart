import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';
import '../student/feedback_screen.dart';
import '../student/profile_setup_screen.dart';
import '../student/saved_screen.dart';
import 'settings_screen.dart';

/// FR-AUTH-06: view and edit profile, sign out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.embedded = false});

  /// True inside the student tab bar (no own app bar back button needed).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final u = app.user!;
    final tenant = app.tenant;
    final isStudent = u.role == Role.student;
    final courses = {for (final c in app.auth.coursesForCurrentTenant()) c.id: c};
    final department = u.departmentId == null
        ? null
        : app.auth.departmentsFor(u.tenantId).where((d) => d.id == u.departmentId).firstOrNull;

    final body = ListView(
      children: [
        ListTile(
          leading: tenant != null ? TenantMark(tenant) : const Icon(Icons.admin_panel_settings_outlined),
          title: Text(u.fullName, style: Theme.of(context).textTheme.titleMedium),
          subtitle: Text('${u.role.label}${tenant != null ? ' · ${tenant.shortCode}' : ''}\n${u.email}'),
          isThreeLine: true,
          trailing: IconButton(
            tooltip: 'Edit name',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final name = await promptText(context, title: 'Edit name', label: 'Full name', action: 'Save', initial: u.fullName);
              if (name != null && context.mounted) {
                await runAction(context, () => app.auth.updateProfile(fullName: name), success: 'Name updated.');
              }
            },
          ),
        ),
        if (isStudent) ...[
          Padding(
            padding: Space.screen,
            child: Column(
              children: [
                if (u.studentNumber != null) InfoRow('Student number', u.studentNumber!),
                if (department != null) InfoRow('Department', department.name),
                if (u.yearOfStudy != null) InfoRow('Year of study', 'Year ${u.yearOfStudy}'),
              ],
            ),
          ),
          SectionHeader(
            'Courses and exams',
            trailing: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileSetupScreen())),
              child: const Text('Edit'),
            ),
          ),
          for (final id in u.enrolledCourseIds)
            if (courses[id] != null)
              ListTile(
                dense: true,
                title: Text(courses[id]!.label),
                subtitle: Text(u.examDates[id] == null ? 'No exam date set' : 'Exam ${formatDate(u.examDates[id]!)}'),
              ),
          ListTile(
            dense: true,
            title: const Text('Preferred study times'),
            subtitle: Text(u.studyTimePreferences.isEmpty ? 'None set' : u.studyTimePreferences.join(', ')),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.bookmark_border),
            title: const Text('Saved papers'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedScreen())),
          ),
          ListTile(
            leading: const Icon(Icons.rate_review_outlined),
            title: const Text('Send feedback'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FeedbackScreen())),
          ),
        ],
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('Settings'),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          onTap: () => app.auth.signOut(),
        ),
      ],
    );
    return embedded ? body : Scaffold(appBar: AppBar(title: const Text('Profile')), body: body);
  }
}
