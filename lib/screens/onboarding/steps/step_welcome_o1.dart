import 'package:flutter/material.dart';

import '../../../theme/settle_design_system.dart';

/// O1 — Welcome. Wireframe: "Settle" / "Know what to say after the hard parts." / CTA "Start".
class StepWelcomeO1 extends StatelessWidget {
  const StepWelcomeO1({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Settle',
            style: SettleTypography.displayLarge.copyWith(
              color: SettleSemanticColors.headline(context),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: SettleSpacing.lg),
          Text(
            'Know what to say after the hard parts.',
            style: SettleTypography.body.copyWith(
              color: SettleSemanticColors.body(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
