import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rules_diff.dart';
import '../providers/family_rules_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/release_rollout_provider.dart';
import '../providers/sleep_tonight_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_pill.dart';
import '../theme/settle_design_system.dart';
import '../widgets/gradient_background.dart';
import '../widgets/calm_loading.dart';
import '../widgets/release_surfaces.dart';
import '../widgets/screen_header.dart';
import '../widgets/settle_disclosure.dart';
import '../widgets/settle_tappable.dart';
import '../widgets/error_state.dart';

String _ruleLabel(String ruleId) {
  return switch (ruleId) {
    'boundary_public' => 'Public boundary script',
    'screens_default' => 'Screens default',
    'snacks_default' => 'Snacks default',
    'bedtime_routine' => 'Bedtime routine',
    _ => ruleId.replaceAll('_', ' '),
  };
}

class FamilyRulesScreen extends ConsumerWidget {
  const FamilyRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rollout = ref.watch(releaseRolloutProvider);
    if (!rollout.isLoading && !rollout.familyRulesEnabled) {
      return const FeaturePausedView(title: 'Family Rules');
    }

    final profile = ref.watch(profileProvider);
    final rulesState = ref.watch(familyRulesProvider);
    final sleepPlan = ref.watch(sleepTonightProvider).activePlan;

    if (profile == null) {
      return const ProfileRequiredView(title: 'Family Rules');
    }

