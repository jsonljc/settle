import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Replaces bare [GestureDetector] with a wrapper that bundles semantics,
/// ink feedback, and minimum hit target size (48x48).
class SettleTappable extends StatelessWidget {
  const SettleTappable({
    super.key,
    required this.child,
    required this.semanticLabel,
    this.onTap,
    this.semanticHint,
    this.excludeSemantics = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String semanticLabel;
  final String? semanticHint;
  final bool excludeSemantics;

  static const double _minHitTarget = 48.0;

  @override
  Widget build(BuildContext context) {
    Widget target = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: _minHitTarget,
        minHeight: _minHitTarget,
      ),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap != null
                ? () {
                    HapticFeedback.lightImpact();
                    onTap!();
                  }
                : null,
            child: child,
          ),
        ),
      ),
    );

    if (!excludeSemantics) {
      target = Semantics(
        button: true,
        label: semanticLabel,
        hint: semanticHint,
        child: target,
      );
    }

    return target;
  }
}
