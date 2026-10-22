import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../core/errors.dart';
import '../auth_service.dart';

/// Google sign-in through Firebase Authentication (cloud mode only).
///
/// Android opens Google's sign-in page in a browser tab, which needs the
/// app's SHA-1 fingerprint registered in the Firebase project; web uses a
/// pop-up. When no one is signed in with Google, the app keeps an anonymous
/// Firebase session so Firestore accepts its reads and writes.
class FirebaseIdentityProvider implements IdentityProvider {
  FirebaseIdentityProvider(this._auth);

  final FirebaseAuth _auth;

  static const _cancelCodes = {
    'canceled',
    'cancelled',
    'web-context-canceled',
    'popup-closed-by-user',
    'cancelled-popup-request',
  };

  /// Signs in anonymously unless a Google (or anonymous) session exists.
  Future<void> ensureSignedIn() async {
    if (_auth.currentUser == null) await _auth.signInAnonymously();
  }

  @override
  Future<ExternalIdentity?> signInWithGoogle() async {
    final provider = GoogleAuthProvider()..addScope('email');
    final UserCredential result;
    try {
      result = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
    } on FirebaseAuthException catch (e) {
      if (_cancelCodes.contains(e.code)) return null;
      debugPrint('Google sign-in failed: ${e.code} ${e.message}');
      throw const AuthException(
        'Google sign-in did not work. Check your connection and try again.',
      );
    }
    final user = result.user;
    final email = user?.email;
    if (email == null) {
      throw const AuthException(
        'Your Google account did not share an email address.',
      );
    }
    return ExternalIdentity(email: email, displayName: user?.displayName ?? '');
  }

  @override
  Future<void> signOut() async {
    if (_auth.currentUser?.isAnonymous ?? true) return;
    await _auth.signOut();
  }
}
