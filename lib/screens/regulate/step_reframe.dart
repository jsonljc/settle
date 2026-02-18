import 'package:flutter/material.dart';

import '../../theme/glass_components.dart';
import '../../theme/settle_design_system.dart';

class _RsfT {
  _RsfT._();

  static final type = _RsfTypeTokens();
  static const pal = _RsfPaletteTokens();
}

class _RsfTypeTokens {
  TextStyle get h2 => SettleTypography.heading.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );
  TextStyle get body => SettleTypography.body;
}

class _RsfPaletteTokens {
  const _RsfPaletteTokens();

  Color get textPrimary => SettleColors.nightText;
}

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
          Text('A quick reframe', style: _RsfT.type.h2),
          const SizedBox(height: 16),
          ..._reframeLines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                line,
                style: _RsfT.type.body.copyWith(
                  color: _RsfT.pal.textPrimary,
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
