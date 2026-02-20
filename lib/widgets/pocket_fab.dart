import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/settle_design_system.dart';

/// Solid FAB for Pocket — bottom-right, above bottom nav. Tap target 56px (≥44 a11y).
/// Used inside [PocketFABAndOverlay] which handles tap and modal.
class PocketFAB extends StatelessWidget {
  const PocketFAB({super.key, required this.onTap});

  final VoidCallback onTap;

  static const double _size = 56;

  static bool _useDarkStyleForPath(String path) {
    final normalized = path.toLowerCase();
    return normalized.contains('/sleep/tonight') ||
        normalized.contains('/plan/reset') ||
        normalized.contains('/plan/moment') ||
        normalized.contains('/plan/regulate') ||
        normalized == '/breathe';
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final isDark = _useDarkStyleForPath(path);
    final fill = isDark
        ? SettleSurfaces.cardDark
        : SettleSurfaces.cardLight;
    final border = isDark
        ? SettleSurfaces.cardBorderDark
        : SettleColors.ink300.withValues(alpha: 0.12);
    final iconColor = isDark ? SettleColors.nightText : SettleColors.ink700;

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const navBarHeight = 64.0;
    const fabMargin = SettleSpacing.lg;
    final top =
        MediaQuery.of(context).size.height -
        bottomPadding -
        navBarHeight -
        _size -
        fabMargin;

    return Positioned(
      top: top,
      right: fabMargin,
      child: Semantics(
        button: true,
        label: 'Open Pocket',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fill,
                border: Border.all(color: border, width: 1),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: iconColor,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
