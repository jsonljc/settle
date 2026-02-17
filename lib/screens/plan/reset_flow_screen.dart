import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/repair_card.dart';
import '../../providers/reset_flow_provider.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/settle_gap.dart';
import '../../widgets/settle_tappable.dart';

/// Reset flow: choose state (self/child) → repair card → Keep / Another (max 3) / Close.
/// Context (general, sleep, tantrum) comes from route query; default general.
class ResetFlowScreen extends ConsumerStatefulWidget {
  const ResetFlowScreen({super.key, this.contextQuery = 'general'});

  /// Route query value: general, sleep, or tantrum.
  final String contextQuery;

  static RepairCardContext contextFromQuery(String? q) {
    switch ((q ?? 'general').trim().toLowerCase()) {
      case 'sleep':
        return RepairCardContext.sleep;
      case 'tantrum':
        return RepairCardContext.tantrum;
      default:
        return RepairCardContext.general;
    }
  }

  @override
  ConsumerState<ResetFlowScreen> createState() => _ResetFlowScreenState();
}

class _ResetFlowScreenState extends ConsumerState<ResetFlowScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final flowContext = ResetFlowScreen.contextFromQuery(widget.contextQuery);
      ref.read(resetFlowProvider.notifier).startSession(flowContext);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetFlowProvider);
    final notifier = ref.read(resetFlowProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: T.space.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHeader(title: 'Reset', fallbackRoute: '/plan'),
              SettleGap.xl(),
              if (state.phase == ResetFlowPhase.chooseState) ...[
                _buildStatePicker(context, notifier),
              ] else ...[
                _buildCardView(context, state, notifier),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatePicker(BuildContext context, ResetFlowNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Who needs the reset?',
          style: T.type.h3.copyWith(color: T.pal.textPrimary),
        ),
        SettleGap.lg(),
        SettleTappable(
          semanticLabel: 'For me',
          onTap: () => notifier.selectState(RepairCardState.self),
          child: GlassCard(
            padding: EdgeInsets.symmetric(
              vertical: T.space.xl,
              horizontal: T.space.lg,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline_rounded,
                  size: 28,
                  color: T.pal.textSecondary,
                ),
                SettleGap.md(),
                Text(
                  'For me',
                  style: T.type.label.copyWith(color: T.pal.textPrimary),
                ),
              ],
            ),
          ),
        ),
        SettleGap.md(),
        SettleTappable(
          semanticLabel: 'For my child',
          onTap: () => notifier.selectState(RepairCardState.child),
          child: GlassCard(
            padding: EdgeInsets.symmetric(
              vertical: T.space.xl,
              horizontal: T.space.lg,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.child_care_outlined,
                  size: 28,
                  color: T.pal.textSecondary,
                ),
                SettleGap.md(),
                Text(
                  'For my child',
                  style: T.type.label.copyWith(color: T.pal.textPrimary),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardView(
    BuildContext context,
    ResetFlowState state,
    ResetFlowNotifier notifier,
  ) {
    if (state.loading) {
      return Expanded(
        child: Center(child: CircularProgressIndicator(color: T.pal.accent)),
      );
    }

    final card = state.currentCard;
    if (card == null) {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              child: Text(
                'No card for this combination right now.',
                style: T.type.body.copyWith(color: T.pal.textSecondary),
              ),
            ),
            SettleGap.lg(),
            Center(
              child: SettleTappable(
                semanticLabel: 'Close without keeping',
                onTap: () => _close(notifier, null),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: T.space.sm),
                  child: Text(
                    'Close',
                    style: T.type.label.copyWith(color: T.pal.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassCard(
              padding: EdgeInsets.symmetric(
                vertical: T.space.xxl,
                horizontal: T.space.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      card.title,
                      style: T.type.h3.copyWith(color: T.pal.textPrimary),
                    ),
                  ),
                  SettleGap.xl(),
                  Text(
                    _maxSentences(card.body),
                    style: T.type.body.copyWith(
                      color: T.pal.textSecondary,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            SettleGap.xxl(),
            GlassCta(label: 'Send', onTap: () => _share(card)),
            SettleGap.lg(),
            GlassCta(label: 'Keep', onTap: () => _keep(notifier, card.id)),
            SettleGap.lg(),
            if (state.canShowAnother)
              Center(
                child: SettleTappable(
                  semanticLabel: 'Another card',
                  onTap: () => notifier.drawAnother(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: T.space.sm),
                    child: Text(
                      'Another',
                      style: T.type.label.copyWith(color: T.pal.accent),
                    ),
                  ),
                ),
              ),
            if (state.canShowAnother) SettleGap.sm(),
            Center(
              child: SettleTappable(
                semanticLabel: 'Close without keeping',
                onTap: () => _close(notifier, null),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: T.space.sm),
                  child: Text(
                    'Close',
                    style: T.type.label.copyWith(color: T.pal.textSecondary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _keep(ResetFlowNotifier notifier, String cardIdKept) async {
    await notifier.keep();
    await notifier.close(cardIdKept: cardIdKept);
    if (!mounted) return;
    _exitFlow();
  }

  Future<void> _close(ResetFlowNotifier notifier, String? cardIdKept) async {
    await notifier.close(cardIdKept: cardIdKept);
    if (!mounted) return;
    _exitFlow();
  }

  void _exitFlow() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/plan');
  }

  void _share(RepairCard card) {
    final text = '${card.title}\n${card.body}\n— from Settle';
    Share.share(text);
  }

  String _maxSentences(String text, {int max = 3}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    final matches = RegExp(r'[^.!?]+(?:[.!?]|$)')
        .allMatches(trimmed)
        .map((m) => m.group(0)!.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (matches.length <= max) return trimmed;
    return matches.take(max).join(' ');
  }
}
