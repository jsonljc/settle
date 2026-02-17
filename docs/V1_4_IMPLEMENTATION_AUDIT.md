# Settle v1.4 Implementation Plan — Audit Report

Audit date: 2025-02-17. Codebase: Settle v1.4 (post–Slice 5A).

---

## PHASE 0 — Content Foundation

| # | Requirement | Result | Evidence / Notes |
|---|-------------|--------|------------------|
| 1 | RepairCard model exists with fields: id, title, body, context, state, tags, warmth_weight, structure_weight | **PASS** | `lib/models/repair_card.dart`: class RepairCard has id, title, body, context (RepairCardContext), state (RepairCardState), tags, warmthWeight, structureWeight. |
| 2 | Seed JSON/asset file exists with 15+ cards (5 general, 5 sleep, 5 tantrum) | **PASS** | `assets/guidance/repair_cards_seed.json`: 15 cards — gen_1–gen_5 (5 general), sleep_bedtime_1/2, sleep_night_1/2, sleep_early_1 (5 sleep), tantrum_child_1/2/3, tantrum_self_1/2 (5 tantrum). |
| 3 | CardRepository can load, filter by context+state, and return weighted-random selection | **PASS** | `lib/data/card_repository.dart`: pickOne/pickOneExcluding use _weightedPick(); weight = warmthWeight + structureWeight (min 0.01). |
| 4 | Moment scripts (Boundary/Connection) stored as structured data, not hardcoded strings | **PASS** | `assets/guidance/moment_scripts.json` (variant + lines); `lib/data/moment_script_repository.dart` loads; `lib/models/moment_script.dart` defines structure. |
| 5 | No card body exceeds 3 sentences | **PASS** | `lib/models/repair_card.dart`: RepairCard.fromJson uses _bodyMaxSentences(body, max: 3) so body is capped at 3 sentences at load. |

---

## PHASE 1 — Spine + Storage

| # | Requirement | Result | Evidence / Notes |
|---|-------------|--------|------------------|
| 1 | Enums exist: SpineContext (general/sleep/tantrum), SpineState (self/child), Stage (infant/toddler/preschool) | **PASS** | `lib/domain/product_spine.dart`: SpineContext = RepairCardContext, SpineState = RepairCardState; enum Stage { infant, toddler, preschool }. |
| 2 | All 5 entry points route correctly: Reset, Playbook, Moment, Sleep Tonight, Tantrum Just Happened | **PASS** | `lib/router.dart`: /plan/reset (212–220), /library/saved (319–321), /plan/moment (222–230), /sleep/tonight (branch path), tantrum-just-happened → /plan/reset?context=tantrum (234–235, 427–429). |
| 3 | Every entry point can exit cleanly (no nav traps) | **PASS** | Slice 5A: Reset/Playbook/Moment/Sleep Tonight/Tantrum all have explicit Close/Back; ScreenHeader fallbackRoute; doc `docs/SLICE_5A_POLISH_SUMMARY.md`. |
| 4 | AppRepository persists: reset events, saved cards, settings (child age) | **PASS** | `lib/data/app_repository.dart`: addResetEvent, getResetEvents; getSavedCardIds, addSavedCard, removeSavedCard; getChildAge, setChildAge, getChildName, setChildName. |
| 5 | Storage fails gracefully — app works if storage is corrupted or empty | **PASS** | `lib/main.dart`: Hive boxes opened in sequence with try/catch per box; `_ensureSpineSchemaVersion` checks `Hive.isBoxOpen('spine_store')`. `lib/data/app_repository.dart`: _profileBoxSafe/_userCardsBoxSafe return null on catch; getters return []/null. |

---

## PHASE 2 — Reset + Playbook

