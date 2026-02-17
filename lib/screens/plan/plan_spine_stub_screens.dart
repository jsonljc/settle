import 'package:flutter/material.dart';

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
                const ScreenHeader(title: 'Reset', fallbackRoute: '/plan'),
                const SizedBox(height: 24),
                Text(
                  'Open the full Reset flow from Plan.',
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
                const ScreenHeader(title: 'Moment', fallbackRoute: '/plan'),
                const SizedBox(height: 24),
                Text(
                  'Open the full Moment flow from Plan.',
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

/// Tantrum "Just happened" — routes directly to Reset with context=tantrum.
/// See: /plan/tantrum-just-happened redirect in router.
