import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/pattern_insight.dart';
import '../../providers/patterns_provider.dart';
import '../../providers/playbook_provider.dart';
import '../../theme/glass_components.dart' hide GlassCard, GlassPill;
import '../../theme/settle_design_system.dart';
import '../../theme/settle_tokens.dart';
import '../../providers/weekly_reflection_provider.dart';
import '../../widgets/calm_loading.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_pill.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/weekly_reflection.dart';

class LibraryHomeScreen extends ConsumerWidget {
  const LibraryHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbookAsync = ref.watch(playbookRepairCardsProvider);
    final patterns = ref.watch(patternsProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Library',
                  subtitle: 'Saved scripts, learning, and patterns.',
                  fallbackRoute: '/library',
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (WeeklyReflectionBanner.shouldShow() &&
                            !ref.watch(
                              weeklyReflectionDismissedThisWeekProvider,
                            )) ...[
                          WeeklyReflectionBanner(
                            onDismiss: () => ref
                                .read(weeklyReflectionProvider.notifier)
                                .dismissThisWeek(),
                          ),
                          const SizedBox(height: 10),
                        ],
                        _MonthlyInsightCard(),
                        const SizedBox(height: 10),
                        _PatternsPreviewCard(patterns: patterns),
                        const SizedBox(height: 10),
                        _SavedPlaybookPreviewCard(
                          playbookAsync: playbookAsync,
                          onRetry: () =>
                              ref.invalidate(playbookRepairCardsProvider),
                        ),
                        const SizedBox(height: 10),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Learn', style: T.type.h3),
                              const SizedBox(height: 8),
                              Text(
                                'Review evidence-backed guidance.',
                                style: T.type.body.copyWith(
                                  color: T.pal.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GlassCta(
                                label: 'Open learn',
                                onTap: () => context.push('/library/learn'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Logs', style: T.type.h3),
                              const SizedBox(height: 8),
                              Text(
                                'Review day and week outcomes quietly over time.',
                                style: T.type.body.copyWith(
                                  color: T.pal.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GlassCta(
                                label: 'Open logs',
                                onTap: () => context.push('/library/logs'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
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

class _MonthlyInsightCard extends StatelessWidget {
  const _MonthlyInsightCard();

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Monthly insight', style: T.type.h3),
          const SizedBox(height: 8),
          Text(
            'A quiet look at scripts, wins, and regulation this month.',
            style: T.type.body.copyWith(color: T.pal.textSecondary),
          ),
          const SizedBox(height: 12),
          GlassCta(
            label: 'Open monthly insight',
            onTap: () => context.push('/library/insights'),
          ),
        ],
      ),
    );
  }
}

class _PatternsPreviewCard extends StatelessWidget {
  const _PatternsPreviewCard({required this.patterns});

  final List<PatternInsight> patterns;

  @override
  Widget build(BuildContext context) {
    final preview = patterns.take(2).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your patterns', style: T.type.h3),
          const SizedBox(height: 8),
          if (preview.isEmpty)
            Text(
              'Pattern insights will appear once enough usage events accumulate.',
              style: T.type.body.copyWith(color: T.pal.textSecondary),
            )
          else
            ...preview.map((pattern) {
              final confidence = (pattern.confidence * 100).clamp(0, 100);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _patternLabel(pattern),
                      style: T.type.caption.copyWith(color: T.pal.textTertiary),
                    ),
                    const SizedBox(height: 3),
                    Text(pattern.insight, style: T.type.body),
                    const SizedBox(height: 2),
                    Text(
                      '${confidence.toStringAsFixed(0)}% confidence',
                      style: T.type.caption.copyWith(color: T.pal.textTertiary),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 10),
          GlassPill(
            label: 'Open patterns',
            onTap: () => context.push('/library/patterns'),
            variant: GlassPillVariant.secondaryLight,
          ),
        ],
      ),
    );
  }

  String _patternLabel(PatternInsight pattern) {
    return switch (pattern.patternType.name) {
      'time' => 'Timing pattern',
      'strategy' => 'Strategy pattern',
      'regulation' => 'Regulation pattern',
      _ => 'Pattern insight',
    };
  }
}

class _SavedPlaybookPreviewCard extends StatelessWidget {
  const _SavedPlaybookPreviewCard({
    required this.playbookAsync,
    this.onRetry,
  });

  final AsyncValue<List<PlaybookEntry>> playbookAsync;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Playbook', style: T.type.h3),
          const SizedBox(height: 8),
          playbookAsync.when(
            data: (list) {
              if (list.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your playbook is empty.',
                      style: SettleTypography.body.copyWith(
                        color: T.pal.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassPill(
                      label: 'Open playbook',
                      onTap: () => context.push('/library/saved'),
                      variant: GlassPillVariant.secondaryLight,
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...list.take(3).map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: GestureDetector(
                        onTap: () => context.push(
                          '/library/saved/card/${entry.repairCard.id}',
                        ),
                        child: GlassCard(
                          variant: GlassCardVariant.lightStrong,
                          padding: const EdgeInsets.all(10),
                          child: Text(
                            entry.repairCard.title,
                            style: T.type.label,
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 10),
                  GlassPill(
                    label: 'Open playbook',
                    onTap: () => context.push('/library/saved'),
                    variant: GlassPillVariant.secondaryLight,
                  ),
                ],
              );
            },
            loading: () => const SizedBox(
              height: 56,
              child: Center(
                child: CalmLoading(message: 'Loading library…'),
              ),
            ),
            error: (_, __) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final color = isDark ? SettleColors.nightSoft : SettleColors.ink500;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Something went wrong.',
                    style: SettleTypography.body.copyWith(color: color),
                  ),
                const SizedBox(height: SettleSpacing.md),
                if (onRetry != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: SettleSpacing.sm),
                    child: GlassPill(
                      label: 'Try again',
                      onTap: onRetry!,
                      variant: GlassPillVariant.primaryLight,
                    ),
                  ),
                GlassPill(
                  label: 'Open playbook',
                  onTap: () => context.push('/library/saved'),
                  variant: GlassPillVariant.secondaryLight,
                ),
              ],
            );
            },
          ),
        ],
      ),
    );
  }
}
