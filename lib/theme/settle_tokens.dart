import 'package:flutter/material.dart';

enum SurfaceMode { day, night, focus }

/// Settle Design Tokens — single source of truth for all visual constants.
///
/// Access via the convenience alias `T`:
///   T.pal.accent, T.type.h1, T.space.md, etc.
class T {
  T._();
  static const pal = _Palette();
  static const type = _Type();
  static const space = _Space();
  static const radius = _Radius();
  static const glass = _Glass();
  static const arc = _Arc();
  static const anim = _Anim();

  /// True when the platform requests reduced motion.
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;
}

// ─────────────────────────────────────────────
//  Color Palette
// ─────────────────────────────────────────────

class _Palette {
  const _Palette();

  // Backgrounds — raw colors used to build gradients
  final Color bgDeep = const Color(0xFF0F1724);
  final Color bgWarm = const Color(0xFF162033);
  final Color bgSlate = const Color(0xFF1A2740);

  final Color bgNightDeep = const Color(0xFF07090E);
  final Color bgNightMid = const Color(0xFF0A0E17);

  final Color bgSplashDeep = const Color(0xFF111D2E);
  final Color bgSplashMid = const Color(0xFF1A2D44);

  // Day-mode backgrounds (v3): brighter neutral blues for daytime readability.
  final Color bgDayTop = const Color(0xFF1A2433);
  final Color bgDayMid = const Color(0xFF253245);
  final Color bgDayBottom = const Color(0xFF2E3D53);

  // Background gradients (168° ≈ nearly vertical, slight rightward lean)
  LinearGradient get bg => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0F1724), Color(0xFF162033), Color(0xFF1A2740)],
  );

  LinearGradient get bgNight => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF07090E), Color(0xFF0A0E17), Color(0xFF07090E)],
  );

  LinearGradient get bgDay => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A2433), Color(0xFF253245), Color(0xFF2E3D53)],
  );

  LinearGradient get bgFlashcard => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF0A1320), Color(0xFF121F2F), Color(0xFF0C1726)],
  );

  LinearGradient get bgSplash => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF111D2E), Color(0xFF1A2D44), Color(0xFF111D2E)],
  );

  // Accent & semantic
  final Color accent = const Color(0xFFE8A94A);
  final Color teal = const Color(0xFF5AB5A0);
  final Color rose = const Color(0x1FC86464); // rgba(200,100,100,0.12)

  // Text
  final Color textPrimary = const Color(0xFFF2F5F8);
  final Color textSecondary = const Color(0x99FFFFFF); // white 60%
  final Color textTertiary = const Color(0x66FFFFFF); // white 40%

  /// Pure black for distraction-free focus mode (SOS, Regulate flow).
  final Color focusBackground = const Color(0xFF000000);

  LinearGradient gradientFor(SurfaceMode mode) {
    return switch (mode) {
      SurfaceMode.day => bgDay,
      SurfaceMode.night => bgNight,
      SurfaceMode.focus => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF000000), Color(0xFF000000)],
      ),
    };
  }
}

// ─────────────────────────────────────────────
//  Wake-Window Arc Colors
// ─────────────────────────────────────────────

class _Arc {
  const _Arc();

  final Color ok = const Color(0xFF6EE7B7); // 0–55%
  final Color watch = const Color(0xFFFBBF24); // 55–75%
  final Color soon = const Color(0xFFF59E0B); // 75–90%
  final Color now = const Color(0xFFE89A3D); // 90%+ (high attention)
  final Color critical = const Color(0xFFEF4444); // urgent only

  /// Returns the correct arc color for a given progress (0.0–1.0).
  Color forProgress(double p) {
    if (p < 0.55) return ok;
    if (p < 0.75) return watch;
    if (p < 0.90) return soon;
    return now;
  }
}

// ─────────────────────────────────────────────
//  Glass Surface Tokens
// ─────────────────────────────────────────────

class _Glass {
  const _Glass();

  // Background fills
  final Color fill = const Color(0x12FFFFFF); // white 7%
  final Color fillDark = const Color(0x4D000000); // black 30%
  final Color fillAccent = const Color(0x1AE8A94A); // accent 10%
  final Color fillRose = const Color(0x1FC86464); // rose 12%
  final Color fillTeal = const Color(0x1A5AB5A0); // teal 10%

  // V3 mode-specific fills (higher opacity by mode for readability).
  final Color fillDay = const Color(0x2AFFFFFF); // white 16%
  final Color fillNight = const Color(0x16FFFFFF); // white 9%

  // Blur
  final double sigma = 12.0; // sigmaX & sigmaY for BackdropFilter
  final double saturate = 1.5;
  final double sigmaDay = 8.0;
  final double sigmaNight = 10.0;
  final double sigmaFocus = 6.0;

  // Border
  final Color border = const Color(0x0AFFFFFF); // white 4%
  final Color borderDay = const Color(0x2FFFFFFF); // white 18%
  final Color borderNight = const Color(0x1AFFFFFF); // white 10%

  // Top-edge specular highlight
  final LinearGradient specular = const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x08FFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.4],
  );
}

// ─────────────────────────────────────────────
//  Typography Tokens
// ─────────────────────────────────────────────

class _Type {
  const _Type();

  // Font family applied at the ThemeData level via google_fonts.
  // These tokens define size / weight / spacing / height only.

  TextStyle get splash => const TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.8,
    height: 1.15,
  );

  TextStyle get h1 => const TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );

  TextStyle get h2 => const TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.22,
  );

  TextStyle get h3 => const TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );

  TextStyle get body => const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.6,
  );

  TextStyle get label => const TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.4,
  );

  TextStyle get caption => const TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.5,
  );

  TextStyle get overline => const TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    height: 1.4,
  );

  TextStyle get stat => const TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.0,
  );

  TextStyle get timer => const TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w300,
    letterSpacing: -2.5,
    height: 1.0,
  );
}

// ─────────────────────────────────────────────
//  Spacing & Radii (4px base grid)
// ─────────────────────────────────────────────

class _Space {
  const _Space();

  final double xs = 4;
  final double sm = 8;
  final double md = 12;
  final double lg = 16;
  final double xl = 20;
  final double xxl = 24;
  final double xxxl = 32;

  /// Screen horizontal padding.
  final double screen = 20;

  /// Card internal padding range (use md–lg contextually).
  final double cardMin = 16;
  final double cardMax = 26;
}

class _Radius {
  const _Radius();

  final double sm = 14;
  final double md = 18;
  final double lg = 22;
  final double xl = 26;
  final double pill = 100;
}

// ─────────────────────────────────────────────
//  Animation Durations
// ─────────────────────────────────────────────

class _Anim {
  const _Anim();

  final Duration fast = const Duration(milliseconds: 150);
  final Duration normal = const Duration(milliseconds: 250);
  final Duration slow = const Duration(milliseconds: 400);
  final Duration modeSwitch = const Duration(milliseconds: 800);
  final Duration breathe = const Duration(milliseconds: 5500); // moon
  final Duration sosBreathe = const Duration(milliseconds: 8000); // SOS circles
}
