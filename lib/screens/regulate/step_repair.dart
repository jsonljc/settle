import 'package:flutter/material.dart';

import '../../theme/glass_components.dart';
import '../../theme/settle_design_system.dart';

class _RsrT {
  _RsrT._();

  static final type = _RsrTypeTokens();
  static const pal = _RsrPaletteTokens();
}

class _RsrTypeTokens {
  TextStyle get h2 => SettleTypography.heading.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );
  TextStyle get body => SettleTypography.body;
}

class _RsrPaletteTokens {
  const _RsrPaletteTokens();

  Color get textSecondary => SettleColors.nightSoft;
}

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
          Text('Repair when you\'re ready', style: _RsrT.type.h2),
          const SizedBox(height: 8),
          Text(
            'A short, genuine repair goes a long way. You don\'t have to be perfect.',
            style: _RsrT.type.body.copyWith(color: _RsrT.pal.textSecondary),
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
                    style: _RsrT.type.body.copyWith(height: 1.45),
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
