import 'enums.dart';
import 'json.dart';

class AppUser implements TenantScoped {
  AppUser({
    required this.id,
    required this.tenantId,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.roleGrantedAt,
    this.studentNumber,
    this.departmentId,
    this.yearOfStudy,
    List<String>? enrolledCourseIds,
    Map<String, DateTime>? examDates,
    List<String>? studyTimePreferences,
    this.active = true,
    this.profileComplete = false,
    Map<String, bool>? notificationPrefs,
    this.pendingRole,
  })  : enrolledCourseIds = enrolledCourseIds ?? [],
        examDates = examDates ?? {},
        studyTimePreferences = studyTimePreferences ?? [],
        notificationPrefs = notificationPrefs ?? {};

  @override
  final String id;
  @override
  final String tenantId;
  String fullName;
  String email;
  String passwordHash;
  Role role;
  DateTime roleGrantedAt;

  /// FR-ADM-04: a revoked or changed role takes effect at the next sign-in.
  Role? pendingRole;
  String? studentNumber;
  String? departmentId;
  int? yearOfStudy;
  List<String> enrolledCourseIds;

  /// courseId -> examination date (FR-AUTH-05).
  Map<String, DateTime> examDates;

  /// "HH:mm" strings (FR-AUTH-05).
  List<String> studyTimePreferences;
  bool active;
  bool profileComplete;

  /// NotificationCategory.name -> enabled (FR-NOT-06). Missing means enabled.
  Map<String, bool> notificationPrefs;

  bool wantsCategory(NotificationCategory c) => notificationPrefs[c.name] ?? true;

  String get firstName => fullName.split(' ').first;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'],
        tenantId: j['tenantId'],
        fullName: j['fullName'],
        email: j['email'],
        passwordHash: j['passwordHash'],
        role: enumByName(Role.values, j['role']),
        pendingRole: j['pendingRole'] == null
            ? null
            : enumByName(Role.values, j['pendingRole']),
        roleGrantedAt: parseDate(j['roleGrantedAt'])!,
        studentNumber: j['studentNumber'],
        departmentId: j['departmentId'],
        yearOfStudy: j['yearOfStudy'],
        enrolledCourseIds: stringList(j['enrolledCourseIds']),
        examDates: (j['examDates'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, parseDate(v)!)),
        studyTimePreferences: stringList(j['studyTimePreferences']),
        active: j['active'] ?? true,
        profileComplete: j['profileComplete'] ?? false,
        notificationPrefs:
            (j['notificationPrefs'] as Map<String, dynamic>? ?? {})
                .map((k, v) => MapEntry(k, v as bool)),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'fullName': fullName,
        'email': email,
        'passwordHash': passwordHash,
        'role': role.name,
        'pendingRole': pendingRole?.name,
        'roleGrantedAt': dateToJson(roleGrantedAt),
        'studentNumber': studentNumber,
        'departmentId': departmentId,
        'yearOfStudy': yearOfStudy,
        'enrolledCourseIds': enrolledCourseIds,
        'examDates': examDates.map((k, v) => MapEntry(k, dateToJson(v))),
        'studyTimePreferences': studyTimePreferences,
        'active': active,
        'profileComplete': profileComplete,
        'notificationPrefs': notificationPrefs,
      };
}
