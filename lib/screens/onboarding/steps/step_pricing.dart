import 'package:flutter/material.dart';

import '../../../theme/glass_components.dart';
import '../../../theme/settle_design_system.dart';

class _SprT {
  _SprT._();

  static final type = _SprTypeTokens();
  static const pal = _SprPaletteTokens();
}

class _SprTypeTokens {
  TextStyle get h1 => SettleTypography.heading.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
  );
  TextStyle get h3 => SettleTypography.heading.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );
  TextStyle get body => SettleTypography.body;
  TextStyle get caption => SettleTypography.caption.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
}

class _SprPaletteTokens {
  const _SprPaletteTokens();

  Color get textSecondary => SettleColors.nightSoft;
}

class StepPricing extends StatelessWidget {
  const StepPricing({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Try Settle Premium', style: _SprT.type.h1),
        const SizedBox(height: 10),
        Text(
          'Billing integration comes next. This screen previews the paywall copy.',
          style: _SprT.type.caption.copyWith(color: _SprT.pal.textSecondary),
        ),
        const SizedBox(height: 18),
        GlassCardAccent(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('7-day free trial', style: _SprT.type.h3),
              const SizedBox(height: 6),
              Text(
                '\$9.99/month after trial',
                style: _SprT.type.body.copyWith(color: _SprT.pal.textSecondary),
              ),
              const SizedBox(height: 10),
              Text(
                'Includes Plan scripts, Family alignment, and proactive nudges.',
                style: _SprT.type.caption.copyWith(
                  color: _SprT.pal.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
