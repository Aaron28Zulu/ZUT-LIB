import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';

/// FR-RES-06: physical copies with copy number and shelf location.
class CopiesScreen extends StatelessWidget {
  const CopiesScreen({super.key, required this.resourceId});

  final String resourceId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final r = app.resources.resource(resourceId);
    final copies = app.resources.copies(resourceId);
    return Scaffold(
      appBar: AppBar(title: const Text('Printed copies')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(AppIcons.add),
        label: const Text('Add copy'),
        onPressed: () async {
          final shelf = await promptText(context, title: 'Add copy', label: 'Shelf location, e.g. B2-04', action: 'Add');
          if (shelf != null && context.mounted) {
            await runAction(context, () => app.resources.addCopy(resourceId, shelf), success: 'Copy added.');
          }
        },
      ),
      body: Readable(child: copies.isEmpty
          ? const EmptyState(icon: AppIcons.copies, message: 'No printed copies recorded for this paper.')
          : ListView(
              children: [
                ListTile(title: Text(r.title), subtitle: Text('${copies.length} copies')),
                const Divider(),
                for (final c in copies)
                  ListTile(
                    title: Text('Copy ${c.copyNumber}'),
                    subtitle: Text('Shelf ${c.shelfLocation} · ${c.status.label}'),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Copy actions',
                      onSelected: (v) async {
                        if (v == 'move') {
                          final shelf = await promptText(context,
                              title: 'Move copy ${c.copyNumber}', label: 'Shelf location', action: 'Save', initial: c.shelfLocation);
                          if (shelf != null && context.mounted) {
                            await runAction(context, () => app.resources.updateCopy(c.id, shelf), success: 'Shelf updated.');
                          }
                        } else if (v == 'remove' &&
                            await confirm(context,
                                title: 'Remove copy ${c.copyNumber}?',
                                message: 'Use this when a copy is lost or withdrawn.',
                                action: 'Remove',
                                destructive: true) &&
                            context.mounted) {
                          await runAction(context, () => app.resources.removeCopy(c.id), success: 'Copy removed.');
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'move', child: Text('Change shelf')),
                        PopupMenuItem(
                          value: 'remove',
                          enabled: c.status == CopyStatus.available,
                          child: const Text('Remove copy'),
                        ),
                      ],
                    ),
                  ),
              ],
            )),
    );
  }
}
