import 'package:flutter/material.dart';

import '../../models/user_card.dart';
import '../../models/v2_enums.dart';
import '../../services/card_content_service.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/micro_celebration.dart';
import '../../widgets/output_card.dart';
import '../../widgets/script_card.dart';
import '../../widgets/settle_disclosure.dart';
import 'pocket_after_log.dart';
import 'pocket_inline_breathe.dart';

/// Modal content for Pocket: top pinned script (OutputCard), CTAs, optional "regulate first" and after-log.
class PocketOverlay extends StatelessWidget {
  const PocketOverlay({
    super.key,
    required this.pinnedCards,
    required this.resolvedContent,
    required this.currentIndex,
    required this.onClose,
    required this.onThisHelped,
    required this.onDidntWork,
    required this.onRegulateFirst,
    required this.onDifferentScript,
  });

  final List<UserCard> pinnedCards;
  final List<CardContent?> resolvedContent;
  final int currentIndex;
  final VoidCallback onClose;
  final void Function(String cardId) onThisHelped;
  final void Function(String cardId) onDidntWork;
  final VoidCallback onRegulateFirst;
  final VoidCallback onDifferentScript;

  @override
  Widget build(BuildContext context) {
    final card = currentIndex < pinnedCards.length
        ? pinnedCards[currentIndex]
        : null;
    final content = card != null && currentIndex < resolvedContent.length
        ? resolvedContent[currentIndex]
        : null;

    if (content == null || card == null) {
      return _EmptyPocketContent(onClose: onClose);
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        T.space.screen,
        T.space.screen,
        T.space.screen,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pocket', style: T.type.h3),
              GestureDetector(
                onTap: onClose,
                child: Text(
                  'Done',
                  style: T.type.label.copyWith(color: T.pal.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutputCard(
            scenarioLabel: content.triggerType,
            prevent: content.prevent,
            say: content.say,
            doStep: content.doStep,
            ifEscalates: content.ifEscalates,
            context: ScriptCardContext.pocket,
            onPrimary: () => onThisHelped(card.cardId),
          ),
          const SizedBox(height: 16),
          GlassCta(
            label: 'This helped',
            onTap: () => onThisHelped(card.cardId),
          ),
          const SizedBox(height: 12),
          SettleDisclosure(
            title: 'More options',
            subtitle: 'Use only if needed',
            children: [
              const SizedBox(height: 8),
              GlassPill(
                label: 'Didn\'t work this time',
                onTap: () => onDidntWork(card.cardId),
              ),
              if (pinnedCards.length > 1) ...[
                const SizedBox(height: 8),
                GlassPill(label: 'Different script', onTap: onDifferentScript),
              ],
              const SizedBox(height: 8),
              GlassPill(
                label: 'I need to regulate first',
                onTap: onRegulateFirst,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyPocketContent extends StatelessWidget {
  const _EmptyPocketContent({required this.onClose});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: T.space.screen),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pocket', style: T.type.h3),
              GestureDetector(
                onTap: onClose,
                child: Text(
                  'Done',
                  style: T.type.label.copyWith(color: T.pal.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Pin a script from Plan or Library to see it here in the moment.',
            style: T.type.body.copyWith(color: T.pal.textSecondary),
          ),
          const SizedBox(height: 24),
          GlassCta(label: 'Done', onTap: onClose),
        ],
      ),
    );
  }
}

/// Wrapper that switches between script view, inline breathe, after-log, and celebration.
class PocketOverlayBody extends StatelessWidget {
  const PocketOverlayBody({
    super.key,
    required this.view,
    required this.pinnedCards,
    required this.resolvedContent,
    required this.currentIndex,
    required this.afterLogCardId,
    required this.afterLogOutcome,
    required this.onClose,
    required this.onThisHelped,
    required this.onDidntWork,
    required this.onRegulateFirst,
    required this.onDifferentScript,
    required this.onBackToScript,
    required this.onAfterLogSubmitted,
    required this.onCelebrationDismiss,
  });

  final PocketOverlayView view;
  final List<UserCard> pinnedCards;
  final List<CardContent?> resolvedContent;
  final int currentIndex;
  final String afterLogCardId;
  final UsageOutcome afterLogOutcome;
  final VoidCallback onClose;
  final void Function(String cardId) onThisHelped;
  final void Function(String cardId) onDidntWork;
  final VoidCallback onRegulateFirst;
  final VoidCallback onDifferentScript;
  final VoidCallback onBackToScript;
  final VoidCallback onAfterLogSubmitted;
  final VoidCallback onCelebrationDismiss;

  @override
  Widget build(BuildContext context) {
    return switch (view) {
      PocketOverlayView.script => PocketOverlay(
        pinnedCards: pinnedCards,
        resolvedContent: resolvedContent,
        currentIndex: currentIndex,
        onClose: onClose,
        onThisHelped: onThisHelped,
        onDidntWork: onDidntWork,
        onRegulateFirst: onRegulateFirst,
        onDifferentScript: onDifferentScript,
      ),
      PocketOverlayView.regulate => PocketInlineBreathe(
        onBackToScript: onBackToScript,
      ),
      PocketOverlayView.afterLog => PocketAfterLog(
        cardId: afterLogCardId,
        outcome: afterLogOutcome,
        onSubmitted: onAfterLogSubmitted,
      ),
      PocketOverlayView.celebration => MicroCelebration(
        onDismiss: onCelebrationDismiss,
      ),
    };
  }
}

enum PocketOverlayView { script, regulate, afterLog, celebration }
