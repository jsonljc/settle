import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/settle_design_system.dart';

/// Variant of the pill button (light/dark, primary/secondary).
enum GlassPillVariant {
  primaryLight,
  secondaryLight,
  primaryDark,
  secondaryDark,
}

/// Solid pill-shaped button with optional icon, variants, and press animation.
///
/// - Min height 48px (Settle tap target), pill radius, 11px vertical / 22px horizontal padding.
/// - All variants: scale-down (0.97) on press (100ms), haptic feedback.
///
/// Name kept as `GlassPill` for backward compatibility across 48+ importers.
class GlassPill extends StatefulWidget {
  const GlassPill({
    super.key,
    required this.label,
    required this.onTap,
    this.variant,
    this.icon,
    this.iconData,
    this.expanded = false,
    this.fill,
    this.textColor,
    this.border,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final GlassPillVariant? variant;
  final Widget? icon;
  final IconData? iconData;
  final bool expanded;
  final Color? fill;
  final Color? textColor;
  final Color? border;
  final bool enabled;

  @override
  State<GlassPill> createState() => _GlassPillState();
}

class _GlassPillState extends State<GlassPill> {
  bool _pressed = false;

  static const double _minHeight = 48;
  static const EdgeInsets _padding = EdgeInsets.symmetric(
    vertical: 11,
    horizontal: 22,
  );
  static const Duration _pressDuration = Duration(milliseconds: 100);
  static const double _pressedScale = 0.97;

  static TextStyle _labelStyle(Color color) => SettleTypography.body.copyWith(
    fontWeight: FontWeight.w500,
    letterSpacing: -0.01,
    color: color,
  );

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveVariant =
        widget.variant ?? GlassPillVariant.primaryLight;
    final isLight =
        effectiveVariant == GlassPillVariant.primaryLight ||
        effectiveVariant == GlassPillVariant.secondaryLight;
    var (Color fill, Color borderColor, Color textColor) =
        _resolveVariant(effectiveVariant);
    if (widget.fill != null) fill = widget.fill!;
    if (widget.textColor != null) textColor = widget.textColor!;
    if (widget.border != null) borderColor = widget.border!;

    final radius = BorderRadius.circular(SettleRadii.pill);

    return Semantics(
      button: true,
      enabled: widget.enabled,
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.5,
        child: AnimatedScale(
          duration: _pressDuration,
          curve: Curves.easeOutCubic,
          scale: _pressed ? _pressedScale : 1,
          child: Listener(
            onPointerDown: (_) => _setPressed(true),
            onPointerUp: (_) => _setPressed(false),
            onPointerCancel: (_) => _setPressed(false),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.enabled
                    ? () {
                        HapticFeedback.lightImpact();
                        widget.onTap();
                      }
                    : null,
                splashColor: _splashColor(isLight),
                highlightColor: _highlightColor(isLight),
                borderRadius: radius,
                child: Container(
                  constraints: const BoxConstraints(minHeight: _minHeight),
                  width: widget.expanded ? double.infinity : null,
                  padding: _padding,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: radius,
                    border: Border.all(color: borderColor, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: widget.expanded
                        ? MainAxisSize.max
                        : MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        widget.icon!,
                        const SizedBox(width: SettleSpacing.sm),
                      ] else if (widget.iconData != null) ...[
                        Icon(
                          widget.iconData,
                          size: 20,
                          color: textColor,
                        ),
                        const SizedBox(width: SettleSpacing.sm),
                      ],
                      Flexible(
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _labelStyle(textColor),
                        ),
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

  (Color, Color, Color) _resolveVariant(GlassPillVariant v) {
    switch (v) {
      case GlassPillVariant.primaryLight:
        return (
          SettleColors.stone100,
          SettleColors.ink300.withValues(alpha: 0.20),
          SettleColors.ink800,
        );
      case GlassPillVariant.secondaryLight:
        return (
          SettleColors.stone50,
          SettleColors.ink300.withValues(alpha: 0.12),
          SettleColors.ink700,
        );
      case GlassPillVariant.primaryDark:
        return (
          SettleColors.night700,
          Colors.white.withValues(alpha: 0.12),
          SettleColors.nightText,
        );
      case GlassPillVariant.secondaryDark:
        return (
          SettleColors.night800,
          Colors.white.withValues(alpha: 0.08),
          SettleColors.nightSoft,
        );
    }
  }

  Color _splashColor(bool isLight) {
    if (isLight) {
      return SettleColors.ink900.withValues(alpha: 0.08);
    }
    return SettleColors.nightText.withValues(alpha: 0.08);
  }

  Color _highlightColor(bool isLight) {
    if (isLight) {
      return SettleColors.ink900.withValues(alpha: 0.04);
    }
    return SettleColors.nightText.withValues(alpha: 0.04);
  }
}
