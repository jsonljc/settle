import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/settle_tokens.dart';

/// A selectable option tile used throughout onboarding.
/// Renders as a glass card that lights up with accent tint when selected.
class OptionButton extends StatelessWidget {
  const OptionButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fill = selected ? T.glass.fillAccent : T.glass.fill;
    final borderColor =
        selected ? T.pal.accent.withValues(alpha: 0.4) : T.glass.border;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(T.radius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: T.glass.sigma,
            sigmaY: T.glass.sigma,
          ),
          child: AnimatedContainer(
            duration: T.anim.fast,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(T.radius.lg),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: selected ? T.pal.accent : T.pal.textSecondary,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: T.type.label.copyWith(
                          color: selected
                              ? T.pal.textPrimary
                              : T.pal.textSecondary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: T.type.caption.copyWith(
                            color: T.pal.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, size: 20, color: T.pal.accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact 2×2 grid variant — shorter padding, no subtitle.
class OptionButtonCompact extends StatelessWidget {
  const OptionButtonCompact({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fill = selected ? T.glass.fillAccent : T.glass.fill;
    final borderColor =
        selected ? T.pal.accent.withValues(alpha: 0.4) : T.glass.border;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(T.radius.md),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: T.glass.sigma,
            sigmaY: T.glass.sigma,
          ),
          child: AnimatedContainer(
            duration: T.anim.fast,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(T.radius.md),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 18,
                    color: selected ? T.pal.accent : T.pal.textSecondary,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: T.type.label.copyWith(
                      fontSize: 14,
                      color:
                          selected ? T.pal.textPrimary : T.pal.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
