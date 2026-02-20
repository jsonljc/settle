import 'package:flutter/material.dart';

import '../../widgets/settle_cta.dart';
import '../../theme/settle_design_system.dart';

/// Step 3: Cognitive reframe — "This isn't personal" + developmental context.
/// Skipped when trigger is [RegulationTrigger.needMinute].
class RegulateStepReframe extends StatelessWidget {
  const RegulateStepReframe({super.key, required this.onNext});

  final VoidCallback onNext;

  static const _reframeLines = [
    'This isn\'t personal. Their brain is still learning to regulate.',
    'Big feelings are a sign of feeling safe enough to let them out with you.',
    'You don\'t have to fix it in one moment. Staying calm is enough.',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('A quick reframe', style: SettleTypography.heading.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ..._reframeLines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                line,
                style: SettleTypography.body.copyWith(
                  color: SettleColors.nightText,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SettleCta(label: 'Continue', onTap: onNext),
        ],
      ),
    );
  }
}
