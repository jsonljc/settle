import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/approach.dart';
import '../models/rhythm_models.dart';
import '../providers/profile_provider.dart';
import '../providers/release_rollout_provider.dart';
import '../providers/rhythm_provider.dart';
import '../services/notification_service.dart';
import '../services/sleep_ai_explainer_service.dart';
import '../theme/glass_components.dart';
import '../theme/settle_tokens.dart';
import '../widgets/calm_loading.dart';
import '../widgets/release_surfaces.dart';
import '../widgets/screen_header.dart';
import '../widgets/settle_chip.dart';

class CurrentRhythmScreen extends ConsumerStatefulWidget {
  const CurrentRhythmScreen({super.key});

  @override
  ConsumerState<CurrentRhythmScreen> createState() =>
      _CurrentRhythmScreenState();
}

class _CurrentRhythmScreenState extends ConsumerState<CurrentRhythmScreen> {
  String? _loadedChildId;
  bool _loadScheduled = false;
  String? _lastWindDownSignature;
  String? _lastDriftSignature;

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

  Future<void> _loadIfNeeded() async {
    final profile = ref.read(profileProvider);
    if (profile == null) return;
    final childId = profile.createdAt;
    if (_loadedChildId == childId) return;
    _loadedChildId = childId;
    await ref
        .read(rhythmProvider.notifier)
        .load(childId: childId, ageMonths: _ageMonthsFor(profile.ageBracket));
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

  String _formatClock(BuildContext context, int minutes) {
    final normalized = ((minutes % 1440) + 1440) % 1440;
    return MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }

  String _relaxedLabel(RhythmScheduleBlock block) {
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

  Future<void> _pickWakeTime(String childId, int currentWakeMinutes) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: currentWakeMinutes ~/ 60,
        minute: currentWakeMinutes % 60,
      ),
    );
    if (picked == null) return;

