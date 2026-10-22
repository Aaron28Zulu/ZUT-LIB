import '../../core/clock.dart';
import '../../core/errors.dart';
import '../../core/ids.dart';
import '../../core/permissions.dart';
import '../../models/models.dart';
import '../platform_service.dart';
import 'mock_context.dart';

class MockPlatformService implements PlatformService {
  MockPlatformService(this._ctx, {required this.onClockChanged});

  final MockContext _ctx;

  /// Runs the loan and reminder jobs after the clock moves.
  final void Function() onClockChanged;

  @override
  List<Tenant> tenants() {
    _ctx.require(Permission.manageTenants);
    return List.of(_ctx.store.tenants);
  }

  @override
  Future<Tenant> addTenant(String name, String shortCode, String themeColour) async {
    _ctx.require(Permission.manageTenants);
    final e = <String, String>{};
    final code = shortCode.trim().toUpperCase();
    if (name.trim().isEmpty) e['name'] = 'Enter the institution name.';
    if (!RegExp(r'^[A-Z0-9]{2,6}$').hasMatch(code)) {
      e['shortCode'] = 'Use 2 to 6 letters or digits.';
    } else if (_ctx.store.tenants.any((t) => t.shortCode == code)) {
      e['shortCode'] = 'Another institution already uses this code.';
    }
    if (e.isNotEmpty) throw ValidationException(e);
    final t = Tenant(
      id: newId('t'),
      name: name.trim(),
      shortCode: code,
      themeColour: themeColour,
      createdAt: Clock.now(),
    );
    _ctx.store.tenants.add(t);
    _ctx.store.commit();
    return t;
  }

  /// FR-ADM-05: counts per tenant only.
  @override
  List<TenantTotals> totals() {
    _ctx.require(Permission.manageTenants);
    return [
      for (final t in _ctx.store.tenants)
        TenantTotals(
          t,
          _ctx.store.users.of(t.id).length,
          _ctx.store.resources.of(t.id).where((r) => !r.archived).length,
          _ctx.store.loans.of(t.id).length,
        ),
    ];
  }

  @override
  Future<void> resetDemoData() async {
    final admin = _ctx.require(Permission.demoControls);
    await _ctx.store.loadSeed();
    // Keep the platform admin signed in on the fresh data.
    _ctx.currentUser = _ctx.store.users.find(admin.tenantId, admin.id);
  }

  @override
  DateTime get now => Clock.now();

  @override
  Duration get clockOffset => Clock.offset;

  @override
  Future<void> advanceClock(Duration by) async {
    _ctx.require(Permission.demoControls);
    Clock.advance(by);
    onClockChanged();
    _ctx.store.commit();
  }

  @override
  Future<void> resetClock() async {
    _ctx.require(Permission.demoControls);
    Clock.reset();
    onClockChanged();
    _ctx.store.commit();
  }

  @override
  bool get shortSessionTimeout => _ctx.store.shortSessionTimeout;

  @override
  Future<void> setShortSessionTimeout(bool value) async {
    _ctx.require(Permission.demoControls);
    _ctx.store.shortSessionTimeout = value;
    _ctx.store.commit();
  }
}
