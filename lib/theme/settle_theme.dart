import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'settle_tokens.dart';

/// Builds the app-wide ThemeData for Settle.
///
/// Usage in MaterialApp:
///   theme: SettleTheme.data,
class SettleTheme {
  SettleTheme._();

  static ThemeData get data => _build(v3Enabled: false);

  static ThemeData get dataV3 => _build(v3Enabled: true);

  static ThemeData _build({required bool v3Enabled}) {
    final base = ThemeData.dark(useMaterial3: true);

    // Nunito as the primary font, falling back to platform default.
    final textTheme = GoogleFonts.nunitoTextTheme(
      base.textTheme,
    ).apply(bodyColor: T.pal.textPrimary, displayColor: T.pal.textPrimary);

    final dividerAlpha = v3Enabled ? 0.22 : 0.15;

    return base.copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      canvasColor: T.pal.bgDeep,

      // Color scheme
      colorScheme: ColorScheme.dark(
        primary: T.pal.accent,
        secondary: T.pal.teal,
        surface: T.pal.bgDeep,
        error: T.arc.critical,
        onPrimary: T.pal.bgDeep,
        onSecondary: T.pal.bgDeep,
        onSurface: T.pal.textPrimary,
        onError: T.pal.textPrimary,
      ),

      // Text
      textTheme: textTheme,

      // AppBar — transparent, no elevation, blends with gradient
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: textTheme.titleLarge?.merge(T.type.h2),
        iconTheme: IconThemeData(color: T.pal.textSecondary),
      ),

      // Elevated buttons use accent fill
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: T.pal.accent,
          foregroundColor: T.pal.bgDeep,
          textStyle: T.type.label,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(T.radius.pill),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          elevation: 0,
        ),
      ),

      // Text buttons — subtle, no splash
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: T.pal.textSecondary,
          textStyle: T.type.label,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Icon buttons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: T.pal.textSecondary),
      ),

      // Dividers
      dividerTheme: DividerThemeData(
        color: T.pal.textTertiary.withValues(alpha: dividerAlpha),
        thickness: 0.5,
      ),

      // Page transitions — fade only, no slides
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
        },
      ),

      // Splash / highlight — subtle
      splashColor: T.pal.accent.withValues(alpha: 0.08),
      highlightColor: T.pal.accent.withValues(alpha: 0.04),
    );
  }
}
