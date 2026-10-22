import 'dart:math';

import '../../core/clock.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/ids.dart';
import '../../core/permissions.dart';
import '../../core/rules.dart';
import '../../models/models.dart';
import '../study_assistant_service.dart';
import 'mock_context.dart';

/// Rule-based study assistant (FR-SSA-13). No language model: every answer is
/// computed from the tagged seed data.
class MockStudyAssistantService implements StudyAssistantService {
  MockStudyAssistantService(this._ctx, {Random? random}) : _random = random ?? Random();

  final MockContext _ctx;
  final Random _random;

  AppUser get _student => _ctx.require(Permission.useStudyAssistant);

  Course _enrolledCourse(AppUser u, String courseId) {
    final c = _ctx.store.courses.find(u.tenantId, courseId);
    if (c == null) throw const NotFoundException('That course could not be found.');
    if (!u.enrolledCourseIds.contains(courseId)) {
      throw const RuleException('Add this course to your profile to study it.');
    }
    return c;
  }

  @override
  List<Course> enrolledCourses() {
    final u = _student;
    return [
      for (final id in u.enrolledCourseIds)
        if (_ctx.store.courses.find(u.tenantId, id) != null)
          _ctx.store.courses.find(u.tenantId, id)!,
    ]..sort((a, b) => a.code.compareTo(b.code));
  }

  List<Question> _questions(String tenantId, String courseId, {String? topic}) =>
      _ctx.store.questions
          .of(tenantId)
          .where((q) => q.courseId == courseId && (topic == null || q.topic == topic))
          .toList();

  @override
  List<String> topicsFor(String courseId) {
    final u = _ctx.requireSignedIn();
    return {for (final q in _questions(u.tenantId, courseId)) q.topic}.toList()..sort();
  }

  @override
  int questionCount(String courseId, {String? topic}) =>
      _questions(_ctx.requireSignedIn().tenantId, courseId, topic: topic).length;

  Map<String, TopicScore> _topicTotals(AppUser u, String? courseId) {
    final totals = <String, TopicScore>{};
    for (final a in _ctx.store.quizAttempts.of(u.tenantId)) {
      if (a.studentId != u.id || (courseId != null && a.courseId != courseId)) continue;
      a.topicScores.forEach((topic, s) {
        final t = totals.putIfAbsent('${a.courseId}|$topic', TopicScore.new);
        t.correct += s.correct;
        t.total += s.total;
      });
    }
    return totals;
  }

  Set<String> _weakTopics(AppUser u, String courseId) => {
        for (final e in _topicTotals(u, courseId).entries)
          if (e.value.total > 0 && e.value.percent < Rules.weakTopicThreshold)
            e.key.split('|').last,
      };

  @override
  QuizSession startQuiz(String courseId, int count, {String? topic}) {
    final u = _student;
    _enrolledCourse(u, courseId);
    if (!Rules.quizLengths.contains(count)) {
      throw const RuleException('Choose 5, 10 or 20 questions.');
    }
    final pool = _questions(u.tenantId, courseId, topic: topic)..shuffle(_random);
    if (pool.isEmpty) {
      throw const RuleException('There are no practice questions for this course yet.');
    }

    // FR-SSA-04: at least half from weak topics when enough exist.
    final weak = topic == null ? _weakTopics(u, courseId) : <String>{};
    final chosen = <Question>[];
    if (weak.isNotEmpty) {
      final weakPool = pool.where((q) => weak.contains(q.topic)).toList();
      final otherPool = pool.where((q) => !weak.contains(q.topic)).toList();
      final weakTarget = (count / 2).ceil();
      chosen.addAll(weakPool.take(weakTarget));
      chosen.addAll(otherPool.take(count - chosen.length));
      chosen.addAll(weakPool.skip(weakTarget).take(count - chosen.length));
      chosen.shuffle(_random);
    } else {
      chosen.addAll(pool.take(count));
    }
    return QuizSession(
      courseId: courseId,
      topic: topic,
      questions: chosen,
      startedAt: Clock.now(),
    );
  }

  static String _norm(String s) => s.toLowerCase().replaceAll(RegExp(r'\s+'), '');

