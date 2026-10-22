import 'enums.dart';
import 'json.dart';

class AppNotification implements TenantScoped {
  AppNotification({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.targetRoute,
    this.read = false,
  });

  @override
  final String id;
  @override
  final String tenantId;
  final String userId;
  final NotificationCategory category;
  final String title;
  final String body;

  /// `loan:<id>`, `resource:<id>`, `plan`, or `queue` (FR-NOT-05).
  final String? targetRoute;
  bool read;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'],
        tenantId: j['tenantId'],
        userId: j['userId'],
        category: enumByName(NotificationCategory.values, j['category']),
        title: j['title'],
        body: j['body'],
        targetRoute: j['targetRoute'],
        read: j['read'] ?? false,
        createdAt: parseDate(j['createdAt'])!,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'userId': userId,
        'category': category.name,
        'title': title,
        'body': body,
        'targetRoute': targetRoute,
        'read': read,
        'createdAt': dateToJson(createdAt),
      };
}

/// Anonymous event counts for dashboards (NFR-09: not linked to student names).
class UsageEvent implements TenantScoped {
  UsageEvent({
    required this.id,
    required this.tenantId,
    required this.type,
    required this.createdAt,
    this.refId,
    this.term,
  });

  @override
  final String id;
  @override
  final String tenantId;
  final UsageEventType type;
  final String? refId;
  final String? term;
  final DateTime createdAt;

  factory UsageEvent.fromJson(Map<String, dynamic> j) => UsageEvent(
        id: j['id'],
        tenantId: j['tenantId'],
        type: enumByName(UsageEventType.values, j['type']),
        refId: j['refId'],
        term: j['term'],
        createdAt: parseDate(j['createdAt'])!,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'type': type.name,
        'refId': refId,
        'term': term,
        'createdAt': dateToJson(createdAt),
      };
}

class FeedbackEntry implements TenantScoped {
  FeedbackEntry({
    required this.id,
    required this.tenantId,
    required this.userId,
    required this.message,
    required this.createdAt,
  });

  @override
  final String id;
  @override
  final String tenantId;
  final String userId;
  final String message;
  final DateTime createdAt;

  factory FeedbackEntry.fromJson(Map<String, dynamic> j) => FeedbackEntry(
        id: j['id'],
        tenantId: j['tenantId'],
        userId: j['userId'],
        message: j['message'],
        createdAt: parseDate(j['createdAt'])!,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tenantId': tenantId,
        'userId': userId,
        'message': message,
        'createdAt': dateToJson(createdAt),
      };
}
