import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../tantrum/providers/tantrum_module_providers.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';

/// Card detail: full content + "Pin to Protocol" (max 10).
class CardDetailScreen extends ConsumerWidget {
  const CardDetailScreen({
    super.key,
    required this.cardId,
  });

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardAsync = ref.watch(tantrumCardByIdProvider(cardId));
    final pinnedIds = ref.watch(protocolPinnedIdsProvider);
    final notifier = ref.read(protocolPinnedIdsProvider.notifier);
    final isPinned = pinnedIds.contains(cardId);
    final atMax = notifier.isAtMax && !isPinned;

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: cardAsync.when(
              data: (card) {
                if (card == null) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ScreenHeader(
                        title: 'Card',
                        fallbackRoute: '/tantrum/cards',
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Card not found.',
                        style: T.type.body.copyWith(color: T.pal.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      GlassCta(
                        label: 'Back to CARDS',
                        onTap: () => context.go('/tantrum/cards'),
                      ),
                    ],
                  );
                }
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ScreenHeader(
                        title: card.title,
                        fallbackRoute: '/tantrum/cards',
                      ),
                      const SizedBox(height: 24),
                      _Section(
                        title: 'Say this',
                        body: card.say,
                        accent: true,
                      ),
                      const SizedBox(height: 16),
                      _Section(
                        title: 'Do this',
                        body: card.doStep,
                      ),
                      const SizedBox(height: 16),
                      _Section(
                        title: 'If it escalates',
                        body: card.ifEscalates,
                      ),
                      const SizedBox(height: 24),
                      if (isPinned)
                        GlassPill(
                          label: 'Pinned to Protocol',
                          onTap: () async {
                            await notifier.unpin(cardId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Removed from Protocol'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        )
                      else if (atMax)
                        Text(
                          'Protocol is full (10 cards). Unpin one in CARDS to add another.',
                          style: T.type.caption.copyWith(
                            color: T.pal.textSecondary,
                          ),
                        )
                      else
                        GlassCta(
                          label: 'Pin to Protocol',
                          onTap: () async {
                            final ok = await notifier.pin(cardId);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? 'Added to Protocol'
                                        : 'Protocol is full',
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                        ),
                      const SizedBox(height: 16),
                      GlassPill(
                        label: 'Use in Crisis View',
                        onTap: () => context.push(
                          '/tantrum/crisis?cardId=${Uri.encodeComponent(cardId)}',
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScreenHeader(
                    title: 'Card',
                    fallbackRoute: '/tantrum/cards',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Something went wrong.',
                    style: T.type.body.copyWith(color: T.pal.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  GlassCta(
                    label: 'Back to CARDS',
                    onTap: () => context.go('/tantrum/cards'),
                  ),
                ],
              ),
            ),
          ),
        ),
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
        Text(
          title,
          style: T.type.overline.copyWith(color: T.pal.textTertiary),
        ),
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
      return GlassCardAccent(
        padding: const EdgeInsets.all(20),
        child: content,
      );
    }
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: content,
    );
  }
}
