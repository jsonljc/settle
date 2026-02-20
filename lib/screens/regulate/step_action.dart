import 'package:flutter/material.dart';

import '../../services/card_content_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/settle_cta.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/calm_loading.dart';

/// Step 4: Actionable next step — context-aware Say/Do script from [CardContentService].
/// Uses "overwhelmed" trigger for parent-focused script.
class RegulateStepAction extends StatelessWidget {
  const RegulateStepAction({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CardContent?>(
      future: CardContentService.instance.selectBestCard(
        triggerType: 'overwhelmed',
      ),
      builder: (context, snapshot) {
        final card = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SettleSpacing.screenPadding,
            ),
            child: const Center(
              child: CalmLoading(message: 'Getting your next step…'),
            ),
          );
        }
        if (card == null) {
          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SettleSpacing.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('One thing you can do', style: SettleTypography.heading.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text(
                  'Take one calm breath. Then name what you see: "You\'re having a hard time. I\'m here."',
                  style: SettleTypography.body.copyWith(
                    color: SettleColors.nightSoft,
                  ),
                ),
                const SizedBox(height: 24),
                SettleCta(label: 'Done', onTap: onNext),
              ],
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: SettleSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('One thing you can do', style: SettleTypography.heading.copyWith(fontSize: 22, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Say',
                      style: SettleTypography.caption.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: SettleColors.nightMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(card.say, style: SettleTypography.heading.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Text(
                      'Do',
                      style: SettleTypography.caption.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: SettleColors.nightMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.doStep,
                      style: SettleTypography.body.copyWith(
                        color: SettleColors.nightSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SettleCta(label: 'Done', onTap: onNext),
            ],
          ),
        );
      },
    );
  }
}
