import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../internal_tools_gate.dart';
import '../models/approach.dart';
import '../models/tantrum_profile.dart';
import '../providers/disruption_provider.dart';
import '../providers/nudge_settings_provider.dart';
import '../providers/patterns_provider.dart';
import '../providers/profile_provider.dart';
import '../services/focus_mode_rules.dart';
import '../services/nudge_scheduler.dart';
import '../services/notification_service.dart';
import '../theme/settle_design_system.dart';
import '../widgets/glass_card.dart';
import '../widgets/settle_gap.dart';
import '../widgets/gradient_background.dart';
import '../widgets/screen_header.dart';
import '../widgets/option_button.dart';
import '../widgets/settle_chip.dart';
import '../widgets/settle_disclosure.dart';
import '../widgets/settle_tappable.dart';

/// Settings — profile card, toggle groups, approach switcher.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Toggle states — local until we add persistence
  bool _wakeNudges = true;
  bool _autoNight = false;
  bool _wellbeingCheckins = true;
  bool _simplifiedMode = false;
  bool _oneHanded = false;
  bool _griefAware = false;
  bool _napTransition = false;
  bool _partnerSync = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final disruptionMode = ref.watch(disruptionProvider);
    final allowedModes = FocusModeRules.allowedModesForAge(
      profile?.ageBracket ?? AgeBracket.newborn,
    );
    final showInternalTools = InternalToolsGate.enabled;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardVariant =
        isDark ? GlassCardVariant.dark : GlassCardVariant.light;

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SettleSpacing.screenPadding,
                ),
                child: const ScreenHeader(title: 'Settings'),
              ),
              const SettleGap.lg(),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: SettleSpacing.screenPadding,
                  ).copyWith(bottom: 32),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // ── Profile card ──
                    GlassCard(
                      variant: cardVariant,
                      padding: EdgeInsets.all(SettleSpacing.md),
                      child: Row(
                        children: [
                          // Avatar circle
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: SettleSemanticColors.accent(context)
                                  .withValues(alpha: 0.15),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (profile?.name ?? 'B')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: SettleTypography.heading
                                  .copyWith(
                                    fontSize: 22,
                                    color:
                                        SettleSemanticColors.accent(context),
                                  ),
                            ),
                          ),
                          SizedBox(width: SettleSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?.name ?? 'Baby',
                                  style: SettleTypography.heading.copyWith(
                                    color: SettleSemanticColors.headline(
                                      context,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${profile?.ageBracket.label ?? ''} · ${profile?.approach.label ?? ''}',
                                  style: SettleTypography.caption.copyWith(
                                    color: SettleSemanticColors.supporting(
                                      context,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Focus: ${profile?.focusMode.label ?? FocusMode.sleepOnly.label}',
                                  style: SettleTypography.caption.copyWith(
                                    color:
                                        SettleSemanticColors.muted(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ).entryFadeIn(
                      context,
                      delay: const Duration(milliseconds: 150),
                    ),
                    const SettleGap.lg(),

                    _SectionHeader(title: 'Feature focus'),
                    SizedBox(height: SettleSpacing.cardGap),
                    ...allowedModes.map((mode) {
                      final isSelected =
                          (profile?.focusMode ?? FocusMode.sleepOnly) == mode;
                      return Padding(
                        padding: EdgeInsets.only(bottom: SettleSpacing.sm),
                        child: OptionButton(
                          label: mode.label,
                          selected: isSelected,
                          onTap: () => ref
                              .read(profileProvider.notifier)
                              .updateFocusMode(mode),
                        ),
                      );
                    }),
                    if (profile?.tantrumProfile != null) ...[
                      const SettleGap.sm(),
                      GlassCard(
                        variant: cardVariant,
                        padding: EdgeInsets.all(SettleSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tantrum profile',
                              style: SettleTypography.overline.copyWith(
                                color:
                                    SettleSemanticColors.muted(context),
                              ),
                            ),
                            const SettleGap.sm(),
                            Text(
                              'Type: ${profile!.tantrumProfile!.tantrumType.label}',
                              style: SettleTypography.caption.copyWith(
                                color: SettleSemanticColors.supporting(
                                  context,
                                ),
                              ),
                            ),
                            const SettleGap.xs(),
                            Text(
                              'Triggers: ${profile.tantrumProfile!.commonTriggers.map((t) => t.label).join(', ')}',
                              style: SettleTypography.caption.copyWith(
                                color: SettleSemanticColors.supporting(
                                  context,
                                ),
                              ),
                            ),
                            const SettleGap.xs(),
                            Text(
                              'Priority: ${profile.tantrumProfile!.responsePriority.label}',
                              style: SettleTypography.caption.copyWith(
                                color: SettleSemanticColors.supporting(
                                  context,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SettleGap.lg(),

                    _SectionHeader(title: 'Recommended'),
                    SizedBox(height: SettleSpacing.cardGap),
                    _ToggleCard(
                      label: 'Wake window nudges',
                      value: _wakeNudges,
                      onChanged: (v) => setState(() => _wakeNudges = v),
                    ),
                    const SettleGap.sm(),
                    _ToggleCard(
                      label: 'Wellbeing check-ins',
                      value: _wellbeingCheckins,
                      onChanged: (v) => setState(() => _wellbeingCheckins = v),
                    ),
                    const SettleGap.sm(),
                    _ToggleCard(
                      label: 'Disruption mode',
                      subtitle:
                          'Travel, illness, teething — expands windows, softens guidance',
                      value: disruptionMode,
                      onChanged: (v) =>
                          ref.read(disruptionProvider.notifier).set(v),
                    ),
                    const SettleGap.lg(),
                    _SectionHeader(title: 'Plan nudges'),
                    SizedBox(height: SettleSpacing.cardGap),
                    _NudgeSettingsSection(),
                    const SettleGap.lg(),
                    _SectionHeader(title: 'Shared Scripts'),
                    SizedBox(height: SettleSpacing.cardGap),
                    SettleTappable(
                      semanticLabel: 'Keep caregivers on the same page',
                      onTap: () => context.push('/rules'),
                      child: const _InlineActionRow(
                        icon: Icons.people_outline_rounded,
                        title: 'Keep caregivers on the same page',
                        trailing: Icons.chevron_right_rounded,
                      ),
                    ),
                    const SettleGap.lg(),
                    GlassCard(
                      variant: cardVariant,
                      padding: EdgeInsets.symmetric(
                        horizontal: SettleSpacing.md,
                        vertical: SettleSpacing.sm,
                      ),
                      child: SettleDisclosure(
                        title: 'More settings',
                        subtitle:
                            'Accessibility, sharing, and advanced preferences.',
                        children: [
                          const SettleGap.sm(),
                          _SectionHeader(title: 'Alerts'),
                          const SettleGap.sm(),
                          _ToggleCard(
                            label: 'Auto nighttime support',
                            value: _autoNight,
                            embedded: true,
                            onChanged: (v) => setState(() => _autoNight = v),
                          ),
                          const SizedBox(height: 12),
                          _SectionHeader(title: 'Accessibility'),
                          const SettleGap.sm(),
                          _ToggleCard(
                            label: 'Simplified mode',
                            value: _simplifiedMode,
                            embedded: true,
                            onChanged: (v) =>
                                setState(() => _simplifiedMode = v),
                          ),
                          const SettleGap.sm(),
                          _ToggleCard(
                            label: 'One-handed mode',
                            value: _oneHanded,
                            embedded: true,
                            onChanged: (v) => setState(() => _oneHanded = v),
                          ),
                          const SettleGap.sm(),
                          _ToggleCard(
                            label: 'Grief-aware language',
                            value: _griefAware,
                            embedded: true,
                            onChanged: (v) => setState(() => _griefAware = v),
                          ),
                          const SizedBox(height: 12),
                          _SectionHeader(title: 'Sleep details'),
                          const SettleGap.sm(),
                          _ToggleCard(
                            label: 'Nap transition',
                            subtitle: 'Adjusting nap count',
                            value: _napTransition,
                            embedded: true,
                            onChanged: (v) =>
                                setState(() => _napTransition = v),
                          ),
                          const SizedBox(height: 12),
                          _SectionHeader(title: 'Sharing'),
                          const SettleGap.sm(),
                          _ToggleCard(
                            label: 'Partner sync',
                            value: _partnerSync,
                            embedded: true,
                            onChanged: (v) => setState(() => _partnerSync = v),
                          ),
                          const SettleGap.sm(),
                          Opacity(
                            opacity: 0.55,
                            child: _InlineActionRow(
                              icon: Icons.share_outlined,
                              title: 'Sharing tools are in progress',
                              trailing: Icons.hourglass_bottom_rounded,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _SectionHeader(title: 'Approach'),
                          const SettleGap.sm(),
                          if (profile != null)
                            OptionButton(
                              label: profile.approach.label,
                              subtitle: profile.approach.description,
                              selected: true,
                              onTap: () => context.push('/sleep/tonight'),
                              icon: _approachIcon(profile.approach),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            'To switch approach, use Tonight → More options → Change approach.',
                            style: SettleTypography.caption.copyWith(
                              color: SettleSemanticColors.supporting(context),
                            ),
                          ),
                          if (showInternalTools) ...[
                            const SizedBox(height: 12),
                            _SectionHeader(title: 'Internal tools'),
                            const SettleGap.sm(),
                            SettleTappable(
                              semanticLabel: 'Open release checks',
                              onTap: () => context.push('/release-ops'),
                              child: const _InlineActionRow(
                                icon: Icons.tune_rounded,
                                title: 'Open release checks',
                                trailing: Icons.chevron_right_rounded,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          _SectionHeader(title: 'App'),
                          const SettleGap.sm(),
                          SettleTappable(
                            semanticLabel: 'Restart from onboarding',
                            onTap: () async {
                              await ref.read(profileProvider.notifier).clear();
                              if (context.mounted) context.go('/');
                            },
                            child: const _InlineActionRow(
                              icon: Icons.replay_rounded,
                              title: 'Restart from onboarding',
                              trailing: Icons.chevron_right_rounded,
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Section Header
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: SettleTypography.overline.copyWith(
        color: SettleSemanticColors.muted(context),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Toggle Card
// ─────────────────────────────────────────────

class _ToggleCard extends StatelessWidget {
  const _ToggleCard({
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.embedded = false,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? subtitle;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = SettleSemanticColors.accent(context);
    final mutedColor = SettleSemanticColors.muted(context);
    final strongVariant =
        isDark ? GlassCardVariant.darkStrong : GlassCardVariant.lightStrong;
    final standardVariant =
        isDark ? GlassCardVariant.dark : GlassCardVariant.light;
    final inactiveTrack = isDark
        ? SettleSurfaces.cardDark
        : SettleSurfaces.cardLight;

    final content = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: SettleTypography.label.copyWith(
                  color: SettleSemanticColors.headline(context),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: SettleTypography.caption.copyWith(
                    color: mutedColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 28,
          child: Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: accentColor,
            activeTrackColor: accentColor.withValues(alpha: 0.3),
            inactiveTrackColor: inactiveTrack,
            inactiveThumbColor: mutedColor,
          ),
        ),
      ],
    );

    if (embedded) {
      return GlassCard(
        padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: SettleSpacing.cardGap,
      ),
        variant: strongVariant,
        child: content,
      );
    }

    return GlassCard(
      padding: EdgeInsets.symmetric(
        horizontal: SettleSpacing.md,
        vertical: 12,
      ),
      variant: standardVariant,
      child: content,
    );
  }
}

// ─────────────────────────────────────────────
//  Nudge settings (v2 Plan nudges)
// ─────────────────────────────────────────────

class _NudgeSettingsSection extends ConsumerWidget {
  const _NudgeSettingsSection();

  Future<void> _refreshScheduler(WidgetRef ref) async {
    final profile = ref.read(profileProvider);
    final patterns = ref.read(patternsProvider);
    final settings = ref.read(nudgeSettingsProvider);
    await NudgeScheduler.scheduleNudges(
      profile: profile,
      patterns: patterns,
      settings: settings,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(nudgeSettingsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardVariant =
        isDark ? GlassCardVariant.dark : GlassCardVariant.light;

    return GlassCard(
      variant: cardVariant,
      padding: EdgeInsets.all(SettleSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gentle reminders for scripts and patterns. Quiet hours: no nudges.',
            style: SettleTypography.caption.copyWith(
              color: SettleSemanticColors.supporting(context),
            ),
          ),
          const SizedBox(height: 12),
          _ToggleCard(
            label: 'Predictable moment (e.g. before bedtime)',
            value: settings.predictableEnabled,
            onChanged: (v) async {
              await ref
                  .read(nudgeSettingsProvider.notifier)
                  .setPredictableEnabled(v);
              await _refreshScheduler(ref);
            },
          ),
          const SettleGap.sm(),
          _ToggleCard(
            label: 'Pattern-based (from your usage)',
            value: settings.patternEnabled,
            onChanged: (v) async {
              await ref
                  .read(nudgeSettingsProvider.notifier)
                  .setPatternEnabled(v);
              await _refreshScheduler(ref);
            },
          ),
          const SettleGap.sm(),
          _ToggleCard(
            label: 'Content (age-based tips)',
            value: settings.contentEnabled,
            onChanged: (v) async {
              await ref
                  .read(nudgeSettingsProvider.notifier)
                  .setContentEnabled(v);
              await _refreshScheduler(ref);
            },
          ),
          const SettleGap.sm(),
          _ToggleCard(
            label: 'Evening check-in (1h before bedtime)',
            value: settings.eveningCheckInEnabled,
            onChanged: (v) async {
              await ref
                  .read(nudgeSettingsProvider.notifier)
                  .setEveningCheckInEnabled(v);
              if (!v) await NotificationService.cancelEveningCheckIn();
            },
          ),
          const SizedBox(height: 12),
          Text(
            'Quiet hours: ${_formatHour(settings.quietStartHour)} – ${_formatHour(settings.quietEndHour)}',
            style: SettleTypography.caption.copyWith(
              color: SettleSemanticColors.muted(context),
            ),
          ),
          const SettleGap.sm(),
          Text(
            'Frequency: ${_frequencyLabel(settings.frequency)}',
            style: SettleTypography.caption.copyWith(
              color: SettleSemanticColors.muted(context),
            ),
          ),
          SizedBox(height: SettleSpacing.cardGap),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SettleChip(
                variant: SettleChipVariant.frequency,
                label: 'Minimal',
                selected: settings.frequency == NudgeFrequency.minimal,
                onTap: () async {
                  await ref
                      .read(nudgeSettingsProvider.notifier)
                      .setFrequency(NudgeFrequency.minimal);
                  await _refreshScheduler(ref);
                },
              ),
              SettleChip(
                variant: SettleChipVariant.frequency,
                label: 'Smart',
                selected: settings.frequency == NudgeFrequency.smart,
                onTap: () async {
                  await ref
                      .read(nudgeSettingsProvider.notifier)
                      .setFrequency(NudgeFrequency.smart);
                  await _refreshScheduler(ref);
                },
              ),
              SettleChip(
                variant: SettleChipVariant.frequency,
                label: 'More',
                selected: settings.frequency == NudgeFrequency.more,
                onTap: () async {
                  await ref
                      .read(nudgeSettingsProvider.notifier)
                      .setFrequency(NudgeFrequency.more);
                  await _refreshScheduler(ref);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatHour(int h) {
    if (h == 0) return '12am';
    if (h == 12) return '12pm';
    if (h < 12) return '${h}am';
    return '${h - 12}pm';
  }

  String _frequencyLabel(NudgeFrequency f) {
    return switch (f) {
      NudgeFrequency.minimal => '~1 per week',
      NudgeFrequency.smart => '2–3 per week',
      NudgeFrequency.more => 'Up to 3 per week',
    };
  }
}

class _InlineActionRow extends StatelessWidget {
  const _InlineActionRow({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final IconData trailing;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final variant =
        isDark ? GlassCardVariant.darkStrong : GlassCardVariant.lightStrong;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      variant: variant,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: SettleSemanticColors.supporting(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: SettleTypography.label.copyWith(
                color: SettleSemanticColors.supporting(context),
              ),
            ),
          ),
          Icon(
            trailing,
            size: 18,
            color: SettleSemanticColors.muted(context),
          ),
        ],
      ),
    );
  }
}

IconData _approachIcon(Approach approach) {
  return switch (approach) {
    Approach.stayAndSupport => Icons.favorite_outline,
    Approach.checkAndReassure => Icons.timer_outlined,
    Approach.cueBased => Icons.hearing_outlined,
    Approach.rhythmFirst => Icons.music_note_outlined,
    Approach.extinction => Icons.nightlight_round_outlined,
  };
}
