import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/profile_provider.dart';
import '../providers/release_rollout_provider.dart';
import '../services/help_now_age_band_mapper.dart';
import '../services/event_bus_service.dart';
import '../services/help_now_guidance_service.dart';
import '../services/spec_policy.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_pill.dart';
import '../widgets/settle_cta.dart';
import '../theme/settle_design_system.dart';
import '../widgets/gradient_background.dart';
import '../widgets/release_surfaces.dart';
import '../widgets/screen_header.dart';
import '../widgets/settle_disclosure.dart';
import '../widgets/settle_gap.dart';


class HelpNowScreen extends ConsumerStatefulWidget {
  const HelpNowScreen({super.key, this.now});

  final DateTime Function()? now;

  @override
  ConsumerState<HelpNowScreen> createState() => _HelpNowScreenState();
}

class _HelpNowScreenState extends ConsumerState<HelpNowScreen> {
  static const _outcomes = [
    EventOutcomes.improved,
    EventOutcomes.unchanged,
    EventOutcomes.escalated,
    EventOutcomes.aborted,
  ];

  static const _tags = [
    EventTags.hunger,
    EventTags.transition,
    EventTags.screen,
    EventTags.tired,
    EventTags.publicTag,
  ];

  static const _ageBands = ['1-2', '3-5', '6-8', '9-12'];

  _IncidentOption? _incident;
  String? _ageBand;
  _HelpNowOutput? _output;
  Set<String> _selectedTags = <String>{};
  String? _outcome;

  bool _incidentLogged = false;
  bool _nightRouted = false;
  DateTime? _screenOpenedAt;
  bool _didApplyRoutePrefill = false;
  bool _forceIncidentMode = false;

  @override
  void initState() {
    super.initState();
    _screenOpenedAt = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didApplyRoutePrefill) return;
    _didApplyRoutePrefill = true;

    final incidentId = GoRouterState.of(
      context,
    ).uri.queryParameters['incident'];
    if (incidentId == null || incidentId.isEmpty) return;

    final option = _IncidentGrid.optionById(incidentId);
    if (option == null) return;

    _forceIncidentMode = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onIncidentTapped(option, forceIncident: true);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool get _isNight {
    return SpecPolicy.isNight((widget.now ?? DateTime.now)());
  }

  String _childId() {
    final profile = ref.read(profileProvider);
    return profile?.createdAt ?? 'unknown-child';
  }

  int? _timeToActionSeconds() {
    final openedAt = _screenOpenedAt;
    if (openedAt == null) return null;
    final diff = DateTime.now().difference(openedAt).inSeconds;
    return diff < 0 ? 0 : diff;
  }

  String? _inferAgeBand() {
    final profile = ref.read(profileProvider);
    if (profile == null) return null;
    // Always resolve from profile — never show age picker to onboarded users.
    return HelpNowAgeBandMapper.map(profile.ageBracket);
  }

