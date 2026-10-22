import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/app_icons.dart';
import 'core/theme.dart';
import 'state/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Bundled fonts are OFL; their licences show on the About/licences page.
  LicenseRegistry.addLicense(() async* {
    for (final (pkg, file) in [('Inter', 'OFL-Inter.txt'), ('Source Serif 4', 'OFL-SourceSerif4.txt')]) {
      yield LicenseEntryWithLineBreaks([pkg], await rootBundle.loadString('assets/fonts/$file'));
    }
  });
  runApp(const BootApp());
}

/// Shows the splash screen while seed data loads (SRS 8: Splash).
class BootApp extends StatefulWidget {
  const BootApp({super.key});

  @override
  State<BootApp> createState() => _BootAppState();
}

class _BootAppState extends State<BootApp> {
  late final Future<AppState> _boot = AppState.create();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppState>(
      future: _boot,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return ChangeNotifierProvider.value(value: snapshot.data!, child: const ZutLibApp());
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          home: _Splash(error: snapshot.error),
        );
      },
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({this.error});

  final Object? error;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.library, size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: Space.l),
              Text('ZutLib', style: t.headlineMedium),
              const SizedBox(height: Space.s),
              Text('Past papers and study tools', style: t.bodyLarge),
              const SizedBox(height: Space.xl),
              if (error == null)
                const SizedBox(width: 160, child: LinearProgressIndicator())
              else
                Text('The demo data could not be loaded: $error', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
