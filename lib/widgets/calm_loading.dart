import 'package:flutter/material.dart';

import '../theme/settle_tokens.dart';

/// Calm loading indicator — reassuring text with a subtle opacity pulse.
///
/// Replaces `CircularProgressIndicator` throughout the app.
class CalmLoading extends StatefulWidget {
  const CalmLoading({super.key, this.message = 'Getting things ready…'});

  final String message;

  @override
  State<CalmLoading> createState() => _CalmLoadingState();
}

class _CalmLoadingState extends State<CalmLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _opacity = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (T.reduceMotion(context)) {
      _controller.stop();
      _controller.value = 1.0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FadeTransition(
        opacity: _opacity,
        child: Text(
          widget.message,
          style: T.type.body.copyWith(color: T.pal.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
