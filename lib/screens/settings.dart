import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../internal_tools_gate.dart';
import '../models/approach.dart';
import '../models/tantrum_profile.dart';
import '../providers/disruption_provider.dart';
import '../providers/profile_provider.dart';
import '../services/focus_mode_rules.dart';
import '../theme/glass_components.dart';
import '../theme/reduce_motion.dart';
import '../theme/settle_tokens.dart';
import '../widgets/screen_header.dart';
import '../widgets/settle_disclosure.dart';

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
      body: SettleBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: T.space.screen),
                child: const ScreenHeader(title: 'Settings'),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: T.space.screen,
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
                              color: T.pal.accent.withValues(alpha: 0.15),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              (profile?.name ?? 'B')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: T.type.h2.copyWith(color: T.pal.accent),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(profile?.name ?? 'Baby', style: T.type.h3),
                                const SizedBox(height: 2),
                                Text(
                                  '${profile?.ageBracket.label ?? ''} · ${profile?.approach.label ?? ''}',
                                  style: T.type.caption.copyWith(
                                    color: T.pal.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Focus: ${profile?.focusMode.label ?? FocusMode.sleepOnly.label}',
                                  style: T.type.caption.copyWith(
                                    color: T.pal.textTertiary,
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
                        child: _FocusModeOption(
                          mode: mode,
                          isSelected: isSelected,
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
                              style: T.type.overline.copyWith(
                                color: T.pal.textTertiary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Type: ${profile!.tantrumProfile!.tantrumType.label}',
                              style: T.type.caption.copyWith(
                                color: T.pal.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Triggers: ${profile.tantrumProfile!.commonTriggers.map((t) => t.label).join(', ')}',
                              style: T.type.caption.copyWith(
                                color: T.pal.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Priority: ${profile.tantrumProfile!.responsePriority.label}',
                              style: T.type.caption.copyWith(
                                color: T.pal.textSecondary,
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
                            _ApproachOption(
                              approach: profile.approach,
                              isSelected: true,
                              onTap: () => context.push('/sleep/tonight'),
                            ),
                          const SizedBox(height: 6),
                          Text(
                            'To switch approach, use Tonight → More options → Change approach.',
                            style: T.type.caption.copyWith(
                              color: T.pal.textSecondary,
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
      style: T.type.overline.copyWith(color: T.pal.textTertiary),
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
              Text(label, style: T.type.label),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: T.type.caption.copyWith(color: T.pal.textTertiary),
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
            activeColor: T.pal.accent,
            activeTrackColor: T.pal.accent.withValues(alpha: 0.3),
            inactiveTrackColor: T.glass.fill,
            inactiveThumbColor: T.pal.textTertiary,
          ),
        ),
      ],
    );

    if (embedded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: T.glass.fill,
          borderRadius: BorderRadius.circular(T.radius.lg),
          border: Border.all(color: T.glass.border),
        ),
        child: content,
      );
    }

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: content,
    );
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: T.glass.fill,
        borderRadius: BorderRadius.circular(T.radius.lg),
        border: Border.all(color: T.glass.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: T.pal.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: T.type.label.copyWith(color: T.pal.textSecondary),
            ),
          ),
          Icon(trailing, size: 18, color: T.pal.textTertiary),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Approach Option (compact — no expanded detail)
// ─────────────────────────────────────────────

class _ApproachOption extends StatelessWidget {
  const _ApproachOption({
    required this.approach,
    required this.isSelected,
    required this.onTap,
  });

  final Approach approach;
  final bool isSelected;
  final VoidCallback onTap;

  static const _icons = {
    Approach.stayAndSupport: Icons.favorite_outline,
    Approach.checkAndReassure: Icons.timer_outlined,
    Approach.cueBased: Icons.hearing_outlined,
    Approach.rhythmFirst: Icons.music_note_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final fill = isSelected ? T.glass.fillAccent : T.glass.fill;
    final borderColor = isSelected
        ? T.pal.accent.withValues(alpha: 0.4)
        : T.glass.border;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(T.radius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: T.glass.sigma,
            sigmaY: T.glass.sigma,
          ),
          child: AnimatedContainer(
            duration: T.anim.fast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(T.radius.lg),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                Icon(
                  _icons[approach],
                  size: 20,
                  color: isSelected ? T.pal.accent : T.pal.textSecondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        approach.label,
                        style: T.type.label.copyWith(
                          color: isSelected
                              ? T.pal.textPrimary
                              : T.pal.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        approach.description,
                        style: T.type.caption.copyWith(
                          color: T.pal.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 20, color: T.pal.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusModeOption extends StatelessWidget {
  const _FocusModeOption({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final FocusMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = isSelected ? T.glass.fillAccent : T.glass.fill;
    final borderColor = isSelected
        ? T.pal.accent.withValues(alpha: 0.4)
        : T.glass.border;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(T.radius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: T.glass.sigma,
            sigmaY: T.glass.sigma,
          ),
          child: AnimatedContainer(
            duration: T.anim.fast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(T.radius.lg),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    mode.label,
                    style: T.type.label.copyWith(
                      color: isSelected
                          ? T.pal.textPrimary
                          : T.pal.textSecondary,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 20, color: T.pal.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