  /// FR-SSA-02: exact match for choice questions, keyword match for short answers.
  static bool isCorrect(Question q, String answer) {
    if (q.type != QuestionType.shortAnswer) return answer == q.correctAnswer;
    final a = _norm(answer);
    if (a.isEmpty) return false;
    if (a == _norm(q.correctAnswer)) return true;
    return q.acceptedKeywords.any((k) => a.contains(_norm(k)));
  }

  @override
  AnswerFeedback answer(QuizSession session, Question q, String answer) {
    final u = _student;
    session.answers[q.id] = answer;
    final src = q.sourceResourceId == null
        ? null
        : _ctx.store.resources.find(u.tenantId, q.sourceResourceId!);
    return AnswerFeedback(
      correct: isCorrect(q, answer),
      correctAnswer: q.correctAnswer,
      explanation: q.explanation,
      sourceLabel: src == null ? 'Question bank' : _ctx.resourceLabel(src),
    );
  }

  @override
  Future<QuizAttempt> finishQuiz(QuizSession session) async {
    final u = _student;
    final topicScores = <String, TopicScore>{};
    var correct = 0;
    for (final q in session.questions) {
      final ok = isCorrect(q, session.answers[q.id] ?? '');
      final t = topicScores.putIfAbsent(q.topic, TopicScore.new);
      t.total++;
      if (ok) {
        t.correct++;
        correct++;
      }
    }
    final attempt = QuizAttempt(
      id: newId('a'),
      tenantId: u.tenantId,
      studentId: u.id,
      courseId: session.courseId,
      questionIds: [for (final q in session.questions) q.id],
      answers: Map.of(session.answers),
      score: session.questions.isEmpty ? 0 : (correct * 100 / session.questions.length).round(),
      topicScores: topicScores,
      startedAt: session.startedAt,
      finishedAt: Clock.now(),
    );
    _ctx.store.quizAttempts.add(attempt);
    _ctx.logEvent(u.tenantId, UsageEventType.quiz, refId: attempt.id);
    _ctx.store.commit();
    return attempt;
  }

  @override
  List<QuizAttempt> attempts({String? courseId}) {
    final u = _student;
    return _ctx.store.quizAttempts
        .of(u.tenantId)
        .where((a) => a.studentId == u.id && (courseId == null || a.courseId == courseId))
        .toList()
      ..sort((a, b) => a.finishedAt.compareTo(b.finishedAt));
  }

  // ------------------------------------------------------------ flashcards

  Map<String, FlashcardReview> _reviews(AppUser u) => {
        for (final r in _ctx.store.flashcardReviews.of(u.tenantId))
          if (r.studentId == u.id) r.flashcardId: r,
      };

  @override
  List<Flashcard> flashcardSession(String courseId) {
    final u = _student;
    _enrolledCourse(u, courseId);
    final reviews = _reviews(u);
    final now = Clock.now();
    final cards = _ctx.store.flashcards.of(u.tenantId).where((f) => f.courseId == courseId).toList()
      ..shuffle(_random);
    // Hard cards from the last session come first, then unseen, then by due date.
    DateTime due(Flashcard f) => reviews[f.id]?.nextDueAt ?? now;
    int rank(Flashcard f) => switch (reviews[f.id]?.rating) {
          CardRating.hard => 0,
          null => 1,
          CardRating.good => 2,
          CardRating.easy => 3,
        };
    cards.sort((a, b) {
      final r = rank(a).compareTo(rank(b));
      return r != 0 ? r : due(a).compareTo(due(b));
    });
    return cards;
  }

  @override
  Future<void> rateCard(Flashcard card, CardRating rating) async {
    final u = _student;
    final now = Clock.now();
    final next = now.add(switch (rating) {
      CardRating.hard => const Duration(minutes: 10),
      CardRating.good => const Duration(days: 1),
      CardRating.easy => const Duration(days: 3),
    });
    final existing = _reviews(u)[card.id];
    if (existing != null) {
      existing
        ..rating = rating
        ..reviewedAt = now
        ..nextDueAt = next;
    } else {
      _ctx.store.flashcardReviews.add(FlashcardReview(
        id: newId('fr'),
        tenantId: u.tenantId,
        studentId: u.id,
        flashcardId: card.id,
        rating: rating,
        reviewedAt: now,
        nextDueAt: next,
      ));
    }
    _ctx.store.commit();
  }

