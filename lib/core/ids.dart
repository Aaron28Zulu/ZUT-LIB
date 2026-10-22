import 'dart:math';

final _random = Random.secure();

/// A collision-resistant id with a readable prefix, e.g. `l_k3j9x2m1q8`.
String newId(String prefix) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final suffix =
      List.generate(10, (_) => chars[_random.nextInt(chars.length)]).join();
  return '${prefix}_$suffix';
}

/// Random collection code without look-alike characters (NFR-08: no personal data).
String newCollectionToken(int length) {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return List.generate(length, (_) => chars[_random.nextInt(chars.length)])
      .join();
}
