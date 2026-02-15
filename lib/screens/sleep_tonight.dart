import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/approach.dart';
import '../providers/profile_provider.dart';
import '../providers/release_rollout_provider.dart';
import '../providers/sleep_tonight_provider.dart';
import '../services/sleep_guidance_service.dart';
import '../services/spec_policy.dart';
import '../theme/glass_components.dart';
import '../theme/settle_tokens.dart';
import '../widgets/calm_loading.dart';
import '../widgets/release_surfaces.dart';
import '../widgets/screen_header.dart';
import '../widgets/settle_disclosure.dart';

class SleepTonightScreen extends ConsumerStatefulWidget {
  const SleepTonightScreen({super.key});

  @override
  ConsumerState<SleepTonightScreen> createState() => _SleepTonightScreenState();
}

class _SleepTonightScreenState extends ConsumerState<SleepTonightScreen> {
  String _scenario = 'bedtime_protest';
  bool _feedingAssociation = false;
  String _feedMode = 'keep_feeds';

  String? _loadedChildId;
  bool _loadScheduled = false;
  DateTime? _screenOpenedAt;
  bool _didHydrateScenario = false;

  @override
  void initState() {
    super.initState();
    _screenOpenedAt = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didHydrateScenario) return;
    _didHydrateScenario = true;

    final scenario = GoRouterState.of(context).uri.queryParameters['scenario'];
    final allowed = const {
      'bedtime_protest',
      'night_wakes',
      'early_wakes',
      'split_nights',
    };
    if (scenario != null && allowed.contains(scenario)) {
      _scenario = scenario;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool _isTrainingAgeAllowed(AgeBracket age) {
    return age.index >= AgeBracket.fourToFiveMonths.index;
  }

  int _ageMonthsFor(AgeBracket age) {
    final months = switch (age) {
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
    return months.clamp(0, 35);
  }

  String _legacyPreferenceForApproach(Approach approach) {
    return switch (approach) {
      Approach.stayAndSupport => 'gentle',
      Approach.checkAndReassure => 'gentle',
      Approach.cueBased => 'standard',
      Approach.rhythmFirst => 'standard',
    };
  }

  String _lockedMethodIdForApproach(Approach approach) {
    return switch (approach) {
      Approach.stayAndSupport => 'fading_chair',
      Approach.checkAndReassure => 'check_console',
      Approach.cueBased => 'check_console',
      Approach.rhythmFirst => 'foundations_only',
    };
  }

  void _loadPlanIfNeeded() {
    final profile = ref.read(profileProvider);
    if (profile == null) return;
    final childId = profile.createdAt;
    if (_loadedChildId == childId) return;
    if (_loadScheduled) return;
    _loadedChildId = childId;
    _loadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScheduled = false;
      if (!mounted) return;
      ref.read(sleepTonightProvider.notifier).loadTonightPlan(childId);
    });
  }

