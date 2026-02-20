import 'package:flutter/material.dart';

import '../../../theme/settle_design_system.dart';
import '../../../widgets/option_button.dart';

/// O3 — What's been hardest lately. Wireframe: "Bedtime battles" / "Meltdowns" / "Big feelings" / "Just exploring".
/// Choice drives post-onboarding default tab (Sleep vs Now).
class StepWhyHere extends StatelessWidget {
  const StepWhyHere({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final String? selected;
  final ValueChanged<String> onSelect;

  static const options = [
    _WhyHereOption(id: 'sleep', label: 'Bedtime battles', icon: Icons.nightlight_round),
    _WhyHereOption(
      id: 'tantrums',
      label: 'Meltdowns',
      icon: Icons.mood_bad_outlined,
    ),
    _WhyHereOption(
      id: 'big_feelings',
      label: 'Big feelings',
      icon: Icons.favorite_border,
    ),
    _WhyHereOption(
      id: 'just_exploring',
      label: 'Just exploring',
      icon: Icons.explore_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s been hardest lately?',
          style: SettleTypography.heading.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 20),
        ...options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OptionButton(
              label: option.label,
              icon: option.icon,
              selected: selected == option.id,
              onTap: () => onSelect(option.id),
            ),
          );
        }),
      ],
    );
  }
}

class _WhyHereOption {
  const _WhyHereOption({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}
