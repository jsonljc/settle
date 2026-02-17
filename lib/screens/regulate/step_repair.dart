import 'package:flutter/material.dart';

import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';

/// Step 5: Repair — shown when trigger was [RegulationTrigger.alreadyYelled].
/// Simple repair scripts for reconnecting after a rupture.
class RegulateStepRepair extends StatelessWidget {
  const RegulateStepRepair({
    super.key,
    required this.onDone,
  });

  final VoidCallback onDone;

  static const _repairScripts = [
    'I\'m sorry I raised my voice. I was frustrated. I still love you.',
    'That wasn\'t the way I want to talk to you. Let\'s try again when we\'re both calmer.',
    'I lost my cool. You didn\'t deserve that. I\'m working on it.',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: T.space.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Repair when you\'re ready',
            style: T.type.h2,
          ),
          const SizedBox(height: 8),
          Text(
            'A short, genuine repair goes a long way. You don\'t have to be perfect.',
            style: T.type.body.copyWith(color: T.pal.textSecondary),
          ),
          const SizedBox(height: 20),
          ..._repairScripts.map(
            (script) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Text(
                    script,
                    style: T.type.body.copyWith(height: 1.45),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GlassCta(label: 'Done', onTap: onDone),
        ],
      ),
    );
  }
}
