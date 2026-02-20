import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/approach.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/option_button.dart';

/// Step 1: Age. Combined infant + toddler + preschool brackets.
class StepAge extends StatelessWidget {
  const StepAge({super.key, required this.selected, required this.onSelect});

  final AgeBracket? selected;
  final ValueChanged<AgeBracket> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How old is\nyour child?',
          style: SettleTypography.heading.copyWith(
            fontSize: 26,
            color: SettleSemanticColors.headline(context),
          ),
        ).entryFadeIn(context, duration: 400.ms, moveY: 10),
        const SizedBox(height: 24),
        ...AgeBracket.values.asMap().entries.map((entry) {
          final i = entry.key;
          final bracket = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OptionButton(
              label: bracket.label,
              subtitle: _subtitle(bracket),
              selected: selected == bracket,
              onTap: () => onSelect(bracket),
            ),
          ).entrySlideIn(context, delay: Duration(milliseconds: 80 * i));
        }),
      ],
    );
  }

  String _subtitle(AgeBracket bracket) {
    if (bracket.isSleepOnlyAge || bracket.isHybridAge) {
      final napsText = bracket.naps > 0
          ? '${bracket.naps} naps'
          : 'No regular naps';
      return '$napsText · ${bracket.wakeWindowLabel}';
    }
    return 'Tantrum support primary';
  }
}
