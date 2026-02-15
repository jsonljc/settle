import 'dart:convert';

import 'package:flutter/services.dart';

class FamilyRulesGuidanceService {
  FamilyRulesGuidanceService._();

  static final FamilyRulesGuidanceService instance =
      FamilyRulesGuidanceService._();

  static const _guidancePath = 'assets/guidance/family_rules_guidance_v1.json';
  static const _evidencePath =
      'assets/guidance/family_rules_evidence_registry_v1.json';

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

  Future<Map<String, String>> defaultRules() async {
    await _ensureLoaded();
    final rules = _asMap(_guidance?['rules']);
    final out = <String, String>{};
    for (final entry in rules.entries) {
      final id = entry.key.toString();
      final spec = _asMap(entry.value);
      final value = spec['default']?.toString() ?? '';
      if (id.isEmpty || value.isEmpty) continue;
      out[id] = value;
    }
    return out;
  }

  Future<Set<String>> allowedRuleIds() async {
    final defaults = await defaultRules();
    return defaults.keys.toSet();
  }

  Future<List<String>> evidenceRefsForRule(String ruleId) async {
    await _ensureLoaded();
    final policyBindings = _asMap(_evidence?['policyBindings']);
    final ruleBindings = _asMap(policyBindings['ruleIds']);
    final refs = _asStringList(ruleBindings[ruleId])..sort();
    return refs;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return {};
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
}
