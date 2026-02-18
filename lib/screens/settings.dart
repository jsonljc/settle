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
import '../theme/glass_components.dart';
import '../theme/settle_design_system.dart';
import '../widgets/gradient_background.dart';
import '../theme/reduce_motion.dart';
import '../widgets/screen_header.dart';
import '../widgets/option_button.dart';
import '../widgets/settle_chip.dart';
import '../widgets/settle_disclosure.dart';

class _StgT {
  _StgT._();

  static final type = _StgTypeTokens();
  static const pal = _StgPaletteTokens();
  static const glass = _StgGlassTokens();
}

class _StgTypeTokens {
  TextStyle get h2 => SettleTypography.heading.copyWith(fontSize: 22);
  TextStyle get h3 => SettleTypography.heading;
  TextStyle get label =>
      SettleTypography.body.copyWith(fontWeight: FontWeight.w600);
  TextStyle get caption => SettleTypography.caption;
  TextStyle get overline => SettleTypography.caption.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
}

class _StgPaletteTokens {
  const _StgPaletteTokens();

  Color get accent => SettleColors.nightAccent;
  Color get textSecondary => SettleColors.nightSoft;
  Color get textTertiary => SettleColors.nightMuted;
}

class _StgGlassTokens {
  const _StgGlassTokens();

