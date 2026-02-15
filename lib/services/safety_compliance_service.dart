import 'dart:convert';

import 'package:flutter/services.dart';

class ComplianceChecklistItem {
  const ComplianceChecklistItem({
    required this.id,
    required this.title,
    required this.detail,
    required this.passed,
  });

  final String id;
  final String title;
  final String detail;
  final bool passed;
}

class ComplianceChecklistSnapshot {
  const ComplianceChecklistSnapshot({
    required this.items,
    required this.updatedAt,
  });

  final List<ComplianceChecklistItem> items;
  final String updatedAt;
}

class SafetyComplianceService {
  const SafetyComplianceService();

  static const _safetyRegistryPath =
      'assets/guidance/safety_legal_evidence_registry_v1.json';
  static const _sleepModulePath = 'assets/guidance/sleep_tonight_complete.json';

  Future<ComplianceChecklistSnapshot> loadChecklist() async {
    final safety = await _loadJson(_safetyRegistryPath);
    final sleepModule = await _loadJson(_sleepModulePath);
    final safetyMeta = _asMap(safety['meta']);
    final updatedAt = safetyMeta['updatedAt']?.toString() ?? 'unknown';

    final policyBindings = _asMap(safety['policyBindings']);
    final redFlagGates = _asMap(policyBindings['redFlagGates']);
    final liability = _asMap(policyBindings['liabilityBoundaries']);
    final privacy = _asMap(policyBindings['privacyCompliance']);

    final sleepSafety = _asMap(sleepModule['safety']);
    final stopRules = _asMapList(sleepSafety['stopRules']);
    final stopRuleIds = stopRules
        .map((r) => r['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();

    final hasBehavioralBoundary = _hasListBinding(
      liability,
      'behavioral_not_medical',
    );
    final hasFeedingBoundary = _hasListBinding(
      liability,
      'feeding_behavioral_scope_only',
    );
    final hasPrivacyChecklist =
        _hasListBinding(privacy, 'coppa_children_data') &&
        _hasListBinding(privacy, 'health_breach_notification') &&
        _hasListBinding(privacy, 'hipaa_boundary_for_consumer_apps');
    final hasRedFlagGates =
        _hasListBinding(redFlagGates, 'breathing_difficulty') &&
        _hasListBinding(redFlagGates, 'dehydration_signs') &&
        _hasListBinding(redFlagGates, 'repeated_vomiting') &&
        _hasListBinding(redFlagGates, 'severe_pain_indicators') &&
        _hasListBinding(redFlagGates, 'feeding_refusal_with_pain_signs');
    final hasSleepStopRules =
        stopRuleIds.contains('stop_if_red_flag') &&
        stopRuleIds.contains('stop_if_unsafe_sleep_env');

    final items = <ComplianceChecklistItem>[
      ComplianceChecklistItem(
        id: 'behavioral_not_medical',
        title: 'Behavioral-not-medical boundary',
        detail:
            'Product guidance must remain behavioral support, not diagnosis or treatment.',
        passed: hasBehavioralBoundary,
      ),
      ComplianceChecklistItem(
        id: 'red_flag_redirects',
        title: 'Red-flag redirect gate',
        detail:
            'Breathing, dehydration, vomiting, pain, and feeding pain signs pause tactics and redirect.',
        passed: hasRedFlagGates && hasSleepStopRules,
      ),
      ComplianceChecklistItem(
        id: 'feeding_scope_exclusion',
        title: 'Feeding physiological exclusions',
        detail:
            'Behavioral feeding support is allowed; pain-sign refusal is excluded to clinical guidance.',
        passed: hasFeedingBoundary,
      ),
      ComplianceChecklistItem(
        id: 'privacy_regulatory',
        title: 'Privacy/regulatory checklist',
        detail:
            'COPPA, breach notification, and HIPAA-boundary references are mapped in registry.',
        passed: hasPrivacyChecklist,
      ),
    ];

    return ComplianceChecklistSnapshot(items: items, updatedAt: updatedAt);
  }

  static bool _hasListBinding(Map<String, dynamic> section, String key) {
    final raw = section[key];
    if (raw is! List) return false;
    return raw.isNotEmpty;
  }

  static Future<Map<String, dynamic>> _loadJson(String path) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.from(decoded);
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is! Map) return <String, dynamic>{};
    return Map<String, dynamic>.from(raw);
  }

  static List<Map<String, dynamic>> _asMapList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }
}
