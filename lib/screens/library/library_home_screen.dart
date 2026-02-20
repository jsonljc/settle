import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/settle_design_system.dart';
import '../../widgets/solid_card.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/settle_gap.dart';
import '../../widgets/settle_tappable.dart';

class LibraryHomeScreen extends StatelessWidget {
  const LibraryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SettleSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(
                title: 'Library',
                subtitle: 'Show me what\'s working. Help me make it better.',
                fallbackRoute: '/library',
                showBackButton: false,
              ),
              const SettleGap.xxl(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionHeader(label: 'This week\'s focus'),
                      const SettleGap.md(),
                      _FocusCard(
                        title: 'One thing to try',
                        description:
                            'Same words at lights-out, every night. Repetition builds the cue.',
                        route: '/library/progress',
                      ),
                      const SettleGap.xxl(),
                      _SectionHeader(label: 'How it\'s going'),
                      const SettleGap.md(),
                      _ReflectionCard(
                        line: 'You\'ve had a few tough moments this week. That\'s normal.',
                        seeMoreRoute: '/library/progress',
                      ),
                      const SettleGap.xxl(),
                      _SectionHeader(label: 'Your words'),
                      const SettleGap.md(),
                      _YourWordsCard(fallbackRoute: '/library/saved'),
                      const SettleGap.xxl(),
                      _SectionHeader(label: 'Learn more'),
                      const SettleGap.md(),
                      const _LearnMoreRow(),
                      const SettleGap.xxl(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header — V2 sentence case, calm weight
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: SettleSpacing.xs),
      child: Text(
        label,
        style: SettleTypography.overline.copyWith(
          color: SettleSemanticColors.muted(context),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// V2: This week's focus — one proactive play
// ─────────────────────────────────────────────────────────────────────────────

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.title,
    required this.description,
    required this.route,
  });

  final String title;
  final String description;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open this week\'s focus',
      child: SolidCard(
        onTap: () => context.push(route),
        padding: const EdgeInsets.symmetric(
          horizontal: SettleSpacing.cardPadding,
          vertical: SettleSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: SettleTypography.heading.copyWith(
                color: SettleSemanticColors.headline(context),
              ),
            ),
            const SettleGap.sm(),
            Text(
              description,
              style: SettleTypography.body.copyWith(
                color: SettleSemanticColors.body(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// V2: How it's going — one reflective sentence + See more
// ─────────────────────────────────────────────────────────────────────────────

class _ReflectionCard extends StatelessWidget {
  const _ReflectionCard({
    required this.line,
    required this.seeMoreRoute,
  });

  final String line;
  final String seeMoreRoute;

  @override
  Widget build(BuildContext context) {
    final bodyColor = SettleSemanticColors.body(context);
    final mutedColor = SettleSemanticColors.muted(context);

    return SolidCard(
      padding: const EdgeInsets.symmetric(
        horizontal: SettleSpacing.cardPadding,
        vertical: SettleSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            line,
            style: SettleTypography.body.copyWith(color: bodyColor),
          ),
          const SettleGap.sm(),
          SettleTappable(
            semanticLabel: 'See more',
            onTap: () => context.push(seeMoreRoute),
            child: Text(
              'See more',
              style: SettleTypography.caption.copyWith(
                color: mutedColor,
                decoration: TextDecoration.underline,
                decorationColor: mutedColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// V2: Your words — saved cards; tap opens saved playbook
// ─────────────────────────────────────────────────────────────────────────────

class _YourWordsCard extends StatelessWidget {
  const _YourWordsCard({required this.fallbackRoute});

  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    final bodyColor = SettleSemanticColors.body(context);

    return Semantics(
      button: true,
      label: 'Open your saved words',
      child: SolidCard(
        onTap: () => context.push(fallbackRoute),
        padding: const EdgeInsets.symmetric(
          horizontal: SettleSpacing.cardPadding,
          vertical: SettleSpacing.xl,
        ),
        child: Text(
          'Words you keep will live here. Try a Reset to get your first ones.',
          style: SettleTypography.body.copyWith(color: bodyColor),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// V2: Learn more — compact links to Learn, Patterns, Insights, Logs
// ─────────────────────────────────────────────────────────────────────────────

class _LearnMoreRow extends StatelessWidget {
  const _LearnMoreRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CompactDestinationCard(
                title: 'Learn',
                route: '/library/learn',
              ),
            ),
            const SettleGap.md(),
            Expanded(
              child: _CompactDestinationCard(
                title: 'Patterns',
                route: '/library/patterns',
              ),
            ),
          ],
        ),
        const SettleGap.md(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _CompactDestinationCard(
                title: 'Insights',
                route: '/library/insights',
              ),
            ),
            const SettleGap.md(),
            Expanded(
              child: _CompactDestinationCard(
                title: 'Logs',
                route: '/library/logs',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CompactDestinationCard extends StatelessWidget {
  const _CompactDestinationCard({required this.title, required this.route});

  final String title;
  final String route;

  static const double _minHeight = 88;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open $title',
      child: SolidCard(
        onTap: () => context.push(route),
        padding: const EdgeInsets.symmetric(
          horizontal: SettleSpacing.lg,
          vertical: SettleSpacing.lg,
        ),
        child: SizedBox(
          height: _minHeight,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: SettleTypography.subheading.copyWith(
                color: SettleSemanticColors.headline(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

