import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/repair_card.dart';
import '../../providers/playbook_provider.dart';
import '../../providers/user_cards_provider.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/settle_gap.dart';
import '../../widgets/settle_tappable.dart';

/// Playbook v1: list saved repair cards (most recent first), view detail, remove, send.
class SavedPlaybookScreen extends ConsumerWidget {
  const SavedPlaybookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(playbookRepairCardsProvider);

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'My Playbook',
                  subtitle: 'Saved cards from Reset.',
                  fallbackRoute: '/library',
                ),
                SettleGap.lg(),
                Expanded(
                  child: asyncList.when(
                    data: (list) => list.isEmpty
                        ? _EmptyState()
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final entry = list[index];
                              return _PlaybookListTile(
                                entry: entry,
                                onShare: () => _shareCard(entry.repairCard),
                                onRemove: () => ref
                                    .read(userCardsProvider.notifier)
                                    .unsave(entry.userCard.cardId),
                              );
                            },
                          ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, __) => Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: T.space.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'We couldn\'t load your playbook right now.',
                              style: T.type.body.copyWith(
                                color: T.pal.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SettleGap.lg(),
                            GlassCta(
                              label: 'Try again',
                              onTap: () =>
                                  ref.invalidate(playbookRepairCardsProvider),
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

  void _shareCard(RepairCard card) {
    final text = '${card.title}\n${card.body}\n— from Settle';
    Share.share(text);
  }
}

class _PlaybookListTile extends StatelessWidget {
  const _PlaybookListTile({
    required this.entry,
    required this.onShare,
    required this.onRemove,
  });

  final PlaybookEntry entry;
  final VoidCallback onShare;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final card = entry.repairCard;
    return Padding(
      padding: EdgeInsets.only(bottom: T.space.md),
      child: SettleTappable(
        semanticLabel: '${card.title}. Open card',
        onTap: () => context.push('/library/saved/card/${card.id}'),
        child: GlassCard(
          padding: EdgeInsets.symmetric(
            vertical: T.space.lg,
            horizontal: T.space.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.title,
                          style: T.type.label.copyWith(
                            color: T.pal.textPrimary,
                          ),
                        ),
                        SettleGap.sm(),
                        Text(
                          card.body,
                          style: T.type.caption.copyWith(
                            color: T.pal.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SettleGap.md(),
              Row(
                children: [
                  SettleTappable(
                    semanticLabel: 'Send card',
                    onTap: onShare,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: T.space.xs),
                      child: Text(
                        'Send',
                        style: T.type.caption.copyWith(color: T.pal.accent),
                      ),
                    ),
                  ),
                  SettleGap.lg(),
                  SettleTappable(
                    semanticLabel: 'Remove from playbook',
                    onTap: onRemove,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: T.space.xs),
                      child: Text(
                        'Remove',
                        style: T.type.caption.copyWith(
                          color: T.pal.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: T.space.lg),
        child: Text(
          'Your playbook is empty. Save cards from Reset to get started.',
          style: T.type.body.copyWith(color: T.pal.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
