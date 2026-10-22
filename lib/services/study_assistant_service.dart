import '../models/models.dart';

class QuizSession {
  QuizSession({
    required this.courseId,
    required this.questions,
    required this.startedAt,
    this.topic,
  });

  final String courseId;
  final String? topic;
  final List<Question> questions;
  final DateTime startedAt;
  final Map<String, String> answers = {};
}

class AnswerFeedback {
  const AnswerFeedback({
    required this.correct,
    required this.correctAnswer,
    required this.explanation,
    required this.sourceLabel,
  });

  final bool correct;
  final String correctAnswer;
  final String explanation;

  /// "ICT 2201 Final examination 2023" (FR-SSA-03).
  final String sourceLabel;
}

class Recommendation {
  const Recommendation(this.resource, this.reason, this.score);
  final Resource resource;
  final String reason;
  final double score;
}

class TopicStat {
  const TopicStat(this.courseId, this.topic, this.percent, this.answered);
  final String courseId;
  final String topic;
  final int percent;
  final int answered;
}

class AssistantQuestion {
  const AssistantQuestion(this.id, this.template);
  final String id;

  /// Contains `{course}` where the course code goes.
  final String template;

  String forCourse(Course c) => template.replaceAll('{course}', c.code);
}

/// Smart study assistant (SRS 3.6). FR-SSA-13: screens use only this interface;
/// the prototype ships a rule-based implementation.
abstract interface class StudyAssistantService {
  List<Course> enrolledCourses();
  List<String> topicsFor(String courseId);
  int questionCount(String courseId, {String? topic});

  /// FR-SSA-01, FR-SSA-04
  QuizSession startQuiz(String courseId, int count, {String? topic});

  /// FR-SSA-02, FR-SSA-03
  AnswerFeedback answer(QuizSession session, Question q, String answer);

  /// FR-SSA-05
  Future<QuizAttempt> finishQuiz(QuizSession session);
  List<QuizAttempt> attempts({String? courseId});

  /// FR-SSA-06
  List<Flashcard> flashcardSession(String courseId);
  Future<void> rateCard(Flashcard card, CardRating rating);
  int flashcardCount(String courseId);

  /// FR-SSA-07
  ResourceSummary? summary(String resourceId);

  /// FR-SSA-08
  List<Recommendation> recommendations();

  /// FR-SSA-09, FR-SSA-10
  List<StudyPlanSession> plan();
  Future<void> regeneratePlan();
  Future<void> setSessionDone(String sessionId, bool done);
  double planProgress();
  List<StudyPlanSession> todaysSessions();

  /// FR-SSA-11
  List<TopicStat> topicStats({String? courseId});

  /// FR-SSA-12
  List<AssistantQuestion> assistantQuestions();
  String ask(String questionId, String courseId);

  /// FR-NOT-03: system job, runs when the clock moves.
  void runReminderChecks();

  // Content management for librarians and admins (permissions matrix).
  List<Course> manageableCourses();
  List<Question> questionBank(String courseId);
  Future<void> saveQuestion(Question q);
  Future<void> deleteQuestion(String questionId);
  List<Flashcard> flashcards(String courseId);
  Future<void> saveFlashcard(Flashcard f);
  Future<void> deleteFlashcard(String flashcardId);
  Question newQuestion(String courseId);
  Flashcard newFlashcard(String courseId);
}

/// In-session flashcard order (FR-SSA-06): a card rated Hard is shown again
/// a few cards later, before the session ends.
class FlashcardQueue {
  FlashcardQueue(List<Flashcard> cards) : _queue = List.of(cards);

  static const hardGap = 3;

  final List<Flashcard> _queue;
  int _index = 0;
  int reviewed = 0;

  Flashcard? get current => _index < _queue.length ? _queue[_index] : null;
  int get remaining => _queue.length - _index;
  bool get isDone => current == null;

  void rate(CardRating rating) {
    final card = current;
    if (card == null) return;
    reviewed++;
    _index++;
    if (rating == CardRating.hard) {
      final at = (_index + hardGap).clamp(0, _queue.length);
      _queue.insert(at, card);
    }
  }
}
