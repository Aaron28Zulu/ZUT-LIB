import 'enums.dart';
import 'json.dart';

class Question implements TenantScoped {
  Question({
    required this.id,
    required this.tenantId,
    required this.courseId,
    required this.topic,
    required this.type,
    required this.text,
    required this.correctAnswer,
    required this.explanation,
    this.sourceResourceId,
    List<String>? options,
    List<String>? acceptedKeywords,
  })  : options = options ?? [],
        acceptedKeywords = acceptedKeywords ?? [];

  @override
  final String id;
  @override
  final String tenantId;
  final String courseId;
  String? sourceResourceId;
  String topic;
  QuestionType type;
  String text;
  List<String> options;
  String correctAnswer;
  List<String> acceptedKeywords;
  String explanation;

  factory Question.fromJson(Map<String, dynamic> j) => Question(
        id: j['id'],
        tenantId: j['tenantId'],
        courseId: j['courseId'],
        sourceResourceId: j['sourceResourceId'],
        topic: j['topic'],
        type: enumByName(QuestionType.values, j['type']),
        text: j['text'],
        options: stringList(j['options']),
        correctAnswer: j['correctAnswer'],
        acceptedKeywords: stringList(j['acceptedKeywords']),
        explanation: j['explanation'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'courseId': courseId,
        'sourceResourceId': sourceResourceId,
        'topic': topic,
        'type': type.name,
        'text': text,
        'options': options,
        'correctAnswer': correctAnswer,
        'acceptedKeywords': acceptedKeywords,
        'explanation': explanation,
      };
}

class TopicScore {
  TopicScore({this.correct = 0, this.total = 0});

  int correct;
  int total;

  int get percent => total == 0 ? 0 : (correct * 100 / total).round();

  factory TopicScore.fromJson(Map<String, dynamic> j) =>
      TopicScore(correct: j['correct'], total: j['total']);

  Map<String, dynamic> toJson() => {'correct': correct, 'total': total};
}

class QuizAttempt implements TenantScoped {
  QuizAttempt({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.courseId,
    required this.questionIds,
    required this.answers,
    required this.score,
    required this.topicScores,
    required this.startedAt,
    required this.finishedAt,
  });

  @override
  final String id;
  @override
  final String tenantId;
  final String studentId;
  final String courseId;
  final List<String> questionIds;
  final Map<String, String> answers;

  /// Percentage 0-100.
  final int score;
  final Map<String, TopicScore> topicScores;
  final DateTime startedAt;
  final DateTime finishedAt;

  Duration get timeTaken => finishedAt.difference(startedAt);

  factory QuizAttempt.fromJson(Map<String, dynamic> j) => QuizAttempt(
        id: j['id'],
        tenantId: j['tenantId'],
        studentId: j['studentId'],
        courseId: j['courseId'],
        questionIds: stringList(j['questionIds']),
        answers: (j['answers'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v as String)),
        score: j['score'],
        topicScores: (j['topicScores'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, TopicScore.fromJson(v))),
        startedAt: parseDate(j['startedAt'])!,
        finishedAt: parseDate(j['finishedAt'])!,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'studentId': studentId,
        'courseId': courseId,
        'questionIds': questionIds,
        'answers': answers,
        'score': score,
        'topicScores': topicScores.map((k, v) => MapEntry(k, v.toJson())),
        'startedAt': dateToJson(startedAt),
        'finishedAt': dateToJson(finishedAt),
      };
}

class Flashcard implements TenantScoped {
  Flashcard({
    required this.id,
    required this.tenantId,
    required this.courseId,
    required this.front,
    required this.back,
    required this.topic,
  });

  @override
  final String id;
  @override
  final String tenantId;
  final String courseId;
  String front;
  String back;
  String topic;

  factory Flashcard.fromJson(Map<String, dynamic> j) => Flashcard(
        id: j['id'],
        tenantId: j['tenantId'],
        courseId: j['courseId'],
        front: j['front'],
        back: j['back'],
        topic: j['topic'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'courseId': courseId,
        'front': front,
        'back': back,
        'topic': topic,
      };
}

class FlashcardReview implements TenantScoped {
  FlashcardReview({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.flashcardId,
    required this.rating,
    required this.reviewedAt,
    required this.nextDueAt,
  });

  @override
  final String id;
  @override
  final String tenantId;
  final String studentId;
  final String flashcardId;
  CardRating rating;
  DateTime reviewedAt;
  DateTime nextDueAt;

  factory FlashcardReview.fromJson(Map<String, dynamic> j) => FlashcardReview(
        id: j['id'],
        tenantId: j['tenantId'],
        studentId: j['studentId'],
        flashcardId: j['flashcardId'],
        rating: enumByName(CardRating.values, j['rating']),
        reviewedAt: parseDate(j['reviewedAt'])!,
        nextDueAt: parseDate(j['nextDueAt'])!,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'studentId': studentId,
        'flashcardId': flashcardId,
        'rating': rating.name,
        'reviewedAt': dateToJson(reviewedAt),
        'nextDueAt': dateToJson(nextDueAt),
      };
}

class StudyPlanSession implements TenantScoped {
  StudyPlanSession({
    required this.id,
    required this.tenantId,
    required this.studentId,
    required this.courseId,
    required this.topic,
    required this.scheduledAt,
    required this.durationMinutes,
    this.done = false,
    this.reminded = false,
  });

  @override
  final String id;
  @override
  final String tenantId;
  final String studentId;
  final String courseId;
  final String topic;
  final DateTime scheduledAt;
  final int durationMinutes;
  bool done;
  bool reminded;

  factory StudyPlanSession.fromJson(Map<String, dynamic> j) => StudyPlanSession(
        id: j['id'],
        tenantId: j['tenantId'],
        studentId: j['studentId'],
        courseId: j['courseId'],
        topic: j['topic'],
        scheduledAt: parseDate(j['scheduledAt'])!,
        durationMinutes: j['durationMinutes'],
        done: j['done'] ?? false,
        reminded: j['reminded'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'studentId': studentId,
        'courseId': courseId,
        'topic': topic,
        'scheduledAt': dateToJson(scheduledAt),
        'durationMinutes': durationMinutes,
        'done': done,
        'reminded': reminded,
      };
}
