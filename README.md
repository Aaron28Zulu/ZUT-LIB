# ZutLib

Past papers, library loans and study help for university students, built from the
ZutLib SRS. One app serves several institutions (tenants), with four roles: student,
librarian, institution admin and platform admin.

The backend is mocked behind service interfaces and runs fully offline from bundled
seed data, so the app can be demonstrated without any cloud account.

## Stack

- Flutter (Dart 3), Material 3
- `provider` for state, `shared_preferences` for local persistence
- `pdfx` for the PDF viewer, `qr_flutter` and `mobile_scanner` for loan codes
- `flutter_local_notifications` for device notifications, `fl_chart` for progress charts

Android is the primary target (minSdk 26). Web builds work for quick reviews.

## Getting started

1. Install Android Studio with the Android SDK, and the Flutter SDK (3.47 or newer, which ships Dart 3.13).
2. In Android Studio install the Flutter and Dart plugins, then open this folder.
3. Run once from a terminal in this folder:

   ```sh
   flutter doctor --android-licenses
   flutter pub get
   ```

4. Start an emulator (Device Manager, API 34 or newer is fine) or plug in a phone with
   USB debugging, then:

   ```sh
   flutter run
   ```

5. Build an installable APK:

   ```sh
   flutter build apk --release
   ```

   The file lands in `build/app/outputs/flutter-apk/app-release.apk`.

The QR scanner needs a real camera. On the emulator, use the six-character code shown
under the student's QR instead.

## Demo accounts

Every account uses the password `demo1234`. The sign-in screen also has quick demo
sign-in buttons.

| Institution | Role | Email |
| --- | --- | --- |
| Zambia University College of Technology | Student | student@zut.demo |
| Zambia University College of Technology | Librarian | librarian@zut.demo |
| Zambia University College of Technology | Institution admin | admin@zut.demo |
| Northbridge Technical College | Student | student@northbridge.demo |
| Northbridge Technical College | Librarian | librarian@northbridge.demo |
| Platform administration | Platform admin | platform@zutlib.demo |

Platform admin can move the demo clock forward and reset all demo data from
**Demo controls**. Walk through [docs/DEMO_SCRIPT.md](docs/DEMO_SCRIPT.md) before a
presentation.

## Commands

```sh
flutter analyze                 # lints, must be clean
flutter test                    # unit and widget tests
flutter test --coverage         # coverage report in coverage/lcov.info
python3 tools/generate_seed.py  # regenerate assets/seed and assets/papers
```

Seed data is generated. Edit `tools/seed_content.py` or `tools/generate_seed.py`, never
the JSON files directly. The generator needs Python 3 and `reportlab`.

## Project docs

- [AGENTS.md](AGENTS.md): rules for anyone (human or AI) changing the code
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): layers, data flow, swapping mocks for Firebase
- [docs/DESIGN_CONVENTIONS.md](docs/DESIGN_CONVENTIONS.md) and [docs/ANTI_SLOP.md](docs/ANTI_SLOP.md): UI rules
- [docs/GIT_WORKFLOW.md](docs/GIT_WORKFLOW.md) and [docs/COMMITS.md](docs/COMMITS.md): branching and commit messages
- [docs/WORKLOG.md](docs/WORKLOG.md): hand-off log

Enable the commit message check once per clone:

```sh
git config core.hooksPath tools
```
