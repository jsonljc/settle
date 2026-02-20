import 'package:flutter/material.dart';

import '../models/rhythm_models.dart';
import '../theme/settle_design_system.dart';
import 'solid_card.dart';
import 'settle_cta.dart';
import 'settle_gap.dart';

/// Compact "Today rhythm" card for Home (Now tab): Wake, First nap, Bedtime,
/// next up, confidence, and Sleep tonight guidance CTA.
/// Matches the schedule-focused design (time on the right, label on the left).
class TodayRhythmCard extends StatelessWidget {
  const TodayRhythmCard({
    super.key,
    required this.schedule,
    required this.ageMonths,
    required this.onSleepTonightTap,
  });

  final DaySchedule? schedule;
  final int ageMonths;
  final VoidCallback onSleepTonightTap;

  static String _formatClock(BuildContext context, int minutes) {
    final normalized = ((minutes % 1440) + 1440) % 1440;
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }

  static String _relaxedLabel(RhythmScheduleBlock block) {
    return switch (block.id) {
      'wake' => 'Morning wake',
      'nap1' => 'Late morning nap',
      'nap2' => 'Early afternoon nap',
      'nap3' => 'Late afternoon nap',
      'nap4' => 'Late-day catnap',
      'bedtime' => 'Bedtime',
      _ => block.label,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (schedule == null || schedule!.blocks.isEmpty) {
      return const SizedBox.shrink();
    }

    final blocks = schedule!.blocks;
    final wake = blocks.firstWhere(
          (b) => b.id == 'wake',
          orElse: () => blocks.first,
        );
    final firstNap = blocks.firstWhere(
          (b) => b.id.startsWith('nap'),
          orElse: () => blocks.first,
        );
    final bedtime = blocks.firstWhere(
          (b) => b.id == 'bedtime',
          orElse: () => blocks.last,
        );
    final nowMinutes = (DateTime.now().hour * 60) + DateTime.now().minute;
    final nextUp = blocks
        .where((b) => b.id != 'wake')
        .where((b) =>
            ((b.windowEndMinutes - nowMinutes + 1440) % 1440) <= 720)
        .fold<RhythmScheduleBlock?>(null, (best, current) {
      final bestDiff = best == null
          ? 9999
          : ((best.windowStartMinutes - nowMinutes + 1440) % 1440);
      final currentDiff =
          ((current.windowStartMinutes - nowMinutes + 1440) % 1440);
      if (best == null || currentDiff < bestDiff) return current;
      return best;
    });
    final target = nextUp ?? bedtime;

    return SolidCard(
      color: SettleSurfaces.tintDusk,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Today rhythm', style: SettleTypography.heading),
          const SettleGap.xs(),
          Text(
            'Built for $ageMonths months. Repeat this through the week.',
            style: SettleTypography.caption.copyWith(
              color: SettleColors.nightSoft,
            ),
          ),
          const SettleGap.md(),
          _ScheduleRow(
            label: 'Wake',
            value: _formatClock(context, wake.centerlineMinutes),
          ),
          const SettleGap.sm(),
          _ScheduleRow(
            label: 'First nap',
            value: _formatClock(context, firstNap.centerlineMinutes),
          ),
          const SettleGap.sm(),
          _ScheduleRow(
            label: 'Bedtime',
            value: _formatClock(context, bedtime.centerlineMinutes),
          ),
          const SettleGap.md(),
          Text(
            'Next up: ${_relaxedLabel(target)} around ${_formatClock(context, target.centerlineMinutes)}',
            style: SettleTypography.caption.copyWith(
              color: SettleColors.nightSoft,
            ),
          ),
          const SettleGap.sm(),
          Text(
            'How sure are we? ${schedule!.confidence.label}',
            style: SettleTypography.caption.copyWith(
              color: SettleColors.nightSoft,
            ),
          ),
          const SettleGap.xs(),
          Text(
            'Based on recent logging and pattern stability.',
            style: SettleTypography.caption.copyWith(
              color: SettleColors.nightSoft,
            ),
          ),
          const SettleGap.md(),
          SettleCta(
            label: 'Sleep tonight guidance',
            compact: true,
            onTap: onSleepTonightTap,
          ),
        ],
      ),
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: SettleTypography.caption.copyWith(
              color: SettleColors.nightSoft,
            ),
          ),
        ),
        const SizedBox(width: SettleSpacing.sm),
        Flexible(
          child: Text(
            value,
            style: SettleTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: SettleColors.nightText,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