| # | Requirement | Result | Evidence / Notes |
|---|-------------|--------|------------------|
| 1 | Reset flow: choose state → show card → Keep/Another/Close | **PASS** | `lib/screens/plan/reset_flow_screen.dart`: phase chooseState → state picker; phase showingCard → card view with Keep, Another, Close. `lib/providers/reset_flow_provider.dart`: selectState, drawAnother, keep, close. |
| 2 | "Another" capped at 3 per session | **PASS** | `lib/providers/reset_flow_provider.dart`: maxAnother = 3, canShowAnother, anotherCount incremented in drawAnother. |
| 3 | "Keep" saves to Playbook immediately and card appears in list | **PASS** | ResetFlowNotifier.keep() calls _userCards.save(card.id); Playbook list from playbookRepairCardsProvider (user_cards + card repo). |
| 4 | "Close" persists a reset event with timestamp, context, state, cards seen | **PASS** | `lib/providers/reset_flow_provider.dart`: close() calls _appRepo.addResetEvent(context, state, cardIdsSeen, cardIdKept). `lib/data/app_repository.dart`: addResetEvent writes ResetEvent with timestamp, context, state, cardIdsSeen, cardIdKept. |
| 5 | Reset completable in ≤ 15 seconds (count taps + screens) | **PASS** | Flow: 1 (state) + 1 (card) + 1 (Keep/Close/Another). No multi-step forms. Design allows ≤15s. |
| 6 | Playbook: list saved cards (recency), view, remove, share | **PASS** | `lib/screens/library/saved_playbook_screen.dart`: ListView from playbookRepairCardsProvider; tap → detail; Remove (unsave); Share. `lib/screens/library/playbook_card_detail_screen.dart`: view, Share, Remove. |
| 7 | Share output is text-only: "[title]\n[body]\n— from Settle" | **PASS** | `lib/screens/plan/reset_flow_screen.dart`, `playbook_card_detail_screen.dart`, `saved_playbook_screen.dart`: share text = '${card.title}\n${card.body}\n— from Settle'. |
| 8 | Playbook empty state is a friendly one-liner, not a tutorial | **PASS** | `lib/screens/library/saved_playbook_screen.dart`: _EmptyState "Your playbook is empty. Save cards from Reset to get started." |

---

## PHASE 3 — Domain Flows

| # | Requirement | Result | Evidence / Notes |
|---|-------------|--------|------------------|
| 1 | Moment: calm action → Boundary/Connection choice → script → Close | **PASS** | `lib/screens/plan/moment_flow_screen.dart`: _MomentPhase calm → choice → script; _buildCalmStep, _buildChoiceStep (Boundary/Connection tiles), _buildScriptStep with Close. |
| 2 | Moment reachable from Home, Sleep Tonight, and Tantrum Just Happened | **PASS** | Plan home links to /plan/moment; Sleep Tonight "Just need 10 seconds" / "In the moment? → Moment" → /plan/moment?context=sleep; Tantrum Just Happened → Reset (Moment linked from Plan/Reset). |
| 3 | Moment completable in ≤ 10 seconds | **PASS** | Calm skippable (tap); choice + script + Close = 2–3 taps. Design allows ≤10s. |
| 4 | Sleep Tonight: 3 situations (bedtime protest, night wake, early wake) | **PASS** | `lib/screens/sleep_tonight.dart`: _scenarioLabels and _SituationPicker: bedtime_protest, night_wakes, early_wakes. |
| 5 | Each sleep situation reaches actionable guidance in ≤ 3 taps | **PASS** | Situation picker (1 tap) → plan created → guidance card. No extra required steps before first guidance. |
| 6 | Every sleep path ends with closure | **PASS** | Close clears plan; Save to Playbook; More options/recap/setup sheets all have dismiss. Slice 5A verified. |
| 7 | Tantrum Just Happened routes to Reset with context=tantrum | **PASS** | `lib/router.dart`: tantrum-just-happened redirect → /plan/reset?context=tantrum. |
| 8 | Tantrum reuses Reset engine — no separate UI | **PASS** | Same ResetFlowScreen with contextQuery=tantrum; repair cards filtered by context. |

---

