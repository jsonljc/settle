import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'glass_card.dart';
import 'settle_cta.dart';
import 'settle_tappable.dart';
import '../theme/settle_design_system.dart';
import 'gradient_background.dart';

class FeatureFallbackTarget {
  const FeatureFallbackTarget({required this.label, required this.route});

  final String label;
  final String route;
}

FeatureFallbackTarget pausedFallback({
  required bool preferredEnabled,
  required String preferredLabel,
  required String preferredRoute,
  String defaultLabel = 'Go to Home',
  String defaultRoute = '/now',
}) {
  if (preferredEnabled) {
    return FeatureFallbackTarget(label: preferredLabel, route: preferredRoute);
  }
  return FeatureFallbackTarget(label: defaultLabel, route: defaultRoute);
}

class FeaturePausedView extends StatelessWidget {
  const FeaturePausedView({
    super.key,
    required this.title,
    this.message = 'This section is unavailable right now.',
    this.fallbackLabel = 'Go to Home',
    this.fallbackRoute = '/now',
  });

  final String title;
  final String message;
  final String fallbackLabel;
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    SettleTappable(
                      semanticLabel: 'Back',
                      onTap: () =>
                          context.canPop() ? context.pop() : context.go('/now'),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        size: 20,
                        color: SettleSemanticColors.supporting(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: SettleTypography.heading.copyWith(
                          fontSize: 22,
                          color: SettleSemanticColors.headline(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: SettleTypography.body.copyWith(
                          color: SettleSemanticColors.supporting(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCta(
                        label: fallbackLabel,
                        onTap: () => context.go(fallbackRoute),
                      ),
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

class BehavioralScopeNotice extends StatelessWidget {
  const BehavioralScopeNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      'This app offers parenting support, not medical care.',
      style: SettleTypography.caption.copyWith(
        color: SettleSemanticColors.muted(context),
      ),
    );
  }
}

class ProfileRequiredView extends StatelessWidget {
  const ProfileRequiredView({
    super.key,
    required this.title,
    this.message = 'Add your child profile to continue.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    SettleTappable(
                      semanticLabel: 'Back',
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go('/onboard'),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        size: 20,
                        color: SettleSemanticColors.supporting(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: SettleTypography.heading.copyWith(
                          fontSize: 22,
                          color: SettleSemanticColors.headline(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: SettleTypography.body.copyWith(
                          color: SettleSemanticColors.supporting(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCta(
                        label: 'Continue setup',
                        onTap: () => context.go('/onboard'),
                      ),
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

class RouteUnavailableView extends StatelessWidget {
  const RouteUnavailableView({
    super.key,
    this.title = 'This page is unavailable',
    this.message =
        'We couldn\'t open that page. Please go to Home and try again.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    SettleTappable(
                      semanticLabel: 'Back',
                      onTap: () => context.go('/now'),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        size: 20,
                        color: SettleSemanticColors.supporting(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: SettleTypography.heading.copyWith(
                          fontSize: 22,
                          color: SettleSemanticColors.headline(context),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: SettleTypography.body.copyWith(
                          color: SettleSemanticColors.supporting(context),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCta(
                        label: 'Go to Home',
                        onTap: () => context.go('/now'),
                      ),
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
