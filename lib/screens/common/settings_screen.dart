import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// Notification categories (FR-NOT-06) and app information.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final u = app.user!;
    final categories = switch (u.role) {
      Role.student => [NotificationCategory.loan, NotificationCategory.newResource, NotificationCategory.study],
      Role.librarian || Role.institutionAdmin => [NotificationCategory.request],
      Role.platformAdmin => <NotificationCategory>[],
    };
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          if (categories.isNotEmpty) const SectionHeader('Notifications'),
          for (final c in categories)
            SwitchListTile(
              title: Text(c.label),
              value: u.wantsCategory(c),
              onChanged: (v) => app.auth.setNotificationPreference(c, v),
            ),
          const SectionHeader('About'),
          const Padding(
            padding: Space.screen,
            child: Text(
              'ZutLib demonstration prototype for Zambia University College of Technology. '
              'All institutions, people, papers and loans in this app are fictional. '
              'Data is stored only on this device.',
            ),
          ),
        ],
      ),
    );
  }
}