  Color get fill => SettleGlassDark.backgroundStrong;
  Color get fillAccent => SettleColors.dusk600.withValues(alpha: 0.16);
}

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
              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: SettleSpacing.screenPadding,
                  ).copyWith(bottom: 32),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    // ── Profile card ──
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Avatar circle
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _StgT.pal.accent.withValues(alpha: 0.15),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (profile?.name ?? 'B')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: _StgT.type.h2.copyWith(
                                color: _StgT.pal.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile?.name ?? 'Baby',
                                  style: _StgT.type.h3,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${profile?.ageBracket.label ?? ''} · ${profile?.approach.label ?? ''}',
                                  style: _StgT.type.caption.copyWith(
                                    color: _StgT.pal.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Focus: ${profile?.focusMode.label ?? FocusMode.sleepOnly.label}',
                                  style: _StgT.type.caption.copyWith(
                                    color: _StgT.pal.textTertiary,
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
                    const SizedBox(height: 20),

                    _SectionHeader(title: 'Feature focus'),
                    const SizedBox(height: 10),
                    ...allowedModes.map((mode) {
                      final isSelected =
                          (profile?.focusMode ?? FocusMode.sleepOnly) == mode;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
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
                      const SizedBox(height: 8),
                      GlassCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tantrum profile',
                              style: _StgT.type.overline.copyWith(
                                color: _StgT.pal.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Type: ${profile!.tantrumProfile!.tantrumType.label}',
                              style: _StgT.type.caption.copyWith(
                                color: _StgT.pal.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Triggers: ${profile.tantrumProfile!.commonTriggers.map((t) => t.label).join(', ')}',
                              style: _StgT.type.caption.copyWith(
                                color: _StgT.pal.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Priority: ${profile.tantrumProfile!.responsePriority.label}',
                              style: _StgT.type.caption.copyWith(
                                color: _StgT.pal.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    _SectionHeader(title: 'Recommended'),
                    const SizedBox(height: 10),
                    _ToggleCard(
                      label: 'Wake window nudges',
                      value: _wakeNudges,
                      onChanged: (v) => setState(() => _wakeNudges = v),
                    ),
                    const SizedBox(height: 8),
                    _ToggleCard(
                      label: 'Wellbeing check-ins',
                      value: _wellbeingCheckins,
                      onChanged: (v) => setState(() => _wellbeingCheckins = v),
                    ),
                    const SizedBox(height: 8),
                    _ToggleCard(
                      label: 'Disruption mode',
                      subtitle:
                          'Travel, illness, teething — expands windows, softens guidance',
                      value: disruptionMode,
                      onChanged: (v) =>
                          ref.read(disruptionProvider.notifier).set(v),
                    ),
                    const SizedBox(height: 20),
                    _SectionHeader(title: 'Plan nudges'),
                    const SizedBox(height: 10),
                    _NudgeSettingsSection(),
                    const SizedBox(height: 20),
                    _SectionHeader(title: 'Shared Scripts'),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () => context.push('/rules'),
                      child: const _InlineActionRow(
                        icon: Icons.people_outline_rounded,
                        title: 'Keep caregivers on the same page',
                        trailing: Icons.chevron_right_rounded,
                      ),
                    ),
                    const SizedBox(height: 20),
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: SettleDisclosure(
                        title: 'More settings',
                        subtitle:
                            'Accessibility, sharing, and advanced preferences.',
                        children: [
                          const SizedBox(height: 8),
                          _SectionHeader(title: 'Alerts'),
                          const SizedBox(height: 8),
                          _ToggleCard(
                            label: 'Auto nighttime support',
                            value: _autoNight,
                            embedded: true,
                            onChanged: (v) => setState(() => _autoNight = v),
                          ),
                          const SizedBox(height: 12),
                          _SectionHeader(title: 'Accessibility'),
                          const SizedBox(height: 8),
                          _ToggleCard(
                            label: 'Simplified mode',
                            value: _simplifiedMode,
                            embedded: true,
                            onChanged: (v) =>
                                setState(() => _simplifiedMode = v),
                          ),
                          const SizedBox(height: 8),
                          _ToggleCard(
                            label: 'One-handed mode',
                            value: _oneHanded,
                            embedded: true,
                            onChanged: (v) => setState(() => _oneHanded = v),
                          ),
                          const SizedBox(height: 8),
                          _ToggleCard(
                            label: 'Grief-aware language',
                            value: _griefAware,
                            embedded: true,
                            onChanged: (v) => setState(() => _griefAware = v),
                          ),
                          const SizedBox(height: 12),
                          _SectionHeader(title: 'Sleep details'),
                          const SizedBox(height: 8),
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
                          const SizedBox(height: 8),
                          _ToggleCard(
                            label: 'Partner sync',
                            value: _partnerSync,
                            embedded: true,
                            onChanged: (v) => setState(() => _partnerSync = v),
                          ),
                          const SizedBox(height: 8),
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
                          const SizedBox(height: 8),
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
                            style: _StgT.type.caption.copyWith(
                              color: _StgT.pal.textSecondary,
                            ),
                          ),
                          if (showInternalTools) ...[
                            const SizedBox(height: 12),
                            _SectionHeader(title: 'Internal tools'),
                            const SizedBox(height: 8),
                            GestureDetector(
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
                          const SizedBox(height: 8),
                          GestureDetector(
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
      style: _StgT.type.overline.copyWith(color: _StgT.pal.textTertiary),
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
    final content = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: _StgT.type.label),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: _StgT.type.caption.copyWith(
                    color: _StgT.pal.textTertiary,
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
            activeColor: _StgT.pal.accent,
            activeTrackColor: _StgT.pal.accent.withValues(alpha: 0.3),
            inactiveTrackColor: _StgT.glass.fill,
            inactiveThumbColor: _StgT.pal.textTertiary,
          ),
        ),
      ],
    );

    if (embedded) {
      return GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        fill: _StgT.glass.fill,
        child: content,
      );
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gentle reminders for scripts and patterns. Quiet hours: no nudges.',
            style: _StgT.type.caption.copyWith(color: _StgT.pal.textSecondary),
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
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
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
          const SizedBox(height: 8),
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
            style: _StgT.type.caption.copyWith(color: _StgT.pal.textTertiary),
          ),
          const SizedBox(height: 8),
          Text(
            'Frequency: ${_frequencyLabel(settings.frequency)}',
            style: _StgT.type.caption.copyWith(color: _StgT.pal.textTertiary),
          ),
          const SizedBox(height: 10),
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
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      fill: _StgT.glass.fill,
      child: Row(
        children: [
          Icon(icon, size: 18, color: _StgT.pal.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: _StgT.type.label.copyWith(color: _StgT.pal.textSecondary),
            ),
          ),
          Icon(trailing, size: 18, color: _StgT.pal.textTertiary),
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
