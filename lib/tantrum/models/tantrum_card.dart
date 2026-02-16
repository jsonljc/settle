/// Tantrum-specific card model.
///
/// v2 supports an instant-capture flow with rule-based card selection:
/// trigger × intensity × parentReaction, with trigger-only fallback.
///
/// Backward compatibility:
/// - `ifEscalates` remains available for legacy Crisis screens.
/// - `lessonId` remains available for legacy Learn linking.
enum TantrumCardTier { free, premium }

class TantrumCardMatch {
  const TantrumCardMatch({
    required this.trigger,
    this.intensity,
    this.parentReaction,
  });

  final String trigger;
  final String? intensity;
  final String? parentReaction;

  bool get isTriggerOnly => intensity == null && parentReaction == null;

  /// Higher specificity wins when multiple cards match.
  int get specificity {
    var value = 1; // trigger is always required.
    if (intensity != null) value += 1;
    if (parentReaction != null) value += 1;
    return value;
  }

  bool matches({
    required String trigger,
    String? intensity,
    String? parentReaction,
  }) {
    if (this.trigger != trigger) return false;
    if (this.intensity != null && this.intensity != intensity) return false;
    if (this.parentReaction != null && this.parentReaction != parentReaction) {
      return false;
    }
    return true;
  }

  factory TantrumCardMatch.fromJson(Map<String, dynamic> json) {
    final intensity = (json['intensity'] as String?)?.trim();
    final parentReaction = (json['parentReaction'] as String?)?.trim();
    return TantrumCardMatch(
      trigger: (json['trigger'] as String).trim(),
      intensity: intensity == null || intensity.isEmpty ? null : intensity,
      parentReaction: parentReaction == null || parentReaction.isEmpty
          ? null
          : parentReaction,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'trigger': trigger,
      if (intensity != null) 'intensity': intensity,
      if (parentReaction != null) 'parentReaction': parentReaction,
    };
  }
}

class TantrumCard {
  const TantrumCard({
    required this.id,
    required this.title,
    required this.remember,
    required this.say,
    required this.doStep,
    required this.ifEscalates,
    required this.packId,
    required this.tier,
    this.matchRules = const [],
    this.lessonId,
  });

  final String id;
  final String title;
  final String remember;
  final String say;
  final String doStep;
  final String ifEscalates;
  final String packId;
  final TantrumCardTier tier;
  final List<TantrumCardMatch> matchRules;
  final String? lessonId;

  bool get isPremium => tier == TantrumCardTier.premium;

  static TantrumCardTier _tierFromWire(String? raw) {
    switch ((raw ?? 'free').trim().toLowerCase()) {
      case 'premium':
        return TantrumCardTier.premium;
      case 'free':
      default:
        return TantrumCardTier.free;
    }
  }

  static String _tierToWire(TantrumCardTier tier) {
    switch (tier) {
      case TantrumCardTier.free:
        return 'free';
      case TantrumCardTier.premium:
        return 'premium';
    }
  }

  factory TantrumCard.fromJson(Map<String, dynamic> json) {
    final rememberRaw = (json['remember'] as String?)?.trim();
    final matchRaw = json['match'];
    final parsedMatch = matchRaw is List
        ? matchRaw
              .whereType<Map>()
              .map(
                (e) => TantrumCardMatch.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : const <TantrumCardMatch>[];

    return TantrumCard(
      id: json['id'] as String,
      title: json['title'] as String,
      remember: (rememberRaw == null || rememberRaw.isEmpty)
          ? 'You may notice a hard moment is here. You are not alone.'
          : rememberRaw,
      say: json['say'] as String,
      doStep: json['do'] as String,
      ifEscalates:
          (json['ifEscalates'] as String?) ?? (json['do'] as String? ?? ''),
      packId: (json['packId'] as String?) ?? 'base',
      tier: _tierFromWire(json['tier'] as String?),
      matchRules: parsedMatch,
      lessonId: json['lessonId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'remember': remember,
      'say': say,
      'do': doStep,
      'ifEscalates': ifEscalates,
      'packId': packId,
      'tier': _tierToWire(tier),
      if (matchRules.isNotEmpty)
        'match': matchRules.map((rule) => rule.toJson()).toList(),
      if (lessonId != null) 'lessonId': lessonId,
    };
  }
}
