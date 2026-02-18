import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SETTLE DESIGN SYSTEM — Single source of truth for colors, glass, typography,
// spacing, radii, gradients, and theme.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// COLORS
// ─────────────────────────────────────────────────────────────────────────────

class SettleColors {
  SettleColors._();

  // Light mode backgrounds
  static const Color cream = Color(0xFFFAFAF8);
  static const Color stone50 = Color(0xFFF5F4F2);
  static const Color stone100 = Color(0xFFECEAE6);
  static const Color stone200 = Color(0xFFDDDAD4);

  // Dark mode backgrounds
  static const Color night950 = Color(0xFF0A0D12);
  static const Color night900 = Color(0xFF0F1318);
  static const Color night800 = Color(0xFF161C24);
  static const Color night700 = Color(0xFF1E2630);

  // Text colors (light)
  static const Color ink900 = Color(0xFF1A1A1C);
  static const Color ink800 = Color(0xFF2C2C2E);
  static const Color ink700 = Color(0xFF3A3A3C);
  static const Color ink500 = Color(0xFF636366);
  static const Color ink400 = Color(0xFF8E8E93);
  static const Color ink300 = Color(0xFFAEAEB2);

  // Text colors (dark)
  static const Color nightText = Color(0xFFECEFF4);
  static const Color nightSoft = Color(0xFFB0B8C8);
  static const Color nightMuted = Color(0xFF6B7280);
  static const Color nightAccent = Color(0xFF88AACC);

  // Domain tints (desaturated — subtle)
  static const Color sage400 = Color(0xFF8BB89E);
  static const Color sage600 = Color(0xFF5A8A6E);
  static const Color sage100 = Color(0xFFE4EDE2);
  static const Color blush400 = Color(0xFFBE8B8B);
  static const Color blush600 = Color(0xFF946060);
  static const Color blush100 = Color(0xFFF0E4E4);
  static const Color dusk400 = Color(0xFF7B8FBE);
  static const Color dusk600 = Color(0xFF4A5F94);
  static const Color dusk100 = Color(0xFFE0E4F0);
  static const Color warmth400 = Color(0xFFBEA070);
  static const Color warmth600 = Color(0xFF8A7048);
  static const Color warmth100 = Color(0xFFF0E8DC);

  /// Wake-window arc "ok" zone (0–55% progress). Matches T.arc.ok.
  static const Color arcOk = Color(0xFF6EE7B7);
}

// ─────────────────────────────────────────────────────────────────────────────
// GLASS MATERIALS
// ─────────────────────────────────────────────────────────────────────────────

class SettleGlass {
  SettleGlass._();

  static const SettleGlassLight light = SettleGlassLight();
  static const SettleGlassDark dark = SettleGlassDark();
}

class SettleGlassLight {
  const SettleGlassLight();

  static const Color background = Color(0x7AFFFFFF); // white 48%
  static const Color backgroundStrong = Color(0x9EFFFFFF); // white 62%
  static const Color backgroundSubtle = Color(0x52FFFFFF); // white 32%
  static const Color border = Color(0x80FFFFFF); // white 50%
  static const Color borderStrong = Color(0xADFFFFFF); // white 68%
  static const double blur = 40.0;
  /// For shader if available; otherwise annotation only.
  static const double saturation = 1.8;
}

class SettleGlassDark {
  const SettleGlassDark();

  static const Color background = Color(0x0EFFFFFF); // white 5.5%
  static const Color backgroundStrong = Color(0x17FFFFFF); // white 9%
  static const Color border = Color(0x14FFFFFF); // white 8%
  static const Color borderStrong = Color(0x21FFFFFF); // white 13%
  static const double blur = 40.0;
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPOGRAPHY — Fraunces (display/emotional), Inter (UI/body)
// ─────────────────────────────────────────────────────────────────────────────

class SettleTypography {
  SettleTypography._();

  static const double displaySize = 28;
  static const double headingSize = 20;
  static const double bodySize = 14;
  static const double captionSize = 11.5;

  /// Moment / Reset / greetings — Fraunces, weight 400, letterSpacing -1.5
  static TextStyle get display => GoogleFonts.fraunces(
        fontSize: displaySize,
        fontWeight: FontWeight.w400,
        letterSpacing: -1.5,
      );

