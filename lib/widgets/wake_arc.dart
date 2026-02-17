import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/settle_tokens.dart';

/// Wake window arc — 164×164 CustomPainter, 6px rounded stroke.
///
/// Per spec:
///   Background arc: white 4%, full 360°.
///   Progress arc: dynamic color from arc tokens, sweep = progress × 2π.
///   Glow shadow via MaskFilter.blur on the progress arc.
///   Animated with AnimationController for smooth transitions.
class WakeArc extends StatefulWidget {
  const WakeArc({
    super.key,
    required this.progress,
    required this.color,
    this.size = 164,
    required this.child,
  });

  /// 0.0–1.0+ progress through the wake window.
  final double progress;

  /// The arc fill color (from guidance provider / arc tokens).
  final Color color;

  /// Diameter of the arc. Defaults to 164 per spec.
  final double size;

  /// Content rendered inside the arc (minutes stat, etc.).
  final Widget child;

  @override
  State<WakeArc> createState() => _WakeArcState();
}

class _WakeArcState extends State<WakeArc> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnim;
  late Animation<Color?> _colorAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: T.anim.slow, vsync: this);
    _progressAnim = Tween<double>(
      begin: widget.progress,
      end: widget.progress,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _colorAnim = ColorTween(
      begin: widget.color,
      end: widget.color,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = T.reduceMotion(context)
        ? Duration.zero
        : T.anim.slow;
  }

  @override
  void didUpdateWidget(WakeArc oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress ||
        oldWidget.color != widget.color) {
      _progressAnim = Tween<double>(
        begin: _progressAnim.value,
        end: widget.progress,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _colorAnim = ColorTween(
        begin: _colorAnim.value,
        end: widget.color,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _WakeArcPainter(
            progress: _progressAnim.value.clamp(0.0, 1.0),
            color: _colorAnim.value ?? widget.color,
          ),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(child: widget.child),
          ),
        );
      },
    );
  }
}

class _WakeArcPainter extends CustomPainter {
  _WakeArcPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  static const _strokeWidth = 6.0;
  static const _startAngle = -pi / 2; // 12 o'clock

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - _strokeWidth / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // --- Background arc: white 4%, full circle ---
    final bgPaint = Paint()
      ..color =
          const Color(0x0AFFFFFF) // white ~4%
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, _startAngle, 2 * pi, false, bgPaint);

    if (progress <= 0) return;

    final sweep = progress * 2 * pi;

    // --- Glow shadow behind the progress arc ---
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = _strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawArc(rect, _startAngle, sweep, false, glowPaint);

    // --- Progress arc ---
    final progressPaint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(rect, _startAngle, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(_WakeArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
