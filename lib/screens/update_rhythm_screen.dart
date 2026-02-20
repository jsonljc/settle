import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/approach.dart';
import '../models/rhythm_models.dart';
import '../providers/profile_provider.dart';
import '../providers/release_rollout_provider.dart';
import '../providers/rhythm_provider.dart';
import '../services/event_bus_service.dart';
import '../services/rhythm_engine_service.dart';
import '../widgets/solid_card.dart';
import '../widgets/settle_cta.dart';
import '../widgets/settle_tappable.dart';
import '../theme/settle_design_system.dart';
import '../widgets/gradient_background.dart';
import '../widgets/calm_loading.dart';
import '../widgets/release_surfaces.dart';
import '../widgets/screen_header.dart';
import '../widgets/settle_segmented_choice.dart';

class UpdateRhythmScreen extends ConsumerStatefulWidget {
  const UpdateRhythmScreen({super.key});

  @override
  ConsumerState<UpdateRhythmScreen> createState() => _UpdateRhythmScreenState();
}

class _UpdateRhythmScreenState extends ConsumerState<UpdateRhythmScreen> {
  String? _loadedChildId;
  bool _loadScheduled = false;

  int _step = 0;
  DateTime? _startedAt;
  bool _isSubmitting = false;

  TimeOfDay? _wakeTime;
  bool _wakeAsRange = false;

  String _napToday = 'not_sure';
  TimeOfDay? _napStart;
  TimeOfDay? _napEnd;
  TimeOfDay? _typicalNap;
  bool _daycareMode = false;

  String _bedtimeTarget = 'same'; // earlier/same/later

  int _ageMonthsFor(AgeBracket age) {
    return switch (age) {
      AgeBracket.newborn => 1,
      AgeBracket.twoToThreeMonths => 2,
      AgeBracket.fourToFiveMonths => 5,
      AgeBracket.sixToEightMonths => 7,
      AgeBracket.nineToTwelveMonths => 10,
      AgeBracket.twelveToEighteenMonths => 15,
      AgeBracket.nineteenToTwentyFourMonths => 21,
      AgeBracket.twoToThreeYears => 30,
      AgeBracket.threeToFourYears => 35,
      AgeBracket.fourToFiveYears => 35,
      AgeBracket.fiveToSixYears => 35,
    };
  }

  int _toMinutes(TimeOfDay t) => (t.hour * 60) + t.minute;

  String _formatTime(BuildContext context, int minutes) {
    final normalized = ((minutes % 1440) + 1440) % 1440;
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }

