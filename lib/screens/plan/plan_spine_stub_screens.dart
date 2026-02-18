import 'package:flutter/material.dart';

import '../../theme/settle_design_system.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/screen_header.dart';

class _PssT {
  _PssT._();

  static final type = _PssTypeTokens();
  static const pal = _PssPaletteTokens();
}

class _PssTypeTokens {
  TextStyle get body => SettleTypography.body;
}

class _PssPaletteTokens {
  const _PssPaletteTokens();

  Color get textSecondary => SettleColors.nightSoft;
}

/// Stub for Reset entry point. Reaches correct screen and can exit cleanly (back/close).
class ResetStubScreen extends StatelessWidget {
  const ResetStubScreen({super.key});

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(title: 'Reset', fallbackRoute: '/plan'),
                const SizedBox(height: 24),
                Text(
                  'Open the full Reset flow from Plan.',
                  style: _PssT.type.body.copyWith(
                    color: _PssT.pal.textSecondary,
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

/// Stub for Moment entry point.
class MomentStubScreen extends StatelessWidget {
  const MomentStubScreen({super.key});

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(title: 'Moment', fallbackRoute: '/plan'),
                const SizedBox(height: 24),
                Text(
                  'Open the full Moment flow from Plan.',
                  style: _PssT.type.body.copyWith(
                    color: _PssT.pal.textSecondary,
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

/// Tantrum "Just happened" — routes directly to Reset with context=tantrum.
/// See: /plan/tantrum-just-happened redirect in router.
