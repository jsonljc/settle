/// Content model for repair cards used in Reset and related flows.
///
/// Kept separate from UI. All user-facing strings come from registry/content.
enum RepairCardContext {
  general,
  sleep,
  tantrum,
}

enum RepairCardState {
  self,
  child,
}

/// A single repair card: id, title, short body, context/state, tags, style weights.
class RepairCard {
  const RepairCard({
    required this.id,
    required this.title,
    required this.body,
    required this.context,
    required this.state,
    this.tags = const [],
    this.warmthWeight = 0.5,
    this.structureWeight = 0.5,
  })  : assert(warmthWeight >= 0 && warmthWeight <= 1),
        assert(structureWeight >= 0 && structureWeight <= 1);

  final String id;
  final String title;
  /// Short copy; max 3 sentences in content source.
  final String body;
  final RepairCardContext context;
  final RepairCardState state;
  /// E.g. boundary, connection, co-regulation.
  final List<String> tags;
  /// 0 = structure-first, 1 = warmth-first.
  final double warmthWeight;
  /// 0 = warmth-first, 1 = structure-first.
  final double structureWeight;

  static RepairCardContext _contextFromWire(String? raw) {
    switch ((raw ?? 'general').trim().toLowerCase()) {
      case 'sleep':
        return RepairCardContext.sleep;
      case 'tantrum':
        return RepairCardContext.tantrum;
      case 'general':
      default:
        return RepairCardContext.general;
    }
  }

  static RepairCardState _stateFromWire(String? raw) {
    switch ((raw ?? 'child').trim().toLowerCase()) {
      case 'self':
        return RepairCardState.self;
      case 'child':
      default:
        return RepairCardState.child;
    }
  }

  static List<String> _tagsFromJson(dynamic raw) {
    if (raw == null) return const [];
    if (raw is List) {
      return raw
          .whereType<String>()
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return const [];
  }

  static double _clampWeight(dynamic raw, [double def = 0.5]) {
    if (raw == null) return def;
    if (raw is int) return (raw.clamp(0, 1).toDouble());
    if (raw is double) return raw.clamp(0.0, 1.0);
    return def;
  }

  factory RepairCard.fromJson(Map<String, dynamic> json) {
    return RepairCard(
      id: (json['id'] as String).trim(),
      title: (json['title'] as String).trim(),
      body: (json['body'] as String).trim(),
      context: _contextFromWire(json['context'] as String?),
      state: _stateFromWire(json['state'] as String?),
      tags: _tagsFromJson(json['tags']),
      warmthWeight: _clampWeight(json['warmthWeight']),
      structureWeight: _clampWeight(json['structureWeight']),
    );
  }
}
