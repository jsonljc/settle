import 'package:flutter/material.dart';

import '../../../services/card_content_service.dart';
import '../../../theme/glass_components.dart';
import '../../../theme/settle_design_system.dart';
import '../../../widgets/calm_loading.dart';
import '../../../widgets/output_card.dart';
import '../../../widgets/script_card.dart';

class _SivT {
  _SivT._();

  static final type = _SivTypeTokens();
  static const pal = _SivPaletteTokens();
}

class _SivTypeTokens {
  TextStyle get h1 => SettleTypography.heading.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
  );
  TextStyle get body => SettleTypography.body;
  TextStyle get label =>
      SettleTypography.body.copyWith(fontWeight: FontWeight.w600);
  TextStyle get caption => SettleTypography.caption.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
}

class _SivPaletteTokens {
  const _SivPaletteTokens();

  Color get teal => SettleColors.sage400;
  Color get textSecondary => SettleColors.nightSoft;
}

class StepInstantValue extends StatelessWidget {
  const StepInstantValue({
    super.key,
    required this.challengeLabel,
    required this.loading,
    required this.card,
    required this.saved,
    required this.onSave,
  });

  final String challengeLabel;
  final bool loading;
  final CardContent? card;
  final bool saved;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Instant value', style: _SivT.type.h1),
        const SizedBox(height: 10),
        Text(
          'Here is a first script for $challengeLabel.',
          style: _SivT.type.caption.copyWith(color: _SivT.pal.textSecondary),
        ),
        const SizedBox(height: 16),
        if (loading)
          const GlassCard(
            child: SizedBox(
              height: 140,
              child: Center(child: CalmLoading(message: 'Almost there…')),
            ),
          )
        else if (card == null)
          GlassCard(
            child: Text(
              'Could not load a script right now. You can still continue.',
              style: _SivT.type.body.copyWith(color: _SivT.pal.textSecondary),
            ),
          )
        else
          OutputCard(
            scenarioLabel: card!.triggerType,
            prevent: card!.prevent,
            say: card!.say,
            doStep: card!.doStep,
            ifEscalates: card!.ifEscalates,
            context: ScriptCardContext.onboarding,
            primaryLabel: saved
                ? 'Saved to My Playbook'
                : 'Save to My Playbook',
            primaryEnabled: !saved,
            onPrimary: saved ? null : onSave,
            onSave: onSave,
            onShare: () {},
            onLog: () {},
            onWhy: () {},
          ),
        if (saved) ...[
          const SizedBox(height: 10),
          Text(
            'Saved to My Playbook',
            style: _SivT.type.label.copyWith(color: _SivT.pal.teal),
          ),
        ],
      ],
    );
  }
}
