import 'dart:async';

import 'package:flutter/material.dart';

import '../../widgets/settle_cta.dart';
import '../../theme/settle_design_system.dart';

const int _vagalCycleSeconds = 10; // 4 in + 6 out
const int _vagalCycles = 3;

double _vagalScale(double t) {
  if (t <= 0.4) return 0.85 + 0.15 * (t / 0.4);
  return 1.0 - 0.15 * ((t - 0.4) / 0.6);
}

/// Inline vagal breathing for Pocket "I need to regulate first". Auto-advances after 3 cycles or user taps Back.
class PocketInlineBreathe extends StatefulWidget {
  const PocketInlineBreathe({super.key, required this.onBackToScript});

  final VoidCallback onBackToScript;

  @override
  State<PocketInlineBreathe> createState() => _PocketInlineBreatheState();
}

class _PocketInlineBreatheState extends State<PocketInlineBreathe> {
  Timer? _cycleTimer;
  double _cycleT = 0;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _cycleTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted || _startTime == null) return;
      const cycleMs = _vagalCycleSeconds * 1000;
      final elapsedMs =
          DateTime.now().difference(_startTime!).inMilliseconds % cycleMs;
      final t = (elapsedMs / 1000.0) / _vagalCycleSeconds;
      setState(() => _cycleT = t.clamp(0.0, 1.0));
    });
    Timer(const Duration(seconds: _vagalCycles * _vagalCycleSeconds), () {
      if (!mounted) return;
      _cycleTimer?.cancel();
      widget.onBackToScript();
    });
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    super.dispose();
  }

  bool get _isInhale => _cycleT < 0.4;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Quick reset', style: SettleTypography.heading.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Inhale 4, exhale 6. Tap "Back to script" when ready.',
            style: SettleTypography.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: SettleColors.nightSoft),
          ),
          const SizedBox(height: 20),
          Center(child: _PocketVagalCircles(scale: _vagalScale(_cycleT))),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isInhale
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 20,
                color: SettleColors.nightAccent,
              ),
              const SizedBox(width: 6),
              Text(
                _isInhale ? 'Breathe in' : 'Breathe out',
                style: SettleTypography.body.copyWith(fontWeight: FontWeight.w600, color: SettleColors.nightAccent),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SettleCta(
            label: 'Back to script',
            onTap: () {
              _cycleTimer?.cancel();
              widget.onBackToScript();
            },
          ),
        ],
      ),
    );
  }
}

class _PocketVagalCircles extends StatelessWidget {
  const _PocketVagalCircles({required this.scale});
  final double scale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _PocketScaledCircle(
            size: 180,
            scale: scale,
            color: SettleColors.nightAccent.withValues(alpha: 0.08),
          ),
          _PocketScaledCircle(
            size: 130,
            scale: scale,
            color: SettleColors.nightAccent.withValues(alpha: 0.12),
          ),
          _PocketScaledCircle(
            size: 80,
            scale: scale,
            color: SettleColors.nightAccent.withValues(alpha: 0.18),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SettleColors.nightAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _PocketScaledCircle extends StatelessWidget {
  const _PocketScaledCircle({
    required this.size,
    required this.scale,
    required this.color,
  });

  final double size;
  final double scale;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).disableAnimations ? 1.0 : scale;
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
