import 'package:flutter/material.dart';

import '../theme/settle_tokens.dart';

/// Creates an [AnimationController] that respects reduced motion.
/// When [T.reduceMotion](context) is true, duration is [Duration.zero].
AnimationController createSettleAnimation(
  TickerProvider vsync,
  BuildContext context, {
  required Duration duration,
}) {
  return AnimationController(
    vsync: vsync,
    duration: T.reduceMotion(context) ? Duration.zero : duration,
  );
}