  Future<void> _showNightChoiceModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              SettleSpacing.screenPadding,
              SettleSpacing.md,
              SettleSpacing.screenPadding,
              SettleSpacing.screenPadding,
            ),
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('It\'s nighttime', style: SettleTypography.heading),
                  SettleGap.sm(),
                  Text(
                    'What do you need right now?',
                    style: SettleTypography.caption.copyWith(
                      color: SettleColors.ink500,
                    ),
                  ),
                  SettleGap.lg(),
                  GlassCta(
                    label: 'Sleep support',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.go(SpecPolicy.helpNowNightRouteUri());
                    },
                  ),
                  SettleGap.md(),
                  GlassPill(
                    label: 'Crisis help — stay here',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      setState(() {
                        _forceIncidentMode = true;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _emitIncidentUse() async {
    if (_incident == null || _output == null || _incidentLogged) return;

    await EventBusService.emitHelpNowIncidentUsed(
      childId: _childId(),
      type: _incident!.eventType,
      location: _incident!.id == 'public_meltdown'
          ? EventContextLocation.publicLocation
          : EventContextLocation.home,
      tags: _selectedTags.toList(),
      incident: _incident!.id,
      ageBand: _ageBand ?? 'unknown',
      timerMinutes: _output!.timerMinutes,
      timeToActionSeconds: _timeToActionSeconds(),
      nearMeal: _selectedTags.contains(EventTags.hunger),
      screenOffRelated:
          _selectedTags.contains(EventTags.screen) ||
          _selectedTags.contains(EventTags.screens),
    );

    _incidentLogged = true;
  }

  Future<void> _onIncidentTapped(
    _IncidentOption option, {
    bool forceIncident = false,
  }) async {
    final inferred = _inferAgeBand();

    if (!forceIncident) {
      final now = (widget.now ?? DateTime.now)();
      final routeToSleep = await HelpNowGuidanceService.instance
          .shouldRouteIncidentToSleepNow(
            incidentId: option.id,
            timestamp: now,
            fallbackSleepIncident: option.sleepRelated,
          );

      if (routeToSleep) {
        if (mounted) {
          context.go(SpecPolicy.helpNowIncidentSleepRouteUri(option.id));
        }
        return;
      }
    }

    final resolved = inferred == null
        ? null
        : await _resolveOutput(option.id, inferred);

    setState(() {
      _incident = option;
      _ageBand = inferred;
      _output = resolved;
      _outcome = null;
      _selectedTags = {};
      _incidentLogged = false;
    });

    await _emitIncidentUse();
  }

  Future<void> _onAgeBandSelect(String ageBand) async {
    final incident = _incident;
    if (incident == null) return;
    final resolved = await _resolveOutput(incident.id, ageBand);
    if (!mounted) return;

    setState(() {
      _ageBand = ageBand;
      _output = resolved;
      _incidentLogged = false;
    });

    _emitIncidentUse();
  }

  Future<_HelpNowOutput> _resolveOutput(
    String incidentId,
    String ageBand,
  ) async {
    try {
      final output = await HelpNowGuidanceService.instance
          .resolveIncidentOutput(incidentId: incidentId, ageBand: ageBand);
      return _HelpNowOutput(
        say: output.say,
        doStep: output.doStep,
        timerMinutes: output.timerMinutes,
        ifEscalates: output.ifEscalates,
      );
    } catch (_) {
      return _buildOutput(incidentId, ageBand);
    }
  }

  Future<void> _recordOutcome(String outcome) async {
    final incident = _incident;
    final output = _output;
    if (incident == null || output == null) return;

    setState(() {
      _outcome = outcome;
    });

    await EventBusService.emitHelpNowOutcomeRecorded(
      childId: _childId(),
      location: incident.id == 'public_meltdown'
          ? EventContextLocation.publicLocation
          : EventContextLocation.home,
      tags: _selectedTags.toList(),
      outcome: outcome,
      incident: incident.id,
      ageBand: _ageBand ?? 'unknown',
      timerMinutes: output.timerMinutes,
      nearMeal: _selectedTags.contains(EventTags.hunger),
      screenOffRelated:
          _selectedTags.contains(EventTags.screen) ||
          _selectedTags.contains(EventTags.screens),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rollout = ref.watch(releaseRolloutProvider);
    if (!rollout.isLoading && !rollout.helpNowEnabled) {
      final fallback = pausedFallback(
        preferredEnabled: rollout.sleepTonightEnabled,
        preferredLabel: 'Open Sleep Tonight',
        preferredRoute: SpecPolicy.sleepTonightEntryUri(),
      );
      return FeaturePausedView(
        title: 'Help Now',
        fallbackLabel: fallback.label,
        fallbackRoute: fallback.route,
      );
    }

    if (_isNight && !_forceIncidentMode) {
      if (!_nightRouted) {
        _nightRouted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _showNightChoiceModal();
        });
      }
    }

    final output = _output;
    final ageKnown = _ageBand != null;

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
                  title: 'Help Now',
                  subtitle: 'What\'s happening right now?',
                ),
                SettleGap.xs(),
                const BehavioralScopeNotice(),
                SettleGap.lg(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_incident == null)
                          _IncidentGrid(onTap: _onIncidentTapped)
                        else if (!ageKnown)
                          _AgeBandPicker(onSelect: _onAgeBandSelect)
                        else if (output != null)
                          _GuidedBeats(
                            output: output,
                            tags: _tags,
                            outcomes: _outcomes,
                            selectedTags: _selectedTags,
                            outcome: _outcome,
                            onTagToggle: (tag) {
                              setState(() {
                                if (_selectedTags.contains(tag)) {
                                  _selectedTags.remove(tag);
                                } else {
                                  _selectedTags.add(tag);
                                }
                              });
                            },
                            onOutcome: _recordOutcome,
                            onFinish: () => context.canPop()
                                ? context.pop()
                                : context.go('/now'),
                            onPause: () => context.push(
                              SpecPolicy.nowResetUri(
                                source: 'help_now',
                                returnMode: SpecPolicy.nowModeIncident,
                              ),
                            ),
                          ),
                        SettleGap.xxl(),
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

/// Guided Beats — sequential beat stepper replacing static Say/Do/Timer card.
///
/// Beat flow:
///   0: "Say this" → "I said it →"
///   1: "Do this" → "Done →"
///   2: "Wait with them" → "They're calming down" / "It's getting harder"
///   3a: "You handled it" (calming) — optional outcome logging
///   3b: "If things get harder" (escalating) → "Got it →" → back to beat 2
class _GuidedBeats extends StatefulWidget {
  const _GuidedBeats({
    required this.output,
    required this.tags,
    required this.outcomes,
    required this.selectedTags,
    required this.outcome,
    required this.onTagToggle,
    required this.onOutcome,
    required this.onFinish,
    required this.onPause,
  });

  final _HelpNowOutput output;
  final List<String> tags;
  final List<String> outcomes;
  final Set<String> selectedTags;
  final String? outcome;
  final ValueChanged<String> onTagToggle;
  final ValueChanged<String> onOutcome;
  final VoidCallback onFinish;
  final VoidCallback onPause;

  @override
  State<_GuidedBeats> createState() => _GuidedBeatsState();
}

class _GuidedBeatsState extends State<_GuidedBeats>
    with SingleTickerProviderStateMixin {
  int _beat = 0; // 0=say, 1=do, 2=wait, 3=done, 4=escalate
  int _escalateCount = 0;
  late final AnimationController _pulseController;

  static const int _beatSay = 0;
  static const int _beatDo = 1;
  static const int _beatWait = 2;
  static const int _beatDone = 3;
  static const int _beatEscalate = 4;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _pulseController.stop();
      _pulseController.value = 0.0;
    } else if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _advance(int next) {
    HapticFeedback.selectionClick();
    setState(() => _beat = next);
  }

  int get _totalDots => 4; // say, do, wait, done

  int get _activeDot {
    if (_beat == _beatEscalate) return 2; // escalate maps to wait dot
    return _beat.clamp(0, 3);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress dots
        _BeatDots(total: _totalDots, active: _activeDot),
        SettleGap.lg(),
        // Current beat content
        AnimatedSwitcher(
          duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 200),
          child: _buildBeat(),
        ),
        SettleGap.lg(),
        // Escape hatch — always visible
        _SubtleActionLink(label: 'I need a pause', onTap: widget.onPause),
      ],
    );
  }

  Widget _buildBeat() {
    return switch (_beat) {
      _beatSay => _BeatSay(
        key: const ValueKey('beat_say'),
        text: widget.output.say,
        onNext: () => _advance(_beatDo),
      ),
      _beatDo => _BeatDo(
        key: const ValueKey('beat_do'),
        text: widget.output.doStep,
        onNext: () => _advance(_beatWait),
      ),
      _beatWait => _BeatWait(
        key: const ValueKey('beat_wait'),
        pulseController: _pulseController,
        onCalming: () => _advance(_beatDone),
        onHarder: () {
          _escalateCount++;
          _advance(_beatEscalate);
        },
      ),
      _beatDone => _BeatDone(
        key: const ValueKey('beat_done'),
        tags: widget.tags,
        outcomes: widget.outcomes,
        selectedTags: widget.selectedTags,
        outcome: widget.outcome,
        onTagToggle: widget.onTagToggle,
        onOutcome: widget.onOutcome,
        onFinish: widget.onFinish,
      ),
      _beatEscalate => _BeatEscalate(
        key: const ValueKey('beat_escalate'),
        text: widget.output.ifEscalates,
        escalateCount: _escalateCount,
        onGotIt: () => _advance(_beatWait),
        onPause: widget.onPause,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _BeatDots extends StatelessWidget {
  const _BeatDots({required this.total, required this.active});

  final int total;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isCurrent = i == active;
        final isDone = i < active;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: isCurrent ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isCurrent
                  ? SettleColors.ink700
                  : isDone
                  ? SettleColors.ink700.withValues(alpha: 0.40)
                  : SettleColors.stone100,
              borderRadius: BorderRadius.circular(SettleRadii.pill),
            ),
          ),
        );
      }),
    );
  }
}

