import '../../models/models.dart';
import '../notification_service.dart';
import 'mock_context.dart';

class MockNotificationService implements NotificationService {
  MockNotificationService(this._ctx);

  final MockContext _ctx;

  @override
  List<AppNotification> mine() {
    final u = _ctx.currentUser;
    if (u == null) return const [];
    return _ctx.store.notifications
        .of(u.tenantId)
        .where((n) => n.userId == u.id)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  int unreadCount() => mine().where((n) => !n.read).length;

  @override
  Future<void> markRead(String id) async {
    for (final n in mine()) {
      if (n.id == id) n.read = true;
    }
    _ctx.store.commit();
  }

  @override
  Future<void> markAllRead() async {
    for (final n in mine()) {
      n.read = true;
    }
    _ctx.store.commit();
  }
}

class NoopDeviceNotifier implements DeviceNotifier {
  @override
  Future<void> init() async {}

  @override
  Future<void> show(String title, String body) async {}
}
