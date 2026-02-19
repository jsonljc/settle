import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../models/approach.dart';
import '../providers/profile_provider.dart';
import '../providers/release_rollout_provider.dart';
import '../providers/sleep_tonight_provider.dart';
import '../providers/user_cards_provider.dart';
import '../services/card_content_service.dart';
import '../services/event_bus_service.dart';
import '../services/sleep_guidance_service.dart';
import '../services/spec_policy.dart';
import '../theme/glass_components.dart' as legacy_glass;
import '../theme/settle_design_system.dart';
import '../widgets/calm_loading.dart';
import '../widgets/glass_card.dart';
import '../widgets/release_surfaces.dart';
import '../widgets/settle_gap.dart';
import '../widgets/settle_segmented_choice.dart';
import '../widgets/settle_tappable.dart';

class _StTokens {
  _StTokens._();

  static const type = _StTypeTokens();
  static const pal = _StPaletteTokens();
  static const space = _StSpaceTokens();
}

class _StTypeTokens {
  const _StTypeTokens();

  TextStyle get h3 => SettleTypography.heading;
  TextStyle get label =>
      SettleTypography.body.copyWith(fontWeight: FontWeight.w600);
  TextStyle get body => SettleTypography.body;
  TextStyle get caption => SettleTypography.caption;
  TextStyle get h2 => SettleTypography.heading.copyWith(fontSize: 22);
}

class _StPaletteTokens {
  const _StPaletteTokens();

  Color get textSecondary => SettleColors.ink500;
  Color get textTertiary => SettleColors.ink400;
}

class _StSpaceTokens {
  const _StSpaceTokens();

  double get md => SettleSpacing.md;
}

class SleepTonightScreen extends ConsumerStatefulWidget {
  const SleepTonightScreen({super.key});

  @override
  ConsumerState<SleepTonightScreen> createState() => _SleepTonightScreenState();
}

class _SleepTonightScreenState extends ConsumerState<SleepTonightScreen> {
  String _scenario = 'night_wakes';
  final bool _feedingAssociation = false;
  final String _feedMode = 'keep_feeds';

  String? _loadedChildId;
  bool _loadScheduled = false;
  bool _didHydrateScenario = false;
  bool _openSetupFromQuery = false;
  bool _setupSheetScheduled = false;
  bool _firstGuidanceEventSent = false;
  DateTime? _openedAt;

  static const _scenarioLabels = <String, String>{
    'night_wakes': 'Night wake',
    'early_wakes': 'Early wake',
    'bedtime_protest': 'Bedtime protest',
  };

  @override
  void initState() {
    super.initState();
    _openedAt = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didHydrateScenario) return;
    _didHydrateScenario = true;

