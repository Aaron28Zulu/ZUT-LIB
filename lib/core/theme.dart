import 'package:flutter/material.dart';

/// Spacing scale from docs/DESIGN_CONVENTIONS.md (4 dp grid).
class Space {
  Space._();
  static const xs = 4.0;
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  static const screen = EdgeInsets.symmetric(horizontal: l);
}

class AppText {
  AppText._();

  /// Course codes and collection codes look like identifiers.
  static TextStyle code(BuildContext context) =>
      Theme.of(context).textTheme.labelLarge!.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            letterSpacing: 0.4,
          );

  static TextStyle overline(BuildContext context) =>
      Theme.of(context).textTheme.labelSmall!.copyWith(
            letterSpacing: 0.8,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          );
}

const defaultSeed = Color(0xFF1B5E20);

ThemeData buildTheme(Color seed, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.symmetric(horizontal: Space.l)),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    dividerTheme: const DividerThemeData(space: 1),
  );
}
