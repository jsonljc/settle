# Tantrum Module Audit + Implementation Plan (No Sleep Impact)

## A) Sleep Read-Only Map (Protected Areas)

**Screens & UI**
- `lib/screens/sleep_tonight.dart` — Sleep Tonight screen (READ-ONLY)
- Any widget/screen that renders sleep-specific content

**Providers & State**
- `lib/providers/sleep_tonight_provider.dart`
- `lib/providers/wake_window_provider.dart`
- `lib/providers/session_provider.dart` (if sleep-session specific)
- `lib/providers/guidance_provider.dart` (if used for sleep guidance)

**Services**
- `lib/services/sleep_guidance_service.dart`
- `lib/services/wake_engine.dart`
- `lib/services/adaptive_scheduler.dart` (sleep/nap related logic)
- `lib/services/help_now_guidance_service.dart` — night routing / sleep incident routing (READ-ONLY)

**Models**
- `lib/models/sleep_session.dart`, `lib/models/sleep_session.g.dart`
- `lib/models/day_plan.dart`, `lib/models/day_plan.g.dart` (if sleep-day-plan specific)

**Assets & Registries**
- `assets/guidance/sleep_evidence_registry_v1.json`
- `assets/guidance/sleep_day_planner_complete.json`
- `assets/guidance/sleep_tonight_complete.json`

**Router (sleep-related constants and branches only)**
- Tab index 1 = Sleep (`_tabSleep`)
- Shell branch at index 1 (path `/sleep`)
- Redirects: `/sleep-tonight`, `/night-mode`, `/night`

**Tests**
- `test/sleep_tonight_runner_widget_flow_test.dart`
- `test/sleep_tonight_safety_gate_contract_test.dart`
- `test/sleep_guidance_adapter_contract_test.dart`
- Any test file that imports or tests sleep_tonight, sleep_guidance, sleep_session, bedtime, wake window, nap, night wake

**Other files that reference sleep (reference-only; do not change sleep-specific logic)**
- `lib/screens/help_now.dart` — routes to sleep at night (do not modify sleep routing logic)
- `lib/screens/settings.dart`, `lib/screens/home.dart`, `lib/screens/plan_progress.dart`, `lib/screens/today.dart` — may reference sleep; do not change sleep behavior
- `lib/main.dart` — Hive adapters for SleepSession, DayPlan, NightWake (do not remove or alter)
- `lib/widgets/settle_bottom_nav.dart` — contains "Sleep" tab; only allowed change: add a new tab, do not edit Sleep tab label/icon/index
- `lib/router.dart` — contains Sleep branch; only allowed change: add new branch/routes, do not edit Sleep branch or redirects

---

## B) Shared Touchpoints (Minimal Edits Only)

| File | Allowed change |
|------|----------------|
| `lib/router.dart` | Add one new `StatefulShellBranch` for Tantrum (e.g. index 3) and routes: `/tantrum`, `/tantrum/crisis`, `/tantrum/cards`, `/tantrum/cards/:id`, `/tantrum/learn`. Do not modify existing tab indices 0–2 or Sleep branch. |
| `lib/widgets/settle_bottom_nav.dart` | Add one new bottom nav item (e.g. "Tantrum" or "Calm") so total items = 4. Do not change existing Help Now / Sleep / Progress items. |
| `lib/screens/app_shell.dart` | No change required (shell already uses `currentIndex` and `onTabTap`; 4th tab works if router has 4 branches). |

No other shared files need edits. Do not modify `main.dart` unless adding a new Hive adapter for a new tantrum-specific persistable type (e.g. protocol store); if protocol is stored as JSON string in an existing-style box, no main.dart change.

---

## C) No-Conflict Folder Plan (New Tantrum Module)

```
lib/
  tantrum/
    models/
      tantrum_card.dart          # NEW: id, title, say, do, ifEscalates, lessonId
    services/
      tantrum_registry_service.dart   # NEW: load tantrum_registry_v1.json
    providers/
      tantrum_module_providers.dart    # NEW: registry provider, protocol pinned (5–10) provider
  screens/
    tantrum/
      tantrum_now_screen.dart    # NEW: NOW landing, 2 taps to crisis
      crisis_view_screen.dart    # NEW: SAY / DO / IF ESCALATES / Audio stub / Repeat line
      cards_library_screen.dart  # NEW: list or grid of cards
      card_detail_screen.dart    # NEW: detail + "Pin to Protocol"
      tantrum_learn_screen.dart  # NEW: micro-lessons linking to cards
      # Existing: tantrum_hub, flashcard_mode, debrief_mode, scripts_library, pattern_view, practice_mode, tantrum_unavailable — leave as-is or reuse where useful

assets/
  guidance/
    tantrum_registry_v1.json     # NEW: 10–15 tantrum cards (do not touch sleep registries)
```

Protocol: store pinned card IDs (5–10 max) in a dedicated Hive box or shared_preferences key (e.g. `tantrum_protocol` box, key `pinned`, value JSON array of card ids). No new Hive type adapter if we store a single JSON string.

---

## D) Change Set Plan (Ordered Steps)

