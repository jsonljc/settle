import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/repair_card.dart';
import '../../providers/card_repository_provider.dart';
import '../../providers/user_cards_provider.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/settle_gap.dart';
import '../../widgets/settle_tappable.dart';

/// View a single playbook (repair) card — same display as Reset card view.
/// Send (text-only) and Remove (single tap, no modal).
class PlaybookCardDetailScreen extends ConsumerWidget {
  const PlaybookCardDetailScreen({super.key, required this.cardId});

  final String cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(cardRepositoryProvider);
    return FutureBuilder<RepairCard?>(
      future: repo.getById(cardId),
      builder: (context, snapshot) {
        final card = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: SettleBackground(
              child: Center(
                child: CircularProgressIndicator(color: T.pal.accent),
              ),
            ),
          );
        }
        if (card == null) {
          return Scaffold(
            body: SettleBackground(
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: T.space.screen),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ScreenHeader(
                        title: 'Card',
                        fallbackRoute: '/library/saved',
                      ),
                      SettleGap.xl(),
                      Text(
                        'This card is no longer available.',
                        style: T.type.body.copyWith(color: T.pal.textSecondary),
                      ),
                      SettleGap.lg(),
                      GlassCta(
                        label: 'Back to Playbook',
                        onTap: () => context.go('/library/saved'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }
        return _Content(card: card);
      },
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.card});

  final RepairCard card;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ScreenHeader(
                  title: 'Playbook',
                  fallbackRoute: '/library/saved',
                ),
                SettleGap.xl(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        GlassCard(
                          padding: EdgeInsets.symmetric(
                            vertical: T.space.xxl,
                            horizontal: T.space.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  card.title,
                                  style: T.type.h3.copyWith(
                                    color: T.pal.textPrimary,
                                  ),
                                ),
                              ),
                              SettleGap.xl(),
                              Text(
                                card.body,
                                style: T.type.body.copyWith(
                                  color: T.pal.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SettleGap.xxl(),
                        GlassCta(label: 'Send', onTap: () => _share(context)),
                        SettleGap.lg(),
                        Center(
                          child: SettleTappable(
                            semanticLabel: 'Remove from playbook',
                            onTap: () => _remove(context, ref),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: T.space.sm,
                              ),
                              child: Text(
                                'Remove',
                                style: T.type.label.copyWith(
                                  color: T.pal.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
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

  void _share(BuildContext context) {
    final text = 'Repair words to use right now:\n${card.title}\n${card.body}';
    Share.share(text);
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    await ref.read(userCardsProvider.notifier).unsave(card.id);
    if (!context.mounted) return;
    context.pop();
  }
}
