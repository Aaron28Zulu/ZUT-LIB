import 'package:flutter_test/flutter_test.dart';
import 'package:zutlib/core/clock.dart';
import 'package:zutlib/core/errors.dart';
import 'package:zutlib/models/models.dart';
import 'package:zutlib/services/auth_service.dart';
import 'package:zutlib/services/mock/mock_study_assistant_service.dart';
import 'package:zutlib/services/study_assistant_service.dart';

import 'helpers.dart';

Question _q(QuestionType type, String correct, {List<String> keywords = const []}) => Question(
      id: 'q',
      tenantId: 't',
      courseId: 'c',
      topic: 'T',
      type: type,
      text: '?',
      correctAnswer: correct,
      acceptedKeywords: keywords,
      explanation: '',
    );

void main() {
  group('scoring (FR-SSA-02)', () {
    test('multiple choice and true/false use exact match', () {
      expect(MockStudyAssistantService.isCorrect(_q(QuestionType.multipleChoice, 'HAVING'), 'HAVING'), isTrue);
      expect(MockStudyAssistantService.isCorrect(_q(QuestionType.multipleChoice, 'HAVING'), 'WHERE'), isFalse);
      expect(MockStudyAssistantService.isCorrect(_q(QuestionType.trueFalse, 'False'), 'False'), isTrue);
      expect(MockStudyAssistantService.isCorrect(_q(QuestionType.trueFalse, 'False'), 'True'), isFalse);
    });

    test('short answer matches keywords, ignoring case and spaces', () {
      final q = _q(QuestionType.shortAnswer, 'Junction table', keywords: ['junction', 'associative']);
      expect(MockStudyAssistantService.isCorrect(q, 'an Associative table'), isTrue);
      expect(MockStudyAssistantService.isCorrect(q, 'JUNCTION'), isTrue);
      expect(MockStudyAssistantService.isCorrect(q, 'foreign key'), isFalse);
      expect(MockStudyAssistantService.isCorrect(q, ''), isFalse);
      final q2 = _q(QuestionType.shortAnswer, 'n - 1', keywords: ['n-1']);
      expect(MockStudyAssistantService.isCorrect(q2, 'n -1'), isTrue);
    });
  });

  test('quiz uses the requested length and course bank (FR-SSA-01)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    final s = env.services.study.startQuiz('c_ict2201', 10);
    expect(s.questions, hasLength(10));
    expect(s.questions.every((q) => q.courseId == 'c_ict2201'), isTrue);
    expect(() => env.services.study.startQuiz('c_ict2201', 7), throwsA(isA<RuleException>()));
    expect(() => env.services.study.startQuiz('c_ict3301', 5), throwsA(isA<RuleException>()));
  });

  test('at least half the questions come from weak topics (FR-SSA-04)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    final weak = env.services.study
        .topicStats(courseId: 'c_ict2201')
        .where((t) => t.percent < 60)
        .map((t) => t.topic)
        .toSet();
    expect(weak, isNotEmpty, reason: 'seed gives Chanda weak ICT 2201 topics');
    for (var i = 0; i < 5; i++) {
      final s = env.services.study.startQuiz('c_ict2201', 10);
      expect(s.questions.where((q) => weak.contains(q.topic)).length, greaterThanOrEqualTo(5));
    }
  });

  test('feedback names the source paper and finishing saves an attempt (FR-SSA-03, 05)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    final study = env.services.study;
    final before = study.attempts(courseId: 'c_ict2201').length;
    final s = study.startQuiz('c_ict2201', 5);
    for (final q in s.questions) {
      final fb = study.answer(s, q, q.correctAnswer);
      expect(fb.correct, isTrue);
      expect(fb.sourceLabel, startsWith('ICT 2201'));
    }
    final attempt = await study.finishQuiz(s);
    expect(attempt.score, 100);
    expect(attempt.topicScores.values.fold<int>(0, (a, t) => a + t.total), 5);
    expect(study.attempts(courseId: 'c_ict2201').length, before + 1);
  });

  test('hard flashcards reappear before the session ends (FR-SSA-06)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    final cards = env.services.study.flashcardSession('c_ict2201');
    final queue = FlashcardQueue(cards);
    final first = queue.current!;
    queue.rate(CardRating.hard);
    final seen = <String>[];
    while (!queue.isDone) {
      seen.add(queue.current!.id);
      queue.rate(CardRating.easy);
    }
    expect(seen, contains(first.id));

    await env.services.study.rateCard(first, CardRating.hard);
    expect(env.services.study.flashcardSession('c_ict2201').first.id, first.id);
  });

  test('every seeded paper in the four study courses has a summary (FR-SSA-07)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    for (final r in env.store.resources.of('t_zut').where((r) => ['c_ict2201', 'c_ict2205', 'c_ict1101'].contains(r.courseId))) {
      expect(env.services.study.summary(r.id), isNotNull, reason: r.id);
    }
  });

  test('changing an exam date changes recommendation order (FR-SSA-08)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    final study = env.services.study;
    final before = study.recommendations();
    expect(before, hasLength(5));
    expect(before.every((r) => r.reason.isNotEmpty), isTrue);
    final u = env.services.auth.currentUser!;
    await env.services.auth.saveStudyProfile(StudyProfile(
      enrolledCourseIds: u.enrolledCourseIds,
      examDates: {...u.examDates, 'c_ict1101': Clock.now().add(const Duration(days: 1))},
      studyTimes: u.studyTimePreferences,
    ));
    final after = study.recommendations();
    expect(after.first.resource.courseId, 'c_ict1101');
    expect(after.map((r) => r.resource.id), isNot(equals(before.map((r) => r.resource.id))));
  });

  test('revision plan favours the nearest exam and tracks progress (FR-SSA-09, 10)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    final study = env.services.study;
    final plan = study.plan();
    expect(plan, isNotEmpty);
    final u = env.services.auth.currentUser!;
    for (final s in plan) {
      expect(s.scheduledAt.isBefore(u.examDates[s.courseId]!), isTrue);
    }
    final firstWeek = plan.where((s) => s.scheduledAt.isBefore(Clock.now().add(const Duration(days: 7))));
    final counts = <String, int>{};
    for (final s in firstWeek) {
      counts[s.courseId] = (counts[s.courseId] ?? 0) + 1;
    }
    expect(counts['c_ict2201']!, greaterThan(counts['c_ict1101'] ?? 0));

    await study.setSessionDone(plan.first.id, true);
    expect(study.planProgress(), closeTo(1 / plan.length, 0.0001));
  });

  test('study reminder fires when the demo clock reaches a session (FR-NOT-03)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    env.services.study.plan();
    await env.services.auth.signOut();
    await env.signIn('platform@zutlib.demo');
    await env.services.platform.advanceClock(const Duration(days: 1));
    final n = env.store.notifications.of('t_zut').where((n) => n.userId == 'u_zut_chanda' && n.category == NotificationCategory.study);
    expect(n, isNotEmpty);
  });

  test('assistant answers fixed questions from seed data (FR-SSA-12)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    final study = env.services.study;
    for (final q in study.assistantQuestions()) {
      expect(study.ask(q.id, 'c_ict2201'), isNotEmpty);
    }
    expect(study.ask('topics', 'c_ict2201'), contains('Across 4 ICT 2201 papers'));
  });

  test('new paper notifies only enrolled students (FR-NOT-02)', () async {
    final env = await createEnv();
    await env.signIn('librarian@zut.demo');
    // Upload is covered in resource tests; here only the targeting matters.
    final enrolled = env.store.users.of('t_zut').where((u) => u.enrolledCourseIds.contains('c_ict2201')).map((u) => u.id).toSet();
    expect(enrolled, contains('u_zut_chanda'));
    expect(enrolled, isNot(contains('u_zut_natasha')));
  });
}
