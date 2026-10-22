import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../notification_service.dart';

/// Android device notifications (FR-NOT-01). On web this is a no-op; the
/// in-app notification centre still records everything.
class LocalDeviceNotifier implements DeviceNotifier {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  int _nextId = 0;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'zutlib_events',
      'Loans and study reminders',
      channelDescription: 'Loan updates, new papers and study session reminders',
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  @override
  Future<void> init() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      _ready = true;
    } on Object catch (e) {
      debugPrint('Device notifications unavailable: $e');
    }
  }

  @override
  Future<void> show(String title, String body) async {
    if (!_ready) return;
    await _plugin.show(id: _nextId++, title: title, body: body, notificationDetails: _details);
  }
}
