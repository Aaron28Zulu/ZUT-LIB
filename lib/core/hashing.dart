import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Mock password hash for seeded demo accounts. Mirrors tools/generate_seed.py.
/// A production build would use Firebase Authentication instead (SRS 13).
String hashPassword(String password) =>
    sha256.convert(utf8.encode('zutlib-demo-salt:$password')).toString();
