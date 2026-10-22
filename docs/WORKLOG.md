# Work log

Shared hand-off log for agents and humans (see AGENTS.md, "How agents communicate").
Newest entry at the top. Keep entries short and factual.

## In progress

<!-- - `feature/fr-xxx-...` - who - requirement IDs - started YYYY-MM-DD -->

## Entries

### 2026-10-22 - cloud mode with Firestore and Google sign-in (Claude)

- Done: `--dart-define=BACKEND=firebase` build flag, Firestore-backed storage, Google
  sign-in through Firebase Auth, rules file, tests for the Google sign-in paths.
  `flutter analyze` clean, `flutter test` green, `flutter build web` compiles.
- Not verified yet: a real Firebase project. Needs `flutterfire configure` on the dev
  machine, then a cloud run on Android (SHA-1 registered) and web.
- Open: SRS-QUESTION in `mock_auth_service.dart` on Google accounts without a student
  number or department.

### 2026-10-22 - initial scaffold (Claude)

- Done: Flutter project, agent docs, mock backend behind service interfaces, seed
  generator with 20 sample papers, all SRS roles and screens, 63 passing tests
  (service layer coverage about 80%). Reviewed visually on a web build.
- Not verified yet: no Android build. The cloud workspace could not download the Android
  SDK, so the first `flutter run` / `flutter build apk` happens on a dev machine. Then
  work through `docs/DEMO_SCRIPT.md`, especially the camera scan (steps 6 and 7).
- Assumption: the 5-minute short inactivity timeout (FR-AUTH-07) is toggled from
  Platform admin > Demo controls.
- Next: push to GitHub (`Stella05lulu/zutlib-app`) once access is sorted.
