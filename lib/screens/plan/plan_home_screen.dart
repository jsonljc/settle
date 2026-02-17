import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/approach.dart';
import '../../providers/nudge_settings_provider.dart';
import '../../providers/plan_ordering_provider.dart';
import '../../providers/patterns_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/nudge_scheduler.dart';
import '../../providers/user_cards_provider.dart';
import '../../services/card_content_service.dart';
import '../../theme/glass_components.dart' hide GlassCard, GlassPill;
import '../../theme/settle_tokens.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_pill.dart';
import '../../widgets/output_card.dart';
import '../../widgets/settle_tappable.dart';
import '../../widgets/release_surfaces.dart';
import '../../widgets/screen_header.dart';

class PlanHomeScreen extends ConsumerStatefulWidget {
  const PlanHomeScreen({super.key});

  @override
  ConsumerState<PlanHomeScreen> createState() => _PlanHomeScreenState();
}

class _PlanHomeScreenState extends ConsumerState<PlanHomeScreen> {
  String? _selectedTrigger;
  CardContent? _selectedCard;
  bool _loading = false;
  bool _nudgeScheduled = false;

  Future<void> _selectTrigger(String trigger) async {
    setState(() {
      _selectedTrigger = trigger;
      _loading = true;
    });
    final card = await CardContentService.instance.selectBestCard(
      triggerType: trigger,
    );
    if (!mounted) return;
    setState(() {
      _selectedCard = card;
      _loading = false;
    });
  }

  Future<void> _saveCard(CardContent card) async {
    await ref.read(userCardsProvider.notifier).save(card.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved to playbook'),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  Future<void> _showEvidence(CardContent card) async {
    final evidence =
        card.evidence ?? 'This script follows co-regulation first.';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              T.space.screen,
              T.space.md,
              T.space.screen,
              T.space.screen,
            ),
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Why this works', style: T.type.h3),
                  const SizedBox(height: 8),
                  Text(
                    evidence,
                    style: T.type.body.copyWith(color: T.pal.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _copyScript(BuildContext context, CardContent card) {
    final buffer = StringBuffer();
    buffer.writeln('Prevent: ${card.prevent}');
    buffer.writeln('Say: ${card.say}');
    buffer.writeln('Do: ${card.doStep}');
    if (card.ifEscalates != null && card.ifEscalates!.isNotEmpty) {
      buffer.writeln('If it escalates: ${card.ifEscalates}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Script copied to clipboard'),
          duration: Duration(milliseconds: 800),
        ),
      );
    }
  }

  bool _needsRegulateFirst(RegulationLevel? level) {
    return level == RegulationLevel.stressed ||
        level == RegulationLevel.anxious ||
        level == RegulationLevel.angry;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    if (profile == null) {
      return const ProfileRequiredView(title: 'Plan');
    }

    if (!_nudgeScheduled) {
      _nudgeScheduled = true;
      Future.microtask(() async {
        await NudgeScheduler.scheduleNudges(
          profile: ref.read(profileProvider),
          patterns: ref.read(patternsProvider),
          settings: ref.read(nudgeSettingsProvider),
        );
      });
    }

    ref.watch(patternEngineRefreshProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Greeting (no glass)
              Text(
                _greetingText(context),
                style: GoogleFonts.fraunces(
                  fontSize: 28,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.5,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? SettleColors.nightText
                      : SettleColors.ink900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'What do you need right now?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: SettleColors.ink400,
                ),
              ),
              const SizedBox(height: SettleSpacing.xl), // 20px to hero

              // 2. Sleep Tonight hero card (GlassCard lightStrong)
              _SleepTonightHeroCard(onOpen: () => context.push('/sleep/tonight')),

              const SizedBox(height: 10), // 10px hero to quick row

              // 3. Quick actions row (two GlassCard light, 8px gap)
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.mood_rounded,
                      iconColor: SettleColors.sage600,
                      title: 'Reset',
                      subtitle: '~15s',
                      onTap: () => context.push('/plan/reset?context=general'),
                    ),
                  ),
                  const SizedBox(width: SettleSpacing.sm), // 8px gap
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.gps_fixed_rounded,
                      iconColor: SettleColors.dusk600,
                      title: 'Moment',
                      subtitle: '~10s',
                      onTap: () => context.push('/plan/moment?context=general'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10), // 10px quick row to nav
            ],
          ),
        ),
      ),
    );
  }

  /// Morning 5am–12pm, afternoon 12–5pm, evening 5–9pm, late night 9pm–5am.
  /// Late night uses dark-mode greeting if system is dark.
  String _greetingText(BuildContext context) {
    final hour = DateTime.now().hour;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return isDark ? 'Late night' : 'Good evening';
  }
}

/// Sleep Tonight hero: glass card with dusk icon circle, eyebrow, title, desc, CTA.
class _SleepTonightHeroCard extends StatelessWidget {
  const _SleepTonightHeroCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      variant: GlassCardVariant.lightStrong,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Glass circle icon top-right: 48px, dusk tint 8%, moon 22px
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SettleColors.dusk400.withValues(alpha: 0.08),
              ),
              child: Icon(
                Icons.nightlight_round,
                size: 22,
                color: SettleColors.dusk600,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Eyebrow: SLEEP TONIGHT
              Text(
                'SLEEP TONIGHT',
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                  color: SettleColors.dusk600.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 6),
              // Title: Ready when you need it
              Text(
                'Ready when you need it',
                style: GoogleFonts.fraunces(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: SettleColors.ink900,
                ),
              ),
              const SizedBox(height: 4),
              // Desc
              Text(
                '3 short guides for whatever tonight brings.',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: SettleColors.ink400,
                ),
              ),
              const SizedBox(height: 14),
              GlassPill(
                label: 'Open',
                onTap: onOpen,
                variant: GlassPillVariant.primaryLight,
                expanded: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Quick action: icon, title, subtitle in a light GlassCard. Padding 16 vertical, 10 horizontal.
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SettleTappable(
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      child: GlassCard(
        variant: GlassCardVariant.light,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 24, color: iconColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SettleColors.ink900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w400,
                color: SettleColors.ink400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PlanCardScreen extends StatelessWidget {
  const PlanCardScreen({
    super.key,
    required this.cardId,
    this.fallbackRoute = '/plan',
  });

  final String cardId;
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CardContent?>(
      future: CardContentService.instance.getCardById(cardId),
      builder: (context, snapshot) {
        final card = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (card == null) {
          return const RouteUnavailableView(
            title: 'Card not found',
            message: 'This script is no longer available.',
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: T.space.screen),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScreenHeader(title: 'Script', fallbackRoute: fallbackRoute),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: OutputCard(
                          scenarioLabel: card.triggerType,
                          prevent: card.prevent,
                          say: card.say,
                          doStep: card.doStep,
                          ifEscalates: card.ifEscalates,
                          primaryLabel: 'Done',
                          onPrimary: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(fallbackRoute);
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        );
      },
    );
  }
}
