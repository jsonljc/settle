import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/release_rollout_provider.dart';
import '../services/spec_policy.dart';
import '../theme/glass_components.dart';
import '../theme/settle_tokens.dart';
import '../widgets/screen_header.dart';
import '../widgets/settle_disclosure.dart';

class ReliefHubScreen extends ConsumerWidget {
  const ReliefHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rollout = ref.watch(releaseRolloutProvider);
    final rolloutReady = !rollout.isLoading;
    final incidentEnabled = !rolloutReady || rollout.helpNowEnabled;
    final sleepEnabled = !rolloutReady || rollout.sleepTonightEnabled;

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Start Relief',
                  subtitle: 'Pick the moment. We open one specific next step.',
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        _ReliefTile(
                          label: 'Bedtime protest',
                          subtitle: 'Open Sleep Tonight runner for bedtime.',
                          icon: Icons.nightlight_round,
                          enabled: sleepEnabled,
                          highlighted: true,
                          onTap: () => context.push(
                            SpecPolicy.sleepTonightScenarioUri(
                              'bedtime_protest',
                              source: 'relief',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ReliefTile(
                          label: 'Night wake',
                          subtitle: 'Open Sleep Tonight runner for wakes.',
                          icon: Icons.bedtime_outlined,
                          enabled: sleepEnabled,
                          onTap: () => context.push(
                            SpecPolicy.sleepTonightScenarioUri(
                              'night_wakes',
                              source: 'relief',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        GlassCard(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: SettleDisclosure(
                              title: 'Other situations',
                              subtitle: 'Early wakes and incident scripts.',
                              children: [
                                const SizedBox(height: 8),
                                _ReliefTile(
                                  label: 'Early wake',
                                  subtitle:
                                      'Open Sleep Tonight runner for early wakes.',
                                  icon: Icons.wb_twilight_outlined,
                                  enabled: sleepEnabled,
                                  onTap: () => context.push(
                                    SpecPolicy.sleepTonightScenarioUri(
                                      'early_wakes',
                                      source: 'relief',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _ReliefTile(
                                  label: 'Public tantrum',
                                  subtitle:
                                      'Open incident script for public moments.',
                                  icon: Icons.storefront_outlined,
                                  enabled: incidentEnabled,
                                  onTap: () => context.push(
                                    SpecPolicy.nowIncidentUri(
                                      source: 'relief',
                                      incident: 'public_meltdown',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _ReliefTile(
                                  label: 'Hitting / biting meltdown',
                                  subtitle:
                                      'Open incident script for aggressive moments.',
                                  icon: Icons.sports_mma_outlined,
                                  enabled: incidentEnabled,
                                  onTap: () => context.push(
                                    SpecPolicy.nowIncidentUri(
                                      source: 'relief',
                                      incident: 'hitting_throwing',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                              ],
                          ),
                        ),
                        if (rolloutReady && (!incidentEnabled || !sleepEnabled))
                          Padding(
                            padding: const EdgeInsets.only(top: 14),
                            child: Text(
                              'Some routes are taking a short break.',
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

class _ReliefTile extends StatelessWidget {
  const _ReliefTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.highlighted = false,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.58,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: GlassCard(
          child: Row(
            children: [
              Icon(
                icon,
                color: highlighted ? T.pal.accent : T.pal.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: T.type.h3),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: T.type.caption.copyWith(
                        color: T.pal.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
