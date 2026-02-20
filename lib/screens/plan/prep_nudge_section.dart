import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/pattern_insight.dart';
import '../../models/v2_enums.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_pill.dart';
import '../../theme/settle_design_system.dart';

class PrepNudgeSection extends StatelessWidget {
  const PrepNudgeSection({super.key, this.patterns = const []});

  final List<PatternInsight> patterns;

  @override
  Widget build(BuildContext context) {
    final timePatterns = patterns
        .where((p) => p.patternType == PatternType.time)
        .toList();
    final timePattern = timePatterns.isNotEmpty ? timePatterns.first : null;
    final approaching =
        timePattern != null && _isApproachingPatternTime(timePattern);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('When you\'re ready', style: SettleTypography.heading),
          const SizedBox(height: 6),
          Text(
            approaching
                ? '${timePattern.insight} Preview a script when you\'re ready.'
                : 'Preview a script for bedtime when you\'re ready.',
            style: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
          ),
          if (approaching) ...[
            const SizedBox(height: 12),
            GlassPill(
              label: 'Preview script',
              onTap: () => context.push('/plan'),
            ),
          ],
        ],
      ),
    );
  }

  /// True if current time is within ~1 hour of a pattern's time window (e.g. "4-6" and we're 3–6).
  bool _isApproachingPatternTime(PatternInsight p) {
    final now = DateTime.now();
    final hour = now.hour;
    final insight = p.insight;
    final match = RegExp(r'(\d{1,2})-(\d{1,2})').firstMatch(insight);
    if (match == null) return false;
    final start = int.tryParse(match.group(1) ?? '') ?? 0;
    final end = int.tryParse(match.group(2) ?? '') ?? 0;
    if (start >= end) return false;
    return hour >= start - 1 && hour <= end + 1;
  }
}
