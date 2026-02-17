import 'package:flutter/material.dart';

import '../theme/glass_components.dart';
import '../theme/settle_tokens.dart';

/// Short celebratory moment after "worked great" — dismiss by tap or after [duration].
class MicroCelebration extends StatefulWidget {
  const MicroCelebration({
    super.key,
    this.message = 'That worked. Small win.',
    this.duration = const Duration(seconds: 2),
    required this.onDismiss,
  });

  final String message;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<MicroCelebration> createState() => _MicroCelebrationState();
}

class _MicroCelebrationState extends State<MicroCelebration> {
  @override
  void initState() {
    super.initState();
    Future.delayed(widget.duration, () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: T.space.screen),
          child: GlassCardAccent(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.celebration_rounded,
                  size: 40,
                  color: T.pal.accent,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.message,
                  style: T.type.h3,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to close',
                  style: T.type.caption.copyWith(color: T.pal.textTertiary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
