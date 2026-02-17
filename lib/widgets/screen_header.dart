import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/settle_tokens.dart';
import 'settle_tappable.dart';

/// Standardized screen header: optional back arrow + h2 title + optional subtitle
/// and optional trailing widget.
///
/// Use [showBackButton: false] for root screens (e.g. Home) so the title stands alone.
/// Spacing: 12px top, 8px below title row, 4px below subtitle if present.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.fallbackRoute = '/now',
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
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
                  color: T.pal.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: T.type.h2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: T.type.caption.copyWith(color: T.pal.textSecondary),
          ),
        ],
      ],
    );
  }
}
