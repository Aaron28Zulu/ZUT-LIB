import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'models/models.dart';
import 'screens/common/institution_screen.dart';
import 'screens/common/loan_details_screen.dart';
import 'screens/common/onboarding_screen.dart';
import 'screens/common/paper_details_screen.dart';
import 'screens/librarian/request_queue_screen.dart';
import 'screens/librarian/staff_shell.dart';
import 'screens/student/profile_setup_screen.dart';
import 'screens/student/revision_plan_screen.dart';
import 'screens/student/student_shell.dart';
import 'state/app_state.dart';
import 'widgets/actions.dart';

final navigatorKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();

class ZutLibApp extends StatelessWidget {
  const ZutLibApp({super.key});

  @override
  Widget build(BuildContext context) {
    final tenant = context.select<AppState, Tenant?>((a) => a.tenant);
    // FR-TEN-04: the tenant colour seeds the whole scheme after sign-in.
    final seed = tenant == null ? defaultSeed : Color(tenant.colourValue);
    return MaterialApp(
      title: 'ZutLib',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      theme: buildTheme(seed, Brightness.light),
      darkTheme: buildTheme(seed, Brightness.dark),
      home: const RootGate(),
    );
  }
}

/// Chooses the first screen from the session and records activity for the
/// inactivity timeout (FR-AUTH-07).
class RootGate extends StatefulWidget {
  const RootGate({super.key});

  @override
  State<RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<RootGate> with WidgetsBindingObserver {
  String? _lastUserId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final app = context.read<AppState>();
    if (state == AppLifecycleState.resumed) app.runScheduledJobs();
    if (state == AppLifecycleState.paused) app.flush();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.user;

    // When the signed-in user changes, drop any screens left from the old session.
    if (user?.id != _lastUserId) {
      _lastUserId = user?.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        navigatorKey.currentState?.popUntil((r) => r.isFirst);
        if (app.consumeSessionExpired()) {
          messengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('You were signed out after a period of inactivity.')),
          );
        }
      });
    }

    final Widget home;
    if (user == null) {
      home = app.onboardingSeen ? const InstitutionScreen() : const OnboardingScreen();
    } else if (user.role == Role.student && !user.profileComplete) {
      home = const ProfileSetupScreen(firstRun: true);
    } else if (user.role == Role.student) {
      home = const StudentShell();
    } else {
      home = const StaffShell();
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => app.registerActivity(),
      child: home,
    );
  }
}

/// Opens the screen a notification points to (FR-NOT-05).
void openTarget(BuildContext context, String? route) {
  if (route == null) return;
  final parts = route.split(':');
  final Widget? screen = switch (parts.first) {
    'loan' when parts.length == 2 => LoanDetailsScreen(loanId: parts[1]),
    'resource' when parts.length == 2 => PaperDetailsScreen(resourceId: parts[1]),
    'plan' => const RevisionPlanScreen(),
    'queue' => const RequestQueueScreen(),
    _ => null,
  };
  if (screen == null) {
    showMessage(context, 'This item is no longer available.');
    return;
  }
  Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
}
