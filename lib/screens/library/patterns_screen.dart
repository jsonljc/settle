import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/pattern_insight.dart';
import '../../providers/patterns_provider.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';

class PatternsScreen extends ConsumerWidget {
  const PatternsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patterns = ref.watch(patternsProvider);

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Your patterns',
                  subtitle: 'Signals generated from your recent usage.',
                  fallbackRoute: '/library',
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: patterns.isEmpty
                      ? _EmptyPatternsState()
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: patterns.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _PatternCard(pattern: patterns[index]),
                            );
                          },
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

class _PatternCard extends StatelessWidget {
  const _PatternCard({required this.pattern});

  final PatternInsight pattern;

  @override
  Widget build(BuildContext context) {
    final confidencePercent = (pattern.confidence * 100).clamp(0, 100);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_typeLabel(pattern), style: T.type.h3),
          const SizedBox(height: 8),
          Text(pattern.insight, style: T.type.body),
          const SizedBox(height: 10),
          Text(
            '${confidencePercent.toStringAsFixed(0)}% confidence · ${pattern.basedOnEvents} events',
            style: T.type.caption.copyWith(color: T.pal.textSecondary),
          ),
          const SizedBox(height: 3),
          Text(
            'Generated ${_formatDate(pattern.createdAt)}',
            style: T.type.caption.copyWith(color: T.pal.textTertiary),
          ),
        ],
      ),
    );
  }

  String _typeLabel(PatternInsight pattern) {
    return switch (pattern.patternType.name) {
      'time' => 'Timing pattern',
      'strategy' => 'Strategy pattern',
      'regulation' => 'Regulation pattern',
      _ => 'Pattern',
    };
  }

  String _formatDate(DateTime timestamp) {
    final mm = timestamp.month.toString().padLeft(2, '0');
    final dd = timestamp.day.toString().padLeft(2, '0');
    return '$mm/$dd/${timestamp.year}';
  }
}

class _EmptyPatternsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No patterns yet', style: T.type.h3),
          const SizedBox(height: 8),
          Text(
            'Pattern detection will populate here after more usage events are logged.',
            style: T.type.body.copyWith(color: T.pal.textSecondary),
          ),
          const SizedBox(height: 12),
          GlassCta(label: 'Open plan', onTap: () => context.push('/plan')),
        ],
      ),
    );
  }
}
