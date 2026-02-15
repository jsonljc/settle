import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _readJsonFile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    fail('Missing required registry file: $path');
  }
  final raw = file.readAsStringSync();
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    fail('Expected top-level JSON object in $path');
  }
  return Map<String, dynamic>.from(decoded);
}

void _collectBindingRefs(dynamic node, Set<String> refs) {
  if (node is Map) {
    for (final value in node.values) {
      _collectBindingRefs(value, refs);
    }
    return;
  }
  if (node is List) {
    for (final value in node) {
      if (value is String) {
        refs.add(value);
      } else {
        _collectBindingRefs(value, refs);
      }
    }
  }
}

void main() {
  const catalogPath = 'assets/guidance/evidence_registry_catalog_v1.json';

  test('evidence registry catalog references existing registry files', () {
    final catalog = _readJsonFile(catalogPath);
    final registries = catalog['registries'];
    expect(registries, isA<List>());

    for (final raw in registries as List) {
      expect(raw, isA<Map>());
      final mapped = Map<String, dynamic>.from(raw as Map);
      final path = mapped['path']?.toString() ?? '';
      expect(path, isNotEmpty, reason: 'Every catalog entry needs a path.');
      expect(
        File(path).existsSync(),
        isTrue,
        reason: 'Missing registry file: $path',
      );
    }
  });

  test('all registries have valid schema structure and coverage', () {
    final catalog = _readJsonFile(catalogPath);
    final registries = (catalog['registries'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    for (final registryEntry in registries) {
      final registryId = registryEntry['id']?.toString() ?? 'unknown_registry';
      final path = registryEntry['path']?.toString() ?? '';
      final registry = _readJsonFile(path);

      expect(registry['meta'], isA<Map>(), reason: '$registryId missing meta');
      expect(
        registry['policyBindings'],
        isA<Map>(),
        reason: '$registryId missing policyBindings',
      );
      expect(
        registry['evidenceItems'],
        isA<List>(),
        reason: '$registryId missing evidenceItems',
      );

      final evidenceItems = (registry['evidenceItems'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      expect(
        evidenceItems.isNotEmpty,
        isTrue,
        reason: '$registryId must include at least one evidence item.',
      );

      final evidenceIds = <String>{};
      final evidenceById = <String, Map<String, dynamic>>{};
      for (final item in evidenceItems) {
        final id = item['id']?.toString() ?? '';
        expect(
          id,
          isNotEmpty,
          reason: '$registryId has evidence item without id.',
        );
        expect(
          evidenceIds.add(id),
          isTrue,
          reason: '$registryId duplicate id: $id',
        );
        evidenceById[id] = item;

        final sourceRefs = item['sourceRefs'];
        expect(
          sourceRefs,
          isA<List>(),
          reason: '$registryId.$id missing sourceRefs list.',
        );
        final refs = (sourceRefs as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        expect(
          refs.isNotEmpty,
          isTrue,
          reason: '$registryId.$id needs at least 1 source.',
        );

        final classification =
            item['classification']?.toString() ?? 'behavioral';
        if (classification == 'safety_legal') {
          expect(
            refs.length >= 2,
            isTrue,
            reason:
                '$registryId.$id is safety_legal and needs at least 2 sources.',
          );
        }

        for (final ref in refs) {
          expect(
            (ref['citation']?.toString() ?? '').isNotEmpty,
            isTrue,
            reason: '$registryId.$id has source without citation.',
          );
          expect(
            (ref['url']?.toString() ?? '').isNotEmpty,
            isTrue,
            reason: '$registryId.$id has source without url.',
          );
        }
      }

      final bindingRefs = <String>{};
      _collectBindingRefs(registry['policyBindings'], bindingRefs);
      expect(
        bindingRefs.isNotEmpty,
        isTrue,
        reason: '$registryId must bind at least one policy key to evidence.',
      );
      for (final refId in bindingRefs) {
        expect(
          evidenceById.containsKey(refId),
          isTrue,
          reason:
              '$registryId policyBindings reference unknown evidence id: $refId',
        );
      }

      if (registryId == 'safety_legal') {
        for (final refId in bindingRefs) {
          final item = evidenceById[refId]!;
          final classification = item['classification']?.toString() ?? '';
          expect(
            classification == 'safety_legal',
            isTrue,
            reason:
                'safety_legal registry binding $refId must map to safety_legal evidence.',
          );
          final refs = item['sourceRefs'] as List;
          expect(
            refs.length >= 2,
            isTrue,
            reason: 'safety_legal binding $refId must have >=2 sourceRefs.',
          );
        }
      }
    }
  });
}
