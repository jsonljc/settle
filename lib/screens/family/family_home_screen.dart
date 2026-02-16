import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';

class FamilyHomeScreen extends StatelessWidget {
  const FamilyHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Family',
                  subtitle: 'Keep everyone aligned with the same scripts.',
                  fallbackRoute: '/family',
                ),
                const SizedBox(height: 10),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Shared playbook', style: T.type.h3),
                      const SizedBox(height: 8),
                      Text(
                        'Open caregiver scripts and agreement notes.',
                        style: T.type.body.copyWith(color: T.pal.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      GlassCta(
                        label: 'Open shared scripts',
                        onTap: () => context.push('/family/shared'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Invite', style: T.type.h3),
                      const SizedBox(height: 8),
                      Text(
                        'Invite flow is queued for the Family MVP.',
                        style: T.type.body.copyWith(color: T.pal.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
