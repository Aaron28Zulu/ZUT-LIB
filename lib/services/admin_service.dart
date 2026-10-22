import '../models/models.dart';

class CountItem {
  const CountItem(this.label, this.count, {this.refId});
  final String label;
  final int count;
  final String? refId;
}

/// FR-ADM-03. Counts only; no student names (NFR-09).
class TenantDashboard {
  const TenantDashboard({
    required this.totalResources,
    required this.searches,
    required this.views,
    required this.activeLoans,
    required this.overdueLoans,
    required this.pendingRequests,
    required this.dueToday,
    required this.quizAttempts,
    required this.mostViewed,
    required this.unmetSearches,
  });

  final int totalResources;
  final int searches;
  final int views;
  final int activeLoans;
  final int overdueLoans;
  final int pendingRequests;
  final int dueToday;
  final int quizAttempts;
  final List<CountItem> mostViewed;
  final List<CountItem> unmetSearches;
}

class NewUserDraft {
  NewUserDraft({
    required this.fullName,
    required this.email,
    required this.role,
    this.studentNumber,
    this.departmentId,
    this.yearOfStudy,
  });

  final String fullName;
  final String email;
  final Role role;
  final String? studentNumber;
  final String? departmentId;
  final int? yearOfStudy;
}

/// Institution administration and reports (SRS 3.8).
abstract interface class AdminService {
  /// FR-ADM-01
  List<AppUser> users({String query = '', Role? role});
  AppUser user(String id);
  Future<AppUser> addUser(NewUserDraft draft);
  Future<void> setActive(String userId, bool active);
  Future<void> changeRole(String userId, Role role);

  /// FR-ADM-04
  List<AppUser> staffRoles();
  Future<void> revokeRole(String userId);

  /// FR-ADM-02
  List<Department> departments();
  List<Course> courses();
  Future<void> saveDepartment({String? id, required String name, required String code});
  Future<void> saveCourse({
    String? id,
    required String departmentId,
    required String code,
    required String name,
    required int yearLevel,
  });
  Future<void> deleteDepartment(String id);
  Future<void> deleteCourse(String id);

  /// FR-ADM-03. Librarians get the same object; screens show only the loans
  /// and resources part (permissions matrix "Partial").
  TenantDashboard dashboard();

  /// FR-ADM-06
  Future<void> sendFeedback(String message);
  List<FeedbackEntry> feedback();
  String feedbackAuthor(FeedbackEntry f);
}
