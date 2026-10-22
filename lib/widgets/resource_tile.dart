import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_icons.dart';
import '../core/theme.dart';
import '../models/models.dart';
import '../screens/common/paper_details_screen.dart';
import '../state/app_state.dart';
import 'common.dart';

String _shortType(PaperType t) => switch (t) {
      PaperType.final_ => 'Final',
      PaperType.mid => 'Mid-sem',
      PaperType.supp => 'Supp',
      PaperType.assignment => 'Assignment',
      PaperType.notes => 'Notes',
    };

void _open(BuildContext context, Resource r) => Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaperDetailsScreen(resourceId: r.id)),
    );

/// A paper in a list, laid out like a course listing: thumbnail, bold title,
/// a muted metadata line and, when given, why it is shown.
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
    final p = AppPalette.of(context);
    final t = Theme.of(context).textTheme;
    final code = course?.code ?? '';
    final meta = [
      resource.paperType.label,
      '${resource.academicYear}',
      'Semester ${resource.semester}',
    ].join(' · ');

    return InkWell(
      onTap: () => _open(context, resource),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PaperThumb(code: code, caption: '${resource.academicYear}'),
            const SizedBox(width: Space.l),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course == null ? resource.title : '$code ${course.name}',
                    style: t.titleMedium,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 2),
                  Text(meta, style: AppText.muted(context)),
                  if (subtitle != null) ...[
                    const SizedBox(height: Space.xs),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: ExcludeSemantics(child: Icon(AppIcons.target, size: 14, color: p.info)),
                        ),
                        const SizedBox(width: Space.xs),
                        Expanded(child: Text(subtitle!, style: t.bodySmall?.copyWith(color: p.info))),
                      ],
                    ),
                  ],
                  if (available != null || resource.archived || resource.hasMemo) ...[
                    const SizedBox(height: Space.s),
                    Wrap(
                      spacing: Space.s,
                      runSpacing: Space.xs,
                      children: [
                        if (available != null)
                          available == 0
                              ? Tag('No copies free', icon: AppIcons.copies, foreground: p.warning, background: p.warningBg)
                              : Tag(
                                  '$available ${available == 1 ? 'copy' : 'copies'} free',
                                  icon: AppIcons.copies,
                                  foreground: p.success,
                                  background: p.successBg,
                                ),
                        if (resource.hasMemo) const Tag('Memo', icon: AppIcons.done),
                        if (resource.archived)
                          Tag('Archived', icon: AppIcons.warning, foreground: p.danger, background: p.dangerBg),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A paper on a horizontal shelf: big thumbnail on top, title and reason
/// below, like a course card on a catalogue home page. Flat, no shadow.
class ResourceCard extends StatelessWidget {
  const ResourceCard(this.resource, {super.key, this.reason});

  final Resource resource;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    final course = app.resources.course(resource.courseId);
    final code = course?.code ?? '';
    final t = Theme.of(context).textTheme;
    final p = AppPalette.of(context);
    return Semantics(
      button: true,
      label: '${course?.name ?? resource.title}, ${resource.paperType.label} ${resource.academicYear}'
          '${reason == null ? '' : '. $reason'}',
      excludeSemantics: true,
      child: InkWell(
        onTap: () => _open(context, resource),
        borderRadius: Radii.tagRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PaperThumb(
              code: code,
              caption: '${_shortType(resource.paperType)} ${resource.academicYear}',
              width: Sizes.shelfCardWidth,
              height: Sizes.shelfThumbHeight,
            ),
            const SizedBox(height: Space.s),
            Text(course?.name ?? resource.title, style: t.titleSmall, maxLines: 2),
            const SizedBox(height: 2),
            Text('${resource.paperType.label} · Sem ${resource.semester}', style: t.bodySmall),
            if (reason != null) ...[
              const SizedBox(height: Space.xs),
              Text(reason!, style: t.bodySmall?.copyWith(color: p.info), maxLines: 3),
            ],
            const SizedBox(height: Space.xs),
          ],
        ),
      ),
    );
  }
}
