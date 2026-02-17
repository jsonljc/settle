import 'package:flutter/material.dart';

import '../../../theme/glass_components.dart';
import '../../../theme/settle_tokens.dart';

class StepPricing extends StatelessWidget {
  const StepPricing({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Try Settle Premium', style: T.type.h1),
        const SizedBox(height: 10),
        Text(
          'Billing integration comes next. This screen previews the paywall copy.',
          style: T.type.caption.copyWith(color: T.pal.textSecondary),
        ),
        const SizedBox(height: 18),
        GlassCardAccent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('7-day free trial', style: T.type.h3),
              const SizedBox(height: 6),
              Text(
                '\$9.99/month after trial',
                style: T.type.body.copyWith(color: T.pal.textSecondary),
              ),
              const SizedBox(height: 10),
              Text(
                'Includes Plan scripts, Family alignment, and proactive nudges.',
                style: T.type.caption.copyWith(color: T.pal.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
