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

    final isNightContext = _isNightContext();
    final primaryAction = isNightContext
        ? const _NowAction(
            icon: Icons.nightlight_round,
            title: 'Night wake right now',
            subtitle: 'Get one immediate sleep step.',
            eta: '~10s',
            route: '/sleep/tonight?scenario=night_wakes',
          )
        : const _NowAction(
            icon: Icons.crisis_alert_rounded,
            title: 'Tantrum happening now',
            subtitle: 'Open reset guidance with the first line to use.',
            eta: '~10s',
            route: '/plan/reset?context=tantrum',
          );
    final secondaryActions = isNightContext
        ? const [
            _NowAction(
              icon: Icons.bedtime_rounded,
              title: 'Bedtime protest',
              subtitle: "Won't settle at bedtime",
              eta: '~15s',
              route: '/sleep/tonight?scenario=bedtime_protest',
            ),
            _NowAction(
              icon: Icons.self_improvement_rounded,
              title: 'I need to regulate',
              subtitle: 'Start a short reset before re-engaging',
              eta: '~10s',
              route: '/plan/moment?context=general',
            ),
          ]
        : const [
            _NowAction(
              icon: Icons.nightlight_round,
              title: 'Night wake',
              subtitle: 'Open sleep guidance for tonight',
              eta: '~15s',
              route: '/sleep/tonight?scenario=night_wakes',
            ),
            _NowAction(
              icon: Icons.self_improvement_rounded,
              title: 'I need to regulate',
              subtitle: 'Start a short reset before re-engaging',
              eta: '~10s',
              route: '/plan/moment?context=general',
            ),
          ];

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
                    const ScreenHeader(
                      title: 'Now',
                      subtitle: 'Choose what is happening right now.',
                      fallbackRoute: '/plan',
                      showBackButton: false,
                    ),
                    if (isNightContext) ...[
                      const SettleGap.sm(),
                      _NowContextHint(
                        icon: Icons.nightlight_round,
                        text: 'Nighttime handoff active: sleep options first.',
                      ),
                    ],
                    const SettleGap.lg(),
                    const _NowSectionHeader(label: 'START HERE'),
                    const SettleGap.sm(),
                    _NowPrimaryCard(
                      action: primaryAction,
                      onTap: () => context.push(primaryAction.route),
                    ),
                    const SettleGap.md(),
                    const _NowSectionHeader(label: 'OTHER FAST PATHS'),
                    const SettleGap.sm(),
                    ...secondaryActions.map(
                      (action) => Padding(
                        padding: const EdgeInsets.only(
                          bottom: SettleSpacing.sm,
                        ),
                        child: _NowActionCard(
                          action: action,
                          onTap: () => context.push(action.route),
                        ),
                      ),
                    ),
                    const SettleGap.sm(),
                    Center(
                      child: SettleTappable(
                        semanticLabel: 'Open Sleep Tonight',
                        onTap: () => context.push('/sleep/tonight'),
                        child: Text(
                          'Need bedtime or early wake? Open Sleep Tonight',
                          style: SettleTypography.caption.copyWith(
                            color: SettleSemanticColors.supporting(context),
                            decoration: TextDecoration.underline,
                            decorationColor: SettleSemanticColors.supporting(
                              context,
                            ),
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

  bool _isNightContext() {
    final hour = DateTime.now().hour;
    return hour >= 20 || hour < 6;
  }
}

class _NowSectionHeader extends StatelessWidget {
  const _NowSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: SettleSpacing.xs),
      child: Text(
        label,
        style: SettleTypography.overline.copyWith(
          color: SettleSemanticColors.muted(context),
        ),
      ),
    );
  }
}

class _NowContextHint extends StatelessWidget {
  const _NowContextHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final accent = SettleSemanticColors.accent(context);
    final supporting = SettleSemanticColors.supporting(context);

    return GlassCard(
      variant: Theme.of(context).brightness == Brightness.dark
          ? GlassCardVariant.dark
          : GlassCardVariant.light,
      padding: const EdgeInsets.symmetric(
        horizontal: SettleSpacing.md,
        vertical: SettleSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: SettleSpacing.md, color: accent),
          const SettleGap.sm(),
          Expanded(
            child: Text(
              text,
              style: SettleTypography.caption.copyWith(color: supporting),
            ),
          ),
        ],
      ),
    );
  }
}

class _NowAction {
  const _NowAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.eta,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String eta;
  final String route;
}

class _NowPrimaryCard extends StatelessWidget {
  const _NowPrimaryCard({required this.action, required this.onTap});

  final _NowAction action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headlineColor = SettleSemanticColors.headline(context);
    final supportingColor = SettleSemanticColors.supporting(context);

    return GlassCard(
      variant: isDark
          ? GlassCardVariant.darkStrong
          : GlassCardVariant.lightStrong,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SettleSemanticColors.accent(
                context,
              ).withValues(alpha: 0.16),
            ),
            child: Icon(
              action.icon,
              color: SettleSemanticColors.accent(context),
            ),
          ),
          const SettleGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Start here',
                  style: SettleTypography.overline.copyWith(
                    color: SettleSemanticColors.muted(context),
                  ),
                ),
                const SettleGap.xs(),
                Text(
                  action.title,
                  style: SettleTypography.heading.copyWith(
                    color: headlineColor,
                  ),
                ),
                const SettleGap.xs(),
                Text(
                  action.subtitle,
                  style: SettleTypography.body.copyWith(color: supportingColor),
                ),
                const SettleGap.sm(),
                Text(
                  action.eta,
                  style: SettleTypography.caption.copyWith(
                    color: SettleSemanticColors.muted(context),
                  ),
                ),
              ],
            ),
          ),
          const SettleGap.sm(),
          Icon(
            Icons.arrow_forward_rounded,
            size: SettleSpacing.lg,
            color: SettleSemanticColors.muted(context),
          ),
        ],
      ),
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

/// Secondary crisis action rows.
class _NowActionCard extends StatelessWidget {
  const _NowActionCard({required this.action, required this.onTap});

  final _NowAction action;
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
      semanticLabel: '${action.title}. ${action.subtitle}',
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
                  child: Icon(
                    action.icon,
                    size: SettleSpacing.lg,
                    color: iconColor,
                  ),
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
              action.title,
              style: SettleTypography.label.copyWith(color: titleColor),
            ),
            const SettleGap.xs(),
            Text(
              action.subtitle,
              style: SettleTypography.caption.copyWith(color: subtitleColor),
            ),
            const SettleGap.xs(),
            Text(
              action.eta,
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
