import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/settle_tokens.dart';

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
/// Uses [T.pal], [T.type], [T.radius], [T.glass]. Selected state uses glass
/// fill accent; unselected uses [T.glass.fill] and subtle border.
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

    Color fill;
    Color borderColor;
    Color textColor;
    TextStyle textStyle;

    switch (variant) {
      case SettleChipVariant.tag:
        fill = selected ? T.glass.fillAccent : T.glass.fill;
        borderColor = selected ? T.pal.accent : T.glass.border;
        textColor = selected ? T.pal.accent : T.pal.textSecondary;
        textStyle = T.type.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        );
        break;
      case SettleChipVariant.action:
        fill = selected ? T.glass.fillAccent : T.glass.fill;
        borderColor = T.glass.border;
        textColor = selected ? T.pal.accent : T.pal.textSecondary;
        textStyle = T.type.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        );
        break;
      case SettleChipVariant.frequency:
        fill = selected ? T.glass.fillAccent : T.glass.fill;
        borderColor = selected
            ? T.pal.accent.withValues(alpha: 0.4)
            : T.glass.border;
        textColor = selected ? T.pal.accent : T.pal.textSecondary;
        textStyle = T.type.label.copyWith(color: textColor);
        break;
    }

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
          borderRadius: BorderRadius.circular(T.radius.pill),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: T.space.md,
              vertical: T.space.sm,
            ),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(T.radius.pill),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: textColor),
                  SizedBox(width: T.space.sm),
                ],
                Text(displayLabel, style: textStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
