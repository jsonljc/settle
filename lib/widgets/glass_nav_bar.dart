import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/settle_design_system.dart';

/// Single item for [GlassNavBar]: icon and label.
class GlassNavBarItem {
  const GlassNavBarItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// Variant for bar fill and text (light vs dark).
enum GlassNavBarVariant { light, dark }

/// Bottom nav bar with liquid glass: blur, top border, inner highlight.
/// Use [variant] or leave null to auto-detect from [ThemeData.brightness].
class GlassNavBar extends StatelessWidget {
  const GlassNavBar({
    super.key,
    required this.items,
    required this.activeIndex,
    required this.onTap,
    this.variant,
  });

  final List<GlassNavBarItem> items;
  final int activeIndex;
  final ValueChanged<int> onTap;
  final GlassNavBarVariant? variant;

  static const double _blurSigma = 48;
  static const double _barHeight = 64;
  static const double _minItemWidth = 48;
  static const double _iconSize = 20;
  static const double _activeIconSize = 21;
  static const double _innerHighlightHeight = 0.5;

  /// Light: white 48%. Dark: white 4%.
  static Color _barFill(GlassNavBarVariant v) {
    switch (v) {
      case GlassNavBarVariant.light:
        return Colors.white.withValues(alpha: 0.56);
      case GlassNavBarVariant.dark:
        return const Color(0x66121822); // smoky neutral
    }
  }

  static Color _topBorder(GlassNavBarVariant v) {
    switch (v) {
      case GlassNavBarVariant.light:
        return Colors.white.withValues(alpha: 0.74);
      case GlassNavBarVariant.dark:
        return Colors.white.withValues(alpha: 0.12);
    }
  }

  /// Label: SettleTypography.caption (Inter 11.5 w500), letterSpacing 0.02
  static TextStyle _labelStyle(Color color) =>
      SettleTypography.caption.copyWith(letterSpacing: 0.02, color: color);

  @override
  Widget build(BuildContext context) {
    final effectiveVariant =
        variant ??
        (Theme.of(context).brightness == Brightness.dark
            ? GlassNavBarVariant.dark
            : GlassNavBarVariant.light);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isLight = effectiveVariant == GlassNavBarVariant.light;

    final activeColor = isLight ? SettleColors.ink900 : SettleColors.nightText;
    final inactiveColor = isLight
        ? SettleColors.ink400
        : SettleColors.nightMuted;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: Container(
          height: _barHeight + bottomPadding,
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: BoxDecoration(
            color: _barFill(effectiveVariant),
            border: Border(
              top: BorderSide(color: _topBorder(effectiveVariant), width: 0.5),
            ),
          ),
          child: Stack(
            children: [
              // Inner shadow: 0.5px white highlight at top
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: _innerHighlightHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: isLight
                        ? Colors.white.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Row(
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final isActive = i == activeIndex;
                  final color = isActive ? activeColor : inactiveColor;

                  return Expanded(
                    child: Semantics(
                      label: '${item.label} tab',
                      selected: isActive,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onTap(i),
                          splashColor: activeColor.withValues(
                            alpha: isLight ? 0.08 : 0.12,
                          ),
                          highlightColor: activeColor.withValues(
                            alpha: isLight ? 0.04 : 0.08,
                          ),
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              constraints: const BoxConstraints(
                                minWidth: _minItemWidth,
                                minHeight: _barHeight - SettleSpacing.sm,
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: SettleSpacing.xs,
                                vertical: SettleSpacing.xs,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: SettleSpacing.sm,
                                vertical: SettleSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? (isLight
                                          ? Colors.white.withValues(alpha: 0.56)
                                          : Colors.white.withValues(
                                              alpha: 0.12,
                                            ))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(
                                  SettleRadii.pill,
                                ),
                                border: isActive
                                    ? Border.all(
                                        color: isLight
                                            ? SettleColors.ink400.withValues(
                                                alpha: 0.24,
                                              )
                                            : Colors.white.withValues(
                                                alpha: 0.20,
                                              ),
                                        width: 0.5,
                                      )
                                    : null,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOutCubic,
                                    child: Icon(
                                      item.icon,
                                      size: isActive
                                          ? _activeIconSize
                                          : _iconSize,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 180),
                                    curve: Curves.easeOutCubic,
                                    style: _labelStyle(color).copyWith(
                                      fontWeight: isActive
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                    ),
                                    child: Text(item.label),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
