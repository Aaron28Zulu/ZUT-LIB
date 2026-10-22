import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zutlib/app.dart';
import 'package:zutlib/core/clock.dart';
import 'package:zutlib/data/storage.dart';
import 'package:zutlib/services/mock/mock_notification_service.dart';
import 'package:zutlib/state/app_state.dart';
import 'package:zutlib/screens/common/paper_details_screen.dart';
import 'package:zutlib/screens/student/home_tab.dart';
import 'package:zutlib/screens/student/study_tab.dart';
import 'package:zutlib/widgets/resource_tile.dart';

/// Clicks through each role's screens on a phone-sized surface. Any layout
/// overflow or exception fails the test (NFR-06 checks 1.3x text too).
Future<AppState> _pumpApp(WidgetTester tester, {double textScale = 1}) async {
  Clock.reset();
  tester.view.physicalSize = const Size(412 * 3, 915 * 3);
  tester.view.devicePixelRatio = 3;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final app = (await tester.runAsync(() => AppState.create(storage: MemoryStorage(), notifier: NoopDeviceNotifier())))!;
  await tester.pumpWidget(ChangeNotifierProvider.value(value: app, child: const ZutLibApp()));
  await tester.pumpAndSettle();
  return app;
}

/// The outermost list inside [of]; shelves add horizontal scrollables below it.
Finder _vertical([Finder? of]) =>
    (of == null ? find.byType(Scrollable) : find.descendant(of: of, matching: find.byType(Scrollable))).first;

Future<void> _signIn(WidgetTester tester, String institution, String quickLabel) async {
  if (find.text('Skip').evaluate().isNotEmpty) {
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
  }
  await tester.scrollUntilVisible(find.text(institution), 200, scrollable: _vertical());
  await tester.tap(find.text(institution));
  await tester.pumpAndSettle();
  final button = find.textContaining(quickLabel);
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> _visitDrawer(WidgetTester tester) async {
  final scaffold = tester.firstState<ScaffoldState>(find.byType(Scaffold));
  scaffold.openDrawer();
  await tester.pumpAndSettle();
  final tiles = find.descendant(of: find.byType(Drawer), matching: find.byType(ListTile));
  final count = tiles.evaluate().length - 1; // first tile is the account header
  Navigator.of(tester.element(find.byType(Drawer))).pop();
  await tester.pumpAndSettle();
  for (var i = 0; i < count; i++) {
    tester.firstState<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
    final dest = find.descendant(of: find.byType(Drawer), matching: find.byType(ListTile)).at(i + 1);
    await tester.ensureVisible(dest);
    await tester.tap(dest);
    await tester.pumpAndSettle();
  }
}

void main() {
  for (final scale in [1.0, 1.3]) {
    testWidgets('student screens render at ${scale}x text', (tester) async {
      await _pumpApp(tester, textScale: scale);
      await _signIn(tester, 'Zambia University College of Technology', 'Chanda Mwila');
      expect(find.text('Recommended for you'), findsOneWidget);

      for (final tab in ['Search', 'Study', 'Loans', 'Profile', 'Home']) {
        await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(tab)));
        await tester.pumpAndSettle();
      }

      // Paper details from a recommendation.
      await tester.scrollUntilVisible(find.text('Your loans'), 200, scrollable: _vertical(find.byType(HomeTab)));
      final card = find.byType(ResourceCard).first;
      await tester.ensureVisible(card);
      await tester.pumpAndSettle();
      await tester.tap(card);
      await tester.pumpAndSettle();
      final summary = find.text('About this paper');
      await tester.scrollUntilVisible(summary, 200, scrollable: _vertical(find.byType(PaperDetailsScreen)));
      expect(summary, findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Study hub screens.
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Study')));
      await tester.pumpAndSettle();
      for (final item in ['Practice quiz', 'Flashcards', 'Revision plan', 'Progress', 'Ask the assistant']) {
        // `.last`: the progress row above the tools also reads "Revision plan".
        final tool = find.descendant(of: find.byType(StudyTab), matching: find.text(item)).last;
        await tester.ensureVisible(tool);
        await tester.tap(tool);
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      // A full quiz. The tool list was scrolled down by the loop above.
      final quizTool = find.descendant(of: find.byType(StudyTab), matching: find.text('Practice quiz'));
      await tester.scrollUntilVisible(quizTool, -200, scrollable: _vertical(find.byType(StudyTab)));
      await tester.ensureVisible(quizTool);
      await tester.pumpAndSettle();
      await tester.tap(quizTool);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start quiz'));
      await tester.tap(find.text('Start quiz'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        final radios = find.byType(RadioListTile<String>);
        if (radios.evaluate().isNotEmpty) {
          await tester.tap(radios.first);
        } else {
          await tester.enterText(find.byType(TextField), 'answer');
        }
        await tester.pump();
        await tester.tap(find.text('Check answer'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining(i == 4 ? 'See results' : 'Next question'));
        await tester.pumpAndSettle();
      }
      expect(find.text('By topic'), findsOneWidget);
    });
  }

  testWidgets('first sign-in shows study profile setup (FR-AUTH-05)', (tester) async {
    await _pumpApp(tester);
    await _signIn(tester, 'Zambia University College of Technology', 'Natasha Banda');
    expect(find.text('Set up your studies'), findsOneWidget);
  });

  testWidgets('wrong password shows the SRS message (FR-AUTH-01)', (tester) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Northbridge Technical College'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'student@northbridge.demo');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect email or password'), findsOneWidget);
  });

  for (final (institution, account) in [
    ('Zambia University College of Technology', 'Mary Phiri'),
    ('Zambia University College of Technology', 'Joseph Tembo'),
    ('Platform administration', 'Platform Admin'),
  ]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('$account staff screens render at ${scale}x text', (tester) async {
        await _pumpApp(tester, textScale: scale);
        await _signIn(tester, institution, account);
        await _visitDrawer(tester);
      });
    }
  }
}
