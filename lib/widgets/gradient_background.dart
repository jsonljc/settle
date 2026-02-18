import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/settle_design_system.dart';

/// A soft colored circle that floats behind glass (center color → transparent).
class AmbientBlob {
  const AmbientBlob({
    required this.color,
    required this.size,
    required this.position,
    this.blur = 2.0,
  });

  final Color color;
  final double size;
  final Alignment position;
  final double blur;

  /// FractionalOffset is normalized (0,0) to (1,1); we convert to Alignment.
  factory AmbientBlob.withFractionalOffset({
    required Color color,
    required double size,
    required FractionalOffset position,
    double blur = 2.0,
  }) {
    return AmbientBlob(
      color: color,
      size: size,
      position: Alignment(position.dx * 2 - 1, position.dy * 2 - 1),
      blur: blur,
    );
  }
}

/// Living gradient + optional ambient blobs that show through all glass elements.
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.gradient,
    required this.child,
    this.ambientBlobs,
  });

  final LinearGradient gradient;
  final List<AmbientBlob>? ambientBlobs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Base gradient
        Container(decoration: BoxDecoration(gradient: gradient)),
        // 2. Ambient blobs (soft circles)
        if (ambientBlobs != null && ambientBlobs!.isNotEmpty)
          ...ambientBlobs!.map((blob) => _buildBlob(blob)),
        // 3. Content on top
        child,
      ],
    );
  }

  Widget _buildBlob(AmbientBlob blob) {
    final blobWidget = Container(
      width: blob.size,
      height: blob.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [blob.color, blob.color.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
    final blurred = ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blob.blur, sigmaY: blob.blur),
      child: blobWidget,
    );
    return Positioned.fill(
      child: Align(alignment: blob.position, child: blurred),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Route-based presets: gradient + blobs per path (for shell or per-screen use)
// ─────────────────────────────────────────────────────────────────────────────

class GradientBackgroundPresets {
  GradientBackgroundPresets._();

  static ({LinearGradient gradient, List<AmbientBlob> blobs}) forPath(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    final p = path.toLowerCase();
    final contextQuery =
        queryParameters?['context']?.toLowerCase().trim() ?? '';
    final isTantrumJustHappened =
        p.contains('/plan/reset') && contextQuery == 'tantrum';

    if (p.contains('/plan/moment')) {
      return (gradient: SettleGradients.moment, blobs: _momentBlobs);
    }
    if (isTantrumJustHappened) {
      return (gradient: SettleGradients.resetDark, blobs: _tantrumBlobs);
    }
    if (p.contains('/plan/reset')) {
      return (gradient: SettleGradients.resetDark, blobs: _resetBlobs);
    }
    if (p.contains('/sleep/tonight') || p == '/sleep/tonight') {
      return (gradient: SettleGradients.sleep, blobs: _sleepBlobs);
    }
    if (p.contains('/library/saved') ||
        p.contains('saved') && p.contains('/library')) {
      return (gradient: SettleGradients.playbook, blobs: _playbookBlobs);
    }
    if (p.contains('/library') || p.startsWith('/plan') || p == '/plan') {
      return (gradient: SettleGradients.home, blobs: _homeBlobs);
    }
    if (p.contains('/family')) {
      return (gradient: SettleGradients.home, blobs: _homeBlobs);
    }
    return (gradient: SettleGradients.home, blobs: _homeBlobs);
  }

  static final List<AmbientBlob> _homeBlobs = [
    AmbientBlob(
      color: SettleColors.sage100,
      size: 180,
      position: Alignment.topRight,
      blur: 2.0,
    ),
    AmbientBlob(
      color: SettleColors.dusk100,
      size: 160,
      position: Alignment.bottomLeft,
      blur: 2.0,
    ),
  ];

  static final List<AmbientBlob> _momentBlobs = [
    AmbientBlob(
      color: Colors.white.withValues(alpha: 0.35),
      size: 200,
      position: Alignment.centerLeft,
      blur: 2.0,
    ),
  ];

  static final List<AmbientBlob> _resetBlobs = [
    AmbientBlob(
      color: SettleColors.nightAccent.withValues(alpha: 0.2),
      size: 140,
      position: Alignment.topLeft,
      blur: 2.0,
    ),
  ];

  /// Tantrum Just Happened: same gradient as Reset, warmth tint for subtle distinction.
  static final List<AmbientBlob> _tantrumBlobs = [
    AmbientBlob(
      color: SettleColors.warmth400.withValues(alpha: 0.25),
      size: 140,
      position: Alignment.topLeft,
      blur: 2.0,
    ),
  ];

  static final List<AmbientBlob> _sleepBlobs = [
    AmbientBlob(
      color: SettleColors.dusk400.withValues(alpha: 0.3),
      size: 160,
      position: Alignment.topCenter,
      blur: 2.0,
    ),
  ];

  static final List<AmbientBlob> _playbookBlobs = [
    AmbientBlob(
      color: SettleColors.warmth100,
      size: 150,
      position: Alignment.topRight,
      blur: 2.0,
    ),
  ];
}

/// Wraps [child] in [GradientBackground] using gradient + blobs for the current
/// route. Use in AppShell so the background updates when the route changes.
class GradientBackgroundFromRoute extends StatelessWidget {
  const GradientBackgroundFromRoute({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    Uri uri;
    try {
      uri = GoRouterState.of(context).uri;
    } catch (_) {
      uri = GoRouter.of(context).routeInformationProvider.value.uri;
    }
    final pathStr = uri.path.isEmpty ? '/plan' : uri.path;
    final presets = GradientBackgroundPresets.forPath(
      pathStr,
      queryParameters: uri.queryParameters,
    );
    return GradientBackground(
      gradient: presets.gradient,
      ambientBlobs: presets.blobs,
      child: child,
    );
  }
}
