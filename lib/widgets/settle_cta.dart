import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/settle_design_system.dart';

/// Primary CTA — solid fill, high contrast. No glass.
class SettleCta extends StatelessWidget {
  const SettleCta({
    super.key,
    required this.label,
    required this.onTap,
    this.compact = false,
    this.enabled = true,
    this.alignment,
    this.expand = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool compact;
  final bool enabled;
  final AlignmentGeometry? alignment;
  final bool expand;

  static const double _minHeight = 48;

  @override
  Widget build(BuildContext context) {
    final padding = compact
        ? const EdgeInsets.symmetric(
            horizontal: SettleSpacing.lg,
            vertical: SettleSpacing.sm,
          )
        : const EdgeInsets.symmetric(
            horizontal: SettleSpacing.xxl,
            vertical: SettleSpacing.lg,
          );
    const textColor = Colors.white;

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    onTap();
                  }
                : null,
            borderRadius: BorderRadius.circular(SettleRadii.pill),
            splashColor: Colors.white.withValues(alpha: 0.2),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: Container(
              constraints: const BoxConstraints(minHeight: _minHeight),
              width: expand ? double.infinity : null,
              padding: padding,
              decoration: BoxDecoration(
                color: SettleColors.sage600,
                borderRadius: BorderRadius.circular(SettleRadii.pill),
              ),
              child: Align(
                alignment: alignment ?? Alignment.center,
                child: Text(
                  label,
                  style: SettleTypography.label.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Alias for [SettleCta] for callers that used theme/glass_components.
class GlassCta extends StatelessWidget {
  const GlassCta({
    super.key,
    required this.label,
    required this.onTap,
    this.compact = false,
    this.enabled = true,
    this.alignment,
    this.expand = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool compact;
  final bool enabled;
  final AlignmentGeometry? alignment;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return SettleCta(
      label: label,
      onTap: onTap,
      compact: compact,
      enabled: enabled,
      alignment: alignment,
      expand: expand,
    );
  }
}
