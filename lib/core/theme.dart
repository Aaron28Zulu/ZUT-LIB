import 'package:flutter/material.dart';

// Design tokens and the ThemeData built from them (docs/DESIGN_CONVENTIONS.md).
// This is the only file allowed raw colours, radii and font sizes. Screens read
// roles from Theme.of(context).colorScheme, AppPalette.of(context) and the
// text theme, never literals.

/// Spacing scale (4 dp grid).
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

/// Corner radii. The look is flat: small radii on controls, none on panels.
class Radii {
  Radii._();
  static const control = 6.0;
  static const tag = 4.0;
  static const panel = 8.0;

  static const controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(control)));
  static const controlRadius = BorderRadius.all(Radius.circular(control));
  static const tagRadius = BorderRadius.all(Radius.circular(tag));
  static const panelRadius = BorderRadius.all(Radius.circular(panel));
}

/// Width breakpoints (Material 3 window size classes).
class Breakpoints {
  Breakpoints._();

  /// Below this: phone layout with a bottom bar or drawer.
  static const medium = 600.0;

  /// From here staff get a permanent side menu and the rail extends.
  static const expanded = 1000.0;

  /// Longest comfortable line length for reading pages.
  static const readable = 760.0;
}

/// Fixed sizes for the visual elements screens draw themselves.
class Sizes {
  Sizes._();
  static const thumbWidth = 64.0;
  static const thumbHeight = 80.0;
  static const shelfCardWidth = 200.0;
  static const shelfThumbHeight = 96.0;
  static const progressBar = 6.0;
  static const hairline = 1.0;
  static const sideMenu = 280.0;
  static const statusDot = 8.0;
}

class AppText {
  AppText._();

  /// Course codes and collection codes look like identifiers.
  static TextStyle code(BuildContext context) => Theme.of(context).textTheme.labelLarge!.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: 0.3,
        fontWeight: FontWeight.w600,
      );

  /// Small label above a group, like course platforms' section kickers.
  static TextStyle overline(BuildContext context) => Theme.of(context).textTheme.labelSmall!.copyWith(
        letterSpacing: 0.8,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  /// Muted secondary line.
  static TextStyle muted(BuildContext context) => Theme.of(context).textTheme.bodyMedium!.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );

  /// Large figures on dashboards and results.
  static TextStyle figure(BuildContext context) => Theme.of(context).textTheme.headlineMedium!.copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Course code printed on a paper thumbnail.
  static TextStyle thumb(BuildContext context, Color ink, {bool large = false}) =>
      Theme.of(context).textTheme.labelLarge!.copyWith(
            color: ink,
            fontSize: large ? 15 : 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            height: 1.15,
          );

  /// Initials on a tenant badge, scaled to the badge size.
  static TextStyle badge(Color ink, double size) =>
      TextStyle(fontFamily: _sans, color: ink, fontWeight: FontWeight.w700, fontSize: size * 0.32, letterSpacing: 0.2);
}