  @override
  int flashcardCount(String courseId) => _ctx.store.flashcards
      .of(_ctx.requireSignedIn().tenantId)
      .where((f) => f.courseId == courseId)
      .length;

  // ------------------------------------------------------------ summaries and recommendations

  @override
  ResourceSummary? summary(String resourceId) {
    final u = _ctx.require(Permission.viewResources);
    return _ctx.store.resources.find(u.tenantId, resourceId)?.summary;
  }

  int? _daysUntilExam(AppUser u, String courseId) {
    final exam = u.examDates[courseId];
    if (exam == null) return null;
    final days = exam.difference(Clock.now()).inHours / 24;
    return days < 0 ? null : days.ceil();
  }

  @override
  List<Recommendation> recommendations() {
    final u = _student;
    final viewed = _ctx.store.viewed[u.id]?.toSet() ?? <String>{};
    final courses = {for (final c in _ctx.store.courses.of(u.tenantId)) c.id: c};
    final recs = <Recommendation>[];
    for (final r in _ctx.store.resources.of(u.tenantId)) {
      if (r.archived) continue;
      final course = courses[r.courseId];
      if (course == null) continue;
      final enrolled = u.enrolledCourseIds.contains(r.courseId);
      final sameDept = course.departmentId == u.departmentId;
      if (!enrolled && !sameDept) continue;

      var score = enrolled ? 3.0 : 0.5;
      final reasons = <String>[];
      final days = enrolled ? _daysUntilExam(u, r.courseId) : null;
      if (days != null) {
        score += 5 / (1 + days / 7);
        reasons.add(days == 0 ? '${course.code} exam is today' : '${course.code} exam in $days days');
      } else if (enrolled) {
        reasons.add('You are enrolled in ${course.code}');
      } else {
        reasons.add('From your department');
      }
      if (viewed.contains(r.id)) {
        score -= 1.5;
      } else {
        score += 1;
        reasons.add('not opened yet');
      }
      if (r.paperType == PaperType.final_) score += 0.4;
      score += (r.academicYear - 2015) * 0.05;
      final reason = reasons.first + (reasons.length > 1 ? '; ${reasons.skip(1).join('; ')}' : '');
      recs.add(Recommendation(r, reason, score));
    }
    // Greedy pick with a penalty per paper already chosen from the same course,
    // so the list covers several courses instead of five papers of one.
    final picked = <Recommendation>[];
    final perCourse = <String, int>{};
    while (picked.length < Rules.maxRecommendations && recs.isNotEmpty) {
      double adjusted(Recommendation r) => r.score - 2.5 * (perCourse[r.resource.courseId] ?? 0);
      final best = recs.reduce((a, b) => adjusted(a) >= adjusted(b) ? a : b);
      recs.remove(best);
      picked.add(best);
      perCourse[best.resource.courseId] = (perCourse[best.resource.courseId] ?? 0) + 1;
    }
    return picked;
  }

  // ------------------------------------------------------------ revision plan

  List<StudyPlanSession> _mySessions(AppUser u) => _ctx.store.planSessions
      .of(u.tenantId)
      .where((s) => s.studentId == u.id)
      .toList()
    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  @override
  List<StudyPlanSession> plan() {
    final u = _student;
    var sessions = _mySessions(u);
    if (sessions.isEmpty && u.profileComplete) {
      _generate(u);
      sessions = _mySessions(u);
    }
    return sessions;
  }

  @override
  Future<void> regeneratePlan() async {
    final u = _student;
    _generate(u);
  }

