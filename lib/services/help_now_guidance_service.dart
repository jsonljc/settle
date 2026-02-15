import 'dart:convert';

import 'package:flutter/services.dart';

import 'spec_policy.dart';

class HelpNowGuidanceOutput {
  const HelpNowGuidanceOutput({
    required this.say,
    required this.doStep,
    required this.timerMinutes,
    required this.ifEscalates,
    required this.evidenceRefs,
  });

  final String say;
  final String doStep;
  final int timerMinutes;
  final String ifEscalates;
  final List<String> evidenceRefs;
}

class HelpNowGuidanceService {
  HelpNowGuidanceService._();

  static final HelpNowGuidanceService instance = HelpNowGuidanceService._();

  static const _guidancePath = 'assets/guidance/help_now_guidance_v1.json';
  static const _evidencePath =
      'assets/guidance/help_now_evidence_registry_v1.json';

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
      throw StateError('Expected object at top-level for $path');
    }
    return Map<String, dynamic>.from(decoded);
  }

  List<String> _evidenceRefsForIncident(String incidentId) {
    final policyBindings = _asMap(_evidence?['policyBindings']);
    final incidents = _asMap(policyBindings['incidents']);
    final refs = _asStringList(incidents[incidentId]);
    return refs..sort();
  }

  Future<bool> isSleepRoutedIncident(String incidentId) async {
    await _ensureLoaded();
    final routing = _asMap(_guidance?['nightRouting']);
    final sleepIncidentIds = _asStringList(routing['sleepIncidentIds']);
    return sleepIncidentIds.contains(incidentId);
  }

  Future<bool> shouldRouteIncidentToSleepNow({
    required String incidentId,
    required DateTime timestamp,
    bool hasActiveSleepPlan = false,
    bool fallbackSleepIncident = false,
  }) async {
    var sleepIncident = fallbackSleepIncident;
    try {
      sleepIncident = await isSleepRoutedIncident(incidentId);
    } catch (_) {
      sleepIncident = fallbackSleepIncident;
    }

    return SpecPolicy.shouldRouteNowToSleep(
      timestamp: timestamp,
      hasActiveSleepPlan: hasActiveSleepPlan,
      sleepIncident: sleepIncident,
    );
  }

  Future<HelpNowGuidanceOutput> resolveIncidentOutput({
    required String incidentId,
    required String ageBand,
  }) async {
    await _ensureLoaded();

    final incidents = _asMapList(_guidance?['incidents']);
    final incident = incidents.firstWhere(
      (i) => i['id']?.toString() == incidentId,
      orElse: () => {},
    );
    if (incident.isEmpty) {
      throw StateError('Unknown Help Now incident: $incidentId');
    }

    final defaults = _asMap(incident['default']);
    final overrides = _asMap(incident['ageBandOverrides']);
    final ageOverride = _asMap(overrides[ageBand]);

    final say = _readString(ageOverride, defaults, 'say');
    final doStep = _readString(ageOverride, defaults, 'doStep');
    final ifEscalates = _readString(ageOverride, defaults, 'ifEscalates');
    final timerMinutes = _readInt(ageOverride, defaults, 'timerMinutes');
    final evidenceRefs = _evidenceRefsForIncident(incidentId);

    return HelpNowGuidanceOutput(
      say: say,
      doStep: doStep,
      timerMinutes: timerMinutes,
      ifEscalates: ifEscalates,
      evidenceRefs: evidenceRefs,
    );
  }

  String _readString(
    Map<String, dynamic> overrideMap,
    Map<String, dynamic> baseMap,
    String key,
  ) {
    final overrideValue = overrideMap[key]?.toString();
    if (overrideValue != null && overrideValue.isNotEmpty) {
      return overrideValue;
    }
    final baseValue = baseMap[key]?.toString() ?? '';
    if (baseValue.isEmpty) {
      throw StateError('Missing required "$key" in Help Now guidance.');
    }
    return baseValue;
  }

  int _readInt(
    Map<String, dynamic> overrideMap,
    Map<String, dynamic> baseMap,
    String key,
  ) {
    final overrideValue = overrideMap[key];
    if (overrideValue is num) return overrideValue.toInt();
    final parsedOverride = int.tryParse(overrideValue?.toString() ?? '');
    if (parsedOverride != null) return parsedOverride;

    final baseValue = baseMap[key];
    if (baseValue is num) return baseValue.toInt();
    final parsedBase = int.tryParse(baseValue?.toString() ?? '');
    if (parsedBase != null) return parsedBase;

    throw StateError('Missing required integer "$key" in Help Now guidance.');
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
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
