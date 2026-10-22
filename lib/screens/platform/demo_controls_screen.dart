import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';

/// FR-DEMO-02, FR-DEMO-03 and the FR-AUTH-07 short timeout toggle.
class DemoControlsScreen extends StatelessWidget {
  const DemoControlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final platform = context.watch<AppState>().platform;
    final offset = platform.clockOffset;
    final t = Theme.of(context).textTheme;

    Future<void> advance(int days) => runAction(
          context,
          () => platform.advanceClock(Duration(days: days)),
          success: 'Demo clock moved forward $days ${days == 1 ? 'day' : 'days'}. Due dates and expiries updated.',
        );

    return ListView(
      padding: const EdgeInsets.only(bottom: Space.xl),
      children: [
        const SectionHeader('Demo clock'),
        Padding(
          padding: Space.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(formatDateTime(platform.now), style: t.headlineSmall),
              const SizedBox(height: Space.xs),
              Text(
                offset == Duration.zero
                    ? 'Real time'
                    : '${offset.inDays} ${offset.inDays == 1 ? 'day' : 'days'} ahead of real time',
              ),
              const SizedBox(height: Space.l),
              Wrap(
                spacing: Space.s,
                runSpacing: Space.s,
                children: [
                  OutlinedButton(onPressed: () => advance(1), child: const Text('+1 day')),
                  OutlinedButton(onPressed: () => advance(2), child: const Text('+2 days')),
                  OutlinedButton(onPressed: () => advance(7), child: const Text('+7 days')),
                  TextButton(
                    onPressed: offset == Duration.zero
                        ? null
                        : () => runAction(context, platform.resetClock, success: 'Demo clock back to real time.'),
                    child: const Text('Back to real time'),
                  ),
                ],
              ),
              const SizedBox(height: Space.s),
              Text('Every due date, collection expiry and study reminder uses this clock.', style: t.bodySmall),
            ],
          ),
        ),
        const SectionHeader('Session'),
        SwitchListTile(
          title: const Text('Short inactivity timeout'),
          subtitle: const Text('Sign out after 5 minutes instead of 30'),
          value: platform.shortSessionTimeout,
          onChanged: (v) => platform.setShortSessionTimeout(v),
        ),
        const SectionHeader('Data'),
        ListTile(
          leading: Icon(Icons.restart_alt, color: Theme.of(context).colorScheme.error),
          title: const Text('Reset demo data'),
          subtitle: const Text('Restore the seed state. Removes every loan, upload, quiz attempt and account created during the demo.'),
          onTap: () async {
            if (await confirm(
                  context,
                  title: 'Reset demo data?',
                  message: 'All changes made during the demonstration will be lost and the demo clock returns to real time.',
                  action: 'Reset',
                  destructive: true,
                ) &&
                context.mounted) {
              await runAction(context, platform.resetDemoData, success: 'Demo data reset to the seed state.');
            }
          },
        ),
      ],
    );
  }
}
