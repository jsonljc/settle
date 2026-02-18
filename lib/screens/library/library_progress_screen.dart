import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/usage_event.dart';
import '../../models/v2_enums.dart';
import '../../providers/profile_provider.dart';
import '../../providers/usage_events_provider.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_pill.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/screen_header.dart';

const int _minTrendDataPoints = 3;

class LibraryProgressScreen extends ConsumerWidget {
  const LibraryProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final events = ref.watch(usageEventsProvider);
    final scored =
        events.where((event) => _isTrendScored(event.outcome)).toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final now = DateTime.now();
    final thisWeek = _eventsInRange(
      scored,
      now: now,
      minDaysAgo: 0,
      maxDaysAgo: 6,
    );
    final lastWeek = _eventsInRange(
      scored,
      now: now,
      minDaysAgo: 7,
      maxDaysAgo: 13,
    );
    final workedThisWeek = thisWeek
        .where((event) => _isWorked(event.outcome))
        .length;
    final workedLastWeek = lastWeek
        .where((event) => _isWorked(event.outcome))
        .length;
    final notQuiteThisWeek = thisWeek
        .where((event) => event.outcome == UsageOutcome.didntWork)
        .length;
    final hasTrendData = scored.length >= _minTrendDataPoints;
    final dayBuckets = _buildDayBuckets(scored, now);
    final maxDayTotal = _maxDayTotal(dayBuckets);
    final methodLabel = profile?.approach.label ?? 'your current method';

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
                  title: 'Progress',
                  subtitle: 'A supportive weekly read of what is working.',
                  fallbackRoute: '/library',
                ),
                const SizedBox(height: SettleSpacing.lg),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!hasTrendData)
                          _ProgressNeedsDataCard(scoredCount: scored.length)
                        else ...[
                          _ProgressSummaryCard(
                            workedThisWeek: workedThisWeek,
                            workedLastWeek: workedLastWeek,
                            notQuiteThisWeek: notQuiteThisWeek,
                          ),
                          const SizedBox(height: SettleSpacing.sm),
                          _WeeklyBarsCard(
                            dayBuckets: dayBuckets,
                            maxDayTotal: maxDayTotal,
                          ),
                          const SizedBox(height: SettleSpacing.sm),
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Plan context',
                                  style: SettleTypography.heading,
                                ),
                                const SizedBox(height: SettleSpacing.sm),
                                Text(
                                  'You are currently using $methodLabel. Keep the same method for a few nights before changing course.',
                                  style: SettleTypography.body.copyWith(
                                    color: _supportingTextColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: SettleSpacing.sm),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Next step',
                                style: SettleTypography.heading,
                              ),
                              const SizedBox(height: SettleSpacing.sm),
                              Text(
                                'Review the timeline when something feels off, then run tonight with one consistent approach.',
                                style: SettleTypography.body.copyWith(
                                  color: _supportingTextColor(context),
                                ),
                              ),
                              const SizedBox(height: SettleSpacing.md),
                              GlassPill(
                                label: 'Open logs',
                                onTap: () => context.push('/library/logs'),
                                variant: GlassPillVariant.primaryLight,
                                expanded: true,
                              ),
                              const SizedBox(height: SettleSpacing.sm),
                              GlassPill(
                                label: 'Open Sleep Tonight',
                                onTap: () => context.push('/sleep/tonight'),
                                variant: GlassPillVariant.secondaryLight,
                                expanded: true,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: SettleSpacing.xl),
                      ],
                    ),
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

class _ProgressNeedsDataCard extends StatelessWidget {
  const _ProgressNeedsDataCard({required this.scoredCount});

  final int scoredCount;

