import 'package:flutter/material.dart';

import '../theme/glass_components.dart';
import '../widgets/settle_bottom_nav.dart';

/// Root scaffold for the bottom navigation shell.
///
/// Each tab maintains its own navigation stack via the GoRouter ShellRoute.
/// The shell provides the SettleBottomNav and a settings gear icon.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SettleBackground(
        child: Stack(
          fit: StackFit.expand,
          children: [child, if (overlay != null) overlay!],
        ),
      ),
      bottomNavigationBar: SettleBottomNav(
        currentIndex: currentIndex,
        onTap: onTabTap,
        items: navItems,
      ),
    );
  }
}
