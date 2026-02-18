import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/nudge_settings_provider.dart';
import '../../providers/plan_ordering_provider.dart';
import '../../providers/patterns_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/nudge_scheduler.dart';
import '../../services/card_content_service.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/calm_loading.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_pill.dart';
import '../../widgets/output_card.dart';
import '../../widgets/settle_tappable.dart';
import '../../widgets/release_surfaces.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/settle_gap.dart';

class PlanHomeScreen extends ConsumerStatefulWidget {
  const PlanHomeScreen({super.key});

  @override
  ConsumerState<PlanHomeScreen> createState() => _PlanHomeScreenState();
}

class _PlanHomeScreenState extends ConsumerState<PlanHomeScreen> {
  bool _nudgeScheduled = false;

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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headlineColor = isDark ? SettleColors.nightText : SettleColors.ink900;
    final supportingColor = isDark
        ? SettleColors.nightSoft
        : SettleColors.ink500;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(
              top: -80,
              right: -30,
              child: _AmbientOrb(
                tint: SettleColors.dusk400,
                size: SettleSpacing.xxl * 8,
              ),
            ),
            const Positioned(
              bottom: 40,
              left: -70,
              child: _AmbientOrb(
                tint: SettleColors.sage400,
                size: SettleSpacing.xxl * 7,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SettleSpacing.screenPadding,
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SettleGap.lg(),
                    _GreetingCluster(
                      greeting: _greetingText(context),
                      isNight: _isNighttime(),
                      headlineColor: headlineColor,
                      supportingColor: supportingColor,
                    ),
                    const SettleGap.xl(),
                    _SleepTonightHeroCard(
                      onOpen: () => context.push('/sleep/tonight'),
                      headlineColor: headlineColor,
                      supportingColor: supportingColor,
                    ),
                    const SettleGap.lg(),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.mood_rounded,
                            iconColor: SettleColors.ink500,
                            title: 'Reset',
                            subtitle: 'Calm body cues',
                            eta: '~15s',
                            onTap: () =>
                                context.push('/plan/reset?context=general'),
                          ),
                        ),
                        const SettleGap.sm(),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.gps_fixed_rounded,
                            iconColor: SettleColors.ink500,
                            title: 'Moment',
                            subtitle: 'One script now',
                            eta: '~10s',
                            onTap: () =>
                                context.push('/plan/moment?context=general'),
                          ),
                        ),
                      ],
                    ),
                    const SettleGap.lg(),
                    _RhythmBridgeCard(
                      supportingColor: supportingColor,
                      onOpenSleep: () => context.go('/sleep'),
                      onOpenLibrary: () => context.go('/library/logs'),
                    ),
                    const SettleGap.xxl(),
                  ],
                ),
              ),
            ),
          ],
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

  bool _isNighttime() {
    final hour = DateTime.now().hour;
    return hour >= 21 || hour < 5;
  }
}

class _GreetingCluster extends StatelessWidget {
  const _GreetingCluster({
    required this.greeting,
    required this.isNight,
    required this.headlineColor,
    required this.supportingColor,
  });

  final String greeting;
  final bool isNight;
  final Color headlineColor;
  final Color supportingColor;

  @override
  Widget build(BuildContext context) {
    final chipTint = isNight ? SettleColors.ink500 : SettleColors.ink700;
    final chipLabel = isNight ? 'Night support' : 'Day rhythm';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(SettleRadii.pill),
            border: Border.all(color: chipTint.withValues(alpha: 0.18)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: SettleSpacing.md,
            vertical: SettleSpacing.xs,
          ),
          child: Text(
            chipLabel,
            style: SettleTypography.caption.copyWith(color: chipTint),
          ),
        ),
        const SettleGap.sm(),
        Text(
          greeting,
          style: SettleTypography.display.copyWith(color: headlineColor),
        ),
        const SettleGap.xs(),
        Text(
          'Pick one next step. We’ll keep it simple.',
          style: SettleTypography.body.copyWith(color: supportingColor),
        ),
      ],
    );
  }
}

class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.tint, required this.size});

  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [tint.withValues(alpha: 0.28), tint.withValues(alpha: 0.0)],
          ),
        ),
      ),
    );
  }
}

/// Sleep Tonight hero: glass card with dusk icon circle, eyebrow, title, desc, CTA.
class _SleepTonightHeroCard extends StatelessWidget {
  const _SleepTonightHeroCard({
    required this.onOpen,
    required this.headlineColor,
    required this.supportingColor,
  });

