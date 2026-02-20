import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/approach.dart';
import '../models/baby_profile.dart';
import '../providers/family_rules_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/release_rollout_provider.dart';
import '../providers/rhythm_provider.dart';
import '../providers/sleep_tonight_provider.dart';
import '../services/spec_policy.dart';
import '../widgets/settle_disclosure.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_pill.dart';
import '../widgets/settle_cta.dart';
import '../widgets/today_rhythm_card.dart';
import '../theme/settle_design_system.dart';
import '../widgets/gradient_background.dart';
import '../widgets/release_surfaces.dart';
import '../widgets/settle_gap.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({
    super.key,
    this.now = DateTime.now,
    this.profileOverride,
    this.sleepStateOverride,
    this.rulesStateOverride,
  });

  final DateTime Function() now;
  final BabyProfile? profileOverride;
  final SleepTonightState? sleepStateOverride;
  final FamilyRulesState? rulesStateOverride;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _loadedChildId;
  bool _syncScheduled = false;
  bool _rhythmLoadScheduled = false;

  bool get _isNight {
    return SpecPolicy.isNight(widget.now());
  }

  static int _ageMonthsFor(AgeBracket age) {
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
      AgeBracket.fiveToSixYears => 66,
    };
  }

  void _syncRhythmIfNeeded() {
    if (widget.profileOverride != null) return;
    if (_rhythmLoadScheduled) return;
    final profile = ref.read(profileProvider);
    if (profile == null) return;
    _rhythmLoadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rhythmLoadScheduled = false;
      if (!mounted) return;
      ref.read(rhythmProvider.notifier).load(
        childId: profile.createdAt,
        ageMonths: _ageMonthsFor(profile.ageBracket),
      );
    });
  }

  void _syncTonightPlan() {
    if (widget.profileOverride != null || widget.sleepStateOverride != null) {
      return;
    }

    final profile = ref.read(profileProvider);
    if (profile == null) return;
    if (_loadedChildId == profile.createdAt) return;
    if (_syncScheduled) return;
    _loadedChildId = profile.createdAt;
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (!mounted) return;
      ref
          .read(sleepTonightProvider.notifier)
          .loadTonightPlan(profile.createdAt);
    });
  }

  @override
  Widget build(BuildContext context) {
    _syncTonightPlan();
    _syncRhythmIfNeeded();

    final profile = widget.profileOverride ?? ref.watch(profileProvider);
    final SleepTonightState sleepState =
        widget.sleepStateOverride ?? ref.watch(sleepTonightProvider);
    final FamilyRulesState rulesState =
        widget.rulesStateOverride ?? ref.watch(familyRulesProvider);
    final rollout = ref.watch(releaseRolloutProvider);
    final rolloutReady = !rollout.isLoading;

    if (profile == null) {
      return const ProfileRequiredView(title: 'Home');
    }

    final helpNowEnabled = !rolloutReady || rollout.helpNowEnabled;
    final sleepEnabled = !rolloutReady || rollout.sleepTonightEnabled;
    final planEnabled = !rolloutReady || rollout.planProgressEnabled;
    final rulesEnabled = !rolloutReady || rollout.familyRulesEnabled;
    final rhythmState = ref.watch(rhythmProvider);
    final ageMonths = profile.ageMonths ?? _ageMonthsFor(profile.ageBracket);

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
                SettleGap.lg(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Home',
                      style: SettleTypography.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: SettleColors.nightMuted,
                      ),
                    ),
                    SettleGap.sm(),
                    Text(profile.name, style: SettleTypography.display.copyWith(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.5, height: 1.2)),
                  ],
                ),
                SettleGap.md(),
                Text(
                  _isNight
                      ? 'It\'s nighttime. You\'re here — that\'s the first step.'
                      : 'You\'re here. That\'s the first step.',
                  style: SettleTypography.caption.copyWith(
                    color: SettleColors.nightSoft,
                  ),
                ),
                if (rolloutReady && sleepEnabled) ...[
                  SettleGap.md(),
                  TodayRhythmCard(
                    schedule: rhythmState.todaySchedule,
                    ageMonths: ageMonths,
                    onSleepTonightTap: () => context.push(
                      SpecPolicy.sleepTonightEntryUri(
                        source: 'home_rhythm_card',
                      ),
                    ),
                  ),
                ],
                if (rolloutReady &&
                    (!rollout.helpNowEnabled ||
                        !rollout.sleepTonightEnabled ||
                        !rollout.planProgressEnabled ||
                        !rollout.familyRulesEnabled)) ...[
                  SettleGap.sm(),
                  Text(
                    'Some sections are taking a short break.',
                    style: SettleTypography.caption.copyWith(
                      color: SettleColors.nightMuted,
                    ),
                  ),
                ],
                SettleGap.lg(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassCardAccent(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start here',
                                style: SettleTypography.caption.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.8,
                                  color: SettleColors.nightMuted,
                                ),
                              ),
                              SettleGap.sm(),
                              Text(
                                'Help with what\'s happening',
                                style: SettleTypography.heading,
                              ),
                              SettleGap.sm(),
                              Text(
                                'We\'ll give you one thing to say and do.',
                                style: SettleTypography.caption.copyWith(
                                  color: SettleColors.nightSoft,
                                ),
                              ),
                              SettleGap.md(),
                              GlassCta(
                                label: 'Help with what\'s happening',
                                enabled: helpNowEnabled,
                                onTap: () => context.push(
                                  SpecPolicy.nowIncidentUri(
                                    source: 'home_primary',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SettleGap.md(),
                        GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: SettleDisclosure(
                            title: 'More actions',
                            subtitle:
                                'Continue plan, reset, rules, or settings.',
                            children: [
                              SettleGap.sm(),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  GlassPill(
                                    label: 'Continue tonight\'s plan',
                                    enabled: sleepEnabled,
                                    onTap: () => context.push(
                                      SpecPolicy.sleepTonightEntryUri(
                                        source: 'home_secondary',
                                      ),
                                    ),
                                  ),
                                  GlassPill(
                                    label: 'Take a breath',
                                    onTap: () => context.push(
                                      SpecPolicy.nowResetUri(
                                        source: 'home_secondary',
                                        returnMode: SpecPolicy.nowModeIncident,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (!sleepState.hasActivePlan &&
                                  sleepEnabled) ...[
                                SettleGap.sm(),
                                Text(
                                  'No plan yet. This opens Sleep Tonight.',
                                  style: SettleTypography.caption.copyWith(
                                    color: SettleColors.nightMuted,
                                  ),
                                ),
                              ],
                              SettleGap.md(),
                              _MoreActionTile(
                                label: 'Plan',
                                subtitle: 'Pick one focus for this week',
                                enabled: planEnabled,
                                onTap: () => context.push('/plan'),
                              ),
                              SettleGap.sm(),
                              _MoreActionTile(
                                label: 'Rules',
                                subtitle: rulesState.unreadCount > 0
                                    ? '${rulesState.unreadCount} changes to review'
                                    : 'Shared scripts for caregivers',
                                badge: rulesState.unreadCount,
                                enabled: rulesEnabled,
                                onTap: () => context.push('/rules'),
                              ),
                              SettleGap.sm(),
                              _MoreActionTile(
                                label: 'Settings',
                                subtitle: 'Profile and app preferences',
                                onTap: () => context.push('/settings'),
                              ),
                              SettleGap.sm(),
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

class _MoreActionTile extends StatelessWidget {
  const _MoreActionTile({
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.badge = 0,
  });

  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.58,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          fill: SettleSurfaces.cardDark,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: SettleTypography.body.copyWith(fontWeight: FontWeight.w600)),
                    SettleGap.xs(),
                    Text(
                      subtitle,
                      style: SettleTypography.caption.copyWith(
                        color: SettleColors.nightSoft,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge > 0)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: SettleColors.dusk600.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(SettleRadii.pill),
                  ),
                  child: Text(
                    '$badge',
                    style: SettleTypography.caption.copyWith(
                      color: SettleColors.nightAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: SettleColors.nightMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
