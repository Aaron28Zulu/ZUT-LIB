import 'json.dart';

class Department implements TenantScoped {
  Department({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.code,
  });

  @override
  final String id;
  @override
  final String tenantId;
  String name;
  String code;

  factory Department.fromJson(Map<String, dynamic> j) => Department(
        id: j['id'],
        tenantId: j['tenantId'],
        name: j['name'],
        code: j['code'],
      );

  Map<String, dynamic> toJson() =>
      {'id': id, 'tenantId': tenantId, 'name': name, 'code': code};
}

class Course implements TenantScoped {
  Course({
    required this.id,
    required this.tenantId,
    required this.departmentId,
    required this.code,
    required this.name,
    required this.yearLevel,
  });

  @override
  final String id;
  @override
  final String tenantId;
  String departmentId;
  String code;
  String name;
  int yearLevel;

  String get label => '$code $name';

  factory Course.fromJson(Map<String, dynamic> j) => Course(
        id: j['id'],
        tenantId: j['tenantId'],
        departmentId: j['departmentId'],
        code: j['code'],
        name: j['name'],
        yearLevel: j['yearLevel'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'departmentId': departmentId,
        'code': code,
        'name': name,
        'yearLevel': yearLevel,
      };
}
