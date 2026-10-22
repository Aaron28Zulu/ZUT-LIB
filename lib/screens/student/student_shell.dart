import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../common/notifications_screen.dart';
import '../common/profile_screen.dart';
import 'home_tab.dart';
import 'loans_tab.dart';
import 'search_tab.dart';
import 'study_tab.dart';

/// Bottom navigation for students (SRS 8 general UI rules).
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_index == 0 ? (tenant?.shortCode ?? 'ZutLib') : _titles[_index]),
        actions: const [NotificationsButton()],
      ),
      body: IndexedStack(
        index: _index,
        children: const [HomeTab(), SearchTab(), StudyTab(), LoansTab(), ProfileScreen(embedded: true)],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: select,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.school_outlined), selectedIcon: Icon(Icons.school), label: 'Study'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Loans'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
