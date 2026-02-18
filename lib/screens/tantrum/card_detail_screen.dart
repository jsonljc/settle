import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../tantrum/providers/tantrum_module_providers.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_design_system.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/screen_header.dart';

/// Deck card detail with save/favorite/pin/share controls.
class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({super.key, required this.cardId});

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardAsync = ref.watch(tantrumCardByIdProvider(cardId));
    final deck = ref.watch(deckStateProvider);
    final notifier = ref.read(deckStateProvider.notifier);

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
            child: cardAsync.when(
              data: (card) {
                if (card == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ScreenHeader(
                        title: 'Card',
                        fallbackRoute: '/tantrum/deck',
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Card not found.',
                        style: T.type.body.copyWith(color: T.pal.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      GlassCta(
                        label: 'Back to Deck',
                        onTap: () => context.go('/tantrum/deck'),
                      ),
                    ],
                  );
                }

                final isSaved = deck.isSaved(cardId);
                final isFavorite = deck.isFavorite(cardId);
                final isPinned = deck.isPinned(cardId);
                final isPackUnlocked =
                    card.packId == 'base' ||
                    deck.purchasedPackIds.contains(card.packId);
                final pinDisabled = !isPinned && notifier.isAtPinnedMax;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScreenHeader(
                        title: card.title,
                        fallbackRoute: '/tantrum/deck',
                      ),
                      const SizedBox(height: 20),
                      _Section(
                        title: 'Remember',
                        body: card.remember,
                        accent: true,
                      ),
                      const SizedBox(height: 12),
                      _Section(title: 'Say', body: card.say),
                      const SizedBox(height: 12),
                      _Section(title: 'Do', body: card.doStep),
                      const SizedBox(height: 18),
                      if (!isPackUnlocked) ...[
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'This card is in a premium pack',
                                style: T.type.label,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Unlock this pack to save, pin, and use this card in your deck.',
                                style: T.type.body.copyWith(
                                  color: T.pal.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassCta(
                          label: 'Unlock pack',
                          onTap: () =>
                              notifier.togglePackPurchased(card.packId),
                        ),
                        const SizedBox(height: 20),
                      ] else ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            SizedBox(
                              width: 160,
                              child: GlassPill(
                                label: isSaved
                                    ? 'Remove from deck'
                                    : 'Save to deck',
                                onTap: () => notifier.toggleSaved(cardId),
                              ),
                            ),
                            SizedBox(
                              width: 150,
                              child: GlassPill(
                                label: isFavorite ? 'Unfavorite' : 'Favorite',
                                onTap: () => notifier.toggleFavorite(cardId),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: GlassPill(
                                label: isPinned ? 'Unpin' : 'Pin',
                                enabled: isPinned || !pinDisabled,
                                onTap: () async {
                                  if (isPinned) {
                                    await notifier.unpin(cardId);
                                  } else {
                                    await notifier.pin(cardId);
                                  }
                                },
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: GlassPill(
                                label: 'Share',
                                onTap: () => _copyCard(
                                  context,
                                  card.title,
                                  card.remember,
                                  card.say,
                                  card.doStep,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (pinDisabled) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Pinned deck is full (max $maxPinnedCards). Unpin one card first.',
                            style: T.type.caption.copyWith(
                              color: T.pal.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        GlassCta(
                          label: 'Use this card now',
                          onTap: () => context.push(
                            '/tantrum/card?cardId=${Uri.encodeComponent(cardId)}',
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScreenHeader(
                    title: 'Card',
                    fallbackRoute: '/tantrum/deck',
                  ),
                  const SizedBox(height: 24),
                  GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Something went wrong.',
                          style: T.type.body.copyWith(
                            fontSize: 14,
                            color: T.pal.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        GlassCta(
                          label: 'Back to Deck',
                          onTap: () => context.go('/tantrum/deck'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyCard(
    BuildContext context,
    String title,
    String remember,
    String say,
    String doStep,
  ) async {
    final payload = '$title\n\nRemember: $remember\n\nSay: $say\n\nDo: $doStep';
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

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.body,
    this.accent = false,
  });

  final String title;
  final String body;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: T.type.overline.copyWith(color: T.pal.textTertiary)),
        const SizedBox(height: 8),
        Text(
          body,
          style: (accent ? T.type.h3 : T.type.body).copyWith(
            color: T.pal.textPrimary,
          ),
        ),
      ],
    );
    if (accent) {
      return GlassCardAccent(padding: const EdgeInsets.all(20), child: content);
    }
    return GlassCard(padding: const EdgeInsets.all(20), child: content);
  }
}
