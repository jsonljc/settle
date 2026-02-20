import 'package:flutter/material.dart';

import '../../../theme/settle_design_system.dart';

/// O4 — First value promise. Single line + CTA "Let's go" (handled by parent).
class StepValuePromise extends StatelessWidget {
  const StepValuePromise({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Next time it gets hard, you\'ll know what to say.',
          style: SettleTypography.heading.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
