import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../tantrum/models/tantrum_card.dart';
import '../../tantrum/providers/tantrum_module_providers.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/tantrum_sub_nav.dart';

/// NOW landing: 2 taps to Crisis View.
/// Tap 1 = land here (from Tantrum tab). Tap 2 = "Use my protocol" or pick a card → Crisis.
class TantrumNowScreen extends ConsumerWidget {
  const TantrumNowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protocolCards = ref.watch(protocolCardsProvider);
    final cardsAsync = ref.watch(tantrumCardsProvider);

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'NOW',
                  subtitle: 'Get to your crisis steps in two taps',
                  fallbackRoute: '/tantrum',
                ),
                const SizedBox(height: 12),
                const TantrumSubNav(currentSegment: TantrumSubNav.segmentNow),
                const SizedBox(height: 20),
                if (protocolCards.isNotEmpty) ...[
                  Text(
                    'Your protocol',
                    style: T.type.overline.copyWith(color: T.pal.textTertiary),
                  ),
                  const SizedBox(height: 8),
                  GlassCta(
                    label: 'Use my protocol',
                    onTap: () => context.push('/tantrum/crisis'),
                  ),
                  const SizedBox(height: 24),
                ],
                Text(
                  protocolCards.isNotEmpty
                      ? 'Or choose a situation'
                      : 'Choose a situation',
                  style: T.type.overline.copyWith(color: T.pal.textTertiary),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: cardsAsync.when(
                    data: (cards) => _CardGrid(
                      cards: cards,
                      onTap: (card) => context.push(
                        '/tantrum/crisis?cardId=${Uri.encodeComponent(card.id)}',
                      ),
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (_, __) => Center(
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

class _CardGrid extends StatelessWidget {
  const _CardGrid({
    required this.cards,
    required this.onTap,
  });

  final List<TantrumCard> cards;
  final ValueChanged<TantrumCard> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return GestureDetector(
          onTap: () => onTap(card),
          child: GlassCard(
            border: false,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  card.title,
                  textAlign: TextAlign.center,
                  style: T.type.label.copyWith(fontSize: 13),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
