import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/baby_profile.dart';
import '../providers/family_rules_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/release_rollout_provider.dart';
import '../providers/sleep_tonight_provider.dart';
import '../services/spec_policy.dart';
import '../widgets/settle_disclosure.dart';
import '../theme/glass_components.dart';
import '../theme/settle_tokens.dart';
import '../widgets/release_surfaces.dart';

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

  bool get _isNight {
    return SpecPolicy.isNight(widget.now());
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

    final helpNowEnabled =
        !rolloutReady || rollout.helpNowEnabled;
    final sleepEnabled = !rolloutReady || rollout.sleepTonightEnabled;
    final planEnabled = !rolloutReady || rollout.planProgressEnabled;
    final rulesEnabled = !rolloutReady || rollout.familyRulesEnabled;

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Home',
                      style: T.type.overline.copyWith(
                        color: T.pal.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(profile.name, style: T.type.h1),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  _isNight
                      ? 'It\'s nighttime. You\'re here — that\'s the first step.'
                      : 'You\'re here. That\'s the first step.',
                  style: T.type.caption.copyWith(color: T.pal.textSecondary),
                ),
                if (rolloutReady &&
                    (!rollout.helpNowEnabled ||
                        !rollout.sleepTonightEnabled ||
                        !rollout.planProgressEnabled ||
                        !rollout.familyRulesEnabled)) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Some sections are taking a short break.',
                    style: T.type.caption.copyWith(color: T.pal.textTertiary),
                  ),
                ],
                const SizedBox(height: 16),
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
                                style: T.type.overline.copyWith(
                                  color: T.pal.textTertiary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('Help with what\'s happening',
                                  style: T.type.h3),
                              const SizedBox(height: 8),
                              Text(
                                'We\'ll give you one thing to say and do.',
                                style: T.type.caption.copyWith(
                                  color: T.pal.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
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
                        const SizedBox(height: 10),
                        GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: SettleDisclosure(
                              title: 'More actions',
                              subtitle: 'Continue plan, reset, rules, or settings.',
                              children: [
                                const SizedBox(height: 6),
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
                                          returnMode:
                                              SpecPolicy.nowModeIncident,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (!sleepState.hasActivePlan &&
                                    sleepEnabled) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'No plan yet. This opens Sleep Tonight.',
                                    style: T.type.caption.copyWith(
                                      color: T.pal.textTertiary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                _MoreActionTile(
                                  label: 'Plan',
                                  subtitle: 'Pick one focus for this week',
                                  enabled: planEnabled,
                                  onTap: () => context.push('/plan'),
                                ),
                                const SizedBox(height: 8),
                                _MoreActionTile(
                                  label: 'Rules',
                                  subtitle: rulesState.unreadCount > 0
                                      ? '${rulesState.unreadCount} changes to review'
                                      : 'Shared scripts for caregivers',
                                  badge: rulesState.unreadCount,
                                  enabled: rulesEnabled,
                                  onTap: () => context.push('/rules'),
                                ),
                                const SizedBox(height: 8),
                                _MoreActionTile(
                                  label: 'Settings',
                                  subtitle: 'Profile and app preferences',
                                  onTap: () => context.push('/settings'),
                                ),
                                const SizedBox(height: 8),
                              ],
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: T.glass.fill,
            borderRadius: BorderRadius.circular(T.radius.lg),
            border: Border.all(color: T.glass.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: T.type.label),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: T.type.caption.copyWith(
                        color: T.pal.textSecondary,
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
                    color: T.glass.fillAccent,
                    borderRadius: BorderRadius.circular(T.radius.pill),
                  ),
                  child: Text(
                    '$badge',
                    style: T.type.caption.copyWith(
                      color: T.pal.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: T.pal.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
