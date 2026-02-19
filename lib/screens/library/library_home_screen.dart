import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/settle_design_system.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/settle_gap.dart';

class LibraryHomeScreen extends StatelessWidget {
  const LibraryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient orbs for visual warmth
            Positioned(
              top: -60,
              right: -40,
              child: _AmbientOrb(
                tint: SettleColors.sage400,
                size: 240,
              ),
            ),
            Positioned(
              bottom: 60,
              left: -50,
              child: _AmbientOrb(
                tint: SettleColors.warmth400,
                size: 200,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SettleSpacing.screenPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScreenHeader(
                    title: 'Library',
                    subtitle:
                        'After a hard moment: review progress and logs.',
                    fallbackRoute: '/library',
                    showBackButton: false,
                  ),
                  const SettleGap.lg(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Track section ──
                          _SectionHeader(label: 'TRACK'),
                          const SettleGap.sm(),
                          _HeroDestinationCard(
                            title: 'Progress',
                            description:
                                'Supportive weekly trend framing from quick check-ins.',
                            route: '/library/progress',
                            icon: Icons.show_chart_rounded,
                            accentColor: isDark
                                ? SettleColors.sage400
                                : SettleColors.sage600,
                            tintColor: isDark
                                ? SettleGlassDark.backgroundSage
                                : SettleGlassLight.backgroundSage,
                          ),
                          const SettleGap.sm(),
                          _LibraryDestinationCard(
                            title: 'Logs',
                            description:
                                'Timeline-first view of script outcomes and sleep entries.',
                            route: '/library/logs',
                            icon: Icons.timeline_rounded,
                            accentColor: isDark
                                ? SettleColors.dusk400
                                : SettleColors.dusk600,
                          ),
                          const SettleGap.xl(),

                          // ── Explore section ──
                          _SectionHeader(label: 'EXPLORE'),
                          const SettleGap.sm(),
                          Row(
                            children: [
                              Expanded(
                                child: _CompactDestinationCard(
                                  title: 'Learn',
                                  icon: Icons.menu_book_rounded,
                                  route: '/library/learn',
                                  accentColor: isDark
                                      ? SettleColors.warmth400
                                      : SettleColors.warmth600,
                                ),
                              ),
                              const SettleGap.sm(),
                              Expanded(
                                child: _CompactDestinationCard(
                                  title: 'Saved',
                                  icon: Icons.bookmark_outline_rounded,
                                  route: '/library/saved',
                                  accentColor: isDark
                                      ? SettleColors.blush400
                                      : SettleColors.blush600,
                                ),
                              ),
                            ],
                          ),
                          const SettleGap.sm(),
                          Row(
                            children: [
                              Expanded(
                                child: _CompactDestinationCard(
                                  title: 'Patterns',
                                  icon: Icons.insights_rounded,
                                  route: '/library/patterns',
                                  accentColor: isDark
                                      ? SettleColors.dusk400
                                      : SettleColors.dusk600,
                                ),
                              ),
                              const SettleGap.sm(),
                              Expanded(
                                child: _CompactDestinationCard(
                                  title: 'Monthly',
                                  icon: Icons.calendar_month_rounded,
                                  route: '/library/insights',
                                  accentColor: isDark
                                      ? SettleColors.sage400
                                      : SettleColors.sage600,
                                ),
                              ),
                            ],
                          ),
                          const SettleGap.xl(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header
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
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero card — Progress (larger, tinted icon circle)
// ─────────────────────────────────────────────────────────────────────────────

class _HeroDestinationCard extends StatelessWidget {
  const _HeroDestinationCard({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
    required this.accentColor,
    required this.tintColor,
  });

  final String title;
  final String description;
  final String route;
  final IconData icon;
  final Color accentColor;
  final Color tintColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: 'Open $title',
      child: GlassCard(
        onTap: () => context.push(route),
        variant: isDark
            ? GlassCardVariant.darkStrong
            : GlassCardVariant.lightStrong,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tintColor,
              ),
              child: Icon(icon, size: 22, color: accentColor),
            ),
            const SizedBox(width: SettleSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SettleTypography.heading.copyWith(
                      color: SettleSemanticColors.headline(context),
                    ),
                  ),
                  const SizedBox(height: SettleSpacing.xs),
                  Text(
                    description,
                    style: SettleTypography.body.copyWith(
                      color: SettleSemanticColors.supporting(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: SettleSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: SettleSemanticColors.muted(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Standard destination card — full width
// ─────────────────────────────────────────────────────────────────────────────

class _LibraryDestinationCard extends StatelessWidget {
  const _LibraryDestinationCard({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String description;
  final String route;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: 'Open $title',
      child: GlassCard(
        onTap: () => context.push(route),
        variant: isDark
            ? GlassCardVariant.darkStrong
            : GlassCardVariant.lightStrong,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: accentColor),
            const SizedBox(width: SettleSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: SettleTypography.heading.copyWith(
                      color: SettleSemanticColors.headline(context),
                    ),
                  ),
                  const SizedBox(height: SettleSpacing.xs),
                  Text(
                    description,
                    style: SettleTypography.body.copyWith(
                      color: SettleSemanticColors.supporting(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: SettleSpacing.sm),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: SettleSemanticColors.muted(context),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact card — 2-column grid items for secondary destinations
// ─────────────────────────────────────────────────────────────────────────────

class _CompactDestinationCard extends StatelessWidget {
  const _CompactDestinationCard({
    required this.title,
    required this.icon,
    required this.route,
    required this.accentColor,
  });

  final String title;
  final IconData icon;
  final String route;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      button: true,
      label: 'Open $title',
      child: GlassCard(
        onTap: () => context.push(route),
        variant: isDark ? GlassCardVariant.dark : GlassCardVariant.light,
        padding: const EdgeInsets.symmetric(
          vertical: SettleSpacing.lg,
          horizontal: SettleSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.12),
              ),
              child: Icon(icon, size: 18, color: accentColor),
            ),
            const SettleGap.sm(),
            Text(
              title,
              style: SettleTypography.label.copyWith(
                color: SettleSemanticColors.headline(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ambient orb — soft diffuse colored glow
// ─────────────────────────────────────────────────────────────────────────────

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
                tint.withValues(alpha: 0.24),
                tint.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
