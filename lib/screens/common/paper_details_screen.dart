import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/errors.dart';
import '../../core/format.dart';
import '../../core/rules.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';
import '../librarian/copies_screen.dart';
import '../librarian/resource_form_screen.dart';
import 'loan_details_screen.dart';
import 'pdf_viewer_screen.dart';

/// Metadata, assistant summary, copies and the Request button (SRS 8).
class PaperDetailsScreen extends StatelessWidget {
  const PaperDetailsScreen({super.key, required this.resourceId});

  final String resourceId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final Resource r;
    try {
      r = app.resources.resource(resourceId);
    } on AppException catch (e) {
      return Scaffold(appBar: AppBar(), body: Readable(child: EmptyState(icon: AppIcons.paper, message: e.message)));
    }
    final user = app.user!;
    final isStudent = user.role == Role.student;
    final course = app.resources.course(r.courseId);
    final department = course == null ? null : app.resources.department(course.departmentId);
    final copies = app.resources.copies(r.id);
    final available = copies.where((c) => c.status == CopyStatus.available).length;
    final bookmarked = app.resources.isBookmarked(r.id);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(course?.code ?? 'Paper'),
        actions: [
          if (isStudent)
            IconButton(
              tooltip: bookmarked ? 'Remove from saved' : 'Save paper',
              icon: Icon(bookmarked ? AppIcons.bookmarked : AppIcons.bookmark),
              onPressed: () => runAction(context, () => app.resources.toggleBookmark(r.id),
                  success: bookmarked ? 'Removed from saved papers.' : 'Saved.'),
            ),
          if (!isStudent)
            IconButton(
              tooltip: 'Edit paper',
              icon: const Icon(AppIcons.edit),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ResourceFormScreen(resourceId: r.id)),
              ),
            ),
        ],
      ),
      body: Readable(child: ListView(
        padding: const EdgeInsets.only(bottom: Space.xxl),
        children: [
          // Header band, like a course landing page: kicker, title, facts, actions.
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.fromLTRB(Space.l, Space.xl, Space.l, Space.l),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (department != null) Text(department.name.toUpperCase(), style: AppText.overline(context)),
                const SizedBox(height: Space.s),
                Text(course == null ? r.title : '${course.code} ${course.name}', style: t.headlineSmall),
                const SizedBox(height: Space.s),
                Text(
                  '${r.paperType.label} · ${r.academicYear} · Semester ${r.semester}'
                  '${r.lecturer == null ? '' : ' · ${r.lecturer}'}',
                  style: AppText.muted(context),
                ),
                const SizedBox(height: Space.m),
                Wrap(
                  spacing: Space.s,
                  runSpacing: Space.xs,
                  children: [
                    if (r.durationMinutes != null) Tag('${r.durationMinutes} min', icon: AppIcons.time),
                    if (r.totalMarks != null) Tag('${r.totalMarks} marks', icon: AppIcons.target),
                    Tag(r.hasMemo ? 'Memo included' : 'No memo', icon: r.hasMemo ? AppIcons.done : AppIcons.info),
                    if (copies.isNotEmpty)
                      Tag(
                        '$available of ${copies.length} copies free',
                        icon: AppIcons.copies,
                        foreground: available > 0 ? AppPalette.of(context).success : AppPalette.of(context).warning,
                        background: available > 0 ? AppPalette.of(context).successBg : AppPalette.of(context).warningBg,
                      ),
                    if (r.archived)
                      Tag(
                        'Archived, hidden from students',
                        icon: AppIcons.warning,
                        foreground: AppPalette.of(context).danger,
                        background: AppPalette.of(context).dangerBg,
                      ),
                  ],
                ),
                const SizedBox(height: Space.l),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(AppIcons.pdf, size: 18),
                        label: const Text('Open paper'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PdfViewerScreen(resourceId: r.id, title: r.title)),
                        ),
                      ),
                    ),
                    if (isStudent) ...[
                      const SizedBox(width: Space.s),
                      Expanded(child: _RequestButton(resourceId: r.id)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const Divider(),
          if (isStudent) _MyLoanForPaper(resourceId: r.id),
          if (r.topics.isNotEmpty) ...[
            const SectionHeader('Topics covered'),
            Padding(
              padding: Space.screen,
              child: Wrap(
                spacing: Space.s,
                runSpacing: Space.s,
                children: [for (final topic in r.topics) Tag(topic, icon: AppIcons.check)],
              ),
            ),
          ],
          const SectionHeader('About this paper', subtitle: 'Summary prepared by the study assistant'),
          _SummaryBlock(summary: r.summary, totalMarks: r.totalMarks),
          SectionHeader(
            'Printed copies',
            trailing: isStudent
                ? null
                : TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => CopiesScreen(resourceId: r.id)),
                    ),
                    child: const Text('Manage'),
                  ),
          ),
          if (copies.isEmpty)
            const Padding(
              padding: Space.screen,
              child: Text('The library has no printed copies of this paper.'),
            )
          else ...[
            Padding(
              padding: Space.screen,
              child: Text('$available of ${copies.length} available to borrow for ${Rules.loanPeriod.inDays} days', style: AppText.muted(context)),
            ),
            if (!isStudent)
              for (final c in copies)
                ListTile(
                  dense: true,
                  title: Text('Copy ${c.copyNumber}'),
                  subtitle: Text('Shelf ${c.shelfLocation}'),
                  trailing: Text(c.status.label),
                ),
          ],
          if (!isStudent)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, 0),
              child: Text('Uploaded ${formatDate(r.uploadedAt)}', style: t.bodySmall),
            ),
        ],
      )),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.summary, this.totalMarks});

  final ResourceSummary? summary;
  final int? totalMarks;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    if (s == null) {
      return Padding(padding: Space.screen, child: Text('Summary not available', style: AppText.muted(context)));
    }
    final t = Theme.of(context).textTheme;
    final total = totalMarks ?? s.markDistribution.fold<int>(0, (a, m) => a + m.marks);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(padding: Space.screen, child: Text(s.overview, style: t.bodyLarge)),
        const SizedBox(height: Space.l),
        Padding(padding: Space.screen, child: Text('QUESTION TYPES', style: AppText.overline(context))),
        const SizedBox(height: Space.s),
        Padding(
          padding: Space.screen,
          child: Wrap(spacing: Space.s, runSpacing: Space.s, children: [for (final q in s.questionTypes) Tag(q)]),
        ),
        const SizedBox(height: Space.l),
        Padding(padding: Space.screen, child: Text('MARK DISTRIBUTION', style: AppText.overline(context))),
        for (final m in s.markDistribution)
          ProgressRow(
            label: m.section,
            value: total == 0 ? 0 : m.marks / total,
            caption: '${m.marks} marks',
          ),
      ],
    );
  }
}