    final scenario = GoRouterState.of(context).uri.queryParameters['scenario'];
    if (_scenarioLabels.containsKey(scenario)) {
      _scenario = scenario!;
    }
    final openSetup = GoRouterState.of(
      context,
    ).uri.queryParameters['open_setup'];
    _openSetupFromQuery = openSetup == '1';
  }

  bool get _isNightContext => SpecPolicy.isNight(DateTime.now());

  bool get _suggestEarlyWake {
    final now = DateTime.now();
    return _isNightContext &&
        (now.hour == 5 || (now.hour == 4 && now.minute >= 30));
  }

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

  String _preferenceForApproach(Approach approach) {
    return switch (approach) {
      Approach.extinction => 'firm',
      Approach.rhythmFirst => 'standard',
      _ => 'gentle',
    };
  }

  String _lockedMethodIdForApproach(Approach approach) {
    return switch (approach) {
      Approach.stayAndSupport => 'check_console',
      Approach.checkAndReassure => 'fading_chair',
      Approach.cueBased => 'check_console',
      Approach.rhythmFirst => 'foundations_only',
      Approach.extinction => 'extinction',
    };
  }

  Approach _activeApproach({
    required Approach profileApproach,
    required SleepTonightState state,
  }) {
    if (state.selectedApproachId.isNotEmpty) {
      return Approach.fromId(state.selectedApproachId);
    }
    return profileApproach;
  }

  int? _timeToFirstGuidanceMs() {
    final openedAt = _openedAt;
    if (openedAt == null) return null;
    final diff = DateTime.now().difference(openedAt).inMilliseconds;
    return diff < 0 ? 0 : diff;
  }

  void _loadPlanIfNeeded({
    required String childId,
    required String selectedApproachId,
  }) {
    if (_loadedChildId == childId) return;
    if (_loadScheduled) return;
    _loadedChildId = childId;
    _loadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScheduled = false;
      if (!mounted) return;
      final notifier = ref.read(sleepTonightProvider.notifier);
      notifier.syncMethodSelection(
        childId: childId,
        selectedApproachId: selectedApproachId,
      );
      notifier.loadTonightPlan(childId);
      EventBusService.emit(
        childId: childId,
        pillar: 'SLEEP_TONIGHT',
        type: 'ST_TONIGHT_OPEN',
      );
    });
  }

  Future<void> _createOrSwitchPlan({
    required String childId,
    required Approach approach,
    required int ageMonths,
    required String scenario,
  }) async {
    final notifier = ref.read(sleepTonightProvider.notifier);
    final safeSleepConfirmed = ref
        .read(sleepTonightProvider)
        .safeSleepConfirmed;
    await notifier.createTonightPlan(
      childId: childId,
      ageMonths: ageMonths,
      scenario: scenario,
      preference: _preferenceForApproach(approach),
      feedingAssociation: _feedingAssociation,
      feedMode: _feedMode,
      lockedMethodId: _lockedMethodIdForApproach(approach),
      safeSleepConfirmed: safeSleepConfirmed,
      timeToStartSeconds: null,
    );

    final guidanceMs = _timeToFirstGuidanceMs();
    if (guidanceMs != null) {
      await EventBusService.emit(
        childId: childId,
        pillar: 'SLEEP_TONIGHT',
        type: 'ST_FIRST_GUIDANCE_RENDERED',
        metadata: {
          'time_to_first_guidance_ms': '$guidanceMs',
          'scenario': scenario,
        },
      );
      _firstGuidanceEventSent = true;
    }
  }

  void _scheduleNightAutoStart({
    required String childId,
    required Approach approach,
    required int ageMonths,
    required SleepTonightState state,
  }) {
    // Slice 3B: Situation picker first always — no auto-start.
    // User taps situation → guidance in ≤3 taps.
    return;
  }

  Future<void> _showEvidenceSheet(List<String> evidenceRefs) async {
    final items = await SleepGuidanceService.instance.getEvidenceItems(
      evidenceRefs,
    );
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              SettleSpacing.screenPadding,
              _StTokens.space.md,
              SettleSpacing.screenPadding,
              SettleSpacing.screenPadding,
            ),
            child: GlassCard(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.75,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Why this works', style: _StTokens.type.h3),
                      const SizedBox(height: 8),
                      if (items.isEmpty)
                        Text(
                          'No evidence details are available for this card right now.',
                          style: _StTokens.type.caption.copyWith(
                            color: _StTokens.pal.textSecondary,
                          ),
                        )
                      else
                        ...items
                            .take(3)
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Text(
                                  '• ${item.claim}',
                                  style: _StTokens.type.caption.copyWith(
                                    color: _StTokens.pal.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openRecapSheet({
    required String childId,
    required SleepTonightState state,
  }) async {
    var outcome = state.lastRecapOutcome ?? SleepRecapOutcome.settled;
    var timeBucket = state.lastTimeToSettleBucket;

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
                  _StTokens.space.md,
                  SettleSpacing.screenPadding,
                  SettleSpacing.screenPadding +
                      MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: GlassCard(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick recap', style: _StTokens.type.h3),
                        const SizedBox(height: 10),
                        Text('Outcome', style: _StTokens.type.label),
                        const SizedBox(height: 8),
                        SettleSegmentedChoice<SleepRecapOutcome>(
                          options: const [
                            SleepRecapOutcome.settled,
                            SleepRecapOutcome.neededHelp,
                            SleepRecapOutcome.notResolved,
                          ],
                          selected: outcome,
                          labelBuilder: (v) => v.label,
                          onChanged: (v) => setModalState(() => outcome = v),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Time to settle (optional)',
                          style: _StTokens.type.label,
                        ),
                        const SizedBox(height: 8),
                        SettleSegmentedChoice<String>(
                          options: const ['<5', '5-15', '15-30', '30+'],
                          selected: timeBucket ?? '<5',
                          labelBuilder: (v) => '$v min',
                          onChanged: (v) => setModalState(() => timeBucket = v),
                        ),
                        const SizedBox(height: 12),
                        legacy_glass.GlassCta(
                          label: 'Save recap',
                          compact: true,
                          onTap: () async {
                            await ref
                                .read(sleepTonightProvider.notifier)
                                .completeWithRecap(
                                  childId: childId,
                                  outcome: outcome,
                                  timeToSettleBucket: timeBucket,
                                );
                            await EventBusService.emit(
                              childId: childId,
                              pillar: 'SLEEP_TONIGHT',
                              type: 'ST_RECAP_COMPLETED',
                              metadata: {
                                'outcome': outcome.wire,
                                if (timeBucket != null)
                                  'time_bucket': timeBucket!,
                              },
                            );
                            if (context.mounted) Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showApproachSwitchSheet({
    required String childId,
    required Approach currentApproach,
    required int ageMonths,
    required String currentScenario,
  }) async {
    Approach next = currentApproach;
    String reason = 'not_working';
    String timing = 'tonight';

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
                  _StTokens.space.md,
                  SettleSpacing.screenPadding,
                  SettleSpacing.screenPadding +
                      MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: GlassCard(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Change approach', style: _StTokens.type.h3),
                        const SizedBox(height: 10),
                        Text('Approach', style: _StTokens.type.label),
                        const SizedBox(height: 8),
                        SettleSegmentedChoice<Approach>(
                          options: Approach.values,
                          selected: next,
                          labelBuilder: (v) => v.label,
                          onChanged: (v) => setModalState(() => next = v),
                        ),
                        const SizedBox(height: 10),
                        Text('Reason', style: _StTokens.type.label),
                        const SizedBox(height: 8),
                        SettleSegmentedChoice<String>(
                          options: const [
                            'not_working',
                            'too_intense',
                            'caregiver_change',
                            'environment_changed',
                            'other',
                          ],
                          selected: reason,
                          labelBuilder: (v) => switch (v) {
                            'not_working' => 'Not working',
                            'too_intense' => 'Too intense',
                            'caregiver_change' => 'Caregiver change',
                            'environment_changed' =>
                              'Sleep environment changed',
                            _ => 'Other',
                          },
                          onChanged: (v) => setModalState(() => reason = v),
                        ),
                        const SizedBox(height: 10),
                        Text('Effective timing', style: _StTokens.type.label),
                        const SizedBox(height: 8),
                        SettleSegmentedChoice<String>(
                          options: const ['tonight', 'tomorrow'],
                          selected: timing,
                          labelBuilder: (v) =>
                              v == 'tonight' ? 'Tonight' : 'Tomorrow',
                          onChanged: (v) => setModalState(() => timing = v),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Switching resets consistency. Expect 2–3 nights to read results.',
                          style: _StTokens.type.caption.copyWith(
                            color: _StTokens.pal.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        legacy_glass.GlassCta(
                          label: 'Confirm switch',
                          compact: true,
                          onTap: () async {
                            await ref
                                .read(sleepTonightProvider.notifier)
                                .changeApproachWithCommitment(
                                  childId: childId,
                                  toApproachId: next.id,
                                  reason: reason,
                                  effectiveTiming: timing,
                                );
                            await EventBusService.emit(
                              childId: childId,
                              pillar: 'SLEEP_TONIGHT',
                              type: 'ST_METHOD_CHANGED',
                              metadata: {
                                'reason': reason,
                                'effective_timing': timing,
                                'to_approach': next.id,
                              },
                            );

                            if (timing == 'tonight') {
                              await ref
                                  .read(profileProvider.notifier)
                                  .updateApproach(next);
                              await _createOrSwitchPlan(
                                childId: childId,
                                approach: next,
                                ageMonths: ageMonths,
                                scenario: currentScenario,
                              );
                            }

                            if (context.mounted) Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showHomeContextSheet({
    required String childId,
    required SleepTonightState state,
  }) async {
    var sharedRoom = state.sharedRoom;
    var caregiverConsistency = state.caregiverConsistency;
    var cryingTolerance = state.cryingTolerance;
    var canLeaveRoom = state.canLeaveRoom;
    var nightFeedsExpected = state.nightFeedsExpected;

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
                  _StTokens.space.md,
                  SettleSpacing.screenPadding,
                  SettleSpacing.screenPadding +
                      MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: GlassCard(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Make guidance fit your home',
                          style: _StTokens.type.h3,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '15 seconds',
                          style: _StTokens.type.caption.copyWith(
                            color: _StTokens.pal.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Shared room',
                            style: _StTokens.type.caption,
                          ),
                          value: sharedRoom,
                          onChanged: (v) => setModalState(() => sharedRoom = v),
                        ),
                        Text(
                          'Caregiver consistency',
                          style: _StTokens.type.caption,
                        ),
                        const SizedBox(height: 6),
                        SettleSegmentedChoice<String>(
                          options: const ['consistent', 'rotating', 'unsure'],
                          selected: caregiverConsistency,
                          labelBuilder: (v) => switch (v) {
                            'consistent' => 'Consistent',
                            'rotating' => 'Rotating',
                            _ => 'Unsure',
                          },
                          onChanged: (v) =>
                              setModalState(() => caregiverConsistency = v),
                        ),
                        const SizedBox(height: 8),
                        Text('Crying tolerance', style: _StTokens.type.caption),
                        const SizedBox(height: 6),
                        SettleSegmentedChoice<String>(
                          options: const ['low', 'med', 'high'],
                          selected: cryingTolerance,
                          labelBuilder: (v) => v.toUpperCase(),
                          onChanged: (v) =>
                              setModalState(() => cryingTolerance = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Can leave room',
                            style: _StTokens.type.caption,
                          ),
                          value: canLeaveRoom,
                          onChanged: (v) =>
                              setModalState(() => canLeaveRoom = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Night feeds expected',
                            style: _StTokens.type.caption,
                          ),
                          value: nightFeedsExpected,
                          onChanged: (v) =>
                              setModalState(() => nightFeedsExpected = v),
                        ),
                        const SizedBox(height: 10),
                        legacy_glass.GlassCta(
                          label: 'Save setup',
                          compact: true,
                          onTap: () async {
                            await ref
                                .read(sleepTonightProvider.notifier)
                                .setHomeContext(
                                  childId: childId,
                                  sharedRoom: sharedRoom,
                                  caregiverConsistency: caregiverConsistency,
                                  cryingTolerance: cryingTolerance,
                                  canLeaveRoom: canLeaveRoom,
                                  nightFeedsExpected: nightFeedsExpected,
                                );
                            if (context.mounted) Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _shareSleepPlan(Map<String, dynamic> plan, Approach approach) {
    const maxSteps = 3;
    final allSteps =
        (plan['steps'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final steps = allSteps.length > maxSteps
        ? allSteps.sublist(0, maxSteps)
        : allSteps;
    final current = steps.isEmpty
        ? 0
        : (plan['current_step'] as int? ?? 0).clamp(0, steps.length - 1);
    final currentStep = steps.isEmpty
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(steps[current]);
    final stepMinutes = (currentStep['minutes'] as int?) ?? 3;
    String singleLine(String? text, String fallback) {
      final compact = (text ?? '').replaceAll('\n', ' ').trim();
      return compact.isEmpty ? fallback : compact;
    }

    final doNow = singleLine(
      currentStep['script']?.toString(),
      'Keep your response calm and consistent.',
    );
    final ifStill = singleLine(
      currentStep['do_step']?.toString(),
      'Repeat the same brief response.',
    );
    final stopRule = singleLine(
      plan['escalation_rule']?.toString(),
      'Pause and switch to comfort-first if things escalate.',
    );
    final commitmentLabel =
        'Night ${plan['current_step'] ?? 0}/${plan['commitment_nights'] ?? 7}';
    final body = [
      'Approach: ${approach.label} • $commitmentLabel',
      'Do now: $doNow',
      'If still crying after $stepMinutes min: $ifStill',
      'Stop rule: $stopRule',
    ].join('\n');
    final text = "Tonight's sleep plan to use right now:\n$body";
    Share.share(text);
  }

  Future<void> _showMoreOptionsSheet({
    required String childId,
    required SleepTonightState state,
    required Approach approach,
    required int ageMonths,
    required List<String> evidenceRefs,
  }) async {
    var selectedScenario =
        state.activePlan?['scenario']?.toString() ?? _scenario;

    EventBusService.emit(
      childId: childId,
      pillar: 'SLEEP_TONIGHT',
      type: 'ST_MORE_OPTIONS_OPEN',
    );

    if (!mounted) return;

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
                  _StTokens.space.md,
                  SettleSpacing.screenPadding,
                  SettleSpacing.screenPadding,
                ),
                child: GlassCard(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.82,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('More options', style: _StTokens.type.h3),
                          const SettleGap.md(),
                          Text('Switch scenario', style: _StTokens.type.label),
                          const SettleGap.sm(),
                          SettleSegmentedChoice<String>(
                            options: _scenarioLabels.keys.toList(),
                            selected: selectedScenario,
                            labelBuilder: (v) => _scenarioLabels[v]!,
                            onChanged: (v) async {
                              setModalState(() => selectedScenario = v);
                              setState(() => _scenario = v);
                              await EventBusService.emit(
                                childId: childId,
                                pillar: 'SLEEP_TONIGHT',
                                type: 'ST_SCENARIO_CHANGED',
                                metadata: {'scenario': v},
                              );
                              await _createOrSwitchPlan(
                                childId: childId,
                                approach: approach,
                                ageMonths: ageMonths,
                                scenario: v,
                              );
                            },
                          ),
                          const SettleGap.md(),
                          legacy_glass.GlassPill(
                            label: 'Why this works',
                            enabled: evidenceRefs.isNotEmpty,
                            onTap: evidenceRefs.isNotEmpty
                                ? () => _showEvidenceSheet(evidenceRefs)
                                : () {},
                          ),
                          const SettleGap.sm(),
                          legacy_glass.GlassPill(
                            label: 'Mark done',
                            onTap: () async {
                              Navigator.of(context).pop();
                              await _openRecapSheet(
                                childId: childId,
                                state: state,
                              );
                            },
                          ),
                          const SettleGap.sm(),
                          legacy_glass.GlassPill(
                            label: 'Change approach',
                            onTap: () async {
                              await EventBusService.emit(
                                childId: childId,
                                pillar: 'SLEEP_TONIGHT',
                                type: 'ST_METHOD_CHANGE_INITIATED',
                              );
                              if (!mounted) return;
                              await _showApproachSwitchSheet(
                                childId: childId,
                                currentApproach: approach,
                                ageMonths: ageMonths,
                                currentScenario: selectedScenario,
                              );
                            },
                          ),
                          const SettleGap.md(),
                          Text(
                            'Use these only if needed.',
                            style: _StTokens.type.caption.copyWith(
                              color: _StTokens.pal.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final rollout = ref.watch(releaseRolloutProvider);
    if (!rollout.isLoading && !rollout.sleepTonightEnabled) {
      final fallback = pausedFallback(
        preferredEnabled: rollout.helpNowEnabled,
        preferredLabel: 'Open Now: Incident',
        preferredRoute: SpecPolicy.nowIncidentUri(source: 'sleep_paused'),
      );
      return FeaturePausedView(
        title: 'Tonight',
        fallbackLabel: fallback.label,
        fallbackRoute: fallback.route,
      );
    }

    final profile = ref.watch(profileProvider);
    final state = ref.watch(sleepTonightProvider);
    if (profile == null) {
      return const ProfileRequiredView(title: 'Tonight');
    }

    final childId = profile.createdAt;
    final ageMonths = _ageMonthsFor(profile.ageBracket);
    final approach = _activeApproach(
      profileApproach: profile.approach,
      state: state,
    );

    _loadPlanIfNeeded(
      childId: childId,
      selectedApproachId: profile.approach.id,
    );
    _scheduleNightAutoStart(
      childId: childId,
      approach: approach,
      ageMonths: ageMonths,
      state: state,
    );
    if (_openSetupFromQuery && !_setupSheetScheduled && !state.isLoading) {
      _openSetupFromQuery = false;
      _setupSheetScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _setupSheetScheduled = false;
        if (!mounted) return;
        await _showHomeContextSheet(childId: childId, state: state);
      });
    }

    final plan = state.activePlan;
    if (state.hasActivePlan && !_firstGuidanceEventSent) {
      final guidanceMs = _timeToFirstGuidanceMs();
      final scenario = plan?['scenario']?.toString() ?? _scenario;
      _firstGuidanceEventSent = true;
      if (guidanceMs != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          EventBusService.emit(
            childId: childId,
            pillar: 'SLEEP_TONIGHT',
            type: 'ST_FIRST_GUIDANCE_RENDERED',
            metadata: {
              'time_to_first_guidance_ms': '$guidanceMs',
              'scenario': scenario,
            },
          );
        });
      }
    }
    final evidenceRefs =
        (plan?['evidence_refs'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];

    return Theme(
      data: SettleTheme.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: SettleSpacing.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SleepTonightSceneHeader(),
                const SettleGap.md(),
                Expanded(
                  child: state.isLoading
                      ? const CalmLoading(message: 'Getting guidance ready…')
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!state.hasActivePlan) ...[
                                const _SleepSectionHeader(label: 'START HERE'),
                                const SettleGap.sm(),
                                _SleepTonightSituationPicker(
                                  onTapScenario: (scenario) async {
                                    setState(() => _scenario = scenario);
                                    await _createOrSwitchPlan(
                                      childId: childId,
                                      approach: approach,
                                      ageMonths: ageMonths,
                                      scenario: scenario,
                                    );
                                  },
                                ),
                                const SettleGap.md(),
                              ],
                              if (!state.hasSleepSetup ||
                                  !state.safeSleepConfirmed ||
                                  (_isNightContext && _suggestEarlyWake)) ...[
                                const _SleepSectionHeader(label: 'SAFETY'),
                                const SettleGap.sm(),
                                if (!state.hasSleepSetup) ...[
                                  GlassCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Make guidance fit your home (15 seconds)',
                                          style: _StTokens.type.label,
                                        ),
                                        const SettleGap.sm(),
                                        legacy_glass.GlassCta(
                                          label: 'Sleep setup',
                                          compact: true,
                                          onTap: () => _showHomeContextSheet(
                                            childId: childId,
                                            state: state,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SettleGap.sm(),
                                ],
                                if (_isNightContext && _suggestEarlyWake)
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: SettleSpacing.sm,
                                    ),
                                    child: Text(
                                      'Might be an early wake? You can switch in More options.',
                                      style: _StTokens.type.caption.copyWith(
                                        color: _StTokens.pal.textSecondary,
                                      ),
                                    ),
                                  ),
                                if (!state.safeSleepConfirmed)
                                  legacy_glass.GlassCardRose(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sleep space is not confirmed as safe.',
                                          style: _StTokens.type.label,
                                        ),
                                        const SettleGap.xs(),
                                        Text(
                                          'Confirm safety before starting training guidance.',
                                          style: _StTokens.type.caption
                                              .copyWith(
                                                color:
                                                    _StTokens.pal.textSecondary,
                                              ),
                                        ),
                                        const SettleGap.md(),
                                        legacy_glass.GlassCta(
                                          label: 'Confirm sleep space is safe',
                                          compact: true,
                                          onTap: () => ref
                                              .read(
                                                sleepTonightProvider.notifier,
                                              )
                                              .updateSafetyGate(
                                                breathingDifficulty:
                                                    state.breathingDifficulty,
                                                dehydrationSigns:
                                                    state.dehydrationSigns,
                                                repeatedVomiting:
                                                    state.repeatedVomiting,
                                                severePainIndicators:
                                                    state.severePainIndicators,
                                                feedingRefusalWithPainSigns: state
                                                    .feedingRefusalWithPainSigns,
                                                safeSleepConfirmed: true,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SettleGap.md(),
                              ],
                              const _SleepSectionHeader(label: 'GUIDANCE'),
                              const SettleGap.sm(),
                              if (state.hasActivePlan)
                                _ThreeLineGuidanceCard(
                                  approachLabel: approach.label,
                                  commitmentLabel:
                                      'Night ${state.commitmentNight}/${state.commitmentNightsDefault}',
                                  plan: plan!,
                                  runnerHint: plan['runner_hint']?.toString(),
                                  onNextStep: () async {
                                    await ref
                                        .read(sleepTonightProvider.notifier)
                                        .completeCurrentStep();
                                    await EventBusService.emit(
                                      childId: childId,
                                      pillar: 'SLEEP_TONIGHT',
                                      type: 'ST_NEXT_STEP_TAPPED',
                                    );
                                  },
                                  onClose: () async {
                                    await ref
                                        .read(sleepTonightProvider.notifier)
                                        .clearActivePlan(childId);
                                    if (context.mounted) {
                                      setState(() {});
                                    }
                                  },
                                  onSaveToPlaybook: () async {
                                    final triggerType =
                                        _scenario == 'bedtime_protest'
                                        ? 'bedtime_battles'
                                        : 'bedtime_battles';
                                    final card = await CardContentService
                                        .instance
                                        .selectBestCard(
                                          triggerType: triggerType,
                                        );
                                    if (card != null && context.mounted) {
                                      await ref
                                          .read(userCardsProvider.notifier)
                                          .save(card.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Saved to playbook'),
                                            duration: Duration(
                                              milliseconds: 1100,
                                            ),
                                          ),
                                        );
                                        ref
                                            .read(sleepTonightProvider.notifier)
                                            .clearActivePlan(childId);
                                        setState(() {});
                                      }
                                    }
                                  },
                                  onShare: () =>
                                      _shareSleepPlan(plan, approach),
                                  onMoreOptions: () => _showMoreOptionsSheet(
                                    childId: childId,
                                    state: state,
                                    approach: approach,
                                    ageMonths: ageMonths,
                                    evidenceRefs: evidenceRefs,
                                  ),
                                )
                              else ...[
                                GlassCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pick what is happening now to get your first step.',
                                        style: _StTokens.type.body,
                                      ),
                                      const SettleGap.sm(),
                                      Text(
                                        'One tap to start. You can adjust options after guidance is visible.',
                                        style: _StTokens.type.caption.copyWith(
                                          color: _StTokens.pal.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SettleGap.md(),
                              ],
                              if (state.lastError != null) ...[
                                const SettleGap.sm(),
                                legacy_glass.GlassCardRose(
                                  child: Text(
                                    state.lastError!,
                                    style: _StTokens.type.caption.copyWith(
                                      color: _StTokens.pal.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                              const SettleGap.md(),
                              const _SleepSectionHeader(label: 'SUPPORT'),
                              const SettleGap.sm(),
                              if (state.hasActivePlan) ...[
                                Center(
                                  child: SettleTappable(
                                    semanticLabel: 'In the moment? Open Moment',
                                    onTap: () => context.push(
                                      '/plan/moment?context=sleep',
                                    ),
                                    child: Text(
                                      'In the moment? → Moment',
                                      style: _StTokens.type.caption.copyWith(
                                        color: SettleColors.nightAccent
                                            .withValues(alpha: 0.5),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                                const SettleGap.sm(),
                                Wrap(
                                  spacing: SettleSpacing.sm,
                                  runSpacing: SettleSpacing.sm,
                                  children: [
                                    legacy_glass.GlassPill(
                                      label: 'View rhythm',
                                      onTap: () =>
                                          context.push('/sleep/rhythm'),
                                    ),
                                    legacy_glass.GlassPill(
                                      label: 'Update rhythm',
                                      onTap: () =>
                                          context.push('/sleep/update'),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Center(
                                  child: SettleTappable(
                                    semanticLabel:
                                        'Need to regulate first? Open Moment',
                                    onTap: () => context.push(
                                      '/plan/moment?context=sleep',
                                    ),
                                    child: Text(
                                      'Need to regulate first? → Moment',
                                      style: _StTokens.type.caption.copyWith(
                                        color: SettleColors.nightAccent
                                            .withValues(alpha: 0.6),
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                              const SettleGap.xxl(),
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

/// Scene header: glass moon, stars, "Sleep tonight", "What's happening?". Dark only.
class _SleepTonightSceneHeader extends StatelessWidget {
  const _SleepTonightSceneHeader();

  static const double _moonSize = 44;
  static const double _moonBlur = 20;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Stars: 5 dots 1.5px, white 30%, scattered
              Positioned(left: 4, top: 6, child: _starDot()),
              Positioned(right: 8, top: 4, child: _starDot()),
              Positioned(left: 12, top: 14, child: _starDot()),
              Positioned(right: 2, top: 18, child: _starDot()),
              Positioned(left: 28, top: 2, child: _starDot()),
              // Glass moon centered
              Center(
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _moonBlur,
                      sigmaY: _moonBlur,
                    ),
                    child: Container(
                      width: _moonSize,
                      height: _moonSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                          width: 0.5,
                        ),
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Specular arc: top 35%
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              height: _moonSize * 0.35,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.06),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Center(
                            child: Icon(
                              Icons.nightlight_round,
                              size: 20,
                              color: SettleColors.nightAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SettleGap.md(),
        Text(
          'Sleep tonight',
          textAlign: TextAlign.center,
          style: _StTokens.type.h2.copyWith(
            fontWeight: FontWeight.w400,
            color: SettleColors.nightText,
          ),
        ),
        const SettleGap.xs(),
        Text(
          "What's happening?",
          textAlign: TextAlign.center,
          style: SettleTypography.caption.copyWith(
            color: SettleColors.nightMuted,
          ),
        ),
      ],
    );
  }

  Widget _starDot() {
    return Container(
      width: 1.5,
      height: 1.5,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.3),
      ),
    );
  }
}

class _SleepSectionHeader extends StatelessWidget {
  const _SleepSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: SettleSpacing.xs),
      child: Text(
        label,
        style: SettleTypography.overline.copyWith(
          color: SettleColors.nightMuted,
        ),
      ),
    );
  }
}

/// Three option cards (GlassCard dark) + Moment link. Dark only.
class _SleepTonightSituationPicker extends StatelessWidget {
  const _SleepTonightSituationPicker({required this.onTapScenario});

  final ValueChanged<String> onTapScenario;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SleepOptionCard(
          icon: Icons.bedtime_rounded,
          title: 'Bedtime protest',
          subtitle: "Won't settle at bedtime",
          onTap: () => onTapScenario('bedtime_protest'),
        ),
        const SettleGap.sm(),
        _SleepOptionCard(
          icon: Icons.nightlight_round,
          title: 'Night wake',
          subtitle: 'Up in the middle of the night',
          onTap: () => onTapScenario('night_wakes'),
        ),
        const SettleGap.sm(),
        _SleepOptionCard(
          icon: Icons.wb_twilight_rounded,
          title: 'Early wake',
          subtitle: 'Up too early',
          onTap: () => onTapScenario('early_wakes'),
        ),
        const SettleGap.md(),
        Center(
          child: SettleTappable(
            semanticLabel: 'In the moment? Open Moment',
            onTap: () => context.push('/plan/moment?context=sleep'),
            child: Text(
              'In the moment? → Moment',
              style: _StTokens.type.caption.copyWith(
                color: SettleColors.nightAccent.withValues(alpha: 0.5),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// One row: icon container (38px, glass, emoji) | title + subtitle | chevron. GlassCard dark.
class _SleepOptionCard extends StatelessWidget {
  const _SleepOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SettleTappable(
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      child: GlassCard(
        variant: GlassCardVariant.dark,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SettleColors.nightAccent.withValues(alpha: 0.08),
                border: Border.all(
                  color: SettleColors.nightAccent.withValues(alpha: 0.16),
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 20, color: SettleColors.nightAccent),
            ),
            const SettleGap.md(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: SettleTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: SettleColors.nightText,
                    ),
                  ),
                  const SettleGap.xs(),
                  Text(
                    subtitle,
                    style: SettleTypography.caption.copyWith(
                      color: SettleColors.nightMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '›',
              style: _StTokens.type.body.copyWith(
                fontWeight: FontWeight.w300,
                color: SettleColors.nightMuted.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThreeLineGuidanceCard extends StatelessWidget {
  const _ThreeLineGuidanceCard({
    required this.approachLabel,
    required this.commitmentLabel,
    required this.plan,
    this.runnerHint,
    required this.onNextStep,
    required this.onClose,
    required this.onSaveToPlaybook,
    this.onShare,
    required this.onMoreOptions,
  });

  final String approachLabel;
  final String commitmentLabel;
  final Map<String, dynamic> plan;
  final String? runnerHint;
  final VoidCallback onNextStep;
  final VoidCallback onClose;
  final VoidCallback onSaveToPlaybook;
  final VoidCallback? onShare;
  final VoidCallback onMoreOptions;

  static const _maxSteps = 3;

  String _singleLine(String text, String fallback) {
    final compact = text.replaceAll('\n', ' ').trim();
    return compact.isEmpty ? fallback : compact;
  }

  @override
  Widget build(BuildContext context) {
    final allSteps = (plan['steps'] as List?)?.cast<Map>() ?? [];
    final steps = allSteps.length > _maxSteps
        ? allSteps.sublist(0, _maxSteps)
        : allSteps;
    final current = steps.isEmpty
        ? 0
        : (plan['current_step'] as int? ?? 0).clamp(0, steps.length - 1);
    final currentStep = steps.isEmpty
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(steps[current]);
    final stepMinutes = (currentStep['minutes'] as int?) ?? 3;
    final isLastStep = steps.isNotEmpty && current >= steps.length - 1;

    final doNow = _singleLine(
      currentStep['script']?.toString() ?? '',
      'Keep your response calm and consistent.',
    );
    final ifStill = _singleLine(
      currentStep['do_step']?.toString() ?? '',
      'Repeat the same brief response.',
    );
    final stopRule = _singleLine(
      plan['escalation_rule']?.toString() ?? '',
      'Pause and switch to comfort-first if things escalate.',
    );

    return legacy_glass.GlassCardAccent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Approach: $approachLabel • $commitmentLabel',
            style: _StTokens.type.caption.copyWith(
              color: _StTokens.pal.textSecondary,
            ),
          ),
          const SettleGap.md(),
          Text('Do now: $doNow', style: _StTokens.type.h3),
          const SettleGap.md(),
          Text(
            'If still crying after $stepMinutes min: $ifStill',
            style: _StTokens.type.h3,
          ),
          const SettleGap.md(),
          Text('Stop rule: $stopRule', style: _StTokens.type.h3),
          if (runnerHint != null && runnerHint!.trim().isNotEmpty) ...[
            const SettleGap.md(),
            Text(
              runnerHint!,
              style: _StTokens.type.caption.copyWith(
                color: _StTokens.pal.textSecondary,
              ),
            ),
          ],
          const SettleGap.md(),
          if (isLastStep) ...[
            Row(
              children: [
                Expanded(
                  child: legacy_glass.GlassCta(
                    label: 'Close',
                    onTap: onClose,
                    compact: true,
                  ),
                ),
                const SettleGap.md(),
                Expanded(
                  child: legacy_glass.GlassCta(
                    label: 'Save to Playbook',
                    onTap: onSaveToPlaybook,
                    compact: true,
                  ),
                ),
              ],
            ),
            if (onShare != null) ...[
              const SettleGap.sm(),
              legacy_glass.GlassCta(
                label: 'Send',
                onTap: onShare!,
                compact: true,
              ),
            ],
          ] else
            legacy_glass.GlassCta(label: 'Next step', onTap: onNextStep),
          const SettleGap.sm(),
          legacy_glass.GlassPill(label: 'More options', onTap: onMoreOptions),
        ],
      ),
    );
  }
}
