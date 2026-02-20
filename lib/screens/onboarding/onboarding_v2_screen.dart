import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/approach.dart';
import '../../models/baby_profile.dart';
import '../../models/tantrum_profile.dart';
import '../../providers/profile_provider.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/settle_cta.dart';
import '../../widgets/settle_tappable.dart';
import 'steps/step_child_basics_o2.dart';
import 'steps/step_value_promise.dart';
import 'steps/step_welcome_o1.dart';
import 'steps/step_why_here.dart';

/// Wireframe V2: exactly 4 steps — O1 Welcome, O2 Child basics, O3 What's hardest, O4 Value promise.
enum _V2OnboardingStep {
  welcome,
  childBasics,
  whyHere,
  valuePromise,
}

class OnboardingV2Screen extends ConsumerStatefulWidget {
  const OnboardingV2Screen({super.key, this.onSaveProfile});

  final Future<void> Function(BabyProfile profile)? onSaveProfile;

  @override
  ConsumerState<OnboardingV2Screen> createState() => _OnboardingV2ScreenState();
}

class _OnboardingV2ScreenState extends ConsumerState<OnboardingV2Screen> {
  final _nameController = TextEditingController();

  int _step = 0;
  String? _ageChipId = '1_2'; // default 1–2
  String? _whyHereChoice;
  bool _savingProfile = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  static const _steps = [
    _V2OnboardingStep.welcome,
    _V2OnboardingStep.childBasics,
    _V2OnboardingStep.whyHere,
    _V2OnboardingStep.valuePromise,
  ];

  bool _canProceed(_V2OnboardingStep stepKind) {
    return switch (stepKind) {
      _V2OnboardingStep.welcome => true,
      _V2OnboardingStep.childBasics => _ageChipId != null,
      _V2OnboardingStep.whyHere => _whyHereChoice != null,
      _V2OnboardingStep.valuePromise => true,
    };
  }

  Future<void> _next() async {
    if (_savingProfile) return;

    final steps = _steps;
    final safeIndex = min(_step, steps.length - 1);
    final stepKind = steps[safeIndex];

    if (!_canProceed(stepKind)) return;

    if (safeIndex < steps.length - 1) {
      setState(() => _step = safeIndex + 1);
      return;
    }

    await _finish();
  }

  void _back() {
    if (_step > 0) {
      setState(() => _step--);
    }
  }

  Future<void> _finish() async {
    if (_savingProfile || _ageChipId == null || _whyHereChoice == null) return;

    setState(() => _savingProfile = true);

    final name = _nameController.text.trim();
    final ageMonths = StepChildBasicsO2.ageMonthsFromChip(_ageChipId);

    final profile = BabyProfile(
      name: name.isEmpty ? 'your child' : name,
      ageBracket: _ageBracketFromMonths(ageMonths),
      familyStructure: FamilyStructure.withSupport,
      approach: Approach.stayAndSupport,
      primaryChallenge: PrimaryChallenge.fallingAsleep,
      feedingType: FeedingType.solids,
      focusMode: FocusMode.both,
      regulationLevel: null,
      ageMonths: ageMonths,
      sleepProfileComplete: false,
    );

    if (widget.onSaveProfile != null) {
      await widget.onSaveProfile!(profile);
    } else {
      await ref.read(profileProvider.notifier).save(profile);
    }

    if (!mounted) return;
    final route = _whyHereChoice == 'sleep' ? '/sleep' : '/plan';
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    final currentStepIndex = _step.clamp(0, steps.length - 1);
    final currentStep = steps[currentStepIndex];

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Column(
            children: [
              _V2TopBar(
                step: currentStepIndex,
                totalSteps: steps.length,
                onBack: currentStepIndex > 0 ? _back : null,
              ),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: SettleSpacing.screenPadding,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 116),
                    child: AnimatedSwitcher(
                      duration: SettleAnimations.normal,
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _buildStep(currentStep),
                    ),
                  ),
                ),
              ),
              _V2BottomCta(
                step: currentStepIndex,
                totalSteps: steps.length,
                currentStepKind: currentStep,
                busy: _savingProfile,
                canProceed: _canProceed(currentStep),
                onNext: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(_V2OnboardingStep stepKind) {
    return switch (stepKind) {
      _V2OnboardingStep.welcome => const StepWelcomeO1(
        key: ValueKey(_V2OnboardingStep.welcome),
      ),
      _V2OnboardingStep.childBasics => StepChildBasicsO2(
        key: const ValueKey(_V2OnboardingStep.childBasics),
        nameController: _nameController,
        ageChipId: _ageChipId,
        onAgeChipChanged: (value) => setState(() => _ageChipId = value),
      ),
      _V2OnboardingStep.whyHere => StepWhyHere(
        key: const ValueKey(_V2OnboardingStep.whyHere),
        selected: _whyHereChoice,
        onSelect: (value) => setState(() => _whyHereChoice = value),
      ),
      _V2OnboardingStep.valuePromise => const StepValuePromise(
        key: ValueKey(_V2OnboardingStep.valuePromise),
      ),
    };
  }

  AgeBracket _ageBracketFromMonths(int months) {
    if (months <= 12) return AgeBracket.nineToTwelveMonths;
    if (months <= 18) return AgeBracket.twelveToEighteenMonths;
    if (months <= 24) return AgeBracket.nineteenToTwentyFourMonths;
    if (months <= 36) return AgeBracket.twoToThreeYears;
    if (months <= 48) return AgeBracket.threeToFourYears;
    return AgeBracket.fourToFiveYears;
  }
}

class _V2TopBar extends StatelessWidget {
  const _V2TopBar({required this.step, required this.totalSteps, this.onBack});

  final int step;
  final int totalSteps;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final accentColor = SettleSemanticColors.accent(context);
    final mutedColor = SettleSemanticColors.muted(context);
    final supportingColor = SettleSemanticColors.supporting(context);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SettleSpacing.screenPadding,
        vertical: 12,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: onBack == null
                ? const SizedBox.shrink()
                : SettleTappable(
                    semanticLabel: 'Back',
                    onTap: onBack,
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 20,
                      color: supportingColor,
                    ),
                  ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalSteps, (index) {
                final active = index == step;
                final done = index < step;
                return AnimatedContainer(
                  duration: SettleAnimations.fast,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? accentColor
                        : done
                        ? accentColor.withValues(alpha: 0.38)
                        : mutedColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                    // No shadow — clean, minimal progress dots.
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

class _V2BottomCta extends StatelessWidget {
  const _V2BottomCta({
    required this.step,
    required this.totalSteps,
    required this.currentStepKind,
    required this.canProceed,
    required this.busy,
    required this.onNext,
  });

  final int step;
  final int totalSteps;
  final _V2OnboardingStep currentStepKind;
  final bool canProceed;
  final bool busy;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isFirst = step == 0;
    final isLast = step == totalSteps - 1;
    final isLetsGo = isLast && currentStepKind == _V2OnboardingStep.valuePromise;
    final label = busy
        ? 'Saving...'
        : isFirst
        ? 'Start'
        : isLetsGo
        ? "Let's go"
        : 'Next';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SettleSpacing.screenPadding,
        0,
        SettleSpacing.screenPadding,
        16,
      ),
      child: AnimatedOpacity(
        opacity: canProceed && !busy ? 1 : 0.45,
        duration: SettleAnimations.fast,
        child: IgnorePointer(
          ignoring: !canProceed || busy,
          child: SettleCta(
            key: const ValueKey('v2_onboarding_next_cta'),
            label: label,
            onTap: onNext,
          ),
        ),
      ),
    );
  }
}
