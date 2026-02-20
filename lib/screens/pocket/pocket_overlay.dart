import 'package:flutter/material.dart';

import '../../models/user_card.dart';
import '../../models/v2_enums.dart';
import '../../services/card_content_service.dart';
import '../../widgets/glass_pill.dart';
import '../../widgets/settle_cta.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/micro_celebration.dart';
import '../../widgets/output_card.dart';
import '../../widgets/script_card.dart';
import '../../widgets/settle_disclosure.dart';
import '../../widgets/settle_gap.dart';
import '../../widgets/settle_tappable.dart';
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
        SettleSpacing.screenPadding,
        SettleSpacing.screenPadding,
        SettleSpacing.screenPadding,
        MediaQuery.of(context).padding.bottom +
            SettleSpacing.lg +
            SettleSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pocket', style: SettleTypography.heading.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
              SettleTappable(
                onTap: onClose,
                semanticLabel: 'Close Pocket overlay',
                child: Text(
                  'Done',
                  style: SettleTypography.body.copyWith(fontWeight: FontWeight.w600, color: SettleColors.nightAccent),
                ),
              ),
            ],
          ),
          const SettleGap.md(),
          OutputCard(
            scenarioLabel: content.triggerType,
            prevent: content.prevent,
            say: content.say,
            doStep: content.doStep,
            ifEscalates: content.ifEscalates,
            context: ScriptCardContext.pocket,
            onPrimary: () => onThisHelped(card.cardId),
          ),
          const SettleGap.lg(),
          SettleCta(
            label: 'This helped',
            onTap: () => onThisHelped(card.cardId),
          ),
          const SettleGap.md(),
          SettleDisclosure(
            title: 'More options',
            subtitle: 'Use only if needed',
            children: [
              const SettleGap.sm(),
              GlassPill(
                label: 'Didn\'t work this time',
                onTap: () => onDidntWork(card.cardId),
              ),
              if (pinnedCards.length > 1) ...[
                const SettleGap.sm(),
                GlassPill(label: 'Different script', onTap: onDifferentScript),
              ],
              const SettleGap.sm(),
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
      padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pocket', style: SettleTypography.heading.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
              SettleTappable(
                onTap: onClose,
                semanticLabel: 'Close Pocket overlay',
                child: Text(
                  'Done',
                  style: SettleTypography.body.copyWith(fontWeight: FontWeight.w600, color: SettleColors.nightAccent),
                ),
              ),
            ],
          ),
          SizedBox(height: SettleSpacing.lg + SettleSpacing.sm),
          Text(
            'Pin a script from Plan or Library to see it here in the moment.',
            style: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
          ),
          SizedBox(height: SettleSpacing.lg + SettleSpacing.sm),
          SettleCta(label: 'Done', onTap: onClose),
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
