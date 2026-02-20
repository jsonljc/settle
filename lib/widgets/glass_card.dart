import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/settle_design_system.dart';

/// Variant of the card (light/dark, standard/strong).
enum GlassCardVariant {
  light,
  lightStrong,
  dark,
  darkStrong,
}

/// Solid surface card with subtle shadow and optional border.
/// When [onTap] is set, press feedback: opacity 0.85 + scale 0.985 (ease-out).
///
/// Name kept as `GlassCard` for backward compatibility across 63+ importers.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.variant = GlassCardVariant.light,
    this.padding,
    this.borderRadius,
    this.margin,
    this.onTap,
    this.fill,
    this.border,
  });

  final Widget child;
  final GlassCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? fill;
  final bool? border;

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? SettleRadii.card;
    final radius = BorderRadius.circular(br);
    final resolvedPadding =
        padding ?? const EdgeInsets.all(SettleSpacing.cardPadding);
    final isDark = variant == GlassCardVariant.dark ||
        variant == GlassCardVariant.darkStrong;

    final Color bg = fill ?? (isDark ? SettleSurfaces.cardDark : SettleSurfaces.cardLight);
    final showBorder = border ?? isDark;

    Widget card = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: showBorder
            ? Border.all(
                color: isDark
                    ? SettleSurfaces.cardBorderDark
                    : SettleColors.ink300.withValues(alpha: 0.12),
                width: 0.5,
              )
            : null,
        boxShadow: _shadow(isDark),
      ),
      child: Padding(
        padding: resolvedPadding,
        child: child,
      ),
    );

    if (margin != null) {
      card = Padding(padding: margin!, child: card);
    }
    if (onTap != null) {
      card = _GlassCardTapWrapper(onTap: onTap!, child: card);
    }
    return card;
  }

  static List<BoxShadow> _shadow(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ];
  }
}

/// Applies opacity 0.85 + scale 0.985 on press, with haptic feedback.
class _GlassCardTapWrapper extends StatefulWidget {
  const _GlassCardTapWrapper({
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_GlassCardTapWrapper> createState() => _GlassCardTapWrapperState();
}

class _GlassCardTapWrapperState extends State<_GlassCardTapWrapper> {
  bool _pressed = false;

  static const Duration _pressDuration = Duration(milliseconds: 100);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        setState(() => _pressed = true);
        HapticFeedback.selectionClick();
      },
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          duration: _pressDuration,
          curve: Curves.easeOutCubic,
          scale: _pressed ? 0.985 : 1,
          child: AnimatedOpacity(
            duration: _pressDuration,
            curve: Curves.easeOut,
            opacity: _pressed ? 0.85 : 1,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Convenience card variants
// ─────────────────────────────────────────────────────────────────────────────

/// Accent-tinted card (dusk). Used for highlighted blocks.
class GlassCardAccent extends StatelessWidget {
  const GlassCardAccent({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      variant: GlassCardVariant.darkStrong,
      fill: SettleSurfaces.tintDusk,
      padding: padding ?? const EdgeInsets.all(SettleSpacing.cardPadding),
      child: child,
    );
  }
}

/// Dark card (e.g. for flashcard mode).
class GlassCardDark extends StatelessWidget {
  const GlassCardDark({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      variant: GlassCardVariant.darkStrong,
      padding: padding ?? const EdgeInsets.all(SettleSpacing.cardPadding),
      child: child,
    );
  }
}

/// Rose/blush tinted card for soft error or caution blocks.
class GlassCardRose extends StatelessWidget {
  const GlassCardRose({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      variant: GlassCardVariant.lightStrong,
      fill: SettleSurfaces.tintBlush,
      padding: padding ?? const EdgeInsets.all(SettleSpacing.cardPadding),
      child: DefaultTextStyle(
        style: DefaultTextStyle.of(context).style.copyWith(
              color: SettleColors.ink800,
            ),
        child: child,
      ),
    );
  }
}

/// Sage tinted card for reflection or positive blocks.
class GlassCardTeal extends StatelessWidget {
  const GlassCardTeal({
    super.key,
    required this.child,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      variant: GlassCardVariant.lightStrong,
      fill: SettleSurfaces.tintSage,
      padding: padding ?? const EdgeInsets.all(SettleSpacing.cardPadding),
      child: child,
    );
  }
}
