/// Where the app keeps its data.
///
/// The SRS prototype runs offline on bundled seed data (FR-DEMO-01), so that
/// stays the default. Build with `--dart-define=BACKEND=firebase` to save the
/// same data to Cloud Firestore and offer Google sign-in.
enum Backend {
  offline('Offline (this device)'),
  firebase('Cloud (Firebase)');

  const Backend(this.label);

  final String label;

  static const current = String.fromEnvironment('BACKEND') == 'firebase'
      ? Backend.firebase
      : Backend.offline;
}
