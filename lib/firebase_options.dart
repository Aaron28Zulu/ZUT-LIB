// Placeholder so the app compiles before Firebase is set up.
// `flutterfire configure` overwrites this file with the project's real keys
// (see the setup steps in docs/ARCHITECTURE.md, "Cloud mode").

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => throw UnsupportedError(
    'Firebase is not configured yet. Run `flutterfire configure`, then build with --dart-define=BACKEND=firebase.',
  );
}