class _BeatSay extends StatelessWidget {
  const _BeatSay({super.key, required this.text, required this.onNext});

  final String text;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Say this',
          style: SettleTypography.caption.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8).copyWith(
            color: SettleColors.ink400,
          ),
        ),
        SettleGap.sm(),
        GlassCardAccent(
          padding: const EdgeInsets.all(20),
          child: Text(text, style: SettleTypography.heading.copyWith(fontSize: 22)),
        ),
        SettleGap.md(),
        GlassCta(label: 'I said it →', onTap: onNext),
      ],
    );
  }
}

class _BeatDo extends StatelessWidget {
  const _BeatDo({super.key, required this.text, required this.onNext});

  final String text;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Do this',
          style: SettleTypography.caption.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8).copyWith(
            color: SettleColors.ink400,
          ),
        ),
        SettleGap.sm(),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Text(text, style: SettleTypography.heading),
        ),
        SettleGap.md(),
        GlassCta(label: 'Done →', onTap: onNext),
      ],
    );
  }
}

class _BeatWait extends StatelessWidget {
  const _BeatWait({
    super.key,
    required this.pulseController,
    required this.onCalming,
    required this.onHarder,
  });

  final AnimationController pulseController;
  final VoidCallback onCalming;
  final VoidCallback onHarder;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wait with them',
          style: SettleTypography.caption.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8).copyWith(
            color: SettleColors.ink400,
          ),
        ),
        SettleGap.sm(),
        GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              AnimatedBuilder(
                animation: pulseController,
                builder: (context, child) {
                  final scale = 1.0 + (pulseController.value * 0.3);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: SettleColors.ink700.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                },
              ),
              SettleGap.lg(),
              Text(
                'Stay close. Breathe.\nThis will pass.',
                textAlign: TextAlign.center,
                style: SettleTypography.heading.copyWith(
                  color: SettleColors.ink500,
                ),
              ),
            ],
          ),
        ),
        SettleGap.md(),
        GlassCta(label: 'They\'re calming down', onTap: onCalming),
        SettleGap.md(),
        GlassPill(label: 'It\'s getting harder', onTap: onHarder),
      ],
    );
  }
}