/// Semantic colours that ColorScheme has no role for. Each status pairs a
/// foreground with a pale background; neither is ever the only signal (a label
/// or icon always goes with it).
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.success,
    required this.successBg,
    required this.warning,
    required this.warningBg,
    required this.info,
    required this.infoBg,
    required this.danger,
    required this.dangerBg,
    required this.neutral,
    required this.neutralBg,
    required this.thumbInk,
    required this.onBrand,
    required this.thumbs,
  });

  final Color success, successBg, warning, warningBg, info, infoBg, danger, dangerBg, neutral, neutralBg;

  /// Text colour on paper thumbnails.
  final Color thumbInk;

  /// Text on a saturated colour such as a tenant badge or the QR panel.
  final Color onBrand;

  /// Flat tints for paper thumbnails, chosen per course so a shelf scans by colour
  /// as well as by code.
  final List<Color> thumbs;

  static AppPalette of(BuildContext context) {
    final ext = Theme.of(context).extension<AppPalette>();
    assert(ext != null, 'AppPalette missing. Build ThemeData with buildTheme().');
    return ext!;
  }

  Color thumbFor(String key) => thumbs[key.codeUnits.fold<int>(0, (a, b) => a + b) % thumbs.length];

  @override
  AppPalette copyWith({
    Color? success,
    Color? successBg,
    Color? warning,
    Color? warningBg,
    Color? info,
    Color? infoBg,
    Color? danger,
    Color? dangerBg,
    Color? neutral,
    Color? neutralBg,
    Color? thumbInk,
    Color? onBrand,
    List<Color>? thumbs,
  }) =>
      AppPalette(
        success: success ?? this.success,
        successBg: successBg ?? this.successBg,
        warning: warning ?? this.warning,
        warningBg: warningBg ?? this.warningBg,
        info: info ?? this.info,
        infoBg: infoBg ?? this.infoBg,
        danger: danger ?? this.danger,
        dangerBg: dangerBg ?? this.dangerBg,
        neutral: neutral ?? this.neutral,
        neutralBg: neutralBg ?? this.neutralBg,
        thumbInk: thumbInk ?? this.thumbInk,
        onBrand: onBrand ?? this.onBrand,
        thumbs: thumbs ?? this.thumbs,
      );

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      success: l(success, other.success),
      successBg: l(successBg, other.successBg),
      warning: l(warning, other.warning),
      warningBg: l(warningBg, other.warningBg),
      info: l(info, other.info),
      infoBg: l(infoBg, other.infoBg),
      danger: l(danger, other.danger),
      dangerBg: l(dangerBg, other.dangerBg),
      neutral: l(neutral, other.neutral),
      neutralBg: l(neutralBg, other.neutralBg),
      thumbInk: l(thumbInk, other.thumbInk),
      onBrand: l(onBrand, other.onBrand),
      // Lists of different tints do not interpolate meaningfully; snap halfway.
      thumbs: t < 0.5 ? thumbs : other.thumbs,
    );
  }
}

// Primitives. Blue is the single brand hue; everything else is neutral.
abstract final class _P {
  static const blue600 = Color(0xFF0B5CD5);
  static const blue700 = Color(0xFF0A4BAE);
  static const blue50 = Color(0xFFEAF1FD);
  static const blue900 = Color(0xFF0A2E66);
  static const blue300 = Color(0xFF8AB4F8);
  static const blue950 = Color(0xFF0B2552);
  static const blue800d = Color(0xFF1A3A6B);
  static const blue100d = Color(0xFFD7E5FD);

  static const ink = Color(0xFF1C1D1F);
  static const slate = Color(0xFF545B68);
  static const white = Color(0xFFFFFFFF);
  static const grey25 = Color(0xFFF7F8FA);
  static const grey50 = Color(0xFFF1F3F6);
  static const grey100 = Color(0xFFE9ECF0);
  static const grey150 = Color(0xFFE2E5EA);
  static const grey300 = Color(0xFFC6CBD3);

  static const night = Color(0xFF111317);
  static const night1 = Color(0xFF16191E);
  static const night2 = Color(0xFF1C2026);
  static const night3 = Color(0xFF23282F);
  static const night4 = Color(0xFF2A3038);
  static const nightLine = Color(0xFF2E343D);
  static const nightOutline = Color(0xFF4A515C);
  static const fog = Color(0xFFE7E9EC);
  static const fogMuted = Color(0xFFA6ADB8);

  static const green = Color(0xFF1C7A4B);
  static const greenBg = Color(0xFFE5F3EB);
  static const amber = Color(0xFF8F5B00);
  static const amberBg = Color(0xFFFBF0DA);
  static const red = Color(0xFFB3261E);
  static const redBg = Color(0xFFFCEAE8);

  static const greenD = Color(0xFF7FD3A4);
  static const greenBgD = Color(0xFF173726);
  static const amberD = Color(0xFFF0C46A);
  static const amberBgD = Color(0xFF3A2C0E);
  static const redD = Color(0xFFF2A39C);
  static const redBgD = Color(0xFF45201C);
}

const _lightPalette = AppPalette(
  success: _P.green,
  successBg: _P.greenBg,
  warning: _P.amber,
  warningBg: _P.amberBg,
  info: _P.blue700,
  infoBg: _P.blue50,
  danger: _P.red,
  dangerBg: _P.redBg,
  neutral: _P.slate,
  neutralBg: _P.grey50,
  thumbInk: _P.ink,
  onBrand: _P.white,
  thumbs: [
    Color(0xFFDCE8FB), // blue
    Color(0xFFE3E9F2), // slate
    Color(0xFFDDEFEA), // teal
    Color(0xFFEDE6F6), // violet
    Color(0xFFF6EBDD), // sand
  ],
);

