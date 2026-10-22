import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/errors.dart';
import '../../core/format.dart';
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
      return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.menu_book_outlined, message: e.message));
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
              icon: Icon(bookmarked ? Icons.bookmark : Icons.bookmark_border),
              onPressed: () => runAction(context, () => app.resources.toggleBookmark(r.id),
                  success: bookmarked ? 'Removed from saved papers.' : 'Saved.'),
            ),
          if (!isStudent)
            IconButton(
              tooltip: 'Edit paper',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ResourceFormScreen(resourceId: r.id)),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: Space.xxl),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
            child: Text(r.title, style: t.titleLarge),
          ),
          if (r.archived)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
              child: Text('Archived. Students cannot see this paper.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          Padding(
            padding: const EdgeInsets.all(Space.l),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.picture_as_pdf_outlined),
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
          ),
          Padding(
            padding: Space.screen,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(Space.l),
                child: Column(
                  children: [
                    if (course != null) InfoRow('Course', '${course.code} ${course.name}'),
                    if (department != null) InfoRow('Department', department.name),
                    InfoRow('Paper type', r.paperType.label),
                    InfoRow('Year', '${r.academicYear}, semester ${r.semester}'),
                    if (r.lecturer != null) InfoRow('Lecturer', r.lecturer!),
                    if (r.durationMinutes != null) InfoRow('Duration', '${r.durationMinutes} minutes'),
                    if (r.totalMarks != null) InfoRow('Total marks', '${r.totalMarks}'),
                    if (r.topics.isNotEmpty) InfoRow('Topics', r.topics.join(', ')),
                    InfoRow('Memo', r.hasMemo ? 'Marking guide attached' : 'No marking guide'),
                  ],
                ),
              ),
            ),
          ),
          SectionHeader('Assistant summary'),
          _SummaryBlock(summary: r.summary),
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
              child: Text('$available of ${copies.length} available'),
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
          if (isStudent) _MyLoanForPaper(resourceId: r.id),
          if (!isStudent)
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, 0),
              child: Text('Uploaded ${formatDate(r.uploadedAt)}', style: t.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.summary});

  final ResourceSummary? summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    if (s == null) {
      return const Padding(padding: Space.screen, child: Text('Summary not available'));
    }
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: Space.screen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.overview),
          const SizedBox(height: Space.m),
          Text('Question types', style: t.labelLarge),
          Text(s.questionTypes.join(', ')),
          const SizedBox(height: Space.m),
          Text('Mark distribution', style: t.labelLarge),
          for (final m in s.markDistribution)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(child: Text(m.section)),
                  Text('${m.marks} marks', style: AppText.code(context)),
                ],
              ),
            ),
        ],
      ),
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
            leading: const Icon(Icons.assignment_outlined),
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
