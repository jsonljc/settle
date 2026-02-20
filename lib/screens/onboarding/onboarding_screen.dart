import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/approach.dart';
import '../../models/baby_profile.dart';
import '../../models/tantrum_profile.dart';
import '../../providers/profile_provider.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/settle_cta.dart';
import '../../widgets/settle_tappable.dart';
import '../../widgets/gradient_background.dart';
import 'focus_selector.dart';
import 'step_age.dart';
import 'step_challenge.dart';
import 'step_family.dart';
import 'step_name.dart';
import 'step_setup.dart';
import 'tantrum_profile_step.dart';

enum _OnboardingStep {
  name,
  age,
  focus,
  family,
  sleepSetup,
  sleepChallenge,
  tantrumProfile,
}

/// Onboarding flow with conditional branching for sleep/tantrum support.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;

  // Step 0 — name
  final _nameController = TextEditingController();

  // Step 1 — age
  AgeBracket? _age;

  // Step 2/3 — focus/family
  FocusMode? _focusMode;
  FamilyStructure? _family;

  // Sleep path
  Approach? _philosophy;
  PrimaryChallenge? _challenge;
  FeedingType? _feeding;
  Approach? _approach;

  // Tantrum path
  TantrumType? _tantrumType;
  Set<TriggerType> _triggers = <TriggerType>{};
  ParentPattern? _parentPattern;
  ResponsePriority? _responsePriority;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  FocusMode? get _resolvedFocusMode {
    final age = _age;
    if (age == null) return null;
    if (age.isSleepOnlyAge) return FocusMode.sleepOnly;
    if (age.isHybridAge) return _focusMode;
    return FocusMode.tantrumOnly;
  }

  List<_OnboardingStep> get _steps {
    final steps = <_OnboardingStep>[_OnboardingStep.name, _OnboardingStep.age];

    if (_age == null) return steps;

    if (_age!.isHybridAge) {
      steps.add(_OnboardingStep.focus);
    }

    final mode = _resolvedFocusMode;
    if (mode == null) return steps;

    steps.add(_OnboardingStep.family);

    final includeSleep = mode != FocusMode.tantrumOnly;
    final includeTantrum = mode != FocusMode.sleepOnly;

    if (includeSleep) {
      steps.add(_OnboardingStep.sleepSetup);
      if (mode == FocusMode.sleepOnly) {
        steps.add(_OnboardingStep.sleepChallenge);
      }
    }

    if (includeTantrum) {
      steps.add(_OnboardingStep.tantrumProfile);
    }

    return steps;
  }

  bool _canProceed(_OnboardingStep stepKind) {
    return switch (stepKind) {
      _OnboardingStep.name => _nameController.text.trim().isNotEmpty,
      _OnboardingStep.age => _age != null,
      _OnboardingStep.focus => _focusMode != null,
      _OnboardingStep.family => _family != null,
      _OnboardingStep.sleepSetup => _philosophy != null,
      _OnboardingStep.sleepChallenge => _challenge != null,
      _OnboardingStep.tantrumProfile => _tantrumType != null,
    };
  }

  void _next() {
    final steps = _steps;
    final safeIndex = min(_step, steps.length - 1);
    final stepKind = steps[safeIndex];

    if (!_canProceed(stepKind)) return;

    if (stepKind == _OnboardingStep.sleepSetup && _approach == null) {
      _approach = _philosophy;
    }

    if (safeIndex < steps.length - 1) {
      setState(() => _step = safeIndex + 1);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  Future<void> _finish() async {
    final age = _age!;
    final mode = _resolvedFocusMode ?? FocusMode.sleepOnly;

    final includeSleep = mode != FocusMode.tantrumOnly;
    final includeTantrum = mode != FocusMode.sleepOnly;

    final tantrumProfile = includeTantrum
        ? TantrumProfile(
            tantrumType: _tantrumType ?? TantrumType.mixed,
            commonTriggers: _triggers.isNotEmpty
                ? _triggers.toList()
                : const [TriggerType.unpredictable],
            parentPattern: _parentPattern ?? ParentPattern.freezes,
            responsePriority: _responsePriority ?? ResponsePriority.scripts,
          )
        : null;

    final profile = BabyProfile(
      name: _nameController.text.trim(),
      ageBracket: age,
      familyStructure: _family ?? FamilyStructure.other,
      approach: includeSleep
          ? (_approach ?? _philosophy ?? Approach.stayAndSupport)
          : Approach.stayAndSupport,
      primaryChallenge: includeSleep
          ? (_challenge ?? PrimaryChallenge.schedule)
          : PrimaryChallenge.schedule,
      feedingType: includeSleep
          ? (_feeding ?? FeedingType.solids)
          : FeedingType.solids,
      tantrumProfile: tantrumProfile,
      focusMode: mode,
    );

    await ref.read(profileProvider.notifier).save(profile);
    if (mounted) context.go('/now');
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final currentStep = _step.clamp(0, steps.length - 1);

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                step: currentStep,
                totalSteps: steps.length,
                onBack: currentStep > 0 ? _back : null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: SettleSpacing.screenPadding,
                  ),
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 120),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _buildStep(steps[currentStep]),
                    ),
                  ),
                ),
              ),
              _BottomCta(
                step: currentStep,
                totalSteps: steps.length,
                canProceed: _canProceed(steps[currentStep]),
                onNext: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(_OnboardingStep stepKind) {
    return switch (stepKind) {
      _OnboardingStep.name => StepName(
        key: const ValueKey(_OnboardingStep.name),
        controller: _nameController,
        onNext: _next,
        onChanged: (_) => setState(() {}),
      ),
      _OnboardingStep.age => StepAge(
        key: const ValueKey(_OnboardingStep.age),
        selected: _age,
        onSelect: (v) => setState(() {
          _age = v;
          if (!v.isHybridAge) {
            _focusMode = null;
          }
        }),
      ),
      _OnboardingStep.focus => FocusSelectorStep(
        key: const ValueKey(_OnboardingStep.focus),
        selected: _focusMode,
        onSelect: (v) => setState(() => _focusMode = v),
      ),
      _OnboardingStep.family => StepFamily(
        key: const ValueKey(_OnboardingStep.family),
        family: _family,
        onFamilySelect: (v) => setState(() => _family = v),
      ),
      _OnboardingStep.sleepSetup => StepSetup(
        key: const ValueKey(_OnboardingStep.sleepSetup),
        family: _family,
        onFamilySelect: (v) => setState(() => _family = v),
        approach: _philosophy,
        onApproachSelect: (v) => setState(() => _philosophy = v),
        showFamily: false,
      ),
      _OnboardingStep.sleepChallenge => StepChallenge(
        key: const ValueKey(_OnboardingStep.sleepChallenge),
        challenge: _challenge,
        onChallengeSelect: (v) => setState(() => _challenge = v),
        feeding: _feeding,
        onFeedingSelect: (v) => setState(() => _feeding = v),
      ),
      _OnboardingStep.tantrumProfile => TantrumProfileStep(
        key: const ValueKey(_OnboardingStep.tantrumProfile),
        tantrumType: _tantrumType,
        onTantrumTypeSelect: (v) => setState(() => _tantrumType = v),
        triggers: _triggers,
        onTriggersChanged: (v) => setState(() => _triggers = v),
        parentPattern: _parentPattern,
        onParentPatternSelect: (v) => setState(() => _parentPattern = v),
      ),
    };
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.totalSteps, this.onBack});

  final int step;
  final int totalSteps;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SettleSpacing.screenPadding,
        vertical: 12,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: onBack != null
                ? SettleTappable(
                    semanticLabel: 'Back',
                    onTap: onBack,
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 20,
                      color: SettleColors.nightSoft,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalSteps, (i) {
                final isActive = i == step;
                final isDone = i < step;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive
                        ? SettleColors.nightAccent
                        : isDone
                        ? SettleColors.nightAccent.withValues(alpha: 0.4)
                        : SettleColors.nightMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _BottomCta extends StatelessWidget {
  const _BottomCta({
    required this.step,
    required this.totalSteps,
    required this.canProceed,
    required this.onNext,
  });

  final int step;
  final int totalSteps;
  final bool canProceed;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = step == totalSteps - 1;
    final label = isLast ? 'Get started' : 'Continue';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SettleSpacing.screenPadding,
        0,
        SettleSpacing.screenPadding,
        16,
      ),
      child: AnimatedOpacity(
        opacity: canProceed ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 150),
        child: SettleCta(label: label, onTap: onNext, enabled: canProceed),
      ),
    );
  }
}
