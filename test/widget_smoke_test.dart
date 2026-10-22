import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:zutlib/app.dart';
import 'package:zutlib/core/clock.dart';
import 'package:zutlib/data/storage.dart';
import 'package:zutlib/services/mock/mock_notification_service.dart';
import 'package:zutlib/state/app_state.dart';

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

Future<void> _signIn(WidgetTester tester, String institution, String quickLabel) async {
  if (find.text('Skip').evaluate().isNotEmpty) {
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
  }
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
      expect(find.text('Recommended papers'), findsOneWidget);

      for (final tab in ['Search', 'Study', 'Loans', 'Profile', 'Home']) {
        await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(tab)));
        await tester.pumpAndSettle();
      }

      // Paper details from a recommendation.
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Assistant summary'), 200);
      expect(find.text('Assistant summary'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Study hub screens.
      await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text('Study')));
      await tester.pumpAndSettle();
      for (final item in ['Practice quiz', 'Flashcards', 'Revision plan', 'Progress', 'Ask the assistant']) {
        await tester.tap(find.text(item).first);
        await tester.pumpAndSettle();
        await tester.pageBack();
        await tester.pumpAndSettle();
      }

      // A full quiz.
      await tester.tap(find.text('Practice quiz'));
      await tester.pumpAndSettle();
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
