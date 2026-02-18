import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/profile_provider.dart';
import '../providers/release_rollout_provider.dart';
import '../services/release_ops_service.dart';
import '../theme/glass_components.dart';
import '../theme/settle_design_system.dart';
import '../widgets/gradient_background.dart';
import '../widgets/release_surfaces.dart';
import '../widgets/screen_header.dart';

class _RocT {
  _RocT._();

  static final type = _RocTypeTokens();
  static const pal = _RocPaletteTokens();
  static const glass = _RocGlassTokens();
}

class _RocTypeTokens {
  TextStyle get h3 => SettleTypography.heading;
  TextStyle get body => SettleTypography.body;
  TextStyle get label =>
      SettleTypography.body.copyWith(fontWeight: FontWeight.w600);
  TextStyle get caption => SettleTypography.caption;
}

class _RocPaletteTokens {
  const _RocPaletteTokens();

  Color get textPrimary => SettleColors.nightText;
  Color get textSecondary => SettleColors.nightSoft;
  Color get textTertiary => SettleColors.nightMuted;
  Color get accent => SettleColors.nightAccent;
  Color get teal => SettleColors.sage400;
}

class _RocGlassTokens {
  const _RocGlassTokens();

  Color get border => SettleGlassDark.borderStrong;
}

class ReleaseOpsChecklistScreen extends ConsumerStatefulWidget {
  const ReleaseOpsChecklistScreen({
    super.key,
    this.service = const ReleaseOpsService(),
  });

  final ReleaseOpsService service;

  @override
  ConsumerState<ReleaseOpsChecklistScreen> createState() =>
      _ReleaseOpsChecklistScreenState();
}

