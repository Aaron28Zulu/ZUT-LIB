import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../core/clock.dart';
import '../models/models.dart';
import 'storage.dart';
import 'tenant_table.dart';

/// Reads one bundled seed file by name, e.g. `resources` -> assets/seed/resources.json.
typedef SeedReader = Future<String> Function(String name);

const seedFiles = [
  'meta',
  'tenants',
  'departments',
  'courses',
  'users',
  'resources',
  'copies',
  'loans',
  'questions',
  'flashcards',
  'quizAttempts',
  'usageEvents',
  'notifications',
  'feedback',
];

final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$');

/// The mock database: every table of SRS section 6 held in memory, loaded from
/// seed JSON (FR-DEMO-01) and persisted after each change (FR-DEMO-04).
class DataStore extends ChangeNotifier {
  DataStore({required this.storage, required this.seedReader});

  static const _stateKey = 'zutlib.state.v1';
  static const _filePrefix = 'zutlib.file.';

  final KeyValueStorage storage;
  final SeedReader seedReader;

  final List<Tenant> tenants = [];
  final users = TenantTable<AppUser>();
  final departments = TenantTable<Department>();
  final courses = TenantTable<Course>();
  final resources = TenantTable<Resource>();
  final copies = TenantTable<PhysicalCopy>();
  final loans = TenantTable<Loan>();
  final questions = TenantTable<Question>();
  final flashcards = TenantTable<Flashcard>();
  final flashcardReviews = TenantTable<FlashcardReview>();
  final quizAttempts = TenantTable<QuizAttempt>();
  final planSessions = TenantTable<StudyPlanSession>();
  final notifications = TenantTable<AppNotification>();
  final usageEvents = TenantTable<UsageEvent>();
  final feedback = TenantTable<FeedbackEntry>();

  /// Per-user device conveniences keyed by user id.
  final Map<String, List<String>> bookmarks = {};
  final Map<String, List<String>> recentSearches = {};
  final Map<String, List<String>> recentViews = {};

  /// Every resource a user has opened, for recommendations (FR-SSA-08).
  final Map<String, List<String>> viewed = {};

  /// Device-level demo settings.
  bool shortSessionTimeout = false;
  bool onboardingSeen = false;

  Timer? _saveTimer;

  Future<void> init() async {
    final saved = await storage.read(_stateKey);
    if (saved != null) {
      try {
        _fromJson(jsonDecode(saved) as Map<String, dynamic>);
        return;
      } on Object catch (e) {
        debugPrint('Saved demo state unreadable, reloading seed: $e');
      }
    }
    await loadSeed();
  }

  /// FR-DEMO-01 / FR-DEMO-02. Dates in the seed are shifted so the seed anchor
  /// becomes "now", keeping due dates and two weeks of history current.
  Future<void> loadSeed() async {
    Clock.reset();
    final raw = <String, dynamic>{};
    for (final name in seedFiles) {
      raw[name] = jsonDecode(await seedReader(name));
    }
    final anchor = DateTime.parse(raw['meta']['seedAnchor'] as String);
    final shift = Clock.now().difference(anchor);
    final shifted = _shiftDates(raw, shift) as Map<String, dynamic>;
    final keepOnboarding = onboardingSeen;
    _fromJson({...shifted, 'onboardingSeen': keepOnboarding});
    await _saveNow();
    notifyListeners();
  }

  Object? _shiftDates(Object? node, Duration shift) {
    if (node is Map) {
      return node.map((k, v) => MapEntry(k as String, _shiftDates(v, shift)));
    }
    if (node is List) return node.map((v) => _shiftDates(v, shift)).toList();
    if (node is String && _isoDate.hasMatch(node)) {
      return DateTime.parse(node).add(shift).toUtc().toIso8601String();
    }
    return node;
  }

  bool _notifyScheduled = false;

