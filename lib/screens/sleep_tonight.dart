import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
import '../theme/glass_components.dart' hide GlassCard;
import '../theme/settle_design_system.dart';
import '../theme/settle_tokens.dart';
import '../widgets/calm_loading.dart';
import '../widgets/glass_card.dart';
import '../widgets/release_surfaces.dart';
import '../widgets/screen_header.dart';
import '../widgets/settle_segmented_choice.dart';
import '../widgets/settle_tappable.dart';

class SleepTonightScreen extends ConsumerStatefulWidget {
  const SleepTonightScreen({super.key});

  @override
  ConsumerState<SleepTonightScreen> createState() => _SleepTonightScreenState();
}

class _SleepTonightScreenState extends ConsumerState<SleepTonightScreen> {
  String _scenario = 'night_wakes';
  bool _feedingAssociation = false;
  final String _feedMode = 'keep_feeds';
  TimeOfDay? _lastFeedTime;
  TimeOfDay? _lastNapEndTime;

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
              T.space.screen,
              T.space.md,
              T.space.screen,
              T.space.screen,
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
                      Text('Why this works', style: T.type.h3),
                      const SizedBox(height: 8),
                      if (items.isEmpty)
                        Text(
                          'No evidence details are available for this card right now.',
                          style: T.type.caption.copyWith(
                            color: T.pal.textSecondary,
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
                                  style: T.type.caption.copyWith(
                                    color: T.pal.textSecondary,
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
                  T.space.screen + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: GlassCard(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quick recap', style: T.type.h3),
                        const SizedBox(height: 10),
                        Text('Outcome', style: T.type.label),
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
                        Text('Time to settle (optional)', style: T.type.label),
                        const SizedBox(height: 8),
                        SettleSegmentedChoice<String>(
                          options: const ['<5', '5-15', '15-30', '30+'],
                          selected: timeBucket ?? '<5',
                          labelBuilder: (v) => '$v min',
                          onChanged: (v) => setModalState(() => timeBucket = v),
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
                        GlassCta(
                          label: 'Save recap',
                          compact: true,
                          onTap: () async {
                            await ref
                                .read(sleepTonightProvider.notifier)
                                .completeWithRecap(
                                  childId: childId,
                                  outcome: outcome,
                                  timeToSettleBucket: timeBucket,
                                  note: noteController.text.trim(),
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
    noteController.dispose();
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
                  T.space.screen,
                  T.space.md,
                  T.space.screen,
                  T.space.screen + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: GlassCard(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Change approach', style: T.type.h3),
                        const SizedBox(height: 10),
                        Text('Approach', style: T.type.label),
                        const SizedBox(height: 8),
                        SettleSegmentedChoice<Approach>(
                          options: Approach.values,
                          selected: next,
                          labelBuilder: (v) => v.label,
                          onChanged: (v) => setModalState(() => next = v),
                        ),
                        const SizedBox(height: 10),
                        Text('Reason', style: T.type.label),
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
                        Text('Effective timing', style: T.type.label),
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
                          style: T.type.caption.copyWith(
                            color: T.pal.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassCta(
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
                  T.space.screen,
                  T.space.md,
                  T.space.screen,
                  T.space.screen + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: GlassCard(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Make guidance fit your home', style: T.type.h3),
                        const SizedBox(height: 4),
                        Text(
                          '15 seconds',
                          style: T.type.caption.copyWith(
                            color: T.pal.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Shared room', style: T.type.caption),
                          value: sharedRoom,
                          onChanged: (v) => setModalState(() => sharedRoom = v),
                        ),
                        Text('Caregiver consistency', style: T.type.caption),
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
                        Text('Crying tolerance', style: T.type.caption),
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
                          title: Text('Can leave room', style: T.type.caption),
                          value: canLeaveRoom,
                          onChanged: (v) =>
                              setModalState(() => canLeaveRoom = v),
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Night feeds expected',
                            style: T.type.caption,
                          ),
                          value: nightFeedsExpected,
                          onChanged: (v) =>
                              setModalState(() => nightFeedsExpected = v),
                        ),
                        const SizedBox(height: 10),
                        GlassCta(
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
    VoidCallback? onShare,
  }) async {
    var selectedScenario =
        state.activePlan?['scenario']?.toString() ?? _scenario;
    var localComfortMode = state.comfortMode;
    var quickDone = state.quickDoneEnabled;
    var safeSleepConfirmed = state.safeSleepConfirmed;

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
                  T.space.screen,
                  T.space.md,
                  T.space.screen,
                  T.space.screen,
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
                          Text('More options', style: T.type.h3),
                          const SizedBox(height: 12),
                          if (onShare != null) ...[
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                onShare();
                              },
                              icon: const Icon(Icons.share_outlined, size: 18),
                              label: const Text('Send plan'),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Text('Switch scenario', style: T.type.label),
                          const SizedBox(height: 8),
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
                          const SizedBox(height: 10),
                          ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            title: Text('Optional inputs', style: T.type.label),
                            children: [
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _lastFeedTime == null
                                          ? 'Last feed: not set'
                                          : 'Last feed: ${_lastFeedTime!.format(context)}',
                                      style: T.type.caption.copyWith(
                                        color: T.pal.textSecondary,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime:
                                            _lastFeedTime ?? TimeOfDay.now(),
                                      );
                                      if (picked != null && mounted) {
                                        setState(() => _lastFeedTime = picked);
                                        setModalState(() {});
                                      }
                                    },
                                    child: const Text('Set'),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _lastNapEndTime == null
                                          ? 'Last nap end: not set'
                                          : 'Last nap end: ${_lastNapEndTime!.format(context)}',
                                      style: T.type.caption.copyWith(
                                        color: T.pal.textSecondary,
                                      ),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      final picked = await showTimePicker(
                                        context: context,
                                        initialTime:
                                            _lastNapEndTime ?? TimeOfDay.now(),
                                      );
                                      if (picked != null && mounted) {
                                        setState(
                                          () => _lastNapEndTime = picked,
                                        );
                                        setModalState(() {});
                                      }
                                    },
                                    child: const Text('Set'),
                                  ),
                                ],
                              ),
                              SwitchListTile.adaptive(
                                contentPadding: EdgeInsets.zero,
                                title: Text(
                                  'Feeding-to-sleep pattern',
                                  style: T.type.caption,
                                ),
                                value: _feedingAssociation,
                                onChanged: (v) {
                                  setState(() => _feedingAssociation = v);
                                  setModalState(() {});
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (evidenceRefs.isNotEmpty)
                            TextButton(
                              onPressed: () => _showEvidenceSheet(evidenceRefs),
                              child: const Text('Why this works'),
                            ),
                          Text('Log & recap', style: T.type.label),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              OutlinedButton(
                                onPressed: () async {
                                  if (quickDone &&
                                      state.lastRecapOutcome != null) {
                                    await ref
                                        .read(sleepTonightProvider.notifier)
                                        .completeWithRecap(
                                          childId: childId,
                                          outcome: state.lastRecapOutcome!,
                                          timeToSettleBucket:
                                              state.lastTimeToSettleBucket,
                                        );
                                  } else {
                                    await _openRecapSheet(
                                      childId: childId,
                                      state: state,
                                    );
                                  }
                                },
                                child: const Text('Mark done'),
                              ),
                              OutlinedButton(
                                onPressed: () => _openRecapSheet(
                                  childId: childId,
                                  state: state,
                                ),
                                child: const Text('Add note'),
                              ),
                            ],
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Quick done uses last recap defaults',
                              style: T.type.caption,
                            ),
                            value: quickDone,
                            onChanged: (v) async {
                              setModalState(() => quickDone = v);
                              await ref
                                  .read(sleepTonightProvider.notifier)
                                  .setQuickDoneEnabled(
                                    childId: childId,
                                    enabled: v,
                                  );
                            },
                          ),
                          const SizedBox(height: 10),
                          Text('Mode', style: T.type.label),
                          const SizedBox(height: 8),
                          SettleSegmentedChoice<String>(
                            options: const ['training', 'comfort'],
                            selected: localComfortMode ? 'comfort' : 'training',
                            labelBuilder: (v) =>
                                v == 'comfort' ? 'Comfort' : 'Training',
                            onChanged: (v) async {
                              final nextComfort = v == 'comfort';
                              setModalState(
                                () => localComfortMode = nextComfort,
                              );
                              await ref
                                  .read(sleepTonightProvider.notifier)
                                  .setComfortMode(nextComfort);
                            },
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: () async {
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
                            child: const Text('Change approach'),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'If you suspect illness or pain, pause training and comfort first tonight.',
                            style: T.type.caption.copyWith(
                              color: T.pal.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              'Sleep space is safe',
                              style: T.type.caption,
                            ),
                            value: safeSleepConfirmed,
                            onChanged: (v) {
                              setModalState(() => safeSleepConfirmed = v);
                              ref
                                  .read(sleepTonightProvider.notifier)
                                  .updateSafetyGate(
                                    breathingDifficulty:
                                        state.breathingDifficulty,
                                    dehydrationSigns: state.dehydrationSigns,
                                    repeatedVomiting: state.repeatedVomiting,
                                    severePainIndicators:
                                        state.severePainIndicators,
                                    feedingRefusalWithPainSigns:
                                        state.feedingRefusalWithPainSigns,
                                    safeSleepConfirmed: v,
                                  );
                            },
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => ref
                                .read(sleepTonightProvider.notifier)
                                .markSomethingFeelsOff(),
                            child: const Text('Something feels off'),
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
            padding: const EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SleepTonightSceneHeader(),
                const SizedBox(height: 14),
                Expanded(
                  child: state.isLoading
                      ? const CalmLoading(message: 'Getting guidance ready…')
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!state.hasSleepSetup) ...[
                                GlassCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Make guidance fit your home (15 seconds)',
                                        style: T.type.label,
                                      ),
                                      const SizedBox(height: 8),
                                      GlassCta(
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
                                const SizedBox(height: 10),
                              ],
                              if (_isNightContext && _suggestEarlyWake)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Text(
                                    'Might be an early wake? You can switch in More options.',
                                    style: T.type.caption.copyWith(
                                      color: T.pal.textSecondary,
                                    ),
                                  ),
                                ),
                              if (!state.safeSleepConfirmed) ...[
                                GlassCardRose(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Sleep space is not confirmed as safe.',
                                        style: T.type.label,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Confirm safety before starting training guidance.',
                                        style: T.type.caption.copyWith(
                                          color: T.pal.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      GlassCta(
                                        label: 'Confirm sleep space is safe',
                                        compact: true,
                                        onTap: () => ref
                                            .read(sleepTonightProvider.notifier)
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
                                const SizedBox(height: 10),
                              ],
                              if (!state.hasActivePlan)
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
                                )
                              else if (state.hasActivePlan)
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
                                    onShare: () =>
                                        _shareSleepPlan(plan, approach),
                                  ),
                                )
                              else
                                GlassCard(
                                  child: Text(
                                    'Preparing tonight\'s guidance…',
                                    style: T.type.body,
                                  ),
                                ),
                              if (state.lastError != null) ...[
                                const SizedBox(height: 10),
                                GlassCardRose(
                                  child: Text(
                                    state.lastError!,
                                    style: T.type.caption.copyWith(
                                      color: T.pal.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Center(
                                child: SettleTappable(
                                  semanticLabel: 'In the moment? Open Moment',
                                  onTap: () =>
                                      context.push('/plan/moment?context=sleep'),
                                  child: Text(
                                    'In the moment? → Moment',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: SettleColors.nightAccent
                                          .withValues(alpha: 0.5),
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  TextButton(
                                    onPressed: () =>
                                        context.push('/sleep/rhythm'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'View rhythm',
                                      style: T.type.caption.copyWith(
                                        color: T.pal.textTertiary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    ' · ',
                                    style: T.type.caption.copyWith(
                                      color: T.pal.textTertiary,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        context.push('/sleep/update'),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Update rhythm',
                                      style: T.type.caption.copyWith(
                                        color: T.pal.textTertiary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
const SizedBox(height: 24),
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
        const SizedBox(height: 12),
        Text(
          'Sleep tonight',
          textAlign: TextAlign.center,
          style: GoogleFonts.fraunces(
            fontSize: 22,
            fontWeight: FontWeight.w400,
            color: SettleColors.nightText,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "What's happening?",
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w400,
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
          emoji: '😤',
          title: 'Bedtime protest',
          subtitle: "Won't settle at bedtime",
          onTap: () => onTapScenario('bedtime_protest'),
        ),
        const SizedBox(height: SettleSpacing.sm),
        _SleepOptionCard(
          emoji: '🌙',
          title: 'Night wake',
          subtitle: 'Up in the middle of the night',
          onTap: () => onTapScenario('night_wakes'),
        ),
        const SizedBox(height: SettleSpacing.sm),
        _SleepOptionCard(
          emoji: '🌅',
          title: 'Early wake',
          subtitle: 'Up too early',
          onTap: () => onTapScenario('early_wakes'),
        ),
        const SizedBox(height: 12),
        Center(
          child: SettleTappable(
            semanticLabel: 'In the moment? Open Moment',
            onTap: () => context.push('/plan/moment?context=sleep'),
            child: Text(
              'In the moment? → Moment',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
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
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
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
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: SettleColors.nightAccent.withValues(alpha: 0.06),
                border: Border.all(
                  color: SettleColors.nightAccent.withValues(alpha: 0.12),
                  width: 0.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: SettleColors.nightText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: SettleColors.nightMuted,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '›',
              style: GoogleFonts.inter(
                fontSize: 16,
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

class _SituationPicker extends StatelessWidget {
  const _SituationPicker({required this.onTapScenario});

  final ValueChanged<String> onTapScenario;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose what is happening', style: T.type.h3),
          const SizedBox(height: 10),
          _ScenarioButton(
            label: 'Bedtime protest',
            onTap: () => onTapScenario('bedtime_protest'),
          ),
          const SizedBox(height: 8),
          _ScenarioButton(
            label: 'Night wake',
            onTap: () => onTapScenario('night_wakes'),
          ),
          const SizedBox(height: 8),
          _ScenarioButton(
            label: 'Early wake',
            onTap: () => onTapScenario('early_wakes'),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => context.push('/plan/moment?context=sleep'),
            child: Text(
              'In the moment? → Moment',
              style: T.type.caption.copyWith(
                color: T.pal.textTertiary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScenarioButton extends StatelessWidget {
  const _ScenarioButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassCta(
      label: label,
      onTap: onTap,
      compact: true,
      alignment: Alignment.centerLeft,
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

    return GlassCardAccent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Approach: $approachLabel • $commitmentLabel',
            style: T.type.caption.copyWith(color: T.pal.textSecondary),
          ),
          const SizedBox(height: 12),
          Text('Do now: $doNow', style: T.type.h3),
          const SizedBox(height: 10),
          Text(
            'If still crying after $stepMinutes min: $ifStill',
            style: T.type.h3,
          ),
          const SizedBox(height: 10),
          Text('Stop rule: $stopRule', style: T.type.h3),
          if (runnerHint != null && runnerHint!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              runnerHint!,
              style: T.type.caption.copyWith(color: T.pal.textSecondary),
            ),
          ],
          const SizedBox(height: 14),
          if (isLastStep) ...[
            Row(
              children: [
                Expanded(
                  child: GlassCta(
                    label: 'Close',
                    onTap: onClose,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GlassCta(
                    label: 'Save to Playbook',
                    onTap: onSaveToPlaybook,
                    compact: true,
                  ),
                ),
              ],
            ),
            if (onShare != null) ...[
              const SizedBox(height: 8),
              GlassCta(label: 'Send', onTap: onShare!, compact: true),
            ],
          ] else
            GlassCta(label: 'Next step', onTap: onNextStep),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onMoreOptions,
            child: const Text('More options'),
          ),
        ],
      ),
    );
  }
}
