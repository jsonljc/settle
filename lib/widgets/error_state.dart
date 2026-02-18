import 'package:flutter/material.dart';

import '../theme/settle_design_system.dart';
import 'glass_pill.dart';

/// Error state with optional retry. Use in AsyncValue.error branches.
///
/// Shows [message] and, when [onRetry] is non-null, a "Try again" [GlassPill]
/// (48px min height, haptics, Semantics button).
class SettleErrorState extends StatelessWidget {
  const SettleErrorState({
    super.key,
    required this.message,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final variant = isDark
        ? GlassPillVariant.primaryDark
        : GlassPillVariant.primaryLight;
    final color = isDark ? SettleColors.nightSoft : SettleColors.ink500;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: SettleSpacing.xl,
        horizontal: SettleSpacing.screenPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: SettleTypography.body.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: SettleSpacing.lg),
            Semantics(
              button: true,
              label: 'Try again',
              child: GlassPill(
                label: 'Try again',
                onTap: onRetry!,
                variant: variant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
