import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'settle_tokens.dart';

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
    final r = borderRadius ?? T.radius.xl;
    final br = BorderRadius.circular(r);

    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: T.glass.sigma, sigmaY: T.glass.sigma),
        child: Container(
          decoration: BoxDecoration(
            color: fill ?? T.glass.fill,
            borderRadius: br,
            border: border ? Border.all(color: T.glass.border, width: 1) : null,
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
                      gradient: T.glass.specular,
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
    return GlassCard(fill: T.glass.fillDark, padding: padding, child: child);
  }
}

/// Accent-tinted glass for active / highlighted states.
class GlassCardAccent extends StatelessWidget {
  const GlassCardAccent({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(fill: T.glass.fillAccent, padding: padding, child: child);
  }
}

/// Teal-tinted glass for positive trends.
class GlassCardTeal extends StatelessWidget {
  const GlassCardTeal({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(fill: T.glass.fillTeal, padding: padding, child: child);
  }
}

/// Rose-tinted glass for SOS / crisis elements.
class GlassCardRose extends StatelessWidget {
  const GlassCardRose({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(fill: T.glass.fillRose, padding: padding, child: child);
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
    final baseFill = widget.fill ?? T.glass.fill;
    final fill = _pressed
        ? baseFill.withValues(alpha: (baseFill.a + 0.08).clamp(0.0, 1.0))
        : baseFill;

    return Opacity(
      opacity: widget.enabled ? 1 : 0.55,
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(T.radius.pill),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            scale: _pressed ? 0.985 : 1,
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
                  sigmaX: T.glass.sigma + 2,
                  sigmaY: T.glass.sigma + 2,
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
                    borderRadius: BorderRadius.circular(T.radius.pill),
                    border: Border.all(
                      color: _pressed
                          ? T.pal.textPrimary.withValues(alpha: 0.22)
                          : T.glass.border.withValues(alpha: 0.65),
                      width: 1,
                    ),
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
                                T.radius.pill,
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
                              color: widget.textColor ?? T.pal.textPrimary,
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
                              style: T.type.label.copyWith(
                                color: widget.textColor ?? T.pal.textPrimary,
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
    final radius = BorderRadius.circular(T.radius.pill);
    final normalFill = widget.enabled
        ? T.glass.fillAccent.withValues(alpha: 0.26)
        : T.glass.fillAccent.withValues(alpha: 0.14);
    final pressedFill = widget.enabled
        ? T.glass.fillAccent.withValues(alpha: 0.34)
        : normalFill;
    final borderColor = widget.enabled
        ? T.pal.accent.withValues(alpha: _pressed ? 0.40 : 0.22)
        : T.glass.border.withValues(alpha: 0.4);
    final fg = widget.enabled
        ? T.pal.textPrimary
        : T.pal.textPrimary.withValues(alpha: 0.7);

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
                sigmaX: T.glass.sigma + 2,
                sigmaY: T.glass.sigma + 2,
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
                            color: T.pal.accent.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: T.pal.accent.withValues(alpha: 0.06),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                ),
                child: Align(
                  alignment: widget.alignment,
                  child: Text(
                    widget.label,
                    style: T.type.label.copyWith(color: fg),
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
  const SettleBackground({super.key, required this.child, this.gradient});

  final Widget child;

  /// Override the background gradient (e.g. for nighttime surfaces).
  final LinearGradient? gradient;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: T.anim.modeSwitch,
      curve: Curves.easeInOut,
      decoration: BoxDecoration(gradient: gradient ?? T.pal.bg),
      child: child,
    );
  }
}
