import 'dart:ui';

import 'package:flutter/material.dart';

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
class GlassPill extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(T.radius.pill),
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: T.glass.sigma,
              sigmaY: T.glass.sigma,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: fill ?? T.glass.fill,
                borderRadius: BorderRadius.circular(T.radius.pill),
                border: Border.all(color: T.glass.border, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: textColor ?? T.pal.textPrimary, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: T.type.label.copyWith(
                        color: textColor ?? T.pal.textPrimary,
                      ),
                    ),
                  ),
                ],
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
class GlassCta extends StatelessWidget {
  const GlassCta({
    super.key,
    required this.label,
    required this.onTap,
    this.expand = true,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool expand;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bg = enabled ? T.pal.accent : T.pal.accent.withValues(alpha: 0.45);
    final fg = enabled ? T.pal.bgDeep : T.pal.bgDeep.withValues(alpha: 0.75);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(T.radius.pill),
        ),
        alignment: expand ? Alignment.center : null,
        child: Text(label, style: T.type.label.copyWith(color: fg)),
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
