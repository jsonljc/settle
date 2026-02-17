import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/v2_enums.dart';
import '../../providers/usage_events_provider.dart';
import '../../providers/user_cards_provider.dart';
import '../../services/card_content_service.dart';
import '../../theme/glass_components.dart';
import '../../widgets/pocket_fab.dart';
import 'pocket_overlay.dart';

/// FAB + modal overlay for Pocket. When [pocketEnabled], shell passes this as overlay.
/// Shows top pinned script; "This helped" / "Didn't work"; optional regulate first and after-log.
class PocketFABAndOverlay extends ConsumerStatefulWidget {
  const PocketFABAndOverlay({super.key});

  @override
  ConsumerState<PocketFABAndOverlay> createState() =>
      _PocketFABAndOverlayState();
}

class _PocketFABAndOverlayState extends ConsumerState<PocketFABAndOverlay> {
  bool _open = false;
  PocketOverlayView _view = PocketOverlayView.script;
  int _currentIndex = 0;
  String _afterLogCardId = '';
  UsageOutcome _afterLogOutcome = UsageOutcome.didntWork;

  void _close() {
    setState(() {
      _open = false;
      _view = PocketOverlayView.script;
    });
  }

  Future<void> _onThisHelped(String cardId) async {
    await ref.read(userCardsProvider.notifier).incrementUsage(cardId);
    await ref
        .read(usageEventsProvider.notifier)
        .log(
          cardId: cardId,
          outcome: UsageOutcome.great,
          regulationUsed: false,
        );
    if (!mounted) return;
    setState(() => _view = PocketOverlayView.celebration);
  }

  void _onDidntWork(String cardId) {
    setState(() {
      _view = PocketOverlayView.afterLog;
      _afterLogCardId = cardId;
      _afterLogOutcome = UsageOutcome.didntWork;
    });
  }

  void _onRegulateFirst() {
    setState(() => _view = PocketOverlayView.regulate);
  }

  void _onBackToScript() {
    setState(() => _view = PocketOverlayView.script);
  }

  void _onAfterLogSubmitted() {
    _close();
  }

  void _onDifferentScript() {
    final pinned = ref.read(pinnedUserCardsProvider);
    if (pinned.length <= 1) return;
    setState(() => _currentIndex = (_currentIndex + 1) % pinned.length);
  }

  @override
  Widget build(BuildContext context) {
    final pinnedCards = ref.watch(pinnedUserCardsProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        PocketFAB(onTap: () => setState(() => _open = true)),
        if (_open)
          Positioned.fill(
            child: GestureDetector(
              onTap: _close,
              behavior: HitTestBehavior.opaque,
              child: Container(
                color: Colors.black54,
                child: SafeArea(
                  child: Center(
                    child: GestureDetector(
                      onTap: () {},
                      child: FutureBuilder<List<CardContent>>(
                        future: CardContentService.instance.getCards(),
                        builder: (context, snapshot) {
                          final allCards = snapshot.data ?? [];
                          final byId = {for (final c in allCards) c.id: c};
                          final resolvedContent = pinnedCards
                              .map((uc) => byId[uc.cardId])
                              .toList();

                          return GlassCard(
                            padding: const EdgeInsets.all(20),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: 400,
                                maxHeight:
                                    MediaQuery.of(context).size.height * 0.75,
                              ),
                              child: PocketOverlayBody(
                                view: _view,
                                pinnedCards: pinnedCards,
                                resolvedContent: resolvedContent,
                                currentIndex: _currentIndex,
                                afterLogCardId: _afterLogCardId,
                                afterLogOutcome: _afterLogOutcome,
                                onClose: _close,
                                onThisHelped: _onThisHelped,
                                onDidntWork: _onDidntWork,
                                onRegulateFirst: _onRegulateFirst,
                                onDifferentScript: _onDifferentScript,
                                onBackToScript: _onBackToScript,
                                onAfterLogSubmitted: _onAfterLogSubmitted,
                                onCelebrationDismiss: _close,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
