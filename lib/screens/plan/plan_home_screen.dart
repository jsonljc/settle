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
import '../../widgets/solid_card.dart';
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

    final hero = _heroTileForContext();
    final secondary = _secondaryTiles();

    return Scaffold(
      body: SafeArea(
        child: Padding(
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
                  subtitle: 'I need help right now.',
                  fallbackRoute: '/plan',
                  showBackButton: false,
                ),
                const SettleGap.xl(),
                // V2: one hero tile (context-aware), full width
                _NowHeroCard(
                  title: hero.title,
                  subtitle: hero.subtitle,
                  onTap: () => context.push(hero.route),
                ),
                const SettleGap.lg(),
                // V2: two secondary tiles, half-width each
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _NowSecondaryCard(
                        title: secondary.left.title,
                        onTap: () =>
                            context.push(secondary.left.route),
                      ),
                    ),
                    const SettleGap.md(),
                    Expanded(
                      child: _NowSecondaryCard(
                        title: secondary.right.title,
                        onTap: () =>
                            context.push(secondary.right.route),
                      ),
                    ),
                  ],
                ),
                const SettleGap.xxl(),
                // V2: "I just need words" — fast path to two-script view
                Center(
                  child: SettleTappable(
                    semanticLabel: 'I just need words',
                    onTap: () => context.push('/plan/moment?fast_path=1'),
                    child: Text(
                      'I just need words',
                      style: SettleTypography.caption.copyWith(
                        color: SettleSemanticColors.supporting(context),
                        decoration: TextDecoration.underline,
                        decorationColor:
                            SettleSemanticColors.supporting(context),
                      ),
                    ),
                  ),
                ),
                const SettleGap.xxl(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// V2: context-aware hero. Default "I lost my cool"; night → "Bedtime isn't working"; etc.
  ({String title, String subtitle, String route}) _heroTileForContext() {
    final isNight = _isNightContext();
    if (isNight) {
      return (
        title: 'Bedtime isn\'t working',
        subtitle: 'Get one immediate step for tonight.',
        route: '/sleep/tonight?scenario=night_wakes',
      );
    }
    return (
      title: 'I lost my cool',
      subtitle: 'Get the words to say right now.',
      route: '/plan/reset',
    );
  }

  /// V2: secondary tiles — "Meltdown just happened" and "I need to calm down".
  ({_NowSecondaryTile left, _NowSecondaryTile right}) _secondaryTiles() {
    return (
      left: const _NowSecondaryTile(
        title: 'Meltdown just happened',
        route: '/plan/reset?context=tantrum',
      ),
      right: const _NowSecondaryTile(
        title: 'I need to calm down',
        route: '/plan/moment?context=general',
      ),
    );
  }

  bool _isNightContext() {
    final hour = DateTime.now().hour;
    return hour >= 20 || hour < 6;
  }
}

/// V2: Hero tile — largest, full-width, single primary action.
class _NowHeroCard extends StatelessWidget {
  const _NowHeroCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final headlineColor = SettleSemanticColors.headline(context);
    final supportingColor = SettleSemanticColors.supporting(context);

    return SolidCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(
        SettleSpacing.cardPadding,
        SettleSpacing.xxl,
        SettleSpacing.cardPadding,
        SettleSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: SettleTypography.heading.copyWith(color: headlineColor),
          ),
          const SettleGap.sm(),
          Text(
            subtitle,
            style: SettleTypography.body.copyWith(color: supportingColor),
          ),
        ],
      ),
    );
  }
}

class _NowSecondaryTile {
  const _NowSecondaryTile({
    required this.title,
    required this.route,
  });

  final String title;
  final String route;
}

/// V2: Secondary tile — half-width, label only, calm.
class _NowSecondaryCard extends StatelessWidget {
  const _NowSecondaryCard({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final headlineColor = SettleSemanticColors.headline(context);

    return Semantics(
      button: true,
      label: title,
      child: SolidCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(
          vertical: SettleSpacing.lg,
          horizontal: SettleSpacing.md,
        ),
        child: Text(
          title,
          style: SettleTypography.subheading.copyWith(color: headlineColor),
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
