import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/theme.dart';
import '../student/search_tab.dart';
import 'resource_form_screen.dart';

/// Librarian paper list: the student search, plus archived papers and upload.
class ResourcesListScreen extends StatelessWidget {
  const ResourcesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const SearchTab(includeArchived: true),
        Positioned(
          right: Space.l,
          bottom: Space.l,
          child: FloatingActionButton.extended(
            heroTag: 'upload',
            icon: const Icon(AppIcons.upload),
            label: const Text('Upload paper'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResourceFormScreen())),
          ),
        ),
      ],
    );
  }
}