  /// FR-SSA-09: fills preferred study slots up to each exam, giving nearer
  /// exams and weaker topics more sessions. Done and past sessions are kept.
  void _generate(AppUser u) {
    final now = Clock.now();
    _ctx.store.planSessions.removeWhere(
        u.tenantId, (s) => s.studentId == u.id && !s.done && s.scheduledAt.isAfter(now));

    final exams = {
      for (final id in u.enrolledCourseIds)
        if (u.examDates[id] != null && u.examDates[id]!.isAfter(now)) id: u.examDates[id]!,
    };
    if (exams.isEmpty || u.studyTimePreferences.isEmpty) {
      _ctx.store.commit();
      return;
    }

    // Topic rotation per course: weak topics appear twice.
    final rotations = <String, List<String>>{};
    for (final id in exams.keys) {
      final topics = topicsFor(id);
      final weak = _weakTopics(u, id);
      rotations[id] = [...topics.where(weak.contains), ...topics];
      if (rotations[id]!.isEmpty) rotations[id] = ['General revision'];
    }
    final rotationIndex = {for (final id in exams.keys) id: 0};
    final credit = {for (final id in exams.keys) id: 0.0};

    final localNow = now.toLocal();
    final lastExam = exams.values.reduce((a, b) => a.isAfter(b) ? a : b);
    final horizon = min(Rules.planHorizonDays, lastExam.difference(now).inDays + 1);
    for (var day = 0; day <= horizon; day++) {
      final date = DateTime(localNow.year, localNow.month, localNow.day + day);
      for (final slot in u.studyTimePreferences) {
        final parts = slot.split(':');
        final at = DateTime(date.year, date.month, date.day, int.parse(parts[0]), int.parse(parts[1])).toUtc();
        if (!at.isAfter(now)) continue;
        final eligible = exams.entries.where((e) => e.value.isAfter(at)).toList();
        if (eligible.isEmpty) continue;
        // Weighted round-robin: weight = 1 / days remaining to that exam.
        var total = 0.0;
        for (final e in eligible) {
          final w = 1 / (e.value.difference(at).inHours / 24 + 1);
          credit[e.key] = credit[e.key]! + w;
          total += w;
        }
        final pick = eligible.map((e) => e.key).reduce((a, b) => credit[a]! >= credit[b]! ? a : b);
        credit[pick] = credit[pick]! - total;
        final rotation = rotations[pick]!;
        final topic = rotation[rotationIndex[pick]! % rotation.length];
        rotationIndex[pick] = rotationIndex[pick]! + 1;
        _ctx.store.planSessions.add(StudyPlanSession(
          id: newId('ps'),
          tenantId: u.tenantId,
          studentId: u.id,
          courseId: pick,
          topic: topic,
          scheduledAt: at,
          durationMinutes: Rules.planSessionMinutes,
        ));
      }
    }
    _ctx.store.commit();
  }

  @override
  Future<void> setSessionDone(String sessionId, bool done) async {
    final u = _student;
    final s = _ctx.store.planSessions.find(u.tenantId, sessionId);
    if (s == null || s.studentId != u.id) throw const NotFoundException('That session could not be found.');
    s.done = done;
    _ctx.store.commit();
  }

  @override
  double planProgress() {
    final sessions = plan();
    if (sessions.isEmpty) return 0;
    return sessions.where((s) => s.done).length / sessions.length;
  }

  @override
  List<StudyPlanSession> todaysSessions() {
    final today = Clock.now().toLocal();
    return plan().where((s) {
      final d = s.scheduledAt.toLocal();
      return d.year == today.year && d.month == today.month && d.day == today.day;
    }).toList();
  }

  @override
  void runReminderChecks() {
    final now = Clock.now();
    final due = <String, List<StudyPlanSession>>{};
    for (final s in _ctx.store.planSessions.unscoped) {
      if (!s.done && !s.reminded && !s.scheduledAt.isAfter(now)) {
        s.reminded = true;
        due.putIfAbsent('${s.tenantId}|${s.studentId}', () => []).add(s);
      }
    }
    if (due.isEmpty) return;
    for (final sessions in due.values) {
      // After a large clock jump, send one reminder for the latest session only.
      sessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      final s = sessions.last;
      final c = _ctx.store.courses.find(s.tenantId, s.courseId);
      final earlier = sessions.length - 1;
      _ctx.notify(
        tenantId: s.tenantId,
        userId: s.studentId,
        category: NotificationCategory.study,
        title: 'Study session: ${c?.code ?? ''}',
        body: '${s.topic}, ${s.durationMinutes} minutes, planned for ${formatTime(s.scheduledAt)}.'
            '${earlier > 0 ? ' $earlier earlier session${earlier == 1 ? '' : 's'} not marked done.' : ''}',
        route: 'plan',
      );
    }
    _ctx.store.commit();
  }

