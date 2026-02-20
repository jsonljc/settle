import 'package:flutter/material.dart';

import '../../../services/card_content_service.dart';
import '../../../widgets/glass_card.dart';
import '../../../theme/settle_design_system.dart';
import '../../../widgets/calm_loading.dart';
import '../../../widgets/output_card.dart';
import '../../../widgets/script_card.dart';

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
        Text('Instant value', style: SettleTypography.heading.copyWith(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(
          'Here is a first script for $challengeLabel.',
          style: SettleTypography.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: SettleColors.nightSoft),
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
              style: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
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
            style: SettleTypography.body.copyWith(fontWeight: FontWeight.w600, color: SettleColors.sage400),
          ),
        ],
      ],
    );
  }
}
