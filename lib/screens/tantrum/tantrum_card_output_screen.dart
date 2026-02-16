import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../tantrum/providers/tantrum_module_providers.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';

/// Immediate post-capture payoff: one calm card for the logged event.
class TantrumCardOutputScreen extends ConsumerWidget {
  const TantrumCardOutputScreen({super.key, this.cardId});

  final String? cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardAsync = ref.watch(effectiveCrisisCardProvider(cardId));

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
                        fallbackRoute: '/tantrum/capture',
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No card available right now.',
                        style: T.type.body.copyWith(color: T.pal.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      GlassCta(
                        label: 'Back to Capture',
                        onTap: () => context.go('/tantrum/capture'),
                      ),
                    ],
                  );
                }

                final deck = ref.watch(deckStateProvider);
                final isSaved = deck.isSaved(card.id);
                final notifier = ref.read(deckStateProvider.notifier);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ScreenHeader(
                      title: 'Card',
                      subtitle: 'One grounded step for this moment',
                      fallbackRoute: '/tantrum/capture',
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: GlassCard(
                        fill: T.pal.textPrimary.withValues(alpha: 0.08),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(card.title, style: T.type.h1),
                            const SizedBox(height: 20),
                            _CardLine(label: 'Remember', body: card.remember),
                            const SizedBox(height: 16),
                            _CardLine(label: 'Say', body: card.say),
                            const SizedBox(height: 16),
                            _CardLine(label: 'Do', body: card.doStep),
                            const Spacer(),
                            Divider(
                              color: T.glass.border.withValues(alpha: 0.8),
                              height: 1,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: GlassPill(
                                    label: isSaved
                                        ? 'Saved to deck'
                                        : 'Save to deck',
                                    onTap: () async {
                                      if (isSaved) return;
                                      await notifier.save(card.id);
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Saved to deck'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GlassPill(
                                    label: 'Share',
                                    onTap: () async {
                                      final payload =
                                          '${card.title}\n\nRemember: ${card.remember}\n\nSay: ${card.say}\n\nDo: ${card.doStep}';
                                      await Clipboard.setData(
                                        ClipboardData(text: payload),
                                      );
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Card copied to clipboard',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: GlassCta(
                                    label: 'Done',
                                    onTap: () => context.go('/tantrum/capture'),
                                    compact: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScreenHeader(
                    title: 'Card',
                    fallbackRoute: '/tantrum/capture',
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Could not load card.',
                    style: T.type.body.copyWith(color: T.pal.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  GlassCta(
                    label: 'Back to Capture',
                    onTap: () => context.go('/tantrum/capture'),
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

class _CardLine extends StatelessWidget {
  const _CardLine({required this.label, required this.body});

  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: T.type.overline.copyWith(color: T.pal.textTertiary)),
        const SizedBox(height: 6),
        Text(body, style: T.type.body.copyWith(color: T.pal.textPrimary)),
      ],
    );
  }
}
