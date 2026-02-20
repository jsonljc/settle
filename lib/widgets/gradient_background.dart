import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/settle_design_system.dart';

/// A soft colored circle that floats behind content.
/// Deprecated — kept for backward compatibility during migration.
class AmbientBlob {
  const AmbientBlob({
    required this.color,
    required this.size,
    required this.position,
    this.blur = 50.0,
  });

  final Color color;
  final double size;
  final Alignment position;
  final double blur;

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
      blur: blur == 2.0 ? 50.0 : blur,
    );
  }
}

/// Deprecated — kept for backward compatibility. Renders solid color only.
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
    // Solid background: use the first color of the gradient (ignoring blobs).
    final color = gradient.colors.isNotEmpty
        ? gradient.colors.first
        : SettleColors.stone50;
    return Container(color: color, child: child);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Route-based presets — now solid colors only
// ─────────────────────────────────────────────────────────────────────────────

class GradientBackgroundPresets {
  GradientBackgroundPresets._();

  static ({LinearGradient gradient, List<AmbientBlob> blobs}) forPath(
    String path, {
    Map<String, String>? queryParameters,
  }) {
    // All presets now return empty blobs and solid-color gradients.
    return (gradient: SettleGradients.home, blobs: const <AmbientBlob>[]);
  }
}

/// Solid background by route. Dark for crisis flows, stone50/night900 otherwise.
class GradientBackgroundFromRoute extends StatelessWidget {
  const GradientBackgroundFromRoute({super.key, required this.child});

  final Widget child;

  static bool _isDarkFlow(String path) {
    final p = path.toLowerCase();
    return p.contains('/plan/reset') ||
        p.contains('/plan/moment') ||
        p.contains('/plan/regulate') ||
        p.contains('/sleep/tonight') ||
        p == '/breathe';
  }

  @override
  Widget build(BuildContext context) {
    Uri uri;
    try {
      uri = GoRouterState.of(context).uri;
    } catch (_) {
      try {
        uri = GoRouter.of(context).routeInformationProvider.value.uri;
      } catch (_) {
        uri = Uri(path: '/plan');
      }
    }
    final pathStr = uri.path.isEmpty ? '/plan' : uri.path;
    final darkFlow = _isDarkFlow(pathStr);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (darkFlow || isDark) {
      return Container(
        color: SettleColors.night900,
        child: child,
      );
    }
    return Container(
      color: SettleColors.stone50,
      child: child,
    );
  }
}
