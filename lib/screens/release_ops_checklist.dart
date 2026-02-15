import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/profile_provider.dart';
import '../providers/release_rollout_provider.dart';
import '../services/release_ops_service.dart';
import '../theme/glass_components.dart';
import '../theme/settle_tokens.dart';
import '../widgets/release_surfaces.dart';
import '../widgets/screen_header.dart';

class ReleaseOpsChecklistScreen extends ConsumerStatefulWidget {
  const ReleaseOpsChecklistScreen({super.key});

  @override
  ConsumerState<ReleaseOpsChecklistScreen> createState() =>
      _ReleaseOpsChecklistScreenState();
}

class _ReleaseOpsChecklistScreenState
    extends ConsumerState<ReleaseOpsChecklistScreen> {
  final _service = const ReleaseOpsService();
  Future<ReleaseOpsSnapshot>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final childId = ref.read(profileProvider)?.createdAt;
    _future = _service.loadSnapshot(childId: childId);
  }

  @override
  Widget build(BuildContext context) {
    final rollout = ref.watch(releaseRolloutProvider);

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScreenHeader(
                  title: 'Release Ops',
                  trailing: GestureDetector(
                    onTap: () => setState(_reload),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: T.pal.textTertiary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const BehavioralScopeNotice(),
                const SizedBox(height: 14),
                Expanded(
                  child: FutureBuilder<ReleaseOpsSnapshot>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator.adaptive(),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Center(
                          child: GlassCard(
                            child: Text(
                              'Unable to load release checklist.',
                              style: T.type.body.copyWith(
                                color: T.pal.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }
                      final data = snapshot.data!;
                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _HeaderCard(data: data),
                          const SizedBox(height: 10),
                          _GateSection(
                            title: 'Required gates',
                            gates: data.requiredGates,
                          ),
                          const SizedBox(height: 10),
                          _GateSection(
                            title: 'Advisory signals',
                            gates: data.advisoryGates,
                          ),
                          const SizedBox(height: 10),
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Quick controls', style: T.type.h3),
                                const SizedBox(height: 8),
                                _RolloutSwitchRow(
                                  label: 'Help Now',
                                  value: rollout.helpNowEnabled,
                                  onChanged: (v) => ref
                                      .read(releaseRolloutProvider.notifier)
                                      .setHelpNowEnabled(v),
                                ),
                                _RolloutSwitchRow(
                                  label: 'Sleep Tonight',
                                  value: rollout.sleepTonightEnabled,
                                  onChanged: (v) => ref
                                      .read(releaseRolloutProvider.notifier)
                                      .setSleepTonightEnabled(v),
                                ),
                                _RolloutSwitchRow(
                                  label: 'Plan & Progress',
                                  value: rollout.planProgressEnabled,
                                  onChanged: (v) => ref
                                      .read(releaseRolloutProvider.notifier)
                                      .setPlanProgressEnabled(v),
                                ),
                                _RolloutSwitchRow(
                                  label: 'Family Rules',
                                  value: rollout.familyRulesEnabled,
                                  onChanged: (v) => ref
                                      .read(releaseRolloutProvider.notifier)
                                      .setFamilyRulesEnabled(v),
                                ),
                                _RolloutSwitchRow(
                                  label: 'Sleep bounded AI copy',
                                  value: rollout.sleepBoundedAiEnabled,
                                  onChanged: (v) => ref
                                      .read(releaseRolloutProvider.notifier)
                                      .setSleepBoundedAiEnabled(v),
                                ),
                                _RolloutSwitchRow(
                                  label: 'Wind-down notifications',
                                  value: rollout.windDownNotificationsEnabled,
                                  onChanged: (v) => ref
                                      .read(releaseRolloutProvider.notifier)
                                      .setWindDownNotificationsEnabled(v),
                                ),
                                _RolloutSwitchRow(
                                  label: 'Drift notifications',
                                  value:
                                      rollout.scheduleDriftNotificationsEnabled,
                                  onChanged: (v) => ref
                                      .read(releaseRolloutProvider.notifier)
                                      .setScheduleDriftNotificationsEnabled(v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              GlassPill(
                                label: 'Open Release Metrics',
                                onTap: () => context.push('/release-metrics'),
                              ),
                              GlassPill(
                                label: 'Open Compliance',
                                onTap: () =>
                                    context.push('/release-compliance'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.data});

  final ReleaseOpsSnapshot data;

  @override
  Widget build(BuildContext context) {
    final ready = data.rolloutReady;
    final color = ready ? T.pal.teal : const Color(0xFFC86464);

    return GlassCardAccent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ready ? 'Ready to expand rollout' : 'Hold rollout',
            style: T.type.h3.copyWith(color: T.pal.accent),
          ),
          const SizedBox(height: 8),
          Text(
            'Required: ${data.requiredPassCount}/${data.requiredTotal} · Advisory: ${data.advisoryPassCount}/${data.advisoryTotal}',
            style: T.type.body.copyWith(color: T.pal.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: ${ready ? 'green' : 'needs attention'}',
            style: T.type.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GateSection extends StatelessWidget {
  const _GateSection({required this.title, required this.gates});

  final String title;
  final List<ReleaseOpsGate> gates;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: T.type.h3),
          const SizedBox(height: 8),
          ...gates.map((gate) {
            final color = gate.passed ? T.pal.teal : const Color(0xFFC86464);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      gate.passed
                          ? Icons.check_circle_rounded
                          : Icons.error_outline_rounded,
                      size: 16,
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(gate.title, style: T.type.label),
                        const SizedBox(height: 2),
                        Text(
                          gate.detail,
                          style: T.type.caption.copyWith(
                            color: T.pal.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RolloutSwitchRow extends StatelessWidget {
  const _RolloutSwitchRow({
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
