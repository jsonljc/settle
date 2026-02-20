import 'package:flutter/material.dart';

import '../../../widgets/glass_card.dart';
import '../../../theme/settle_design_system.dart';

class StepPricing extends StatelessWidget {
  const StepPricing({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Try Settle Premium', style: SettleTypography.heading.copyWith(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(
          'Billing integration comes next. This screen previews the paywall copy.',
          style: SettleTypography.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: SettleColors.nightSoft),
        ),
        const SizedBox(height: 18),
        GlassCardAccent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('7-day free trial', style: SettleTypography.heading.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                '\$9.99/month after trial',
                style: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
              ),
              const SizedBox(height: 10),
              Text(
                'Includes Plan scripts, Family alignment, and proactive nudges.',
                style: SettleTypography.caption.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: SettleColors.nightSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
