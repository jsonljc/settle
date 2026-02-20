import 'package:flutter/material.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/glass_pill.dart';
import '../../theme/settle_design_system.dart';

class DebriefSection extends StatelessWidget {
  const DebriefSection({
    super.key,
    required this.selectedTrigger,
    required this.onTriggerTap,
    this.triggers = const [
      'transitions',
      'bedtime_battles',
      'public_meltdowns',
      'no_to_everything',
      'sibling_conflict',
      'overwhelmed',
    ],
  });

  final String? selectedTrigger;
  final List<String> triggers;
  final ValueChanged<String> onTriggerTap;

  static const _labels = {
    'transitions': 'Transitions',
    'bedtime_battles': 'Bedtime battles',
    'public_meltdowns': 'Public meltdowns',
    'no_to_everything': '"No" to everything',
    'sibling_conflict': 'Sibling conflict',
    'overwhelmed': "I'm overwhelmed",
  };

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What\'s been hardest?', style: SettleTypography.heading),
          const SizedBox(height: 6),
          Text(
            'Tap one for a script.',
            style: SettleTypography.caption.copyWith(color: SettleColors.nightSoft),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: triggers.map((trigger) {
              final selected = selectedTrigger == trigger;
              return GlassPill(
                label: _labels[trigger] ?? trigger,
                fill: selected ? SettleColors.nightAccent.withValues(alpha: 0.10) : null,
                textColor: selected ? SettleColors.nightAccent : SettleColors.nightText,
                onTap: () => onTriggerTap(trigger),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
