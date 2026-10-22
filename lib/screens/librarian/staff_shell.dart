import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/permissions.dart';
import '../../core/theme.dart';
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
        _Destination('Dashboard', AppIcons.dashboard, () => const DashboardScreen()),
      if (can(Permission.processLoans)) ...[
        _Destination('Request queue', AppIcons.inbox, () => const RequestQueueScreen(embedded: true),
            badge: (a) => a.loans.pendingRequests().length + a.loans.renewalRequests().length),
        _Destination('Scan code', AppIcons.scan, () => const ScanScreen()),
        _Destination('Loans', AppIcons.loans, () => const LoansListScreen()),
      ],
      if (can(Permission.manageResources))
        _Destination('Papers', AppIcons.paper, () => const ResourcesListScreen()),
      if (can(Permission.manageStudyContent))
        _Destination('Question bank', AppIcons.quiz, () => const QuestionBankScreen()),
      if (can(Permission.manageUsers)) ...[
        _Destination('Users', AppIcons.users, () => const UsersScreen()),
        _Destination('Role review', AppIcons.roleReview, () => const RoleReviewScreen()),
        _Destination('Courses', AppIcons.courses, () => const DepartmentsCoursesScreen()),
      ],
      if (can(Permission.viewFeedback))
        _Destination('Feedback', AppIcons.feedback, () => const FeedbackListScreen()),
      if (can(Permission.manageTenants))
        _Destination('Institutions', AppIcons.institution, () => const TenantsScreen()),
      if (can(Permission.demoControls))
        _Destination('Demo controls', AppIcons.demoControls, () => const DemoControlsScreen()),
      _Destination('Profile', AppIcons.profile, () => const ProfileScreen(embedded: true)),
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
    final width = MediaQuery.sizeOf(context).width;
    final permanent = width >= Breakpoints.expanded;
    final s = Theme.of(context).colorScheme;

    Widget menu({required bool closeOnTap}) => SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: Space.m),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.l),
                child: Row(
                  children: [
                    if (tenant != null) ...[TenantMark(tenant, size: 40), const SizedBox(width: Space.m)],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName, style: Theme.of(context).textTheme.titleSmall),
                          Text(user.role.label, style: Theme.of(context).textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(height: Space.s),
              for (final (i, d) in items.indexed)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: 1),
                  child: ListTile(
                    selected: i == index,
                    selectedTileColor: s.primaryContainer,
                    selectedColor: s.onPrimaryContainer,
                    shape: Radii.controlShape,
                    leading: Badge(
                      isLabelVisible: (d.badge?.call(app) ?? 0) > 0,
                      label: Text('${d.badge?.call(app) ?? 0}'),
                      child: Icon(d.icon, size: 20),
                    ),
                    title: Text(
                      d.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: i == index ? FontWeight.w600 : FontWeight.w500,
                            color: i == index ? s.onPrimaryContainer : s.onSurface,
                          ),
                    ),
                    onTap: () {
                      setState(() => _index = i);
                      if (closeOnTap) Navigator.pop(context);
                    },
                  ),
                ),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !permanent,
        titleSpacing: permanent ? Space.xl : null,
        title: Text(current.label),
        actions: const [NotificationsButton(), SizedBox(width: Space.xs)],
      ),
      // ListTile rows rather than NavigationDrawerDestination so labels wrap
      // at large text sizes (NFR-06). From tablet-landscape width the menu is
      // always visible, like the side navigation on course dashboards.
      drawer: permanent ? null : Drawer(child: menu(closeOnTap: true)),
      body: permanent
          ? Row(
              children: [
                SizedBox(width: Sizes.sideMenu, child: menu(closeOnTap: false)),
                VerticalDivider(width: 1, color: s.outlineVariant),
                Expanded(child: Readable(maxWidth: 1040, child: current.builder())),
              ],
            )
          : current.builder(),
    );
  }
}
