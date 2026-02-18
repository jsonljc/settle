import 'package:flutter/material.dart';

import '../../services/card_content_service.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/calm_loading.dart';

class _RsaT {
  _RsaT._();

  static final type = _RsaTypeTokens();
  static const pal = _RsaPaletteTokens();
}

class _RsaTypeTokens {
  TextStyle get h2 => SettleTypography.heading.copyWith(
    fontSize: 22,
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

class _RsaPaletteTokens {
  const _RsaPaletteTokens();

  Color get textSecondary => SettleColors.nightSoft;
  Color get textTertiary => SettleColors.nightMuted;
}

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
                Text('One thing you can do', style: _RsaT.type.h2),
                const SizedBox(height: 12),
                Text(
                  'Take one calm breath. Then name what you see: "You\'re having a hard time. I\'m here."',
                  style: _RsaT.type.body.copyWith(
                    color: _RsaT.pal.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                GlassCta(label: 'Done', onTap: onNext),
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
              Text('One thing you can do', style: _RsaT.type.h2),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Say',
                      style: _RsaT.type.caption.copyWith(
                        color: _RsaT.pal.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(card.say, style: _RsaT.type.h3),
                    const SizedBox(height: 12),
                    Text(
                      'Do',
                      style: _RsaT.type.caption.copyWith(
                        color: _RsaT.pal.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      card.doStep,
                      style: _RsaT.type.body.copyWith(
                        color: _RsaT.pal.textSecondary,
                      ),
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
