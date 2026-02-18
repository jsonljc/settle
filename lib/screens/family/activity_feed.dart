import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/v2_enums.dart';
import '../../providers/usage_events_provider.dart';
import '../../services/card_content_service.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/screen_header.dart';

class _AfT {
  _AfT._();

  static final type = _AfTypeTokens();
  static const pal = _AfPaletteTokens();
}

class _AfTypeTokens {
  TextStyle get h3 => SettleTypography.heading.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );
  TextStyle get body => SettleTypography.body;
  TextStyle get label =>
      SettleTypography.body.copyWith(fontWeight: FontWeight.w600);
  TextStyle get caption => SettleTypography.caption.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
}

class _AfPaletteTokens {
  const _AfPaletteTokens();

  Color get textSecondary => SettleColors.nightSoft;
  Color get textTertiary => SettleColors.nightMuted;
  Color get accent => SettleColors.nightAccent;
  Color get teal => SettleColors.sage400;
}

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
                const SizedBox(height: 12),
                Expanded(
                  child: events.isEmpty
                      ? Center(
                          child: Text(
                            'When you use scripts from Plan or Pocket, they\'ll show here.',
                            style: _AfT.type.body.copyWith(
                              color: _AfT.pal.textSecondary,
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
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GlassCard(
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 4,
                                          ),
                                      title: Text(
                                        _triggerDisplayName(triggerLabel),
                                        style: _AfT.type.label,
                                      ),
                                      subtitle: Text(
                                        '${_outcomeLabel(event.outcome)} · ${_formatTime(event.timestamp)}',
                                        style: _AfT.type.caption.copyWith(
                                          color: _AfT.pal.textTertiary,
                                        ),
                                      ),
                                      trailing:
                                          event.outcome == UsageOutcome.great
                                          ? Icon(
                                              Icons.thumb_up_rounded,
                                              size: 18,
                                              color: _AfT.pal.teal,
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
              Text('Activity', style: _AfT.type.h3),
              if (events.isNotEmpty)
                GestureDetector(
                  onTap: () => context.push('/family/activity'),
                  child: Text(
                    'See all',
                    style: _AfT.type.label.copyWith(color: _AfT.pal.accent),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (recent.isEmpty)
            Text(
              'Recent script use will appear here.',
              style: _AfT.type.body.copyWith(color: _AfT.pal.textSecondary),
            )
          else
            ...recent.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      e.outcome == UsageOutcome.great
                          ? Icons.thumb_up_rounded
                          : Icons.description_outlined,
                      size: 16,
                      color: _AfT.pal.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.cardId,
                        style: _AfT.type.caption.copyWith(
                          color: _AfT.pal.textSecondary,
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
