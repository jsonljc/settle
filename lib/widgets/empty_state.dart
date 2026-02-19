import 'package:flutter/material.dart';

import '../theme/settle_design_system.dart';
import 'settle_tappable.dart';

/// Empty state with optional icon, warm supporting text, and optional action CTA.
///
/// Provides visual warmth instead of clinical emptiness. Uses subtle sage-tinted
/// icon circle when [icon] is provided. Action uses SettleTappable (48px min
/// target, haptics, semantics).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.icon,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final supportingColor = SettleSemanticColors.supporting(context);
    final accentColor = SettleSemanticColors.accent(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SettleSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.08),
              ),
              child: Icon(icon, size: 24, color: accentColor.withValues(alpha: 0.5)),
            ),
            const SizedBox(height: SettleSpacing.md),
          ],
          Text(
            message,
            style: SettleTypography.body.copyWith(color: supportingColor),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: SettleSpacing.md),
            SettleTappable(
              semanticLabel: actionLabel!,
              onTap: onAction!,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: SettleSpacing.sm,
                  horizontal: SettleSpacing.sm,
                ),
                child: Text(
                  '$actionLabel \u2192',
                  style: SettleTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: accentColor,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