  /// Call after every mutation. Notifies listeners and schedules a save.
  /// Notification is deferred to a microtask so a service may commit while a
  /// screen is building (e.g. a revision plan generated on first view).
  void commit() {
    if (!_notifyScheduled) {
      _notifyScheduled = true;
      scheduleMicrotask(() {
        _notifyScheduled = false;
        notifyListeners();
      });
    }
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 300), _saveNow);
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    await _saveNow();
  }

  Future<void> _saveNow() =>
      storage.write(_stateKey, jsonEncode(_toJson()));

  // Uploaded PDF bytes are stored separately so the main state stays small.
  Future<void> saveFile(String fileId, Uint8List bytes) =>
      storage.write('$_filePrefix$fileId', base64Encode(bytes));

  Future<Uint8List?> readFile(String fileId) async {
    final v = await storage.read('$_filePrefix$fileId');
    return v == null ? null : base64Decode(v);
  }

  Map<String, dynamic> _toJson() => {
        'clockOffsetMinutes': Clock.offset.inMinutes,
        'shortSessionTimeout': shortSessionTimeout,
        'onboardingSeen': onboardingSeen,
        'tenants': tenants.map((e) => e.toJson()).toList(),
        'users': users.unscoped.map((e) => e.toJson()).toList(),
        'departments': departments.unscoped.map((e) => e.toJson()).toList(),
        'courses': courses.unscoped.map((e) => e.toJson()).toList(),
        'resources': resources.unscoped.map((e) => e.toJson()).toList(),
        'copies': copies.unscoped.map((e) => e.toJson()).toList(),
        'loans': loans.unscoped.map((e) => e.toJson()).toList(),
        'questions': questions.unscoped.map((e) => e.toJson()).toList(),
        'flashcards': flashcards.unscoped.map((e) => e.toJson()).toList(),
        'flashcardReviews':
            flashcardReviews.unscoped.map((e) => e.toJson()).toList(),
        'quizAttempts': quizAttempts.unscoped.map((e) => e.toJson()).toList(),
        'planSessions': planSessions.unscoped.map((e) => e.toJson()).toList(),
        'notifications':
            notifications.unscoped.map((e) => e.toJson()).toList(),
        'usageEvents': usageEvents.unscoped.map((e) => e.toJson()).toList(),
        'feedback': feedback.unscoped.map((e) => e.toJson()).toList(),
        'bookmarks': bookmarks,
        'recentSearches': recentSearches,
        'recentViews': recentViews,
        'viewed': viewed,
      };

  void _fromJson(Map<String, dynamic> j) {
    List<T> rows<T>(String key, T Function(Map<String, dynamic>) f) =>
        (j[key] as List? ?? []).map((e) => f(e as Map<String, dynamic>)).toList();
    Map<String, List<String>> lists(String key) =>
        (j[key] as Map<String, dynamic>? ?? {}).map(
            (k, v) => MapEntry(k, (v as List).map((e) => e as String).toList()));

    Clock.setOffset(Duration(minutes: j['clockOffsetMinutes'] as int? ?? 0));
    shortSessionTimeout = j['shortSessionTimeout'] as bool? ?? false;
    onboardingSeen = j['onboardingSeen'] as bool? ?? false;
    tenants
      ..clear()
      ..addAll(rows('tenants', Tenant.fromJson));
    users.replaceAll(rows('users', AppUser.fromJson));
    departments.replaceAll(rows('departments', Department.fromJson));
    courses.replaceAll(rows('courses', Course.fromJson));
    resources.replaceAll(rows('resources', Resource.fromJson));
    copies.replaceAll(rows('copies', PhysicalCopy.fromJson));
    loans.replaceAll(rows('loans', Loan.fromJson));
    questions.replaceAll(rows('questions', Question.fromJson));
    flashcards.replaceAll(rows('flashcards', Flashcard.fromJson));
    flashcardReviews.replaceAll(rows('flashcardReviews', FlashcardReview.fromJson));
    quizAttempts.replaceAll(rows('quizAttempts', QuizAttempt.fromJson));
    planSessions.replaceAll(rows('planSessions', StudyPlanSession.fromJson));
    notifications.replaceAll(rows('notifications', AppNotification.fromJson));
    usageEvents.replaceAll(rows('usageEvents', UsageEvent.fromJson));
    feedback.replaceAll(rows('feedback', FeedbackEntry.fromJson));
    bookmarks
      ..clear()
      ..addAll(lists('bookmarks'));
    recentSearches
      ..clear()
      ..addAll(lists('recentSearches'));
    recentViews
      ..clear()
      ..addAll(lists('recentViews'));
    viewed
      ..clear()
      ..addAll(lists('viewed'));
  }

  /// Users are looked up across tenants only to sign in (the user chooses the
  /// tenant first; the email must belong to it).
  AppUser? userByEmailInTenant(String tenantId, String email) {
    final e = email.trim().toLowerCase();
    for (final u in users.of(tenantId)) {
      if (u.email.toLowerCase() == e) return u;
    }
    return null;
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }
}
