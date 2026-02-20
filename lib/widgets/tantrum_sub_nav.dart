import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/settle_design_system.dart';
import 'settle_tappable.dart';

/// Sub-navigation for Tantrum tab: CAPTURE | DECK | INSIGHTS.
/// Use on capture/deck/insights surfaces.
class TantrumSubNav extends StatelessWidget {
  const TantrumSubNav({super.key, required this.currentSegment});

  static const segmentCapture = 'capture';
  // Backward alias used by older callsites.
  static const segmentNow = segmentCapture;
  static const segmentCards = 'cards';
  static const segmentInsights = 'insights';
  // Backward alias used by older callsites.
  static const segmentLearn = segmentInsights;

  final String currentSegment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _Segment(
            label: 'CAPTURE',
            active: currentSegment == segmentCapture,
            onTap: () => context.go('/tantrum/capture'),
          ),
          const SizedBox(width: 8),
          _Segment(
            label: 'DECK',
            active: currentSegment == segmentCards,
            onTap: () => context.go('/tantrum/deck'),
          ),
          const SizedBox(width: 8),
          _Segment(
            label: 'INSIGHTS',
            active: currentSegment == segmentInsights,
            onTap: () => context.go('/tantrum/insights'),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = SettleSemanticColors.accent(context);
    final fill = active
        ? accentColor.withValues(alpha: 0.10)
        : (isDark ? SettleSurfaces.cardDark : SettleColors.stone50);
    final borderColor = active
        ? accentColor
        : (isDark ? SettleSurfaces.cardBorderDark : SettleColors.ink300.withValues(alpha: 0.12));

    return SettleTappable(
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(SettleRadii.pill),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: SettleTypography.caption.copyWith(
            color: active
                ? accentColor
                : SettleSemanticColors.supporting(context),
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
