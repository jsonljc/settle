import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/user_card.dart';
import '../../models/v2_enums.dart';
import '../../providers/usage_events_provider.dart';
import '../../providers/user_cards_provider.dart';
import '../../services/card_content_service.dart';
import '../../services/spec_policy.dart';
import '../../widgets/glass_card.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/pocket_fab.dart';
import 'pocket_overlay.dart';

/// FAB + modal overlay for Pocket. When [pocketEnabled], shell passes this as overlay.
/// Shows top pinned script; "This helped" / "Didn't work"; optional regulate first and after-log.
/// UXV2-006: Contextual ordering via path + time (_orderPocketCandidates); a11y: FAB ≥44px + semantics, overlay dismiss semantics.
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

  void _onDifferentScript(int totalCards) {
    if (totalCards <= 1) return;
    setState(() => _currentIndex = (_currentIndex + 1) % totalCards);
  }

  @override
  Widget build(BuildContext context) {
    final pinnedCards = ref.watch(pinnedUserCardsProvider);
    final path = GoRouter.of(context).routeInformationProvider.value.uri.path;
    final isNightContext = SpecPolicy.isNight(DateTime.now());

    return Stack(
      clipBehavior: Clip.none,
      children: [
        PocketFAB(
          onTap: () => setState(() {
            _open = true;
            _view = PocketOverlayView.script;
            _currentIndex = 0;
          }),
        ),
        if (_open)
          Positioned.fill(
            child: Semantics(
              label: 'Dismiss Pocket overlay',
              button: true,
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
                            final orderedCandidates = _orderPocketCandidates(
                              pinnedCards: pinnedCards,
                              byId: byId,
                              path: path,
                              isNightContext: isNightContext,
                            );
                            final orderedPinnedCards = orderedCandidates
                                .map((candidate) => candidate.card)
                                .toList();
                            final orderedResolvedContent = orderedCandidates
                                .map((candidate) => candidate.content)
                                .toList();
                            final safeIndex =
                                _currentIndex < orderedPinnedCards.length
                                ? _currentIndex
                                : 0;

                            return GlassCard(
                              padding: const EdgeInsets.all(
                                SettleSpacing.cardPadding,
                              ),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: 400,
                                  maxHeight:
                                      MediaQuery.of(context).size.height * 0.75,
                                ),
                                child: PocketOverlayBody(
                                  view: _view,
                                  pinnedCards: orderedPinnedCards,
                                  resolvedContent: orderedResolvedContent,
                                  currentIndex: safeIndex,
                                  afterLogCardId: _afterLogCardId,
                                  afterLogOutcome: _afterLogOutcome,
                                  onClose: _close,
                                  onThisHelped: _onThisHelped,
                                  onDidntWork: _onDidntWork,
                                  onRegulateFirst: _onRegulateFirst,
                                  onDifferentScript: () => _onDifferentScript(
                                    orderedPinnedCards.length,
                                  ),
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
          ),
      ],
    );
  }
}

class _PocketCandidate {
  const _PocketCandidate({
    required this.card,
    required this.content,
    required this.sourceIndex,
    required this.contextRank,
  });

  final UserCard card;
  final CardContent? content;
  final int sourceIndex;
  final int contextRank;
}

List<_PocketCandidate> _orderPocketCandidates({
  required List<UserCard> pinnedCards,
  required Map<String, CardContent> byId,
  required String path,
  required bool isNightContext,
}) {
  final preferredTriggers = _preferredTriggersForContext(
    path: path,
    isNightContext: isNightContext,
  );
  final fallbackRank = preferredTriggers.length + 1;

  final candidates = <_PocketCandidate>[
    for (var i = 0; i < pinnedCards.length; i++)
      _PocketCandidate(
        card: pinnedCards[i],
        content: byId[pinnedCards[i].cardId],
        sourceIndex: i,
        contextRank: () {
          final trigger = byId[pinnedCards[i].cardId]?.triggerType;
          if (trigger == null) return fallbackRank;
          final rank = preferredTriggers.indexOf(trigger);
          return rank == -1 ? fallbackRank : rank;
        }(),
      ),
  ];

  candidates.sort((a, b) {
    final contextCmp = a.contextRank.compareTo(b.contextRank);
    if (contextCmp != 0) return contextCmp;
    return a.sourceIndex.compareTo(b.sourceIndex);
  });
  return candidates;
}

List<String> _preferredTriggersForContext({
  required String path,
  required bool isNightContext,
}) {
  final normalizedPath = path.toLowerCase();
  if (normalizedPath.contains('/plan/moment') ||
      normalizedPath.contains('/plan/regulate') ||
      normalizedPath == '/breathe') {
    return const ['overwhelmed', 'transitions', 'bedtime_battles'];
  }

  if (isNightContext || normalizedPath.contains('/sleep')) {
    return const ['bedtime_battles', 'transitions', 'overwhelmed'];
  }

  return const [
    'public_meltdowns',
    'no_to_everything',
    'sibling_conflict',
    'transitions',
    'overwhelmed',
  ];
}
