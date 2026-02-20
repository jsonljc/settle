import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/tantrum_profile.dart';
import '../../providers/tantrum_providers.dart';
import '../../tantrum/services/tantrum_insights_service.dart';
import '../../widgets/glass_card.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/tantrum_sub_nav.dart';

class TantrumInsightsScreen extends ConsumerWidget {
  const TantrumInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(tantrumEventsProvider);
    final unlocked = ref.watch(tantrumInsightsUnlockedProvider);
    final lines = ref.watch(tantrumInsightsLinesProvider);
    final remaining = (TantrumInsightsService.unlockThreshold - events.length)
        .clamp(0, 99);

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SettleSpacing.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Insights',
                  subtitle: 'Patterns become clear with quick logs',
                  fallbackRoute: '/tantrum',
                ),
                const SizedBox(height: 12),
                const TantrumSubNav(
                  currentSegment: TantrumSubNav.segmentInsights,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: unlocked
                      ? _InsightsView(lines: lines, events: events)
                      : _LockedInsightsView(
                          loggedCount: events.length,
                          remainingCount: remaining,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LockedInsightsView extends StatelessWidget {
  const _LockedInsightsView({
    required this.loggedCount,
    required this.remainingCount,
  });

  final int loggedCount;
  final int remainingCount;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        GlassCardAccent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Insights unlock at 5 logs', style: SettleTypography.heading),
              const SizedBox(height: 8),
              Text(
                remainingCount == 0
                    ? 'You unlocked insights. Keep logging to sharpen the pattern.'
                    : 'You are $remainingCount log${remainingCount == 1 ? '' : 's'} away from your first pattern insight.',
                style: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _UnlockProgress(loggedCount: loggedCount),
        const SizedBox(height: 12),
        GlassCard(
          child: Text(
            'You may notice better insight when each moment is logged the same quick way.',
            style: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
          ),
        ),
      ],
    );
  }
}

class _UnlockProgress extends StatelessWidget {
  const _UnlockProgress({required this.loggedCount});

  final int loggedCount;

  @override
  Widget build(BuildContext context) {
    final active = loggedCount.clamp(0, TantrumInsightsService.unlockThreshold);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progress', style: SettleTypography.body.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            children: List.generate(TantrumInsightsService.unlockThreshold, (
              i,
            ) {
              final on = i < active;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i == 4 ? 0 : 6),
                  height: 10,
                  decoration: BoxDecoration(
                    color: on
                        ? SettleColors.nightAccent.withValues(alpha: 0.6)
                        : SettleSurfaces.cardDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: on
                          ? SettleColors.nightAccent.withValues(alpha: 0.5)
                          : SettleSurfaces.cardBorderDark,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '$active / ${TantrumInsightsService.unlockThreshold} logs',
            style: SettleTypography.caption.copyWith(color: SettleColors.nightSoft),
          ),
        ],
      ),
    );
  }
}

class _InsightsView extends StatelessWidget {
  const _InsightsView({required this.lines, required this.events});

  final List<String> lines;
  final List<TantrumEvent> events;

  @override
  Widget build(BuildContext context) {
    final byBucket = <DayBucket, int>{for (final b in DayBucket.values) b: 0};
    for (final e in events) {
      final bucket = DayBucket.fromDateTime(e.timestamp);
      byBucket[bucket] = (byBucket[bucket] ?? 0) + 1;
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pattern insights', style: SettleTypography.heading),
              const SizedBox(height: 8),
              Text(
                'Based on your recent logs',
                style: SettleTypography.caption.copyWith(
                  color: SettleColors.nightSoft,
                ),
              ),
              const SizedBox(height: 12),
              ...lines.asMap().entries.map(
                (entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom: entry.key == lines.length - 1 ? 0 : 10,
                  ),
                  child: _InsightLine(text: entry.value),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Time pattern', style: SettleTypography.body.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ...DayBucket.values.map(
                (bucket) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _BucketRow(
                    label: bucket.label,
                    value: byBucket[bucket] ?? 0,
                    maxValue: _maxBucket(byBucket),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  int _maxBucket(Map<DayBucket, int> values) {
    var max = 1;
    for (final value in values.values) {
      if (value > max) max = value;
    }
    return max;
  }
}

class _InsightLine extends StatelessWidget {
  const _InsightLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: SettleColors.nightAccent.withValues(alpha: 0.8),
              shape: BoxShape.circle,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
          ),
        ),
      ],
    );
  }
}

class _BucketRow extends StatelessWidget {
  const _BucketRow({
    required this.label,
    required this.value,
    required this.maxValue,
  });

  final String label;
  final int value;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final fill = maxValue == 0 ? 0.0 : value / maxValue;
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(
            label,
            style: SettleTypography.caption.copyWith(color: SettleColors.nightSoft),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fill,
              minHeight: 8,
              backgroundColor: SettleSurfaces.cardDark,
              valueColor: AlwaysStoppedAnimation(
                SettleColors.nightAccent.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 18,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: SettleTypography.caption.copyWith(color: SettleColors.nightSoft),
          ),
        ),
      ],
    );
  }
}
