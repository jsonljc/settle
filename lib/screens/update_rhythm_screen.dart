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
import '../theme/glass_components.dart';
import '../theme/settle_tokens.dart';
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
      return const Scaffold(
        body: SettleBackground(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: CalmLoading(message: 'Preparing update flow…'),
            ),
          ),
        ),
      );
    }

    if (rhythm == null) {
      return Scaffold(
        body: SettleBackground(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: T.space.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScreenHeader(
                    title: 'Update Rhythm',
                    subtitle: 'Replan only when rhythm has shifted.',
                  ),
                  GlassCard(
                    child: Text(
                      'No rhythm loaded yet. Open Current Rhythm first.',
                      style: T.type.body,
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
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
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
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Step ${_step + 1} of 4',
                                style: T.type.caption,
                              ),
                              const SizedBox(height: 8),
                              if (_step == 0) ...[
                                Text('Wake time', style: T.type.h3),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: () => _pickWakeTime(context),
                                  child: Text(
                                    _wakeTime == null
                                        ? 'Pick wake time'
                                        : 'Wake at ${_wakeTime!.format(context)}',
                                  ),
                                ),
                                SwitchListTile.adaptive(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(
                                    'Use a ±15 min range',
                                    style: T.type.caption,
                                  ),
                                  value: _wakeAsRange,
                                  onChanged: (v) =>
                                      setState(() => _wakeAsRange = v),
                                ),
                              ],
                              if (_step == 1) ...[
                                Text('Nap today?', style: T.type.h3),
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
                                    style: T.type.caption,
                                  ),
                                  value: _daycareMode,
                                  onChanged: (v) =>
                                      setState(() => _daycareMode = v),
                                ),
                                if (_napToday == 'yes') ...[
                                  const SizedBox(height: 8),
                                  OutlinedButton(
                                    onPressed: () => _pickTime(
                                      context,
                                      current: _napStart,
                                      onPicked: (v) =>
                                          setState(() => _napStart = v),
                                    ),
                                    child: Text(
                                      _napStart == null
                                          ? 'Nap start (optional)'
                                          : 'Nap start ${_napStart!.format(context)}',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  OutlinedButton(
                                    onPressed: () => _pickTime(
                                      context,
                                      current: _napEnd,
                                      onPicked: (v) =>
                                          setState(() => _napEnd = v),
                                    ),
                                    child: Text(
                                      _napEnd == null
                                          ? 'Nap end (optional)'
                                          : 'Nap end ${_napEnd!.format(context)}',
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  OutlinedButton(
                                    onPressed: () => _pickTime(
                                      context,
                                      current: _typicalNap,
                                      onPicked: (v) =>
                                          setState(() => _typicalNap = v),
                                    ),
                                    child: Text(
                                      _typicalNap == null
                                          ? 'Typical nap time'
                                          : 'Typical ${_typicalNap!.format(context)}',
                                    ),
                                  ),
                                ],
                              ],
                              if (_step == 2) ...[
                                Text('Bedtime target', style: T.type.h3),
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
                                Text('Review', style: T.type.h3),
                                const SizedBox(height: 8),
                                Text(
                                  'Wake ${_wakeTime?.format(context) ?? '--'}${_wakeAsRange ? ' (±15m)' : ''}',
                                  style: T.type.body,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Nap today: ${_napToday == 'yes'
                                      ? 'Yes'
                                      : _napToday == 'no'
                                      ? 'No'
                                      : 'Not sure'}',
                                  style: T.type.body,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Bedtime target: ${_bedtimeTarget[0].toUpperCase()}${_bedtimeTarget.substring(1)}',
                                  style: T.type.body,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Daycare mode: ${_daycareMode ? 'On' : 'Off'}',
                                  style: T.type.body,
                                ),
                                if (_napDurationHintMinutes() != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Nap duration hint: ${_napDurationHintMinutes()} min',
                                    style: T.type.body,
                                  ),
                                ],
                                if (previewPlan != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    'Confidence: ${previewPlan.confidence.label}',
                                    style: T.type.caption.copyWith(
                                      color: T.pal.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    previewPlan.whyNow,
                                    style: T.type.caption.copyWith(
                                      color: T.pal.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    previewPlan.anchorRecommendation,
                                    style: T.type.caption.copyWith(
                                      color: T.pal.textSecondary,
                                    ),
                                  ),
                                  if (previewPlan.changeSummary.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    ...previewPlan.changeSummary.map(
                                      (line) => Text(
                                        '• $line',
                                        style: T.type.caption.copyWith(
                                          color: T.pal.textSecondary,
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
                                    TextButton(
                                      onPressed: () => setState(() => _step--),
                                      child: const Text('Back'),
                                    ),
                                  const Spacer(),
                                  GlassCta(
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
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('New rhythm ready', style: T.type.h3),
                                const SizedBox(height: 6),
                                Text(
                                  'Recommended anchor: ${_formatTime(context, updatePlan.rhythm.bedtimeAnchorMinutes)} (lock for 7–14 days).',
                                  style: T.type.body,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Confidence: ${updatePlan.confidence.label}',
                                  style: T.type.caption.copyWith(
                                    color: T.pal.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GlassCta(
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
