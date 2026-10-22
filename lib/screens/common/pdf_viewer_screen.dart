import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../services/resource_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';

/// In-app viewer with pinch zoom and page navigation (FR-RES-07).
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({super.key, required this.resourceId, required this.title});

  final String resourceId;
  final String title;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PdfControllerPinch? _controller;
  String? _error;
  int _page = 1;
  int _pages = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final file = await context.read<AppState>().resources.openFile(widget.resourceId);
    if (!mounted) return;
    final doc = switch (file) {
      AssetPaperFile(:final assetPath) => PdfDocument.openAsset(assetPath),
      BytesPaperFile(:final bytes) => PdfDocument.openData(bytes),
      null => null,
    };
    if (doc == null) {
      setState(() => _error = 'The file for this paper is missing. Ask the librarian to replace it.');
      return;
    }
    setState(() => _controller = PdfControllerPinch(document: doc));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _go(int page) {
    if (page < 1 || page > _pages) return;
    _controller?.animateToPage(pageNumber: page, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
      body: _error != null
          ? EmptyState(icon: Icons.picture_as_pdf_outlined, message: _error!)
          : controller == null
              ? const Align(alignment: Alignment.topCenter, child: LinearProgressIndicator())
              : PdfViewPinch(
                  controller: controller,
                  onDocumentLoaded: (doc) => setState(() => _pages = doc.pagesCount),
                  onPageChanged: (p) => setState(() => _page = p),
                  onDocumentError: (e) => setState(() => _error = 'This PDF could not be opened.'),
                ),
      bottomNavigationBar: _pages == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: Space.s),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous page',
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _page > 1 ? () => _go(_page - 1) : null,
                    ),
                    Expanded(
                      child: Text('Page $_page of $_pages', textAlign: TextAlign.center),
                    ),
                    IconButton(
                      tooltip: 'Next page',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _page < _pages ? () => _go(_page + 1) : null,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
