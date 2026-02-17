import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/v2_enums.dart';
import '../../providers/regulation_events_provider.dart';
import '../../providers/usage_events_provider.dart';
import '../../services/card_content_service.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';

/// Transition / bedtime / regulation summary for the current month.
class MonthlyInsightScreen extends ConsumerWidget {
  const MonthlyInsightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageEvents = ref.watch(usageEventsProvider);
    final regulationEvents = ref.watch(regulationEventsProvider);
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

    final monthUsage = usageEvents
        .where((e) => e.timestamp.isAfter(startOfMonth) || e.timestamp.isAtSameMomentAs(startOfMonth))
        .toList();
    final monthRegulation = regulationEvents
        .where((e) => e.timestamp.isAfter(startOfMonth) || e.timestamp.isAtSameMomentAs(startOfMonth))
        .toList();

    final greatCount = monthUsage.where((e) => e.outcome == UsageOutcome.great).length;

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Monthly insight',
                  subtitle: 'A quiet look at your month.',
                  fallbackRoute: '/library',
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: FutureBuilder<List<CardContent>>(
                      future: CardContentService.instance.getCards(),
                      builder: (context, snapshot) {
                        final cards = snapshot.data ?? [];
                        final byId = {for (final c in cards) c.id: c};
                        final usageByTrigger = <String, int>{};
                        for (final e in monthUsage) {
                          final trigger = byId[e.cardId]?.triggerType ?? e.cardId;
                          usageByTrigger[trigger] = (usageByTrigger[trigger] ?? 0) + 1;
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SummaryCard(
                              title: 'Scripts used',
                              subtitle: 'Times you used a Pocket or Plan script this month.',
                              value: '${monthUsage.length}',
                              icon: Icons.menu_book_rounded,
                            ),
                            const SizedBox(height: 10),
                            _SummaryCard(
                              title: '"Worked great"',
                              subtitle: 'Moments that went well.',
                              value: '$greatCount',
                              icon: Icons.celebration_rounded,
                            ),
                            const SizedBox(height: 10),
                            _SummaryCard(
                              title: 'Regulation resets',
                              subtitle: 'Times you used the regulate flow.',
                              value: '${monthRegulation.length}',
                              icon: Icons.self_improvement_rounded,
                            ),
                            if (usageByTrigger.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Text(
                                'By situation',
                                style: T.type.h3,
                              ),
                              const SizedBox(height: 8),
                              ...usageByTrigger.entries.map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: GlassCard(
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              _formatTrigger(e.key),
                                              style: T.type.body,
                                            ),
                                          ),
                                          Text(
                                            '${e.value}',
                                            style: T.type.label.copyWith(
                                              color: T.pal.accent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )),
                            ],
                            const SizedBox(height: 24),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _formatTrigger(String triggerType) {
    return triggerType
        .split('_')
        .map((part) {
          if (part.isEmpty) return part;
          return '${part[0].toUpperCase()}${part.substring(1)}';
        })
        .join(' ');
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: T.pal.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: T.type.h3),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: T.type.body.copyWith(color: T.pal.textSecondary),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: T.type.h2.copyWith(color: T.pal.accent),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
