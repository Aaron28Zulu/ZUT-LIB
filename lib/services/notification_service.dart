import '../models/models.dart';

/// In-app notification centre (SRS 3.7).
abstract interface class NotificationService {
  /// FR-NOT-05
  List<AppNotification> mine();
  int unreadCount();
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

/// Shows a device notification (FR-NOT-01). Android uses
/// flutter_local_notifications; web and tests use a no-op.
abstract interface class DeviceNotifier {
  Future<void> init();
  Future<void> show(String title, String body);
}
