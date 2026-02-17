import 'package:flutter_test/flutter_test.dart';
import 'package:settle/theme/settle_tokens.dart';
import 'package:settle/theme/surface_mode_resolver.dart';

void main() {
  test('resolves focus mode for regulate routes', () {
    final mode = SurfaceModeResolver.resolve(
      now: DateTime(2026, 2, 16, 14, 0),
      routePath: '/plan/regulate',
    );
    expect(mode, SurfaceMode.focus);
  });

  test('resolves night mode for nighttime non-focus routes', () {
    final mode = SurfaceModeResolver.resolve(
      now: DateTime(2026, 2, 16, 21, 0),
      routePath: '/plan',
    );
    expect(mode, SurfaceMode.night);
  });

  test('resolves day mode for daytime non-focus routes', () {
    final mode = SurfaceModeResolver.resolve(
      now: DateTime(2026, 2, 16, 11, 0),
      routePath: '/plan',
    );
    expect(mode, SurfaceMode.day);
  });
}
