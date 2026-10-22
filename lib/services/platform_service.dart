import '../models/models.dart';

/// FR-ADM-05: totals only, never individual student records.
class TenantTotals {
  const TenantTotals(this.tenant, this.users, this.resources, this.loans);
  final Tenant tenant;
  final int users;
  final int resources;
  final int loans;
}

/// Platform administration and demo controls (FR-TEN-05, SRS 3.9).
abstract interface class PlatformService {
  List<Tenant> tenants();
  Future<Tenant> addTenant(String name, String shortCode, String themeColour);
  List<TenantTotals> totals();

  /// FR-DEMO-02
  Future<void> resetDemoData();

  /// FR-DEMO-03
  DateTime get now;
  Duration get clockOffset;
  Future<void> advanceClock(Duration by);
  Future<void> resetClock();

  /// FR-AUTH-07 short timeout toggle.
  bool get shortSessionTimeout;
  Future<void> setShortSessionTimeout(bool value);
}