    final minutes = (picked.hour * 60) + picked.minute;
    await ref
        .read(rhythmProvider.notifier)
        .setWakeTime(childId: childId, wakeTimeMinutes: minutes, known: true);
  }

  Future<void> _openMorningRecapSheet(String childId) async {
    var outcome = 'settled';
    String? timeBucket;
    final noteController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  T.space.screen,
                  T.space.md,
                  T.space.screen,
                  T.space.screen,
                ),
                child: GlassCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick recap', style: T.type.h3),
                      const SizedBox(height: 10),
                      Text('Outcome', style: T.type.label),
                      const SizedBox(height: 8),
                      _ChoiceWrap(
                        options: const {
                          'settled': 'Settled',
                          'needed_help': 'Needed help',
                          'not_resolved': 'Not resolved',
                        },
                        selected: outcome,
                        onChanged: (value) {
                          setModalState(() => outcome = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      Text('Time to settle (optional)', style: T.type.label),
                      const SizedBox(height: 8),
                      _ChoiceWrap(
                        options: const {
                          '<5': '<5m',
                          '5-15': '5–15m',
                          '15-30': '15–30m',
                          '30+': '30m+',
                        },
                        selected: timeBucket ?? '',
                        onChanged: (value) {
                          setModalState(() => timeBucket = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: noteController,
                        style: T.type.caption,
                        decoration: InputDecoration(
                          labelText: 'Note (optional)',
                          labelStyle: T.type.caption.copyWith(
                            color: T.pal.textTertiary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(T.radius.md),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SettleChip(
                        variant: SettleChipVariant.action,
                        label: 'Save recap',
                        selected: true,
                        onTap: () async {
                          final mappedNight = switch (outcome) {
                            'settled' => MorningRecapNightQuality.good,
                            'needed_help' => MorningRecapNightQuality.ok,
                            _ => MorningRecapNightQuality.rough,
                          };
                          final mappedWakes = switch (timeBucket) {
                            '<5' => MorningRecapWakesBucket.zero,
                            '30+' => MorningRecapWakesBucket.threePlus,
                            _ =>
                              outcome == 'not_resolved'
                                  ? MorningRecapWakesBucket.threePlus
                                  : MorningRecapWakesBucket.oneToTwo,
                          };
                          final mappedLongest = switch (timeBucket) {
                            '<5' => MorningRecapLongestAwakeBucket.under10,
                            '5-15' => MorningRecapLongestAwakeBucket.tenTo30,
                            '15-30' => MorningRecapLongestAwakeBucket.tenTo30,
                            '30+' => MorningRecapLongestAwakeBucket.over30,
                            _ =>
                              outcome == 'not_resolved'
                                  ? MorningRecapLongestAwakeBucket.over30
                                  : MorningRecapLongestAwakeBucket.tenTo30,
                          };
                          await ref
                              .read(rhythmProvider.notifier)
                              .submitMorningRecap(
                                childId: childId,
                                nightQuality: mappedNight,
                                wakesBucket: mappedWakes,
                                longestAwakeBucket: mappedLongest,
                              );
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    noteController.dispose();
  }

  DateTime? _targetDateTimeForBlock(RhythmScheduleBlock block, DateTime now) {
    final target = DateTime(
      now.year,
      now.month,
      now.day,
      block.windowStartMinutes ~/ 60,
      block.windowStartMinutes % 60,
    );
    if (target.isAfter(now)) return target;
    return null;
  }

  RhythmScheduleBlock? _nextWindDownBlock(
    List<RhythmScheduleBlock> blocks,
    DateTime now,
  ) {
    final candidates = blocks
        .where((block) => block.id.startsWith('nap') || block.id == 'bedtime')
        .map(
          (block) =>
              (block: block, target: _targetDateTimeForBlock(block, now)),
        )
        .where((entry) => entry.target != null)
        .toList();

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.target!.compareTo(b.target!));
    return candidates.first.block;
  }

  void _syncPhase5Notifications({
    required String childName,
    required DaySchedule schedule,
    required RhythmShiftAssessment shift,
    required bool windDownEnabled,
    required bool driftEnabled,
  }) {
    final now = DateTime.now();
    final nextBlock = _nextWindDownBlock(schedule.blocks, now);
    final windDownSignature = [
      windDownEnabled,
      schedule.dateKey,
      nextBlock?.id ?? 'none',
      nextBlock?.windowStartMinutes ?? -1,
    ].join(':');

    if (_lastWindDownSignature != windDownSignature) {
      _lastWindDownSignature = windDownSignature;
      if (!windDownEnabled || nextBlock == null) {
        NotificationService.cancelWindDownReminder();
      } else {
        final target = _targetDateTimeForBlock(nextBlock, now);
        if (target != null) {
          NotificationService.scheduleWindDownReminder(
            targetTime: target,
            babyName: childName,
            bedtime: nextBlock.id == 'bedtime',
            leadMinutes: 15,
          );
        }
      }
    }

    final driftSignature = [
      driftEnabled,
      shift.shouldSuggestUpdate,
      shift.softPromptOnly,
    ].join(':');
    if (_lastDriftSignature != driftSignature) {
      _lastDriftSignature = driftSignature;
      if (!driftEnabled || !shift.shouldSuggestUpdate) {
        NotificationService.cancelScheduleDriftPrompt();
      } else {
        NotificationService.scheduleDriftDetectedPrompt(babyName: childName);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _scheduleLoadIfNeeded();

    final profile = ref.watch(profileProvider);
    if (profile == null) {
      return const ProfileRequiredView(title: 'Current Rhythm');
    }

    final childId = profile.createdAt;
    final state = ref.watch(rhythmProvider);
    final rollout = ref.watch(releaseRolloutProvider);
    if (!rollout.isLoading && !rollout.sleepRhythmSurfacesEnabled) {
      return const FeaturePausedView(title: 'Current Rhythm');
    }
    final rhythm = state.rhythm;
    final schedule = state.todaySchedule;
    final ageMonths = _ageMonthsFor(profile.ageBracket);
    final shift = state.shiftAssessment;

    if (state.isLoading) {
      return const Scaffold(
        body: SettleBackground(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: CalmLoading(message: 'Loading current rhythm…'),
            ),
          ),
        ),
      );
    }

    if (rhythm == null || schedule == null) {
      return Scaffold(
        body: SettleBackground(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: T.space.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScreenHeader(
                    title: 'Current Rhythm',
                    subtitle: 'Repeatable routine for this week.',
                  ),
                  GlassCard(
                    child: Text(
                      'We could not load a rhythm right now. Try recalculating in a moment.',
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

    final blocks = schedule.blocks;
    final bedtime = blocks.firstWhere(
      (b) => b.id == 'bedtime',
      orElse: () => blocks.last,
    );
    final wake = blocks.firstWhere(
      (b) => b.id == 'wake',
      orElse: () => blocks.first,
    );
    final firstNap = blocks.firstWhere(
      (b) => b.id.startsWith('nap'),
      orElse: () => blocks.first,
    );
    final nowMinutes = (DateTime.now().hour * 60) + DateTime.now().minute;
    final nextUp = blocks
        .where((b) => b.id != 'wake')
        .where((b) => ((b.windowEndMinutes - nowMinutes + 1440) % 1440) <= 720)
        .fold<RhythmScheduleBlock?>(null, (best, current) {
          final bestDiff = best == null
              ? 9999
              : ((best.windowStartMinutes - nowMinutes + 1440) % 1440);
          final currentDiff =
              ((current.windowStartMinutes - nowMinutes + 1440) % 1440);
          if (best == null || currentDiff < bestDiff) return current;
          return best;
        });
    final aiSummary = rollout.sleepBoundedAiEnabled
        ? SleepAiExplainerService.instance.summarizeRhythm(
            schedule: schedule,
            shiftAssessment: shift,
            recapHistory: state.recapHistory,
            dailySignals: state.dailySignals,
          )
        : null;
    _syncPhase5Notifications(
      childName: profile.name,
      schedule: schedule,
      shift: shift,
      windDownEnabled: rollout.windDownNotificationsEnabled,
      driftEnabled:
          rollout.scheduleDriftNotificationsEnabled &&
          rollout.rhythmShiftDetectorPromptsEnabled,
    );

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Current Rhythm',
                  subtitle: 'Repeat this for the next 1–2 weeks.',
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
                                'Current Rhythm (this week)',
                                style: T.type.h3,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Typical for $ageMonths months',
                                style: T.type.caption.copyWith(
                                  color: T.pal.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bedtime anchor: ${_formatClock(context, rhythm.bedtimeAnchorMinutes)}${rhythm.locks.bedtimeAnchorLocked ? ' (locked)' : ''}',
                                style: T.type.caption.copyWith(
                                  color: T.pal.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'How sure are we? ${schedule.confidence.label}',
                                style: T.type.caption.copyWith(
                                  color: T.pal.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Based on recent logging and pattern stability.',
                                style: T.type.caption.copyWith(
                                  color: T.pal.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (rollout.rhythmShiftDetectorPromptsEnabled &&
                            shift.shouldSuggestUpdate) ...[
                          const SizedBox(height: 10),
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Update Rhythm suggested',
                                  style: T.type.h3,
                                ),
                                const SizedBox(height: 6),
                                Text(shift.explanation, style: T.type.body),
                                const SizedBox(height: 8),
                                SettleChip(
                                  variant: SettleChipVariant.action,
                                  label: 'Update Rhythm',
                                  selected: true,
                                  onTap: () => context.push('/sleep/update'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (state.preciseView && aiSummary != null) ...[
                          const SizedBox(height: 10),
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(aiSummary.headline, style: T.type.h3),
                                const SizedBox(height: 6),
                                Text(aiSummary.whatChanged, style: T.type.body),
                                const SizedBox(height: 6),
                                Text(
                                  aiSummary.why,
                                  style: T.type.caption.copyWith(
                                    color: T.pal.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  aiSummary.patternSummary,
                                  style: T.type.caption.copyWith(
                                    color: T.pal.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        if (!state.preciseView)
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Today at a glance', style: T.type.h3),
                                const SizedBox(height: 10),
                                _AnchorRow(
                                  label: 'Wake',
                                  value: _formatClock(
                                    context,
                                    wake.centerlineMinutes,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _AnchorRow(
                                  label: 'Nap',
                                  value: _formatClock(
                                    context,
                                    firstNap.centerlineMinutes,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                _AnchorRow(
                                  label: 'Bed',
                                  value: _formatClock(
                                    context,
                                    bedtime.centerlineMinutes,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Next up: ${_relaxedLabel(nextUp ?? bedtime)} around ${_formatClock(context, (nextUp ?? bedtime).centerlineMinutes)}',
                                  style: T.type.caption.copyWith(
                                    color: T.pal.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GlassCta(
                                  label: 'Update rhythm',
                                  onTap: () => context.push('/sleep/update'),
                                  compact: true,
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: () => ref
                                      .read(rhythmProvider.notifier)
                                      .recalculate(childId: childId),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(44),
                                    side: BorderSide(color: T.glass.border),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        T.radius.pill,
                                      ),
                                    ),
                                  ),
                                  child: const Text('Recalculate schedule'),
                                ),
                                const SizedBox(height: 6),
                                TextButton(
                                  onPressed: () =>
                                      _openMorningRecapSheet(childId),
                                  child: const Text('Morning recap'),
                                ),
                                const SizedBox(height: 2),
                                TextButton(
                                  onPressed: () => ref
                                      .read(rhythmProvider.notifier)
                                      .setPreciseView(
                                        childId: childId,
                                        precise: true,
                                      ),
                                  child: const Text('Advanced'),
                                ),
                              ],
                            ),
                          )
                        else ...[
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Today timeline', style: T.type.label),
                                const SizedBox(height: 10),
                                ...blocks.map((block) {
                                  final center = _formatClock(
                                    context,
                                    block.centerlineMinutes,
                                  );
                                  final soft =
                                      '${_formatClock(context, block.windowStartMinutes)}–${_formatClock(context, block.windowEndMinutes)}';
                                  final duration =
                                      (block.expectedDurationMinMinutes !=
                                              null &&
                                          block.expectedDurationMaxMinutes !=
                                              null)
                                      ? ' · ${block.expectedDurationMinMinutes}-${block.expectedDurationMaxMinutes}m'
                                      : '';
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          block.label,
                                          style: T.type.caption.copyWith(
                                            color: T.pal.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '$center (soft: $soft)$duration',
                                          style: T.type.body,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                                const SizedBox(height: 8),
                                Text(
                                  'Bedtime window: ${_formatClock(context, bedtime.windowStartMinutes)}–${_formatClock(context, bedtime.windowEndMinutes)}',
                                  style: T.type.caption.copyWith(
                                    color: T.pal.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Day taps (optional)',
                            style: T.type.caption.copyWith(
                              color: T.pal.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SettleChip(
                                variant: SettleChipVariant.action,
                                label: 'Wake time was…',
                                selected: false,
                                onTap: () => _pickWakeTime(
                                  childId,
                                  state.wakeTimeMinutes,
                                ),
                              ),
                              SettleChip(
                                variant: SettleChipVariant.action,
                                label: 'Short nap',
                                selected: false,
                                onTap: () => ref
                                    .read(rhythmProvider.notifier)
                                    .markNapQualityTap(
                                      childId: childId,
                                      quality: NapQualityTap.short,
                                    ),
                              ),
                              SettleChip(
                                variant: SettleChipVariant.action,
                                label: 'OK nap',
                                selected: false,
                                onTap: () => ref
                                    .read(rhythmProvider.notifier)
                                    .markNapQualityTap(
                                      childId: childId,
                                      quality: NapQualityTap.ok,
                                    ),
                              ),
                              SettleChip(
                                variant: SettleChipVariant.action,
                                label: 'Long nap',
                                selected: false,
                                onTap: () => ref
                                    .read(rhythmProvider.notifier)
                                    .markNapQualityTap(
                                      childId: childId,
                                      quality: NapQualityTap.long,
                                    ),
                              ),
                              SettleChip(
                                variant: SettleChipVariant.action,
                                label: 'Skipped nap',
                                selected: false,
                                onTap: () => ref
                                    .read(rhythmProvider.notifier)
                                    .markSkippedNap(childId: childId),
                              ),
                              SettleChip(
                                variant: SettleChipVariant.action,
                                label: state.advancedDayLogging
                                    ? 'Advanced mode: On'
                                    : 'Advanced mode: Off',
                                selected: state.advancedDayLogging,
                                onTap: () => ref
                                    .read(rhythmProvider.notifier)
                                    .setAdvancedDayLogging(
                                      childId: childId,
                                      enabled: !state.advancedDayLogging,
                                    ),
                              ),
                              if (state.advancedDayLogging)
                                SettleChip(
                                  variant: SettleChipVariant.action,
                                  label: 'Nap started',
                                  selected: false,
                                  onTap: () => ref
                                      .read(rhythmProvider.notifier)
                                      .markNapStarted(childId: childId),
                                ),
                              if (state.advancedDayLogging)
                                SettleChip(
                                  variant: SettleChipVariant.action,
                                  label: 'Nap ended',
                                  selected: false,
                                  onTap: () => ref
                                      .read(rhythmProvider.notifier)
                                      .markNapEnded(childId: childId),
                                ),
                              SettleChip(
                                variant: SettleChipVariant.action,
                                label: 'Bedtime battle',
                                selected: false,
                                onTap: () => ref
                                    .read(rhythmProvider.notifier)
                                    .markBedtimeResistance(childId: childId),
                              ),
                              SettleChip(
                                variant: SettleChipVariant.action,
                                label: 'Morning recap',
                                selected: false,
                                onTap: () => _openMorningRecapSheet(childId),
                              ),
                              SettleChip(
                                variant: SettleChipVariant.action,
                                label: 'Recalculate schedule',
                                selected: false,
                                onTap: () => ref
                                    .read(rhythmProvider.notifier)
                                    .recalculate(childId: childId),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextButton(
                            onPressed: () => ref
                                .read(rhythmProvider.notifier)
                                .setPreciseView(
                                  childId: childId,
                                  precise: false,
                                ),
                            child: const Text('Back to relaxed'),
                          ),
                        ],
                        if (state.lastHint != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            state.lastHint!,
                            style: T.type.caption.copyWith(
                              color: T.pal.textSecondary,
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

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final Map<String, String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((entry) {
        final isSelected = selected == entry.key;
        return SettleChip(
          variant: SettleChipVariant.action,
          label: entry.value,
          selected: isSelected,
          onTap: () => onChanged(entry.key),
        );
      }).toList(),
    );
  }
}

class _AnchorRow extends StatelessWidget {
  const _AnchorRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: T.type.caption.copyWith(color: T.pal.textSecondary),
          ),
        ),
        Text(value, style: T.type.label),
      ],
    );
  }
}
