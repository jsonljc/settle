import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/approach.dart';
import '../providers/plan_progress_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/release_rollout_provider.dart';
import '../services/event_bus_service.dart';
import '../services/plan_progress_guidance_service.dart';
import '../services/sleep_guidance_service.dart';
import '../services/spec_policy.dart';
import '../theme/glass_components.dart';
import '../theme/settle_design_system.dart';
import '../widgets/gradient_background.dart';
import '../theme/settle_tokens.dart';
import '../widgets/release_surfaces.dart';
import '../widgets/calm_loading.dart';
import '../widgets/screen_header.dart';
import '../widgets/settle_disclosure.dart';
import '../widgets/settle_chip.dart';
import '../widgets/settle_gap.dart';

class PlanProgressScreen extends ConsumerStatefulWidget {
  const PlanProgressScreen({super.key});

  @override
  ConsumerState<PlanProgressScreen> createState() => _PlanProgressScreenState();
}

class _PlanProgressScreenState extends ConsumerState<PlanProgressScreen> {
  String? _loadedChildId;
  bool _loadScheduled = false;
  String? _detectedBottleneck;
  String? _detectedEvidence;
  String? _recommendedExperiment;
  SleepDayRuntimePlan? _dayRuntime;
  String? _dayRuntimeError;

  final _controllers = {
    'wake': TextEditingController(),
    'nap': TextEditingController(),
    'meals': TextEditingController(),
    'milk': TextEditingController(),
    'bedtime_routine': TextEditingController(),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadIfNeeded() async {
    final profile = ref.read(profileProvider);
    if (profile == null) return;
    final childId = profile.createdAt;

    if (_loadedChildId == childId) return;
    _loadedChildId = childId;

    await ref.read(planProgressProvider.notifier).load(childId: childId);

    await _detectBottleneck(childId);
    await _loadDayRuntime(profile.ageBracket);

    final state = ref.read(planProgressProvider);
    for (final entry in state.rhythm.entries) {
      final controller = _controllers[entry.key];
      if (controller != null && controller.text.isEmpty) {
        controller.text = entry.value;
      }
    }
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

  int _parseClockMinutes(String value, int fallback) {
    final v = value.trim();
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(v);
    if (m == null) return fallback;
    final h = int.tryParse(m.group(1) ?? '');
    final min = int.tryParse(m.group(2) ?? '');
    if (h == null || min == null || h < 0 || h > 23 || min < 0 || min > 59) {
      return fallback;
    }
    return (h * 60) + min;
  }

  String _formatClock(int minutes) {
    final normalized = ((minutes % 1440) + 1440) % 1440;
    final h = normalized ~/ 60;
    final m = normalized % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  Future<void> _loadDayRuntime(AgeBracket age) async {
    try {
      final rhythm = ref.read(planProgressProvider).rhythm;
      final wakeAnchor = _parseClockMinutes(rhythm['wake'] ?? '', 7 * 60);
      final bedtimeTarget = _parseClockMinutes(
        rhythm['bedtime_routine'] ?? '',
        19 * 60,
      );
      final runtime = await SleepGuidanceService.instance
          .buildDayPlannerRuntime(
            ageMonths: _ageMonthsFor(age),
            wakeAnchorMinutes: wakeAnchor,
            bedtimeTargetMinutes: bedtimeTarget,
            minutesUntilBedtime: (bedtimeTarget - wakeAnchor).clamp(0, 720),
          );
      if (!mounted) return;
      setState(() {
        _dayRuntime = runtime;
        _dayRuntimeError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _dayRuntime = null;
        _dayRuntimeError = e.toString();
      });
    }
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
              T.space.md,
              SettleSpacing.screenPadding,
              SettleSpacing.screenPadding,
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
                            child: Text('Evidence Details', style: T.type.h3),
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
                      SettleGap.sm(),
                      Text(
                        'Day planner suggestions are linked to evidence records.',
                        style: T.type.caption.copyWith(
                          color: T.pal.textSecondary,
                        ),
                      ),
                      SettleGap.md(),
                      if (items.isEmpty)
                        Text(
                          'No evidence records were found.',
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
                                  SettleGap.xs(),
                                  Text(
                                    item.claim,
                                    style: T.type.caption.copyWith(
                                      color: T.pal.textSecondary,
                                    ),
                                  ),
                                  SettleGap.sm(),
                                  Text(
                                    '${item.sources.length} source(s)',
                                    style: T.type.caption.copyWith(
                                      color: T.pal.textTertiary,
                                    ),
                                  ),
                                  SettleGap.xs(),
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

  Future<void> _detectBottleneck(String childId) async {
    final current = ref.read(planProgressProvider);
    if (!current.insightEligible) {
      if (!mounted) return;
      setState(() {
        _detectedBottleneck = null;
        _detectedEvidence = null;
        _recommendedExperiment = null;
      });
      return;
    }

    final recent = await EventBusService.eventsInLastDaysForChild(
      days: SpecPolicy.insightWindowDays,
      childId: childId,
    );
    final recommendation = await PlanProgressGuidanceService.instance
        .recommendFromEvents(recent);
    if (!mounted) return;

    if (recommendation == null) {
      setState(() {
        _detectedBottleneck = null;
        _detectedEvidence = null;
        _recommendedExperiment = null;
      });
      return;
    }

    setState(() {
      _detectedBottleneck = recommendation.bottleneck;
      _detectedEvidence = recommendation.evidence;
      _recommendedExperiment = recommendation.experiment;
    });
  }

  @override
  Widget build(BuildContext context) {
    _scheduleLoadIfNeeded();

    final rollout = ref.watch(releaseRolloutProvider);
    if (!rollout.isLoading && !rollout.planProgressEnabled) {
      return const FeaturePausedView(title: 'Progress');
    }

    final profile = ref.watch(profileProvider);
    final state = ref.watch(planProgressProvider);

    if (profile == null) {
      return const ProfileRequiredView(title: 'Progress');
    }

    final childId = profile.createdAt;
    final options = const [
      'Night wakes after bedtime',
      'Hard moments in public',
      'Stuck on no',
      'Hard transitions',
      'Parent capacity feels low',
    ];

    final bottleneck = state.bottleneck ?? _detectedBottleneck;
    final evidence = state.evidence ?? _detectedEvidence;
    final experiment = state.experiment ?? _recommendedExperiment;

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Progress',
                  subtitle: 'See how this week is going.',
                ),
                SettleGap.xs(),
                const BehavioralScopeNotice(),
                SettleGap.md(),
                Expanded(
                  child: state.isLoading
                      ? const CalmLoading(message: 'Loading your progress…')
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'This week\'s focus',
                                      style: T.type.h3,
                                    ),
                                    SettleGap.md(),
                                    if (!state.insightEligible &&
                                        bottleneck == null)
                                      Text(
                                        'Need a little more data. Choose one friction point this week.',
                                        style: T.type.body.copyWith(
                                          color: T.pal.textSecondary,
                                        ),
                                      )
                                    else if (bottleneck != null)
                                      Text(bottleneck, style: T.type.label)
                                    else
                                      Text(
                                        'Choose the biggest friction point for this week.',
                                        style: T.type.caption.copyWith(
                                          color: T.pal.textSecondary,
                                        ),
                                      ),
                                    SettleGap.md(),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: options.map((option) {
                                        final selected = option == bottleneck;
                                        return SettleChip(
                                          variant: SettleChipVariant.tag,
                                          label: option,
                                          selected: selected,
                                          onTap: () => ref
                                              .read(
                                                planProgressProvider.notifier,
                                              )
                                              .setBottleneck(
                                                childId: childId,
                                                bottleneck: option,
                                                evidence:
                                                    evidence ??
                                                    'Selected this week by caregiver.',
                                              ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              ),
                              SettleGap.md(),
                              GlassCardAccent(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'One experiment',
                                      style: T.type.h3.copyWith(
                                        color: T.pal.accent,
                                      ),
                                    ),
                                    SettleGap.sm(),
                                    if (!state.insightEligible)
                                      Text(
                                        'Keep logging for a few days. We\'ll suggest one experiment.',
                                        style: T.type.caption.copyWith(
                                          color: T.pal.textSecondary,
                                        ),
                                      )
                                    else ...[
                                      Text(
                                        experiment ??
                                            'We\'re still learning your pattern. Pick one focus for this week.',
                                        style: T.type.body.copyWith(
                                          color: T.pal.textSecondary,
                                        ),
                                      ),
                                      if (experiment != null) ...[
                                        SettleGap.md(),
                                        GlassCta(
                                          label: state.experiment == experiment
                                              ? 'Mark experiment done'
                                              : 'Set this experiment',
                                          onTap: () {
                                            if (state.experiment ==
                                                experiment) {
                                              ref
                                                  .read(
                                                    planProgressProvider
                                                        .notifier,
                                                  )
                                                  .completeExperiment(
                                                    childId: childId,
                                                    experiment: experiment,
                                                  );
                                              return;
                                            }
                                            ref
                                                .read(
                                                  planProgressProvider.notifier,
                                                )
                                                .setExperiment(
                                                  childId: childId,
                                                  experiment: experiment,
                                                );
                                          },
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                              // ── Secondary links (visible, not behind disclosure) ──
                              SettleGap.md(),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  _SecondaryLink(
                                    label: 'This week',
                                    onTap: () => context.push('/progress/logs'),
                                  ),
                                  _SecondaryLink(
                                    label: 'Learn why',
                                    onTap: () =>
                                        context.push('/progress/learn'),
                                  ),
                                  _SecondaryLink(
                                    label: 'Shared Scripts',
                                    onTap: () => context.push('/rules'),
                                  ),
                                ],
                              ),
                              // ── More details (disclosure) ──
                              SettleGap.md(),
                              GlassCard(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: SettleDisclosure(
                                  title: 'More details',
                                  subtitle: 'Evidence and day rhythm tuning.',
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          SettleGap.xs(),
                                          Text(
                                            'Tiny evidence',
                                            style: T.type.overline.copyWith(
                                              color: T.pal.textTertiary,
                                            ),
                                          ),
                                          SettleGap.sm(),
                                          Text(
                                            state.insightEligible
                                                ? (evidence ??
                                                      'Pattern still emerging.')
                                                : 'Need a little more data.',
                                            style: T.type.body.copyWith(
                                              color: T.pal.textSecondary,
                                            ),
                                          ),
                                          SettleGap.md(),
                                          Text(
                                            'Daily rhythm details',
                                            style: T.type.overline.copyWith(
                                              color: T.pal.textTertiary,
                                            ),
                                          ),
                                          SettleGap.sm(),
                                          Text(
                                            'Use this only when tuning your plan feels useful.',
                                            style: T.type.caption.copyWith(
                                              color: T.pal.textSecondary,
                                            ),
                                          ),
                                          SettleGap.md(),
                                          ..._controllers.entries.map((entry) {
                                            final key = entry.key;
                                            final controller = entry.value;
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                bottom: 8,
                                              ),
                                              child: TextField(
                                                controller: controller,
                                                onSubmitted: (v) async {
                                                  await ref
                                                      .read(
                                                        planProgressProvider
                                                            .notifier,
                                                      )
                                                      .updateRhythmBlock(
                                                        childId: childId,
                                                        block: key,
                                                        value: v,
                                                      );
                                                  await _loadDayRuntime(
                                                    profile.ageBracket,
                                                  );
                                                },
                                                style: T.type.caption,
                                                decoration: InputDecoration(
                                                  labelText: key.replaceAll(
                                                    '_',
                                                    ' ',
                                                  ),
                                                  labelStyle: T.type.caption
                                                      .copyWith(
                                                        color:
                                                            T.pal.textTertiary,
                                                      ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          T.radius.md,
                                                        ),
                                                  ),
                                                  focusedBorder:
                                                      OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              T.radius.md,
                                                            ),
                                                        borderSide: BorderSide(
                                                          color: T.pal.accent,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            );
                                          }),
                                          SettleGap.md(),
                                          Text(
                                            'Day planner runtime',
                                            style: T.type.label,
                                          ),
                                          SettleGap.sm(),
                                          if (_dayRuntimeError != null)
                                            Text(
                                              'Could not load day rhythm details right now.',
                                              style: T.type.caption.copyWith(
                                                color: T.pal.textSecondary,
                                              ),
                                            )
                                          else if (_dayRuntime == null)
                                            Text(
                                              'No day rhythm output yet.',
                                              style: T.type.caption.copyWith(
                                                color: T.pal.textSecondary,
                                              ),
                                            )
                                          else ...[
                                            Text(
                                              'Template: ${_dayRuntime!.templateId}',
                                              style: T.type.caption,
                                            ),
                                            SettleGap.xs(),
                                            Text(
                                              'Bedtime window: ${_formatClock(_dayRuntime!.bedtimeWindowEarliest)}–${_formatClock(_dayRuntime!.bedtimeWindowLatest)}',
                                              style: T.type.caption.copyWith(
                                                color: T.pal.textSecondary,
                                              ),
                                            ),
                                            SettleGap.sm(),
                                            ..._dayRuntime!.napWindows
                                                .take(3)
                                                .map(
                                                  (nap) => Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          bottom: 4,
                                                        ),
                                                    child: Text(
                                                      '${nap.slotId}: ${_formatClock(nap.startWindowMinutes)}–${_formatClock(nap.endWindowMinutes)} (${nap.targetDurationMinutes}m)',
                                                      style: T.type.caption
                                                          .copyWith(
                                                            color: T
                                                                .pal
                                                                .textSecondary,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                            SettleGap.sm(),
                                            Text(
                                              'Rules: ${_dayRuntime!.appliedRuleIds.length} • Constraints: ${_dayRuntime!.appliedConstraintIds.length}',
                                              style: T.type.caption.copyWith(
                                                color: T.pal.textTertiary,
                                              ),
                                            ),
                                            if (_dayRuntime!
                                                .evidenceRefs
                                                .isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 6,
                                                ),
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: GestureDetector(
                                                    onTap: () =>
                                                        _showEvidenceSheet(
                                                          _dayRuntime!
                                                              .evidenceRefs,
                                                        ),
                                                    child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons
                                                              .menu_book_outlined,
                                                          size: 14,
                                                          color: T
                                                              .pal
                                                              .textTertiary,
                                                        ),
                                                        const SizedBox(
                                                          width: 4,
                                                        ),
                                                        Text(
                                                          'Why this? (${_dayRuntime!.evidenceRefs.length})',
                                                          style: T.type.caption
                                                              .copyWith(
                                                                color: T
                                                                    .pal
                                                                    .textTertiary,
                                                              ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                          ],
                                          SettleGap.sm(),
                                        ],
                                      ),
                                    ),
                                  ],
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

class _SecondaryLink extends StatelessWidget {
  const _SecondaryLink({required this.label, required this.onTap});

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
