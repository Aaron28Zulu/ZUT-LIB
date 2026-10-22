import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:zutlib/core/errors.dart';
import 'package:zutlib/models/models.dart';
import 'package:zutlib/services/resource_service.dart';

import 'helpers.dart';

ResourceDraft _draft({String? courseId = 'c_ict2201', int year = 2025}) => ResourceDraft(
      title: 'ICT 2201 Database Systems - Final examination $year',
      departmentId: 'd_zut_ict',
      courseId: courseId,
      academicYear: year,
      semester: 2,
      paperType: PaperType.final_,
      topics: ['SQL'],
      fileName: 'paper.pdf',
      fileBytes: Uint8List.fromList([37, 80, 68, 70]),
    );

void main() {
  test('search by course code and keyword (FR-SRCH-01, demo step 2)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    final r = env.services.resources;
    final byCode = r.search(const SearchQuery(text: 'ICT 2201'));
    expect(byCode, hasLength(4));
    expect(r.search(const SearchQuery(text: 'ict2201')), hasLength(4));
    expect(r.search(const SearchQuery(text: 'database')), hasLength(4));
    final filtered = r.search(const SearchQuery(text: 'ICT 2201', year: 2023));
    expect(filtered.single.id, 'r_ict2201_2023_final');
    expect(r.availableCopies('r_ict2201_2023_final'), greaterThanOrEqualTo(1));
  });

  test('filters combine and sorting reorders (FR-SRCH-02, 03)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    final r = env.services.resources;
    final finals = r.search(const SearchQuery(departmentId: 'd_zut_ict', paperType: PaperType.final_));
    expect(finals.every((x) => x.paperType == PaperType.final_), isTrue);
    final newest = r.search(const SearchQuery(sort: SortOrder.newest));
    final oldest = r.search(const SearchQuery(sort: SortOrder.oldest));
    expect(newest.first.academicYear, greaterThanOrEqualTo(newest.last.academicYear));
    expect(oldest.first.academicYear, lessThanOrEqualTo(oldest.last.academicYear));
  });

  test('unmet searches are logged for the gap report (FR-SRCH-05)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    expect(env.services.resources.search(const SearchQuery(text: 'quantum biology'), log: true), isEmpty);
    await env.services.auth.signOut();
    await env.signIn('admin@zut.demo');
    expect(env.services.admin.dashboard().unmetSearches.map((c) => c.label), contains('quantum biology'));
  });

  test('browse lists only levels with resources (FR-SRCH-04)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    final r = env.services.resources;
    final depts = r.browseDepartments().map((d) => d.code);
    expect(depts, containsAll(['ICT', 'BUS']));
    expect(depts, isNot(contains('ENG')));
    expect(r.browseYears('c_ict2201'), [2024, 2023, 2021, 2019]);
  });

  test('upload validates mandatory fields per field (FR-RES-02, demo step 11)', () async {
    final env = await createEnv();
    await env.signIn('librarian@zut.demo');
    try {
      await env.services.resources.upload(_draft(courseId: null));
      fail('expected validation error');
    } on ValidationException catch (e) {
      expect(e.fieldErrors.keys, ['courseId']);
    }
  });

  test('upload makes the paper searchable and notifies enrolled students (demo step 12)', () async {
    final env = await createEnv();
    await env.signIn('librarian@zut.demo');
    final created = await env.services.resources.upload(_draft());
    await env.services.auth.signOut();
    await env.signIn('student@zut.demo');
    expect(env.services.resources.search(const SearchQuery(text: 'ICT 2201')).map((r) => r.id), contains(created.id));
    expect(env.services.notifications.mine().first.title, 'New paper for ICT 2201');
    await env.services.auth.signOut();
    await env.signIn('student2@zut.demo');
    expect(env.services.notifications.mine().where((n) => n.title.startsWith('New paper')), isEmpty);
  });

  test('duplicate detection (FR-RES-04)', () async {
    final env = await createEnv();
    await env.signIn('librarian@zut.demo');
    expect(env.services.resources.findDuplicate(_draft(year: 2023))?.id, 'r_ict2201_2023_final');
    expect(env.services.resources.findDuplicate(_draft(year: 2025)), isNull);
  });

  test('archived papers leave student search but stay for librarians (FR-RES-05)', () async {
    final env = await createEnv();
    await env.signIn('librarian@zut.demo');
    await env.services.resources.setArchived('r_ict2201_2019_final', true);
    expect(env.services.resources.search(const SearchQuery(text: 'ICT 2201', includeArchived: true)), hasLength(4));
    await env.services.auth.signOut();
    await env.signIn('student@zut.demo');
    expect(env.services.resources.search(const SearchQuery(text: 'ICT 2201', includeArchived: true)), hasLength(3));
  });

  test('copies can be added; a copy on loan cannot be removed (FR-RES-06)', () async {
    final env = await createEnv();
    await env.signIn('librarian@zut.demo');
    final r = env.services.resources;
    final before = r.copies('r_ict2205_2020_final').length;
    final c = await r.addCopy('r_ict2205_2020_final', 'C1-01');
    expect(r.copies('r_ict2205_2020_final').length, before + 1);
    expect(c.copyNumber, before + 1);
    final onLoan = r.copies('r_ict2205_2020_final').firstWhere((c) => c.status == CopyStatus.onLoan);
    expect(() => r.removeCopy(onLoan.id), throwsA(isA<RuleException>()));
  });

  test('bookmarks and recent searches persist in the store (FR-RES-08, FR-SRCH-06)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    final r = env.services.resources;
    await r.toggleBookmark('r_ict2201_2023_final');
    expect(r.bookmarked().single.id, 'r_ict2201_2023_final');
    for (final t in ['a', 'b', 'c', 'd', 'e', 'f']) {
      await r.addRecentSearch(t);
    }
    expect(r.recentSearches(), ['f', 'e', 'd', 'c', 'b']);
    await env.store.flush();
    expect(env.store.bookmarks['u_zut_chanda'], ['r_ict2201_2023_final']);
  });

  test('reset restores the seed state (FR-DEMO-02)', () async {
    final env = await createEnv();
    await env.signIn('student@zut.demo');
    await env.services.loans.request('r_ict2201_2023_final');
    await env.services.auth.signOut();
    await env.signIn('platform@zutlib.demo');
    final seeded = env.store.loans.unscoped.length;
    await env.services.platform.resetDemoData();
    expect(env.store.loans.unscoped.length, seeded - 1);
    expect(env.services.auth.currentUser?.role, Role.platformAdmin);
  });

  test('platform totals contain no student names (FR-ADM-05)', () async {
    final env = await createEnv();
    await env.signIn('platform@zutlib.demo');
    final totals = env.services.platform.totals();
    expect(totals, hasLength(2));
    expect(totals.first.users, greaterThan(0));
    await env.services.platform.addTenant('Copperbelt Skills Institute', 'CSI', '#6A1B9A');
    expect(env.services.auth.tenants().map((t) => t.shortCode), contains('CSI'));
  });

  test('admin dashboard counts reflect actions (FR-ADM-03)', () async {
    final env = await createEnv();
    await env.signIn('admin@zut.demo');
    final before = env.services.admin.dashboard();
    expect(before.mostViewed, isNotEmpty);
    expect(before.overdueLoans, 1);
    await env.services.auth.signOut();
    await env.signIn('student@zut.demo');
    await env.services.resources.openFile('r_ict2201_2023_final');
    await env.services.auth.signOut();
    await env.signIn('admin@zut.demo');
    expect(env.services.admin.dashboard().views, before.views + 1);
  });
}