  int? _timeToStartSeconds() {
    final openedAt = _screenOpenedAt;
    if (openedAt == null) return null;
    final diff = DateTime.now().difference(openedAt).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  void _updateSafetyGate({
    required SleepTonightState state,
    bool? breathingDifficulty,
    bool? dehydrationSigns,
    bool? repeatedVomiting,
    bool? severePainIndicators,
    bool? feedingRefusalWithPainSigns,
    bool? safeSleepConfirmed,
  }) {
    ref
        .read(sleepTonightProvider.notifier)
        .updateSafetyGate(
          breathingDifficulty: breathingDifficulty ?? state.breathingDifficulty,
          dehydrationSigns: dehydrationSigns ?? state.dehydrationSigns,
          repeatedVomiting: repeatedVomiting ?? state.repeatedVomiting,
          severePainIndicators:
              severePainIndicators ?? state.severePainIndicators,
          feedingRefusalWithPainSigns:
              feedingRefusalWithPainSigns ?? state.feedingRefusalWithPainSigns,
          safeSleepConfirmed: safeSleepConfirmed ?? state.safeSleepConfirmed,
        );
  }

  List<String> _evidenceRefsFromPlan(Map<String, dynamic>? plan) {
    final raw = plan?['evidence_refs'];
    if (raw is! List) return const [];
    return raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
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
                  maxHeight: MediaQuery.of(context).size.height * 0.78,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text('Why this plan', style: T.type.h3),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: T.pal.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This plan maps to evidence-linked guidance records.',
                        style: T.type.caption.copyWith(
                          color: T.pal.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (items.isEmpty)
                        Text(
                          'No evidence records were found for this plan.',
                          style: T.type.caption.copyWith(
                            color: T.pal.textSecondary,
                          ),
                        )
                      else
                        ...items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassCard(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: T.type.label),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.claim,
                                    style: T.type.caption.copyWith(
                                      color: T.pal.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '${item.sources.length} source(s)',
                                    style: T.type.caption.copyWith(
                                      color: T.pal.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  ...item.sources
                                      .take(2)
                                      .map(
                                        (source) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          child: Text(
                                            '• ${source.citation}',
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

  @override
  Widget build(BuildContext context) {
    _loadPlanIfNeeded();

    final rollout = ref.watch(releaseRolloutProvider);
    if (!rollout.isLoading && !rollout.sleepTonightEnabled) {
      final fallback = pausedFallback(
        preferredEnabled: rollout.helpNowEnabled,
        preferredLabel: 'Open Now: Incident',
        preferredRoute: SpecPolicy.nowIncidentUri(source: 'sleep_paused'),
      );
      return FeaturePausedView(
        title: 'Sleep Tonight',
        fallbackLabel: fallback.label,
        fallbackRoute: fallback.route,
      );
    }

    final profile = ref.watch(profileProvider);
    final state = ref.watch(sleepTonightProvider);
    final activeEvidenceRefs = _evidenceRefsFromPlan(state.activePlan);
    final hasRedFlags = state.redFlagTriggered;
    final showSafetyGate =
        !state.hasActivePlan || !state.safeSleepConfirmed || hasRedFlags;

    if (profile == null) {
      return const ProfileRequiredView(title: 'Sleep Tonight');
    }

    final childId = profile.createdAt;
    final trainingAllowed = _isTrainingAgeAllowed(profile.ageBracket);
    final source = GoRouterState.of(context).uri.queryParameters['source'];
    final fromNightEntry = source != null && source.contains('night');
    final isNightContext = SpecPolicy.isNight(DateTime.now());
    final showNightSupportLinks =
        fromNightEntry || isNightContext || state.hasActivePlan || hasRedFlags;

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Tonight\'s Sleep',
                  subtitle: 'One step at a time. We\'ll guide you.',
                ),
                const SizedBox(height: 4),
                const BehavioralScopeNotice(),
                if (showNightSupportLinks) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _ContextLink(
                        label: 'Current rhythm',
                        onTap: () => context.push('/sleep/rhythm'),
                      ),
                      _ContextLink(
                        label: 'Take a breath',
                        onTap: () => context.push(
                          SpecPolicy.nowResetUri(
                            source: 'sleep',
                            returnMode: SpecPolicy.nowModeSleep,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Expanded(
                  child: state.isLoading
                      ? const CalmLoading(message: 'Getting your plan ready…')
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!trainingAllowed)
                                GlassCard(
                                  child: Text(
                                    'Tonight is a foundations night for this age.',
                                    style: T.type.body,
                                  ),
                                ),
                              if (state.lastError != null) ...[
                                const SizedBox(height: 10),
                                GlassCard(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'We couldn\'t load tonight\'s plan. Try again soon.',
                                        style: T.type.body,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Your previous settings are still saved.',
                                        style: T.type.caption.copyWith(
                                          color: T.pal.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (showSafetyGate)
                                _SafetyGate(
                                  breathingDifficulty:
                                      state.breathingDifficulty,
                                  dehydrationSigns: state.dehydrationSigns,
                                  repeatedVomiting: state.repeatedVomiting,
                                  severePainIndicators:
                                      state.severePainIndicators,
                                  feedingRefusalWithPainSigns:
                                      state.feedingRefusalWithPainSigns,
                                  safeSleepConfirmed: state.safeSleepConfirmed,
                                  onBreathingDifficultyChanged: (v) =>
                                      _updateSafetyGate(
                                        state: state,
                                        breathingDifficulty: v,
                                      ),
                                  onDehydrationSignsChanged: (v) =>
                                      _updateSafetyGate(
                                        state: state,
                                        dehydrationSigns: v,
                                      ),
                                  onRepeatedVomitingChanged: (v) =>
                                      _updateSafetyGate(
                                        state: state,
                                        repeatedVomiting: v,
                                      ),
                                  onSeverePainIndicatorsChanged: (v) =>
                                      _updateSafetyGate(
                                        state: state,
                                        severePainIndicators: v,
                                      ),
                                  onFeedingRefusalWithPainSignsChanged: (v) =>
                                      _updateSafetyGate(
                                        state: state,
                                        feedingRefusalWithPainSigns: v,
                                      ),
                                  onSafeSleepChanged: (v) => _updateSafetyGate(
                                    state: state,
                                    safeSleepConfirmed: v,
                                  ),
                                ),
                              if (showSafetyGate) const SizedBox(height: 12),
                              if (hasRedFlags)
                                GlassCardRose(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pause the plan. Comfort first. If you\'re worried, contact your pediatric clinician.',
                                        style: T.type.body,
                                      ),
                                      if (state.hasActivePlan) ...[
                                        const SizedBox(height: 10),
                                        _SecondaryActionLink(
                                          label: 'Pause active plan',
                                          onTap: () => ref
                                              .read(
                                                sleepTonightProvider.notifier,
                                              )
                                              .abortPlan(),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              else if (!trainingAllowed)
                                const _FoundationsOnlyCard()
                              else if (state.hasActivePlan &&
                                  state.safeSleepConfirmed)
                                _NightWakeCard(
                                  plan: state.activePlan!,
                                  evidenceCount: activeEvidenceRefs.length,
                                  comfortMode: state.comfortMode,
                                  somethingFeelsOff: state.somethingFeelsOff,
                                  onViewEvidence: activeEvidenceRefs.isEmpty
                                      ? null
                                      : () => _showEvidenceSheet(
                                          activeEvidenceRefs,
                                        ),
                                  onModeChanged: (isComfortMode) => ref
                                      .read(sleepTonightProvider.notifier)
                                      .setComfortMode(isComfortMode),
                                  onSomethingFeelsOff: () => ref
                                      .read(sleepTonightProvider.notifier)
                                      .markSomethingFeelsOff(),
                                  onLogWake: () => ref
                                      .read(sleepTonightProvider.notifier)
                                      .logNightWake(),
                                  onMorningReview: () => ref
                                      .read(sleepTonightProvider.notifier)
                                      .completeMorningReview(),
                                  onAbort: () => ref
                                      .read(sleepTonightProvider.notifier)
                                      .abortPlan(),
                                )
                              else if (state.hasActivePlan &&
                                  !state.safeSleepConfirmed)
                                GlassCard(
                                  child: Text(
                                    'Confirm the sleep space is safe to resume.',
                                    style: T.type.body,
                                  ),
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _ScenarioQuickPick(
                                      scenario: _scenario,
                                      onScenarioChanged: (v) =>
                                          setState(() => _scenario = v),
                                    ),
                                    const SizedBox(height: 10),
                                    _TonightInputs(
                                      approachLabel: profile.approach.label,
                                      feedingAssociation: _feedingAssociation,
                                      feedMode: _feedMode,
                                      onFeedingAssociationChanged: (v) =>
                                          setState(
                                            () => _feedingAssociation = v,
                                          ),
                                      onFeedModeChanged: (v) =>
                                          setState(() => _feedMode = v),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 14),
                              if (!hasRedFlags &&
                                  trainingAllowed &&
                                  !state.hasActivePlan)
                                GlassCta(
                                  label: 'Start now',
                                  enabled: state.safeSleepConfirmed,
                                  onTap: () => ref
                                      .read(sleepTonightProvider.notifier)
                                      .createTonightPlan(
                                        childId: childId,
                                        ageMonths: _ageMonthsFor(
                                          profile.ageBracket,
                                        ),
                                        scenario: _scenario,
                                        preference:
                                            _legacyPreferenceForApproach(
                                              profile.approach,
                                            ),
                                        feedingAssociation: _feedingAssociation,
                                        feedMode: _feedMode,
                                        lockedMethodId:
                                            _lockedMethodIdForApproach(
                                              profile.approach,
                                            ),
                                        safeSleepConfirmed:
                                            state.safeSleepConfirmed,
                                        timeToStartSeconds:
                                            _timeToStartSeconds(),
                                      ),
                                ),
                              if (!state.safeSleepConfirmed &&
                                  trainingAllowed &&
                                  !state.hasActivePlan)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Confirm the sleep space is safe to begin.',
                                    style: T.type.caption.copyWith(
                                      color: T.pal.textTertiary,
                                    ),
                                  ),
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

class _ContextLink extends StatelessWidget {
  const _ContextLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: T.type.caption.copyWith(
          color: T.pal.textTertiary,
          decoration: TextDecoration.underline,
          decorationColor: T.pal.textTertiary,
        ),
      ),
    );
  }
}

class _SafetyGate extends StatelessWidget {
  const _SafetyGate({
    required this.breathingDifficulty,
    required this.dehydrationSigns,
    required this.repeatedVomiting,
    required this.severePainIndicators,
    required this.feedingRefusalWithPainSigns,
    required this.safeSleepConfirmed,
    required this.onBreathingDifficultyChanged,
    required this.onDehydrationSignsChanged,
    required this.onRepeatedVomitingChanged,
    required this.onSeverePainIndicatorsChanged,
    required this.onFeedingRefusalWithPainSignsChanged,
    required this.onSafeSleepChanged,
  });

  final bool breathingDifficulty;
  final bool dehydrationSigns;
  final bool repeatedVomiting;
  final bool severePainIndicators;
  final bool feedingRefusalWithPainSigns;
  final bool safeSleepConfirmed;
  final ValueChanged<bool> onBreathingDifficultyChanged;
  final ValueChanged<bool> onDehydrationSignsChanged;
  final ValueChanged<bool> onRepeatedVomitingChanged;
  final ValueChanged<bool> onSeverePainIndicatorsChanged;
  final ValueChanged<bool> onFeedingRefusalWithPainSignsChanged;
  final ValueChanged<bool> onSafeSleepChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick safety check', style: T.type.h3),
          const SizedBox(height: 8),
          Text(
            'Before we start, one quick check.',
            style: T.type.caption.copyWith(color: T.pal.textSecondary),
          ),
          const SizedBox(height: 12),
          _SafetySwitchRow(
            label: 'Sleep space is safe',
            value: safeSleepConfirmed,
            onChanged: onSafeSleepChanged,
          ),
          const SizedBox(height: 6),
          SettleDisclosure(
            title: 'More safety checks (optional)',
            titleStyle: T.type.caption.copyWith(color: T.pal.textSecondary),
            children: [
              _SafetySwitchRow(
                label: 'Breathing difficulty',
                value: breathingDifficulty,
                onChanged: onBreathingDifficultyChanged,
              ),
              _SafetySwitchRow(
                label: 'Dehydration signs',
                value: dehydrationSigns,
                onChanged: onDehydrationSignsChanged,
              ),
              _SafetySwitchRow(
                label: 'Repeated vomiting',
                value: repeatedVomiting,
                onChanged: onRepeatedVomitingChanged,
              ),
              _SafetySwitchRow(
                label: 'Strong pain signs',
                value: severePainIndicators,
                onChanged: onSeverePainIndicatorsChanged,
              ),
              _SafetySwitchRow(
                label: 'Refusing feeds with pain signs',
                value: feedingRefusalWithPainSigns,
                onChanged: onFeedingRefusalWithPainSignsChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SafetySwitchRow extends StatelessWidget {
  const _SafetySwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: T.type.caption)),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: T.pal.accent,
        ),
      ],
    );
  }
}

class _ScenarioQuickPick extends StatelessWidget {
  const _ScenarioQuickPick({
    required this.scenario,
    required this.onScenarioChanged,
  });

  final String scenario;
  final ValueChanged<String> onScenarioChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What is happening tonight?', style: T.type.label),
          const SizedBox(height: 8),
          _ChoiceWrap(
            options: const {
              'bedtime_protest': 'Bedtime protest',
              'night_wakes': 'Night wake',
              'early_wakes': 'Early wake',
              'split_nights': 'Split night',
            },
            selected: scenario,
            onChanged: onScenarioChanged,
          ),
        ],
      ),
    );
  }
}

class _TonightInputs extends StatelessWidget {
  const _TonightInputs({
    required this.approachLabel,
    required this.feedingAssociation,
    required this.feedMode,
    required this.onFeedingAssociationChanged,
    required this.onFeedModeChanged,
  });

  final String approachLabel;
  final bool feedingAssociation;
  final String feedMode;
  final ValueChanged<bool> onFeedingAssociationChanged;
  final ValueChanged<String> onFeedModeChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SettleDisclosure(
        title: 'Optional tonight inputs',
        children: [
          Text(
            'Approach locked for tonight: $approachLabel',
            style: T.type.caption.copyWith(color: T.pal.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text('Feeding-to-sleep pattern?', style: T.type.caption),
              ),
              Switch.adaptive(
                value: feedingAssociation,
                onChanged: onFeedingAssociationChanged,
                activeColor: T.pal.accent,
              ),
            ],
          ),
          if (feedingAssociation) ...[
            const SizedBox(height: 6),
            _ChoiceWrap(
              options: const {
                'keep_feeds': 'Keep feeds',
                'reduce_gradually': 'Reduce gradually',
                'separate_feed_sleep': 'Separate feed from sleep',
              },
              selected: feedMode,
              onChanged: onFeedModeChanged,
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FoundationsOnlyCard extends StatelessWidget {
  const _FoundationsOnlyCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Foundations only tonight', style: T.type.h3),
          const SizedBox(height: 8),
          Text(
            'No formal training plan at this age. Keep routine calm, use brief reassurance, and protect sleep cues.',
            style: T.type.body.copyWith(color: T.pal.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            'If distress persists, pause and comfort first.',
            style: T.type.caption.copyWith(color: T.pal.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _NightWakeCard extends StatelessWidget {
  const _NightWakeCard({
    required this.plan,
    required this.evidenceCount,
    required this.onViewEvidence,
    required this.comfortMode,
    required this.somethingFeelsOff,
    required this.onModeChanged,
    required this.onSomethingFeelsOff,
    required this.onLogWake,
    required this.onMorningReview,
    required this.onAbort,
  });

  final Map<String, dynamic> plan;
  final int evidenceCount;
  final VoidCallback? onViewEvidence;
  final bool comfortMode;
  final bool somethingFeelsOff;
  final ValueChanged<bool> onModeChanged;
  final VoidCallback onSomethingFeelsOff;
  final VoidCallback onLogWake;
  final VoidCallback onMorningReview;
  final VoidCallback onAbort;

  String _singleLine(String text, String fallback) {
    final compact = text.replaceAll('\n', ' ').trim();
    return compact.isEmpty ? fallback : compact;
  }

  @override
  Widget build(BuildContext context) {
    final steps = (plan['steps'] as List?)?.cast<Map>() ?? [];
    final current = steps.isEmpty
        ? 0
        : (plan['current_step'] as int? ?? 0).clamp(0, steps.length - 1);
    final currentStep = steps.isEmpty
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(steps[current]);
    final doStep = currentStep['do_step']?.toString() ?? '';
    final runnerHint = plan['runner_hint']?.toString() ?? '';
    final escalationRule = plan['escalation_rule']?.toString() ?? '';
    final stepMinutes = (currentStep['minutes'] as int?) ?? 3;

    final doNow = comfortMode
        ? 'Go in now and offer calm comfort in a dark, low-stimulation room.'
        : _singleLine(
            currentStep['script']?.toString() ?? '',
            'Keep your response brief and consistent.',
          );
    final ifStillCrying = comfortMode
        ? 'Repeat the same comfort routine after 10 min if crying continues.'
        : 'After $stepMinutes min: ${_singleLine(doStep, 'repeat the same brief response.')}';
    final stopRule = somethingFeelsOff
        ? 'Pause training expectations tonight and stay comfort-first.'
        : _singleLine(
            escalationRule,
            'Pause and switch to comfort mode if things escalate.',
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCardAccent(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Night Wake Card',
                  style: T.type.h3.copyWith(color: T.pal.accent),
                ),
              ),
              if (somethingFeelsOff)
                Text(
                  'Comfort-first',
                  style: T.type.caption.copyWith(color: T.pal.accent),
                ),
            ],
          ),
        ),
        if (onViewEvidence != null && evidenceCount > 0) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onViewEvidence,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.menu_book_outlined,
                    size: 14,
                    color: T.pal.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Why this? ($evidenceCount)',
                    style: T.type.caption.copyWith(color: T.pal.textTertiary),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 10),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (runnerHint.isNotEmpty) ...[
                Text(
                  runnerHint,
                  style: T.type.caption.copyWith(color: T.pal.textSecondary),
                ),
                const SizedBox(height: 10),
              ],
              Text('Mode', style: T.type.overline),
              const SizedBox(height: 8),
              _ChoiceWrap(
                options: const {
                  'training': 'Training mode',
                  'comfort': 'Comfort mode',
                },
                selected: comfortMode ? 'comfort' : 'training',
                onChanged: (v) => onModeChanged(v == 'comfort'),
              ),
              const SizedBox(height: 12),
              Text('Do now', style: T.type.overline),
              const SizedBox(height: 6),
              Text(
                doNow,
                style: T.type.body.copyWith(color: T.pal.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'If still crying: $ifStillCrying',
                style: T.type.body.copyWith(color: T.pal.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                'Stop rule: $stopRule',
                style: T.type.body.copyWith(color: T.pal.textSecondary),
              ),
              const SizedBox(height: 10),
              _ActionChip(
                label: 'Something feels off',
                selected: somethingFeelsOff,
                onTap: onSomethingFeelsOff,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SettleDisclosure(
            title: 'More actions',
            titleStyle: T.type.caption.copyWith(color: T.pal.textSecondary),
            children: [
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionChip(label: 'Log wake', onTap: onLogWake),
                  _ActionChip(
                    label: 'Morning recap done',
                    onTap: onMorningReview,
                  ),
                  _ActionChip(label: 'Pause plan for tonight', onTap: onAbort),
                ],
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ],
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

class _SecondaryActionLink extends StatelessWidget {
  const _SecondaryActionLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: T.type.caption.copyWith(
          color: T.pal.textTertiary,
          decoration: TextDecoration.underline,
          decorationColor: T.pal.textTertiary,
        ),
      ),
    );
  }
}