  // ------------------------------------------------------------ progress and assistant

  @override
  List<TopicStat> topicStats({String? courseId}) {
    final u = _student;
    final stats = [
      for (final e in _topicTotals(u, courseId).entries)
        TopicStat(e.key.split('|').first, e.key.split('|').last, e.value.percent, e.value.total),
    ]..sort((a, b) => a.percent.compareTo(b.percent));
    return stats;
  }

  static const _questionsList = [
    AssistantQuestion('topics', 'Which topics come up most in {course}?'),
    AssistantQuestion('years', 'Which years of {course} papers are available?'),
    AssistantQuestion('types', 'What kinds of questions appear in {course}?'),
    AssistantQuestion('revise', 'Which {course} topics should I revise first?'),
    AssistantQuestion('format', 'How long is the {course} final examination?'),
    AssistantQuestion('exam', 'When is my {course} examination?'),
  ];

  @override
  List<AssistantQuestion> assistantQuestions() => _questionsList;

  @override
  String ask(String questionId, String courseId) {
    final u = _student;
    final course = _ctx.store.courses.find(u.tenantId, courseId);
    if (course == null) throw const NotFoundException('That course could not be found.');
    final papers = _ctx.store.resources
        .of(u.tenantId)
        .where((r) => r.courseId == courseId && !r.archived)
        .toList();
    if (papers.isEmpty && questionId != 'exam') {
      return 'There are no ${course.code} papers in the library yet.';
    }
    switch (questionId) {
      case 'topics':
        final counts = <String, int>{};
        for (final r in papers) {
          for (final t in r.topics) {
            counts[t] = (counts[t] ?? 0) + 1;
          }
        }
        final ranked = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        return 'Across ${papers.length} ${course.code} papers: ${ranked.take(5).map((e) => '${e.key} (${e.value} of ${papers.length})').join(', ')}.';
      case 'years':
        final years = {for (final r in papers) r.academicYear}.toList()..sort();
        return '${course.code} papers are available for ${years.join(', ')}.';
      case 'types':
        final qs = _questions(u.tenantId, courseId);
        final byType = <QuestionType, int>{};
        for (final q in qs) {
          byType[q.type] = (byType[q.type] ?? 0) + 1;
        }
        final types = {for (final r in papers) r.paperType.label};
        return 'Paper types: ${types.join(', ')}. The practice bank has ${qs.length} questions: '
            '${byType.entries.map((e) => '${e.value} ${e.key.label.toLowerCase()}').join(', ')}.';
      case 'revise':
        final weak = topicStats(courseId: courseId).where((s) => s.percent < Rules.weakTopicThreshold).toList();
        if (weak.isNotEmpty) {
          return 'Your weakest ${course.code} topics from past quizzes: '
              '${weak.take(3).map((s) => '${s.topic} (${s.percent}%)').join(', ')}.';
        }
        return 'No weak topics yet. Take a practice quiz so the assistant can find them; '
            'meanwhile start with the topics that appear most often.';
      case 'format':
        final finals = papers.where((r) => r.paperType == PaperType.final_ && r.durationMinutes != null).toList();
        if (finals.isEmpty) return 'There are no ${course.code} final examinations in the library yet.';
        final latest = finals.reduce((a, b) => a.academicYear > b.academicYear ? a : b);
        return 'The ${latest.academicYear} final was ${latest.durationMinutes} minutes for '
            '${latest.totalMarks ?? 'unspecified'} marks across ${latest.topics.length} sections.';
      case 'exam':
        final exam = u.examDates[courseId];
        return exam == null
            ? 'You have not set a ${course.code} examination date. Add it in your study profile.'
            : 'Your ${course.code} examination is on ${formatDate(exam)} (${formatRelative(exam)}).';
    }
    throw const NotFoundException('The assistant does not know that question.');
  }

