import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
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
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              children: [
                ScreenHeader(title: title),
                const Spacer(),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tantrum support is not active', style: T.type.h3),
                      const SizedBox(height: 8),
                      Text(
                        message ??
                            'Enable tantrum support from onboarding or settings to open this screen.',
                        style: T.type.body.copyWith(color: T.pal.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                GlassCta(
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
