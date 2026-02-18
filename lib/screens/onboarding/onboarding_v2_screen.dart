import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/approach.dart';
import '../../models/baby_profile.dart';
import '../../models/tantrum_profile.dart';
import '../../providers/profile_provider.dart';
import '../../providers/user_cards_provider.dart';
import '../../services/card_content_service.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/gradient_background.dart';
import 'steps/step_challenge_v2.dart';
import 'steps/step_child_name_age.dart';
import 'steps/step_instant_value.dart';
import 'steps/step_parent_type.dart';
import 'steps/step_partner_invite.dart';
import 'steps/step_pricing.dart';
import 'steps/step_regulation_check.dart';

class _Obv2T {
  _Obv2T._();

  static const pal = _Obv2PaletteTokens();
  static const anim = _Obv2AnimTokens();
}

class _Obv2PaletteTokens {
  const _Obv2PaletteTokens();

  Color get accent => SettleColors.nightAccent;
  Color get textSecondary => SettleColors.nightSoft;
  Color get textTertiary => SettleColors.nightMuted;
}

class _Obv2AnimTokens {
  const _Obv2AnimTokens();

  Duration get fast => const Duration(milliseconds: 150);
  Duration get normal => const Duration(milliseconds: 250);
}

enum _V2OnboardingStep {
  childNameAge,
  parentType,
  challenge,
  instantValue,
  regulation,
  partnerInvite,
  pricing,
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
  int _ageMonths = 24;
  FamilyStructure? _familyStructure;
  String? _challengeTrigger;
  CardContent? _instantCard;
  String? _instantCardTrigger;
  bool _instantCardLoading = false;
  bool _instantCardSaved = false;
  RegulationLevel? _regulationLevel;
  bool _savingProfile = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<_V2OnboardingStep> get _steps {
    final steps = <_V2OnboardingStep>[
      _V2OnboardingStep.childNameAge,
      _V2OnboardingStep.parentType,
      _V2OnboardingStep.challenge,
      _V2OnboardingStep.instantValue,
      _V2OnboardingStep.regulation,
    ];

    if (_showsPartnerInvite(_familyStructure)) {
      steps.add(_V2OnboardingStep.partnerInvite);
    }

    steps.add(_V2OnboardingStep.pricing);
    return steps;
  }

  bool _showsPartnerInvite(FamilyStructure? familyStructure) {
    return familyStructure == FamilyStructure.twoParents ||
        familyStructure == FamilyStructure.coParent ||
        familyStructure == FamilyStructure.withSupport;
  }

  bool _canProceed(_V2OnboardingStep stepKind) {
    return switch (stepKind) {
      _V2OnboardingStep.childNameAge => _ageMonths >= 12 && _ageMonths <= 60,
      _V2OnboardingStep.parentType => _familyStructure != null,
      _V2OnboardingStep.challenge => _challengeTrigger != null,
      _V2OnboardingStep.instantValue => true,
      _V2OnboardingStep.regulation => _regulationLevel != null,
      _V2OnboardingStep.partnerInvite => true,
      _V2OnboardingStep.pricing => true,
    };
  }

  Future<void> _next() async {
    if (_savingProfile) return;

    final steps = _steps;
    final safeIndex = min(_step, steps.length - 1);
    final stepKind = steps[safeIndex];

    if (!_canProceed(stepKind)) return;

    if (stepKind == _V2OnboardingStep.challenge) {
      await _loadInstantValueCard();
      if (!mounted) return;
    }

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

  Future<void> _loadInstantValueCard() async {
    final trigger = _challengeTrigger;
    if (trigger == null) return;
    if (_instantCardTrigger == trigger && _instantCard != null) return;

    setState(() {
      _instantCardLoading = true;
      _instantCardTrigger = trigger;
      _instantCard = null;
      _instantCardSaved = false;
    });

    final card = await CardContentService.instance.selectBestCard(
      triggerType: trigger,
    );

    if (!mounted) return;
    setState(() {
      _instantCard = card;
      _instantCardLoading = false;
    });
  }

  Future<void> _saveInstantCard() async {
    final card = _instantCard;
    if (card == null || _instantCardSaved) return;

    await ref.read(userCardsProvider.notifier).save(card.id);

    if (!mounted) return;
    setState(() => _instantCardSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved to My Playbook'),
        duration: Duration(milliseconds: 1100),
      ),
    );
  }

