import 'package:flutter/material.dart';

import '../../../theme/settle_tokens.dart';
import '../../../widgets/option_button.dart';

class StepChallengeV2 extends StatelessWidget {
  const StepChallengeV2({
    super.key,
    required this.selectedTrigger,
    required this.onSelect,
  });

  final String? selectedTrigger;
  final ValueChanged<String> onSelect;

  static const options = [
    _ChallengeOption(
      id: 'transitions',
      label: 'Transitions',
      subtitle: 'Leaving, cleanup, getting in the car',
      icon: Icons.compare_arrows_rounded,
    ),
    _ChallengeOption(
      id: 'bedtime_battles',
      label: 'Bedtime battles',
      subtitle: 'Stalling, protests, second wind',
      icon: Icons.bedtime_outlined,
    ),
    _ChallengeOption(
      id: 'public_meltdowns',
      label: 'Public meltdowns',
      subtitle: 'Stores, playgrounds, crowded moments',
      icon: Icons.store_mall_directory_outlined,
    ),
    _ChallengeOption(
      id: 'no_to_everything',
      label: '"No" to everything',
      subtitle: 'Refusing requests and routines',
      icon: Icons.block_outlined,
    ),
    _ChallengeOption(
      id: 'sibling_conflict',
      label: 'Sibling conflict',
      subtitle: 'Fights, grabbing, escalating quickly',
      icon: Icons.people_alt_outlined,
    ),
    _ChallengeOption(
      id: 'overwhelmed',
      label: 'I am overwhelmed',
      subtitle: 'You are near your limit',
      icon: Icons.self_improvement_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What feels hardest right now?', style: T.type.h1),
        const SizedBox(height: 10),
        Text(
          'Pick one. You can adjust this later from Plan.',
          style: T.type.caption.copyWith(color: T.pal.textSecondary),
        ),
        const SizedBox(height: 20),
        ...options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OptionButton(
              label: option.label,
              subtitle: option.subtitle,
              icon: option.icon,
              selected: selectedTrigger == option.id,
              onTap: () => onSelect(option.id),
            ),
          );
        }),
      ],
    );
  }

  static String labelFor(String? id) {
    for (final option in options) {
      if (option.id == id) return option.label;
    }
    return 'Hard moments';
  }
}

class _ChallengeOption {
  const _ChallengeOption({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
}
