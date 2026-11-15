import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- Brand palette --------------------------------------------------
  // Dark-first: the app now defaults to this navy/blue/purple system
  // everywhere, with light mode as a secondary variant of the same
  // accents rather than the primary experience.
  static const Color background = Color(0xFF0B1230);
  static const Color surface = Color(0xFF131C3F);
  static const Color surface2 = Color(0xFF1A2550);
  static const Color border = Color(0xFF26336A);
  static const Color textColor = Color(0xFFF3F5FF);
  static const Color mutedText = Color(0xFFA6B0D8);

  static const Color primary = Color(0xFF3366FF);
  static const Color primaryLight = Color(0xFF7FA2FF);
  static const Color cyan = Color(0xFF22C3F0);
  static const Color aiPurple = Color(0xFF9D7BFA);
  static const Color successColor = Color(0xFF34D399);
  static const Color warningColor = Color(0xFFFBBF24);
  static const Color dangerColor = Color(0xFFF87171);

  // AI-generated content cards: tinted dark purple with a purple border,
  // distinct from ordinary surfaces so AI output is always recognizable.
  static const Color aiCardBg = Color(0xFF171348);
  static const Color aiCardBorder = Color(0xFF43358A);

  // --- Back-compat aliases --------------------------------------------
  // Existing screens reference these names directly (splash/login
  // gradients, feature-card accents, etc). Re-pointing the values here
  // means those screens pick up the new brand without per-file edits.
  static const Color navy = primary;
  static const Color navyLight = primaryLight;
  static const Color navyDark = background;

  static const Color aura = aiPurple;
  static const Color auraLight = Color(0xFFC9B8FF);
  static const Color auraCore = Color(0xFFEDE8FF);

  static const RadialGradient auraGlow = RadialGradient(
    colors: [auraCore, auraLight, aura],
    stops: [0, 0.45, 1],
  );

  static const Color blue = cyan;
  static const Color green = successColor;
  static const Color amber = warningColor;
  static const Color red = dangerColor;
  static const Color success = successColor;
  static const Color warning = warningColor;
  static const Color error = dangerColor;

  // Neutral colors used by the (secondary) light theme.
  static const Color dark = Color(0xFF1F2937);
  static const Color grey = Color(0xFF6B7280);
  static const Color light = Color(0xFFEEF1FC);
  static const Color white = Color(0xFFFFFFFF);

  // Gradients
  static const LinearGradient navyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, navyLight],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navyDark, navy, navyLight],
  );

  // --- Typography -------------------------------------------------------
  // Outfit for display/headings (distinctive, geometric), Inter for
  // body/labels (clean, highly legible at small sizes).
  static TextStyle get _display => GoogleFonts.outfit();
  static TextStyle get _body => GoogleFonts.inter();

  static TextTheme get textTheme => TextTheme(
    displayLarge: _display,
    displayMedium: _display,
    displaySmall: _display,
    headlineLarge: _display,
    headlineMedium: _display,
    headlineSmall: _display,
    titleLarge: _display,
    titleMedium: _display,
    titleSmall: _display,
    bodyLarge: _body,
    bodyMedium: _body,
    bodySmall: _body,
    labelLarge: _body,
    labelMedium: _body,
    labelSmall: _body,
  );

  // Text Styles
  static TextStyle get headingLarge => _display.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: dark,
  );

  static TextStyle get headingMedium => _display.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: dark,
  );

  static TextStyle get headingSmall => _display.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: dark,
  );

  static TextStyle get bodyLarge => _body.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: dark,
  );

  static TextStyle get bodyMedium => _body.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: dark,
  );

  static TextStyle get bodySmall => _body.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: grey,
  );

  static TextStyle get labelLarge => _body.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: dark,
  );

  // Border Radius — cards 18, buttons/inputs 14, chips fully rounded.
  static const double radiusSmall = 10;
  static const double radiusMedium = 14;
  static const double radiusLarge = 18;
  static const double radiusXLarge = 24;

  // Spacing grid (base 4; screen padding 20; card gap 12-14).
  static const double spacingXSmall = 4;
  static const double spacingSmall = 8;
  static const double spacingMedium = 12;
  static const double spacingLarge = 16;
  static const double spacingXLarge = 20;
  static const double spacing2XLarge = 24;
  static const double spacing3XLarge = 32;

  static const double controlHeight = 52;
  static const double iconTileSize = 40;
  static const double chipHeight = 28;

  // Shadows
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> shadowLarge = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 8)),
  ];

  static final OutlineInputBorder _lightInputBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(radiusMedium),
    borderSide: const BorderSide(color: light),
  );

  static final RoundedRectangleBorder _buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(radiusMedium),
  );

  // ThemeData — light (secondary variant, same accents on light surfaces)
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: navy,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: white,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: white,
      elevation: 0,
      iconTheme: const IconThemeData(color: dark),
      titleTextStyle: headingSmall,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: light,
      border: _lightInputBorder,
      enabledBorder: _lightInputBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: navy, width: 1.5),
      ),
      labelStyle: const TextStyle(color: grey),
      hintStyle: const TextStyle(color: grey),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMedium,
        vertical: spacingMedium,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: navy,
        foregroundColor: white,
        minimumSize: const Size.fromHeight(controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: spacingLarge),
        shape: _buttonShape,
        textStyle: _body.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: navy,
        side: const BorderSide(color: navy),
        minimumSize: const Size.fromHeight(controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: spacingLarge),
        shape: _buttonShape,
        textStyle: _body.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: navy,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingSmall,
        ),
        textStyle: _body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
      ),
      color: white,
      surfaceTintColor: navy,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: light,
      selectedColor: navy,
      labelStyle: _body.copyWith(color: dark),
      showCheckmark: true,
      shape: const StadiumBorder(),
    ),
  );

  // ThemeData — dark (the primary, default brand experience)
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: background,
    textTheme: textTheme
        .apply(bodyColor: textColor, displayColor: textColor)
        .copyWith(bodySmall: _body.copyWith(fontSize: 12, color: mutedText)),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      iconTheme: const IconThemeData(color: textColor),
      titleTextStyle: _display.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
        borderSide: const BorderSide(color: primaryLight, width: 1.5),
      ),
      labelStyle: const TextStyle(color: mutedText),
      hintStyle: const TextStyle(color: mutedText),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacingMedium,
        vertical: spacingMedium,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: white,
        minimumSize: const Size.fromHeight(controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: spacingLarge),
        shape: _buttonShape,
        textStyle: _body.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: border),
        minimumSize: const Size.fromHeight(controlHeight),
        padding: const EdgeInsets.symmetric(horizontal: spacingLarge),
        shape: _buttonShape,
        textStyle: _body.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLight,
        padding: const EdgeInsets.symmetric(
          horizontal: spacingMedium,
          vertical: spacingSmall,
        ),
        textStyle: _body.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusLarge),
        side: const BorderSide(color: border),
      ),
      color: surface,
      surfaceTintColor: primary,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: border,
      selectedColor: primary,
      labelStyle: _body.copyWith(color: textColor),
      showCheckmark: true,
      shape: const StadiumBorder(),
    ),
    dividerColor: border,
  );
}
