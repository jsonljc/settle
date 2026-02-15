import 'dart:convert';

import 'package:flutter/services.dart';

class PlanProgressRecommendation {
  const PlanProgressRecommendation({
    required this.bottleneck,
    required this.evidence,
    required this.experiment,
    required this.triggerEventType,
    required this.triggerCount,
    required this.evidenceRefs,
  });

  final String bottleneck;
  final String evidence;
  final String experiment;
  final String triggerEventType;
  final int triggerCount;
  final List<String> evidenceRefs;
}

class PlanProgressGuidanceService {
  PlanProgressGuidanceService._();

  static final PlanProgressGuidanceService instance =
      PlanProgressGuidanceService._();

  static const _guidancePath = 'assets/guidance/plan_progress_guidance_v1.json';
  static const _evidencePath =
      'assets/guidance/plan_progress_evidence_registry_v1.json';
  static const _signalEventTypes = <String>{
    'HN_USED_TANTRUM',
    'HN_USED_AGGRESSION',
    'HN_USED_UNSAFE',
    'HN_USED_REFUSAL',
    'HN_USED_PUBLIC',
    'HN_USED_PARENT_OVERWHELM',
    'ST_NIGHT_WAKE_LOGGED',
    'ST_EARLY_WAKE_LOGGED',
  };

  Map<String, dynamic>? _guidance;
  Map<String, dynamic>? _evidence;

  Future<void> _ensureLoaded() async {
    _guidance ??= await _loadJson(_guidancePath);
    _evidence ??= await _loadJson(_evidencePath);
  }

  Future<Map<String, dynamic>> _loadJson(String path) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw StateError('Expected top-level object in $path');
    }
    return Map<String, dynamic>.from(decoded);
  }

  Future<PlanProgressRecommendation?> recommendFromEvents(
    List<Map<String, dynamic>> events,
  ) async {
    await _ensureLoaded();

    final counts = <String, int>{};
    for (final event in events) {
      final type = event['type'];
      if (type is! String ||
          type.isEmpty ||
          !_signalEventTypes.contains(type)) {
        continue;
      }
      counts[type] = (counts[type] ?? 0) + 1;
    }

    final defaultMinSimilar = _defaultMinSimilarEvents();
    final rules = _asMapList(_guidance?['recommendationRules']);
    for (final rule in rules) {
      final eventType = rule['eventType']?.toString() ?? '';
      final minCount = _asInt(rule['minCount'], fallback: defaultMinSimilar);
      final count = counts[eventType] ?? 0;
      if (eventType.isEmpty || count < minCount) continue;

      final bottleneck =
          rule['bottleneck']?.toString() ?? 'High-friction moments';
      final evidenceTemplate =
          rule['evidenceTemplate']?.toString() ??
          '{count} events in last 14 days';
      final experiment =
          rule['experiment']?.toString() ??
          'Pick one script and repeat for one week.';
      final evidenceBindingKey = rule['evidenceBindingKey']?.toString() ?? '';
      final experimentBindingKey =
          rule['experimentBindingKey']?.toString() ?? '';
      final evidence = _fillTemplate(
        evidenceTemplate,
        count: count,
        eventType: eventType,
      );
      final evidenceRefs = _refsFor(
        evidenceBindingKey: evidenceBindingKey,
        experimentBindingKey: experimentBindingKey,
      );

      return PlanProgressRecommendation(
        bottleneck: bottleneck,
        evidence: evidence,
        experiment: experiment,
        triggerEventType: eventType,
        triggerCount: count,
        evidenceRefs: evidenceRefs,
      );
    }

    final fallback = _asMap(_guidance?['fallback']);
    final minAnySimilar = _asInt(
      fallback['minAnySimilar'],
      fallback: defaultMinSimilar,
    );
    final ranked = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (ranked.isEmpty || ranked.first.value < minAnySimilar) {
      return null;
    }

    final top = ranked.first;
    final bottleneck =
        fallback['bottleneck']?.toString() ?? 'High-friction moments';
    final evidenceTemplate =
        fallback['evidenceTemplate']?.toString() ??
        '{count} similar events ({eventType}) in last 14 days';
    final experiment =
        fallback['experiment']?.toString() ??
        'Pick one script and one timer, repeat exactly for one week.';
    final evidence = _fillTemplate(
      evidenceTemplate,
      count: top.value,
      eventType: top.key,
    );

    return PlanProgressRecommendation(
      bottleneck: bottleneck,
      evidence: evidence,
      experiment: experiment,
      triggerEventType: top.key,
      triggerCount: top.value,
      evidenceRefs: const [],
    );
  }

  int _defaultMinSimilarEvents() {
    final eligibility = _asMap(_guidance?['eligibility']);
    return _asInt(eligibility['minSimilarEvents14d'], fallback: 3);
  }

  List<String> _refsFor({
    required String evidenceBindingKey,
    required String experimentBindingKey,
  }) {
    final policyBindings = _asMap(_evidence?['policyBindings']);
    final bottlenecks = _asMap(policyBindings['bottlenecks']);
    final experiments = _asMap(policyBindings['experiments']);
    final refs = <String>{
      ..._asStringList(bottlenecks[evidenceBindingKey]),
      ..._asStringList(experiments[experimentBindingKey]),
    };
    final sorted = refs.toList()..sort();
    return sorted;
  }

  String _fillTemplate(
    String template, {
    required int count,
    required String eventType,
  }) {
    return template
        .replaceAll('{count}', '$count')
        .replaceAll('{eventType}', eventType);
  }

  int _asInt(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
}
