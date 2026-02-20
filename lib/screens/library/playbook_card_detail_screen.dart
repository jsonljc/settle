import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/repair_card.dart';
import '../../providers/card_repository_provider.dart';
import '../../utils/share_text.dart';
import '../../providers/user_cards_provider.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/settle_cta.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/calm_loading.dart';
import '../../widgets/gradient_background.dart';
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
            body: GradientBackgroundFromRoute(
              child: const Center(child: CalmLoading(message: 'Loading card…')),
            ),
          );
        }
        if (card == null) {
          return Scaffold(
            body: GradientBackgroundFromRoute(
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SettleSpacing.screenPadding,
                  ),
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
                        style: SettleTypography.body.copyWith(
                          color: SettleColors.nightSoft,
                        ),
                      ),
                      SettleGap.lg(),
                      SettleCta(
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
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  card.title,
                                  style: SettleTypography.heading.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: SettleColors.nightText,
                                  ),
                                ),
                              ),
                              SettleGap.xl(),
                              Text(
                                card.body,
                                style: SettleTypography.body.copyWith(
                                  color: SettleColors.nightSoft,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SettleGap.xxl(),
                        SettleCta(label: 'Send', onTap: () => _share(context)),
                        SettleGap.lg(),
                        Center(
                          child: SettleTappable(
                            semanticLabel: 'Remove from playbook',
                            onTap: () => _remove(context, ref),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                              ),
                              child: Text(
                                'Remove',
                                style: SettleTypography.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: SettleColors.nightSoft,
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
    final text = buildCardShareText(card.title, card.body);
    Share.share(text);
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    await ref.read(userCardsProvider.notifier).unsave(card.id);
    if (!context.mounted) return;
    context.pop();
  }
}
