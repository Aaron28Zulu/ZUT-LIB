import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../core/app_icons.dart';
import '../../core/errors.dart';
import '../../core/theme.dart';
import '../../services/loan_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../common/loan_details_screen.dart';

enum _Mode { collect, giveBack }

/// FR-BOR-06 / FR-BOR-09: camera scanning on Android; the 6-character code
/// field works everywhere (and is the only option on web, SRS 2.4).
class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _code = TextEditingController();
  _Mode _mode = _Mode.collect;
  bool _camera = false;
  bool _busy = false;
  ScanResult? _result;
  String? _error;

  bool get _cameraSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _process(String code) async {
    if (_busy || code.trim().isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
      _camera = false;
    });
    final loans = context.read<AppState>().loans;
    try {
      final r = _mode == _Mode.collect ? await loans.collect(code) : await loans.returnByCode(code);
      if (mounted) setState(() => _result = r);
      _code.clear();
    } on AppException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final result = _result;
    return ListView(
      padding: const EdgeInsets.all(Space.l),
      children: [
        SegmentedButton<_Mode>(
          segments: const [
            ButtonSegment(value: _Mode.collect, label: Text('Collection'), icon: Icon(AppIcons.signIn)),
            ButtonSegment(value: _Mode.giveBack, label: Text('Return'), icon: Icon(AppIcons.signOut)),
          ],
          selected: {_mode},
          onSelectionChanged: (s) => setState(() {
            _mode = s.first;
            _result = null;
            _error = null;
          }),
        ),
        const SizedBox(height: Space.l),
        if (_camera)
          ClipRRect(
            borderRadius: Radii.panelRadius,
            child: SizedBox(
              height: 280,
              child: MobileScanner(
                onDetect: (capture) {
                  final value = capture.barcodes.firstOrNull?.rawValue;
                  if (value != null) _process(value);
                },
              ),
            ),
          )
        else if (_cameraSupported)
          FilledButton.icon(
            icon: const Icon(AppIcons.scan),
            label: Text(_mode == _Mode.collect ? 'Scan student\'s code' : 'Scan loan code'),
            onPressed: () => setState(() => _camera = true),
          ),
        if (_camera)
          TextButton(onPressed: () => setState(() => _camera = false), child: const Text('Stop camera')),
        const SizedBox(height: Space.l),
        Text(
          _cameraSupported ? 'Or type the 6-character code' : 'Type the 6-character code shown on the student\'s loan',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: Space.s),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _code,
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'Code', counterText: ''),
                onSubmitted: _process,
              ),
            ),
            const SizedBox(width: Space.s),
            FilledButton(
              onPressed: _busy ? null : () => _process(_code.text),
              child: Text(_mode == _Mode.collect ? 'Collect' : 'Return'),
            ),
          ],
        ),
        const SizedBox(height: Space.l),
        if (_error != null)
          Card(
            color: scheme.errorContainer,
            child: ListTile(
              leading: Icon(AppIcons.warning, color: scheme.onErrorContainer),
              title: Text(_error!, style: TextStyle(color: scheme.onErrorContainer)),
            ),
          ),
        if (result != null)
          Card(
            color: scheme.primaryContainer,
            child: ListTile(
              leading: Icon(AppIcons.done, color: scheme.onPrimaryContainer),
              title: Text(result.message, style: TextStyle(color: scheme.onPrimaryContainer)),
              subtitle: Text(context.read<AppState>().loans.resourceFor(result.loan).title,
                  style: TextStyle(color: scheme.onPrimaryContainer)),
              trailing: StatusChip(result.loan.status),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => LoanDetailsScreen(loanId: result.loan.id)),
              ),
            ),
          ),
      ],
    );
  }
}
