import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';
import 'home_tab.dart';
import 'loans_tab.dart';
import 'search_tab.dart';
import 'study_tab.dart';

class _Tab {
  const _Tab(this.label, this.icon);
  final String label;
  final IconData icon;
}

const _tabs = [
  _Tab('Home', AppIcons.home),
  _Tab('Search', AppIcons.search),
  _Tab('Study', AppIcons.study),
  _Tab('Loans', AppIcons.loans),
  _Tab('Profile', AppIcons.profile),
];

/// Student navigation (SRS 8 general UI rules): a bottom bar on phones and a
/// side rail from tablet width, with content held to a readable width.
class StudentShell extends StatefulWidget {
  const StudentShell({super.key});

  static void goToTab(BuildContext context, int index) =>
      context.findAncestorStateOfType<_StudentShellState>()?.select(index);

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int _index = 0;

  void select(int i) => setState(() => _index = i);

  static const _titles = ['Home', 'Search', 'Study', 'My loans', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final tenant = context.watch<AppState>().tenant;
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= Breakpoints.medium;
    final s = Theme.of(context).colorScheme;

    final body = IndexedStack(
      index: _index,
      children: const [HomeTab(), SearchTab(), StudyTab(), LoansTab(), ProfileScreen(embedded: true)],
    );

    return Scaffold(
      appBar: AppBar(
        titleSpacing: Space.l,
        title: _index == 0 && tenant != null
            ? Row(
                children: [
                  TenantMark(tenant, size: 30),
                  const SizedBox(width: Space.m),
                  const Flexible(child: Text('ZutLib')),
                ],
              )
            : Text(_titles[_index]),
        actions: const [NotificationsButton(), SizedBox(width: Space.xs)],
      ),
      body: wide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: select,
                  extended: width >= Breakpoints.expanded,
                  labelType: width >= Breakpoints.expanded ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                  minExtendedWidth: 200,
                  destinations: [
                    for (final t in _tabs) NavigationRailDestination(icon: Icon(t.icon), label: Text(t.label)),
                  ],
                ),
                VerticalDivider(width: 1, color: s.outlineVariant),
                Expanded(child: Readable(child: body)),
              ],
            )
          : body,
      bottomNavigationBar: wide
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: s.outlineVariant))),
              child: NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: select,
                destinations: [
                  for (final t in _tabs) NavigationDestination(icon: Icon(t.icon), label: t.label),
                ],
              ),
            ),
    );
  }
}
