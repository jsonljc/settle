import 'package:flutter/material.dart';

import '../theme/settle_design_system.dart';

/// Calm loading indicator — reassuring text with a subtle opacity pulse and
/// an optional breathing dot for visual anchor.
///
/// Replaces `CircularProgressIndicator` throughout the app.
class CalmLoading extends StatefulWidget {
  const CalmLoading({
    super.key,
    this.message = 'Getting things ready\u2026',
    this.showDot = true,
  });

  final String message;
  final bool showDot;

  @override
  State<CalmLoading> createState() => _CalmLoadingState();
}

class _CalmLoadingState extends State<CalmLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _dotScale;
  late final Animation<double> _dotOpacity;

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
    _dotScale = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _dotOpacity = Tween<double>(
      begin: 0.25,
      end: 0.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SettleAnimations.reduceMotion(context)) {
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
    final secondaryColor = SettleSemanticColors.supporting(context);
    final accentColor = SettleSemanticColors.accent(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showDot) ...[
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _dotScale.value,
                  child: Opacity(
                    opacity: _dotOpacity.value,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accentColor,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: SettleSpacing.md),
          ],
          FadeTransition(
            opacity: _opacity,
            child: Text(
              widget.message,
              style: SettleTypography.body.copyWith(color: secondaryColor),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
