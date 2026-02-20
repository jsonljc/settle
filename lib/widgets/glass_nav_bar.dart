import 'package:flutter/material.dart';

import '../theme/settle_design_system.dart';

/// Single item for [GlassNavBar]: outline icon, optional filled icon when active, and label.
/// Per WIREFRAMES_V2: active tab shows solid icon + label; inactive shows outline icon only.
class GlassNavBarItem {
  const GlassNavBarItem({
    required this.icon,
    required this.label,
    IconData? activeIcon,
  }) : activeIcon = activeIcon ?? icon;

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

/// Variant for bar fill and text (light vs dark).
enum GlassNavBarVariant { light, dark }

/// Solid bottom nav bar with top divider.
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

  static const double _barHeight = 68;

  /// Label only for active tab (V2: inactive = outline icon, no label).
  static TextStyle _labelStyle(Color color) =>
      SettleTypography.caption.copyWith(
        letterSpacing: 0.0,
        color: color,
        fontWeight: FontWeight.w600,
      );

  static const double _iconSize = 26;

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

    final barColor = isLight ? Colors.white : const Color(0xFF1A1F28);

    return Container(
      height: _barHeight + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: BoxDecoration(
        color: barColor,
        border: Border(
          top: BorderSide(
            color: isLight
                ? SettleColors.ink300.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final isActive = i == activeIndex;
                  final color = isActive ? activeColor : inactiveColor;
                  final icon = isActive ? item.activeIcon : item.icon;

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
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: _barHeight - SettleSpacing.sm,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(icon, size: _iconSize, color: color),
                                  if (isActive) ...[
                                    const SizedBox(height: SettleSpacing.xs),
                                    AnimatedDefaultTextStyle(
                                      duration: const Duration(
                                        milliseconds: 180,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      style: _labelStyle(color),
                                      child: Text(item.label),
                                    ),
                                  ],
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
    );
  }
}