  /// Headings — Inter, weight 600, letterSpacing -0.3
  static TextStyle get heading => GoogleFonts.inter(
        fontSize: headingSize,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      );

  /// Body — Inter, weight 400, letterSpacing -0.1
  static TextStyle get body => GoogleFonts.inter(
        fontSize: bodySize,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.1,
      );

  /// Caption — Inter, weight 500, letterSpacing 0.2
  static TextStyle get caption => GoogleFonts.inter(
        fontSize: captionSize,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.2,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SPACING
// ─────────────────────────────────────────────────────────────────────────────

class SettleSpacing {
  SettleSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 28;
  static const double cardPadding = 20;
  static const double screenPadding = 18;
  static const double cardGap = 8;
  static const double sectionGap = 20;
}

// ─────────────────────────────────────────────────────────────────────────────
// RADII
// ─────────────────────────────────────────────────────────────────────────────

class SettleRadii {
  SettleRadii._();

  static const double glass = 20;
  static const double pill = 100;
  static const double sm = 14;
  static const double card = 26;
}

// ─────────────────────────────────────────────────────────────────────────────
// GRADIENTS — backgrounds that show through glass
// ─────────────────────────────────────────────────────────────────────────────

class SettleGradients {
  SettleGradients._();

  static const Alignment begin = Alignment.topCenter;
  static const Alignment end = Alignment.bottomCenter;

  static const LinearGradient home = LinearGradient(
    begin: begin,
    end: end,
    colors: [
      Color(0xFFC8D8E8),
      Color(0xFFE0D8CC),
      Color(0xFFD4DED0),
      Color(0xFFE4DED6),
    ],
  );

  static const LinearGradient moment = LinearGradient(
    begin: begin,
    end: end,
    colors: [
      Color(0xFF90B8A4),
      Color(0xFFA8D0B8),
      Color(0xFFC4DED0),
      Color(0xFFE4F0E8),
    ],
  );

  static const LinearGradient sleep = LinearGradient(
    begin: begin,
    end: end,
    colors: [
      Color(0xFF1A2544),
      Color(0xFF253660),
      Color(0xFF344880),
      Color(0xFF4A6090),
    ],
  );

  static const LinearGradient resetDark = LinearGradient(
    begin: begin,
    end: end,
    colors: [
      Color(0xFF0A0D12),
      Color(0xFF0F1318),
      Color(0xFF161C24),
    ],
  );

  static const LinearGradient playbook = LinearGradient(
    begin: begin,
    end: end,
    colors: [
      Color(0xFFE6E2DC),
      Color(0xFFEDEBE6),
      Color(0xFFE8E4DE),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME — light / dark ThemeData, system brightness
// ─────────────────────────────────────────────────────────────────────────────

class SettleTheme {
  SettleTheme._();

  static ThemeData get light => _buildLight();
  static ThemeData get dark => _buildDark();

  static ThemeData _buildLight() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = _buildLightTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: SettleColors.stone50,
      colorScheme: ColorScheme.light(
        primary: SettleColors.sage600,
        secondary: SettleColors.dusk600,
        surface: SettleColors.stone50,
        error: SettleColors.blush600,
        onPrimary: SettleColors.cream,
        onSecondary: SettleColors.cream,
        onSurface: SettleColors.ink900,
        onError: SettleColors.cream,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: SettleTypography.heading.copyWith(color: SettleColors.ink900),
        iconTheme: const IconThemeData(color: SettleColors.ink700),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SettleColors.sage600,
          foregroundColor: SettleColors.cream,
          textStyle: SettleTypography.body,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SettleRadii.pill),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: SettleSpacing.xxl,
            vertical: SettleSpacing.lg,
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SettleColors.ink700,
          textStyle: SettleTypography.body,
          padding: const EdgeInsets.symmetric(
            horizontal: SettleSpacing.lg,
            vertical: SettleSpacing.sm,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: SettleColors.ink700),
      ),
      dividerTheme: DividerThemeData(
        color: SettleColors.ink400.withValues(alpha: 0.3),
        thickness: 0.5,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      splashColor: SettleColors.sage400.withValues(alpha: 0.12),
      highlightColor: SettleColors.sage400.withValues(alpha: 0.06),
    );
  }

  static ThemeData _buildDark() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = _buildDarkTextTheme(base.textTheme);

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: SettleColors.night900,
      colorScheme: ColorScheme.dark(
        primary: SettleColors.nightAccent,
        secondary: SettleColors.sage400,
        surface: SettleColors.night900,
        error: SettleColors.blush400,
        onPrimary: SettleColors.night950,
        onSecondary: SettleColors.night950,
        onSurface: SettleColors.nightText,
        onError: SettleColors.night950,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: SettleTypography.heading.copyWith(color: SettleColors.nightText),
        iconTheme: const IconThemeData(color: SettleColors.nightSoft),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: SettleColors.nightAccent,
          foregroundColor: SettleColors.night950,
          textStyle: SettleTypography.body,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(SettleRadii.pill),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: SettleSpacing.xxl,
            vertical: SettleSpacing.lg,
          ),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SettleColors.nightSoft,
          textStyle: SettleTypography.body,
          padding: const EdgeInsets.symmetric(
            horizontal: SettleSpacing.lg,
            vertical: SettleSpacing.sm,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: SettleColors.nightSoft),
      ),
      dividerTheme: DividerThemeData(
        color: SettleColors.nightMuted.withValues(alpha: 0.4),
        thickness: 0.5,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
      splashColor: SettleColors.nightAccent.withValues(alpha: 0.12),
      highlightColor: SettleColors.nightAccent.withValues(alpha: 0.06),
    );
  }

  static TextTheme _buildLightTextTheme(TextTheme base) {
    return TextTheme(
      displayLarge: SettleTypography.display.copyWith(color: SettleColors.ink900),
      displayMedium: SettleTypography.display.copyWith(color: SettleColors.ink900),
      displaySmall: SettleTypography.display.copyWith(color: SettleColors.ink900),
      headlineLarge: SettleTypography.heading.copyWith(color: SettleColors.ink900),
      headlineMedium: SettleTypography.heading.copyWith(color: SettleColors.ink900),
      headlineSmall: SettleTypography.heading.copyWith(color: SettleColors.ink900),
      titleLarge: SettleTypography.heading.copyWith(color: SettleColors.ink800),
      titleMedium: SettleTypography.body.copyWith(color: SettleColors.ink800),
      titleSmall: SettleTypography.body.copyWith(color: SettleColors.ink700),
      bodyLarge: SettleTypography.body.copyWith(color: SettleColors.ink800),
      bodyMedium: SettleTypography.body.copyWith(color: SettleColors.ink700),
      bodySmall: SettleTypography.caption.copyWith(color: SettleColors.ink500),
      labelLarge: SettleTypography.body.copyWith(color: SettleColors.ink700),
      labelMedium: SettleTypography.caption.copyWith(color: SettleColors.ink500),
      labelSmall: SettleTypography.caption.copyWith(color: SettleColors.ink400),
    );
  }

  static TextTheme _buildDarkTextTheme(TextTheme base) {
    return TextTheme(
      displayLarge: SettleTypography.display.copyWith(color: SettleColors.nightText),
      displayMedium: SettleTypography.display.copyWith(color: SettleColors.nightText),
      displaySmall: SettleTypography.display.copyWith(color: SettleColors.nightText),
      headlineLarge: SettleTypography.heading.copyWith(color: SettleColors.nightText),
      headlineMedium: SettleTypography.heading.copyWith(color: SettleColors.nightText),
      headlineSmall: SettleTypography.heading.copyWith(color: SettleColors.nightText),
      titleLarge: SettleTypography.heading.copyWith(color: SettleColors.nightText),
      titleMedium: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
      titleSmall: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
      bodyLarge: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
      bodyMedium: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
      bodySmall: SettleTypography.caption.copyWith(color: SettleColors.nightMuted),
      labelLarge: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
      labelMedium: SettleTypography.caption.copyWith(color: SettleColors.nightMuted),
      labelSmall: SettleTypography.caption.copyWith(color: SettleColors.nightMuted),
    );
  }
}
