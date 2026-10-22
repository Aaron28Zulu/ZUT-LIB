import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/admin_service.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';

/// FR-ADM-01: list, search, add, deactivate and reactivate users; change role.
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _query = '';
  Role? _role;

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AppState>().admin;
    final users = admin.users(query: _query, role: _role);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-user',
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add user'),
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _AddUserScreen())),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.s),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), labelText: 'Search name, email or student number'),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: Space.screen,
            child: Row(
              spacing: Space.s,
              children: [
                ChoiceChip(label: const Text('All'), selected: _role == null, onSelected: (_) => setState(() => _role = null)),
                for (final r in Role.values.where((r) => r != Role.platformAdmin))
                  ChoiceChip(label: Text(r.label), selected: _role == r, onSelected: (_) => setState(() => _role = r)),
              ],
            ),
          ),
          Expanded(
            child: users.isEmpty
                ? const EmptyState(icon: Icons.person_search_outlined, message: 'No users match.')
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: users.length,
                    itemBuilder: (context, i) {
                      final u = users[i];
                      return ListTile(
                        title: Text(u.fullName),
                        subtitle: Text([
                          u.role.label,
                          if (u.studentNumber != null) u.studentNumber!,
                          if (!u.active) 'Deactivated',
                          if (u.pendingRole != null) 'Becomes ${u.pendingRole!.label.toLowerCase()} at next sign-in',
                        ].join(' · ')),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showUser(context, u.id),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showUser(BuildContext context, String id) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _UserSheet(userId: id),
    );
  }
}

class _UserSheet extends StatelessWidget {
  const _UserSheet({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final u = app.admin.user(userId);
    final isSelf = u.id == app.user!.id;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(u.fullName, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Space.s),
            InfoRow('Email', u.email),
            InfoRow('Role', u.role.label),
            InfoRow('Role granted', formatDate(u.roleGrantedAt)),
            if (u.studentNumber != null) InfoRow('Student number', u.studentNumber!),
            if (u.yearOfStudy != null) InfoRow('Year of study', '${u.yearOfStudy}'),
            InfoRow('Status', u.active ? 'Active' : 'Deactivated'),
            const SizedBox(height: Space.l),
            if (!isSelf) ...[
              DropdownButtonFormField<Role>(
                initialValue: u.pendingRole ?? u.role,
                decoration: const InputDecoration(labelText: 'Role', helperText: 'Takes effect at the user\'s next sign-in'),
                items: [
                  for (final r in Role.values.where((r) => r != Role.platformAdmin))
                    DropdownMenuItem(value: r, child: Text(r.label)),
                ],
                onChanged: (r) {
                  if (r != null) runAction(context, () => app.admin.changeRole(u.id, r), success: 'Role change saved.');
                },
              ),
              const SizedBox(height: Space.m),
              OutlinedButton(
                onPressed: () => runAction(context, () => app.admin.setActive(u.id, !u.active),
                    success: u.active ? 'Account deactivated. The user can no longer sign in.' : 'Account reactivated.'),
                child: Text(u.active ? 'Deactivate account' : 'Reactivate account'),
              ),
            ] else
              const Text('This is your account. Another administrator can change its role.'),
          ],
        ),
      ),
    );
  }
}

class _AddUserScreen extends StatefulWidget {
  const _AddUserScreen();

  @override
  State<_AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<_AddUserScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _number = TextEditingController();
  Role _role = Role.student;
  String? _departmentId;
  int? _year;
  Map<String, String> _errors = {};

  @override
  void dispose() {
    for (final c in [_name, _email, _number]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final departments = app.admin.departments();
    const gap = SizedBox(height: Space.m);
    return Scaffold(
      appBar: AppBar(title: const Text('Add user')),
      body: ListView(
        padding: const EdgeInsets.all(Space.l),
        children: [
          DropdownButtonFormField<Role>(
            initialValue: _role,
            decoration: InputDecoration(labelText: 'Role', errorText: _errors['role']),
            items: [
              for (final r in Role.values.where((r) => r != Role.platformAdmin)) DropdownMenuItem(value: r, child: Text(r.label)),
            ],
            onChanged: (r) => setState(() => _role = r ?? Role.student),
          ),
          gap,
          TextField(controller: _name, decoration: InputDecoration(labelText: 'Full name', errorText: _errors['fullName'])),
          gap,
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(labelText: 'Email', errorText: _errors['email']),
          ),
          if (_role == Role.student) ...[
            gap,
            TextField(controller: _number, decoration: InputDecoration(labelText: 'Student number', errorText: _errors['studentNumber'])),
            gap,
            DropdownButtonFormField<String>(
              initialValue: _departmentId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Department'),
              items: [for (final d in departments) DropdownMenuItem(value: d.id, child: Text(d.name))],
              onChanged: (v) => setState(() => _departmentId = v),
            ),
            gap,
            DropdownButtonFormField<int>(
              initialValue: _year,
              decoration: const InputDecoration(labelText: 'Year of study'),
              items: [for (var y = 1; y <= 5; y++) DropdownMenuItem(value: y, child: Text('Year $y'))],
              onChanged: (v) => setState(() => _year = v),
            ),
          ],
          gap,
          const Text('The account starts with the demo password demo1234.'),
          const SizedBox(height: Space.xl),
          FilledButton(
            onPressed: () async {
              setState(() => _errors = {});
              final ok = await runAction(
                context,
                () => app.admin.addUser(NewUserDraft(
                  fullName: _name.text,
                  email: _email.text,
                  role: _role,
                  studentNumber: _role == Role.student ? _number.text : null,
                  departmentId: _role == Role.student ? _departmentId : null,
                  yearOfStudy: _role == Role.student ? _year : null,
                )),
                success: 'User added.',
                onFieldErrors: (e) => setState(() => _errors = e),
              );
              if (ok && context.mounted) Navigator.pop(context);
            },
            child: const Text('Add user'),
          ),
        ],
      ),
    );
  }
}
