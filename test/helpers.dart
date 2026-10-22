import 'dart:io';

import 'package:zutlib/core/clock.dart';
import 'package:zutlib/data/data_store.dart';
import 'package:zutlib/data/storage.dart';
import 'package:zutlib/services/auth_service.dart';
import 'package:zutlib/services/mock/mock_services.dart';
import 'package:zutlib/services/notification_service.dart';

class RecordingNotifier implements DeviceNotifier {
  final shown = <String>[];

  @override
  Future<void> init() async {}

  @override
  Future<void> show(String title, String body) async => shown.add(title);
}

class TestEnv {
  TestEnv(this.store, this.services, this.notifier);

  final DataStore store;
  final ServiceBundle services;
  final RecordingNotifier notifier;

  Future<void> signIn(String email, {String? tenantId}) async {
    final tenant = tenantId ??
        (email.endsWith('@zut.demo')
            ? 't_zut'
            : email.endsWith('@northbridge.demo')
                ? 't_nbt'
                : 'platform');
    await services.auth.signIn(tenant, email, 'demo1234');
  }
}

/// A fresh store loaded from the bundled seed files, with the clock at real time.
Future<TestEnv> createEnv({IdentityProvider? identity}) async {
  Clock.reset();
  final store = DataStore(
    storage: MemoryStorage(),
    seedReader: (name) => File('assets/seed/$name.json').readAsString(),
  );
  await store.init();
  final notifier = RecordingNotifier();
  final services = ServiceBundle.mock(store, notifier, identity: identity);
  return TestEnv(store, services, notifier);
}