const _darkPalette = AppPalette(
  success: _P.greenD,
  successBg: _P.greenBgD,
  warning: _P.amberD,
  warningBg: _P.amberBgD,
  info: _P.blue300,
  infoBg: _P.blue800d,
  danger: _P.redD,
  dangerBg: _P.redBgD,
  neutral: _P.fogMuted,
  neutralBg: _P.night3,
  thumbInk: _P.fog,
  onBrand: _P.white,
  thumbs: [
    Color(0xFF1D3150),
    Color(0xFF283140),
    Color(0xFF1C3631),
    Color(0xFF2E2742),
    Color(0xFF3A3024),
  ],
);

ColorScheme _scheme(Brightness b) => b == Brightness.light
    ? const ColorScheme(
        brightness: Brightness.light,
        primary: _P.blue600,
        onPrimary: _P.white,
        primaryContainer: _P.blue50,
        onPrimaryContainer: _P.blue900,
        secondary: _P.slate,
        onSecondary: _P.white,
        secondaryContainer: _P.grey50,
        onSecondaryContainer: _P.ink,
        tertiary: _P.green,
        onTertiary: _P.white,
        tertiaryContainer: _P.greenBg,
        onTertiaryContainer: Color(0xFF0E4A2C),
        error: _P.red,
        onError: _P.white,
        errorContainer: _P.redBg,
        onErrorContainer: Color(0xFF7A1A14),
        surface: _P.white,
        onSurface: _P.ink,
        onSurfaceVariant: _P.slate,
        surfaceContainerLowest: _P.white,
        surfaceContainerLow: _P.grey25,
        surfaceContainer: _P.grey50,
        surfaceContainerHigh: _P.grey100,
        surfaceContainerHighest: _P.grey150,
        outline: _P.grey300,
        outlineVariant: _P.grey150,
        inverseSurface: _P.ink,
        onInverseSurface: _P.white,
        inversePrimary: _P.blue300,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        surfaceTint: Color(0x00000000),
      )
    : const ColorScheme(
        brightness: Brightness.dark,
        primary: _P.blue300,
        onPrimary: _P.blue950,
        primaryContainer: _P.blue800d,
        onPrimaryContainer: _P.blue100d,
        secondary: _P.fogMuted,
        onSecondary: _P.night,
        secondaryContainer: _P.night3,
        onSecondaryContainer: _P.fog,
        tertiary: _P.greenD,
        onTertiary: Color(0xFF0B2A1A),
        tertiaryContainer: _P.greenBgD,
        onTertiaryContainer: Color(0xFFC6EED6),
        error: _P.redD,
        onError: Color(0xFF3B0D09),
        errorContainer: _P.redBgD,
        onErrorContainer: Color(0xFFFAD6D2),
        surface: _P.night,
        onSurface: _P.fog,
        onSurfaceVariant: _P.fogMuted,
        surfaceContainerLowest: _P.night,
        surfaceContainerLow: _P.night1,
        surfaceContainer: _P.night2,
        surfaceContainerHigh: _P.night3,
        surfaceContainerHighest: _P.night4,
        outline: _P.nightOutline,
        outlineVariant: _P.nightLine,
        inverseSurface: _P.fog,
        onInverseSurface: _P.night,
        inversePrimary: _P.blue600,
        shadow: Color(0xFF000000),
        scrim: Color(0xFF000000),
        surfaceTint: Color(0x00000000),
      );

const _sans = 'Inter';
const _serif = 'SourceSerif4';

TextTheme _textTheme(ColorScheme s) {
  TextStyle sans(double size, FontWeight w, {double height = 1.4, double spacing = 0}) => TextStyle(
        fontFamily: _sans,
        fontSize: size,
        fontWeight: w,
        height: height,
        letterSpacing: spacing,
        color: s.onSurface,
      );
  TextStyle serif(double size, FontWeight w, {double height = 1.25}) => TextStyle(
        fontFamily: _serif,
        fontSize: size,
        fontWeight: w,
        height: height,
        color: s.onSurface,
      );
  return TextTheme(
    displayLarge: serif(48, FontWeight.w600),
    displayMedium: serif(40, FontWeight.w600),
    displaySmall: serif(34, FontWeight.w600),
    headlineLarge: serif(30, FontWeight.w600),
    headlineMedium: serif(26, FontWeight.w600),
    headlineSmall: serif(22, FontWeight.w600),
    titleLarge: serif(20, FontWeight.w600),
    titleMedium: sans(16, FontWeight.w600, height: 1.35),
    titleSmall: sans(14, FontWeight.w600, height: 1.35),
    bodyLarge: sans(16, FontWeight.w400, height: 1.5),
    bodyMedium: sans(14, FontWeight.w400, height: 1.45),
    bodySmall: sans(12, FontWeight.w400, height: 1.4).copyWith(color: s.onSurfaceVariant),
    labelLarge: sans(14, FontWeight.w600, height: 1.2),
    labelMedium: sans(12, FontWeight.w600, height: 1.2),
    labelSmall: sans(11, FontWeight.w500, height: 1.2, spacing: 0.3),
  );
}

