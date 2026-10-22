import 'package:flutter_test/flutter_test.dart';
import 'package:zutlib/core/errors.dart';
import 'package:zutlib/core/permissions.dart';
import 'package:zutlib/models/models.dart';
import 'package:zutlib/services/admin_service.dart';
import 'package:zutlib/services/auth_service.dart';
import 'package:zutlib/services/resource_service.dart';

import 'helpers.dart';

void main() {
  group('tenant isolation (FR-TEN-02, NFR-07)', () {
    test('seed contains two tenants with separate data (FR-TEN-01)', () async {
      final env = await createEnv();
      expect(env.store.tenants.map((t) => t.shortCode), ['ZUT', 'NBT']);
      expect(env.store.resources.of('t_zut'), isNotEmpty);
      expect(env.store.resources.of('t_nbt'), isNotEmpty);
    });

    test('a Northbridge student never sees ZUT resources (demo step 13)', () async {
      final env = await createEnv();
      await env.signIn('student@northbridge.demo');
      final r = env.services.resources;
      expect(r.search(const SearchQuery(text: 'ICT 2201')), isEmpty);
      expect(r.search(const SearchQuery()).every((x) => x.tenantId == 't_nbt'), isTrue);
      expect(r.courses().every((c) => c.tenantId == 't_nbt'), isTrue);
      expect(() => r.resource('r_ict2201_2023_final'), throwsA(isA<NotFoundException>()));
    });

    test('a ZUT librarian cannot approve a Northbridge loan', () async {
      final env = await createEnv();
      await env.signIn('librarian@zut.demo');
      expect(() => env.services.loans.approve('l_nbt_01'), throwsA(isA<NotFoundException>()));
      expect(env.services.loans.tenantLoans().every((l) => l.tenantId == 't_zut'), isTrue);
    });

    test('a ZUT librarian cannot collect with a Northbridge QR payload', () async {
      final env = await createEnv();
      await env.signIn('librarian@zut.demo');
      expect(
        () => env.services.loans.collect('ZUTLIB|t_nbt|l_nbt_02|ABCDEF'),
        throwsA(isA<RuleException>().having((e) => e.message, 'message', contains('another institution'))),
      );
    });

    test('sign-in requires the email to belong to the chosen tenant', () async {
      final env = await createEnv();
      expect(
        () => env.services.auth.signIn('t_nbt', 'student@zut.demo', 'demo1234'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Incorrect email or password')),
      );
    });
  });

  group('permissions matrix enforced in services (FR-AUTH-08)', () {
    test('matrix rows match SRS section 4', () {
      expect(roleAllows(Role.student, Permission.borrow), isTrue);
      expect(roleAllows(Role.librarian, Permission.borrow), isFalse);
      expect(roleAllows(Role.platformAdmin, Permission.viewResources), isFalse);
      expect(roleAllows(Role.librarian, Permission.manageUsers), isFalse);
      expect(roleAllows(Role.institutionAdmin, Permission.processLoans), isTrue);
      expect(roleAllows(Role.institutionAdmin, Permission.demoControls), isFalse);
    });

    test('student cannot upload, approve, manage users or reset demo', () async {
      final env = await createEnv();
      await env.signIn('student@zut.demo');
      final s = env.services;
      expect(() => s.resources.upload(ResourceDraft()), throwsA(isA<PermissionDeniedException>()));
      expect(() => s.loans.approve('l_zut_01'), throwsA(isA<PermissionDeniedException>()));
      expect(() => s.admin.users(), throwsA(isA<PermissionDeniedException>()));
      expect(() => s.platform.resetDemoData(), throwsA(isA<PermissionDeniedException>()));
      expect(() => s.study.questionBank('c_ict2201'), throwsA(isA<PermissionDeniedException>()));
      expect(() => s.admin.dashboard(), throwsA(isA<PermissionDeniedException>()));
    });

    test('librarian cannot borrow, use the study assistant or manage users', () async {
      final env = await createEnv();
      await env.signIn('librarian@zut.demo');
      final s = env.services;
      expect(() => s.loans.request('r_ict2201_2023_final'), throwsA(isA<PermissionDeniedException>()));
      expect(() => s.study.startQuiz('c_ict2201', 5), throwsA(isA<PermissionDeniedException>()));
      expect(() => s.admin.addUser(NewUserDraft(fullName: 'X', email: 'x@zut.demo', role: Role.student)),
          throwsA(isA<PermissionDeniedException>()));
      expect(() => s.platform.advanceClock(const Duration(days: 1)), throwsA(isA<PermissionDeniedException>()));
    });

    test('librarian dashboard is partial: no searches, quiz attempts or unmet terms', () async {
      final env = await createEnv();
      await env.signIn('librarian@zut.demo');
      final d = env.services.admin.dashboard();
      expect(d.totalResources, greaterThan(0));
      expect(d.searches, 0);
      expect(d.unmetSearches, isEmpty);
    });

    test('institution admin cannot use demo controls or borrow', () async {
      final env = await createEnv();
      await env.signIn('admin@zut.demo');
      expect(() => env.services.platform.resetClock(), throwsA(isA<PermissionDeniedException>()));
      expect(() => env.services.loans.myLoans(), throwsA(isA<PermissionDeniedException>()));
    });

    test('platform admin cannot view resources or loans', () async {
      final env = await createEnv();
      await env.signIn('platform@zutlib.demo');
      expect(() => env.services.resources.search(const SearchQuery()), throwsA(isA<PermissionDeniedException>()));
      expect(() => env.services.loans.tenantLoans(), throwsA(isA<PermissionDeniedException>()));
    });

    test('signed-out calls are refused', () async {
      final env = await createEnv();
      expect(() => env.services.resources.search(const SearchQuery()), throwsA(isA<AuthException>()));
    });
  });

  group('authentication', () {
    test('wrong password shows the SRS message (FR-AUTH-01)', () async {
      final env = await createEnv();
      expect(
        () => env.services.auth.signIn('t_zut', 'student@zut.demo', 'nope'),
        throwsA(isA<AuthException>().having((e) => e.message, 'message', 'Incorrect email or password')),
      );
    });

    test('demo accounts list the SRS table 18 accounts per tenant (FR-AUTH-03)', () async {
      final env = await createEnv();
      expect(env.services.auth.demoAccounts('t_zut').map((a) => a.email),
          ['student@zut.demo', 'student2@zut.demo', 'librarian@zut.demo', 'admin@zut.demo']);
      expect(env.services.auth.demoAccounts('platform').single.role, Role.platformAdmin);
    });

    test('a deactivated user cannot sign in (FR-ADM-01)', () async {
      final env = await createEnv();
      await env.signIn('admin@zut.demo');
      await env.services.admin.setActive('u_zut_natasha', false);
      await env.services.auth.signOut();
      expect(() => env.signIn('student2@zut.demo'), throwsA(isA<AuthException>()));
    });

    test('registered student can sign in and appears in the admin list (FR-AUTH-04)', () async {
      final env = await createEnv();
      // Registration is open before sign-in, for the selected tenant.
      await env.services.auth.register(
        _draft('t_zut', 'Test Student', 'new.student@zut.demo'),
      );
      await env.services.auth.signIn('t_zut', 'new.student@zut.demo', 'password123');
      expect(env.services.auth.currentUser!.profileComplete, isFalse);
      await env.services.auth.signOut();
      await env.signIn('admin@zut.demo');
      expect(env.services.admin.users(query: 'Test Student'), hasLength(1));
    });

    test('revoked role applies at next sign-in (FR-ADM-04)', () async {
      final env = await createEnv();
      await env.signIn('admin@zut.demo');
      await env.services.admin.revokeRole('u_zut_mary');
      expect(env.store.users.find('t_zut', 'u_zut_mary')!.role, Role.librarian);
      await env.services.auth.signOut();
      await env.signIn('librarian@zut.demo');
      expect(env.services.auth.currentUser!.role, Role.student);
    });
  });
}

RegistrationDraft _draft(String tenant, String name, String email) => RegistrationDraft(
      tenantId: tenant,
      fullName: name,
      email: email,
      studentNumber: '2399999',
      departmentId: 'd_zut_ict',
      yearOfStudy: 1,
      password: 'password123',
    );