  @override
  Widget build(BuildContext context) {
    final remaining = (_minTrendDataPoints - scoredCount).clamp(
      0,
      _minTrendDataPoints,
    );
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress appears after 3 check-ins',
            style: SettleTypography.heading,
          ),
          const SizedBox(height: SettleSpacing.sm),
          Text(
            scoredCount == 0
                ? 'Log how a script worked a few times, then trends will appear here.'
                : 'You have $scoredCount check-in${scoredCount == 1 ? '' : 's'}. Add $remaining more to unlock trend framing.',
            style: SettleTypography.body.copyWith(
              color: _supportingTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSummaryCard extends StatelessWidget {
  const _ProgressSummaryCard({
    required this.workedThisWeek,
    required this.workedLastWeek,
    required this.notQuiteThisWeek,
  });

  final int workedThisWeek;
  final int workedLastWeek;
  final int notQuiteThisWeek;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This week', style: SettleTypography.heading),
          const SizedBox(height: SettleSpacing.sm),
          Text(
            _trendMessage(
              workedLastWeek: workedLastWeek,
              workedThisWeek: workedThisWeek,
            ),
            style: SettleTypography.body,
          ),
          const SizedBox(height: SettleSpacing.sm),
          Text(
            '$notQuiteThisWeek "Not quite" checks this week.',
            style: SettleTypography.body.copyWith(
              color: _supportingTextColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBarsCard extends StatelessWidget {
  const _WeeklyBarsCard({required this.dayBuckets, required this.maxDayTotal});

  final List<_DayBucket> dayBuckets;
  final int maxDayTotal;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 7 days', style: SettleTypography.heading),
          const SizedBox(height: SettleSpacing.sm),
          Text(
            'Worked vs not quite check-ins.',
            style: SettleTypography.body.copyWith(
              color: _supportingTextColor(context),
            ),
          ),
          const SizedBox(height: SettleSpacing.md),
          SizedBox(
            height: 118,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final bucket in dayBuckets)
                  Expanded(
                    child: _DayBar(
                      worked: bucket.worked,
                      notQuite: bucket.notQuite,
                      label: bucket.label,
                      maxDayTotal: maxDayTotal,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.worked,
    required this.notQuite,
    required this.label,
    required this.maxDayTotal,
  });

  final int worked;
  final int notQuite;
  final String label;
  final int maxDayTotal;

  static const double _barWidth = 16;
  static const double _barHeight = 72;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final workedColor = brightness == Brightness.dark
        ? SettleColors.sage400
        : SettleColors.sage600;
    final notQuiteColor = brightness == Brightness.dark
        ? SettleColors.warmth400
        : SettleColors.warmth600;
    final railColor = brightness == Brightness.dark
        ? SettleGlassDark.backgroundStrong
        : SettleGlassLight.backgroundStrong;
    final workedHeight = maxDayTotal == 0
        ? 0.0
        : _barHeight * (worked / maxDayTotal);
    final notQuiteHeight = maxDayTotal == 0
        ? 0.0
        : _barHeight * (notQuite / maxDayTotal);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: _barWidth,
          height: _barHeight,
          decoration: BoxDecoration(
            color: railColor,
            borderRadius: BorderRadius.circular(SettleRadii.pill),
          ),
          alignment: Alignment.bottomCenter,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (notQuiteHeight > 0)
                Container(
                  width: _barWidth,
                  height: notQuiteHeight,
                  color: notQuiteColor.withValues(alpha: 0.75),
                ),
              if (workedHeight > 0)
                Container(
                  width: _barWidth,
                  height: workedHeight,
                  decoration: BoxDecoration(
                    color: workedColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(SettleRadii.pill),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: SettleSpacing.xs),
        Text(
          label,
          style: SettleTypography.caption.copyWith(
            color: _mutedTextColor(context),
          ),
        ),
      ],
    );
  }
}

class _DayBucket {
  const _DayBucket({
    required this.label,
    required this.worked,
    required this.notQuite,
  });

  final String label;
  final int worked;
  final int notQuite;
}

bool _isTrendScored(UsageOutcome? outcome) {
  return outcome == UsageOutcome.great ||
      outcome == UsageOutcome.okay ||
      outcome == UsageOutcome.didntWork;
}

bool _isWorked(UsageOutcome? outcome) {
  return outcome == UsageOutcome.great || outcome == UsageOutcome.okay;
}

List<UsageEvent> _eventsInRange(
  List<UsageEvent> events, {
  required DateTime now,
  required int minDaysAgo,
  required int maxDaysAgo,
}) {
  final today = DateTime(now.year, now.month, now.day);
  return events.where((event) {
    final day = DateTime(
      event.timestamp.year,
      event.timestamp.month,
      event.timestamp.day,
    );
    final daysAgo = today.difference(day).inDays;
    return daysAgo >= minDaysAgo && daysAgo <= maxDaysAgo;
  }).toList();
}

List<_DayBucket> _buildDayBuckets(List<UsageEvent> events, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final buckets = <_DayBucket>[];
  for (var offset = 6; offset >= 0; offset--) {
    final day = today.subtract(Duration(days: offset));
    final worked = events.where((event) {
      return _sameDay(event.timestamp, day) && _isWorked(event.outcome);
    }).length;
    final notQuite = events.where((event) {
      return _sameDay(event.timestamp, day) &&
          event.outcome == UsageOutcome.didntWork;
    }).length;
    buckets.add(
      _DayBucket(label: _weekdayLabel(day), worked: worked, notQuite: notQuite),
    );
  }
  return buckets;
}

int _maxDayTotal(List<_DayBucket> dayBuckets) {
  var max = 0;
  for (final bucket in dayBuckets) {
    final total = bucket.worked + bucket.notQuite;
    if (total > max) {
      max = total;
    }
  }
  return max == 0 ? 1 : max;
}

String _trendMessage({
  required int workedLastWeek,
  required int workedThisWeek,
}) {
  if (workedLastWeek == 0 && workedThisWeek == 0) {
    return 'You are building a baseline. Keep logging quick outcomes this week.';
  }
  if (workedThisWeek > workedLastWeek) {
    return 'Worked checks went from $workedLastWeek to $workedThisWeek. Consistency is starting to pay off.';
  }
  if (workedThisWeek == workedLastWeek) {
    return 'Worked checks held steady at $workedThisWeek. Staying consistent is still progress.';
  }
  return 'Worked checks are $workedThisWeek this week vs $workedLastWeek last week. Hard weeks happen; keep one approach tonight.';
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

String _weekdayLabel(DateTime date) {
  return switch (date.weekday) {
    DateTime.monday => 'Mo',
    DateTime.tuesday => 'Tu',
    DateTime.wednesday => 'We',
    DateTime.thursday => 'Th',
    DateTime.friday => 'Fr',
    DateTime.saturday => 'Sa',
    DateTime.sunday => 'Su',
    _ => '',
  };
}

Color _supportingTextColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? SettleColors.nightSoft : SettleColors.ink500;
}

Color _mutedTextColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? SettleColors.nightMuted : SettleColors.ink400;
}
