import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/repair_card.dart';
import '../../providers/card_repository_provider.dart';
import '../../utils/share_text.dart';
import '../../providers/user_cards_provider.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/calm_loading.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/settle_gap.dart';
import '../../widgets/settle_tappable.dart';

class _PcdT {
  _PcdT._();

  static final type = _PcdTypeTokens();
  static const pal = _PcdPaletteTokens();
  static const space = _PcdSpaceTokens();
}

class _PcdTypeTokens {
  TextStyle get h3 => SettleTypography.heading.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );
  TextStyle get body => SettleTypography.body;
  TextStyle get label =>
      SettleTypography.body.copyWith(fontWeight: FontWeight.w600);
}

class _PcdPaletteTokens {
  const _PcdPaletteTokens();

  Color get textPrimary => SettleColors.nightText;
  Color get textSecondary => SettleColors.nightSoft;
}

class _PcdSpaceTokens {
  const _PcdSpaceTokens();

  double get sm => 8;
  double get lg => 16;
  double get xxl => 24;
}

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
                        style: _PcdT.type.body.copyWith(
                          color: _PcdT.pal.textSecondary,
                        ),
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
                          padding: EdgeInsets.symmetric(
                            vertical: _PcdT.space.xxl,
                            horizontal: _PcdT.space.lg,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Semantics(
                                header: true,
                                child: Text(
                                  card.title,
                                  style: _PcdT.type.h3.copyWith(
                                    color: _PcdT.pal.textPrimary,
                                  ),
                                ),
                              ),
                              SettleGap.xl(),
                              Text(
                                card.body,
                                style: _PcdT.type.body.copyWith(
                                  color: _PcdT.pal.textSecondary,
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
                                vertical: _PcdT.space.sm,
                              ),
                              child: Text(
                                'Remove',
                                style: _PcdT.type.label.copyWith(
                                  color: _PcdT.pal.textSecondary,
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