/// FR-BOR-01: disabled with a reason when the student cannot request.
class _RequestButton extends StatelessWidget {
  const _RequestButton({required this.resourceId});

  final String resourceId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final reason = app.loans.requestBlockReason(resourceId);
    return Tooltip(
      message: reason ?? 'Ask the library to hold a printed copy for you',
      triggerMode: TooltipTriggerMode.tap,
      child: OutlinedButton(
        onPressed: reason != null
            ? null
            : () async {
                final ok = await confirm(
                  context,
                  title: 'Request a printed copy?',
                  message: 'The librarian will review your request. When it is approved you get a '
                      'collection code to show at the library within 48 hours.',
                  action: 'Request copy',
                );
                if (ok && context.mounted) {
                  await runAction(context, () => app.loans.request(resourceId),
                      success: 'Request sent. The librarian will review it.');
                }
              },
        child: const Text('Request copy'),
      ),
    );
  }
}

class _MyLoanForPaper extends StatelessWidget {
  const _MyLoanForPaper({required this.resourceId});

  final String resourceId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final reason = app.loans.requestBlockReason(resourceId);
    final active = app.loans.myLoans().where((l) => l.resourceId == resourceId && l.status.isActive);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (reason != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
            child: Text(reason, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ),
        for (final l in active)
          ListTile(
            leading: const Icon(AppIcons.loans),
            title: const Text('Your loan'),
            subtitle: l.dueAt == null ? null : Text('Due ${formatDate(l.dueAt!)}'),
            trailing: StatusChip(l.status),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LoanDetailsScreen(loanId: l.id)),
            ),
          ),
      ],
    );
  }
}
