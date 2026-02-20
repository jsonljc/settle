import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../tantrum/models/tantrum_card.dart';
import '../../tantrum/providers/tantrum_module_providers.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_pill.dart';
import '../../widgets/settle_cta.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/screen_header.dart';

/// Crisis View: big SAY line, DO, IF ESCALATES, Audio button (stub), Repeat line mode.
/// Shown after 2 taps from NOW (e.g. pick card or Use protocol).
class CrisisViewScreen extends ConsumerStatefulWidget {
  const CrisisViewScreen({super.key, this.cardId});

  /// If null, first protocol card or first registry card is used.
  final String? cardId;

  @override
  ConsumerState<CrisisViewScreen> createState() => _CrisisViewScreenState();
}

class _CrisisViewScreenState extends ConsumerState<CrisisViewScreen> {
  int _step = 0; // 0 = Say, 1 = Do, 2 = If Escalates
  bool _repeatLineMode = false;

  void _playAudioStub() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Audio playback coming soon'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardAsync = ref.watch(effectiveCrisisCardProvider(widget.cardId));

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
                        title: 'Crisis View',
                        fallbackRoute: '/tantrum/capture',
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No card selected. Add and pin cards from Deck first.',
                        style: SettleTypography.body.copyWith(
                          color: SettleColors.nightSoft,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SettleCta(
                        label: 'Back to Now',
                        onTap: () => context.go('/tantrum/capture'),
                      ),
                    ],
                  );
                }
                return _CrisisContent(
                  card: card,
                  step: _step,
                  repeatLineMode: _repeatLineMode,
                  onStepChange: (s) => setState(() => _step = s),
                  onRepeatLineModeToggle: () =>
                      setState(() => _repeatLineMode = !_repeatLineMode),
                  onAudioStub: _playAudioStub,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScreenHeader(
                    title: 'Crisis View',
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
                          label: 'Back to Now',
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

class _CrisisContent extends StatelessWidget {
  const _CrisisContent({
    required this.card,
    required this.step,
    required this.repeatLineMode,
    required this.onStepChange,
    required this.onRepeatLineModeToggle,
    required this.onAudioStub,
  });

  final TantrumCard card;
  final int step;
  final bool repeatLineMode;
  final ValueChanged<int> onStepChange;
  final VoidCallback onRepeatLineModeToggle;
  final VoidCallback onAudioStub;

  @override
  Widget build(BuildContext context) {
    final sayLine = card.say;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ScreenHeader(
          title: 'Crisis View',
          subtitle: 'One step at a time',
          fallbackRoute: '/tantrum/capture',
          trailing: _AudioStubButton(),
        ),
        const SizedBox(height: 24),
        // Step dots
        Row(
          children: [
            _StepDot(label: 'Say', active: step == 0, done: step > 0),
            const SizedBox(width: 8),
            _StepDot(label: 'Do', active: step == 1, done: step > 1),
            const SizedBox(width: 8),
            _StepDot(label: 'If escalates', active: step == 2, done: step > 2),
          ],
        ),
        const SizedBox(height: 20),
        // Big SAY line (always visible in repeat mode; otherwise current step)
        if (step == 0 || repeatLineMode) ...[
          Text(
            'Say this',
            style: SettleTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8).copyWith(color: SettleColors.nightMuted),
          ),
          const SizedBox(height: 8),
          GlassCardAccent(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(child: Text(sayLine, style: SettleTypography.heading.copyWith(fontSize: 22, fontWeight: FontWeight.w700))),
                IconButton(
                  onPressed: onAudioStub,
                  icon: const Icon(Icons.volume_up_rounded),
                  color: SettleColors.nightAccent,
                ),
              ],
            ),
          ),
          if (step > 0) ...[
            const SizedBox(height: 10),
            GlassPill(
              label: repeatLineMode ? 'Hide repeat line' : 'Repeat line mode',
              onTap: onRepeatLineModeToggle,
            ),
          ],
          const SizedBox(height: 20),
        ],
        if (step == 1) ...[
          Text(
            'Do this',
            style: SettleTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8).copyWith(color: SettleColors.nightMuted),
          ),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Text(card.doStep, style: SettleTypography.heading.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 20),
        ],
        if (step == 2) ...[
          Text(
            'If it escalates',
            style: SettleTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8).copyWith(color: SettleColors.nightMuted),
          ),
          const SizedBox(height: 8),
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Text(card.ifEscalates, style: SettleTypography.heading.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 20),
        ],
        const Spacer(),
        if (step < 2)
          SettleCta(
            label: step == 0 ? 'I said it →' : 'Done →',
            onTap: () => onStepChange(step + 1),
          )
        else
          SettleCta(label: 'Done', onTap: () => context.go('/tantrum/capture')),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  const _StepDot({
    required this.label,
    required this.active,
    required this.done,
  });

  final String label;
  final bool active;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? SettleColors.nightAccent
                : done
                ? SettleColors.nightAccent.withValues(alpha: 0.5)
                : SettleSurfaces.cardDark,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: SettleTypography.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w400).copyWith(
            color: active ? SettleColors.nightAccent : SettleColors.nightMuted,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _AudioStubButton extends ConsumerWidget {
  const _AudioStubButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      onPressed: () {
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio coming soon'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
      },
      icon: Icon(
        Icons.volume_up_outlined,
        size: 22,
        color: SettleColors.nightSoft,
      ),
    );
  }
}
