import 'package:flutter/material.dart';

import '../theme/settle_tokens.dart';

/// Guided empty state with optional CTA.
///
/// Pattern: calm message + optional action link.
/// Used wherever a list or section has no data yet.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData? icon;

  /// If provided, renders a tappable CTA below the message.
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 28, color: T.pal.textTertiary),
            const SizedBox(height: 10),
          ],
          Text(
            message,
            style: T.type.body.copyWith(color: T.pal.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onAction,
              child: Text(
                '$actionLabel →',
                style: T.type.label.copyWith(color: T.pal.accent),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
