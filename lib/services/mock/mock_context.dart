import '../../core/clock.dart';
import '../../core/errors.dart';
import '../../core/ids.dart';
import '../../core/permissions.dart';
import '../../data/data_store.dart';
import '../../models/models.dart';
import '../notification_service.dart';

/// Shared state for the mock services: the store, the session and the
/// permission guard. Every mock service method starts with [require]
/// (FR-AUTH-08, NFR-07).
class MockContext {
  MockContext(this.store, this.notifier);

  final DataStore store;
  final DeviceNotifier notifier;

  AppUser? currentUser;

  AppUser require(Permission permission) {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('Your session has ended. Sign in again.');
    }
    if (!user.active) {
      throw const AuthException('This account has been deactivated.');
    }
    if (!roleAllows(user.role, permission)) {
      throw const PermissionDeniedException();
    }
    return user;
  }

  AppUser requireSignedIn() {
    final user = currentUser;
    if (user == null) {
      throw const AuthException('Your session has ended. Sign in again.');
    }
    return user;
  }

  /// Creates an in-app notification and a device notification, honouring the
  /// recipient's category preferences (FR-NOT-06).
  void notify({
    required String tenantId,
    required String userId,
    required NotificationCategory category,
    required String title,
    required String body,
    String? route,
  }) {
    final recipient = store.users.find(tenantId, userId);
    if (recipient == null || !recipient.wantsCategory(category)) return;
    store.notifications.add(AppNotification(
      id: newId('n'),
      tenantId: tenantId,
      userId: userId,
      category: category,
      title: title,
      body: body,
      targetRoute: route,
      createdAt: Clock.now(),
    ));
    notifier.show(title, body);
  }

  void notifyRole(String tenantId, Set<Role> roles, NotificationCategory category,
      String title, String body, {String? route}) {
    for (final u in store.users.of(tenantId)) {
      if (roles.contains(u.role) && u.active) {
        notify(
          tenantId: tenantId,
          userId: u.id,
          category: category,
          title: title,
          body: body,
          route: route,
        );
      }
    }
  }

  void logEvent(String tenantId, UsageEventType type, {String? refId, String? term}) {
    store.usageEvents.add(UsageEvent(
      id: newId('e'),
      tenantId: tenantId,
      type: type,
      refId: refId,
      term: term,
      createdAt: Clock.now(),
    ));
  }

  Resource resourceOrThrow(String tenantId, String id) {
    final r = store.resources.find(tenantId, id);
    if (r == null) throw const NotFoundException('That paper could not be found.');
    return r;
  }

  String resourceLabel(Resource r) {
    final course = store.courses.find(r.tenantId, r.courseId);
    return '${course?.code ?? ''} ${r.paperType.label} ${r.academicYear}'.trim();
  }
}
