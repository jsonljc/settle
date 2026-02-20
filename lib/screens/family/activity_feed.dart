import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/v2_enums.dart';
import '../../providers/usage_events_provider.dart';
import '../../services/card_content_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_pill.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/settle_gap.dart';
import '../../widgets/settle_tappable.dart';

/// Local activity feed: recent [UsageEvent]s (card uses). MVP, no backend.
class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(usageEventsProvider);

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SettleSpacing.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ScreenHeader(
                  title: 'Activity',
                  subtitle: 'Recent script use (local only).',
                  fallbackRoute: '/family',
                ),
                const SettleGap.md(),
                Expanded(
                  child: events.isEmpty
                      ? Center(
                          child: Text(
                            'When you use scripts from Plan, they\'ll show here.',
                            style: SettleTypography.body.copyWith(
                              color: SettleColors.nightSoft,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : FutureBuilder<List<CardContent>>(
                          future: CardContentService.instance.getCards(),
                          builder: (context, snapshot) {
                            final cards = snapshot.data ?? [];
                            final byId = {for (final c in cards) c.id: c};
                            final recent = events.take(50).toList();
                            return ListView.builder(
                              itemCount: recent.length,
                              itemBuilder: (context, i) {
                                final event = recent[i];
                                final card = byId[event.cardId];
                                final triggerLabel =
                                    card?.triggerType ?? event.cardId;
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: SettleSpacing.sm,
                                  ),
                                  child: GlassCard(
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: SettleSpacing.md,
                                            vertical: SettleSpacing.xs,
                                          ),
                                      title: Text(
                                        _triggerDisplayName(triggerLabel),
                                        style: SettleTypography.body.copyWith(fontWeight: FontWeight.w600),
                                      ),
                                      subtitle: Text(
                                        '${_outcomeLabel(event.outcome)} · ${_formatTime(event.timestamp)}',
                                        style: SettleTypography.caption.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: SettleColors.nightMuted,
                                        ),
                                      ),
                                      trailing:
                                          event.outcome == UsageOutcome.great
                                          ? Icon(
                                              Icons.thumb_up_rounded,
                                              size: 18,
                                              color: SettleColors.sage400,
                                            )
                                          : null,
                                      onTap: () => context.push(
                                        '/library/cards/${event.cardId}',
                                      ),
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
              Text('Activity', style: SettleTypography.heading.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
              if (events.isNotEmpty)
                SettleTappable(
                  onTap: () => context.push('/family/activity'),
                  semanticLabel: 'Open all family activity',
                  child: Text(
                    'See all',
                    style: SettleTypography.body.copyWith(fontWeight: FontWeight.w600, color: SettleColors.nightAccent),
                  ),
                ),
            ],
          ),
          const SettleGap.sm(),
          if (recent.isEmpty)
            Text(
              'Recent script use will appear here.',
              style: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
            )
          else
            ...recent.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: SettleSpacing.xs),
                child: Row(
                  children: [
                    Icon(
                      e.outcome == UsageOutcome.great
                          ? Icons.thumb_up_rounded
                          : Icons.description_outlined,
                      size: 16,
                      color: SettleColors.nightMuted,
                    ),
                    const SizedBox(width: SettleSpacing.sm),
                    Expanded(
                      child: Text(
                        e.cardId,
                        style: SettleTypography.caption.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: SettleColors.nightSoft,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
