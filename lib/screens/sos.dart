import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../theme/glass_components.dart';
import '../widgets/settle_disclosure.dart';
import '../theme/settle_design_system.dart';
import '../theme/settle_tokens.dart';
import '../widgets/gradient_background.dart';

/// SOS Screen — ZERO interaction required. Auto-cycles everything.
///
/// Concentric breathing circles (8s period, staggered 1.5s offsets).
/// Box breathing phases auto-advance every 5s.
/// Permission statement + crisis resources always visible.
class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  static const _phases = ['Breathe in', 'Hold', 'Breathe out', 'Hold'];
  static const _selfRegScripts = [
    'I am the adult. I am safe.',
    'This is a hard moment. Breathe.',
    'I can take this one step at a time.',
    'My child is having a hard time, and I can stay steady.',
  ];

  int _phase = 0;
  int _scriptIndex = 0;
  late Timer _phaseTimer;

  @override
  void initState() {
    super.initState();
    // Auto-advance breathing phase every 5 seconds
    _phaseTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() {
          _phase = (_phase + 1) % _phases.length;
          _scriptIndex = (_scriptIndex + 1) % _selfRegScripts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _phaseTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Column(
          children: [
            const SizedBox(height: 12),
            // Exit — keep this low-emphasis in calm/overnight contexts.
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () =>
                      context.canPop() ? context.pop() : context.go('/now'),
                  child: Text(
                    'back',
                    style: T.type.caption.copyWith(color: T.pal.textTertiary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding + 8),
              child: Column(
                children: [Text('Take a Breath', style: T.type.h2)],
              ),
            ),
            const SizedBox(height: 20),

            // ── Breathing circles ──
            Expanded(
              flex: 3,
              child: Center(child: _BreathingCircles(phase: _phase)),
            ),

            // ── Box breathing phase labels ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
              child: _BreathingLabels(phase: _phase),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding + 8),
              child: AnimatedSwitcher(
                duration: T.anim.normal,
                child: Text(
                  _selfRegScripts[_scriptIndex],
                  key: ValueKey(_scriptIndex),
                  textAlign: TextAlign.center,
                  style: T.type.caption.copyWith(
                    color: T.pal.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── Permission statement ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding + 8),
              child: Text(
                'If you need a pause, it is okay to place baby in a safe crib '
                'and step away for a few minutes.',
                textAlign: TextAlign.center,
                style: T.type.body.copyWith(
                  color: T.pal.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Crisis resources ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: SettleDisclosure(
                  title: 'Need to talk to someone?',
                  subtitle: 'Open to view call or text options.',
                  children: const [
                    SizedBox(height: 8),
                    _CrisisResource(
                      name: '988 Suicide & Crisis Lifeline',
                      number: '988',
                      note: '24/7 · call or text',
                    ),
                    SizedBox(height: 10),
                    _CrisisResource(
                      name: 'Postpartum Support International',
                      number: '1-800-944-4773',
                      note: '24/7 · call or text',
                    ),
                    SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    ),
    );
  }
}

// ─────────────────────────────────────────────
//  Concentric Breathing Circles
// ─────────────────────────────────────────────

class _BreathingCircles extends StatelessWidget {
  const _BreathingCircles({required this.phase});
  final int phase;

  @override
  Widget build(BuildContext context) {
    // Three concentric circles, staggered 1.5s offsets, 8s period
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle
          _PulsingCircle(
            size: 220,
            delay: 0,
            color: T.pal.accent.withValues(alpha: 0.08),
          ),
          // Middle circle
          _PulsingCircle(
            size: 160,
            delay: 1500,
            color: T.pal.accent.withValues(alpha: 0.12),
          ),
          // Inner circle
          _PulsingCircle(
            size: 100,
            delay: 3000,
            color: T.pal.accent.withValues(alpha: 0.18),
          ),
          // Center dot
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: T.pal.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingCircle extends StatelessWidget {
  const _PulsingCircle({
    required this.size,
    required this.delay,
    required this.color,
  });

  final double size;
  final int delay;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
    if (T.reduceMotion(context)) return circle;
    return circle
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
          delay: Duration(milliseconds: delay),
        )
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1.0, 1.0),
          duration: T.anim.sosBreathe,
          curve: Curves.easeInOut,
        );
  }
}

// ─────────────────────────────────────────────
//  Box Breathing Labels
// ─────────────────────────────────────────────

class _BreathingLabels extends StatelessWidget {
  const _BreathingLabels({required this.phase});
  final int phase;

  static const _labels = ['Breathe in', 'Hold', 'Breathe out', 'Hold'];
  static const _icons = [
    Icons.arrow_upward_rounded,
    Icons.pause_rounded,
    Icons.arrow_downward_rounded,
    Icons.pause_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(4, (i) {
        final isActive = i == phase;
        return AnimatedOpacity(
          duration: T.anim.normal,
          opacity: isActive ? 1.0 : 0.25,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _icons[i],
                size: 20,
                color: isActive ? T.pal.textPrimary : T.pal.textTertiary,
              ),
              const SizedBox(height: 4),
              Text(
                _labels[i],
                style: T.type.caption.copyWith(
                  color: isActive ? T.pal.textPrimary : T.pal.textTertiary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
//  Crisis Resource Card
// ─────────────────────────────────────────────

class _CrisisResource extends StatelessWidget {
  const _CrisisResource({
    required this.name,
    required this.number,
    required this.note,
  });

  final String name;
  final String number;
  final String note;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: T.type.label.copyWith(
                    color: T.pal.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note,
                  style: T.type.caption.copyWith(color: T.pal.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: T.glass.fillAccent,
              borderRadius: BorderRadius.circular(T.radius.pill),
            ),
            child: Text(
              number,
              style: SettleTypography.body.copyWith(
                color: T.pal.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