    final childId = profile.createdAt;
    final author = 'Primary caregiver';

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
                  title: 'Family Rules',
                  subtitle: rulesState.unreadCount == 0
                      ? 'No pending updates right now.'
                      : '${rulesState.unreadCount} updates to review',
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: SettleSurfaces.tintDusk,
                      borderRadius: BorderRadius.circular(SettleRadii.pill),
                    ),
                    child: Text(
                      'v${rulesState.rulesetVersion}',
                      style: SettleTypography.caption.copyWith(color: SettleColors.nightAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const BehavioralScopeNotice(),
                const SizedBox(height: 14),
                Expanded(
                  child: rulesState.isLoading
                      ? const CalmLoading(message: 'Loading shared scripts…')
                      : rulesState.error != null
                      ? SettleErrorState(
                          message: rulesState.error!,
                          onRetry: () =>
                              ref.read(familyRulesProvider.notifier).load(),
                        )
                      : ListView(
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _PendingDiffs(childId: childId, state: rulesState),
                            const SizedBox(height: 10),
                            _RulesEditor(
                              title: 'Boundary scripts',
                              rules: {
                                'boundary_public':
                                    rulesState.rules['boundary_public'] ?? '',
                              },
                              onSave: (ruleId, value) => ref
                                  .read(familyRulesProvider.notifier)
                                  .updateRule(
                                    childId: childId,
                                    ruleId: ruleId,
                                    newValue: value,
                                    author: author,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            GlassCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: SettleDisclosure(
                                title: 'More details (optional)',
                                titleStyle: SettleTypography.heading,
                                subtitle:
                                    'Defaults, tonight context, and recent updates.',
                                children: [
                                  const SizedBox(height: 6),
                                  _RulesEditor(
                                    title: 'Defaults',
                                    embedded: true,
                                    rules: {
                                      'screens_default':
                                          rulesState.rules['screens_default'] ??
                                          '',
                                      'snacks_default':
                                          rulesState.rules['snacks_default'] ??
                                          '',
                                      'bedtime_routine':
                                          rulesState.rules['bedtime_routine'] ??
                                          '',
                                    },
                                    onSave: (ruleId, value) => ref
                                        .read(familyRulesProvider.notifier)
                                        .updateRule(
                                          childId: childId,
                                          ruleId: ruleId,
                                          newValue: value,
                                          author: author,
                                        ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Tonight plan context',
                                    style: SettleTypography.heading,
                                  ),
                                  const SizedBox(height: 8),
                                  if (sleepPlan == null ||
                                      !(sleepPlan['is_active'] as bool? ??
                                          false))
                                    Text(
                                      'No active sleep plan yet tonight.',
                                      style: SettleTypography.caption.copyWith(
                                        color: SettleColors.nightSoft,
                                      ),
                                    )
                                  else ...[
                                    Text(
                                      'Scenario: ${sleepPlan['scenario']}',
                                      style: SettleTypography.caption,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      sleepPlan['escalation_rule']
                                              ?.toString() ??
                                          '',
                                      style: SettleTypography.body.copyWith(
                                        color: SettleColors.nightSoft,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Text('Recent updates', style: SettleTypography.heading),
                                  const SizedBox(height: 8),
                                  if (rulesState.changeFeed.isEmpty)
                                    Text(
                                      'No updates yet.',
                                      style: SettleTypography.caption.copyWith(
                                        color: SettleColors.nightSoft,
                                      ),
                                    )
                                  else
                                    ...rulesState.changeFeed
                                        .take(10)
                                        .map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: Text(
                                              '• ${item['message']} (${item['timestamp'].toString().split('T').first})',
                                              style: SettleTypography.caption.copyWith(
                                                color: SettleColors.nightSoft,
                                              ),
                                            ),
                                          ),
                                        ),
                                  const SizedBox(height: 6),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
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

class _RulesEditor extends StatefulWidget {
  const _RulesEditor({
    required this.title,
    required this.rules,
    required this.onSave,
    this.embedded = false,
  });

  final String title;
  final Map<String, String> rules;
  final Future<void> Function(String ruleId, String value) onSave;
  final bool embedded;

  @override
  State<_RulesEditor> createState() => _RulesEditorState();
}

class _RulesEditorState extends State<_RulesEditor> {
  late final Map<String, TextEditingController> _controllers;
  String? _lastSavedRuleId;

  @override
  void initState() {
    super.initState();
    _controllers = {
      for (final entry in widget.rules.entries)
        entry.key: TextEditingController(text: entry.value),
    };
  }

  @override
  void didUpdateWidget(covariant _RulesEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final entry in widget.rules.entries) {
      final c = _controllers[entry.key];
      if (c != null && c.text != entry.value) {
        c.text = entry.value;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _saveRule(String ruleId) async {
    final controller = _controllers[ruleId];
    if (controller == null) return;
    await widget.onSave(ruleId, controller.text.trim());
    if (!mounted) return;
    setState(() {
      _lastSavedRuleId = ruleId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: SettleTypography.heading),
        const SizedBox(height: 8),
        ...widget.rules.keys.map((ruleId) {
          final controller = _controllers[ruleId]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  style: SettleTypography.caption,
                  decoration: InputDecoration(
                    labelText: _ruleLabel(ruleId),
                    labelStyle: SettleTypography.caption.copyWith(
                      color: SettleColors.nightMuted,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  onSubmitted: (_) => _saveRule(ruleId),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _RuleActionLink(
                      label: 'Save',
                      onTap: () => _saveRule(ruleId),
                    ),
                    if (_lastSavedRuleId == ruleId) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Saved',
                        style: SettleTypography.caption.copyWith(
                          color: SettleColors.sage400,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );

    if (widget.embedded) {
      return GlassCard(
        padding: const EdgeInsets.all(16),
        fill: SettleSurfaces.cardDark,
        child: content,
      );
    }

    return GlassCard(child: content);
  }
}

class _PendingDiffs extends ConsumerWidget {
  const _PendingDiffs({required this.childId, required this.state});

  final String childId;
  final FamilyRulesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byRule = <String, List<RulesDiff>>{};
    for (final diff in state.pendingDiffs) {
      final rule = diff.changedRuleId;
      byRule.putIfAbsent(rule, () => []).add(diff);
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pending updates', style: SettleTypography.heading),
          const SizedBox(height: 8),
          if (state.pendingDiffs.isEmpty)
            Text(
              'No updates waiting.',
              style: SettleTypography.caption.copyWith(color: SettleColors.nightSoft),
            )
          else
            ...byRule.entries.map((entry) {
              final ruleId = entry.key;
              final diffs = entry.value;
              final overlapConflicts = state.overlapConflictsForRule(ruleId);

              if (overlapConflicts.length > 1) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose one final version for ${_ruleLabel(ruleId)}.',
                        style: SettleTypography.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      ...overlapConflicts.map((diff) {
                        final dateLabel = diff.timestamp.split('T').first;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: GlassCard(
                            border: false,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  diff.newValue,
                                  style: SettleTypography.caption.copyWith(
                                    color: SettleColors.nightSoft,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Updated by ${diff.author} on $dateLabel',
                                  style: SettleTypography.caption.copyWith(
                                    color: SettleColors.nightMuted,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GlassPill(
                                  label: 'Use this version',
                                  onTap: () => ref
                                      .read(familyRulesProvider.notifier)
                                      .resolveConflict(
                                        childId: childId,
                                        ruleId: ruleId,
                                        chosenDiffId: diff.diffId,
                                        resolver: 'Primary caregiver',
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: diffs.map((diff) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: GlassCard(
                      border: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_ruleLabel(ruleId), style: SettleTypography.body.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(
                            'Current: ${diff.oldValue}',
                            style: SettleTypography.caption.copyWith(
                              color: SettleColors.nightMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Suggested: ${diff.newValue}',
                            style: SettleTypography.caption.copyWith(
                              color: SettleColors.nightSoft,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GlassPill(
                            label: 'Use this version',
                            onTap: () => ref
                                .read(familyRulesProvider.notifier)
                                .acceptDiff(
                                  childId: childId,
                                  diffId: diff.diffId,
                                  reviewer: 'Primary caregiver',
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
        ],
      ),
    );
  }
}

class _RuleActionLink extends StatelessWidget {
  const _RuleActionLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SettleTappable(
      semanticLabel: label,
      onTap: onTap,
      child: Text(
        label,
        style: SettleTypography.caption.copyWith(
          color: SettleColors.nightMuted,
          decoration: TextDecoration.underline,
          decorationColor: SettleColors.nightMuted,
        ),
      ),
    );
  }
}
