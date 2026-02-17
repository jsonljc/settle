import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_card.dart';
import '../../providers/user_cards_provider.dart';
import '../../services/card_content_service.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';

class SavedPlaybookScreen extends ConsumerWidget {
  const SavedPlaybookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedCards = ref.watch(userCardsProvider);

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Saved playbook',
                  subtitle: 'Your saved scripts grouped by scenario.',
                  fallbackRoute: '/library',
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: savedCards.isEmpty
                      ? _EmptySavedState()
                      : FutureBuilder<List<CardContent>>(
                          future: CardContentService.instance.getCards(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const Center(
                                child: CircularProgressIndicator.adaptive(),
                              );
                            }

                            final cards =
                                snapshot.data ?? const <CardContent>[];
                            final grouped = _groupResolved(savedCards, cards);
                            if (grouped.isEmpty) {
                              return GlassCard(
                                child: Text(
                                  'Saved entries exist, but matching card content was not found.',
                                  style: T.type.body.copyWith(
                                    color: T.pal.textSecondary,
                                  ),
                                ),
                              );
                            }

                            final triggerKeys = grouped.keys.toList()..sort();
                            return ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              itemCount: triggerKeys.length,
                              itemBuilder: (context, index) {
                                final trigger = triggerKeys[index];
                                final entries = grouped[trigger]!;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: GlassCard(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _triggerLabel(trigger),
                                          style: T.type.h3,
                                        ),
                                        const SizedBox(height: 10),
                                        ...entries.map((entry) {
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            child: _SavedCardRow(entry: entry),
                                          );
                                        }),
                                      ],
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

  Map<String, List<_ResolvedCard>> _groupResolved(
    List<UserCard> userCards,
    List<CardContent> cards,
  ) {
    final byId = {for (final card in cards) card.id: card};
    final grouped = <String, List<_ResolvedCard>>{};
    for (final userCard in userCards) {
      final content = byId[userCard.cardId];
      if (content == null) continue;
      final key = content.triggerType;
      final bucket = grouped.putIfAbsent(key, () => <_ResolvedCard>[]);
      bucket.add(_ResolvedCard(userCard: userCard, content: content));
    }

    for (final bucket in grouped.values) {
      bucket.sort((a, b) {
        if (a.userCard.pinned != b.userCard.pinned) {
          return a.userCard.pinned ? -1 : 1;
        }
        return b.userCard.savedAt.compareTo(a.userCard.savedAt);
      });
    }
    return grouped;
  }

  String _triggerLabel(String triggerType) {
    return triggerType
        .split('_')
        .map((part) {
          if (part.isEmpty) return part;
          return '${part[0].toUpperCase()}${part.substring(1)}';
        })
        .join(' ');
  }
}

class _SavedCardRow extends ConsumerWidget {
  const _SavedCardRow({required this.entry});

  final _ResolvedCard entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(userCardsProvider.notifier);
    final card = entry.content;
    final userCard = entry.userCard;

    return Container(
      decoration: BoxDecoration(
        color: T.glass.fillAccent,
        borderRadius: BorderRadius.circular(T.radius.md),
        border: Border.all(color: T.glass.border),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  card.prevent,
                  style: T.type.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (userCard.pinned)
                Icon(Icons.push_pin_rounded, size: 14, color: T.pal.accent),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            card.say,
            style: T.type.caption.copyWith(color: T.pal.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GlassPill(
                label: 'Open',
                onTap: () => context.push('/library/cards/${card.id}'),
              ),
              GlassPill(
                label: userCard.pinned ? 'Unpin' : 'Pin',
                onTap: () async {
                  if (userCard.pinned) {
                    await notifier.unpin(userCard.cardId);
                  } else {
                    await notifier.pin(userCard.cardId);
                  }
                },
              ),
              GlassPill(
                label: 'Remove',
                onTap: () async {
                  await notifier.unsave(userCard.cardId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Removed from playbook'),
                      duration: Duration(milliseconds: 1000),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptySavedState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No saved scripts yet', style: T.type.h3),
          const SizedBox(height: 8),
          Text(
            'Save cards from Plan to build your playbook.',
            style: T.type.body.copyWith(color: T.pal.textSecondary),
          ),
          const SizedBox(height: 12),
          GlassCta(label: 'Open plan', onTap: () => context.push('/plan')),
        ],
      ),
    );
  }
}

class _ResolvedCard {
  const _ResolvedCard({required this.userCard, required this.content});

  final UserCard userCard;
  final CardContent content;
}
