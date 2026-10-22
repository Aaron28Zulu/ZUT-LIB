import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../models/models.dart';
import '../screens/common/paper_details_screen.dart';
import '../state/app_state.dart';

class ResourceTile extends StatelessWidget {
  const ResourceTile(this.resource, {super.key, this.subtitle, this.showAvailability = true});

  final Resource resource;

  /// Replaces the default metadata line, e.g. a recommendation reason.
  final String? subtitle;
  final bool showAvailability;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final course = app.resources.course(resource.courseId);
    final available = showAvailability ? app.resources.availableCopies(resource.id) : null;
    final scheme = Theme.of(context).colorScheme;
    final meta = [
      resource.paperType.label,
      '${resource.academicYear}',
      'Sem ${resource.semester}',
      if (available != null) available == 0 ? 'No copies free' : '$available ${available == 1 ? 'copy' : 'copies'} free',
    ].join(' · ');
    return ListTile(
      leading: const Icon(Icons.menu_book_outlined),
      title: Text(course == null ? resource.title : '${course.code} ${course.name}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(meta),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text(subtitle!, style: TextStyle(color: scheme.primary)),
            ),
          if (resource.archived)
            Text('Archived', style: TextStyle(color: scheme.error)),
        ],
      ),
      isThreeLine: subtitle != null || resource.archived,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PaperDetailsScreen(resourceId: resource.id)),
      ),
    );
  }
}
