import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app.dart';
import '../../core/format.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// FR-NOT-05: opening a notification marks it read and opens the item.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static IconData iconFor(NotificationCategory c) => switch (c) {
        NotificationCategory.loan => Icons.assignment_outlined,
        NotificationCategory.newResource => Icons.menu_book_outlined,
        NotificationCategory.study => Icons.event_note_outlined,
        NotificationCategory.request => Icons.inbox_outlined,
        NotificationCategory.system => Icons.info_outline,
      };

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final items = app.notifications.mine();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (items.any((n) => !n.read))
            TextButton(onPressed: app.notifications.markAllRead, child: const Text('Mark all read')),
        ],
      ),
      body: items.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none,
              message: 'No notifications. Loan updates and study reminders appear here.',
            )
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, i) {
                final n = items[i];
                return ListTile(
                  leading: Icon(iconFor(n.category)),
                  title: Text(
                    n.title,
                    style: n.read ? null : const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text('${n.body}\n${formatRelative(n.createdAt)}'),
                  isThreeLine: true,
                  trailing: n.read
                      ? null
                      : Semantics(
                          label: 'Unread',
                          child: CircleAvatar(radius: 4, backgroundColor: Theme.of(context).colorScheme.primary),
                        ),
                  onTap: () {
                    app.notifications.markRead(n.id);
                    openTarget(context, n.targetRoute);
                  },
                );
              },
            ),
    );
  }
}

/// Bell icon with unread count, for app bars.
class NotificationsButton extends StatelessWidget {
  const NotificationsButton({super.key});

  @override
  Widget build(BuildContext context) {
    final count = context.watch<AppState>().notifications.unreadCount();
    return IconButton(
      tooltip: count == 0 ? 'Notifications' : 'Notifications, $count unread',
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text('$count'),
        child: const Icon(Icons.notifications_outlined),
      ),
      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
    );
  }
}