  final VoidCallback onOpen;
  final Color headlineColor;
  final Color supportingColor;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      variant: GlassCardVariant.lightStrong,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: SettleSpacing.xs,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(SettleRadii.card),
                color: SettleColors.ink500.withValues(alpha: 0.14),
              ),
            ),
          ),
          Positioned(
            top: SettleSpacing.sm,
            right: 0,
            child: Container(
              width: SettleSpacing.xxl * 2,
              height: SettleSpacing.xxl * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.46),
              ),
              child: Icon(
                Icons.nightlight_round,
                size: SettleSpacing.lg + SettleSpacing.sm,
                color: SettleColors.ink700,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SettleGap.sm(),
              Text(
                'SLEEP TONIGHT',
                style: SettleTypography.caption.copyWith(
                  letterSpacing: 0.7,
                  color: SettleColors.ink500,
                ),
              ),
              const SettleGap.sm(),
              Text(
                'Open Sleep Tonight',
                style: SettleTypography.heading.copyWith(color: headlineColor),
              ),
              const SettleGap.xs(),
              Text(
                'Night wake, bedtime protest, or early wake.\nOne clear step at a time.',
                style: SettleTypography.body.copyWith(color: supportingColor),
              ),
              const SettleGap.md(),
              Wrap(
                spacing: SettleSpacing.sm,
                runSpacing: SettleSpacing.sm,
                children: const [
                  _HeroTag(label: 'No setup'),
                  _HeroTag(label: 'Fast entry'),
                  _HeroTag(label: 'Guided beats'),
                ],
              ),
              const SettleGap.md(),
              GlassPill(
                label: 'Open Sleep Tonight',
                onTap: onOpen,
                variant: GlassPillVariant.secondaryLight,
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
    required this.eta,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String eta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SettleTappable(
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      child: GlassCard(
        variant: GlassCardVariant.lightStrong,
        padding: const EdgeInsets.symmetric(
          vertical: SettleSpacing.lg,
          horizontal: SettleSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: SettleSpacing.xl + SettleSpacing.lg,
                  height: SettleSpacing.xl + SettleSpacing.lg,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor.withValues(alpha: 0.14),
                  ),
                  child: Icon(icon, size: SettleSpacing.lg, color: iconColor),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: SettleSpacing.lg,
                  color: SettleColors.ink400,
                ),
              ],
            ),
            const SettleGap.sm(),
            Text(
              title,
              style: SettleTypography.body.copyWith(
                fontWeight: FontWeight.w700,
                color: SettleColors.ink900,
              ),
            ),
            const SettleGap.xs(),
            Text(
              subtitle,
              style: SettleTypography.caption.copyWith(
                color: SettleColors.ink500,
              ),
            ),
            const SettleGap.xs(),
            Text(
              eta,
              style: SettleTypography.caption.copyWith(
                color: SettleColors.ink400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: SettleColors.stone100.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(SettleRadii.pill),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: SettleSpacing.md,
        vertical: SettleSpacing.xs,
      ),
      child: Text(
        label,
        style: SettleTypography.caption.copyWith(
          color: SettleColors.ink500,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RhythmBridgeCard extends StatelessWidget {
  const _RhythmBridgeCard({
    required this.supportingColor,
    required this.onOpenSleep,
    required this.onOpenLibrary,
  });

  final Color supportingColor;
  final VoidCallback onOpenSleep;
  final VoidCallback onOpenLibrary;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      variant: GlassCardVariant.lightStrong,
      padding: const EdgeInsets.symmetric(
        horizontal: SettleSpacing.lg,
        vertical: SettleSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keep today visible',
            style: SettleTypography.body.copyWith(
              color: SettleColors.ink900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SettleGap.xs(),
          Text(
            'Sleep holds your rhythm plan. Library keeps your logs.',
            style: SettleTypography.caption.copyWith(color: supportingColor),
          ),
          const SettleGap.md(),
          Wrap(
            spacing: SettleSpacing.sm,
            runSpacing: SettleSpacing.sm,
            children: [
              GlassPill(
                label: 'Open Sleep tab',
                onTap: onOpenSleep,
                variant: GlassPillVariant.secondaryLight,
              ),
              GlassPill(
                label: 'Open logs',
                onTap: onOpenLibrary,
                variant: GlassPillVariant.secondaryLight,
              ),
            ],
          ),
        ],
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
            body: Center(
              child: CalmLoading(message: 'Finding the right approach…'),
            ),
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
              padding: EdgeInsets.symmetric(
                horizontal: SettleSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ScreenHeader(title: 'Script', fallbackRoute: fallbackRoute),
                  const SettleGap.sm(),
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
