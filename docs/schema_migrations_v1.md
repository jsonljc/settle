# Settle OS v1 Schema Migration Notes

Updated: 2026-02-13

## Event Bus
- Storage: `event_bus_v1` (Hive)
- `schema_version`: `1`
- `taxonomy_version`: `1`
- Canonical pillars: `HELP_NOW`, `SLEEP_TONIGHT`, `PLAN_PROGRESS`, `FAMILY_RULES`
- Canonical types: enforced by `lib/services/event_bus_service.dart`
- Migration behavior:
  - Legacy events are normalized on read via `_normalizeEvent`.
  - Unknown tags are dropped during migration path; known legacy alias `screen` is normalized to `screens`.
  - Invalid pillar/type combinations are remapped by canonical type ownership where possible.
  - Migrated events are rewritten back to storage.

## Family Rules
- Storage: `family_rules_v1` (Hive)
- Contract fields:
  - `ruleset_version` (int)
  - `pending_diffs` as typed `RulesDiff` objects
  - `change_feed` event log entries
- `RulesDiff` contract (`lib/models/rules_diff.dart`):
  - `schema_version`: `1`
  - required: `diff_id`, `changed_rule_id`, `old_value`, `new_value`, `author`, `timestamp`, `ruleset_version`
  - `status`: `pending | accepted | resolved`
- Migration behavior:
  - Legacy map-style pending diffs are upgraded through `RulesDiff.tryFrom`.
  - Missing schema/status fields are backfilled to v1 defaults.

## Rollout State
- Storage: `release_rollout_v1` (Hive)
- `schema_version`: `1`
- Flags:
  - `help_now_enabled`
  - `sleep_tonight_enabled`
  - `plan_progress_enabled`
  - `family_rules_enabled`
  - `metrics_dashboard_enabled`
  - `compliance_checklist_enabled`
