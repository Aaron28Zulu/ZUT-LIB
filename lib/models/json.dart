DateTime? parseDate(Object? v) =>
    v == null ? null : DateTime.parse(v as String).toUtc();

String? dateToJson(DateTime? d) => d?.toUtc().toIso8601String();

List<String> stringList(Object? v) =>
    v == null ? [] : (v as List).map((e) => e as String).toList();

/// Every entity except Tenant carries a tenantId (SRS 6, FR-TEN-02).
abstract interface class TenantScoped {
  String get id;
  String get tenantId;
}
