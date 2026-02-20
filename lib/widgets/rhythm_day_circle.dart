import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/settle_design_system.dart';

/// Sun→moon day circle: one full loop of the day with wake (sun), nap(s), and
/// bedtime (moon). Optional "now" marker. Gradient arc from warm (morning) to
/// cool (evening).
class RhythmDayCircle extends StatelessWidget {
  const RhythmDayCircle({
    super.key,
    required this.wakeMinutes,
    required this.bedtimeMinutes,
    required this.napMinutesList,
    this.nowMinutes,
    this.size = 200,
    this.showLabels = true,
    this.labelBuilder,
  });

  /// Minute of day (0–1439) for wake.
  final int wakeMinutes;
  /// Minute of day for bedtime.
  final int bedtimeMinutes;
  /// Minutes of day for each nap (centerline).
  final List<int> napMinutesList;
  /// Current minute of day for "you are here" dot; null to hide.
  final int? nowMinutes;
  /// Diameter of the circle.
  final double size;
  /// Whether to show time labels at anchors.
  final bool showLabels;
  /// Optional: format minute-of-day to string. If null, uses default HH:MM.
  final String Function(int minutes)? labelBuilder;

  static const double _twoPi = 2 * math.pi;

  /// Angle for minute-of-day: 0 = top (12 o'clock), clockwise. Radians.
  static double _minuteToRad(int minutes) {
    final normalized = minutes % 1440;
    return (normalized / 1440) * _twoPi;
  }

