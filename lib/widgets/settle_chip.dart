import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/settle_design_system.dart';

/// Variant of chip used in the Settle design system.
enum SettleChipVariant {
  /// Tag filter (e.g. plan progress tags). Selected: accent fill + border.
  tag,

  /// Action chip (e.g. rhythm actions). Selected: accent fill; border always subtle.
  action,

  /// Frequency or option chip (e.g. settings). Selected: accent fill + soft accent border; optional icon.
  frequency,
}

/// Shared chip widget replacing ad-hoc _TagChip, _ActionChip, _FrequencyChip.
/// Brightness-aware: works on both light and dark backgrounds.
class SettleChip extends StatelessWidget {
  const SettleChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.variant,
    this.icon,
    this.count,
    this.semanticLabel,
    this.semanticHint,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final SettleChipVariant variant;
  final IconData? icon;
  final int? count;
  final String? semanticLabel;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final effectiveLabel = semanticLabel ?? label;
    final hint = semanticHint ?? 'Double tap to select';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (Color fill, Color borderColor, Color textColor, TextStyle textStyle) =
        _resolveColors(isDark);

    final displayLabel = count != null ? '$label ($count)' : label;

    return Semantics(
      button: true,
      selected: selected,
      label: effectiveLabel,
      hint: hint,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap != null
              ? () {
                  HapticFeedback.selectionClick();
                  onTap!();
                }
              : null,
          borderRadius: BorderRadius.circular(SettleRadii.pill),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: SettleSpacing.md,
              vertical: SettleSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(SettleRadii.pill),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: textColor),
                  SizedBox(width: SettleSpacing.sm),
                ],
                Text(displayLabel, style: textStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }

  (Color, Color, Color, TextStyle) _resolveColors(bool isDark) {
    Color fill;
    Color borderColor;
    Color textColor;

    if (isDark) {
      switch (variant) {
        case SettleChipVariant.tag:
          fill = selected
              ? SettleColors.dusk600.withValues(alpha: 0.18)
              : SettleSurfaces.cardDark;
          borderColor = selected
              ? SettleColors.dusk400.withValues(alpha: 0.50)
              : SettleSurfaces.cardBorderDark;
          textColor = selected ? SettleColors.nightText : SettleColors.nightSoft;
        case SettleChipVariant.action:
          fill = selected
              ? SettleColors.dusk600.withValues(alpha: 0.16)
              : SettleSurfaces.cardDark;
          borderColor = SettleSurfaces.cardBorderDark;
          textColor = selected ? SettleColors.nightText : SettleColors.nightSoft;
        case SettleChipVariant.frequency:
          fill = selected
              ? SettleColors.dusk600.withValues(alpha: 0.16)
              : SettleSurfaces.cardDark;
          borderColor = selected
              ? SettleColors.dusk400.withValues(alpha: 0.45)
              : SettleSurfaces.cardBorderDark;
          textColor = selected ? SettleColors.nightText : SettleColors.nightSoft;
      }
    } else {
      final lightBorder = SettleColors.ink300.withValues(alpha: 0.12);
      switch (variant) {
        case SettleChipVariant.tag:
          fill = selected
              ? SettleColors.sage600.withValues(alpha: 0.14)
              : SettleColors.stone50;
          borderColor = selected
              ? SettleColors.sage400.withValues(alpha: 0.50)
              : lightBorder;
          textColor = selected ? SettleColors.ink900 : SettleColors.ink700;
        case SettleChipVariant.action:
          fill = selected
              ? SettleColors.sage600.withValues(alpha: 0.12)
              : SettleColors.stone50;
          borderColor = lightBorder;
          textColor = selected ? SettleColors.ink900 : SettleColors.ink700;
        case SettleChipVariant.frequency:
          fill = selected
              ? SettleColors.sage600.withValues(alpha: 0.12)
              : SettleColors.stone50;
          borderColor = selected
              ? SettleColors.sage400.withValues(alpha: 0.45)
              : lightBorder;
          textColor = selected ? SettleColors.ink900 : SettleColors.ink700;
      }
    }

    final isBodySize = variant == SettleChipVariant.frequency;
    final textStyle = (isBodySize ? SettleTypography.body : SettleTypography.caption)
        .copyWith(color: textColor, fontWeight: FontWeight.w600);

    return (fill, borderColor, textColor, textStyle);
  }
}
