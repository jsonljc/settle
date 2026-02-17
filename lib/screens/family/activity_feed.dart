import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/v2_enums.dart';
import '../../providers/usage_events_provider.dart';
import '../../services/card_content_service.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';

/// Local activity feed: recent [UsageEvent]s (card uses). MVP, no backend.
class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(usageEventsProvider);

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ScreenHeader(
                  title: 'Activity',
                  subtitle: 'Recent script use (local only).',
                  fallbackRoute: '/family',
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: events.isEmpty
                      ? Center(
                          child: Text(
                            'When you use scripts from Plan or Pocket, they\'ll show here.',
                            style: T.type.body.copyWith(
                              color: T.pal.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : FutureBuilder<List<CardContent>>(
                          future: CardContentService.instance.getCards(),
                          builder: (context, snapshot) {
                            final cards = snapshot.data ?? [];
                            final byId = {
                              for (final c in cards) c.id: c
                            };
                            final recent = events.take(50).toList();
                            return ListView.builder(
                              itemCount: recent.length,
                              itemBuilder: (context, i) {
                                final event = recent[i];
                                final card = byId[event.cardId];
                                final triggerLabel = card?.triggerType ?? event.cardId;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GlassCard(
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      title: Text(
                                        _triggerDisplayName(triggerLabel),
                                        style: T.type.label,
                                      ),
                                      subtitle: Text(
                                        '${_outcomeLabel(event.outcome)} · ${_formatTime(event.timestamp)}',
                                        style: T.type.caption.copyWith(
                                          color: T.pal.textTertiary,
                                        ),
                                      ),
                                      trailing: event.outcome == UsageOutcome.great
                                          ? Icon(
                                              Icons.thumb_up_rounded,
                                              size: 18,
                                              color: T.pal.teal,
                                            )
                                          : null,
                                      onTap: () => context.push('/library/cards/${event.cardId}'),
                                    ),
                                  ),
                                );
                              },
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

  String _outcomeLabel(UsageOutcome? o) {
    if (o == null) return 'Used';
    return switch (o) {
      UsageOutcome.great => 'Worked great',
      UsageOutcome.okay => 'Okay',
      UsageOutcome.didntWork => 'Didn\'t work',
      UsageOutcome.didntTry => 'Didn\'t try',
    };
  }

  String _triggerDisplayName(String triggerType) {
    return triggerType
        .split('_')
        .map((p) => p.isEmpty ? p : '${p[0].toUpperCase()}${p.substring(1)}')
        .join(' ');
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(t.year, t.month, t.day);
    if (d == today) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    final yesterday = today.subtract(const Duration(days: 1));
    if (d == yesterday) return 'Yesterday';
    return '${t.month}/${t.day}';
  }
}

/// Compact activity feed widget for Family home (preview).
class ActivityFeedPreview extends ConsumerWidget {
  const ActivityFeedPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(usageEventsProvider);
    final recent = events.take(5).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Activity', style: T.type.h3),
              if (events.isNotEmpty)
                GestureDetector(
                  onTap: () => context.push('/family/activity'),
                  child: Text(
                    'See all',
                    style: T.type.label.copyWith(color: T.pal.accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            Text(
              'Recent script use will appear here.',
              style: T.type.body.copyWith(color: T.pal.textSecondary),
            )
          else
            ...recent.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        e.outcome == UsageOutcome.great
                            ? Icons.thumb_up_rounded
                            : Icons.description_outlined,
                        size: 16,
                        color: T.pal.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          e.cardId,
                          style: T.type.caption.copyWith(
                            color: T.pal.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          if (recent.isNotEmpty)
            GlassPill(
              label: 'Open activity',
              onTap: () => context.push('/family/activity'),
            ),
        ],
      ),
    );
  }
}
