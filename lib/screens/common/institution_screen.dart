import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
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
      body: Readable(child: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, 0),
              child: Row(
                children: [
                  Icon(AppIcons.library, color: scheme.primary, size: 26),
                  const SizedBox(width: Space.s),
                  Expanded(child: Text('ZutLib', style: t.titleLarge?.copyWith(color: scheme.primary))),
                  const _DemoModeLabel(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.xxl, Space.l, Space.s),
              child: Text('Past papers, library loans and revision in one place', style: t.headlineMedium),
            ),
            Padding(
              padding: Space.screen,
              child: Text(
                'Find papers for your courses, borrow printed copies and practise with quizzes built from real exams.',
                style: t.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            const SectionHeader('Choose your institution'),
            Padding(
              padding: Space.screen,
              child: Panel(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    for (final (i, tenant) in tenants.indexed) ...[
                      if (i > 0) const Divider(),
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.xs),
                        leading: TenantMark(tenant),
                        title: Text(tenant.name, style: t.titleSmall),
                        subtitle: Text(tenant.shortCode),
                        trailing: const Icon(AppIcons.next, size: 18),
                        onTap: () => _open(context, tenant.id, tenant.name, tenant),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: Space.l),
            ListTile(
              leading: const Icon(AppIcons.admin, size: 20),
              title: Text('Platform administration', style: t.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
              subtitle: const Text('For the operator of the shared platform'),
              trailing: const Icon(AppIcons.next, size: 18),
              onTap: () => _open(context, platformTenantId, 'Platform administration', null),
            ),
          ],
        ),
      )),
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
    final p = AppPalette.of(context);
    return Tooltip(
      message: 'All data in this app is fictional',
      child: Tag('Demo mode', icon: AppIcons.info, foreground: p.info, background: p.infoBg),
    );
  }
}

class DemoModeBanner extends StatelessWidget {
  const DemoModeBanner({super.key});

  @override
  Widget build(BuildContext context) => const _DemoModeLabel();
}
