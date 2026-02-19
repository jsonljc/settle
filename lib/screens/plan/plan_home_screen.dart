import 'dart:ui';

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
      return const ProfileRequiredView(title: 'Now');
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
    final headlineColor = SettleSemanticColors.headline(context);
    final supportingColor = SettleSemanticColors.supporting(context);

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
                      headlineColor: headlineColor,
                      supportingColor: supportingColor,
                    ),
                    const SettleGap.lg(),
                    _PrimaryCrisisCard(
                      onOpen: () =>
                          context.push('/sleep/tonight?scenario=night_wakes'),
                      isDark: isDark,
                    ),
                    const SettleGap.md(),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.crisis_alert_rounded,
                            title: 'Tantrum now',
                            subtitle: 'Open reset guidance',
                            eta: '~15s',
                            onTap: () =>
                                context.push('/plan/reset?context=tantrum'),
                          ),
                        ),
                        const SettleGap.sm(),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.self_improvement_rounded,
                            title: 'I need to regulate',
                            subtitle: 'Open moment guidance',
                            eta: '~10s',
                            onTap: () =>
                                context.push('/plan/moment?context=general'),
                          ),
                        ),
                      ],
                    ),
                    const SettleGap.md(),
                    Center(
                      child: SettleTappable(
                        semanticLabel:
                            'Need bedtime or early wake? Open Sleep Tonight',
                        onTap: () => context.push('/sleep/tonight'),
                        child: Text(
                          'Need bedtime or early wake? Open Sleep Tonight',
                          style: SettleTypography.caption.copyWith(
                            color: supportingColor,
                            decoration: TextDecoration.underline,
                            decorationColor: supportingColor,
                          ),
                        ),
                      ),
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

}

class _GreetingCluster extends StatelessWidget {
  const _GreetingCluster({
    required this.greeting,
    required this.headlineColor,
    required this.supportingColor,
  });

  final String greeting;
  final Color headlineColor;
  final Color supportingColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? SettleGlassDark.backgroundStrong
                : Colors.white.withValues(alpha: 0.34),
            borderRadius: BorderRadius.circular(SettleRadii.pill),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : SettleColors.ink700.withValues(alpha: 0.18),
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: SettleSpacing.md,
            vertical: SettleSpacing.xs,
          ),
          child: Text(
            'Now',
            style: SettleTypography.caption.copyWith(
              color: isDark ? SettleColors.nightSoft : SettleColors.ink700,
            ),
          ),
        ),
        const SettleGap.sm(),
        Text(
          greeting,
          style: SettleTypography.display.copyWith(color: headlineColor),
        ),
        const SettleGap.xs(),
        Text(
          'Choose what is happening right now.',
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
      child: ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                tint.withValues(alpha: 0.28),
                tint.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Dominant primary action for Now: start Night Wake guidance in one tap.
class _PrimaryCrisisCard extends StatelessWidget {
  const _PrimaryCrisisCard({
    required this.onOpen,
    required this.isDark,
  });

  final VoidCallback onOpen;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final headlineColor = SettleSemanticColors.headline(context);
    final supportingColor = SettleSemanticColors.supporting(context);

    return GlassCard(
      variant: isDark ? GlassCardVariant.darkStrong : GlassCardVariant.lightStrong,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRIMARY',
            style: SettleTypography.overline.copyWith(
              color: SettleSemanticColors.muted(context),
            ),
          ),
          const SettleGap.sm(),
          Text(
            'Night wake right now',
            style: SettleTypography.heading.copyWith(color: headlineColor),
          ),
          const SettleGap.xs(),
          Text(
            'Get one immediate step for a middle-of-the-night wake.',
            style: SettleTypography.body.copyWith(color: supportingColor),
          ),
          const SettleGap.md(),
          GlassPill(
            label: 'Open Night Wake',
            onTap: onOpen,
            variant: isDark
                ? GlassPillVariant.primaryDark
                : GlassPillVariant.primaryLight,
            expanded: true,
          ),
        ],
      ),
    );
  }
}

/// Quick action: icon, title, subtitle in a GlassCard. Brightness-aware.
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.eta,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String eta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = SettleSemanticColors.supporting(context);
    final titleColor = SettleSemanticColors.headline(context);
    final subtitleColor = SettleSemanticColors.supporting(context);
    final mutedColor = SettleSemanticColors.muted(context);

    return SettleTappable(
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      child: GlassCard(
        variant: isDark
            ? GlassCardVariant.darkStrong
            : GlassCardVariant.lightStrong,
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
                  color: mutedColor,
                ),
              ],
            ),
            const SettleGap.sm(),
            Text(
              title,
              style: SettleTypography.label.copyWith(color: titleColor),
            ),
            const SettleGap.xs(),
            Text(
              subtitle,
              style: SettleTypography.caption.copyWith(color: subtitleColor),
            ),
            const SettleGap.xs(),
            Text(
              eta,
              style: SettleTypography.caption.copyWith(color: mutedColor),
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