  // ------------------------------------------------------------ content management

  @override
  List<Course> manageableCourses() {
    final u = _ctx.require(Permission.manageStudyContent);
    return _ctx.store.courses.of(u.tenantId)..sort((a, b) => a.code.compareTo(b.code));
  }

  @override
  List<Question> questionBank(String courseId) {
    final u = _ctx.require(Permission.manageStudyContent);
    return _questions(u.tenantId, courseId)..sort((a, b) => a.topic.compareTo(b.topic));
  }

  @override
  Question newQuestion(String courseId) {
    final u = _ctx.require(Permission.manageStudyContent);
    return Question(
      id: newId('q'),
      tenantId: u.tenantId,
      courseId: courseId,
      topic: '',
      type: QuestionType.multipleChoice,
      text: '',
      options: ['', '', '', ''],
      correctAnswer: '',
      explanation: '',
    );
  }

  @override
  Future<void> saveQuestion(Question q) async {
    final u = _ctx.require(Permission.manageStudyContent);
    if (q.tenantId != u.tenantId) throw const PermissionDeniedException();
    final e = <String, String>{};
    if (q.text.trim().isEmpty) e['text'] = 'Enter the question.';
    if (q.topic.trim().isEmpty) e['topic'] = 'Enter a topic.';
    if (q.correctAnswer.trim().isEmpty) e['correctAnswer'] = 'Enter the correct answer.';
    if (q.type == QuestionType.multipleChoice) {
      q.options = q.options.where((o) => o.trim().isNotEmpty).toList();
      if (q.options.length < 2) e['options'] = 'Give at least two options.';
      if (!q.options.contains(q.correctAnswer)) {
        e['correctAnswer'] = 'The correct answer must be one of the options.';
      }
    }
    if (q.type == QuestionType.shortAnswer && q.acceptedKeywords.isEmpty) {
      e['acceptedKeywords'] = 'Give at least one accepted keyword.';
    }
    if (e.isNotEmpty) throw ValidationException(e);
    _ctx.store.questions
      ..remove(u.tenantId, q.id)
      ..add(q);
    _ctx.store.commit();
  }

  @override
  Future<void> deleteQuestion(String questionId) async {
    final u = _ctx.require(Permission.manageStudyContent);
    _ctx.store.questions.remove(u.tenantId, questionId);
    _ctx.store.commit();
  }

  @override
  List<Flashcard> flashcards(String courseId) {
    final u = _ctx.require(Permission.manageStudyContent);
    return _ctx.store.flashcards.of(u.tenantId).where((f) => f.courseId == courseId).toList()
      ..sort((a, b) => a.topic.compareTo(b.topic));
  }

  @override
  Flashcard newFlashcard(String courseId) {
    final u = _ctx.require(Permission.manageStudyContent);
    return Flashcard(id: newId('f'), tenantId: u.tenantId, courseId: courseId, front: '', back: '', topic: '');
  }

  @override
  Future<void> saveFlashcard(Flashcard f) async {
    final u = _ctx.require(Permission.manageStudyContent);
    if (f.tenantId != u.tenantId) throw const PermissionDeniedException();
    final e = <String, String>{};
    if (f.front.trim().isEmpty) e['front'] = 'Enter the front of the card.';
    if (f.back.trim().isEmpty) e['back'] = 'Enter the back of the card.';
    if (f.topic.trim().isEmpty) e['topic'] = 'Enter a topic.';
    if (e.isNotEmpty) throw ValidationException(e);
    _ctx.store.flashcards
      ..remove(u.tenantId, f.id)
      ..add(f);
    _ctx.store.commit();
  }

  @override
  Future<void> deleteFlashcard(String flashcardId) async {
    final u = _ctx.require(Permission.manageStudyContent);
    _ctx.store.flashcards.remove(u.tenantId, flashcardId);
    _ctx.store.commit();
  }
}
