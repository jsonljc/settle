import 'package:flutter/material.dart';

import '../theme/settle_design_system.dart';
import 'settle_chip.dart';

/// A single-select group of options rendered as chips in a shared container.
/// Replaces _SegmentedChoice and _SegmentedString. Only one option can be
/// selected at a time. Uses [SettleChip] with [SettleChipVariant.frequency].
class SettleSegmentedChoice<TOption> extends StatelessWidget {
  const SettleSegmentedChoice({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    required this.labelBuilder,
    this.groupSemanticLabel,
  });

  final List<TOption> options;
  final TOption selected;
  final ValueChanged<TOption> onChanged;
  final String Function(TOption) labelBuilder;
  final String? groupSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final total = options.length;
    return Semantics(
      container: true,
      label: groupSemanticLabel,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SettleSpacing.sm,
          vertical: SettleSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: SettleSurfaces.cardDark,
          borderRadius: BorderRadius.circular(SettleRadii.surface),
          border: Border.all(color: SettleSurfaces.cardBorderDark),
        ),
        child: Wrap(
          spacing: SettleSpacing.sm,
          runSpacing: SettleSpacing.sm,
          children: List.generate(options.length, (index) {
            final value = options[index];
            final isSelected = selected == value;
            final label = labelBuilder(value);
            final positionLabel =
                '$label, ${index + 1} of $total'
                '${isSelected ? ', selected' : ''}';
            return SettleChip(
              key: ValueKey(index),
              label: label,
              selected: isSelected,
              onTap: () => onChanged(value),
              variant: SettleChipVariant.frequency,
              semanticLabel: positionLabel,
            );
          }),
        ),
      ),
    );
  }
}
