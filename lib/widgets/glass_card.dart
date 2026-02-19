import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/settle_design_system.dart';

/// Variant of the glass card (light/dark, standard/strong).
enum GlassCardVariant {
  light,
  lightStrong,
  dark,
  darkStrong,
}

/// Apple Liquid Glass–style card: heavy backdrop blur, specular highlight,
/// inner depth, and outer shadow. Pixel-perfect for the glass effect.
/// When [onTap] is set, press feedback: opacity 0.85 (ease-out).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.variant = GlassCardVariant.light,
    this.padding,
    this.borderRadius,
    this.margin,
    this.onTap,
  });

  final Widget child;
  final GlassCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final double? borderRadius;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;

  static const double _blurSigma = 40;
  static const double _specularHeight = 0.5;
  static const double _innerHighlightHeight = 2;

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? SettleRadii.glass;
    final radius = BorderRadius.circular(br);
    final resolvedPadding =
        padding ?? EdgeInsets.all(SettleSpacing.cardPadding);
    final isLight = variant == GlassCardVariant.light ||
        variant == GlassCardVariant.lightStrong;

    final (Color bg, Color borderColor) = _resolveFillAndBorder();
    final List<BoxShadow> outerShadow = _outerShadow();

    Widget card = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: radius,
            border: Border.all(
              color: borderColor,
              width: 0.5,
            ),
            boxShadow: outerShadow,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Content (bottom layer)
              Padding(
                padding: resolvedPadding,
                child: child,
              ),
              // 2. Inner shadow (depth) — 2px top highlight, white 10% → transparent
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _innerHighlightHeight,
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(br),
                      topRight: Radius.circular(br),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: _innerHighlightGradient,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
              // 3. Specular highlight — 0.5px at top (left→right gradient), on top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _specularHeight,
                child: IgnorePointer(
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(br),
                      topRight: Radius.circular(br),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: isLight
                            ? _specularGradientLight
                            : _specularGradientDark,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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

  (Color, Color) _resolveFillAndBorder() {
    switch (variant) {
      case GlassCardVariant.light:
        return (SettleGlassLight.background, SettleGlassLight.border);
      case GlassCardVariant.lightStrong:
        return (SettleGlassLight.backgroundStrong, SettleGlassLight.borderStrong);
      case GlassCardVariant.dark:
        return (SettleGlassDark.background, SettleGlassDark.border);
      case GlassCardVariant.darkStrong:
        return (SettleGlassDark.backgroundStrong, SettleGlassDark.borderStrong);
    }
  }

  List<BoxShadow> _outerShadow() {
    switch (variant) {
      case GlassCardVariant.light:
      case GlassCardVariant.lightStrong:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 3,
            offset: Offset.zero,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: Offset.zero,
          ),
        ];
      case GlassCardVariant.dark:
      case GlassCardVariant.darkStrong:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 3,
            offset: Offset.zero,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: Offset.zero,
          ),
        ];
    }
  }

  /// Light: transparent → white 55% → white 80% → white 55% → transparent
  static const LinearGradient _specularGradientLight = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0x00FFFFFF),
      Color(0x8CFFFFFF), // 55%
      Color(0xCCFFFFFF), // 80%
      Color(0x8CFFFFFF), // 55%
      Color(0x00FFFFFF),
    ],
    stops: [0.0, 0.35, 0.5, 0.65, 1.0],
  );

  /// Dark: transparent → white 7% → white 14% → white 7% → transparent
  static const LinearGradient _specularGradientDark = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0x00FFFFFF),
      Color(0x12FFFFFF), // 7%
      Color(0x24FFFFFF), // 14%
      Color(0x12FFFFFF), // 7%
      Color(0x00FFFFFF),
    ],
    stops: [0.0, 0.35, 0.5, 0.65, 1.0],
  );

  /// 2px top inner highlight: white 10% → transparent
  static const LinearGradient _innerHighlightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x1AFFFFFF), // 10%
      Color(0x00FFFFFF),
    ],
  );
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
// Preview for manual QA (optional: use in a test route or debug screen)
// ─────────────────────────────────────────────────────────────────────────────

/// Full-screen preview of all GlassCard variants on light and dark gradients.
/// Navigate to this screen and take screenshots for pixel-perfect QA.
class GlassCardPreview extends StatelessWidget {
  const GlassCardPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(SettleSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Light background', style: TextStyle(fontSize: 12)),
              const SizedBox(height: SettleSpacing.sm),
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: SettleGradients.home,
                  borderRadius: BorderRadius.all(Radius.circular(SettleRadii.glass)),
                ),
                padding: const EdgeInsets.all(SettleSpacing.lg),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GlassCard(
                      variant: GlassCardVariant.light,
                      child: Text('Light variant'),
                    ),
                    SizedBox(height: SettleSpacing.cardGap),
                    GlassCard(
                      variant: GlassCardVariant.lightStrong,
                      child: Text('Light strong variant'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: SettleSpacing.sectionGap),
              const Text('Dark background', style: TextStyle(fontSize: 12, color: Colors.white)),
              const SizedBox(height: SettleSpacing.sm),
              Container(
                height: 200,
                decoration: const BoxDecoration(
                  gradient: SettleGradients.sleep,
                  borderRadius: BorderRadius.all(Radius.circular(SettleRadii.glass)),
                ),
                padding: const EdgeInsets.all(SettleSpacing.lg),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GlassCard(
                      variant: GlassCardVariant.dark,
                      child: Text('Dark variant', style: TextStyle(color: Colors.white70)),
                    ),
                    SizedBox(height: SettleSpacing.cardGap),
                    GlassCard(
                      variant: GlassCardVariant.darkStrong,
                      child: Text('Dark strong variant', style: TextStyle(color: Colors.white70)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
