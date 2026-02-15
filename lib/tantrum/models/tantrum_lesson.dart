/// Micro-lesson for Tantrum LEARN tab. Links to cards via cardIds.
class TantrumLesson {
  const TantrumLesson({
    required this.id,
    required this.title,
    required this.body,
    required this.cardIds,
  });

  final String id;
  final String title;
  final String body;
  final List<String> cardIds;

  factory TantrumLesson.fromJson(Map<String, dynamic> json) {
    final cardIdsRaw = json['cardIds'];
    final cardIds = cardIdsRaw is List
        ? (cardIdsRaw).map((e) => e.toString()).toList()
        : <String>[];
    return TantrumLesson(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      cardIds: cardIds,
    );
  }
}
