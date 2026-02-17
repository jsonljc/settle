import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/repair_card.dart';
import '../../providers/playbook_provider.dart';
import '../../providers/user_cards_provider.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_chip.dart';
import '../../widgets/settle_tappable.dart';

/// Playbook: saved cards from Reset. Light themed; SettleGradients.playbook + warmth blob.
class SavedPlaybookScreen extends ConsumerWidget {
  const SavedPlaybookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(playbookRepairCardsProvider);

    return Theme(
      data: SettleTheme.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Playbook',
                  style: GoogleFonts.fraunces(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.3,
                    color: SettleColors.ink900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cards that worked for you',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w400,
                    color: SettleColors.ink400,
                  ),
                ),
                const SizedBox(height: SettleSpacing.lg),
                Expanded(
                  child: asyncList.when(
                    data: (list) => list.isEmpty
                        ? const _PlaybookEmptyState()
                        : ListView.separated(
                            physics: const BouncingScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: SettleSpacing.sm),
                            itemBuilder: (context, index) {
                              final entry = list[index];
                              return _PlaybookCard(
                                entry: entry,
                                onShare: () => _shareCard(entry.repairCard),
                                onRemove: () => ref
                                    .read(userCardsProvider.notifier)
                                    .unsave(entry.userCard.cardId),
                              );
                            },
                          ),
                    loading: () => const Center(
                      child: CircularProgressIndicator(
                        color: SettleColors.sage600,
                      ),
                    ),
                    error: (_, __) => Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: SettleSpacing.lg,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'We couldn\'t load your playbook right now.',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: SettleColors.ink500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: SettleSpacing.lg),
                            TextButton(
                              onPressed: () =>
                                  ref.invalidate(playbookRepairCardsProvider),
                              child: const Text('Try again'),
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

/// Single playbook card: title + share icon, body, chips row. GlassCard light, 16px padding.
class _PlaybookCard extends StatelessWidget {
  const _PlaybookCard({
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
    return SettleTappable(
      semanticLabel: '${card.title}. Open card',
      onTap: () => context.push('/library/saved/card/${card.id}'),
      child: GlassCard(
        variant: GlassCardVariant.light,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    card.title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.01,
                      color: SettleColors.ink800,
                    ),
                  ),
                ),
                SettleTappable(
                  semanticLabel: 'Share card',
                  onTap: onShare,
                  child: Icon(
                    Icons.ios_share,
                    size: 15,
                    color: SettleColors.ink300,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              card.body,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                fontWeight: FontWeight.w400,
                color: SettleColors.ink400,
                height: 1.5,
                letterSpacing: -0.006,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: _chipsForCard(card),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _chipsForCard(RepairCard card) {
    final chips = <Widget>[];
    chips.add(GlassChip(
      label: _contextLabel(card.context),
      domain: _contextDomain(card.context),
    ));
    chips.add(GlassChip(
      label: card.state == RepairCardState.self ? 'For you' : 'For them',
      domain: card.state == RepairCardState.self
          ? GlassChipDomain.self
          : GlassChipDomain.child,
    ));
    for (final tag in card.tags.take(2)) {
      if (tag.trim().isEmpty) continue;
      final domain = _tagDomain(tag);
      chips.add(GlassChip(
        label: tag,
        domain: domain,
      ));
    }
    return chips;
  }

  String _contextLabel(RepairCardContext c) {
    switch (c) {
      case RepairCardContext.general:
        return 'General';
      case RepairCardContext.sleep:
        return 'Sleep';
      case RepairCardContext.tantrum:
        return 'Tantrum';
    }
  }

  GlassChipDomain _contextDomain(RepairCardContext c) {
    switch (c) {
      case RepairCardContext.general:
        return GlassChipDomain.general;
      case RepairCardContext.sleep:
        return GlassChipDomain.sleep;
      case RepairCardContext.tantrum:
        return GlassChipDomain.tantrum;
    }
  }

  GlassChipDomain _tagDomain(String tag) {
    final t = tag.toLowerCase();
    if (t.contains('sleep')) return GlassChipDomain.sleep;
    if (t.contains('tantrum')) return GlassChipDomain.tantrum;
    if (t.contains('self') || t.contains('you')) return GlassChipDomain.self;
    if (t.contains('child') || t.contains('them')) return GlassChipDomain.child;
    return GlassChipDomain.general;
  }
}

class _PlaybookEmptyState extends StatelessWidget {
  const _PlaybookEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Text(
          'Cards you keep from Reset will appear here',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: SettleColors.ink400,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
