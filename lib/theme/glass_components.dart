import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'settle_design_system.dart';
import 'settle_tokens.dart' show SurfaceMode;
import 'surface_mode_resolver.dart';

class _GcTokens {
  _GcTokens._();

  static const double radiusXl = 26;
  static const double radiusPill = 100;

  static const double sigma = 12;
  static const double sigmaDay = 8;
  static const double sigmaNight = 10;
  static const double sigmaFocus = 6;

  static const Color fillDark = Color(0x4D000000);
  static const Color fillAccent = Color(0x1A5F6B80);
  static const Color fillTeal = Color(0x1A6F8C84);
  static const Color fillRose = Color(0x1A9A7A7A);
  static const Color fillDay = Color(0x2AFFFFFF);
  static const Color fillNight = Color(0x16FFFFFF);
  static const Color border = Color(0x0AFFFFFF);
  static const Color borderDay = Color(0x2FFFFFFF);
  static const Color borderNight = Color(0x1AFFFFFF);

  static const Color bgDeep = Color(0xFF0F1724);
  static const Color textPrimary = Color(0xFFF2F5F8);
  static const Color accent = Color(0xFF5F6B80);

  static const LinearGradient specular = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x08FFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 0.4],
  );

  static const Duration modeSwitch = Duration(milliseconds: 800);

  static TextStyle get label =>
      SettleTypography.body.copyWith(fontWeight: FontWeight.w600);

  static LinearGradient gradientFor(SurfaceMode mode) {
    return switch (mode) {
      SurfaceMode.day => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1A2433), Color(0xFF253245), Color(0xFF2E3D53)],
      ),
      SurfaceMode.night => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF07090E), Color(0xFF0A0E17), Color(0xFF07090E)],
      ),
      SurfaceMode.focus => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF000000), Color(0xFF000000)],
      ),
    };
  }
}

