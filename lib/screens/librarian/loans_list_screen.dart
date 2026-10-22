import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/clock.dart';
import '../../core/format.dart';
import '../../core/permissions.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../state/app_state.dart';
import '../../widgets/actions.dart';
import '../../widgets/common.dart';
import '../common/loan_details_screen.dart';

/// All tenant loans filterable by status (FR-BOR-12) with CSV export (FR-ADM-07).
class LoansListScreen extends StatefulWidget {
  const LoansListScreen({super.key, this.initialStatus, this.standalone = false});

  final LoanStatus? initialStatus;

  /// Pushed from the dashboard rather than shown in the drawer.
  final bool standalone;

  @override
  State<LoansListScreen> createState() => _LoansListScreenState();
}

class _LoansListScreenState extends State<LoansListScreen> {
  late LoanStatus? _status = widget.initialStatus;

  Future<void> _export() async {
    final app = context.read<AppState>();
    final csv = app.loans.exportCsv();
    final stamp = Clock.now().toLocal().toIso8601String().substring(0, 10);
    try {
      final saved = await FilePicker.saveFile(
        fileName: 'zutlib-loans-$stamp.csv',
        bytes: Uint8List.fromList(utf8.encode(csv)),
        mimeType: 'text/csv',
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (mounted && saved != null) showMessage(context, 'Loan list exported.');
    } on Object {
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) showMessage(context, 'Saving is not available here, so the CSV was copied to the clipboard.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final loans = app.loans.tenantLoans(status: _status);
    final canExport = roleAllows(app.user!.role, Permission.processLoans);

    final body = Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
          child: Row(
            spacing: Space.s,
            children: [
              ChoiceChip(label: const Text('All'), selected: _status == null, onSelected: (_) => setState(() => _status = null)),
              for (final s in LoanStatus.values)
                ChoiceChip(label: Text(s.label), selected: _status == s, onSelected: (_) => setState(() => _status = s)),
            ],
          ),
        ),
        Expanded(
          child: loans.isEmpty
              ? EmptyState(
                  icon: Icons.assignment_outlined,
                  message: _status == null ? 'No loans yet.' : 'No ${_status!.label.toLowerCase()} loans.',
                )
              : ListView.separated(
                  itemCount: loans.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, i) {
                    final l = loans[i];
                    final r = app.loans.resourceFor(l);
                    final when = l.dueAt != null && l.status.isActive
                        ? 'due ${formatDate(l.dueAt!)}'
                        : 'requested ${formatDate(l.requestedAt)}';
                    return ListTile(
                      title: Text(r.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text('${app.loans.studentName(l)} · $when'),
                      trailing: StatusChip(l.status),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoanDetailsScreen(loanId: l.id))),
                    );
                  },
                ),
        ),
      ],
    );

    final exportButton = canExport
        ? IconButton(tooltip: 'Export loans as CSV', icon: const Icon(Icons.download_outlined), onPressed: _export)
        : null;
    if (widget.standalone) {
      return Scaffold(appBar: AppBar(title: const Text('Loans'), actions: [?exportButton]), body: body);
    }
    return Stack(
      children: [
        body,
        if (exportButton != null)
          Positioned(
            right: Space.l,
            bottom: Space.l,
            child: FloatingActionButton.extended(
              heroTag: 'export',
              onPressed: _export,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Export CSV'),
            ),
          ),
      ],
    );
  }
}
