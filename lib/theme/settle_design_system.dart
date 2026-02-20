import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SETTLE DESIGN SYSTEM — "The Quiet Hand"
// Solid surfaces, typography-forward, minimal chrome.
// The words are the interface.
// ─────────────────────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────────────────────
// COLORS — Strong contrast, WCAG-friendly
// ─────────────────────────────────────────────────────────────────────────────

class SettleColors {
  SettleColors._();

  // Light backgrounds — warm off-white
  static const Color cream = Color(0xFFFFFBF7);
  static const Color stone50 = Color(0xFFF5F3F0);
  static const Color stone100 = Color(0xFFEBE8E4);
  static const Color stone200 = Color(0xFFDDD9D4);

  // Dark backgrounds
  static const Color night950 = Color(0xFF0C0E12);
  static const Color night900 = Color(0xFF12161C);
  static const Color night800 = Color(0xFF1A1F28);
  static const Color night700 = Color(0xFF242B36);

  // Light mode text — dark for readability
  static const Color ink900 = Color(0xFF0F1114);
  static const Color ink800 = Color(0xFF1C1E22);
  static const Color ink700 = Color(0xFF2D3036);
  static const Color ink600 = Color(0xFF45494F);
  static const Color ink500 = Color(0xFF5C6066);
  static const Color ink400 = Color(0xFF73787F);
  static const Color ink300 = Color(0xFF8E9299);

  // Dark mode text
  static const Color nightText = Color(0xFFF0F2F5);
  static const Color nightSoft = Color(0xFFC2C8D0);
  static const Color nightMuted = Color(0xFF88909C);
  static const Color nightAccent = Color(0xFF7BA3C7);

  // Primary accent (one clear CTA color)
  static const Color sage400 = Color(0xFF5B9B7A);
  static const Color sage600 = Color(0xFF3D7A5A);
  static const Color sage100 = Color(0xFFE2EDE6);
  static const Color blush400 = Color(0xFFC07878);
  static const Color blush600 = Color(0xFFA05A5A);
  static const Color blush100 = Color(0xFFF2E6E6);
  static const Color dusk400 = Color(0xFF6B8AB8);
  static const Color dusk600 = Color(0xFF4A6A96);
  static const Color dusk100 = Color(0xFFE2E8F2);
  static const Color warmth400 = Color(0xFFB8926A);
  static const Color warmth600 = Color(0xFF96704A);
  static const Color warmth100 = Color(0xFFF0E8DC);

  // Arcs
  static const Color arcOk = Color(0xFF6BA881);
  static const Color arcWatch = Color(0xFFC9A055);
  static const Color arcSoon = Color(0xFFB87D4A);
  static const Color arcNow = Color(0xFFA66B4A);
  static const Color arcCritical = Color(0xFFB85A5A);

