import 'package:cloud_firestore/cloud_firestore.dart';

import 'storage.dart';

/// Firestore documents hold at most 1 MiB, so long values are split.
/// 200,000 characters stays under the limit even if every one needs 4 bytes.
const firestoreChunkLength = 200000;

/// Splits [value] into pieces of at most [length] characters. An empty value
/// is one empty piece, so a read can tell "empty" from "missing".
List<String> splitIntoChunks(
  String value, [
  int length = firestoreChunkLength,
]) => [
  for (var i = 0; i < value.length || i == 0; i += length)
    value.substring(i, i + length < value.length ? i + length : value.length),
];

/// Cloud mode persistence: the same keys [DataStore] writes locally, kept in
/// the `zutlib_kv` collection. Each key is one document with a `parts` count
/// and the text in a `parts` subcollection (`0`, `1`, ...).
///
/// Firestore keeps an on-device cache, so reads still work without signal and
/// writes are sent when the connection returns.
class FirestoreStorage implements KeyValueStorage {
  FirestoreStorage(this._db, {required this.ensureSignedIn});

  final FirebaseFirestore _db;

  /// The security rules only accept signed-in clients (firestore.rules).
  final Future<void> Function() ensureSignedIn;

  static const collection = 'zutlib_kv';

  DocumentReference<Map<String, dynamic>> _doc(String key) =>
      _db.collection(collection).doc(key);

  @override
  Future<String?> read(String key) async {
    await ensureSignedIn();
    final head = await _doc(key).get();
    final count = head.data()?['parts'] as int?;
    if (count == null) return null;
    final parts = await Future.wait([
      for (var i = 0; i < count; i++)
        _doc(key).collection('parts').doc('$i').get(),
    ]);
    final buffer = StringBuffer();
    for (final p in parts) {
      final data = p.data()?['data'] as String?;
      // A missing piece means a write was cut off; treat the key as unset.
      if (data == null) return null;
      buffer.write(data);
    }
    return buffer.toString();
  }

  @override
  Future<void> write(String key, String value) async {
    await ensureSignedIn();
    final chunks = splitIntoChunks(value);
    final head = await _doc(key).get();
    final oldCount = head.data()?['parts'] as int? ?? 0;
    final batch = _db.batch();
    for (final (i, chunk) in chunks.indexed) {
      batch.set(_doc(key).collection('parts').doc('$i'), {'data': chunk});
    }
    for (var i = chunks.length; i < oldCount; i++) {
      batch.delete(_doc(key).collection('parts').doc('$i'));
    }
    batch.set(_doc(key), {
      'parts': chunks.length,
      'savedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  @override
  Future<void> delete(String key) async {
    await ensureSignedIn();
    final head = await _doc(key).get();
    final count = head.data()?['parts'] as int? ?? 0;
    final batch = _db.batch();
    for (var i = 0; i < count; i++) {
      batch.delete(_doc(key).collection('parts').doc('$i'));
    }
    batch.delete(_doc(key));
    await batch.commit();
  }
}
