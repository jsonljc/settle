/// Structured data for Moment flow script variants.
/// Max 2 sentences per script. Content layer only — no UI.
enum MomentScriptVariant {
  boundary,
  connection,
}

class MomentScript {
  const MomentScript({
    required this.variant,
    required this.lines,
  }) : assert(lines.length >= 1 && lines.length <= 2);

  final MomentScriptVariant variant;
  /// One or two short sentences. No hardcoded UI strings here.
  final List<String> lines;

  static MomentScriptVariant _variantFromWire(String? raw) {
    switch ((raw ?? 'boundary').trim().toLowerCase()) {
      case 'connection':
        return MomentScriptVariant.connection;
      case 'boundary':
      default:
        return MomentScriptVariant.boundary;
    }
  }

  static List<String> _linesFromJson(dynamic raw) {
    if (raw == null) return const [];
    if (raw is String) return [raw.trim()];
    if (raw is List) {
      final list = raw
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .take(2)
          .toList();
      return list.isEmpty ? const ['You’re here. Breathe.'] : list;
    }
    return const ['You’re here. Breathe.'];
  }

  factory MomentScript.fromJson(Map<String, dynamic> json) {
    final lines = _linesFromJson(json['lines']);
    final capped = lines.length > 2 ? lines.sublist(0, 2) : lines;
    return MomentScript(
      variant: _variantFromWire(json['variant'] as String?),
      lines: capped.isEmpty ? const ['You’re here. Breathe.'] : capped,
    );
  }
}
