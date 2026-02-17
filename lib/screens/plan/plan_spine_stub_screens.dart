import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';

/// Stub for Reset entry point. Reaches correct screen and can exit cleanly (back/close).
class ResetStubScreen extends StatelessWidget {
  const ResetStubScreen({super.key});

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
                  title: 'Reset',
                  fallbackRoute: '/plan',
                ),
                const SizedBox(height: 24),
                Text(
                  'Reset flow placeholder.',
                  style: T.type.body.copyWith(color: T.pal.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stub for Moment entry point.
class MomentStubScreen extends StatelessWidget {
  const MomentStubScreen({super.key});

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
                  title: 'Moment',
                  fallbackRoute: '/plan',
                ),
                const SizedBox(height: 24),
                Text(
                  'Moment flow placeholder.',
                  style: T.type.body.copyWith(color: T.pal.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tantrum "Just happened" entry point — routes to Moment (10s brake) as primary CTA.
class TantrumJustHappenedStubScreen extends StatelessWidget {
  const TantrumJustHappenedStubScreen({super.key});

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
                  title: 'Tantrum just happened',
                  fallbackRoute: '/plan',
                ),
                const SizedBox(height: 24),
                Text(
                  'Need a quick reset?',
                  style: T.type.h3.copyWith(color: T.pal.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Moment gives you two script choices in 10 seconds.',
                  style: T.type.body.copyWith(color: T.pal.textSecondary),
                ),
                const SizedBox(height: 20),
                GlassCta(
                  label: 'Just need 10 seconds',
                  onTap: () =>
                      context.push('/plan/moment?context=tantrum'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
