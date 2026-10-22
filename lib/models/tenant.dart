import 'json.dart';

class Tenant {
  Tenant({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.themeColour,
    required this.createdAt,
    this.logoAsset,
  });

  final String id;
  String name;
  String shortCode;

  /// Hex string such as `#1B5E20` (FR-TEN-04).
  String themeColour;
  String? logoAsset;
  final DateTime createdAt;

  int get colourValue =>
      int.parse('FF${themeColour.replaceFirst('#', '')}', radix: 16);

  factory Tenant.fromJson(Map<String, dynamic> j) => Tenant(
        id: j['id'],
        name: j['name'],
        shortCode: j['shortCode'],
        themeColour: j['themeColour'],
        logoAsset: j['logoAsset'],
        createdAt: parseDate(j['createdAt'])!,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'shortCode': shortCode,
        'themeColour': themeColour,
        'logoAsset': logoAsset,
        'createdAt': dateToJson(createdAt),
      };
}
