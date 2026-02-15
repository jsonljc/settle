/// Tantrum-specific content card for Crisis View, CARDS library, and Protocol.
/// Not shared with Sleep or Help Now; do not change existing contracts.
class TantrumCard {
  const TantrumCard({
    required this.id,
    required this.title,
    required this.say,
    required this.doStep,
    required this.ifEscalates,
    this.lessonId,
  });

  final String id;
  final String title;
  final String say;
  final String doStep;
  final String ifEscalates;
  final String? lessonId;

  factory TantrumCard.fromJson(Map<String, dynamic> json) {
    return TantrumCard(
      id: json['id'] as String,
      title: json['title'] as String,
      say: json['say'] as String,
      doStep: json['do'] as String,
      ifEscalates: json['ifEscalates'] as String,
      lessonId: json['lessonId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'say': say,
      'do': doStep,
      'ifEscalates': ifEscalates,
      if (lessonId != null) 'lessonId': lessonId,
    };
  }
}
