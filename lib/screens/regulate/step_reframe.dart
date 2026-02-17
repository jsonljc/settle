import 'package:flutter/material.dart';

import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';

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
      padding: EdgeInsets.symmetric(horizontal: T.space.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('A quick reframe', style: T.type.h2),
          const SizedBox(height: 16),
          ..._reframeLines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                line,
                style: T.type.body.copyWith(
                  color: T.pal.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          GlassCta(label: 'Continue', onTap: onNext),
        ],
      ),
    );
  }
}
