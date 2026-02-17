import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_repository.dart';
import '../data/card_repository.dart';
import '../models/repair_card.dart';
import 'app_repository_provider.dart';
import 'card_repository_provider.dart';
import 'user_cards_provider.dart';

/// Session state for the Reset flow. "Another" counter resets per session.
class ResetFlowState {
  const ResetFlowState({
    this.flowContext = RepairCardContext.general,
    this.phase = ResetFlowPhase.chooseState,
    this.chosenState,
    this.currentCard,
    this.cardIdsSeen = const [],
    this.anotherCount = 0,
    this.loading = false,
  });

  final RepairCardContext flowContext;
  final ResetFlowPhase phase;
  final RepairCardState? chosenState;
  final RepairCard? currentCard;
  final List<String> cardIdsSeen;
  final int anotherCount;
  final bool loading;

  static const int maxAnother = 3;

  bool get canShowAnother => anotherCount < maxAnother;
}

enum ResetFlowPhase { chooseState, showingCard }

class ResetFlowNotifier extends StateNotifier<ResetFlowState> {
  ResetFlowNotifier({
    required CardRepository cardRepo,
    required AppRepository appRepo,
    required UserCardsNotifier userCards,
  }) : _cardRepo = cardRepo,
       _appRepo = appRepo,
       _userCards = userCards,
       super(const ResetFlowState());

  final CardRepository _cardRepo;
  final AppRepository _appRepo;
  final UserCardsNotifier _userCards;

  /// Start a new session (e.g. when entering the flow). Resets "Another" count.
  void startSession(RepairCardContext flowContext) {
    state = ResetFlowState(
      flowContext: flowContext,
      phase: ResetFlowPhase.chooseState,
    );
  }

  /// User chose self or child; draw first card.
  Future<void> selectState(RepairCardState chosen) async {
    state = ResetFlowState(
      flowContext: state.flowContext,
      phase: ResetFlowPhase.showingCard,
      chosenState: chosen,
      loading: true,
    );
    final card = await _cardRepo.pickOne(
      context: state.flowContext,
      state: chosen,
    );
    if (card == null) {
      state = ResetFlowState(
        flowContext: state.flowContext,
        phase: ResetFlowPhase.showingCard,
        chosenState: chosen,
        loading: false,
      );
      return;
    }
    state = ResetFlowState(
      flowContext: state.flowContext,
      phase: ResetFlowPhase.showingCard,
      chosenState: chosen,
      currentCard: card,
      cardIdsSeen: [card.id],
      anotherCount: 0,
      loading: false,
    );
  }

  /// Draw another card (max 3 per session). Excludes already-seen ids.
  Future<void> drawAnother() async {
    if (!state.canShowAnother || state.chosenState == null) return;
    state = ResetFlowState(
      flowContext: state.flowContext,
      phase: state.phase,
      chosenState: state.chosenState,
      currentCard: state.currentCard,
      cardIdsSeen: state.cardIdsSeen,
      anotherCount: state.anotherCount,
      loading: true,
    );
    final card = await _cardRepo.pickOneExcluding(
      excludeIds: state.cardIdsSeen.toSet(),
      context: state.flowContext,
      state: state.chosenState,
    );
    if (card == null) {
      state = ResetFlowState(
        flowContext: state.flowContext,
        phase: state.phase,
        chosenState: state.chosenState,
        currentCard: state.currentCard,
        cardIdsSeen: state.cardIdsSeen,
        // Hide "Another" once no alternate card is available.
        anotherCount: ResetFlowState.maxAnother,
        loading: false,
      );
      return;
    }
    state = ResetFlowState(
      flowContext: state.flowContext,
      phase: state.phase,
      chosenState: state.chosenState,
      currentCard: card,
      cardIdsSeen: [...state.cardIdsSeen, card.id],
      anotherCount: state.anotherCount + 1,
      loading: false,
    );
  }

  /// Save current card to Playbook and return (caller pops).
  Future<void> keep() async {
    final card = state.currentCard;
    if (card == null) return;
    await _userCards.save(card.id);
  }

  /// Persist reset event and return (caller pops). Pass [cardIdKept] if user kept one before closing.
  Future<void> close({String? cardIdKept}) async {
    final contextStr = _contextToString(state.flowContext);
    final stateStr = state.chosenState == null
        ? null
        : (state.chosenState == RepairCardState.self ? 'self' : 'child');
    await _appRepo.addResetEvent(
      context: contextStr,
      state: stateStr,
      cardIdsSeen: state.cardIdsSeen,
      cardIdKept: cardIdKept,
    );
  }

  static String _contextToString(RepairCardContext c) {
    switch (c) {
      case RepairCardContext.general:
        return 'general';
      case RepairCardContext.sleep:
        return 'sleep';
      case RepairCardContext.tantrum:
        return 'tantrum';
    }
  }
}

final resetFlowProvider =
    StateNotifierProvider<ResetFlowNotifier, ResetFlowState>((ref) {
      return ResetFlowNotifier(
        cardRepo: ref.read(cardRepositoryProvider),
        appRepo: ref.read(appRepositoryProvider),
        userCards: ref.read(userCardsProvider.notifier),
      );
    });
