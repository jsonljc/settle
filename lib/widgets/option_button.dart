import 'package:flutter/material.dart';

import '../theme/settle_design_system.dart';

/// A selectable option tile used throughout onboarding.
/// Renders as a solid card that lights up with accent tint when selected.
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
    final fill = selected
        ? SettleSurfaces.tintDusk
        : SettleSurfaces.cardDark;
    final borderColor = selected
        ? SettleColors.dusk400.withValues(alpha: 0.45)
        : SettleSurfaces.cardBorderDark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(SettleRadii.surface),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 20,
                color: selected
                    ? SettleColors.nightText
                    : SettleColors.nightSoft,
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
                    style: SettleTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? SettleColors.nightText
                          : SettleColors.nightSoft,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: SettleTypography.caption.copyWith(
                        color: SettleColors.nightMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                size: 20,
                color: SettleColors.nightText,
              ),
          ],
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
    this.dense = false,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dense;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fill = selected
        ? SettleSurfaces.tintDusk
        : SettleSurfaces.cardDark;
    final borderColor = selected
        ? SettleColors.dusk400.withValues(alpha: 0.45)
        : SettleSurfaces.cardBorderDark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 10 : 14,
          vertical: dense ? 8 : 12,
        ),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(SettleRadii.sm),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: dense ? 16 : 18,
                color: selected
                    ? SettleColors.nightText
                    : SettleColors.nightSoft,
              ),
              SizedBox(width: dense ? 6 : 8),
            ],
            Flexible(
              child: Text(
                label,
                style:
                    (dense
                            ? SettleTypography.caption
                            : SettleTypography.body)
                        .copyWith(
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? SettleColors.nightText
                              : SettleColors.nightSoft,
                        ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
