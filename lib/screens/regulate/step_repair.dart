import 'package:flutter/material.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/settle_cta.dart';
import '../../theme/settle_design_system.dart';

/// Step 5: Repair — shown when trigger was [RegulationTrigger.alreadyYelled].
/// Simple repair scripts for reconnecting after a rupture.
class RegulateStepRepair extends StatelessWidget {
  const RegulateStepRepair({super.key, required this.onDone});

  final VoidCallback onDone;

  static const _repairScripts = [
    'I\'m sorry I raised my voice. I was frustrated. I still love you.',
    'That wasn\'t the way I want to talk to you. Let\'s try again when we\'re both calmer.',
    'I lost my cool. You didn\'t deserve that. I\'m working on it.',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Repair when you\'re ready', style: SettleTypography.heading.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'A short, genuine repair goes a long way. You don\'t have to be perfect.',
            style: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
          ),
          const SizedBox(height: 20),
          ..._repairScripts.map(
            (script) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 4,
                  ),
                  child: Text(
                    script,
                    style: SettleTypography.body.copyWith(height: 1.45),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SettleCta(label: 'Done', onTap: onDone),
        ],
      ),
    );
  }
}
