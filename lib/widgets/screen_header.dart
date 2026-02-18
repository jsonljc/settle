import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/settle_design_system.dart';
import 'settle_tappable.dart';

/// Standardized screen header: optional back arrow + heading title + optional subtitle
/// and optional trailing widget.
///
/// Use [showBackButton: false] for root screens (e.g. Home) so the title stands alone.
/// Spacing: SettleSpacing.md top, sm below title row, xs below subtitle if present.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.fallbackRoute = '/plan',
    this.showBackButton = true,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Where back navigates when there is nothing to pop.
  final String fallbackRoute;

  /// When false, no back arrow (e.g. home tab root). Default true.
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryColor = isDark ? SettleColors.nightSoft : SettleColors.ink500;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: SettleSpacing.md),
        Row(
          children: [
            if (showBackButton) ...[
              SettleTappable(
                semanticLabel: 'Back',
                onTap: () => context.canPop()
                    ? context.pop()
                    : context.go(fallbackRoute),
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  size: 20,
                  color: secondaryColor,
                ),
              ),
              SizedBox(width: SettleSpacing.md),
            ],
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: SettleTypography.heading,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null) ...[
          SizedBox(height: SettleSpacing.sm),
          Text(
            subtitle!,
            style: SettleTypography.caption.copyWith(color: secondaryColor),
          ),
        ],
      ],
    );
  }
}
