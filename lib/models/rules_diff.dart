class RulesDiffStatus {
  static const pending = 'pending';
  static const accepted = 'accepted';
  static const resolved = 'resolved';

  static const all = {pending, accepted, resolved};
}

class RulesDiff {
  const RulesDiff({
    required this.diffId,
    required this.changedRuleId,
    required this.oldValue,
    required this.newValue,
    required this.author,
    required this.timestamp,
    required this.rulesetVersion,
    this.status = RulesDiffStatus.pending,
    this.schemaVersion = schemaVersionV1,
  });

  static const schemaVersionV1 = 1;

  final String diffId;
  final String changedRuleId;
  final String oldValue;
  final String newValue;
  final String author;
  final String timestamp;
  final int rulesetVersion;
  final String status;
  final int schemaVersion;

  RulesDiff copyWith({String? status, int? rulesetVersion}) {
    return RulesDiff(
      diffId: diffId,
      changedRuleId: changedRuleId,
      oldValue: oldValue,
      newValue: newValue,
      author: author,
      timestamp: timestamp,
      rulesetVersion: rulesetVersion ?? this.rulesetVersion,
      status: status ?? this.status,
      schemaVersion: schemaVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schema_version': schemaVersion,
      'diff_id': diffId,
      'changed_rule_id': changedRuleId,
      'old_value': oldValue,
      'new_value': newValue,
      'author': author,
      'timestamp': timestamp,
      'ruleset_version': rulesetVersion,
      'status': status,
    };
  }

  static RulesDiff? tryFrom(dynamic raw) {
    if (raw is! Map) return null;
    final mapped = Map<String, dynamic>.from(raw);

    final diffId = mapped['diff_id']?.toString() ?? '';
    final changedRuleId = mapped['changed_rule_id']?.toString() ?? '';
    final oldValue = mapped['old_value']?.toString() ?? '';
    final newValue = mapped['new_value']?.toString() ?? '';
    final author = mapped['author']?.toString() ?? '';
    final timestamp = mapped['timestamp']?.toString() ?? '';
    final rulesetVersion = mapped['ruleset_version'] is int
        ? mapped['ruleset_version'] as int
        : int.tryParse(mapped['ruleset_version']?.toString() ?? '') ?? 1;
    final status = mapped['status']?.toString() ?? RulesDiffStatus.pending;
    final schemaVersion = mapped['schema_version'] is int
        ? mapped['schema_version'] as int
        : int.tryParse(mapped['schema_version']?.toString() ?? '') ??
              schemaVersionV1;

    if (diffId.isEmpty ||
        changedRuleId.isEmpty ||
        author.isEmpty ||
        timestamp.isEmpty) {
      return null;
    }

    return RulesDiff(
      diffId: diffId,
      changedRuleId: changedRuleId,
      oldValue: oldValue,
      newValue: newValue,
      author: author,
      timestamp: timestamp,
      rulesetVersion: rulesetVersion,
      status: RulesDiffStatus.all.contains(status)
          ? status
          : RulesDiffStatus.pending,
      schemaVersion: schemaVersion,
    );
  }
}
