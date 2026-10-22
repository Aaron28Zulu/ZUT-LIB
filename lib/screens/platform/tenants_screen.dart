import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';

/// FR-TEN-05 and FR-ADM-05: institutions with totals, never student records.
class TenantsScreen extends StatelessWidget {
  const TenantsScreen({super.key});

  static const _colours = ['#1B5E20', '#0D47A1', '#6A1B9A', '#B71C1C', '#E65100', '#004D40'];

  @override
  Widget build(BuildContext context) {
    final platform = context.watch<AppState>().platform;
    final totals = platform.totals();
    final sum = (
      users: totals.fold<int>(0, (s, t) => s + t.users),
      resources: totals.fold<int>(0, (s, t) => s + t.resources),
      loans: totals.fold<int>(0, (s, t) => s + t.loans),
    );
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-tenant',
        icon: const Icon(AppIcons.addInstitution),
        label: const Text('Add institution'),
        onPressed: () => _add(context),
      ),
      body: Readable(child: ListView(
        padding: const EdgeInsets.only(top: Space.l, bottom: 88),
        children: [
          StatGrid([
            StatTile('Institutions', totals.length),
            StatTile('Users', sum.users),
            StatTile('Papers', sum.resources),
            StatTile('Loans', sum.loans),
          ]),
          const SectionHeader('Per institution'),
          for (final t in totals)
            ListTile(
              leading: TenantMark(t.tenant),
              title: Text(t.tenant.name),
              subtitle: Text('${t.users} users · ${t.resources} papers · ${t.loans} loans'),
            ),
          const Padding(
            padding: EdgeInsets.all(Space.l),
            child: Text('Platform totals are counts only. Individual student records stay with each institution.'),
          ),
        ],
      )),
    );
  }

  Future<void> _add(BuildContext context) async {
    final platform = context.read<AppState>().platform;
    final name = TextEditingController();
    final code = TextEditingController();
    var colour = _colours[2];
    await showDialog<void>(
      context: context,
      builder: (dialog) {
        Map<String, String> errors = {};
        return StatefulBuilder(
          builder: (dialog, setState) => AlertDialog(
            title: const Text('Add institution'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(controller: name, decoration: InputDecoration(labelText: 'Name', errorText: errors['name'])),
                  const SizedBox(height: Space.m),
                  TextField(
                    controller: code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(labelText: 'Short code', errorText: errors['shortCode']),
                  ),
                  const SizedBox(height: Space.m),
                  const Text('Theme colour'),
                  const SizedBox(height: Space.s),
                  Wrap(
                    spacing: Space.s,
                    children: [
                      for (final c in _colours)
                        Semantics(
                          label: 'Colour $c',
                          selected: c == colour,
                          child: InkWell(
                            onTap: () => setState(() => colour = c),
                            customBorder: const CircleBorder(),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(int.parse('FF${c.substring(1)}', radix: 16)),
                              child: c == colour ? const Icon(AppIcons.check, color: Colors.white, size: 18) : null,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: Space.m),
                  const Text('The new institution starts with no data.'),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('Cancel')),
              FilledButton(
                onPressed: () async {
                  final ok = await runAction(dialog, () => platform.addTenant(name.text, code.text, colour),
                      success: 'Institution added. It now appears on the sign-in screen.',
                      onFieldErrors: (e) => setState(() => errors = e));
                  if (ok && dialog.mounted) Navigator.pop(dialog);
                },
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );
  }
}
