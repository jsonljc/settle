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
import '../widgets/solid_card.dart';
import '../widgets/settle_cta.dart';
import '../theme/settle_design_system.dart';
import '../widgets/gradient_background.dart';
import '../widgets/calm_loading.dart';
import '../widgets/release_surfaces.dart';
import '../widgets/screen_header.dart';
import '../widgets/settle_chip.dart';
import '../widgets/settle_disclosure.dart';
import '../widgets/settle_gap.dart';

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
                  SettleSpacing.screenPadding,
                  SettleSpacing.md,
                  SettleSpacing.screenPadding,
                  SettleSpacing.screenPadding,
                ),
                child: SolidCard(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick recap', style: SettleTypography.heading),
                      const SettleGap.md(),
                      Text('Outcome', style: SettleTypography.body.copyWith(fontWeight: FontWeight.w600)),
                      const SettleGap.sm(),
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
                      const SettleGap.md(),
                      Text('Time to settle (optional)', style: SettleTypography.body.copyWith(fontWeight: FontWeight.w600)),
                      const SettleGap.sm(),
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
                      const SettleGap.md(),
                      TextField(
                        controller: noteController,
                        style: SettleTypography.caption,
                        decoration: InputDecoration(
                          labelText: 'Note (optional)',
                          labelStyle: SettleTypography.caption.copyWith(
                            color: SettleColors.nightMuted,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      const SettleGap.md(),
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
    final needsSleepSetup = profile.sleepProfileComplete != true;

    if (state.isLoading) {
      return Scaffold(
        body: GradientBackgroundFromRoute(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SettleSpacing.screenPadding,
              ),
              child: CalmLoading(message: 'Loading current rhythm…'),
            ),
          ),
        ),
      );
    }

    if (rhythm == null || schedule == null) {
      return Scaffold(
        body: GradientBackgroundFromRoute(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SettleSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScreenHeader(
                    title: 'Current Rhythm',
                    subtitle: 'Repeatable routine for this week.',
                  ),
                  SolidCard(
                    child: Text(
                      'We could not load a rhythm right now. Try recalculating in a moment.',
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
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SettleSpacing.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Sleep',
                  subtitle: 'Tonight is the hero. Rhythm is here when you need it.',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _RhythmSectionHeader(label: 'Tonight'),
                        const SettleGap.sm(),
                        _TonightHeroRow(
                          needsSetup: needsSleepSetup,
                          onSetup: () => context.push('/sleep/setup'),
                          onTonight: (scenario) =>
                              context.push('/sleep/tonight?scenario=$scenario'),
                        ),
                        const SettleGap.xxl(),
                        const _RhythmSectionHeader(label: 'Today'),
                        const SettleGap.sm(),
                        if (needsSleepSetup) ...[
                          SolidCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Finish sleep setup to personalize tonight guidance.',
                                  style: SettleTypography.body,
                                ),
                                const SettleGap.sm(),
                                SettleCta(
                                  label: 'Complete sleep setup',
                                  compact: true,
                                  onTap: () => context.push('/sleep/setup'),
                                ),
                              ],
                            ),
                          ),
                          const SettleGap.md(),
                        ],
                        SolidCard(
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
                              _AnchorRow(
                                label: 'Wake',
                                value: _formatClock(
                                  context,
                                  wake.centerlineMinutes,
                                ),
                              ),
                              const SettleGap.sm(),
                              _AnchorRow(
                                label: 'First nap',
                                value: _formatClock(
                                  context,
                                  firstNap.centerlineMinutes,
                                ),
                              ),
                              const SettleGap.sm(),
                              _AnchorRow(
                                label: 'Bedtime',
                                value: _formatClock(
                                  context,
                                  bedtime.centerlineMinutes,
                                ),
                              ),
                              const SettleGap.md(),
                              Text(
                                'Next up: ${_relaxedLabel(nextUp ?? bedtime)} around ${_formatClock(context, (nextUp ?? bedtime).centerlineMinutes)}',
                                style: SettleTypography.caption.copyWith(
                                  color: SettleColors.nightSoft,
                                ),
                              ),
                              const SettleGap.sm(),
                              Text(
                                'How sure are we? ${schedule.confidence.label}',
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
                                onTap: () => context.push(
                                  '/sleep/tonight?source=rhythm',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SettleGap.md(),
                        if (rollout.rhythmShiftDetectorPromptsEnabled &&
                            shift.shouldSuggestUpdate) ...[
                          const SettleGap.md(),
                          SolidCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Update Rhythm suggested',
                                  style: SettleTypography.heading,
                                ),
                                const SettleGap.xs(),
                                Text(shift.explanation, style: SettleTypography.body),
                                const SettleGap.sm(),
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
                          const SettleGap.md(),
                          SolidCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(aiSummary.headline, style: SettleTypography.heading),
                                const SettleGap.xs(),
                                Text(
                                  aiSummary.whatChanged,
                                  style: SettleTypography.body,
                                ),
                                const SettleGap.xs(),
                                Text(
                                  aiSummary.why,
                                  style: SettleTypography.caption.copyWith(
                                    color: SettleColors.nightSoft,
                                  ),
                                ),
                                const SettleGap.xs(),
                                Text(
                                  aiSummary.patternSummary,
                                  style: SettleTypography.caption.copyWith(
                                    color: SettleColors.nightSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SettleGap.md(),
                        const _RhythmSectionHeader(label: 'PLAN VIEW'),
                        const SettleGap.sm(),
                        SolidCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('View mode', style: SettleTypography.body.copyWith(fontWeight: FontWeight.w600)),
                              const SettleGap.sm(),
                              Wrap(
                                spacing: SettleSpacing.sm,
                                runSpacing: SettleSpacing.sm,
                                children: [
                                  SettleChip(
                                    variant: SettleChipVariant.action,
                                    label: 'Relaxed view',
                                    selected: !state.preciseView,
                                    onTap: () => ref
                                        .read(rhythmProvider.notifier)
                                        .setPreciseView(
                                          childId: childId,
                                          precise: false,
                                        ),
                                  ),
                                  SettleChip(
                                    variant: SettleChipVariant.action,
                                    label: 'Precise view',
                                    selected: state.preciseView,
                                    onTap: () => ref
                                        .read(rhythmProvider.notifier)
                                        .setPreciseView(
                                          childId: childId,
                                          precise: true,
                                        ),
                                  ),
                                ],
                              ),
                              const SettleGap.md(),
                              Text(
                                state.preciseView
                                    ? 'Today timeline'
                                    : 'Today windows',
                                style: SettleTypography.heading,
                              ),
                              const SettleGap.sm(),
                              ...blocks.map((block) {
                                final window = state.preciseView
                                    ? '${_formatClock(context, block.windowStartMinutes)}–${_formatClock(context, block.windowEndMinutes)}'
                                    : _formatClock(
                                        context,
                                        block.centerlineMinutes,
                                      );
                                final duration =
                                    (block.expectedDurationMinMinutes != null &&
                                        block.expectedDurationMaxMinutes !=
                                            null)
                                    ? ' · ${block.expectedDurationMinMinutes}-${block.expectedDurationMaxMinutes}m'
                                    : '';
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: SettleSpacing.sm,
                                  ),
                                  child: _AnchorRow(
                                    label: _relaxedLabel(block),
                                    value: '$window$duration',
                                  ),
                                );
                              }),
                              const SettleGap.xs(),
                              Text(
                                'Bedtime anchor: ${_formatClock(context, rhythm.bedtimeAnchorMinutes)}${rhythm.locks.bedtimeAnchorLocked ? ' (locked)' : ''}',
                                style: SettleTypography.caption.copyWith(
                                  color: SettleColors.nightSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SettleGap.md(),
                        const _RhythmSectionHeader(label: 'ADJUSTMENTS'),
                        const SettleGap.sm(),
                        SolidCard(
                          child: SettleDisclosure(
                            title: 'Adjust today',
                            subtitle: 'Optional quick taps',
                            children: [
                              const SettleGap.sm(),
                              Wrap(
                                spacing: SettleSpacing.sm,
                                runSpacing: SettleSpacing.sm,
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
                                    label: 'Bedtime battle',
                                    selected: false,
                                    onTap: () => ref
                                        .read(rhythmProvider.notifier)
                                        .markBedtimeResistance(
                                          childId: childId,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SettleGap.md(),
                        SolidCard(
                          child: SettleDisclosure(
                            title: 'Tools',
                            subtitle: 'Use if needed',
                            children: [
                              const SettleGap.sm(),
                              SettleCta(
                                label: 'Update rhythm',
                                compact: true,
                                onTap: () => context.push('/sleep/update'),
                              ),
                              const SettleGap.sm(),
                              SettleChip(
                                variant: SettleChipVariant.action,
                                label: 'Morning recap',
                                selected: false,
                                onTap: () => _openMorningRecapSheet(childId),
                              ),
                              const SettleGap.sm(),
                              SettleChip(
                                variant: SettleChipVariant.action,
                                label: 'Recalculate schedule',
                                selected: false,
                                onTap: () => ref
                                    .read(rhythmProvider.notifier)
                                    .recalculate(childId: childId),
                              ),
                              const SettleGap.sm(),
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
                              if (state.advancedDayLogging) ...[
                                const SettleGap.sm(),
                                Wrap(
                                  spacing: SettleSpacing.sm,
                                  runSpacing: SettleSpacing.sm,
                                  children: [
                                    SettleChip(
                                      variant: SettleChipVariant.action,
                                      label: 'Nap started',
                                      selected: false,
                                      onTap: () => ref
                                          .read(rhythmProvider.notifier)
                                          .markNapStarted(childId: childId),
                                    ),
                                    SettleChip(
                                      variant: SettleChipVariant.action,
                                      label: 'Nap ended',
                                      selected: false,
                                      onTap: () => ref
                                          .read(rhythmProvider.notifier)
                                          .markNapEnded(childId: childId),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (state.lastHint != null) ...[
                          const SettleGap.sm(),
                          Text(
                            state.lastHint!,
                            style: SettleTypography.caption.copyWith(
                              color: SettleColors.nightSoft,
                            ),
                          ),
                        ],
                        const SettleGap.lg(),
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
      spacing: SettleSpacing.sm,
      runSpacing: SettleSpacing.sm,
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

/// V2: Tonight hero (one large tile) + Other situations (two smaller tiles).
class _TonightHeroRow extends StatelessWidget {
  const _TonightHeroRow({
    required this.needsSetup,
    required this.onSetup,
    required this.onTonight,
  });

  final bool needsSetup;
  final VoidCallback onSetup;
  final void Function(String scenario) onTonight;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final isNight = hour >= 20 || hour < 6;
    final isEarlyWake = isNight && (hour == 5 || (hour == 4 && now.minute >= 30));

    String heroTitle;
    String heroSubtitle;
    VoidCallback heroOnTap;
    List<({String title, String scenario})> other;

    if (needsSetup) {
      heroTitle = 'Set up your sleep rhythm';
      heroSubtitle = 'About 30 seconds.';
      heroOnTap = onSetup;
      other = [
        (title: 'Night wake', scenario: 'night_wakes'),
        (title: 'Bedtime protest', scenario: 'bedtime_protest'),
      ];
    } else if (isEarlyWake) {
      heroTitle = 'Early wake';
      heroSubtitle = 'Get one step for before 5–6am.';
      heroOnTap = () => onTonight('early_wakes');
      other = [
        (title: 'Night wake', scenario: 'night_wakes'),
        (title: 'Bedtime protest', scenario: 'bedtime_protest'),
      ];
    } else if (isNight) {
      heroTitle = 'Night wake';
      heroSubtitle = 'Get one immediate step for tonight.';
      heroOnTap = () => onTonight('night_wakes');
      other = [
        (title: 'Early wake', scenario: 'early_wakes'),
        (title: 'Bedtime protest', scenario: 'bedtime_protest'),
      ];
    } else {
      heroTitle = 'Bedtime';
      heroSubtitle = 'Won\'t settle? Get tonight\'s steps.';
      heroOnTap = () => onTonight('bedtime_protest');
      other = [
        (title: 'Night wake', scenario: 'night_wakes'),
        (title: 'Early wake', scenario: 'early_wakes'),
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SolidCard(
          onTap: heroOnTap,
          padding: const EdgeInsets.symmetric(
            horizontal: SettleSpacing.cardPadding,
            vertical: SettleSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                heroTitle,
                style: SettleTypography.heading.copyWith(
                  color: SettleSemanticColors.headline(context),
                ),
              ),
              const SettleGap.sm(),
              Text(
                heroSubtitle,
                style: SettleTypography.body.copyWith(
                  color: SettleSemanticColors.body(context),
                ),
              ),
            ],
          ),
        ),
        const SettleGap.md(),
        Text(
          'Other situations',
          style: SettleTypography.label.copyWith(
            color: SettleSemanticColors.supporting(context),
            fontSize: 14,
          ),
        ),
        const SettleGap.sm(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SolidCard(
                onTap: () => onTonight(other[0].scenario),
                padding: const EdgeInsets.symmetric(
                  vertical: SettleSpacing.lg,
                  horizontal: SettleSpacing.md,
                ),
                child: Text(
                  other[0].title,
                  style: SettleTypography.subheading.copyWith(
                    color: SettleSemanticColors.headline(context),
                  ),
                ),
              ),
            ),
            const SettleGap.md(),
            Expanded(
              child: SolidCard(
                onTap: () => onTonight(other[1].scenario),
                padding: const EdgeInsets.symmetric(
                  vertical: SettleSpacing.lg,
                  horizontal: SettleSpacing.md,
                ),
                child: Text(
                  other[1].title,
                  style: SettleTypography.subheading.copyWith(
                    color: SettleSemanticColors.headline(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RhythmSectionHeader extends StatelessWidget {
  const _RhythmSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: SettleSpacing.xs),
      child: Text(
        label,
        style: SettleTypography.label.copyWith(
          color: SettleSemanticColors.supporting(context),
          fontSize: 14,
        ),
      ),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: SettleTypography.caption.copyWith(color: SettleColors.nightSoft),
          ),
        ),
        const SizedBox(width: SettleSpacing.sm),
        Flexible(
          child: Text(
            value,
            style: SettleTypography.body.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
