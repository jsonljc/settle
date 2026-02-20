import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';

import '../../tantrum/providers/tantrum_module_providers.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/settle_cta.dart';
import '../../theme/settle_design_system.dart';
import '../../utils/share_text.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/output_card.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/script_card.dart';

/// Immediate post-capture payoff: one calm card for the logged event.
class TantrumCardOutputScreen extends ConsumerWidget {
  const TantrumCardOutputScreen({super.key, this.cardId});

  final String? cardId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardAsync = ref.watch(effectiveCrisisCardProvider(cardId));

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SettleSpacing.screenPadding,
            ),
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
                        style: SettleTypography.body.copyWith(
                          color: SettleColors.nightSoft,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SettleCta(
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
                      child: OutputCard(
                        context: ScriptCardContext.crisis,
                        scenarioLabel: card.title,
                        prevent: card.remember,
                        say: card.say,
                        doStep: card.doStep,
                        ifEscalates: card.ifEscalates,
                        onPrimary: () => context.go('/tantrum/capture'),
                        onSave: () async {
                          if (isSaved) return;
                          await notifier.save(card.id);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saved to deck'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        onShare: () async {
                          final body = [
                            'Remember: ${card.remember}',
                            'Say: ${card.say}',
                            'Do: ${card.doStep}',
                          ].join('\n\n');
                          final payload = buildCardShareText(card.title, body);
                          await Share.share(payload);
                        },
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
                  GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Something went wrong.',
                          style: SettleTypography.body.copyWith(
                            fontSize: 14,
                            color: SettleColors.nightSoft,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SettleCta(
                          label: 'Back to Capture',
                          onTap: () => context.go('/tantrum/capture'),
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
}