class _BeatDone extends StatelessWidget {
  const _BeatDone({
    super.key,
    required this.tags,
    required this.outcomes,
    required this.selectedTags,
    required this.outcome,
    required this.onTagToggle,
    required this.onOutcome,
    required this.onFinish,
  });

  final List<String> tags;
  final List<String> outcomes;
  final Set<String> selectedTags;
  final String? outcome;
  final ValueChanged<String> onTagToggle;
  final ValueChanged<String> onOutcome;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCardAccent(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You handled it.', style: SettleTypography.heading.copyWith(fontSize: 22)),
              SettleGap.xs(),
              Text(
                'Close when you\'re ready.',
                style: SettleTypography.body.copyWith(
                  color: SettleColors.ink500,
                ),
              ),
            ],
          ),
        ),
        SettleGap.md(),
        GlassCta(label: 'Finish', onTap: onFinish),
        SettleGap.lg(),
        // Optional outcome logging
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SettleDisclosure(
            title: 'Log this moment (optional)',
            subtitle: 'Quick tags and outcome.',
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SettleGap.xs(),
                    Text(
                      'What was going on?',
                      style: SettleTypography.caption.copyWith(
                        color: SettleColors.ink500,
                      ),
                    ),
                    SettleGap.sm(),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) {
                        final selected = selectedTags.contains(tag);
                        return _SmallChip(
                          label: tag,
                          selected: selected,
                          onTap: () => onTagToggle(tag),
                        );
                      }).toList(),
                    ),
                    SettleGap.lg(),
                    Text(
                      'How did it end?',
                      style: SettleTypography.caption.copyWith(
                        color: SettleColors.ink500,
                      ),
                    ),
                    SettleGap.sm(),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: outcomes.map((o) {
                        return _SmallChip(
                          label: o,
                          selected: outcome == o,
                          onTap: () => onOutcome(o),
                        );
                      }).toList(),
                    ),
                    if (outcome != null) ...[
                      SettleGap.md(),
                      Text(
                        'Noted. You can close anytime.',
                        style: SettleTypography.caption.copyWith(
                          color: SettleColors.sage600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    SettleGap.md(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BeatEscalate extends StatelessWidget {
  const _BeatEscalate({
    super.key,
    required this.text,
    required this.escalateCount,
    required this.onGotIt,
    required this.onPause,
  });

  final String text;
  final int escalateCount;
  final VoidCallback onGotIt;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'If things get harder',
          style: SettleTypography.caption.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.8).copyWith(
            color: SettleColors.ink400,
          ),
        ),
        SettleGap.sm(),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Text(text, style: SettleTypography.heading),
        ),
        SettleGap.md(),
        GlassCta(label: 'Got it →', onTap: onGotIt),
        if (escalateCount >= 2) ...[
          SettleGap.md(),
          GlassPill(label: 'Take a breath instead', onTap: onPause),
        ],
      ],
    );
  }
}

