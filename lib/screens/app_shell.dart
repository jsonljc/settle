import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/settle_design_system.dart';
import '../widgets/glass_nav_bar.dart';
import '../widgets/gradient_background.dart';
import '../widgets/nav_item.dart';

/// Root scaffold for the bottom navigation shell.
///
/// Each tab maintains its own navigation stack via the GoRouter ShellRoute.
/// Uses GlassNavBar; nav items are converted from SettleBottomNavItem for compatibility.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.currentIndex,
    required this.onTabTap,
    required this.navItems,
    required this.child,
    this.overlay,
  });

  final int currentIndex;
  final ValueChanged<int> onTabTap;
  final List<SettleBottomNavItem> navItems;
  final Widget child;
  final Widget? overlay;

  static List<GlassNavBarItem> _toGlassNavItems(
    List<SettleBottomNavItem> items,
  ) {
    return items
        .map((e) => GlassNavBarItem(icon: e.icon, label: e.label))
        .toList();
  }

  static bool _useDarkNavForPath(String path) {
    final normalized = path.toLowerCase();
    return normalized.contains('/sleep/tonight') ||
        normalized.contains('/plan/reset') ||
        normalized.contains('/plan/moment') ||
        normalized.contains('/plan/regulate') ||
        normalized == '/breathe';
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final navVariant = _useDarkNavForPath(path)
        ? GlassNavBarVariant.dark
        : GlassNavBarVariant.light;

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            _ShellOverlayActions(dark: navVariant == GlassNavBarVariant.dark),
            if (overlay != null) overlay!,
          ],
        ),
      ),
      bottomNavigationBar: GlassNavBar(
        items: _toGlassNavItems(navItems),
        activeIndex: currentIndex,
        onTap: onTabTap,
        variant: navVariant,
      ),
    );
  }
}

class _ShellOverlayActions extends StatelessWidget {
  const _ShellOverlayActions({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(
            top: SettleSpacing.sm,
            right: SettleSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ShellOverlayActionButton(
                icon: Icons.group_outlined,
                semanticLabel: 'Open Family',
                dark: dark,
                onTap: () => context.push('/family'),
              ),
              const SizedBox(width: SettleSpacing.xs),
              _ShellOverlayActionButton(
                icon: Icons.tune_rounded,
                semanticLabel: 'Open Settings',
                dark: dark,
                onTap: () => context.push('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShellOverlayActionButton extends StatelessWidget {
  const _ShellOverlayActionButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    required this.dark,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool dark;

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final fill = dark
        ? SettleGlassDark.backgroundStrong
        : SettleGlassLight.backgroundStrong;
    final border = dark
        ? SettleGlassDark.borderStrong
        : SettleGlassLight.border;
    final iconColor = dark ? SettleColors.nightText : SettleColors.ink700;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Material(
            color: fill,
            child: InkWell(
              onTap: onTap,
              child: Container(
                width: _size,
                height: _size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: border, width: 0.8),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
