import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/auth_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import 'sign_in_screen.dart';

/// FR-TEN-03: choose the institution before entering credentials.
class InstitutionScreen extends StatelessWidget {
  const InstitutionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final tenants = app.auth.tenants();
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.xl, Space.l, Space.s),
              child: Row(
                children: [
                  Icon(Icons.local_library_outlined, color: scheme.primary),
                  const SizedBox(width: Space.s),
                  Expanded(child: Text('ZutLib', style: t.titleLarge, overflow: TextOverflow.ellipsis)),
                  const _DemoModeLabel(),
                ],
              ),
            ),
            Padding(
              padding: Space.screen,
              child: Text('Choose your institution', style: t.headlineSmall),
            ),
            const SizedBox(height: Space.s),
            for (final tenant in tenants)
              ListTile(
                leading: TenantMark(tenant),
                title: Text(tenant.name),
                subtitle: Text(tenant.shortCode),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _open(context, tenant.id, tenant.name, tenant),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text('Platform administration'),
              subtitle: const Text('For the operator of the shared platform'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _open(context, platformTenantId, 'Platform administration', null),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, String id, String name, Tenant? tenant) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SignInScreen(tenantId: id, tenantName: name, tenant: tenant)),
    );
  }
}

/// FR-DEMO-05
class _DemoModeLabel extends StatelessWidget {
  const _DemoModeLabel();

  @override
  Widget build(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return Tooltip(
      message: 'All data in this app is fictional',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: Space.xs),
        decoration: BoxDecoration(color: s.tertiaryContainer, borderRadius: BorderRadius.circular(6)),
        child: Text('Demo mode', style: TextStyle(color: s.onTertiaryContainer)),
      ),
    );
  }
}

class DemoModeBanner extends StatelessWidget {
  const DemoModeBanner({super.key});

  @override
  Widget build(BuildContext context) => const _DemoModeLabel();
}