  static Color arcForProgress(double p) {
    if (p < 0.55) return arcOk;
    if (p < 0.75) return arcWatch;
    if (p < 0.90) return arcSoon;
    return arcNow;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SURFACES — Solid card fills, borders, tints
// ─────────────────────────────────────────────────────────────────────────────

class SettleSurfaces {
  SettleSurfaces._();

  // Card fills
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF242B36); // night700

  // Card borders (dark only — light cards have no border)
  static const Color cardBorderDark = Color(0x14FFFFFF); // white 8%

  // Semantic tints (~6% over white/dark)
  static const Color tintSage = Color(0x0F5B9B7A);
  static const Color tintBlush = Color(0x0FC07878);
  static const Color tintDusk = Color(0x0F6B8AB8);
  static const Color tintWarmth = Color(0x0FB8926A);
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPOGRAPHY — DM Sans: warm, readable, calm. Clear hierarchy, generous line height.
// ─────────────────────────────────────────────────────────────────────────────

class SettleTypography {
  SettleTypography._();

  static const double displayLargeSize = 34;
  static const double displaySize = 26;
  static const double headingSize = 20;
  static const double subheadingSize = 17;
  static const double bodySize = 16;
  static const double captionSize = 14;
  static const double overlineSize = 11;

  static TextStyle get displayLarge => GoogleFonts.dmSans(
    fontSize: displayLargeSize,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.6,
    height: 1.18,
  );

  static TextStyle get display => GoogleFonts.dmSans(
    fontSize: displaySize,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    height: 1.24,
  );

  static TextStyle get heading => GoogleFonts.dmSans(
    fontSize: headingSize,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.3,
  );

  static TextStyle get subheading => GoogleFonts.dmSans(
    fontSize: subheadingSize,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
    height: 1.35,
  );

  static TextStyle get body => GoogleFonts.dmSans(
    fontSize: bodySize,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.55,
  );

  static TextStyle get label => GoogleFonts.dmSans(
    fontSize: bodySize,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.35,
  );

  static TextStyle get caption => GoogleFonts.dmSans(
    fontSize: captionSize,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.04,
    height: 1.42,
  );

  static TextStyle get overline => GoogleFonts.dmSans(
    fontSize: overlineSize,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
    height: 1.25,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SPACING
// ─────────────────────────────────────────────────────────────────────────────

class SettleSpacing {
  SettleSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double cardPadding = 20;
  static const double screenPadding = 20;
  static const double cardGap = 10;
  static const double sectionGap = 24;
}

// ─────────────────────────────────────────────────────────────────────────────
// RADII
// ─────────────────────────────────────────────────────────────────────────────

class SettleRadii {
  SettleRadii._();

  static const double surface = 16;
  /// Alias for [surface]. Kept for backward compatibility.
  static const double glass = surface;
  static const double pill = 999;
  static const double sm = 12;
  static const double card = 20;
}

// ─────────────────────────────────────────────────────────────────────────────
// LEGACY GRADIENTS — Kept for backward compatibility. All now resolve to solid.
// TODO: Remove once all direct references are migrated.
// ─────────────────────────────────────────────────────────────────────────────

class SettleGradients {
  SettleGradients._();

  static const Alignment begin = Alignment.topCenter;
  static const Alignment end = Alignment.bottomCenter;

  static final LinearGradient home = _solid(SettleColors.stone50);
  static final LinearGradient moment = _solid(SettleColors.night900);
  static final LinearGradient sleep = _solid(SettleColors.night900);
  static final LinearGradient resetDark = _solid(SettleColors.night900);
  static final LinearGradient playbook = _solid(SettleColors.stone50);
  static final LinearGradient library = _solid(SettleColors.stone50);

  static LinearGradient _solid(Color c) =>
      LinearGradient(colors: [c, c]);
}

// ─────────────────────────────────────────────────────────────────────────────
// THEME
// ─────────────────────────────────────────────────────────────────────────────

class SettleTheme {
  SettleTheme._();

  static ThemeData get light => _buildLight();
  static ThemeData get dark => _buildDark();

  static ThemeData _buildLight() {
    final textTheme = _buildLightTextTheme(ThemeData.light().textTheme);
    return ThemeData.light(useMaterial3: true).copyWith(
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
          textStyle: SettleTypography.label,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SettleRadii.pill)),
          padding: const EdgeInsets.symmetric(horizontal: SettleSpacing.xxl, vertical: SettleSpacing.lg),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SettleColors.ink700,
          textStyle: SettleTypography.body,
          padding: const EdgeInsets.symmetric(horizontal: SettleSpacing.lg, vertical: SettleSpacing.sm),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: SettleColors.ink700),
      ),
      dividerTheme: DividerThemeData(
        color: SettleColors.ink400.withValues(alpha: 0.35),
        thickness: 0.5,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: const _SettlePageTransitionsBuilder(),
          TargetPlatform.android: const _SettlePageTransitionsBuilder(),
        },
      ),
      splashColor: SettleColors.sage400.withValues(alpha: 0.15),
      highlightColor: SettleColors.sage400.withValues(alpha: 0.08),
    );
  }

  static ThemeData _buildDark() {
    final textTheme = _buildDarkTextTheme(ThemeData.dark().textTheme);
    return ThemeData.dark(useMaterial3: true).copyWith(
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
          textStyle: SettleTypography.label,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(SettleRadii.pill)),
          padding: const EdgeInsets.symmetric(horizontal: SettleSpacing.xxl, vertical: SettleSpacing.lg),
          elevation: 0,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: SettleColors.nightSoft,
          textStyle: SettleTypography.body,
          padding: const EdgeInsets.symmetric(horizontal: SettleSpacing.lg, vertical: SettleSpacing.sm),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: SettleColors.nightSoft),
      ),
      dividerTheme: DividerThemeData(
        color: SettleColors.nightMuted.withValues(alpha: 0.5),
        thickness: 0.5,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: const _SettlePageTransitionsBuilder(),
          TargetPlatform.android: const _SettlePageTransitionsBuilder(),
        },
      ),
      splashColor: SettleColors.nightAccent.withValues(alpha: 0.15),
      highlightColor: SettleColors.nightAccent.withValues(alpha: 0.08),
    );
  }

  static TextTheme _buildLightTextTheme(TextTheme base) {
    return TextTheme(
      displayLarge: SettleTypography.displayLarge.copyWith(color: SettleColors.ink900),
      displayMedium: SettleTypography.display.copyWith(color: SettleColors.ink900),
      displaySmall: SettleTypography.display.copyWith(color: SettleColors.ink900),
      headlineLarge: SettleTypography.heading.copyWith(color: SettleColors.ink900),
      headlineMedium: SettleTypography.heading.copyWith(color: SettleColors.ink900),
      headlineSmall: SettleTypography.subheading.copyWith(color: SettleColors.ink900),
      titleLarge: SettleTypography.subheading.copyWith(color: SettleColors.ink800),
      titleMedium: SettleTypography.label.copyWith(color: SettleColors.ink800),
      titleSmall: SettleTypography.body.copyWith(color: SettleColors.ink700),
      bodyLarge: SettleTypography.body.copyWith(color: SettleColors.ink800),
      bodyMedium: SettleTypography.body.copyWith(color: SettleColors.ink700),
      bodySmall: SettleTypography.caption.copyWith(color: SettleColors.ink600),
      labelLarge: SettleTypography.label.copyWith(color: SettleColors.ink700),
      labelMedium: SettleTypography.caption.copyWith(color: SettleColors.ink600),
      labelSmall: SettleTypography.caption.copyWith(color: SettleColors.ink500),
    );
  }

  static TextTheme _buildDarkTextTheme(TextTheme base) {
    return TextTheme(
      displayLarge: SettleTypography.displayLarge.copyWith(color: SettleColors.nightText),
      displayMedium: SettleTypography.display.copyWith(color: SettleColors.nightText),
      displaySmall: SettleTypography.display.copyWith(color: SettleColors.nightText),
      headlineLarge: SettleTypography.heading.copyWith(color: SettleColors.nightText),
      headlineMedium: SettleTypography.heading.copyWith(color: SettleColors.nightText),
      headlineSmall: SettleTypography.subheading.copyWith(color: SettleColors.nightText),
      titleLarge: SettleTypography.subheading.copyWith(color: SettleColors.nightText),
      titleMedium: SettleTypography.label.copyWith(color: SettleColors.nightSoft),
      titleSmall: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
      bodyLarge: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
      bodyMedium: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
      bodySmall: SettleTypography.caption.copyWith(color: SettleColors.nightMuted),
      labelLarge: SettleTypography.label.copyWith(color: SettleColors.nightSoft),
      labelMedium: SettleTypography.caption.copyWith(color: SettleColors.nightMuted),
      labelSmall: SettleTypography.caption.copyWith(color: SettleColors.nightMuted),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATIONS
// ─────────────────────────────────────────────────────────────────────────────

class SettleAnimations {
  SettleAnimations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration modeSwitch = Duration(milliseconds: 600);
  static const Duration breathe = Duration(milliseconds: 5000);
  static const Duration sosBreathe = Duration(milliseconds: 7000);

  static const Curve entryIn = Curves.easeOutCubic;
  static const Curve entryOut = Curves.easeInCubic;

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;
}

// ─────────────────────────────────────────────────────────────────────────────
// SEMANTIC COLORS — Brightness-aware
// ─────────────────────────────────────────────────────────────────────────────

class SettleSemanticColors {
  SettleSemanticColors._();

  static Color headline(BuildContext context) =>
      _dark(context) ? SettleColors.nightText : SettleColors.ink900;
  static Color body(BuildContext context) =>
      _dark(context) ? SettleColors.nightSoft : SettleColors.ink700;
  static Color supporting(BuildContext context) =>
      _dark(context) ? SettleColors.nightSoft : SettleColors.ink600;
  static Color muted(BuildContext context) =>
      _dark(context) ? SettleColors.nightMuted : SettleColors.ink600;
  static Color accent(BuildContext context) =>
      _dark(context) ? SettleColors.nightAccent : SettleColors.sage600;
  static Color onSurface(BuildContext context) =>
      _dark(context) ? SettleColors.nightText : SettleColors.ink800;
  /// Alias for [onSurface]. Kept for backward compatibility.
  static Color onGlass(BuildContext context) => onSurface(context);

  static bool _dark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
}

// ─────────────────────────────────────────────────────────────────────────────
// PAGE TRANSITION
// ─────────────────────────────────────────────────────────────────────────────

class _SettlePageTransitionsBuilder extends PageTransitionsBuilder {
  const _SettlePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: CurveTween(curve: Curves.easeOut).animate(animation),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REDUCE-MOTION ENTRY ANIMATIONS
// ─────────────────────────────────────────────────────────────────────────────

extension ReduceMotionAnimate on Widget {
  Widget entryFadeIn(
    BuildContext context, {
    Duration? duration,
    Duration delay = Duration.zero,
    double moveY = 12,
  }) {
    if (SettleAnimations.reduceMotion(context)) return this;
    return animate(delay: delay)
        .fadeIn(duration: duration ?? SettleAnimations.normal)
        .moveY(begin: moveY, end: 0);
  }

  Widget entrySlideIn(
    BuildContext context, {
    Duration? duration,
    Duration delay = Duration.zero,
    double moveX = 16,
  }) {
    if (SettleAnimations.reduceMotion(context)) return this;
    return animate(delay: delay)
        .fadeIn(duration: duration ?? 300.ms)
        .moveX(begin: moveX, end: 0, duration: duration ?? 300.ms);
  }

  Widget entryScaleIn(
    BuildContext context, {
    Duration? duration,
    Duration delay = Duration.zero,
    double scaleBegin = 0.95,
  }) {
    if (SettleAnimations.reduceMotion(context)) return this;
    return animate(delay: delay)
        .fadeIn(duration: duration ?? 300.ms)
        .scale(
          begin: Offset(scaleBegin, scaleBegin),
          end: const Offset(1, 1),
          duration: duration ?? 300.ms,
        );
  }

  Widget entryFadeOnly(
    BuildContext context, {
    Duration? duration,
    Duration delay = Duration.zero,
  }) {
    if (SettleAnimations.reduceMotion(context)) return this;
    return animate(delay: delay).fadeIn(duration: duration ?? 300.ms);
  }
}