class _IncidentOption {
  const _IncidentOption({
    required this.id,
    required this.label,
    required this.icon,
    required this.eventType,
    this.sleepRelated = false,
  });

  final String id;
  final String label;
  final IconData icon;
  final String eventType;
  final bool sleepRelated;
}

class _IncidentGrid extends StatelessWidget {
  const _IncidentGrid({required this.onTap});

  final ValueChanged<_IncidentOption> onTap;

  static const primaryOptions = [
    _IncidentOption(
      id: 'screaming_crying',
      label: 'Crying / loud upset',
      icon: Icons.campaign_outlined,
      eventType: EventTypes.hnUsedTantrum,
    ),
    _IncidentOption(
      id: 'hitting_throwing',
      label: 'Hitting / biting',
      icon: Icons.sports_mma_outlined,
      eventType: EventTypes.hnUsedAggression,
    ),
    _IncidentOption(
      id: 'public_meltdown',
      label: 'Public tantrum',
      icon: Icons.storefront_outlined,
      eventType: EventTypes.hnUsedPublic,
    ),
  ];

  static const moreOptions = [
    _IncidentOption(
      id: 'unsafe_bolting',
      label: 'Running off / unsafe',
      icon: Icons.warning_amber_rounded,
      eventType: EventTypes.hnUsedUnsafe,
    ),
    _IncidentOption(
      id: 'refusal_wont',
      label: 'Refusing to move',
      icon: Icons.block,
      eventType: EventTypes.hnUsedRefusal,
    ),
    _IncidentOption(
      id: 'parent_overwhelmed',
      label: 'I feel overwhelmed',
      icon: Icons.self_improvement_outlined,
      eventType: EventTypes.hnUsedParentOverwhelm,
    ),
    _IncidentOption(
      id: 'transition_meltdown',
      label: 'Transition overwhelm',
      icon: Icons.compare_arrows_rounded,
      eventType: EventTypes.hnUsedTantrum,
    ),
    _IncidentOption(
      id: 'bedtime_protest',
      label: 'Bedtime protest',
      icon: Icons.nightlight_round,
      eventType: EventTypes.hnUsedRefusal,
      sleepRelated: true,
    ),
  ];

  static const allOptions = [...primaryOptions, ...moreOptions];

  static _IncidentOption? optionById(String id) {
    for (final option in allOptions) {
      if (option.id == id) return option;
    }
    return null;
  }