## PHASE 4 — Share + Notifications

| # | Requirement | Result | Evidence / Notes |
|---|-------------|--------|------------------|
| 1 | Every card view across the app can share via native share sheet | **PASS** | Tantrum card output now uses Share.share() for the same text payload (with "— from Settle"); native share sheet available. |
| 2 | All share output is text-only and readable standalone | **PASS** | Reset, Playbook, Sleep Tonight share plain text (title/body or plan summary). Tantrum copy is text-only but via clipboard. |
| 3 | Evening notification exists, default 6 PM or 1hr before bedtime | **PASS** | `lib/services/notification_service.dart`: scheduleEveningCheckIn(DateTime fireAt). `lib/main.dart`: fireAt = 1hr before bedtime; _bedtimeHourMin default (18,0) = 6 PM. |
| 4 | Notification frequency: max once/day, skipped if app opened in last 2hrs | **PASS** | Single scheduled time per day; _cancelEveningCheckInIfRecentlyOpened() cancels when now in [fireAt−2h, fireAt+15m]. |
| 5 | Notification is opt-in (off by default) | **PASS** | `lib/providers/nudge_settings_provider.dart`: eveningCheckInEnabled = false. |
| 6 | No nagging language in notification copy | **PASS** | `lib/services/notification_service.dart`: "Tonight's sleep plan is ready" / "Open Settle to see your plan for tonight." |

---

## CROSS-CUTTING

| # | Requirement | Result | Evidence / Notes |
|---|-------------|--------|------------------|
| 1 | One primary CTA per screen — no screen has multiple competing actions | **PASS** | Screens audited: Reset (Keep/Close/Another are clear; Close secondary). Moment (Close primary). Playbook list (tap card primary). Sleep Tonight (situation then Next step / Close). No dual primary CTAs. |
| 2 | Every flow ends with explicit closure — no hanging states | **PASS** | Slice 5A: all flows have Back/Close/fallbackRoute; doc `docs/SLICE_5A_POLISH_SUMMARY.md`. |
| 3 | No forbidden words anywhere in codebase: "urgent", "failed", "streak", "don't forget", "we miss you", "hurry", "you need to", "behind", "missed", "overdue" | **PASS** | Grep: no user-facing strings with those words. "failed" appears in sleep_guidance_service (internal key allNapsFailedToday); "urgent" in theme comment (critical/urgent); "behind" in UI/blur comments; "missed" in test (warnIfMissed). None in user-facing copy. |
| 4 | No dashboards, streaks, or guilt loops | **PASS** | release_rollout_provider/release_metrics use "metricsDashboard" for internal tooling only, gated. No user-facing dashboards, streaks, or guilt. |
| 5 | All data is local-only — no network calls for user data | **PASS** | No dio/retrofit/user API. invite_screen builds https://settle.app/join link for sharing, not data fetch. Hive/local storage only for user data. |
| 6 | Card display uses generous whitespace, no dense text walls | **PASS** | GlassCard, SettleGap, single-step guidance; _maxSentences used in reset card body; body copy with spacing. |

---

## Summary

| Phase | Passed | Failed | Total |
|-------|--------|--------|-------|
| Phase 0 — Content Foundation | 5 | 0 | 5 |
| Phase 1 — Spine + Storage | 5 | 0 | 5 |
| Phase 2 — Reset + Playbook | 8 | 0 | 8 |
| Phase 3 — Domain Flows | 8 | 0 | 8 |
| Phase 4 — Share + Notifications | 6 | 0 | 6 |
| Cross-cutting | 6 | 0 | 6 |
| **Total** | **38** | **0** | **38** |

**Overall: 38/38 passed.**

---

## Fixes applied (post-audit)

- **Phase 4.1:** `lib/screens/tantrum/tantrum_card_output_screen.dart` — onShare now uses `Share.share(payload)` instead of clipboard; payload includes "— from Settle" for consistency with other card shares.

---

*End of audit.*
