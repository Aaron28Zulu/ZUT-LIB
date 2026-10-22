import '../models/models.dart';

/// A tenant-scoped repository over one in-memory table (FR-TEN-02).
///
/// Services read through [of] and [find], which always filter by tenant. The
/// only unfiltered access is [unscoped], used for platform-level totals and
/// system jobs (overdue sweeps); grep for it when reviewing tenant isolation.
class TenantTable<T extends TenantScoped> {
  TenantTable([List<T>? rows]) : _rows = rows ?? [];

  final List<T> _rows;

  List<T> of(String tenantId) =>
      _rows.where((r) => r.tenantId == tenantId).toList();

  T? find(String tenantId, String id) {
    for (final r in _rows) {
      if (r.id == id && r.tenantId == tenantId) return r;
    }
    return null;
  }

  void add(T row) => _rows.add(row);

  void remove(String tenantId, String id) =>
      _rows.removeWhere((r) => r.id == id && r.tenantId == tenantId);

  void removeWhere(String tenantId, bool Function(T) test) =>
      _rows.removeWhere((r) => r.tenantId == tenantId && test(r));

  List<T> get unscoped => List.unmodifiable(_rows);

  void replaceAll(Iterable<T> rows) => _rows
    ..clear()
    ..addAll(rows);
}
