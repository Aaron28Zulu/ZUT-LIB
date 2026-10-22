import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/clock.dart';
import '../core/rules.dart';
import '../data/data_store.dart';
import '../data/storage.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../services/auth_service.dart';
import '../services/device/local_device_notifier.dart';
import '../services/loan_service.dart';
import '../services/mock/mock_services.dart';
import '../services/notification_service.dart';
import '../services/platform_service.dart';
import '../services/resource_service.dart';
import '../services/study_assistant_service.dart';

/// The single place where implementations are chosen (AGENTS.md rule 1).
/// Screens read services from here, typed as interfaces.
class AppState extends ChangeNotifier {
  AppState._(this._store, this._services) {
    _store.addListener(notifyListeners);
  }

  final DataStore _store;
  final ServiceBundle _services;
  DateTime _lastActivity = Clock.wallNow();
  bool _sessionExpired = false;

  /// [storage] and [notifier] are overridden by widget tests.
  static Future<AppState> create({KeyValueStorage? storage, DeviceNotifier? notifier}) async {
    if (storage == null) {
      try {
        storage = SharedPrefsStorage(SharedPreferencesAsync());
        await storage.read('probe');
      } on Object catch (e) {
        debugPrint('Persistent storage unavailable, using memory: $e');
        storage = MemoryStorage();
      }
    }
    final store = DataStore(
      storage: storage,
      seedReader: (name) => rootBundle.loadString('assets/seed/$name.json'),
    );
    await store.init();
    notifier ??= LocalDeviceNotifier();
    await notifier.init();
    final services = ServiceBundle.mock(store, notifier);
    services.runScheduledJobs();
    return AppState._(store, services);
  }

  AuthService get auth => _services.auth;
  ResourceService get resources => _services.resources;
  LoanService get loans => _services.loans;
  StudyAssistantService get study => _services.study;
  NotificationService get notifications => _services.notifications;
  AdminService get admin => _services.admin;
  PlatformService get platform => _services.platform;

  AppUser? get user => auth.currentUser;
  Tenant? get tenant => auth.currentTenant;

  bool get onboardingSeen => _store.onboardingSeen;

  void completeOnboarding() {
    _store.onboardingSeen = true;
    _store.commit();
  }

  /// Set when the inactivity timeout signed the user out (FR-AUTH-07).
  bool consumeSessionExpired() {
    final v = _sessionExpired;
    _sessionExpired = false;
    return v;
  }

  Duration get _timeout =>
      _store.shortSessionTimeout ? Rules.shortSessionTimeout : Rules.sessionTimeout;

  /// Called on every pointer event from the root widget.
  void registerActivity() {
    final now = Clock.wallNow();
    if (user != null && now.difference(_lastActivity) > _timeout) {
      _sessionExpired = true;
      unawaited(auth.signOut());
    }
    _lastActivity = now;
  }

  /// Runs the overdue/expiry and reminder jobs (on resume, after sign-in).
  void runScheduledJobs() => _services.runScheduledJobs();

  Future<void> flush() => _store.flush();

  @override
  void dispose() {
    _store.removeListener(notifyListeners);
    super.dispose();
  }
}
