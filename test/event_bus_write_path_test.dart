import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production code does not bypass central event bus write API', () async {
    final libDir = Directory('lib');
    expect(libDir.existsSync(), isTrue);

    final bypassFindings = <String>[];
    final directBoxFindings = <String>[];

    for (final entity in libDir.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;

      final normalizedPath = entity.path.replaceAll('\\', '/');
      if (normalizedPath.endsWith('/services/event_bus_service.dart')) {
        continue;
      }

      final content = await entity.readAsString();
      if (content.contains('EventBusService.emit(')) {
        bypassFindings.add(normalizedPath);
      }
      if (content.contains('event_bus_v1')) {
        directBoxFindings.add(normalizedPath);
      }
    }

    expect(
      bypassFindings,
      isEmpty,
      reason:
          'Direct EventBusService.emit calls must be routed through typed wrappers.',
    );
    expect(
      directBoxFindings,
      isEmpty,
      reason:
          'Direct event bus box access found outside event_bus_service.dart.',
    );
  });
}