class _ReleaseOpsChecklistScreenState
    extends ConsumerState<ReleaseOpsChecklistScreen> {
  Future<ReleaseOpsSnapshot>? _future;
  bool _isUpdatingRollout = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final childId = ref.read(profileProvider)?.createdAt;
    _future = widget.service.loadSnapshot(childId: childId);
  }

  Future<void> _applyRolloutUpdate({
    required Future<void> Function(ReleaseRolloutNotifier notifier) update,
    required String successMessage,
  }) async {
    if (_isUpdatingRollout) return;
    setState(() => _isUpdatingRollout = true);
    try {
      final notifier = ref.read(releaseRolloutProvider.notifier);
      await update(notifier);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          duration: const Duration(milliseconds: 800),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not update rollout control. Try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingRollout = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rollout = ref.watch(releaseRolloutProvider);

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
                ScreenHeader(
                  title: 'Release Ops',
                  trailing: GestureDetector(
                    onTap: () => setState(_reload),
                    child: Icon(
                      Icons.refresh_rounded,
                      size: 20,
                      color: _RocT.pal.textTertiary,
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
                              style: _RocT.type.body.copyWith(
                                color: _RocT.pal.textSecondary,
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
                                Text('Quick controls', style: _RocT.type.h3),
                                const SizedBox(height: 8),
                                if (_isUpdatingRollout) ...[
                                  Text(
                                    'Updating rollout flags…',
                                    style: _RocT.type.caption.copyWith(
                                      color: _RocT.pal.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                _RolloutSwitchRow(
                                  label: 'Help Now',
                                  value: rollout.helpNowEnabled,
                                  enabled: !_isUpdatingRollout,
                                  onChanged: (v) => _applyRolloutUpdate(
                                    update: (notifier) =>
                                        notifier.setHelpNowEnabled(v),
                                    successMessage: 'Help Now updated',
                                  ),
                                ),
                                _RolloutSwitchRow(
                                  label: 'Sleep Tonight',
                                  value: rollout.sleepTonightEnabled,
                                  enabled: !_isUpdatingRollout,
                                  onChanged: (v) => _applyRolloutUpdate(
                                    update: (notifier) =>
                                        notifier.setSleepTonightEnabled(v),
                                    successMessage: 'Sleep Tonight updated',
                                  ),
                                ),
                                _RolloutSwitchRow(
                                  label: 'Plan & Progress',
                                  value: rollout.planProgressEnabled,
                                  enabled: !_isUpdatingRollout,
                                  onChanged: (v) => _applyRolloutUpdate(
                                    update: (notifier) =>
                                        notifier.setPlanProgressEnabled(v),
                                    successMessage: 'Plan & Progress updated',
                                  ),
                                ),
                                _RolloutSwitchRow(
                                  label: 'Family Rules',
                                  value: rollout.familyRulesEnabled,
                                  enabled: !_isUpdatingRollout,
                                  onChanged: (v) => _applyRolloutUpdate(
                                    update: (notifier) =>
                                        notifier.setFamilyRulesEnabled(v),
                                    successMessage: 'Family Rules updated',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Divider(color: _RocT.glass.border),
                                const SizedBox(height: 6),
                                Text('Phase 1 controls', style: _RocT.type.h3),
                                const SizedBox(height: 8),
                                _RolloutSwitchRow(
                                  label: 'Plan tab',
                                  switchKey: const ValueKey('rollout_v2_plan'),
                                  value: rollout.planTabEnabled,
                                  enabled: !_isUpdatingRollout,
                                  onChanged: (v) => _applyRolloutUpdate(
                                    update: (notifier) =>
                                        notifier.setPlanTabEnabled(v),
                                    successMessage: 'Plan tab updated',
                                  ),
                                ),
                                _RolloutSwitchRow(
                                  label: 'Family tab',
                                  switchKey: const ValueKey(
                                    'rollout_v2_family',
                                  ),
                                  value: rollout.familyTabEnabled,
                                  enabled: !_isUpdatingRollout,
                                  onChanged: (v) => _applyRolloutUpdate(
                                    update: (notifier) =>
                                        notifier.setFamilyTabEnabled(v),
                                    successMessage: 'Family tab updated',
                                  ),
                                ),
                                _RolloutSwitchRow(
                                  label: 'Library tab',
                                  switchKey: const ValueKey(
                                    'rollout_v2_library',
                                  ),
                                  value: rollout.libraryTabEnabled,
                                  enabled: !_isUpdatingRollout,
                                  onChanged: (v) => _applyRolloutUpdate(
                                    update: (notifier) =>
                                        notifier.setLibraryTabEnabled(v),
                                    successMessage: 'Library tab updated',
                                  ),
                                ),
                                _RolloutSwitchRow(
                                  label: 'Regulate route',
                                  switchKey: const ValueKey(
                                    'rollout_v2_regulate',
                                  ),
                                  caption:
                                      'Controls /sos and /breathe -> /plan/regulate redirects',
                                  value: rollout.regulateEnabled,
                                  enabled: !_isUpdatingRollout,
                                  onChanged: (v) => _applyRolloutUpdate(
                                    update: (notifier) =>
                                        notifier.setRegulateEnabled(v),
                                    successMessage: v
                                        ? 'Regulate redirect enabled'
                                        : 'Regulate redirect disabled',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Divider(color: _RocT.glass.border),
                                const SizedBox(height: 6),
                                Text('Foundation flags', style: _RocT.type.h3),
                                const SizedBox(height: 8),
                                _RolloutSwitchRow(
                                  label: 'Sleep bounded AI copy',
                                  value: rollout.sleepBoundedAiEnabled,
                                  enabled: !_isUpdatingRollout,
                                  onChanged: (v) => _applyRolloutUpdate(
                                    update: (notifier) =>
                                        notifier.setSleepBoundedAiEnabled(v),
                                    successMessage:
                                        'Sleep bounded AI copy updated',
                                  ),
                                ),
                                _RolloutSwitchRow(
                                  label: 'Sleep rhythm surfaces',
                                  value: rollout.sleepRhythmSurfacesEnabled,
                                  enabled: !_isUpdatingRollout,
                                  onChanged: (v) => _applyRolloutUpdate(
                                    update: (notifier) => notifier
                                        .setSleepRhythmSurfacesEnabled(v),
                                    successMessage:
                                        'Sleep rhythm surfaces updated',
                                  ),
                                ),
                                _RolloutSwitchRow(
                                  label: 'Rhythm detector prompts',
                                  value:
                                      rollout.rhythmShiftDetectorPromptsEnabled,
                                  enabled: !_isUpdatingRollout,
                                  onChanged: (v) => _applyRolloutUpdate(
                                    update: (notifier) => notifier
                                        .setRhythmShiftDetectorPromptsEnabled(
                                          v,
                                        ),
                                    successMessage:
                                        'Rhythm detector prompts updated',
                                  ),
                                ),
                                _RolloutSwitchRow(
                                  label: 'Wind-down notifications',
                                  value: rollout.windDownNotificationsEnabled,
                                  enabled: !_isUpdatingRollout,
                                  onChanged: (v) => _applyRolloutUpdate(
                                    update: (notifier) => notifier
                                        .setWindDownNotificationsEnabled(v),
                                    successMessage:
                                        'Wind-down notifications updated',
                                  ),
                                ),
                                _RolloutSwitchRow(
                                  label: 'Drift notifications',
                                  value:
                                      rollout.scheduleDriftNotificationsEnabled,
                                  enabled: !_isUpdatingRollout,
                                  onChanged: (v) => _applyRolloutUpdate(
                                    update: (notifier) => notifier
                                        .setScheduleDriftNotificationsEnabled(
                                          v,
                                        ),
                                    successMessage:
                                        'Drift notifications updated',
                                  ),
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
    final color = ready ? _RocT.pal.teal : SettleColors.blush400;

    return GlassCardAccent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ready ? 'Ready to expand rollout' : 'Hold rollout',
            style: _RocT.type.h3.copyWith(color: _RocT.pal.accent),
          ),
          const SizedBox(height: 8),
          Text(
            'Required: ${data.requiredPassCount}/${data.requiredTotal} · Advisory: ${data.advisoryPassCount}/${data.advisoryTotal}',
            style: _RocT.type.body.copyWith(color: _RocT.pal.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: ${ready ? 'green' : 'needs attention'}',
            style: _RocT.type.caption.copyWith(
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
          Text(title, style: _RocT.type.h3),
          const SizedBox(height: 8),
          ...gates.map((gate) {
            final color = gate.passed ? _RocT.pal.teal : SettleColors.blush400;
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
                        Text(gate.title, style: _RocT.type.label),
                        const SizedBox(height: 2),
                        Text(
                          gate.detail,
                          style: _RocT.type.caption.copyWith(
                            color: _RocT.pal.textSecondary,
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
    this.switchKey,
    this.enabled = true,
    this.caption,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Key? switchKey;
  final bool enabled;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: _RocT.type.caption.copyWith(
                  color: enabled
                      ? _RocT.pal.textPrimary
                      : _RocT.pal.textTertiary,
                ),
              ),
              if (caption != null) ...[
                const SizedBox(height: 2),
                Text(
                  caption!,
                  style: _RocT.type.caption.copyWith(
                    color: _RocT.pal.textTertiary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
        Switch.adaptive(
          key: switchKey,
          value: value,
          onChanged: enabled ? onChanged : null,
          activeColor: _RocT.pal.accent,
        ),
      ],
    );
  }
}
