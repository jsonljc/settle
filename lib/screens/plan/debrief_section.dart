import 'package:flutter/material.dart';

import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';

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
          Text('What\'s been hardest?', style: T.type.h3),
          const SizedBox(height: 6),
          Text(
            'Tap one to get a script right now.',
            style: T.type.caption.copyWith(color: T.pal.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: triggers.map((trigger) {
              final selected = selectedTrigger == trigger;
              return GlassPill(
                label: _labels[trigger] ?? trigger,
                fill: selected ? T.glass.fillAccent : null,
                textColor: selected ? T.pal.accent : T.pal.textPrimary,
                onTap: () => onTriggerTap(trigger),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
