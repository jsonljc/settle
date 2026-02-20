import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/profile_provider.dart';
import '../providers/release_rollout_provider.dart';
import '../services/release_metrics_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/settle_cta.dart';
import '../theme/settle_design_system.dart';
import '../widgets/gradient_background.dart';
import '../widgets/release_surfaces.dart';
import '../widgets/screen_header.dart';
import '../widgets/settle_tappable.dart';

class ReleaseMetricsScreen extends ConsumerStatefulWidget {
  const ReleaseMetricsScreen({super.key});

  @override
  ConsumerState<ReleaseMetricsScreen> createState() =>
      _ReleaseMetricsScreenState();
}

class _ReleaseMetricsScreenState extends ConsumerState<ReleaseMetricsScreen> {
  final _service = const ReleaseMetricsService();
  Future<ReleaseMetricsSnapshot>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final childId = ref.read(profileProvider)?.createdAt;
    _future = _service.loadSnapshot(childId: childId);
  }

  String _pct(double? value) {
    if (value == null) return '—';
    return '${(value * 100).toStringAsFixed(0)}%';
  }

  String _secs(double? value) {
    if (value == null) return '—';
    return '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}s';
  }

  @override
  Widget build(BuildContext context) {
    final rollout = ref.watch(releaseRolloutProvider);
    if (!rollout.isLoading && !rollout.metricsDashboardEnabled) {
      return const FeaturePausedView(title: 'Release Metrics');
    }

    final childName = ref.watch(profileProvider)?.name ?? 'Current child';

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
                ScreenHeader(
                  title: 'Release Metrics',
                  trailing: SettleTappable(
                    semanticLabel: 'Refresh',
                    onTap: () => setState(_reload),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: SettleColors.nightMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$childName · 14-day operational window',
                  style: SettleTypography.caption.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: SettleColors.nightSoft,
                  ),
                ),
                const SizedBox(height: 4),
                const BehavioralScopeNotice(),
                const SizedBox(height: 14),
                Expanded(
                  child: FutureBuilder<ReleaseMetricsSnapshot>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator.adaptive(),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Center(
                          child: GlassCard(
                            child: Text(
                              'Unable to load release metrics.',
                              style: SettleTypography.body.copyWith(
                                color: SettleColors.nightSoft,
                              ),
                            ),
                          ),
                        );
                      }
                      final m = snapshot.data!;
                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _MetricCard(
                            title: 'Sleep adoption (14d)',
                            value: _pct(m.sleepAdoptionRate),
                            target: 'steady growth',
                            detail:
                                '${m.sleepActiveDays}/${m.windowDays} day(s) with Sleep Tonight activity.',
                          ),
                          const SizedBox(height: 10),
                          _MetricCard(
                            title: 'Sleep time-to-guidance',
                            value: _secs(m.sleepTimeToGuidanceMedianSeconds),
                            target: '<20s',
                            detail:
                                'Median from ${m.sleepTimeToGuidanceSamples} first-guidance renders.',
                            pass: m.sleepTimeToGuidanceMedianSeconds == null
                                ? null
                                : m.sleepTimeToGuidanceMedianSeconds! < 20,
                          ),
                          const SizedBox(height: 10),
                          _MetricCard(
                            title: 'Sleep recap completion',
                            value: _pct(m.sleepRecapCompletionRate),
                            target: 'maximize',
                            detail:
                                '${m.sleepMorningReviews}/${m.sleepPlans} nights with recap complete.',
                          ),
                          const SizedBox(height: 10),
                          _MetricCard(
                            title: 'Crash-free (7d)',
                            value: _pct(m.crashFreeRate7d),
                            target: '>=99.5%',
                            detail:
                                '${m.appSessions7d} session(s), ${m.appCrashes7d} crash event(s).',
                            pass: m.crashFreeMet7d,
                          ),
                          const SizedBox(height: 10),
                          _MetricCard(
                            title: 'Core funnel stable (7d)',
                            value: m.coreFunnelStable7d ? 'Stable' : 'Unstable',
                            target: 'stable',
                            detail:
                                'Tracks latency + recap completion + repeat use consistency.',
                            pass: m.coreFunnelStable7d,
                          ),
                          const SizedBox(height: 16),
                          _MetricCard(
                            title: 'Help Now time-to-output',
                            value: _secs(m.helpNowMedianSeconds),
                            target: '<10s',
                            detail:
                                'Median from ${m.helpNowMedianSamples} logged sessions.',
                            pass: m.helpNowMedianSeconds == null
                                ? null
                                : m.helpNowMedianSeconds! < 10,
                          ),
                          const SizedBox(height: 10),
                          _MetricCard(
                            title: 'Sleep Tonight time-to-start (legacy)',
                            value: _secs(m.sleepStartMedianSeconds),
                            target: '<60s',
                            detail:
                                'Median from ${m.sleepStartMedianSamples} plan starts.',
                            pass: m.sleepStartMedianSeconds == null
                                ? null
                                : m.sleepStartMedianSeconds! < 60,
                          ),
                          const SizedBox(height: 10),
                          _MetricCard(
                            title: 'Help Now outcome recording',
                            value: _pct(m.helpNowOutcomeRate),
                            target: 'maximize',
                            detail:
                                '${m.helpNowOutcomes}/${m.helpNowSessions} sessions with outcomes.',
                          ),
                          const SizedBox(height: 10),
                          _MetricCard(
                            title: 'Sleep morning review completion',
                            value: _pct(m.sleepMorningReviewRate),
                            target: 'maximize',
                            detail:
                                '${m.sleepMorningReviews}/${m.sleepPlans} nights with review complete.',
                          ),
                          const SizedBox(height: 10),
                          _MetricCard(
                            title: '7-day repeat use',
                            value: m.repeatUseMet ? 'Met' : 'Not met',
                            target: '>=2 active days',
                            detail:
                                '${m.repeatUseActiveDays7d} active day(s) with Help Now or Sleep Tonight.',
                            pass: m.repeatUseMet,
                          ),
                          const SizedBox(height: 10),
                          _MetricCard(
                            title: 'Family Rules accepted diffs',
                            value: '${m.familyDiffAccepted7d}',
                            target: 'weekly cadence',
                            detail: 'Accepted diffs in last 7 days.',
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.target,
    required this.detail,
    this.pass,
  });

  final String title;
  final String value;
  final String target;
  final String detail;
  final bool? pass;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (pass) {
      true => SettleColors.sage400,
      false => SettleColors.blush400,
      null => SettleColors.nightMuted,
    };
    final statusLabel = switch (pass) {
      true => 'On target',
      false => 'Off target',
      null => 'No signal',
    };

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: SettleTypography.heading.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(value, style: SettleTypography.heading.copyWith(fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(width: 10),
              Text(
                statusLabel,
                style: SettleTypography.caption.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Target: $target',
            style: SettleTypography.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: SettleColors.nightSoft),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: SettleTypography.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: SettleColors.nightMuted),
          ),
        ],
      ),
    );
  }
}
