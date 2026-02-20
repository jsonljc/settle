import 'package:flutter/material.dart';

import '../../models/v2_enums.dart';
import '../../widgets/settle_cta.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/option_button.dart';

/// Step 1: Acknowledge — "You're having a hard moment too." Select situation (maps to [RegulationTrigger]).
class RegulateStepAcknowledge extends StatelessWidget {
  const RegulateStepAcknowledge({
    super.key,
    required this.selectedTrigger,
    required this.onSelect,
    required this.onNext,
  });

  final RegulationTrigger? selectedTrigger;
  final ValueChanged<RegulationTrigger> onSelect;
  final VoidCallback onNext;

  static const _options = [
    (
      RegulationTrigger.aboutToLoseIt,
      'I\'m about to lose it',
      'I feel my temper rising',
    ),
    (
      RegulationTrigger.childMelting,
      'My child is melting down',
      'They\'re in the middle of a big moment',
    ),
    (RegulationTrigger.alreadyYelled, 'I already yelled', 'I want to repair'),
    (
      RegulationTrigger.needMinute,
      'I just need a minute',
      'I need to pause before responding',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('You\'re having a hard moment too.', style: SettleTypography.heading.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Which fits best right now?',
            style: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
          ),
          const SizedBox(height: 20),
          ..._options.map((option) {
            final (trigger, label, subtitle) = option;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OptionButton(
                label: label,
                subtitle: subtitle,
                selected: selectedTrigger == trigger,
                onTap: () => onSelect(trigger),
              ),
            );
          }),
          const SizedBox(height: 24),
          SettleCta(
            label: 'Continue',
            onTap: selectedTrigger != null ? onNext : () {},
          ),
        ],
      ),
    );
  }
}
