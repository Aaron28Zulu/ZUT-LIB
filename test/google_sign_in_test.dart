import 'package:flutter_test/flutter_test.dart';
import 'package:zutlib/core/errors.dart';
import 'package:zutlib/data/firestore_storage.dart';
import 'package:zutlib/models/models.dart';
import 'package:zutlib/services/auth_service.dart';

import 'helpers.dart';

class FakeIdentity implements IdentityProvider {
  FakeIdentity(this.next);

  ExternalIdentity? next;
  int signOuts = 0;

  @override
  Future<ExternalIdentity?> signInWithGoogle() async => next;

  @override
  Future<void> signOut() async => signOuts++;
}

ExternalIdentity _google(String email, [String name = 'Test Person']) =>
    ExternalIdentity(email: email, displayName: name);

void main() {
  group('Google sign-in', () {
    test('is refused in the offline build', () async {
      final env = await createEnv();
      expect(env.services.auth.googleSignInAvailable, isFalse);
      expect(
        () => env.services.auth.signInWithGoogle('t_zut'),
        throwsA(isA<AuthException>()),
      );
    });

    test('an email with an account in the tenant signs in to it', () async {
      final env = await createEnv(
        identity: FakeIdentity(_google('Librarian@zut.demo')),
      );
      final user = await env.services.auth.signInWithGoogle('t_zut');
      expect(user!.role, Role.librarian);
      expect(env.services.auth.currentUser, same(user));
    });

    test(
      'a new email gets a student account in the chosen tenant only',
      () async {
        final env = await createEnv(
          identity: FakeIdentity(
            _google('new.person@gmail.test', 'Test Person'),
          ),
        );
        final before = env.store.users.of('t_zut').length;
        final user = await env.services.auth.signInWithGoogle('t_zut');
        expect(user!.role, Role.student);
        expect(user.tenantId, 't_zut');
        expect(user.fullName, 'Test Person');
        expect(user.profileComplete, isFalse);
        expect(env.store.users.of('t_zut').length, before + 1);
        expect(
          env.store.userByEmailInTenant('t_nbt', 'new.person@gmail.test'),
          isNull,
        );
      },
    );

    test('a staff email from another tenant does not open that staff account (FR-TEN-02)', () async {
      final env = await createEnv(
        identity: FakeIdentity(_google('librarian@northbridge.demo')),
      );
      final user = await env.services.auth.signInWithGoogle('t_zut');
      expect(user!.tenantId, 't_zut');
      expect(user.role, Role.student);
    });

    test('a Google-created account cannot sign in with a password', () async {
      final env = await createEnv(
        identity: FakeIdentity(_google('new.person@gmail.test')),
      );
      await env.services.auth.signInWithGoogle('t_zut');
      await env.services.auth.signOut();
      expect(
        () => env.services.auth.signIn('t_zut', 'new.person@gmail.test', ''),
        throwsA(isA<AuthException>()),
      );
    });

    test('a deactivated account is refused (FR-ADM-01)', () async {
      final env = await createEnv(
        identity: FakeIdentity(_google('student2@zut.demo')),
      );
      await env.signIn('admin@zut.demo');
      await env.services.admin.setActive('u_zut_natasha', false);
      await env.services.auth.signOut();
      expect(
        () => env.services.auth.signInWithGoogle('t_zut'),
        throwsA(isA<AuthException>()),
      );
      expect(env.services.auth.currentUser, isNull);
    });

    test('is refused for the platform administrator', () async {
      final env = await createEnv(
        identity: FakeIdentity(_google('platform@zutlib.demo')),
      );
      expect(
        () => env.services.auth.signInWithGoogle('platform'),
        throwsA(isA<AuthException>()),
      );
    });

    test('closing the Google sheet leaves the user signed out', () async {
      final env = await createEnv(identity: FakeIdentity(null));
      expect(await env.services.auth.signInWithGoogle('t_zut'), isNull);
      expect(env.services.auth.currentUser, isNull);
    });

    test('signing out also signs out of Google', () async {
      final identity = FakeIdentity(_google('student@zut.demo'));
      final env = await createEnv(identity: identity);
      await env.services.auth.signInWithGoogle('t_zut');
      await env.services.auth.signOut();
      expect(identity.signOuts, 1);
      expect(env.services.auth.currentUser, isNull);
    });
  });

  group('Firestore chunking', () {
    test('splits long values and joins back to the original', () {
      final value = 'abcdefghij' * 25;
      final chunks = splitIntoChunks(value, 100);
      expect(chunks.map((c) => c.length), [100, 100, 50]);
      expect(chunks.join(), value);
    });

    test('keeps an empty value as one empty chunk', () {
      expect(splitIntoChunks(''), ['']);
    });

    test('an exact multiple has no trailing empty chunk', () {
      expect(splitIntoChunks('x' * 200, 100).length, 2);
    });
  });
}
