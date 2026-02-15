import 'package:flutter/material.dart';

import '../theme/glass_components.dart';
import '../widgets/settle_bottom_nav.dart';

/// Root scaffold for the 3-tab bottom navigation.
///
/// Each tab maintains its own navigation stack via the GoRouter ShellRoute.
/// The shell provides the SettleBottomNav and a settings gear icon.
class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.currentIndex,
    required this.onTabTap,
    required this.child,
  });

  final int currentIndex;
  final ValueChanged<int> onTabTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SettleBackground(
        child: child,
      ),
      bottomNavigationBar: SettleBottomNav(
        currentIndex: currentIndex,
        onTap: onTabTap,
      ),
    );
  }
}
