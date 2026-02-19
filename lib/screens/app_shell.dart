import 'dart:ui';

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
            icon: Icons.more_horiz_rounded,
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
            icon: Icons.group_outlined,
            title: 'Family',
            subtitle: 'Shared rhythm, scripts, and activity.',
            onTap: () => Navigator.of(context).pop(_ShellQuickAction.family),
          ),
          const SettleGap.sm(),
          _ShellQuickActionTile(
            icon: Icons.tune_rounded,
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
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open $title',
      child: Material(
        color: SettleGlassLight.backgroundStrong,
        borderRadius: BorderRadius.circular(SettleRadii.sm),
        child: InkWell(
          borderRadius: BorderRadius.circular(SettleRadii.sm),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(SettleSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: SettleColors.ink700),
                const SettleGap.md(),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: SettleTypography.label.copyWith(
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
                const SettleGap.sm(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: SettleColors.ink400,
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
