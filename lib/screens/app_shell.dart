import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
          children: [child, if (overlay != null) overlay!],
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
