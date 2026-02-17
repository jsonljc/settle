import 'package:flutter/material.dart';

import '../theme/settle_tokens.dart';
import 'settle_chip.dart';

/// A single-select group of options rendered as chips in a shared glass container.
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
          horizontal: T.space.sm,
          vertical: T.space.sm,
        ),
        decoration: BoxDecoration(
          color: T.glass.fill,
          borderRadius: BorderRadius.circular(T.radius.lg),
          border: Border.all(color: T.glass.border),
        ),
        child: Wrap(
          spacing: T.space.sm,
          runSpacing: T.space.sm,
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