/// A frosted-glass card following the Settle glass morphism pattern:
///   ClipRRect → BackdropFilter → Container(fill + border + specular)
///
/// IMPORTANT: This widget only blurs content *behind* it in the paint order.
/// The ambient orbs / gradient background must be a Stack layer underneath.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.fill,
    this.borderRadius,
    this.padding,
    this.border = true,
    this.specular = false,
  });

  final Widget child;

  /// Override the default glass fill color.
  /// Defaults to [_Glass.fill] (white 7%).
  final Color? fill;

  /// Override the border radius. Defaults to [_Radius.xl] (26).
  final double? borderRadius;

  /// Internal padding. Defaults to 16px all sides.
  final EdgeInsetsGeometry? padding;

  /// Whether to draw the subtle border.
  final bool border;

  /// Whether to draw the top-edge specular highlight.
  final bool specular;

  @override
  Widget build(BuildContext context) {
    final mode = SurfaceModeResolver.resolveForContext(context);
    final r = borderRadius ?? _GcTokens.radiusXl;
    final br = BorderRadius.circular(r);
    final sigma = switch (mode) {
      SurfaceMode.day => _GcTokens.sigmaDay,
      SurfaceMode.night => _GcTokens.sigmaNight,
      SurfaceMode.focus => _GcTokens.sigmaFocus,
    };
    final resolvedFill =
        fill ??
        switch (mode) {
          SurfaceMode.day => _GcTokens.fillDay,
          SurfaceMode.night => _GcTokens.fillNight,
          SurfaceMode.focus => _GcTokens.fillDark,
        };
    final resolvedBorder = switch (mode) {
      SurfaceMode.day => _GcTokens.borderDay,
      SurfaceMode.night => _GcTokens.borderNight,
      SurfaceMode.focus => _GcTokens.borderNight,
    };

    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: Container(
          decoration: BoxDecoration(
            color: resolvedFill,
            borderRadius: br,
            border: border ? Border.all(color: resolvedBorder, width: 1) : null,
          ),
          child: Stack(
            children: [
              // Specular top-edge highlight
              if (specular)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 40,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _GcTokens.specular,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(r),
                        topRight: Radius.circular(r),
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dark variant for nighttime support surfaces.
class GlassCardDark extends StatelessWidget {
  const GlassCardDark({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(fill: _GcTokens.fillDark, padding: padding, child: child);
  }
}

/// Accent-tinted glass for active / highlighted states.
class GlassCardAccent extends StatelessWidget {
  const GlassCardAccent({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      fill: _GcTokens.fillAccent,
      padding: padding,
      child: child,
    );
  }
}

/// Teal-tinted glass for positive trends.
class GlassCardTeal extends StatelessWidget {
  const GlassCardTeal({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(fill: _GcTokens.fillTeal, padding: padding, child: child);
  }
}

/// Rose-tinted glass for SOS / crisis elements.
class GlassCardRose extends StatelessWidget {
  const GlassCardRose({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(fill: _GcTokens.fillRose, padding: padding, child: child);
  }
}

// ─────────────────────────────────────────────
//  Glass Pill Button
// ─────────────────────────────────────────────

/// A pill-shaped CTA with glass morphism.
class GlassPill extends StatefulWidget {
  const GlassPill({
    super.key,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.fill,
    this.textColor,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final Color? fill;
  final Color? textColor;
  final IconData? icon;

  @override
  State<GlassPill> createState() => _GlassPillState();
}

class _GlassPillState extends State<GlassPill> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final mode = SurfaceModeResolver.resolveForContext(context);
    final isDay = mode == SurfaceMode.day;
    final baseFill =
        widget.fill ??
        switch (mode) {
          SurfaceMode.day => _GcTokens.fillDay.withValues(alpha: 0.62),
          SurfaceMode.night => _GcTokens.fillNight,
          SurfaceMode.focus => _GcTokens.fillDark,
        };
    final fill = _pressed
        ? baseFill.withValues(alpha: (baseFill.a + 0.08).clamp(0.0, 1.0))
        : baseFill;
    final defaultTextColor = isDay ? _GcTokens.bgDeep : _GcTokens.textPrimary;
    final borderColor = _pressed
        ? (isDay
              ? _GcTokens.bgDeep.withValues(alpha: 0.24)
              : _GcTokens.textPrimary.withValues(alpha: 0.22))
        : (isDay
              ? _GcTokens.bgDeep.withValues(alpha: 0.14)
              : _GcTokens.border.withValues(alpha: 0.65));

    return Opacity(
      opacity: widget.enabled ? 1 : 0.55,
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_GcTokens.radiusPill),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
            scale: _pressed ? 0.97 : 1,
            child: GestureDetector(
              onTapDown: widget.enabled
                  ? (_) {
                      _setPressed(true);
                      HapticFeedback.selectionClick();
                    }
                  : null,
              onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
              onTapCancel: widget.enabled ? () => _setPressed(false) : null,
              onTap: widget.enabled
                  ? () {
                      HapticFeedback.lightImpact();
                      widget.onTap();
                    }
                  : null,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _GcTokens.sigma + 2,
                  sigmaY: _GcTokens.sigma + 2,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(_GcTokens.radiusPill),
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: _pressed
                        ? const []
                        : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.16),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                _GcTokens.radiusPill,
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(
                                    alpha: _pressed ? 0.08 : 0.13,
                                  ),
                                  Colors.white.withValues(alpha: 0.0),
                                ],
                                stops: const [0, 0.48],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(
                              widget.icon,
                              color: widget.textColor ?? defaultTextColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                          ],
                          Flexible(
                            child: Text(
                              widget.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: _GcTokens.label.copyWith(
                                color: widget.textColor ?? defaultTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Glass CTA Button (filled accent)
// ─────────────────────────────────────────────

/// A solid accent-filled CTA button with rounded corners.
class GlassCta extends StatefulWidget {
  const GlassCta({
    super.key,
    required this.label,
    required this.onTap,
    this.expand = true,
    this.enabled = true,
    this.alignment = Alignment.center,
    this.compact = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool expand;
  final bool enabled;
  final AlignmentGeometry alignment;
  final bool compact;

  @override
  State<GlassCta> createState() => _GlassCtaState();
}

class _GlassCtaState extends State<GlassCta> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final mode = SurfaceModeResolver.resolveForContext(context);
    final isDay = mode == SurfaceMode.day;
    final radius = BorderRadius.circular(_GcTokens.radiusPill);
    final normalFill = isDay
        ? (widget.enabled
              ? Colors.white.withValues(alpha: 0.70)
              : Colors.white.withValues(alpha: 0.52))
        : (widget.enabled
              ? _GcTokens.fillAccent.withValues(alpha: 0.26)
              : _GcTokens.fillAccent.withValues(alpha: 0.14));
    final pressedFill = isDay
        ? (widget.enabled ? Colors.white.withValues(alpha: 0.80) : normalFill)
        : (widget.enabled
              ? _GcTokens.fillAccent.withValues(alpha: 0.34)
              : normalFill);
    final borderColor = widget.enabled
        ? (isDay
              ? _GcTokens.bgDeep.withValues(alpha: _pressed ? 0.24 : 0.16)
              : _GcTokens.accent.withValues(alpha: _pressed ? 0.40 : 0.22))
        : _GcTokens.border.withValues(alpha: 0.4);
    final fg = isDay
        ? (widget.enabled
              ? _GcTokens.bgDeep
              : _GcTokens.bgDeep.withValues(alpha: 0.62))
        : (widget.enabled
              ? _GcTokens.textPrimary
              : _GcTokens.textPrimary.withValues(alpha: 0.7));

    return Semantics(
      button: true,
      enabled: widget.enabled,
      child: ClipRRect(
        borderRadius: radius,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          scale: _pressed ? 0.986 : 1,
          child: GestureDetector(
            onTapDown: widget.enabled
                ? (_) {
                    _setPressed(true);
                    HapticFeedback.lightImpact();
                  }
                : null,
            onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
            onTapCancel: widget.enabled ? () => _setPressed(false) : null,
            onTap: widget.enabled
                ? () {
                    widget.onTap();
                  }
                : null,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _GcTokens.sigma + 2,
                sigmaY: _GcTokens.sigma + 2,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                width: widget.expand ? double.infinity : null,
                padding: widget.compact
                    ? const EdgeInsets.symmetric(horizontal: 18, vertical: 11)
                    : const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                decoration: BoxDecoration(
                  color: _pressed ? pressedFill : normalFill,
                  borderRadius: radius,
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: _pressed
                      ? [
                          BoxShadow(
                            color: _GcTokens.accent.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: _GcTokens.accent.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Align(
                  alignment: widget.alignment,
                  child: Text(
                    widget.label,
                    style: _GcTokens.label.copyWith(color: fg),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Gradient Background Scaffold
// ─────────────────────────────────────────────

/// Wraps content in the animated gradient background.
/// All glass cards should be children of this widget so BackdropFilter
/// has something behind it to blur.
class SettleBackground extends StatelessWidget {
  const SettleBackground({
    super.key,
    required this.child,
    this.mode,
    this.gradientOverride,
    this.gradient,
  });

  final Widget child;
  final SurfaceMode? mode;

  /// Override the background gradient.
  final LinearGradient? gradientOverride;

  /// Legacy alias kept for compatibility.
  final LinearGradient? gradient;

  @override
  Widget build(BuildContext context) {
    final routeMode = mode ?? SurfaceModeResolver.resolveForContext(context);
    final customGradient = gradientOverride ?? gradient;
    final resolvedGradient = customGradient ?? _GcTokens.gradientFor(routeMode);

    return AnimatedContainer(
      duration: _GcTokens.modeSwitch,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(gradient: resolvedGradient),
      child: child,
    );
  }
}
