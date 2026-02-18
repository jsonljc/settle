import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/settle_design_system.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/screen_header.dart';

class LibraryHomeScreen extends StatelessWidget {
  const LibraryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SettleSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ScreenHeader(
                title: 'Library',
                subtitle: 'After a hard moment: review progress and logs.',
                fallbackRoute: '/library',
                showBackButton: false,
              ),
              const SizedBox(height: SettleSpacing.lg),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _LibraryDestinationCard(
                        title: 'Progress',
                        description:
                            'Supportive weekly trend framing from quick check-ins.',
                        route: '/library/progress',
                        icon: Icons.show_chart_rounded,
                      ),
                      SizedBox(height: SettleSpacing.sm),
                      _LibraryDestinationCard(
                        title: 'Logs',
                        description:
                            'Timeline-first view of script outcomes and sleep entries.',
                        route: '/library/logs',
                        icon: Icons.timeline_rounded,
                      ),
                      SizedBox(height: SettleSpacing.sm),
                      _LibraryDestinationCard(
                        title: 'Learn',
                        description: 'Evidence-backed guidance and explainers.',
                        route: '/library/learn',
                        icon: Icons.menu_book_rounded,
                      ),
                      SizedBox(height: SettleSpacing.sm),
                      _LibraryDestinationCard(
                        title: 'Saved',
                        description: 'Playbook cards and saved scripts.',
                        route: '/library/saved',
                        icon: Icons.bookmark_outline_rounded,
                      ),
                      SizedBox(height: SettleSpacing.sm),
                      _LibraryDestinationCard(
                        title: 'Patterns',
                        description:
                            'Optional pattern insights from accumulated usage.',
                        route: '/library/patterns',
                        icon: Icons.insights_rounded,
                      ),
                      SizedBox(height: SettleSpacing.sm),
                      _LibraryDestinationCard(
                        title: 'Monthly insight',
                        description:
                            'Quiet monthly recap of scripts and regulation.',
                        route: '/library/insights',
                        icon: Icons.calendar_month_rounded,
                      ),
                      SizedBox(height: SettleSpacing.xl),
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

class _LibraryDestinationCard extends StatelessWidget {
  const _LibraryDestinationCard({
    required this.title,
    required this.description,
    required this.route,
    required this.icon,
  });

  final String title;
  final String description;
  final String route;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open $title',
      child: GlassCard(
        onTap: () => context.push(route),
        variant: GlassCardVariant.lightStrong,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: _accentColor(context)),
            const SizedBox(width: SettleSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: SettleTypography.heading),
                  const SizedBox(height: SettleSpacing.xs),
                  Text(
                    description,
                    style: SettleTypography.body.copyWith(
                      color: _supportingTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: SettleSpacing.sm),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: _mutedTextColor(context),
            ),
          ],
        ),
      ),
    );
  }
}

Color _supportingTextColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? SettleColors.nightSoft : SettleColors.ink500;
}

Color _mutedTextColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? SettleColors.nightMuted : SettleColors.ink400;
}

Color _accentColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? SettleColors.nightAccent : SettleColors.sage600;
}
