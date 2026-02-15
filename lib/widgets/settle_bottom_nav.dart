import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/settle_tokens.dart';

/// Bottom navigation bar with liquid glass blur.
///
/// Liquid Glass Spec (calm version):
///   - BackdropFilter sigma 18 (heavier than card blur for readability)
///   - Fill: bgDeep at 80% opacity
///   - Top border only, 0.5px, white 4%
///   - Selection: accent pill morph, 250ms ease-out
///   - Reduce-motion: instant color, no pill morph
///   - Reduce-transparency: solid bgDeep, no blur
class SettleBottomNav extends StatelessWidget {
  const SettleBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double _barHeight = 64;
  static const double _blurSigma = 18;

  static const _items = [
    _NavItem(label: 'Help Now', icon: Icons.favorite_outline, activeIcon: Icons.favorite_rounded),
    _NavItem(label: 'Sleep', icon: Icons.nightlight_outlined, activeIcon: Icons.nightlight_round),
    _NavItem(label: 'Progress', icon: Icons.trending_up_rounded, activeIcon: Icons.trending_up_rounded),
    _NavItem(label: 'Tantrum', icon: Icons.psychology_outlined, activeIcon: Icons.psychology_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final reduceTransparency =
        MediaQuery.of(context).accessibleNavigation; // proxy for reduce-transparency

    final barFill = reduceTransparency
        ? T.pal.bgDeep
        : T.pal.bgDeep.withValues(alpha: 0.80);

    return ClipRect(
      child: BackdropFilter(
        filter: reduceTransparency
            ? ImageFilter.blur()
            : ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
        child: Container(
          height: _barHeight + bottomPadding,
          padding: EdgeInsets.only(bottom: bottomPadding),
          decoration: BoxDecoration(
            color: barFill,
            border: Border(
              top: BorderSide(
                color: T.glass.border,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final isActive = i == currentIndex;

              return Expanded(
                child: Semantics(
                  label: '${item.label} tab',
                  selected: isActive,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(i),
                    child: _NavTab(
                      item: item,
                      isActive: isActive,
                      reduceMotion: reduceMotion,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.item,
    required this.isActive,
    required this.reduceMotion,
  });

  final _NavItem item;
  final bool isActive;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? T.pal.accent : T.pal.textTertiary;
    final duration = reduceMotion ? Duration.zero : T.anim.fast;

    return SizedBox(
      height: SettleBottomNav._barHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selection pill behind icon+label
          AnimatedContainer(
            duration: reduceMotion ? Duration.zero : T.anim.normal,
            curve: Curves.easeOut,
            width: isActive ? 64 : 0,
            height: isActive ? 32 : 0,
            decoration: BoxDecoration(
              color: isActive ? T.glass.fillAccent : Colors.transparent,
              borderRadius: BorderRadius.circular(T.radius.pill),
            ),
          ),
          // Icon + label
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: duration,
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  key: ValueKey('${item.label}_$isActive'),
                  size: 22,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              AnimatedDefaultTextStyle(
                duration: duration,
                style: T.type.caption.copyWith(
                  color: color,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(item.label),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
