import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/settle_cta.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/screen_header.dart';

// Deprecated in IA cleanup PR6. This fallback exists only for deprecated
// tantrum screens that are no longer reachable from production routes.
class TantrumUnavailableView extends StatelessWidget {
  const TantrumUnavailableView({super.key, required this.title, this.message});

  final String title;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SettleSpacing.screenPadding,
            ),
            child: Column(
              children: [
                ScreenHeader(title: title),
                const Spacer(),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tantrum support is not active',
                        style: SettleTypography.heading.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message ??
                            'Enable tantrum support from onboarding or settings to open this screen.',
                        style: SettleTypography.body.copyWith(
                          color: SettleColors.nightSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SettleCta(
                  label: 'Back to home',
                  onTap: () => context.go('/now'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
