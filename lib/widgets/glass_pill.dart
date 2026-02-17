import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/settle_design_system.dart';

/// Variant of the glass pill button (light/dark, primary/secondary).
enum GlassPillVariant {
  primaryLight,
  secondaryLight,
  primaryDark,
  secondaryDark,
}

/// Pill-shaped glass button with optional icon, variants, and press animation.
///
/// - Min height 48px (Settle tap target), pill radius, 11px vertical / 22px horizontal padding.
/// - All variants: 0.5px specular top highlight, ink ripple, scale-down (0.97) on press (100ms).
class GlassPill extends StatefulWidget {
  const GlassPill({
    super.key,
    required this.label,
    required this.onTap,
    required this.variant,
    this.icon,
    this.expanded = false,
  });

  final String label;
  final VoidCallback onTap;
  final GlassPillVariant variant;
  final Widget? icon;
  final bool expanded;

  @override
  State<GlassPill> createState() => _GlassPillState();
}

class _GlassPillState extends State<GlassPill> {
  bool _pressed = false;

  static const double _minHeight = 48;
  static const EdgeInsets _padding =
      EdgeInsets.symmetric(vertical: 11, horizontal: 22);
  static const Duration _pressDuration = Duration(milliseconds: 100);
  static const double _pressedScale = 0.97;

  /// Inter 14, weight 500, letterSpacing -0.01
  static TextStyle _labelStyle(Color color) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.01,
        color: color,
      );

  /// 0.5px specular highlight gradient (top edge)
  static const LinearGradient _specularGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x0DFFFFFF), Color(0x00FFFFFF)],
    stops: [0.0, 1.0],
  );

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isLight = widget.variant == GlassPillVariant.primaryLight ||
        widget.variant == GlassPillVariant.secondaryLight;
    final (Color fill, Color border, Color textColor, double blur) =
        _resolveVariant(isLight);

    final radius = BorderRadius.circular(SettleRadii.pill);

    return Semantics(
      button: true,
      child: ClipRRect(
        borderRadius: radius,
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
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onTap();
                },
                splashColor: _splashColor(isLight),
                highlightColor: _highlightColor(isLight),
                borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: Container(
                  constraints: const BoxConstraints(minHeight: _minHeight),
                  width: widget.expanded ? double.infinity : null,
                  padding: _padding,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: radius,
                    border: Border.all(color: border, width: 0.5),
                    boxShadow: _innerGlow(widget.variant),
                  ),
                  child: Stack(
                    children: [
                      // 0.5px specular highlight on top (same technique as GlassCard)
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 1,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: _specularGradient,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(SettleRadii.pill),
                              topRight: Radius.circular(SettleRadii.pill),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize:
                            widget.expanded ? MainAxisSize.max : MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.icon != null) ...[
                            widget.icon!,
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
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }

  (Color, Color, Color, double) _resolveVariant(bool isLight) {
    switch (widget.variant) {
      case GlassPillVariant.primaryLight:
        return (
          const Color(0xD12A303A), // rgba(42,48,58) 82%
          const Color(0x0FFFFFFF), // white 6%
          Colors.white,
          16,
        );
      case GlassPillVariant.secondaryLight:
        return (
          SettleGlassLight.background,
          SettleGlassLight.border,
          SettleColors.ink700,
          SettleGlassLight.blur,
        );
      case GlassPillVariant.primaryDark:
        return (
          const Color(0x4088AACC), // rgba(136,170,204) 25%
          const Color(0x3388AACC), // nightAccent 20%
          SettleColors.nightAccent,
          20,
        );
      case GlassPillVariant.secondaryDark:
        return (
          SettleGlassDark.background,
          SettleGlassDark.border,
          SettleColors.nightMuted,
          SettleGlassDark.blur,
        );
    }
  }

  List<BoxShadow>? _innerGlow(GlassPillVariant variant) {
    if (variant == GlassPillVariant.primaryLight) {
      return [
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.06),
          blurRadius: 8,
          spreadRadius: -2,
        ),
      ];
    }
    return null;
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
