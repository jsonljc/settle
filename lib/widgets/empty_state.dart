import 'package:flutter/material.dart';

import '../theme/settle_design_system.dart';
import 'settle_tappable.dart';

/// Empty state: single line, Inter 14px, ink400, centered.
///
/// Optional action link below the message. No tutorial, no icons unless needed.
/// Action uses SettleTappable (48px min target, haptics, semantics).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final String message;

  /// If provided, renders a tappable CTA below the message.
  final String? actionLabel;
  final VoidCallback? onAction;

  static TextStyle get _emptyTextStyle =>
      SettleTypography.body.copyWith(color: SettleColors.ink400);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? SettleColors.nightMuted : SettleColors.ink400;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: SettleSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: _emptyTextStyle.copyWith(color: color),
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
                  '$actionLabel →',
                  style: SettleTypography.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? SettleColors.nightAccent
                        : SettleColors.sage600,
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