  Widget _buildGrid(
    List<_IncidentOption> options, {
    double childAspectRatio = 1.2,
  }) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: options.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: childAspectRatio,
      ),
      itemBuilder: (context, index) {
        final option = options[index];
        return GestureDetector(
          onTap: () => onTap(option),
          child: GlassCard(
            border: false,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(option.icon, size: 24, color: SettleColors.ink500),
                SettleGap.sm(),
                Text(
                  option.label,
                  textAlign: TextAlign.center,
                  style: SettleTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildGrid(primaryOptions),
        SettleGap.md(),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SettleDisclosure(
            title: 'More situations',
            subtitle: 'Transitions, bedtime, refusal, and parent reset.',
            children: [
              SettleGap.sm(),
              _buildGrid(moreOptions, childAspectRatio: 1.28),
              SettleGap.xs(),
            ],
          ),
        ),
      ],
    );
  }
}

class _AgeBandPicker extends StatelessWidget {
  const _AgeBandPicker({required this.onSelect});

  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Child age', style: SettleTypography.heading),
        SettleGap.xs(),
        Text(
          'Choose your child\'s age to tailor wording.',
          style: SettleTypography.caption.copyWith(
            color: SettleColors.ink500,
          ),
        ),
        SettleGap.md(),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _HelpNowScreenState._ageBands.map((ageBand) {
            return _SmallChip(
              label: ageBand,
              selected: false,
              onTap: () => onSelect(ageBand),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _HelpNowOutput {
  const _HelpNowOutput({
    required this.say,
    required this.doStep,
    required this.timerMinutes,
    required this.ifEscalates,
  });

  final String say;
  final String doStep;
  final int timerMinutes;
  final String ifEscalates;
}

_HelpNowOutput _buildOutput(String incidentId, String ageBand) {
  switch (incidentId) {
    case 'hitting_throwing':
      return const _HelpNowOutput(
        say: 'I am here. I will help keep everyone safe.',
        doStep: 'Move breakable items aside and give arm\'s-length space.',
        timerMinutes: 3,
        ifEscalates:
            'Give more space, use fewer words, and repeat one calm line.',
      );
    case 'unsafe_bolting':
      return const _HelpNowOutput(
        say: 'Stop. I will help keep your body safe.',
        doStep: 'Block exits and guide to a safer spot.',
        timerMinutes: 2,
        ifEscalates:
            'Keep your body between danger and child, then call a support person if needed.',
      );
    case 'refusal_wont':
      return const _HelpNowOutput(
        say: 'You can feel upset. The boundary stays the same.',
        doStep: 'Offer one small choice within the limit.',
        timerMinutes: 4,
        ifEscalates: 'Repeat the limit once, then stay nearby and quiet.',
      );
    case 'public_meltdown':
      return const _HelpNowOutput(
        say: 'You are safe. We can take a reset break.',
        doStep: 'Move to a quieter nearby spot.',
        timerMinutes: 3,
        ifEscalates: 'Leave this task for now and focus on calming first.',
      );
    case 'parent_overwhelmed':
      return const _HelpNowOutput(
        say: 'I need thirty seconds to steady myself.',
        doStep:
            'Place child in a safe spot, take ten slow breaths, then return.',
        timerMinutes: 2,
        ifEscalates: 'Pause the plan and lower expectations for this moment.',
      );
    case 'transition_meltdown':
      return const _HelpNowOutput(
        say: 'Transition time. I will help your body shift.',
        doStep: 'Give one short cue, then guide the first step.',
        timerMinutes: 3,
        ifEscalates: 'Return briefly to calm, then retry one small step.',
      );
    case 'screaming_crying':
    default:
      final timer = ageBand == '1-2' ? 2 : 3;
      return _HelpNowOutput(
        say: 'I hear you. I am here.',
        doStep: 'Get low, soften your voice, and hold one clear boundary.',
        timerMinutes: timer,
        ifEscalates: 'Use fewer words, stay close, and focus on safety.',
      );
  }
}

class _SubtleActionLink extends StatelessWidget {
  const _SubtleActionLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        label,
        style: SettleTypography.caption.copyWith(
          color: SettleColors.ink400,
          decoration: TextDecoration.underline,
          decorationColor: SettleColors.ink400,
        ),
      ),
    );
  }
}

class _SmallChip extends StatelessWidget {
  const _SmallChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        fill: selected ? SettleSurfaces.cardLight : SettleColors.stone100,
        borderRadius: SettleRadii.pill,
        border: true,
        child: Text(
          label,
          style: SettleTypography.caption.copyWith(
            color: selected
                ? SettleColors.ink700
                : SettleColors.ink500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
