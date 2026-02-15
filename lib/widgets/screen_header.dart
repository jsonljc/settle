import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/settle_tokens.dart';

/// Standardized screen header: back arrow + h2 title + optional subtitle
/// and optional trailing widget.
///
/// Pattern per UX spec: overline-style label is omitted (screens use h2 only).
/// Spacing: 12px top, 8px below title row, 4px below subtitle if present.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.fallbackRoute = '/now',
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  /// Where back navigates when there is nothing to pop.
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            GestureDetector(
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
            Expanded(
              child: Text(
                title,
                style: T.type.h2,
                overflow: TextOverflow.ellipsis,
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
