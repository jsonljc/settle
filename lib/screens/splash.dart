import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/profile_provider.dart';
import '../theme/reduce_motion.dart';
import '../theme/settle_tokens.dart';
import '../widgets/gradient_background.dart';

/// Splash screen — app name + tagline, auto-redirects after a short minimum.
/// Goes to /home if a profile already exists, /onboard otherwise.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  Timer? _minSplashTimer;
  ProviderSubscription<bool>? _profileLoadedSub;
  bool _minSplashElapsed = false;
  bool _profileLoaded = false;
  bool _didRoute = false;

  @override
  void initState() {
    super.initState();
    // Kick off persisted profile load immediately on app open.
    ref.read(profileProvider.notifier);
    _profileLoaded = ref.read(profileLoadedProvider);
    _profileLoadedSub = ref.listenManual<bool>(profileLoadedProvider, (
      _,
      loaded,
    ) {
      _profileLoaded = loaded;
      _redirectIfReady();
    });
    _minSplashTimer = Timer(const Duration(milliseconds: 900), () {
      _minSplashElapsed = true;
      _redirectIfReady();
    });
    _redirectIfReady();
  }

  void _redirectIfReady() {
    if (_didRoute || !_minSplashElapsed || !_profileLoaded || !mounted) {
      return;
    }
    _didRoute = true;
    final profile = ref.read(profileProvider);
    if (profile == null) {
      context.go('/onboard');
      return;
    }
    context.go('/plan');
  }

  @override
  void dispose() {
    _minSplashTimer?.cancel();
    _profileLoadedSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Moon icon
              Icon(
                Icons.nightlight_round,
                size: 48,
                color: T.pal.accent,
              ).entryScaleIn(context, duration: 600.ms, scaleBegin: 0.8),
              const SizedBox(height: 20),
              // App name
              Text(
                'settle',
                style: T.type.splash.copyWith(color: T.pal.textPrimary),
              ).entryFadeOnly(context, delay: 200.ms, duration: 600.ms),
              const SizedBox(height: 8),
              // Tagline
              Text(
                'One step at a time.',
                style: T.type.overline.copyWith(color: T.pal.textSecondary),
              ).entryFadeOnly(context, delay: 500.ms, duration: 600.ms),
            ],
          ),
        ),
      ),
    );
  }
}
