import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/approach.dart';
import '../models/sleep_session.dart';
import '../providers/profile_provider.dart';
import '../providers/session_provider.dart';
import '../theme/glass_components.dart';
import '../theme/reduce_motion.dart';
import '../theme/settle_design_system.dart';
import '../theme/settle_tokens.dart';
import '../widgets/gradient_background.dart';
import '../widgets/calm_loading.dart';
import '../widgets/empty_state.dart';
import '../widgets/screen_header.dart';
import '../widgets/settle_disclosure.dart';

final _sleepHistoryProvider = FutureProvider<List<SleepSession>>((ref) async {
  ref.watch(sessionProvider);
  return ref.read(sessionProvider.notifier).history;
});

/// Logs screen — real logged data only.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(_sleepHistoryProvider);
    final isPlanTab = _tabController.index == 0;
    const planRoute = '/plan';
    const learnRoute = '/library/learn';

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Logs',
                  subtitle: 'Day and week logs in one place.',
                ),
                const SizedBox(height: 20),
                _GlassTabBar(controller: _tabController),
                const SizedBox(height: 20),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _PlanTab(ref: ref, historyAsync: historyAsync),
                      _WeekTab(historyAsync: historyAsync),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCardAccent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Next step', style: T.type.h3),
                      const SizedBox(height: 8),
                      Text(
                        'Adjust this week\'s plan or review why it works.',
                        style: T.type.caption.copyWith(
                          color: T.pal.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GlassCta(
                        label: isPlanTab ? 'Open Plan Focus' : 'Open Learn Q&A',
                        onTap: () =>
                            context.push(isPlanTab ? planRoute : learnRoute),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () =>
                            context.push(isPlanTab ? learnRoute : planRoute),
                        child: Text(
                          isPlanTab ? 'Open Learn Q&A' : 'Open Plan Focus',
                          style: T.type.caption.copyWith(
                            color: T.pal.textTertiary,
                            decoration: TextDecoration.underline,
                            decorationColor: T.pal.textTertiary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassTabBar extends StatelessWidget {
  const _GlassTabBar({required this.controller});
  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: T.glass.fill,
        borderRadius: BorderRadius.circular(T.radius.pill),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: T.glass.fillAccent,
          borderRadius: BorderRadius.circular(T.radius.pill),
          border: Border.all(color: T.pal.accent.withValues(alpha: 0.3)),
        ),
        dividerColor: Colors.transparent,
        labelColor: T.pal.textPrimary,
        unselectedLabelColor: T.pal.textTertiary,
        labelStyle: SettleTypography.body.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: T.type.caption,
        indicatorSize: TabBarIndicatorSize.tab,
        tabs: const [
          Tab(text: 'Plan'),
          Tab(text: 'Week'),
        ],
      ),
    );
  }
}

class _PlanTab extends StatelessWidget {
  const _PlanTab({required this.ref, required this.historyAsync});

  final WidgetRef ref;
  final AsyncValue<List<SleepSession>> historyAsync;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final bracket = profile?.ageBracket ?? AgeBracket.fourToFiveMonths;
    final (lo, hi) = bracket.wakeWindowMinutes;

    return historyAsync.when(
      loading: () => const CalmLoading(message: 'Loading today\'s logs…'),
      error: (_, __) => _ErrorCard(
        message: 'Could not load today\'s data. Try again in a moment.',
      ),
      data: (history) {
        final now = DateTime.now();
        final dayStart = _startOfDay(now);
        final dayEnd = dayStart.add(const Duration(days: 1));
        final todaySessions =
            history
                .where(
                  (s) =>
                      !s.startedAt.isBefore(dayStart) &&
                      s.startedAt.isBefore(dayEnd),
                )
                .toList()
              ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

        final totalToday = todaySessions.fold<Duration>(
          Duration.zero,
          (sum, session) => sum + session.duration,
        );

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TARGET',
                      style: T.type.overline.copyWith(
                        color: T.pal.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatBlock(value: '${bracket.naps}', label: 'naps'),
                        const SizedBox(width: 24),
                        _StatBlock(
                          value:
                              '${lo ~/ 60}h${lo % 60 > 0 ? ' ${lo % 60}m' : ''}–${hi ~/ 60}h${hi % 60 > 0 ? ' ${hi % 60}m' : ''}',
                          label: 'wake window',
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      bracket.label,
                      style: T.type.caption.copyWith(color: T.pal.textTertiary),
                    ),
                  ],
                ),
              ).entryFadeIn(context, delay: const Duration(milliseconds: 150)),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY SO FAR',
                      style: T.type.overline.copyWith(
                        color: T.pal.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${todaySessions.length} sleep sessions logged',
                      style: T.type.h3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDuration(totalToday),
                      style: T.type.body.copyWith(color: T.pal.textSecondary),
                    ),
                  ],
                ),
              ).entryFadeIn(context, delay: const Duration(milliseconds: 190)),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TIMELINE',
                      style: T.type.overline.copyWith(
                        color: T.pal.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (todaySessions.isEmpty)
                      EmptyState(
                        message: 'No sleep logs yet today.',
                        actionLabel: 'Log a session',
                        onAction: () => context.push('/sleep'),
                      )
                    else
                      ...todaySessions.map(
                        (session) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SessionRow(session: session),
                        ),
                      ),
                  ],
                ),
              ).entryFadeIn(context, delay: const Duration(milliseconds: 230)),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _WeekTab extends StatelessWidget {
  const _WeekTab({required this.historyAsync});

  final AsyncValue<List<SleepSession>> historyAsync;

  @override
  Widget build(BuildContext context) {
    return historyAsync.when(
      loading: () => const CalmLoading(message: 'Loading weekly data…'),
      error: (_, __) => _ErrorCard(
        message: 'Could not load weekly data. Try again in a moment.',
      ),
      data: (history) {
        final weekData = _buildLast7Days(history);
        final totalMinutes = weekData.fold<int>(0, (sum, d) => sum + d.minutes);
        final hasData = totalMinutes > 0;
        final avgHours = (totalMinutes / 7) / 60;
        final firstHalf = weekData.take(3).map((d) => d.minutes).toList();
        final secondHalf = weekData.skip(4).map((d) => d.minutes).toList();
        final firstAvg = firstHalf.isEmpty
            ? 0
            : firstHalf.reduce((a, b) => a + b) / firstHalf.length;
        final secondAvg = secondHalf.isEmpty
            ? 0
            : secondHalf.reduce((a, b) => a + b) / secondHalf.length;
        final trendingUp = secondAvg >= firstAvg;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              if (hasData)
                (trendingUp
                        ? GlassCardTeal(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.trending_up_rounded,
                                  size: 20,
                                  color: T.pal.teal,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Sleep trending upward this week',
                                  style: SettleTypography.body.copyWith(
                                    color: T.pal.teal,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : GlassCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.trending_flat_rounded,
                                      size: 20,
                                      color: T.pal.textSecondary,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Building consistency this week',
                                      style: SettleTypography.body.copyWith(
                                        color: T.pal.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              as Widget)
                    .entryFadeIn(
                      context,
                      delay: const Duration(milliseconds: 150),
                    )
              else
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  child: EmptyState(
                    message:
                        'Log sleep sessions this week to unlock trend insights.',
                    actionLabel: 'Start logging',
                    onAction: () => context.push('/sleep'),
                  ),
                ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WEEKLY SUMMARY',
                      style: T.type.overline.copyWith(
                        color: T.pal.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${avgHours.toStringAsFixed(1)}h average/day',
                      style: T.type.h3,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${weekData.fold<int>(0, (sum, d) => sum + d.sessions)} sessions in 7 days',
                      style: T.type.body.copyWith(color: T.pal.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SLEEP HOURS (LAST 7 DAYS)',
                      style: T.type.overline.copyWith(
                        color: T.pal.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 140,
                      child: _BarChart(
                        values: weekData.map((d) => d.minutes / 60.0).toList(),
                        labels: weekData.map((d) => d.label).toList(),
                        todayIdx: 6,
                        maxY: 12,
                        suffix: 'h',
                        barColor: T.pal.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SettleDisclosure(
                  title: 'More weekly details (optional)',
                  subtitle: 'Session count chart.',
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'SESSION COUNT (LAST 7 DAYS)',
                      style: T.type.overline.copyWith(
                        color: T.pal.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: _BarChart(
                        values: weekData
                            .map((d) => d.sessions.toDouble())
                            .toList(),
                        labels: weekData.map((d) => d.label).toList(),
                        todayIdx: 6,
                        maxY: 6,
                        suffix: '',
                        barColor: T.pal.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final SleepSession session;

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final start = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(session.startedAt),
      alwaysUse24HourFormat: false,
    );
    final endDate = session.endedAt ?? DateTime.now();
    final end = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(endDate),
      alwaysUse24HourFormat: false,
    );

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$start → $end', style: T.type.label),
              const SizedBox(height: 2),
              Text(
                _formatDuration(session.duration),
                style: T.type.caption.copyWith(color: T.pal.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: session.isNight ? T.glass.fillTeal : T.glass.fillAccent,
            borderRadius: BorderRadius.circular(T.radius.pill),
          ),
          child: Text(
            session.isNight ? 'Night' : 'Nap',
            style: T.type.caption.copyWith(
              color: session.isNight ? T.pal.teal : T.pal.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: T.type.h3),
        const SizedBox(height: 2),
        Text(label, style: T.type.caption.copyWith(color: T.pal.textSecondary)),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        child: Text(
          message,
          style: T.type.body.copyWith(color: T.pal.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.values,
    required this.labels,
    required this.todayIdx,
    required this.maxY,
    required this.suffix,
    required this.barColor,
  });

  final List<double> values;
  final List<String> labels;
  final int todayIdx;
  final double maxY;
  final String suffix;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 3,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: T.glass.border, strokeWidth: 0.5);
          },
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox.shrink();
                return Text(
                  '${value.toInt()}$suffix',
                  style: T.type.overline.copyWith(
                    color: T.pal.textTertiary,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Text(
                  labels[i],
                  style: T.type.overline.copyWith(
                    color: i == todayIdx
                        ? T.pal.textPrimary
                        : T.pal.textTertiary,
                    fontWeight: i == todayIdx
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: values.asMap().entries.map((entry) {
          final i = entry.key;
          final v = entry.value;
          final isToday = i == todayIdx;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: v,
                width: 16,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                gradient: isToday
                    ? LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [barColor.withValues(alpha: 0.5), barColor],
                      )
                    : null,
                color: isToday ? null : barColor.withValues(alpha: 0.3),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _DaySleepData {
  const _DaySleepData({
    required this.label,
    required this.minutes,
    required this.sessions,
  });

  final String label;
  final int minutes;
  final int sessions;
}

List<_DaySleepData> _buildLast7Days(List<SleepSession> history) {
  final now = DateTime.now();
  final today = _startOfDay(now);
  final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final buckets = List<_DaySleepData>.generate(7, (index) {
    final day = today.subtract(Duration(days: 6 - index));
    final weekday = day.weekday; // 1..7
    return _DaySleepData(label: labels[weekday - 1], minutes: 0, sessions: 0);
  });

  final mutableMinutes = List<int>.filled(7, 0);
  final mutableSessions = List<int>.filled(7, 0);

  for (final session in history) {
    final day = _startOfDay(session.startedAt);
    final diff = today.difference(day).inDays;
    if (diff < 0 || diff > 6) continue;
    final idx = 6 - diff;
    mutableMinutes[idx] += session.duration.inMinutes;
    mutableSessions[idx] += 1;
  }

  return List<_DaySleepData>.generate(7, (index) {
    return _DaySleepData(
      label: buckets[index].label,
      minutes: mutableMinutes[index],
      sessions: mutableSessions[index],
    );
  });
}

DateTime _startOfDay(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

String _formatDuration(Duration duration) {
  final totalMinutes = duration.inMinutes;
  final h = totalMinutes ~/ 60;
  final m = totalMinutes % 60;
  if (h == 0) return '${m}m total';
  if (m == 0) return '${h}h total';
  return '${h}h ${m}m total';
}
