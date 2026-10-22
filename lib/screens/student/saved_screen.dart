import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/resource_tile.dart';

/// Saved papers (FR-RES-08) and recently opened papers (FR-RES-09).
class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final res = context.watch<AppState>().resources;
    final saved = res.bookmarked();
    final recent = res.recentlyViewed();
    return Scaffold(
      appBar: AppBar(title: const Text('Saved papers')),
      body: saved.isEmpty && recent.isEmpty
          ? const EmptyState(
              icon: Icons.bookmark_border,
              message: 'No saved papers. Tap the bookmark on a paper to save it.',
            )
          : ListView(
              children: [
                const SectionHeader('Saved'),
                if (saved.isEmpty)
                  const ListTile(title: Text('Tap the bookmark on a paper to save it.'))
                else
                  for (final r in saved) ResourceTile(r),
                if (recent.isNotEmpty) ...[
                  const SectionHeader('Recently opened, available offline'),
                  for (final r in recent) ResourceTile(r, showAvailability: false),
                ],
              ],
            ),
    );
  }
}
