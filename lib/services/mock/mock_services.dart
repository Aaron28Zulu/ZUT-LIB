import '../../data/data_store.dart';
import '../admin_service.dart';
import '../auth_service.dart';
import '../loan_service.dart';
import '../notification_service.dart';
import '../platform_service.dart';
import '../resource_service.dart';
import '../study_assistant_service.dart';
import 'mock_admin_service.dart';
import 'mock_auth_service.dart';
import 'mock_context.dart';
import 'mock_loan_service.dart';
import 'mock_notification_service.dart';
import 'mock_platform_service.dart';
import 'mock_resource_service.dart';
import 'mock_study_assistant_service.dart';

/// All services typed as interfaces. A Firebase build would provide another
/// factory with the same shape and no screen would change (NFR-11).
class ServiceBundle {
  ServiceBundle({
    required this.auth,
    required this.resources,
    required this.loans,
    required this.study,
    required this.notifications,
    required this.admin,
    required this.platform,
  });

  final AuthService auth;
  final ResourceService resources;
  final LoanService loans;
  final StudyAssistantService study;
  final NotificationService notifications;
  final AdminService admin;
  final PlatformService platform;

  /// System jobs that a backend would run on a schedule.
  void runScheduledJobs() {
    loans.runScheduledChecks();
    study.runReminderChecks();
  }

  /// [identity] enables Google sign-in; it is set in cloud mode only.
  factory ServiceBundle.mock(DataStore store, DeviceNotifier notifier, {IdentityProvider? identity}) {
    final ctx = MockContext(store, notifier);
    late final ServiceBundle bundle;
    bundle = ServiceBundle(
      auth: MockAuthService(ctx, identity: identity),
      resources: MockResourceService(ctx),
      loans: MockLoanService(ctx),
      study: MockStudyAssistantService(ctx),
      notifications: MockNotificationService(ctx),
      admin: MockAdminService(ctx),
      platform: MockPlatformService(ctx, onClockChanged: () => bundle.runScheduledJobs()),
    );
    return bundle;
  }
}
