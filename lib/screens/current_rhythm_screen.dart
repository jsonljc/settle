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

  String _formatClock(int minutes) {
    final normalized = ((minutes % 1440) + 1440) % 1440;
    final h = normalized ~/ 60;
    final m = normalized % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
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
    var nightQuality = MorningRecapNightQuality.ok;
    var wakesBucket = MorningRecapWakesBucket.oneToTwo;
    var longestAwake = MorningRecapLongestAwakeBucket.tenTo30;

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
                      Text('10-second morning recap', style: T.type.h3),
                      const SizedBox(height: 10),
                      Text('Night quality', style: T.type.label),
                      const SizedBox(height: 8),
                      _ChoiceWrap(
                        options: const {
                          'good': 'Good',
                          'ok': 'OK',
                          'rough': 'Rough',
                        },
                        selected: nightQuality.wire,
                        onChanged: (value) {
                          setModalState(
                            () => nightQuality =
                                MorningRecapNightQualityWire.fromString(value),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text('Wakes', style: T.type.label),
                      const SizedBox(height: 8),
                      _ChoiceWrap(
                        options: const {'0': '0', '1-2': '1–2', '3+': '3+'},
                        selected: wakesBucket.wire,
                        onChanged: (value) {
                          setModalState(
                            () => wakesBucket =
                                MorningRecapWakesBucketWire.fromString(value),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text('Longest awake', style: T.type.label),
                      const SizedBox(height: 8),
                      _ChoiceWrap(
                        options: const {
                          '<10': '<10m',
                          '10-30': '10–30m',
                          '30+': '30m+',
                        },
                        selected: longestAwake.wire,
                        onChanged: (value) {
                          setModalState(
                            () => longestAwake =
                                MorningRecapLongestAwakeBucketWire.fromString(
                                  value,
                                ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      _ActionChip(
                        label: 'Save recap',
                        selected: true,
                        onTap: () async {
                          await ref
                              .read(rhythmProvider.notifier)
                              .submitMorningRecap(
                                childId: childId,
                                nightQuality: nightQuality,
                                wakesBucket: wakesBucket,
                                longestAwakeBucket: longestAwake,
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
      driftEnabled: rollout.scheduleDriftNotificationsEnabled,
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
                                'Confidence: ${schedule.confidence.label}',
                                style: T.type.caption.copyWith(
                                  color: T.pal.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Confidence tracks log completeness + stability.',
                                style: T.type.caption.copyWith(
                                  color: T.pal.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Bedtime anchor: ${_formatClock(rhythm.bedtimeAnchorMinutes)}${rhythm.locks.bedtimeAnchorLocked ? ' (locked)' : ''}',
                                style: T.type.caption.copyWith(
                                  color: T.pal.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _ChoiceWrap(
                                options: const {
                                  'precise': 'Precise view',
                                  'relaxed': 'Relaxed view',
                                },
                                selected: state.preciseView
                                    ? 'precise'
                                    : 'relaxed',
                                onChanged: (value) => ref
                                    .read(rhythmProvider.notifier)
                                    .setPreciseView(
                                      childId: childId,
                                      precise: value == 'precise',
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (shift.shouldSuggestUpdate) ...[
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
                                _ActionChip(
                                  label: 'Update Rhythm',
                                  selected: true,
                                  onTap: () =>
                                      context.push('/sleep/update-rhythm'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (aiSummary != null) ...[
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
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Today timeline', style: T.type.label),
                              const SizedBox(height: 10),
                              ...blocks.map((block) {
                                final relaxed = _relaxedLabel(block);
                                final center = _formatClock(
                                  block.centerlineMinutes,
                                );
                                final soft =
                                    '${_formatClock(block.windowStartMinutes)}–${_formatClock(block.windowEndMinutes)}';
                                final duration =
                                    (block.expectedDurationMinMinutes != null &&
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
                                        state.preciseView
                                            ? block.label
                                            : relaxed,
                                        style: T.type.caption.copyWith(
                                          color: T.pal.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        state.preciseView
                                            ? '$center (soft: $soft)$duration'
                                            : '$relaxed$duration',
                                        style: T.type.body,
                                      ),
                                    ],
                                  ),
                                );
                              }),
                              const SizedBox(height: 8),
                              Text(
                                'Bedtime window: ${_formatClock(bedtime.windowStartMinutes)}–${_formatClock(bedtime.windowEndMinutes)}',
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
                            _ActionChip(
                              label: 'Wake time was…',
                              onTap: () =>
                                  _pickWakeTime(childId, state.wakeTimeMinutes),
                            ),
                            _ActionChip(
                              label: 'Short nap',
                              onTap: () => ref
                                  .read(rhythmProvider.notifier)
                                  .markNapQualityTap(
                                    childId: childId,
                                    quality: NapQualityTap.short,
                                  ),
                            ),
                            _ActionChip(
                              label: 'OK nap',
                              onTap: () => ref
                                  .read(rhythmProvider.notifier)
                                  .markNapQualityTap(
                                    childId: childId,
                                    quality: NapQualityTap.ok,
                                  ),
                            ),
                            _ActionChip(
                              label: 'Long nap',
                              onTap: () => ref
                                  .read(rhythmProvider.notifier)
                                  .markNapQualityTap(
                                    childId: childId,
                                    quality: NapQualityTap.long,
                                  ),
                            ),
                            _ActionChip(
                              label: 'Skipped nap',
                              onTap: () => ref
                                  .read(rhythmProvider.notifier)
                                  .markSkippedNap(childId: childId),
                            ),
                            _ActionChip(
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
                              _ActionChip(
                                label: 'Nap started',
                                onTap: () => ref
                                    .read(rhythmProvider.notifier)
                                    .markNapStarted(childId: childId),
                              ),
                            if (state.advancedDayLogging)
                              _ActionChip(
                                label: 'Nap ended',
                                onTap: () => ref
                                    .read(rhythmProvider.notifier)
                                    .markNapEnded(childId: childId),
                              ),
                            _ActionChip(
                              label: 'Bedtime battle',
                              onTap: () => ref
                                  .read(rhythmProvider.notifier)
                                  .markBedtimeResistance(childId: childId),
                            ),
                            _ActionChip(
                              label: 'Morning recap',
                              onTap: () => _openMorningRecapSheet(childId),
                            ),
                            _ActionChip(
                              label: 'Recalculate schedule',
                              onTap: () => ref
                                  .read(rhythmProvider.notifier)
                                  .recalculate(childId: childId),
                            ),
                          ],
                        ),
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
        return _ActionChip(
          label: entry.value,
          selected: isSelected,
          onTap: () => onChanged(entry.key),
        );
      }).toList(),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? T.pal.accent : T.pal.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? T.glass.fillAccent : T.glass.fill,
          borderRadius: BorderRadius.circular(T.radius.pill),
          border: Border.all(color: T.glass.border),
        ),
        child: Text(
          label,
          style: T.type.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
