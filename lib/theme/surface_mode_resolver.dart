import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../services/spec_policy.dart';
import 'settle_tokens.dart';

class SurfaceModeResolver {
  const SurfaceModeResolver._();

  static const List<String> _focusPrefixes = [
    '/plan/regulate',
    '/breathe',
    '/sos',
    '/regulate',
  ];

  static SurfaceMode resolve({
    required DateTime now,
    required String routePath,
  }) {
    if (isFocusRoute(routePath)) return SurfaceMode.focus;
    return SpecPolicy.isNight(now) ? SurfaceMode.night : SurfaceMode.day;
  }

  static SurfaceMode resolveForContext(
    BuildContext context, {
    DateTime? now,
    String? routePath,
  }) {
    final resolvedRoute = routePath ?? currentRoutePath(context);
    return resolve(now: now ?? DateTime.now(), routePath: resolvedRoute ?? '');
  }

  static bool isFocusRoute(String routePath) {
    for (final prefix in _focusPrefixes) {
      if (routePath.startsWith(prefix)) return true;
    }
    return false;
  }

  static String? currentRoutePath(BuildContext context) {
    try {
      return GoRouterState.of(context).uri.path;
    } catch (_) {
      final name = ModalRoute.of(context)?.settings.name;
      if (name == null || name.isEmpty) return null;
      final parsed = Uri.tryParse(name);
      return parsed?.path ?? name;
    }
  }
}
