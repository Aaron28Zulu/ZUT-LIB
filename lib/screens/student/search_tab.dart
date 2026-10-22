import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/resource_service.dart';
import '../../state/app_state.dart';
import '../../widgets/common.dart';
import '../../widgets/resource_tile.dart';
import 'browse_screen.dart';

/// Keyword search with combinable filters and sorting (SRS 3.4).
class SearchTab extends StatefulWidget {
  const SearchTab({super.key, this.includeArchived = false});

  /// Librarian view shows archived papers too (FR-RES-05).
  final bool includeArchived;

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final _controller = TextEditingController();
  late SearchQuery _query = SearchQuery(includeArchived: widget.includeArchived);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String text) {
    final app = context.read<AppState>();
    setState(() => _query = _query.copyWith(text: text));
    // Logged on submit only, so partial typing does not count as unmet searches.
    app.resources.search(_query, log: true);
    app.resources.addRecentSearch(text);
  }

  Future<T?> _pick<T>(String title, List<(T?, String)> options, T? current) {
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: Space.screen,
              child: Text(title, style: Theme.of(context).textTheme.titleMedium),
            ),
            RadioGroup<T?>(
              groupValue: current,
              onChanged: (v) => Navigator.pop(context, v),
              child: Column(
                children: [
                  for (final (value, label) in options)
                    RadioListTile<T?>(
                      value: value,
                      title: Text(label),
                      toggleable: false,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();
    final res = app.resources;
    final results = res.search(_query);
    final departments = res.departments();
    final courses = res.courses(departmentId: _query.departmentId);
    final years = {for (final r in res.search(SearchQuery(includeArchived: widget.includeArchived))) r.academicYear}.toList()
      ..sort((a, b) => b.compareTo(a));
    final recent = res.recentSearches();
    String deptName(String id) => departments.where((d) => d.id == id).firstOrNull?.code ?? 'Department';
    String courseCode(String id) => res.course(id)?.code ?? 'Course';

    final applied = <Widget>[
      if (_query.departmentId != null)
        InputChip(
          label: Text(deptName(_query.departmentId!)),
          onDeleted: () => setState(() => _query = _query.copyWith(departmentId: () => null, courseId: () => null)),
        ),
      if (_query.courseId != null)
        InputChip(
          label: Text(courseCode(_query.courseId!)),
          onDeleted: () => setState(() => _query = _query.copyWith(courseId: () => null)),
        ),
      if (_query.year != null)
        InputChip(label: Text('${_query.year}'), onDeleted: () => setState(() => _query = _query.copyWith(year: () => null))),
      if (_query.semester != null)
        InputChip(
          label: Text('Semester ${_query.semester}'),
          onDeleted: () => setState(() => _query = _query.copyWith(semester: () => null)),
        ),
      if (_query.paperType != null)
        InputChip(
          label: Text(_query.paperType!.label),
          onDeleted: () => setState(() => _query = _query.copyWith(paperType: () => null)),
        ),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
          child: SearchBar(
            controller: _controller,
            hintText: 'Course code, name or topic',
            leading: const Icon(Icons.search),
            trailing: [
              if (_controller.text.isNotEmpty)
                IconButton(
                  tooltip: 'Clear search',
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _controller.clear();
                    setState(() => _query = _query.copyWith(text: ''));
                  },
                ),
            ],
            onChanged: (v) => setState(() => _query = _query.copyWith(text: v)),
            onSubmitted: _submit,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
          child: Row(
            spacing: Space.s,
            children: [
              ActionChip(
                avatar: const Icon(Icons.account_tree_outlined, size: 18),
                label: const Text('Browse'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BrowseScreen())),
              ),
              FilterChip(
                label: const Text('Department'),
                selected: _query.departmentId != null,
                onSelected: (_) async {
                  final v = await _pick<String>('Department', [(null, 'Any'), for (final d in departments) (d.id, d.name)], _query.departmentId);
                  if (mounted) setState(() => _query = _query.copyWith(departmentId: () => v, courseId: () => null));
                },
              ),
              FilterChip(
                label: const Text('Course'),
                selected: _query.courseId != null,
                onSelected: (_) async {
                  final v = await _pick<String>('Course', [(null, 'Any'), for (final c in courses) (c.id, c.label)], _query.courseId);
                  if (mounted) setState(() => _query = _query.copyWith(courseId: () => v));
                },
              ),
              FilterChip(
                label: const Text('Year'),
                selected: _query.year != null,
                onSelected: (_) async {
                  final v = await _pick<int>('Academic year', [(null, 'Any'), for (final y in years) (y, '$y')], _query.year);
                  if (mounted) setState(() => _query = _query.copyWith(year: () => v));
                },
              ),
              FilterChip(
                label: const Text('Semester'),
                selected: _query.semester != null,
                onSelected: (_) async {
                  final v = await _pick<int>('Semester', [(null, 'Any'), (1, 'Semester 1'), (2, 'Semester 2')], _query.semester);
                  if (mounted) setState(() => _query = _query.copyWith(semester: () => v));
                },
              ),
              FilterChip(
                label: const Text('Type'),
                selected: _query.paperType != null,
                onSelected: (_) async {
                  final v = await _pick<PaperType>('Paper type', [(null, 'Any'), for (final p in PaperType.values) (p, p.label)], _query.paperType);
                  if (mounted) setState(() => _query = _query.copyWith(paperType: () => v));
                },
              ),
              PopupMenuButton<SortOrder>(
                tooltip: 'Sort results',
                initialValue: _query.sort,
                onSelected: (s) => setState(() => _query = _query.copyWith(sort: s)),
                itemBuilder: (_) => [for (final s in SortOrder.values) PopupMenuItem(value: s, child: Text(s.label))],
                child: Chip(avatar: const Icon(Icons.sort, size: 18), label: Text(_query.sort.label)),
              ),
            ],
          ),
        ),
        if (applied.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.l),
            child: Align(alignment: Alignment.centerLeft, child: Wrap(spacing: Space.s, runSpacing: Space.xs, children: applied)),
          ),
        Expanded(
          child: _query.text.isEmpty && !_query.hasFilters && recent.isNotEmpty
              ? ListView(
                  children: [
                    const SectionHeader('Recent searches'),
                    for (final term in recent)
                      ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(term),
                        onTap: () {
                          _controller.text = term;
                          _submit(term);
                        },
                      ),
                    const SectionHeader('All papers'),
                    for (final r in results) ResourceTile(r),
                  ],
                )
              : results.isEmpty
                  ? EmptyState(
                      icon: Icons.search_off,
                      message: 'No papers match your search.',
                      actionLabel: _query.hasFilters ? 'Clear filters' : null,
                      onAction: () => setState(() => _query = _query.clearFilters()),
                    )
                  : ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xs),
                          child: Text('${results.length} ${results.length == 1 ? 'paper' : 'papers'}',
                              style: Theme.of(context).textTheme.labelLarge),
                        ),
                        for (final r in results) ResourceTile(r),
                      ],
                    ),
        ),
      ],
    );
  }
}