  Future<void> _finish() async {
    final family = _familyStructure;
    final regulation = _regulationLevel;
    if (family == null || regulation == null) return;

    if (_savingProfile) return;
    setState(() => _savingProfile = true);

    final name = _nameController.text.trim();
    final profile = BabyProfile(
      name: name.isEmpty ? 'your child' : name,
      ageBracket: _ageBracketFromMonths(_ageMonths),
      familyStructure: family,
      approach: Approach.stayAndSupport,
      primaryChallenge: PrimaryChallenge.fallingAsleep,
      feedingType: FeedingType.solids,
      focusMode: FocusMode.both,
      regulationLevel: regulation,
      ageMonths: _ageMonths,
      sleepProfileComplete: false,
    );

    if (widget.onSaveProfile != null) {
      await widget.onSaveProfile!(profile);
    } else {
      await ref.read(profileProvider.notifier).save(profile);
    }

    if (!mounted) return;
    context.go('/plan');
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
                      duration: _Obv2T.anim.normal,
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
      _V2OnboardingStep.childNameAge => StepChildNameAge(
        key: const ValueKey(_V2OnboardingStep.childNameAge),
        nameController: _nameController,
        ageMonths: _ageMonths,
        onAgeMonthsChanged: (value) => setState(() => _ageMonths = value),
      ),
      _V2OnboardingStep.parentType => StepParentType(
        key: const ValueKey(_V2OnboardingStep.parentType),
        selected: _familyStructure,
        onSelect: (value) => setState(() => _familyStructure = value),
      ),
      _V2OnboardingStep.challenge => StepChallengeV2(
        key: const ValueKey(_V2OnboardingStep.challenge),
        selectedTrigger: _challengeTrigger,
        onSelect: (value) {
          setState(() {
            _challengeTrigger = value;
            _instantCardSaved = false;
          });
        },
      ),
      _V2OnboardingStep.instantValue => StepInstantValue(
        key: const ValueKey(_V2OnboardingStep.instantValue),
        challengeLabel: StepChallengeV2.labelFor(_challengeTrigger),
        loading: _instantCardLoading,
        card: _instantCard,
        saved: _instantCardSaved,
        onSave: _saveInstantCard,
      ),
      _V2OnboardingStep.regulation => StepRegulationCheck(
        key: const ValueKey(_V2OnboardingStep.regulation),
        selected: _regulationLevel,
        onSelect: (value) => setState(() => _regulationLevel = value),
      ),
      _V2OnboardingStep.partnerInvite => StepPartnerInvite(
        key: const ValueKey(_V2OnboardingStep.partnerInvite),
        familyStructure: _familyStructure ?? FamilyStructure.withSupport,
      ),
      _V2OnboardingStep.pricing => const StepPricing(
        key: ValueKey(_V2OnboardingStep.pricing),
      ),
    };
  }

  AgeBracket _ageBracketFromMonths(int months) {
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
                : GestureDetector(
                    onTap: onBack,
                    child: Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 20,
                      color: _Obv2T.pal.textSecondary,
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
                  duration: _Obv2T.anim.fast,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? _Obv2T.pal.accent
                        : done
                        ? _Obv2T.pal.accent.withValues(alpha: 0.38)
                        : _Obv2T.pal.textTertiary.withValues(alpha: 0.3),
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

class _V2BottomCta extends StatelessWidget {
  const _V2BottomCta({
    required this.step,
    required this.totalSteps,
    required this.canProceed,
    required this.busy,
    required this.onNext,
  });

  final int step;
  final int totalSteps;
  final bool canProceed;
  final bool busy;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = step == totalSteps - 1;
    final label = busy
        ? 'Saving...'
        : isLast
        ? 'Finish setup'
        : 'Continue';

    return Padding(
      padding: EdgeInsets.fromLTRB(
        SettleSpacing.screenPadding,
        0,
        SettleSpacing.screenPadding,
        16,
      ),
      child: AnimatedOpacity(
        opacity: canProceed && !busy ? 1 : 0.45,
        duration: _Obv2T.anim.fast,
        child: IgnorePointer(
          ignoring: !canProceed || busy,
          child: GlassCta(
            key: const ValueKey('v2_onboarding_next_cta'),
            label: label,
            onTap: onNext,
          ),
        ),
      ),
    );
  }
}
