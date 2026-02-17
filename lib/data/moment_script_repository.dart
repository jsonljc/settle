import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/moment_script.dart';

/// Loads Moment script variants from bundled content.
/// Content layer only — no UI.
class MomentScriptRepository {
  MomentScriptRepository._();

  static final MomentScriptRepository instance = MomentScriptRepository._();
  static const _scriptsPath = 'assets/guidance/moment_scripts.json';

  List<MomentScript>? _scripts;

  Future<void> _ensureLoaded() async {
    if (_scripts != null) return;
    final raw = await rootBundle.loadString(_scriptsPath);
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final list = map['scripts'] as List<dynamic>? ?? [];
    _scripts = list
        .whereType<Map>()
        .map((e) => MomentScript.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Returns all script variants (e.g. Boundary, Connection).
  Future<List<MomentScript>> loadAll() async {
    await _ensureLoaded();
    return List.unmodifiable(_scripts!);
  }

  /// Returns the script for the given variant, or null if not found.
  Future<MomentScript?> getByVariant(MomentScriptVariant variant) async {
    await _ensureLoaded();
    try {
      return _scripts!.firstWhere((s) => s.variant == variant);
    } catch (_) {
      return null;
    }
  }
}
