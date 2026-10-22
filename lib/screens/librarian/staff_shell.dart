import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/permissions.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../admin/departments_courses_screen.dart';
import '../admin/feedback_list_screen.dart';
import '../admin/role_review_screen.dart';
import '../admin/users_screen.dart';
import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';
import '../platform/demo_controls_screen.dart';
import '../platform/tenants_screen.dart';
import 'dashboard_screen.dart';
import 'loans_list_screen.dart';
import 'question_bank_screen.dart';
import 'request_queue_screen.dart';
import 'resources_list_screen.dart';
import 'scan_screen.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.builder, {this.badge});
  final String label;
  final IconData icon;
  final Widget Function() builder;
  final int Function(AppState)? badge;
}

/// Side drawer navigation for staff roles (SRS 8 general UI rules). Items come
/// from the permissions matrix so each role sees only its own menu (FR-AUTH-02).
class StaffShell extends StatefulWidget {
  const StaffShell({super.key});

  @override
  State<StaffShell> createState() => _StaffShellState();
}

class _StaffShellState extends State<StaffShell> {
  int _index = 0;

  List<_Destination> _destinations(Role role) {
    bool can(Permission p) => roleAllows(role, p);
    return [
      if (can(Permission.viewLibraryReports))
        _Destination('Dashboard', Icons.dashboard_outlined, () => const DashboardScreen()),
      if (can(Permission.processLoans)) ...[
        _Destination('Request queue', Icons.inbox_outlined, () => const RequestQueueScreen(embedded: true),
            badge: (a) => a.loans.pendingRequests().length + a.loans.renewalRequests().length),
        _Destination('Scan code', Icons.qr_code_scanner, () => const ScanScreen()),
        _Destination('Loans', Icons.assignment_outlined, () => const LoansListScreen()),
      ],
      if (can(Permission.manageResources))
        _Destination('Papers', Icons.menu_book_outlined, () => const ResourcesListScreen()),
      if (can(Permission.manageStudyContent))
        _Destination('Question bank', Icons.quiz_outlined, () => const QuestionBankScreen()),
      if (can(Permission.manageUsers)) ...[
        _Destination('Users', Icons.people_outline, () => const UsersScreen()),
        _Destination('Role review', Icons.verified_user_outlined, () => const RoleReviewScreen()),
        _Destination('Courses', Icons.account_tree_outlined, () => const DepartmentsCoursesScreen()),
      ],
      if (can(Permission.viewFeedback))
        _Destination('Feedback', Icons.rate_review_outlined, () => const FeedbackListScreen()),
      if (can(Permission.manageTenants))
        _Destination('Institutions', Icons.apartment_outlined, () => const TenantsScreen()),
      if (can(Permission.demoControls))
        _Destination('Demo controls', Icons.tune, () => const DemoControlsScreen()),
      _Destination('Profile', Icons.person_outline, () => const ProfileScreen(embedded: true)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final user = app.user!;
    final tenant = app.tenant;
    final items = _destinations(user.role);
    final index = _index.clamp(0, items.length - 1);
    final current = items[index];
    return Scaffold(
      appBar: AppBar(
        title: Text(current.label),
        actions: const [NotificationsButton()],
      ),
      // ListTile rows rather than NavigationDrawerDestination so labels wrap
      // at large text sizes (NFR-06).
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              ListTile(
                leading: tenant != null ? TenantMark(tenant, size: 36) : null,
                title: Text(user.fullName, style: Theme.of(context).textTheme.titleSmall),
                subtitle: Text(user.role.label),
              ),
              const Divider(),
              for (final (i, d) in items.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ListTile(
                    selected: i == index,
                    selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
                    shape: const StadiumBorder(),
                    leading: Badge(
                      isLabelVisible: (d.badge?.call(app) ?? 0) > 0,
                      label: Text('${d.badge?.call(app) ?? 0}'),
                      child: Icon(d.icon),
                    ),
                    title: Text(d.label),
                    onTap: () {
                      setState(() => _index = i);
                      Navigator.pop(context);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
      body: current.builder(),
    );
  }
}
