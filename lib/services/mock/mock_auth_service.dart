import '../../core/clock.dart';
import '../../core/errors.dart';
import '../../core/hashing.dart';
import '../../core/ids.dart';
import '../../models/models.dart';
import '../auth_service.dart';
import 'mock_context.dart';

class MockAuthService implements AuthService {
  MockAuthService(this._ctx, {this.identity});

  final MockContext _ctx;

  /// Google sign-in; null in the offline build.
  final IdentityProvider? identity;

  static const _incorrect = 'Incorrect email or password';

  @override
  AppUser? get currentUser => _ctx.currentUser;

  @override
  Tenant? get currentTenant {
    final u = _ctx.currentUser;
    if (u == null) return null;
    for (final t in _ctx.store.tenants) {
      if (t.id == u.tenantId) return t;
    }
    return null;
  }

  @override
  List<Tenant> tenants() => List.of(_ctx.store.tenants);

  @override
  List<DemoAccount> demoAccounts(String tenantId) {
    // Named demo accounts from SRS table 18 use addresses like student@zut.demo;
    // the extra seeded students use first.NN@ and are not offered here.
    final out = <DemoAccount>[
      for (final u in _ctx.store.users.of(tenantId))
        if (u.email.endsWith('.demo') &&
            !u.email.split('@').first.contains('.') &&
            u.active)
          DemoAccount(u.role, u.fullName, u.email),
    ];
    out.sort((a, b) => a.role.index.compareTo(b.role.index));
    return out;
  }

  @override
  Future<AppUser> signIn(String tenantId, String email, String password) async {
    final user = _ctx.store.userByEmailInTenant(tenantId, email);
    if (user == null || user.passwordHash != hashPassword(password)) {
      throw const AuthException(_incorrect);
    }
    return _startSession(user);
  }

  @override
  bool get googleSignInAvailable => identity != null;

  @override
  Future<AppUser?> signInWithGoogle(String tenantId) async {
    final identity = this.identity;
    if (identity == null) {
      throw const AuthException('Google sign-in is only available in the cloud version of the app.');
    }
    if (tenantId == platformTenantId) {
      throw const AuthException('Platform administrators sign in with email and password.');
    }
    if (!_ctx.store.tenants.any((t) => t.id == tenantId)) {
      throw const NotFoundException('This institution is no longer available.');
    }
    final google = await identity.signInWithGoogle();
    if (google == null) return null;
    final email = google.email.trim().toLowerCase();
    // Lookup is scoped to the chosen tenant (FR-TEN-02), so a Google account
    // used at one institution never opens an account at another.
    final existing = _ctx.store.userByEmailInTenant(tenantId, email);
    if (existing != null) return _startSession(existing);

    // SRS-QUESTION: FR-AUTH-04 collects student number, department and year
    // at registration. Google accounts start without them and are always
    // students; staff roles are still granted only by an administrator.
    final user = AppUser(
      id: newId('u'),
      tenantId: tenantId,
      fullName: google.displayName.trim().isEmpty ? email.split('@').first : google.displayName.trim(),
      email: email,
      // No password hash matches an empty string, so password sign-in stays closed.
      passwordHash: '',
      role: Role.student,
      roleGrantedAt: Clock.now(),
    );
    _ctx.store.users.add(user);
    return _startSession(user);
  }

  AppUser _startSession(AppUser user) {
    if (!user.active) {
      throw const AuthException(
          'This account has been deactivated. Contact your institution administrator.');
    }
    // FR-ADM-04: role changes apply at the next sign-in.
    if (user.pendingRole != null) {
      user
        ..role = user.pendingRole!
        ..pendingRole = null
        ..roleGrantedAt = Clock.now();
      _ctx.store.commit();
    }
    _ctx.currentUser = user;
    _ctx.store.commit();
    return user;
  }

  @override
  Future<AppUser> register(RegistrationDraft d) async {
    final errors = <String, String>{};
    if (d.fullName.trim().isEmpty) errors['fullName'] = 'Enter your full name.';
    final email = d.email.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      errors['email'] = 'Enter a valid email address.';
    } else if (_ctx.store.userByEmailInTenant(d.tenantId, email) != null) {
      errors['email'] = 'An account with this email already exists.';
    }
    if (d.studentNumber.trim().isEmpty) {
      errors['studentNumber'] = 'Enter your student number.';
    }
    if (d.departmentId == null) errors['departmentId'] = 'Choose your department.';
    if (d.yearOfStudy == null) errors['yearOfStudy'] = 'Choose your year of study.';
    if (d.password.length < 8) {
      errors['password'] = 'Use at least 8 characters.';
    }
    if (errors.isNotEmpty) throw ValidationException(errors);

    final user = AppUser(
      id: newId('u'),
      tenantId: d.tenantId,
      fullName: d.fullName.trim(),
      email: email,
      passwordHash: hashPassword(d.password),
      role: Role.student,
      roleGrantedAt: Clock.now(),
      studentNumber: d.studentNumber.trim(),
      departmentId: d.departmentId,
      yearOfStudy: d.yearOfStudy,
    );
    _ctx.store.users.add(user);
    _ctx.store.commit();
    return user;
  }

  @override
  Future<void> signOut() async {
    await identity?.signOut();
    _ctx.currentUser = null;
    _ctx.store.commit();
  }

  @override
  Future<void> saveStudyProfile(StudyProfile p) async {
    final user = _ctx.requireSignedIn();
    if (user.role != Role.student) throw const PermissionDeniedException();
    final valid = _ctx.store.courses.of(user.tenantId).map((c) => c.id).toSet();
    if (p.enrolledCourseIds.isEmpty) {
      throw const ValidationException({'courses': 'Choose at least one course.'});
    }
    if (!p.enrolledCourseIds.every(valid.contains)) {
      throw const PermissionDeniedException();
    }
    if (p.studyTimes.isEmpty) {
      throw const ValidationException(
          {'studyTimes': 'Choose at least one preferred study time.'});
    }
    user
      ..enrolledCourseIds = List.of(p.enrolledCourseIds)
      ..examDates = Map.fromEntries(p.examDates.entries
          .where((e) => p.enrolledCourseIds.contains(e.key)))
      ..studyTimePreferences = (List.of(p.studyTimes)..sort())
      ..profileComplete = true;
    _ctx.store.commit();
  }

  @override
  Future<void> updateProfile({String? fullName, int? yearOfStudy}) async {
    final user = _ctx.requireSignedIn();
    if (fullName != null) {
      if (fullName.trim().isEmpty) {
        throw const ValidationException({'fullName': 'Enter your full name.'});
      }
      user.fullName = fullName.trim();
    }
    if (yearOfStudy != null) user.yearOfStudy = yearOfStudy;
    _ctx.store.commit();
  }

  @override
  Future<void> setNotificationPreference(NotificationCategory c, bool enabled) async {
    final user = _ctx.requireSignedIn();
    user.notificationPrefs[c.name] = enabled;
    _ctx.store.commit();
  }

  @override
  List<Department> departmentsFor(String tenantId) =>
      _ctx.store.departments.of(tenantId);

  @override
  List<Course> coursesForCurrentTenant() {
    final user = _ctx.requireSignedIn();
    return _ctx.store.courses.of(user.tenantId)
      ..sort((a, b) => a.code.compareTo(b.code));
  }
}
