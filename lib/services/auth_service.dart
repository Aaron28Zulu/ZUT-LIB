import '../models/models.dart';

class DemoAccount {
  const DemoAccount(this.role, this.name, this.email);
  final Role role;
  final String name;
  final String email;
}

class RegistrationDraft {
  RegistrationDraft({
    required this.tenantId,
    required this.fullName,
    required this.email,
    required this.studentNumber,
    required this.departmentId,
    required this.yearOfStudy,
    required this.password,
  });

  final String tenantId;
  final String fullName;
  final String email;
  final String studentNumber;
  final String? departmentId;
  final int? yearOfStudy;
  final String password;
}

class StudyProfile {
  StudyProfile({
    required this.enrolledCourseIds,
    required this.examDates,
    required this.studyTimes,
  });

  final List<String> enrolledCourseIds;
  final Map<String, DateTime> examDates;
  final List<String> studyTimes;
}

/// A Google account confirmed by the identity backend.
class ExternalIdentity {
  const ExternalIdentity({required this.email, required this.displayName});
  final String email;
  final String displayName;
}

/// Third-party sign-in (Firebase Authentication in cloud mode). The auth
/// service decides which ZutLib account, if any, the identity maps to.
abstract interface class IdentityProvider {
  /// Returns null when the user closes the Google sign-in sheet.
  Future<ExternalIdentity?> signInWithGoogle();

  Future<void> signOut();
}

/// Pseudo-tenant id used by the platform administrator account.
const platformTenantId = 'platform';

/// Authentication and profiles (SRS 3.2). Swappable for Firebase Auth (NFR-11).
abstract interface class AuthService {
  AppUser? get currentUser;
  Tenant? get currentTenant;

  /// FR-TEN-03: institutions shown on the sign-in screen.
  List<Tenant> tenants();

  /// FR-AUTH-03
  List<DemoAccount> demoAccounts(String tenantId);

  /// FR-AUTH-01. Throws [AuthException] with "Incorrect email or password".
  Future<AppUser> signIn(String tenantId, String email, String password);

  /// FR-AUTH-04
  Future<AppUser> register(RegistrationDraft draft);

  /// Whether "Continue with Google" is offered (cloud builds only).
  bool get googleSignInAvailable;

  /// Signs in to [tenantId] with a Google account. An email that already has
  /// an account there signs in to it; a new email gets a student account.
  /// Returns null if the user cancelled.
  Future<AppUser?> signInWithGoogle(String tenantId);

  Future<void> signOut();

  /// FR-AUTH-05
  Future<void> saveStudyProfile(StudyProfile profile);

  /// FR-AUTH-06
  Future<void> updateProfile({String? fullName, int? yearOfStudy});

  /// FR-NOT-06
  Future<void> setNotificationPreference(NotificationCategory c, bool enabled);

  /// Lookup within the signed-in user's tenant (department names on profile).
  List<Department> departmentsFor(String tenantId);
  List<Course> coursesForCurrentTenant();
}
