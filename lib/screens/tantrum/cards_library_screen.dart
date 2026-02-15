import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../tantrum/models/tantrum_card.dart';
import '../../tantrum/providers/tantrum_module_providers.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/tantrum_sub_nav.dart';

/// CARDS: card library (list/grid). Tapping opens card detail.
class CardsLibraryScreen extends ConsumerWidget {
  const CardsLibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(tantrumCardsProvider);
    final pinnedIds = ref.watch(protocolPinnedIdsProvider);

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'CARDS',
                  subtitle: 'Pin up to 10 to your Protocol',
                  fallbackRoute: '/tantrum',
                ),
                const SizedBox(height: 12),
                const TantrumSubNav(currentSegment: TantrumSubNav.segmentCards),
                const SizedBox(height: 16),
                Expanded(
                  child: cardsAsync.when(
                    data: (cards) => ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: cards.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        final isPinned = pinnedIds.contains(card.id);
                        return _CardTile(
                          card: card,
                          isPinned: isPinned,
                          onTap: () => context.push(
                            '/tantrum/cards/${Uri.encodeComponent(card.id)}',
                          ),
                        );
                      },
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (e, _) => Center(
                      child: Text(
                        'Could not load cards.',
                        style: T.type.body.copyWith(color: T.pal.textSecondary),
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
}

class _CardTile extends StatelessWidget {
  const _CardTile({
    required this.card,
    required this.isPinned,
    required this.onTap,
  });

  final TantrumCard card;
  final bool isPinned;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.title,
                    style: T.type.label,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    card.say,
                    style: T.type.caption.copyWith(color: T.pal.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isPinned)
              Icon(Icons.push_pin_rounded, size: 18, color: T.pal.accent),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: T.pal.textTertiary),
          ],
        ),
      ),
    );
  }
}
