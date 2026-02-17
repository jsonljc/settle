import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/settle_disclosure.dart';

/// Step 2: Physiological regulation — vagal tone 4s in / 6s out, 3 cycles (~30s), then auto-advance.
const int _vagalInSeconds = 4;
const int _vagalOutSeconds = 6;
const int _vagalCycles = 3;
const int _vagalCycleSeconds = _vagalInSeconds + _vagalOutSeconds;

/// Curve: 0–0.4 (4s) maps to 0→1 (inhale), 0.4–1.0 (6s) maps to 1→0 (exhale).
double _vagalScale(double t) {
  if (t <= 0.4) return 0.85 + 0.15 * (t / 0.4);
  return 1.0 - 0.15 * ((t - 0.4) / 0.6);
}

class RegulateStepBreathe extends StatefulWidget {
  const RegulateStepBreathe({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<RegulateStepBreathe> createState() => _RegulateStepBreatheState();
}

class _RegulateStepBreatheState extends State<RegulateStepBreathe> {
  Timer? _cycleTimer;
  double _cycleT = 0;

  @override
  void initState() {
    super.initState();
    _cycleTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _startTime == null) return;
      final elapsedMs =
          DateTime.now().difference(_startTime!).inMilliseconds %
          (_vagalCycleSeconds * 1000);
      final t = (elapsedMs / 1000.0) / _vagalCycleSeconds;
      setState(() => _cycleT = t.clamp(0.0, 1.0));
    });
    _startTime = DateTime.now();
    Timer(const Duration(seconds: _vagalCycles * _vagalCycleSeconds), () {
      if (!mounted) return;
      _cycleTimer?.cancel();
      widget.onComplete();
    });
  }

  DateTime? _startTime;

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  int get _cyclesLeft {
    final elapsed = _startTime != null
        ? DateTime.now().difference(_startTime!).inSeconds
        : 0;
    final completed = (elapsed / _vagalCycleSeconds).floor().clamp(
      0,
      _vagalCycles,
    );
    return (_vagalCycles - completed).clamp(0, _vagalCycles);
  }

  bool get _isInhale => _cycleT < 0.4;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: T.space.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Breathe with me', style: T.type.h2),
          const SizedBox(height: 8),
          Text(
            'Inhale 4 counts, exhale 6. $_cyclesLeft ${_cyclesLeft == 1 ? "cycle" : "cycles"} left.',
            style: T.type.body.copyWith(color: T.pal.textSecondary),
          ),
          const SizedBox(height: 24),
          Center(child: _VagalBreathingCircles(scale: _vagalScale(_cycleT))),
          const SizedBox(height: 16),
          _BreathingLabel(isInhale: _isInhale),
          const SizedBox(height: 32),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        ],
      ),
    );
  }
}

class _VagalBreathingCircles extends StatelessWidget {
  const _VagalBreathingCircles({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _ScaledCircle(
            size: 220,
            scale: scale,
            color: T.pal.accent.withValues(alpha: 0.08),
          ),
          _ScaledCircle(
            size: 160,
            scale: scale,
            color: T.pal.accent.withValues(alpha: 0.12),
          ),
          _ScaledCircle(
            size: 100,
            scale: scale,
            color: T.pal.accent.withValues(alpha: 0.18),
          ),
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

class _ScaledCircle extends StatelessWidget {
  const _ScaledCircle({
    required this.size,
    required this.scale,
    required this.color,
  });

  final double size;
  final double scale;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final s = T.reduceMotion(context) ? 1.0 : scale;
    return Transform.scale(
      scale: s,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _BreathingLabel extends StatelessWidget {
  const _BreathingLabel({required this.isInhale});
  final bool isInhale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isInhale ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          size: 24,
          color: T.pal.accent,
        ),
        const SizedBox(width: 8),
        Text(
          isInhale ? 'Breathe in' : 'Breathe out',
          style: T.type.h3.copyWith(color: T.pal.accent),
        ),
      ],
    );
  }
}

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
                    fontSize: 14,
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
              style: T.type.label.copyWith(color: T.pal.accent, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
