import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';

/// FR-ADM-06
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _text = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Send feedback')),
      body: Readable(child: ListView(
        padding: const EdgeInsets.all(Space.l),
        children: [
          const Text('Tell your library what is missing or what could work better. Administrators at your institution read this.'),
          const SizedBox(height: Space.l),
          TextField(
            controller: _text,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(labelText: 'Your feedback', errorText: _error),
          ),
          const SizedBox(height: Space.l),
          FilledButton(
            onPressed: () async {
              final ok = await runAction(
                context,
                () => app.admin.sendFeedback(_text.text),
                success: 'Thank you. Your feedback was sent.',
                onFieldErrors: (e) => setState(() => _error = e['message']),
              );
              if (ok && context.mounted) Navigator.pop(context);
            },
            child: const Text('Send'),
          ),
        ],
      )),
    );
  }
}
