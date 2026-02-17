import 'package:flutter/material.dart';

import '../../services/card_content_service.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';

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
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        if (card == null) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('One thing you can do', style: T.type.h2),
                const SizedBox(height: 12),
                Text(
                  'Take one calm breath. Then name what you see: "You\'re having a hard time. I\'m here."',
                  style: T.type.body.copyWith(color: T.pal.textSecondary),
                ),
                const SizedBox(height: 24),
                GlassCta(label: 'Done', onTap: onNext),
              ],
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: T.space.screen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('One thing you can do', style: T.type.h2),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Say',
                      style: T.type.caption.copyWith(color: T.pal.textTertiary),
                    ),
                    const SizedBox(height: 4),
                    Text(card.say, style: T.type.h3),
                    const SizedBox(height: 12),
                    Text(
                      'Do',
                      style: T.type.caption.copyWith(color: T.pal.textTertiary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.doStep,
                      style: T.type.body.copyWith(color: T.pal.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GlassCta(label: 'Done', onTap: onNext),
            ],
          ),
        );
      },
    );
  }
}
