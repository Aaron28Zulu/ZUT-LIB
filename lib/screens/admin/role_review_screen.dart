import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';

/// FR-ADM-04: staff roles with grant dates; revoking applies at next sign-in.
class RoleReviewScreen extends StatelessWidget {
  const RoleReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final staff = app.admin.staffRoles();
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(Space.l),
          child: Text('Review who holds librarian and administrator roles. Revoke roles that are no longer needed.'),
        ),
        if (staff.isEmpty) const EmptyState(icon: AppIcons.roleReview, message: 'No staff roles at this institution.'),
        for (final u in staff)
          ListTile(
            title: Text(u.fullName),
            subtitle: Text(
              '${u.role.label} since ${formatDate(u.roleGrantedAt)}'
              '${u.pendingRole != null ? '\nBecomes ${u.pendingRole!.label.toLowerCase()} at next sign-in' : ''}',
            ),
            isThreeLine: u.pendingRole != null,
            trailing: u.id == app.user!.id || u.pendingRole != null
                ? null
                : TextButton(
                    onPressed: () async {
                      if (await confirm(
                            context,
                            title: 'Revoke ${u.role.label.toLowerCase()} role?',
                            message: '${u.fullName} becomes a student account at their next sign-in.',
                            action: 'Revoke',
                            destructive: true,
                          ) &&
                          context.mounted) {
                        await runAction(context, () => app.admin.revokeRole(u.id), success: 'Role will be revoked at next sign-in.');
                      }
                    },
                    child: const Text('Revoke'),
                  ),
          ),
      ],
    );
  }
}
