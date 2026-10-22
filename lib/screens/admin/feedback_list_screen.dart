import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/format.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// FR-ADM-06
class FeedbackListScreen extends StatelessWidget {
  const FeedbackListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AppState>().admin;
    final items = admin.feedback();
    if (items.isEmpty) {
      return const EmptyState(icon: AppIcons.feedback, message: 'No feedback yet. Students can send it from their profile.');
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, i) {
        final f = items[i];
        return ListTile(
          title: Text(f.message),
          subtitle: Text('${admin.feedbackAuthor(f)} · ${formatDate(f.createdAt)}'),
        );
      },
    );
  }
}