1. **Create tantrum content and model**
   - Add `assets/guidance/tantrum_registry_v1.json` with 10–15 cards (say, do, ifEscalates, title, optional lessonId).
   - Add `lib/tantrum/models/tantrum_card.dart` (tantrum-specific card model; do not change any shared Card type if it exists).

2. **Create tantrum service and providers**
   - Add `lib/tantrum/services/tantrum_registry_service.dart` to load and parse the registry.
   - Add `lib/tantrum/providers/tantrum_module_providers.dart`: registry provider, protocol provider (pinned ids, max 10, persisted).

3. **Create Crisis View (no sleep code)**
   - Add `lib/screens/tantrum/crisis_view_screen.dart`: big SAY line, DO, IF ESCALATES, Audio button (stub), Repeat line mode.

4. **Create NOW flow (2 taps to Crisis)**
   - Add `lib/screens/tantrum/tantrum_now_screen.dart`: landing; tap 1 = "I need help now" or "Use my protocol"; tap 2 = open Crisis View with selected card or first protocol card.

5. **Create CARDS flow**
   - Add `lib/screens/tantrum/cards_library_screen.dart`: card library (list or grid).
   - Add `lib/screens/tantrum/card_detail_screen.dart`: full card content + "Pin to Protocol" (respect 5–10 max).

6. **Create Tantrum LEARN**
   - Add `lib/screens/tantrum/tantrum_learn_screen.dart`: micro-lessons that link back to cards (e.g. by lessonId/cardId).

7. **Wire navigation (minimal shared edits)**
   - In `lib/router.dart`: add 4th `StatefulShellBranch` for `/tantrum` with child routes for now, crisis, cards, cards/:id, learn. Add redirects if desired (e.g. `/tantrum` → `/tantrum/now`).
   - In `lib/widgets/settle_bottom_nav.dart`: add 4th item (label "Tantrum" or "Calm", icon).

8. **Safety and verification**
   - Run a diff of all modified files. If any modified file is in the Sleep Read-Only Map, revert and redo using only new files or the allowed shared touchpoints.

---

## E) Risk & Mitigation

| Risk | Mitigation |
|------|------------|
| Accidentally editing Sleep screen/provider/service | Never open or edit files listed in (A). Use grep to confirm no sleep file is in the change set before finalizing. |
| Router tab index shift breaking Help Now / Sleep / Progress | Add Tantrum as the 4th branch (index 3). Do not renumber or change existing branches. |
| Learn screen naming/route conflict | Existing Learn stays at `/progress/learn`. New Tantrum Learn lives at `/tantrum/learn` with a distinct screen class name (e.g. `TantrumLearnScreen`). Do not modify `lib/screens/learn.dart`. |
| Registry or content contract collision with Sleep | New file `tantrum_registry_v1.json` only. Do not touch `sleep_evidence_registry_v1.json`, `sleep_tonight_complete.json`, or `sleep_day_planner_complete.json`. Reuse Help Now–style fields (say, do, ifEscalates) in tantrum cards without changing Help Now or Sleep contracts. |
| Hive or main.dart adapter collision | If a new persistable type is introduced, register only the new adapter in main.dart. Do not remove or change SleepSession, DayPlan, NightWake, or other sleep-related adapters. For protocol, prefer storing a JSON string in a simple box to avoid new adapters if possible. |

---

## Implementation Checklist (Post-Audit)

- [x] tantrum_registry_v1.json created
- [x] TantrumCard model + TantrumRegistryService + tantrum_module_providers
- [x] CrisisViewScreen
- [x] TantrumNowScreen (2 taps to Crisis)
- [x] CardsLibraryScreen + CardDetailScreen + Pin to Protocol
- [x] TantrumLearnScreen
- [x] Router: 4th branch + routes
- [x] Bottom nav: 4th item
- [x] Final diff: no sleep-related file modified by this implementation

---

## Sleep Safety Verification (Post-Implementation)

**Files modified in this implementation (Tantrum module work only):**

| File | Change |
|------|--------|
| `lib/router.dart` | Added 4th shell branch for `/tantrum` and child routes (now, crisis, cards, cards/:id, learn). No change to Sleep branch or indices 0–2. |
| `lib/widgets/settle_bottom_nav.dart` | Added 4th nav item "Tantrum" with icon. No change to Help Now / Sleep / Progress items. |

**Files created (new only; no sleep code):**

- `assets/guidance/tantrum_registry_v1.json`
- `docs/TANTRUM_MODULE_AUDIT.md`
- `lib/tantrum/models/tantrum_card.dart`, `lib/tantrum/models/tantrum_lesson.dart`
- `lib/tantrum/services/tantrum_registry_service.dart`
- `lib/tantrum/providers/tantrum_module_providers.dart`
- `lib/screens/tantrum/crisis_view_screen.dart`, `tantrum_now_screen.dart`, `cards_library_screen.dart`, `card_detail_screen.dart`, `tantrum_learn_screen.dart`
- `lib/widgets/tantrum_sub_nav.dart`

**Sleep-related files:** Not modified by this implementation. Any pre-existing modifications to `lib/screens/sleep_tonight.dart` or sleep tests are outside this change set.
