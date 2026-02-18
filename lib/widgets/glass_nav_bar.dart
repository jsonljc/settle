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
  static const double _innerHighlightHeight = 0.5;

  /// Light: white 48%. Dark: white 4%.
  static Color _barFill(GlassNavBarVariant v) {
    switch (v) {
      case GlassNavBarVariant.light:
        return SettleGlassLight.background; // 48%
      case GlassNavBarVariant.dark:
        return const Color(0x0AFFFFFF); // 4%
    }
  }

  static Color _topBorder(GlassNavBarVariant v) {
    switch (v) {
      case GlassNavBarVariant.light:
        return SettleGlassLight.border;
      case GlassNavBarVariant.dark:
        return SettleGlassDark.border;
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

    final activeColor = isLight
        ? SettleColors.dusk600
        : SettleColors.nightAccent;
    final inactiveColor = isLight
        ? SettleColors.ink300
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
                          splashColor: activeColor.withValues(alpha: 0.12),
                          highlightColor: activeColor.withValues(alpha: 0.06),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: _minItemWidth,
                              minHeight: _barHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(item.icon, size: _iconSize, color: color),
                                const SizedBox(height: 2),
                                Text(item.label, style: _labelStyle(color)),
                              ],
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
