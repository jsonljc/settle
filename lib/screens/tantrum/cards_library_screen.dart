import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../tantrum/models/tantrum_card.dart';
import '../../tantrum/providers/tantrum_module_providers.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/settle_gap.dart';
import '../../widgets/tantrum_sub_nav.dart';

/// DECK: saved cards, pinned cards, favorites, and purchased packs.
/// Canonical route is `/tantrum/deck`.
class CardsLibraryScreen extends ConsumerWidget {
  const CardsLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(tantrumCardsProvider);
    final deck = ref.watch(deckStateProvider);
    final notifier = ref.read(deckStateProvider.notifier);

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Deck',
                  subtitle: 'Saved calm cards, pinned and ready',
                  fallbackRoute: '/tantrum',
                ),
                const SizedBox(height: 12),
                const TantrumSubNav(currentSegment: TantrumSubNav.segmentCards),
                const SizedBox(height: 16),
                Expanded(
                  child: cardsAsync.when(
                    data: (cards) {
                      final savedCards = _resolve(cards, deck.savedIds);
                      final pinnedCards = _resolve(cards, deck.pinnedIds);
                      final savedSet = deck.savedIds.toSet();
                      final unlockedPacks = {'base', ...deck.purchasedPackIds};

                      final unlockedUnsaved = cards
                          .where(
                            (card) =>
                                !savedSet.contains(card.id) &&
                                (!card.isPremium ||
                                    unlockedPacks.contains(card.packId)),
                          )
                          .toList();

                      final packSummaries = _packSummaries(
                        cards,
                        deck.purchasedPackIds,
                      );

                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          _SectionHeader(
                            title: 'Pinned cards',
                            subtitle: 'Max $maxPinnedCards',
                          ),
                          const SizedBox(height: 8),
                          if (pinnedCards.isEmpty)
                            _EmptyCard(
                              message:
                                  'Pin up to $maxPinnedCards cards from your saved deck.',
                            )
                          else
                            ...pinnedCards.asMap().entries.map((entry) {
                              final index = entry.key;
                              final card = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _PinnedTile(
                                  card: card,
                                  canMoveUp: index > 0,
                                  canMoveDown: index < pinnedCards.length - 1,
                                  onMoveUp: () =>
                                      notifier.reorderPinned(index, index - 1),
                                  onMoveDown: () =>
                                      notifier.reorderPinned(index, index + 1),
                                  onUnpin: () => notifier.unpin(card.id),
                                  onTap: () => context.push(
                                    '/tantrum/deck/${Uri.encodeComponent(card.id)}',
                                  ),
                                ),
                              );
                            }),

                          const SizedBox(height: 12),
                          const _SectionHeader(
                            title: 'Saved cards',
                            subtitle: 'Favorite, pin, reorder, share',
                          ),
                          const SizedBox(height: 8),
                          if (savedCards.isEmpty)
                            const _EmptyCard(
                              message:
                                  'Save cards from capture output or browse below.',
                            )
                          else
                            ...savedCards.map((card) {
                              final isFavorite = deck.isFavorite(card.id);
                              final isPinned = deck.isPinned(card.id);
                              final pinDisabled =
                                  !isPinned && notifier.isAtPinnedMax;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _SavedCardTile(
                                  card: card,
                                  isFavorite: isFavorite,
                                  isPinned: isPinned,
                                  pinDisabled: pinDisabled,
                                  onTap: () => context.push(
                                    '/tantrum/deck/${Uri.encodeComponent(card.id)}',
                                  ),
                                  onToggleFavorite: () =>
                                      notifier.toggleFavorite(card.id),
                                  onTogglePin: () async {
                                    if (isPinned) {
                                      await notifier.unpin(card.id);
                                    } else {
                                      await notifier.pin(card.id);
                                    }
                                  },
                                  onUnsave: () => notifier.unsave(card.id),
                                  onShare: () => _copyCard(context, card),
                                ),
                              );
                            }),

                          const SizedBox(height: 12),
                          const _SectionHeader(
                            title: 'Purchased packs',
                            subtitle: 'Unlock and keep themed card sets',
                          ),
                          const SizedBox(height: 8),
                          if (packSummaries.isEmpty)
                            const _EmptyCard(
                              message: 'No premium packs available yet.',
                            )
                          else
                            ...packSummaries.map(
                              (pack) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _PackTile(
                                  pack: pack,
                                  onToggle: () =>
                                      notifier.togglePackPurchased(pack.id),
                                ),
                              ),
                            ),

                          const SizedBox(height: 12),
                          const _SectionHeader(
                            title: 'Browse cards',
                            subtitle: 'Add more cards to your deck',
                          ),
                          const SizedBox(height: 8),
                          if (unlockedUnsaved.isEmpty)
                            const _EmptyCard(
                              message:
                                  'You saved all currently unlocked cards.',
                            )
                          else
                            ...unlockedUnsaved.map(
                              (card) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _DiscoverTile(
                                  card: card,
                                  onSave: () => notifier.save(card.id),
                                  onTap: () => context.push(
                                    '/tantrum/deck/${Uri.encodeComponent(card.id)}',
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                        ],
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: T.space.screen,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'We couldn\'t load your deck right now.',
                              style: T.type.body.copyWith(
                                color: T.pal.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SettleGap.lg(),
                            GlassCta(
                              label: 'Back to Incident',
                              onTap: () => context.go('/tantrum'),
                            ),
                          ],
                        ),
                      ),
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

  List<TantrumCard> _resolve(List<TantrumCard> cards, List<String> ids) {
    final byId = {for (final card in cards) card.id: card};
    return ids.map((id) => byId[id]).whereType<TantrumCard>().toList();
  }

  List<_PackSummary> _packSummaries(
    List<TantrumCard> cards,
    Set<String> purchasedPackIds,
  ) {
    final grouped = <String, int>{};
    for (final card in cards) {
      if (card.packId == 'base') continue;
      grouped[card.packId] = (grouped[card.packId] ?? 0) + 1;
    }

    final out = grouped.entries
        .map(
          (e) => _PackSummary(
            id: e.key,
            title: _packTitle(e.key),
            cardCount: e.value,
            purchased: purchasedPackIds.contains(e.key),
          ),
        )
        .toList();

    out.sort((a, b) => a.title.compareTo(b.title));
    return out;
  }

  String _packTitle(String packId) {
    switch (packId) {
      case 'public_meltdown_pack':
        return 'Public Meltdown Pack';
      case 'boundaries_pack':
        return 'Boundaries Pack';
      case 'sibling_conflict_pack':
        return 'Sibling Conflict Pack';
      case 'emotional_regulation_pack':
        return 'Emotional Regulation Pack';
      default:
        final label = packId.replaceAll('_', ' ').trim();
        if (label.isEmpty) return 'Card Pack';
        return label[0].toUpperCase() + label.substring(1);
    }
  }

  Future<void> _copyCard(BuildContext context, TantrumCard card) async {
    final payload =
        '${card.title}\n\nRemember: ${card.remember}\n\nSay: ${card.say}\n\nDo: ${card.doStep}';
    await Clipboard.setData(ClipboardData(text: payload));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Card copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: T.type.label),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: T.type.caption.copyWith(color: T.pal.textSecondary),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Text(
        message,
        style: T.type.body.copyWith(color: T.pal.textSecondary),
      ),
    );
  }
}