  /// Position on circle: radius from center, angle in radians. 0 rad = top.
  static Offset _position(double cx, double cy, double r, double rad) {
    return Offset(
      cx + r * math.sin(rad),
      cy - r * math.cos(rad),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = size / 2;
    final cx = r;
    final cy = r;
    final wakeRad = _minuteToRad(wakeMinutes);
    final bedRad = _minuteToRad(bedtimeMinutes);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final trackColor = isDark
        ? SettleColors.nightMuted.withValues(alpha: 0.35)
        : SettleColors.ink300.withValues(alpha: 0.25);
    final sunColor = SettleColors.warmth400;
    final moonColor = SettleColors.dusk400;
    final labelColor = isDark ? SettleColors.nightSoft : SettleColors.ink700;

    return SizedBox(
      width: size,
      height: size + (showLabels ? 36 : 0),
      child: CustomPaint(
        size: Size(size, size),
        painter: _RhythmDayCirclePainter(
          wakeRad: wakeRad,
          bedRad: bedRad,
          napRads: napMinutesList.map((m) => _minuteToRad(m)).toList(),
          nowRad: nowMinutes != null ? _minuteToRad(nowMinutes!) : null,
          center: Offset(cx, cy),
          radius: r - 14,
          trackColor: trackColor,
          sunColor: sunColor,
          moonColor: moonColor,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Sun at wake
            Positioned(
              left: _position(cx, cy, r - 14, wakeRad).dx - 12,
              top: _position(cx, cy, r - 14, wakeRad).dy - 12,
              child: Icon(Icons.wb_sunny_rounded, size: 24, color: sunColor),
            ),
            // Moon at bedtime
            Positioned(
              left: _position(cx, cy, r - 14, bedRad).dx - 12,
              top: _position(cx, cy, r - 14, bedRad).dy - 12,
              child: Icon(Icons.nightlight_round, size: 24, color: moonColor),
            ),
            if (showLabels) ...[
              _LabelAt(
                angleRad: wakeRad,
                cx: cx,
                cy: cy,
                r: r + 10,
                size: size,
                text: labelBuilder != null
                    ? labelBuilder!(wakeMinutes)
                    : _defaultLabel(wakeMinutes),
                color: labelColor,
              ),
              _LabelAt(
                angleRad: bedRad,
                cx: cx,
                cy: cy,
                r: r + 10,
                size: size,
                text: labelBuilder != null
                    ? labelBuilder!(bedtimeMinutes)
                    : _defaultLabel(bedtimeMinutes),
                color: labelColor,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _defaultLabel(int minutes) {
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    if (h < 12) {
      if (h == 0) return '12:${m.toString().padLeft(2, '0')} AM';
      return '$h:${m.toString().padLeft(2, '0')} AM';
    }
    if (h == 12) return '12:${m.toString().padLeft(2, '0')} PM';
    return '${h - 12}:${m.toString().padLeft(2, '0')} PM';
  }
}

class _LabelAt extends StatelessWidget {
  const _LabelAt({
    required this.angleRad,
    required this.cx,
    required this.cy,
    required this.r,
    required this.size,
    required this.text,
    required this.color,
  });

  final double angleRad;
  final double cx;
  final double cy;
  final double r;
  final double size;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pos = RhythmDayCircle._position(cx, cy, r, angleRad);
    final isRight = pos.dx >= cx;
    return Positioned(
      left: (pos.dx - 28).clamp(0.0, size - 56),
      top: pos.dy - 10,
      width: 56,
      child: Text(
        text,
        textAlign: isRight ? TextAlign.left : TextAlign.right,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: SettleTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _RhythmDayCirclePainter extends CustomPainter {
  _RhythmDayCirclePainter({
    required this.wakeRad,
    required this.bedRad,
    required this.napRads,
    required this.nowRad,
    required this.center,
    required this.radius,
    required this.trackColor,
    required this.sunColor,
    required this.moonColor,
  });

  final double wakeRad;
  final double bedRad;
  final List<double> napRads;
  final double? nowRad;
  final Offset center;
  final double radius;
  final Color trackColor;
  final Color sunColor;
  final Color moonColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 5.0;
    final trackRadius = radius - strokeWidth / 2;

    // Full circle track (subtle)
    canvas.drawCircle(
      center,
      trackRadius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Arc from wake to bedtime: gradient sun → moon
    final path = Path();
    path.moveTo(
      center.dx + trackRadius * math.sin(wakeRad),
      center.dy - trackRadius * math.cos(wakeRad),
    );
    final sweep = _sweepRad(wakeRad, bedRad);
    path.arcTo(
      Rect.fromCircle(center: center, radius: trackRadius),
      _radToDeg(wakeRad) + 90,
      _radToDeg(sweep),
      false,
    );
    final gradient = SweepGradient(
      startAngle: wakeRad + math.pi / 2,
      endAngle: wakeRad + math.pi / 2 + sweep,
      colors: [
        sunColor.withValues(alpha: 0.5),
        sunColor.withValues(alpha: 0.2),
        moonColor.withValues(alpha: 0.2),
        moonColor.withValues(alpha: 0.5),
      ],
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: trackRadius + 2))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // Nap dots (small circles on the track)
    for (final napRad in napRads) {
      final p = Offset(
        center.dx + trackRadius * math.sin(napRad),
        center.dy - trackRadius * math.cos(napRad),
      );
      canvas.drawCircle(
        p,
        4,
        Paint()..color = moonColor.withValues(alpha: 0.7),
      );
    }

    // "Now" dot
    if (nowRad != null) {
      final p = Offset(
        center.dx + trackRadius * math.sin(nowRad!),
        center.dy - trackRadius * math.cos(nowRad!),
      );
      canvas.drawCircle(
        p,
        5,
        Paint()..color = SettleColors.sage400,
      );
      canvas.drawCircle(
        p,
        5,
        Paint()
          ..color = SettleColors.sage400.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  /// Sweep angle (positive) from start to end going clockwise.
  double _sweepRad(double start, double end) {
    var sweep = end - start;
    if (sweep <= 0) sweep += 2 * math.pi;
    return sweep;
  }

  double _radToDeg(double rad) => rad * 180 / math.pi;

  @override
  bool shouldRepaint(covariant _RhythmDayCirclePainter oldDelegate) {
    return oldDelegate.wakeRad != wakeRad ||
        oldDelegate.bedRad != bedRad ||
        oldDelegate.nowRad != nowRad ||
        oldDelegate.center != center ||
        oldDelegate.radius != radius;
  }
}
