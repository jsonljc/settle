import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'settle_tokens.dart';

/// Extension that conditionally applies a flutter_animate entry animation.
/// When reduce-motion is on, the widget is returned unchanged (instant).
extension ReduceMotionAnimate on Widget {
  /// Fade-in + moveY entry animation, skipped when reduce-motion is active.
  Widget entryFadeIn(
    BuildContext context, {
    Duration? duration,
    Duration delay = Duration.zero,
    double moveY = 12,
  }) {
    if (T.reduceMotion(context)) return this;
    return animate(delay: delay)
        .fadeIn(duration: duration ?? T.anim.normal)
        .moveY(begin: moveY, end: 0);
  }

  /// Fade-in + moveX entry animation, skipped when reduce-motion is active.
  Widget entrySlideIn(
    BuildContext context, {
    Duration? duration,
    Duration delay = Duration.zero,
    double moveX = 16,
  }) {
    if (T.reduceMotion(context)) return this;
    return animate(delay: delay)
        .fadeIn(duration: duration ?? 300.ms)
        .moveX(begin: moveX, end: 0, duration: duration ?? 300.ms);
  }

  /// Fade-in + scale entry animation, skipped when reduce-motion is active.
  Widget entryScaleIn(
    BuildContext context, {
    Duration? duration,
    Duration delay = Duration.zero,
    double scaleBegin = 0.95,
  }) {
    if (T.reduceMotion(context)) return this;
    return animate(delay: delay)
        .fadeIn(duration: duration ?? 300.ms)
        .scale(
          begin: Offset(scaleBegin, scaleBegin),
          end: const Offset(1, 1),
          duration: duration ?? 300.ms,
        );
  }

  /// Simple fade-in, skipped when reduce-motion is active.
  Widget entryFadeOnly(
    BuildContext context, {
    Duration? duration,
    Duration delay = Duration.zero,
  }) {
    if (T.reduceMotion(context)) return this;
    return animate(delay: delay).fadeIn(duration: duration ?? 300.ms);
  }
}
