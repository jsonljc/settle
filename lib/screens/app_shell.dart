import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/settle_design_system.dart';
import '../widgets/glass_nav_bar.dart';
import '../widgets/gradient_background.dart';
import '../widgets/nav_item.dart';
import '../widgets/settle_gap.dart';
import '../widgets/settle_modal_sheet.dart';

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
        .map((e) => GlassNavBarItem(
              icon: e.icon,
              activeIcon: e.activeIcon,
              label: e.label,
            ))
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

  static bool _showOverlayMenuForPath(String path) {
    final normalized = path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;
    return normalized == '/plan' ||
        normalized == '/sleep' ||
        normalized == '/library';
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final navVariant = _useDarkNavForPath(path)
        ? GlassNavBarVariant.dark
        : GlassNavBarVariant.light;
    final showOverlayMenu = _showOverlayMenuForPath(path);

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            _ShellOverlayActions(
              dark: navVariant == GlassNavBarVariant.dark,
              visible: showOverlayMenu,
            ),
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
  const _ShellOverlayActions({required this.dark, required this.visible});

  final bool dark;
  final bool visible;

  /// UXV2-008 / UXV2-009: Family and Settings only via this Menu (or deep link); no tab.
  Future<void> _openQuickActions(BuildContext context) async {
    final selected = await showSettleSheet<_ShellQuickAction>(
      context,
      child: const _ShellQuickActionsSheet(),
    );
    if (selected == null || !context.mounted) return;

    switch (selected) {
      case _ShellQuickAction.family:
        context.push('/family');
        break;
      case _ShellQuickAction.settings:
        context.push('/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(
            top: SettleSpacing.sm,
            right: SettleSpacing.sm,
          ),
          child: _ShellOverlayActionButton(
            label: 'Menu',
            semanticLabel: 'Open quick actions',
            dark: dark,
            onTap: () => _openQuickActions(context),
          ),
        ),
      ),
    );
  }
}

enum _ShellQuickAction { family, settings }

class _ShellQuickActionsSheet extends StatelessWidget {
  const _ShellQuickActionsSheet();

  @override
  Widget build(BuildContext context) {
    return SettleModalSheet(
      title: 'Quick actions',
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ShellQuickActionTile(
            title: 'Family',
            subtitle: 'Shared rhythm, scripts, and activity.',
            onTap: () => Navigator.of(context).pop(_ShellQuickAction.family),
          ),
          const SettleGap.sm(),
          _ShellQuickActionTile(
            title: 'Settings',
            subtitle: 'Child profile, methods, and notifications.',
            onTap: () => Navigator.of(context).pop(_ShellQuickAction.settings),
          ),
        ],
      ),
    );
  }
}

class _ShellQuickActionTile extends StatelessWidget {
  const _ShellQuickActionTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open $title',
      child: Material(
        color: SettleSurfaces.cardLight,
        borderRadius: BorderRadius.circular(SettleRadii.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(SettleRadii.sm),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(SettleSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: SettleTypography.subheading.copyWith(
                    color: SettleColors.ink900,
                  ),
                ),
                const SettleGap.xs(),
                Text(
                  subtitle,
                  style: SettleTypography.body.copyWith(
                    color: SettleColors.ink500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellOverlayActionButton extends StatelessWidget {
  const _ShellOverlayActionButton({
    required this.label,
    required this.semanticLabel,
    required this.onTap,
    required this.dark,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fill = dark ? SettleSurfaces.cardDark : SettleSurfaces.cardLight;
    final borderColor = dark
        ? SettleSurfaces.cardBorderDark
        : SettleColors.ink300.withValues(alpha: 0.15);
    final iconColor = dark ? SettleColors.nightText : SettleColors.ink700;

    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: fill,
        borderRadius: BorderRadius.circular(SettleRadii.pill),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(SettleRadii.pill),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(
              horizontal: SettleSpacing.md,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(SettleRadii.pill),
              border: Border.all(color: borderColor, width: 0.5),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: SettleTypography.label.copyWith(color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}
