import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/settle_design_system.dart';

/// Empty state: single line, Inter 14px, ink400, centered.
///
/// Optional action link below the message. No tutorial, no icons unless needed.
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

  static TextStyle get _emptyTextStyle => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.006,
        color: SettleColors.ink400,
      );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? SettleColors.nightMuted : SettleColors.ink400;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            style: _emptyTextStyle.copyWith(color: color),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onAction,
              child: Text(
                '$actionLabel →',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                  color: isDark ? SettleColors.nightAccent : SettleColors.sage600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