ThemeData buildTheme(Brightness brightness) {
  final s = _scheme(brightness);
  final t = _textTheme(s);
  final palette = brightness == Brightness.light ? _lightPalette : _darkPalette;
  final hairline = BorderSide(color: s.outlineVariant, width: Sizes.hairline);
  const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
  const buttonMinSize = Size(64, 48);
  OutlineInputBorder field(Color c, [double w = 1]) =>
      OutlineInputBorder(borderRadius: Radii.controlRadius, borderSide: BorderSide(color: c, width: w));

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: s,
    textTheme: t,
    fontFamily: _sans,
    fontFamilyFallback: const ['Roboto', 'sans-serif'],
    extensions: [palette],
    scaffoldBackgroundColor: s.surface,
    canvasColor: s.surface,
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: InkRipple.splashFactory,
    iconTheme: IconThemeData(size: 22, color: s.onSurfaceVariant),
    primaryIconTheme: IconThemeData(size: 22, color: s.primary),
    dividerTheme: DividerThemeData(space: 1, thickness: 1, color: s.outlineVariant),
    appBarTheme: AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: s.surface,
      foregroundColor: s.onSurface,
      surfaceTintColor: Colors.transparent,
      shape: Border(bottom: hairline),
      titleTextStyle: t.titleLarge,
      iconTheme: IconThemeData(size: 22, color: s.onSurface),
      actionsIconTheme: IconThemeData(size: 22, color: s.onSurface),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 68,
      elevation: 0,
      backgroundColor: s.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: s.primaryContainer,
      indicatorShape: Radii.controlShape,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (st) => IconThemeData(size: 22, color: st.contains(WidgetState.selected) ? s.primary : s.onSurfaceVariant),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (st) => t.labelMedium!.copyWith(
          color: st.contains(WidgetState.selected) ? s.primary : s.onSurfaceVariant,
          fontWeight: st.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: s.surface,
      elevation: 0,
      indicatorColor: s.primaryContainer,
      indicatorShape: Radii.controlShape,
      useIndicator: true,
      labelType: NavigationRailLabelType.all,
      selectedIconTheme: IconThemeData(size: 22, color: s.primary),
      unselectedIconTheme: IconThemeData(size: 22, color: s.onSurfaceVariant),
      selectedLabelTextStyle: t.labelMedium!.copyWith(color: s.primary, fontWeight: FontWeight.w700),
      unselectedLabelTextStyle: t.labelMedium!.copyWith(color: s.onSurfaceVariant, fontWeight: FontWeight.w500),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: s.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(),
      width: Sizes.sideMenu,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: s.surface,
      surfaceTintColor: Colors.transparent,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: Radii.panelRadius, side: hairline),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: Space.l),
      minVerticalPadding: 10,
      iconColor: s.onSurfaceVariant,
      titleTextStyle: t.bodyLarge!.copyWith(fontWeight: FontWeight.w500),
      subtitleTextStyle: t.bodyMedium!.copyWith(color: s.onSurfaceVariant),
      selectedColor: s.primary,
      selectedTileColor: s.primaryContainer,
      shape: const RoundedRectangleBorder(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: buttonMinSize,
        padding: buttonPadding,
        shape: Radii.controlShape,
        textStyle: t.labelLarge,
        elevation: 0,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: buttonMinSize,
        padding: buttonPadding,
        shape: Radii.controlShape,
        textStyle: t.labelLarge,
        elevation: 0,
        backgroundColor: s.primary,
        foregroundColor: s.onPrimary,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: buttonMinSize,
        padding: buttonPadding,
        shape: Radii.controlShape,
        textStyle: t.labelLarge,
        foregroundColor: s.onSurface,
        side: BorderSide(color: s.onSurface),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: Radii.controlShape,
        textStyle: t.labelLarge,
        foregroundColor: s.primary,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(minimumSize: const Size(48, 48), shape: Radii.controlShape),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      backgroundColor: s.primary,
      foregroundColor: s.onPrimary,
      shape: Radii.controlShape,
      extendedTextStyle: t.labelLarge,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        shape: Radii.controlShape,
        side: BorderSide(color: s.outline),
        selectedBackgroundColor: s.primaryContainer,
        selectedForegroundColor: s.onPrimaryContainer,
        textStyle: t.labelLarge,
        minimumSize: const Size(48, 44),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: const RoundedRectangleBorder(borderRadius: Radii.tagRadius),
      side: BorderSide(color: s.outline),
      backgroundColor: s.surface,
      selectedColor: s.primaryContainer,
      checkmarkColor: s.onPrimaryContainer,
      showCheckmark: false,
      labelStyle: t.labelLarge!.copyWith(fontWeight: FontWeight.w500),
      secondaryLabelStyle: t.labelLarge!.copyWith(color: s.onPrimaryContainer),
      padding: const EdgeInsets.symmetric(horizontal: Space.s, vertical: Space.xs),
      elevation: 0,
      pressElevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: field(s.outline),
      enabledBorder: field(s.outline),
      focusedBorder: field(s.primary, 2),
      errorBorder: field(s.error),
      focusedErrorBorder: field(s.error, 2),
      labelStyle: t.bodyLarge!.copyWith(color: s.onSurfaceVariant),
      floatingLabelStyle: t.bodyMedium!.copyWith(color: s.primary, fontWeight: FontWeight.w600),
      hintStyle: t.bodyLarge!.copyWith(color: s.onSurfaceVariant),
      helperStyle: t.bodySmall,
      errorStyle: t.bodySmall!.copyWith(color: s.error),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(s.surfaceContainer),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: const WidgetStatePropertyAll(Radii.controlShape),
      side: WidgetStatePropertyAll(BorderSide(color: s.outlineVariant)),
      constraints: const BoxConstraints(minHeight: 48),
      textStyle: WidgetStatePropertyAll(t.bodyLarge),
      hintStyle: WidgetStatePropertyAll(t.bodyLarge!.copyWith(color: s.onSurfaceVariant)),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: s.onSurface,
      unselectedLabelColor: s.onSurfaceVariant,
      labelStyle: t.labelLarge,
      unselectedLabelStyle: t.labelLarge!.copyWith(fontWeight: FontWeight.w500),
      indicatorColor: s.onSurface,
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: s.outlineVariant,
    ),
    checkboxTheme: CheckboxThemeData(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(3))),
      side: BorderSide(color: s.onSurfaceVariant, width: 1.5),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: s.primary,
      linearTrackColor: s.surfaceContainerHigh,
      circularTrackColor: Colors.transparent,
      linearMinHeight: Sizes.progressBar,
    ),
    sliderTheme: SliderThemeData(activeTrackColor: s.primary, inactiveTrackColor: s.surfaceContainerHigh),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: s.inverseSurface,
      contentTextStyle: t.bodyMedium!.copyWith(color: s.onInverseSurface),
      actionTextColor: s.inversePrimary,
      shape: Radii.controlShape,
    ),
    dialogTheme: DialogThemeData(
      elevation: 0,
      backgroundColor: s.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: Radii.panelRadius, side: hairline),
      titleTextStyle: t.titleLarge,
      contentTextStyle: t.bodyMedium,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      elevation: 0,
      backgroundColor: s.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.panel)),
        side: hairline,
      ),
    ),
    popupMenuTheme: PopupMenuThemeData(
      elevation: 2,
      color: s.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: Radii.panelRadius, side: hairline),
      textStyle: t.bodyMedium,
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        elevation: const WidgetStatePropertyAll(2),
        backgroundColor: WidgetStatePropertyAll(s.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: Radii.panelRadius, side: hairline)),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: t.bodyLarge,
      menuStyle: MenuStyle(
        elevation: const WidgetStatePropertyAll(2),
        backgroundColor: WidgetStatePropertyAll(s.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
    ),
    badgeTheme: BadgeThemeData(backgroundColor: s.error, textColor: s.onError, textStyle: t.labelSmall),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: s.inverseSurface, borderRadius: Radii.tagRadius),
      textStyle: t.bodySmall!.copyWith(color: s.onInverseSurface),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: s.onSurfaceVariant,
      collapsedIconColor: s.onSurfaceVariant,
    ),
  );
}