  Future<void> _pickWakeTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime ?? const TimeOfDay(hour: 6, minute: 45),
    );
    if (picked != null) {
      setState(() => _wakeTime = picked);
    }
  }

  Future<void> _pickTime(
    BuildContext context, {
    required TimeOfDay? current,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? TimeOfDay.now(),
    );
    if (picked != null) onPicked(picked);
  }

  Future<void> _loadIfNeeded() async {
    final profile = ref.read(profileProvider);
    if (profile == null) return;
    final childId = profile.createdAt;
    if (_loadedChildId == childId) return;
    _loadedChildId = childId;
    await ref
        .read(rhythmProvider.notifier)
        .load(childId: childId, ageMonths: _ageMonthsFor(profile.ageBracket));

    final schedule = ref.read(rhythmProvider).todaySchedule;
    if (schedule != null && _wakeTime == null) {
      final m = schedule.wakeTimeMinutes;
      _wakeTime = TimeOfDay(hour: m ~/ 60, minute: m % 60);
    }
    _startedAt ??= DateTime.now();
  }

  void _scheduleLoadIfNeeded() {
    if (_loadScheduled) return;
    _loadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScheduled = false;
      if (!mounted) return;
      _loadIfNeeded();
    });
  }

  bool _canContinue() {
    return switch (_step) {
      0 => _wakeTime != null,
      1 => _napToday != 'yes' || _napStart != null || _typicalNap != null,
      2 => true,
      _ => true,
    };
  }

  int? _napDurationHintMinutes() {
    if (_napStart == null || _napEnd == null) return null;
    final start = _toMinutes(_napStart!);
    final end = _toMinutes(_napEnd!);
    if (end >= start) return end - start;
    return (end + 1440) - start;
  }

  int? _napCountReality(int? currentNapTarget) {
    return switch (_napToday) {
      'yes' => currentNapTarget,
      'no' =>
        currentNapTarget == null ? null : (currentNapTarget - 1).clamp(1, 4),
      _ => null,
    };
  }

  RhythmUpdateIssue _issueFromAnswers({int? napDurationHintMinutes}) {
    if (_napToday == 'no') return RhythmUpdateIssue.shortNaps;
    if (napDurationHintMinutes != null && napDurationHintMinutes < 45) {
      return RhythmUpdateIssue.shortNaps;
    }
    if (_bedtimeTarget == 'earlier') return RhythmUpdateIssue.earlyWakes;
    if (_bedtimeTarget == 'later') return RhythmUpdateIssue.bedtimeBattles;
    if (_typicalNap != null) {
      final typical = _toMinutes(_typicalNap!);
      if (typical >= (15 * 60) + 30) {
        return RhythmUpdateIssue.bedtimeBattles;
      }
    }
    return RhythmUpdateIssue.nightWakes;
  }

  RhythmUpdatePlan? _buildPreviewPlan({
    required RhythmState state,
    required int ageMonths,
  }) {
    if (_wakeTime == null || state.rhythm == null) return null;
    final wake = _toMinutes(_wakeTime!);
    final wakeStart = _wakeAsRange ? wake - 15 : wake;
    final wakeEnd = _wakeAsRange ? wake + 15 : wake;
    final napDurationHint = _napDurationHintMinutes();
    final napReality = _napCountReality(state.rhythm?.napCountTarget);
    final issue = _issueFromAnswers(napDurationHintMinutes: napDurationHint);
    final whyNow = state.shiftAssessment.shouldSuggestUpdate
        ? state.shiftAssessment.explanation
        : 'Manual rhythm refresh requested.';

    return RhythmEngineService.instance.buildUpdatedRhythm(
      currentRhythm: state.rhythm!,
      ageMonths: ageMonths,
      wakeRangeStartMinutes: wakeStart,
      wakeRangeEndMinutes: wakeEnd,
      daycareMode: _daycareMode,
      napCountReality: napReality,
      issue: issue,
      whyNow: whyNow,
      now: DateTime.now(),
    );
  }

  Future<void> _submit({
    required String childId,
    required int ageMonths,
  }) async {
    if (_isSubmitting || _wakeTime == null) return;

    final wake = _toMinutes(_wakeTime!);
    final wakeStart = _wakeAsRange ? wake - 15 : wake;
    final wakeEnd = _wakeAsRange ? wake + 15 : wake;

    final currentNapTarget = ref.read(rhythmProvider).rhythm?.napCountTarget;
    final napReality = _napCountReality(currentNapTarget);
    final napDurationHint = _napDurationHintMinutes();
    final issue = _issueFromAnswers(napDurationHintMinutes: napDurationHint);

    setState(() => _isSubmitting = true);
    await ref
        .read(rhythmProvider.notifier)
        .applyRhythmUpdate(
          childId: childId,
          ageMonths: ageMonths,
          wakeRangeStartMinutes: wakeStart,
          wakeRangeEndMinutes: wakeEnd,
          daycareMode: _daycareMode,
          napCountReality: napReality,
          issue: issue,
          napDurationHintMinutes: napDurationHint,
        );
    final startedAt = _startedAt;
    if (startedAt != null) {
      final durationMs = DateTime.now().difference(startedAt).inMilliseconds;
      await EventBusService.emit(
        childId: childId,
        pillar: 'SLEEP_TONIGHT',
        type: 'ST_UPDATE_WIZARD_COMPLETED',
        metadata: {'duration_ms': '$durationMs'},
      );
    }
    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    _scheduleLoadIfNeeded();

    final profile = ref.watch(profileProvider);
    if (profile == null) {
      return const ProfileRequiredView(title: 'Update Rhythm');
    }

    final rollout = ref.watch(releaseRolloutProvider);
    if (!rollout.isLoading && !rollout.sleepRhythmSurfacesEnabled) {
      return const FeaturePausedView(title: 'Update Rhythm');
    }

    final childId = profile.createdAt;
    final ageMonths = _ageMonthsFor(profile.ageBracket);
    final state = ref.watch(rhythmProvider);
    final rhythm = state.rhythm;
    final updatePlan = state.lastUpdatePlan;
    final previewPlan = _buildPreviewPlan(state: state, ageMonths: ageMonths);

    if (state.isLoading) {
      return Scaffold(
        body: GradientBackgroundFromRoute(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SettleSpacing.screenPadding,
              ),
              child: CalmLoading(message: 'Preparing update flow…'),
            ),
          ),
        ),
      );
    }

    if (rhythm == null) {
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
                    title: 'Update Rhythm',
                    subtitle: 'Replan only when rhythm has shifted.',
                  ),
                  SolidCard(
                    child: Text(
                      'No rhythm loaded yet. Open Current Rhythm first.',
                      style: SettleTypography.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

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
                  title: 'Update Rhythm',
                  subtitle: '2–5 taps, then run it for 1–2 weeks.',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SolidCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Step ${_step + 1} of 4',
                                style: SettleTypography.caption,
                              ),
                              const SizedBox(height: 8),
                              if (_step == 0) ...[
                                Text('Wake time', style: SettleTypography.heading),
                                const SizedBox(height: 8),
                                _TimeSlotRow(
                                  label: 'Wake time',
                                  value: _wakeTime == null
                                      ? 'Pick time'
                                      : _wakeTime!.format(context),
                                  onTap: () => _pickWakeTime(context),
                                ),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Use a ±15 min range',
                                    style: SettleTypography.caption,
                                  ),
                                  value: _wakeAsRange,
                                  onChanged: (v) =>
                                      setState(() => _wakeAsRange = v),
                                ),
                              ],
                              if (_step == 1) ...[
                                Text('Nap today?', style: SettleTypography.heading),
                                const SizedBox(height: 8),
                                SettleSegmentedChoice<String>(
                                  options: const ['yes', 'no', 'not_sure'],
                                  selected: _napToday,
                                  labelBuilder: (v) => switch (v) {
                                    'yes' => 'Yes',
                                    'no' => 'No',
                                    _ => 'Not sure',
                                  },
                                  onChanged: (v) =>
                                      setState(() => _napToday = v),
                                ),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Daycare mode',
                                    style: SettleTypography.caption,
                                  ),
                                  value: _daycareMode,
                                  onChanged: (v) =>
                                      setState(() => _daycareMode = v),
                                ),
                                if (_napToday == 'yes') ...[
                                  const SizedBox(height: 8),
                                  _TimeSlotRow(
                                    label: 'Nap start',
                                    value: _napStart == null
                                        ? 'Optional'
                                        : _napStart!.format(context),
                                    onTap: () => _pickTime(
                                      context,
                                      current: _napStart,
                                      onPicked: (v) =>
                                          setState(() => _napStart = v),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _TimeSlotRow(
                                    label: 'Nap end',
                                    value: _napEnd == null
                                        ? 'Optional'
                                        : _napEnd!.format(context),
                                    onTap: () => _pickTime(
                                      context,
                                      current: _napEnd,
                                      onPicked: (v) =>
                                          setState(() => _napEnd = v),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  _TimeSlotRow(
                                    label: 'Typical nap',
                                    value: _typicalNap == null
                                        ? 'Pick time'
                                        : _typicalNap!.format(context),
                                    onTap: () => _pickTime(
                                      context,
                                      current: _typicalNap,
                                      onPicked: (v) =>
                                          setState(() => _typicalNap = v),
                                    ),
                                  ),
                                ],
                              ],
                              if (_step == 2) ...[
                                Text('Bedtime target', style: SettleTypography.heading),
                                const SizedBox(height: 8),
                                SettleSegmentedChoice<String>(
                                  options: const ['earlier', 'same', 'later'],
                                  selected: _bedtimeTarget,
                                  labelBuilder: (v) => switch (v) {
                                    'earlier' => 'Earlier',
                                    'same' => 'Same',
                                    _ => 'Later',
                                  },
                                  onChanged: (v) =>
                                      setState(() => _bedtimeTarget = v),
                                ),
                              ],
                              if (_step == 3) ...[
                                Text('Review', style: SettleTypography.heading),
                                const SizedBox(height: 8),
                                Text(
                                  'Wake ${_wakeTime?.format(context) ?? '--'}${_wakeAsRange ? ' (±15m)' : ''}',
                                  style: SettleTypography.body,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Nap today: ${_napToday == 'yes'
                                      ? 'Yes'
                                      : _napToday == 'no'
                                      ? 'No'
                                      : 'Not sure'}',
                                  style: SettleTypography.body,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bedtime target: ${_bedtimeTarget[0].toUpperCase()}${_bedtimeTarget.substring(1)}',
                                  style: SettleTypography.body,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Daycare mode: ${_daycareMode ? 'On' : 'Off'}',
                                  style: SettleTypography.body,
                                ),
                                if (_napDurationHintMinutes() != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Nap duration hint: ${_napDurationHintMinutes()} min',
                                    style: SettleTypography.body,
                                  ),
                                ],
                                if (previewPlan != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Confidence: ${previewPlan.confidence.label}',
                                    style: SettleTypography.caption.copyWith(
                                      color: SettleColors.nightSoft,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    previewPlan.whyNow,
                                    style: SettleTypography.caption.copyWith(
                                      color: SettleColors.nightSoft,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    previewPlan.anchorRecommendation,
                                    style: SettleTypography.caption.copyWith(
                                      color: SettleColors.nightSoft,
                                    ),
                                  ),
                                  if (previewPlan.changeSummary.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    ...previewPlan.changeSummary.map(
                                      (line) => Text(
                                        '• $line',
                                        style: SettleTypography.caption.copyWith(
                                          color: SettleColors.nightSoft,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (_step > 0)
                                    SettleTappable(
                                      semanticLabel: 'Back',
                                      onTap: () => setState(() => _step--),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 8,
                                        ),
                                        child: Text(
                                          'Back',
                                          style: SettleTypography.body.copyWith(
                                            color: SettleSemanticColors.muted(
                                              context,
                                            ),
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  const Spacer(),
                                  SettleCta(
                                    label: _step < 3
                                        ? 'Next'
                                        : _isSubmitting
                                        ? 'Saving…'
                                        : 'Save rhythm',
                                    expand: false,
                                    compact: true,
                                    enabled: _canContinue() && !_isSubmitting,
                                    onTap: () async {
                                      if (_step < 3) {
                                        setState(() => _step++);
                                        return;
                                      }
                                      await _submit(
                                        childId: childId,
                                        ageMonths: ageMonths,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (updatePlan != null) ...[
                          const SizedBox(height: 10),
                          SolidCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('New rhythm ready', style: SettleTypography.heading),
                                const SizedBox(height: 6),
                                Text(
                                  'Recommended anchor: ${_formatTime(context, updatePlan.rhythm.bedtimeAnchorMinutes)} (lock for 7–14 days).',
                                  style: SettleTypography.body,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Confidence: ${updatePlan.confidence.label}',
                                  style: SettleTypography.caption.copyWith(
                                    color: SettleColors.nightSoft,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SettleCta(
                                  label: 'Back to Current Rhythm',
                                  compact: true,
                                  onTap: () => context.go('/sleep/rhythm'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
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

/// Schedule-style row: label on left, value on right, tappable. Used for time slots.
class _TimeSlotRow extends StatelessWidget {
  const _TimeSlotRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SettleTappable(
      semanticLabel: '$label: $value',
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: SettleTypography.body.copyWith(
                  color: SettleSemanticColors.supporting(context),
                ),
              ),
            ),
            Text(
              value,
              style: SettleTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: SettleSemanticColors.headline(context),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: SettleSemanticColors.supporting(context),
            ),
          ],
        ),
      ),
    );
  }
}