class _PinnedTile extends StatelessWidget {
  const _PinnedTile({
    required this.card,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onUnpin,
    required this.onTap,
  });

  final TantrumCard card;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onUnpin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.title, style: T.type.label),
                  const SizedBox(height: 4),
                  Text(
                    card.remember,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: T.type.caption.copyWith(color: T.pal.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: canMoveUp ? onMoveUp : null,
              icon: const Icon(Icons.keyboard_arrow_up_rounded),
              color: T.pal.textSecondary,
            ),
            IconButton(
              onPressed: canMoveDown ? onMoveDown : null,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              color: T.pal.textSecondary,
            ),
            IconButton(
              onPressed: onUnpin,
              icon: const Icon(Icons.push_pin_outlined),
              color: T.pal.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedCardTile extends StatelessWidget {
  const _SavedCardTile({
    required this.card,
    required this.isFavorite,
    required this.isPinned,
    required this.pinDisabled,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onTogglePin,
    required this.onUnsave,
    required this.onShare,
  });

  final TantrumCard card;
  final bool isFavorite;
  final bool isPinned;
  final bool pinDisabled;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onTogglePin;
  final VoidCallback onUnsave;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(card.title, style: T.type.label)),
                if (isPinned)
                  Icon(Icons.push_pin_rounded, size: 16, color: T.pal.accent),
                const SizedBox(width: 6),
                if (isFavorite)
                  Icon(Icons.star_rounded, size: 16, color: T.pal.accent),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              card.say,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: T.type.caption.copyWith(color: T.pal.textSecondary),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _TinyAction(
                  label: isFavorite ? 'Unfavorite' : 'Favorite',
                  onTap: onToggleFavorite,
                ),
                const SizedBox(width: 6),
                _TinyAction(
                  label: isPinned ? 'Unpin' : 'Pin',
                  enabled: isPinned || !pinDisabled,
                  onTap: onTogglePin,
                ),
                const SizedBox(width: 6),
                _TinyAction(label: 'Share', onTap: onShare),
                const SizedBox(width: 6),
                _TinyAction(label: 'Remove', onTap: onUnsave),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyAction extends StatelessWidget {
  const _TinyAction({
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassPill(label: label, enabled: enabled, onTap: onTap),
    );
  }
}

class _PackTile extends StatelessWidget {
  const _PackTile({required this.pack, required this.onToggle});

  final _PackSummary pack;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pack.title, style: T.type.label),
                const SizedBox(height: 2),
                Text(
                  '${pack.cardCount} cards',
                  style: T.type.caption.copyWith(color: T.pal.textSecondary),
                ),
              ],
            ),
          ),
          GlassPill(
            label: pack.purchased ? 'Purchased' : 'Unlock',
            onTap: onToggle,
          ),
        ],
      ),
    );
  }
}

class _DiscoverTile extends StatelessWidget {
  const _DiscoverTile({
    required this.card,
    required this.onSave,
    required this.onTap,
  });

  final TantrumCard card;
  final VoidCallback onSave;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.title, style: T.type.label),
                  const SizedBox(height: 4),
                  Text(
                    card.remember,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: T.type.caption.copyWith(color: T.pal.textSecondary),
                  ),
                ],
              ),
            ),
            GlassPill(label: 'Save', onTap: onSave),
          ],
        ),
      ),
    );
  }
}

class _PackSummary {
  const _PackSummary({
    required this.id,
    required this.title,
    required this.cardCount,
    required this.purchased,
  });

  final String id;
  final String title;
  final int cardCount;
  final bool purchased;
}
