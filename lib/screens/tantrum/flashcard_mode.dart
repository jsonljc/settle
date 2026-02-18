import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/tantrum_providers.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/gradient_background.dart';
import 'tantrum_unavailable.dart';

class _FmT {
  _FmT._();

  static final type = _FmTypeTokens();
  static const pal = _FmPaletteTokens();
  static const anim = _FmAnimTokens();

  static bool reduceMotion(BuildContext context) =>
      MediaQuery.of(context).disableAnimations;
}

class _FmTypeTokens {
  TextStyle get h3 => SettleTypography.heading.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );
  TextStyle get caption => SettleTypography.caption.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
}

class _FmPaletteTokens {
  const _FmPaletteTokens();

  Color get accent => SettleColors.nightAccent;
  Color get textSecondary => SettleColors.nightSoft;
  Color get textTertiary => SettleColors.nightMuted;
}

class _FmAnimTokens {
  const _FmAnimTokens();

  Duration get normal => const Duration(milliseconds: 250);
}

// Deprecated in IA cleanup PR6. This legacy tantrum surface is no longer
// reachable from production routes and is retained only for internal reference.
class FlashcardModeScreen extends ConsumerStatefulWidget {
  const FlashcardModeScreen({super.key});

  @override
  ConsumerState<FlashcardModeScreen> createState() =>
      _FlashcardModeScreenState();
}

class _FlashcardModeScreenState extends ConsumerState<FlashcardModeScreen> {
  static const _breathSeconds = 10;

  late Timer _timer;
  int _secondsLeft = _breathSeconds;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        _timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  bool get _showBreathingGate => _secondsLeft > 0;

  @override
  Widget build(BuildContext context) {
    final hasTantrumSupport = ref.watch(hasTantrumFeatureProvider);
    if (!hasTantrumSupport) {
      return const TantrumUnavailableView(title: 'Flashcard');
    }

    final lines = ref.watch(flashcardProvider);

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SettleSpacing.screenPadding,
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () =>
                        context.canPop() ? context.pop() : context.go('/now'),
                    child: Text(
                      'back',
                      style: _FmT.type.caption.copyWith(
                        color: _FmT.pal.textTertiary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: _FmT.anim.normal,
                      child: _showBreathingGate
                          ? _BreathingGate(secondsLeft: _secondsLeft)
                          : Semantics(
                              label: 'Flashcard guidance. Three lines only.',
                              child: GlassCardDark(
                                key: const ValueKey('flashcard'),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 22,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (final line in lines) ...[
                                      Text(
                                        line,
                                        style: _FmT.type.h3.copyWith(
                                          fontSize: 20,
                                          height: 1.35,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      if (line != lines.last)
                                        const SizedBox(height: 10),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
                if (!_showBreathingGate) ...[
                  GlassCta(
                    label: 'End hard moment',
                    onTap: () =>
                        context.push('/home/tantrum/debrief?flashcard=1'),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => context.go('/now'),
                    child: Text(
                      'Not now',
                      style: _FmT.type.caption.copyWith(
                        color: _FmT.pal.textSecondary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BreathingGate extends StatelessWidget {
  const _BreathingGate({required this.secondsLeft});

  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('breath'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _Pulse(size: 180, alpha: 0.08),
              _Pulse(size: 128, alpha: 0.12, delayMs: 400),
              _Pulse(size: 82, alpha: 0.18, delayMs: 800),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _FmT.pal.accent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text('One breath first', style: _FmT.type.h3),
        const SizedBox(height: 4),
        Text(
          '$secondsLeft s',
          style: _FmT.type.caption.copyWith(color: _FmT.pal.textSecondary),
        ),
      ],
    );
  }
}

class _Pulse extends StatelessWidget {
  const _Pulse({required this.size, required this.alpha, this.delayMs = 0});

  final double size;
  final double alpha;
  final int delayMs;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _FmT.pal.accent.withValues(alpha: alpha),
        shape: BoxShape.circle,
      ),
    );
    if (_FmT.reduceMotion(context)) return circle;
    return circle
        .animate(onPlay: (c) => c.repeat(reverse: true), delay: delayMs.ms)
        .scale(
          begin: const Offset(0.86, 0.86),
          end: const Offset(1.0, 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
  }
}
