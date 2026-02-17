# Slice 5A: Final polish pass — summary

## Files changed

| File | Changes |
|------|--------|
| `lib/screens/library/playbook_card_detail_screen.dart` | When card is null, added explicit "Back to Playbook" CTA so close/exit is always available. |
| `lib/screens/library/saved_playbook_screen.dart` | Error state: calm copy ("We couldn't load your playbook right now.") + "Try again" CTA that invalidates provider. |
| `lib/screens/library/library_home_screen.dart` | Playbook preview error copy aligned to calm message. |
| `lib/screens/plan/moment_flow_screen.dart` | "Need more? → Reset" link wrapped in `SettleTappable` with semantic label for a11y and consistent closure. |
| `lib/screens/plan/plan_spine_stub_screens.dart` | Replaced placeholder copy with user-facing copy: "Open the full Reset/Moment flow from Plan." |
| `lib/screens/plan/plan_script_log_screen.dart` | SnackBar duration 900ms → 800ms. |
| `lib/screens/plan/plan_home_screen.dart` | SnackBar durations 1100ms and 1500ms → 800ms. |
| `lib/screens/release_ops_checklist.dart` | SnackBar duration 900ms → 800ms. |
| `lib/screens/tantrum/flashcard_mode.dart` | Scale animation duration 3600ms → 300ms. |
| `lib/screens/tantrum/cards_library_screen.dart` | Error state: calm copy + "Back to Incident" CTA; added `settle_gap` import. |
| `lib/main.dart` | Hive box opening: open boxes in sequence with try/catch per box so one failure doesn’t crash app; `_ensureSpineSchemaVersion` checks `Hive.isBoxOpen('spine_store')` before use. |

---

## Flow closure verification (done in code)

- **Reset:** Close and Keep both call `_exitFlow()` → `context.pop()` or `context.go('/plan')`. No hanging state.
- **Playbook:** List → detail uses `ScreenHeader` fallback; card-not-found now has "Back to Playbook"; Remove pops. Back works at every depth.
- **Moment:** Back/Close in all phases → `context.pop()` or `context.go('/plan')`. "Need more? → Reset" uses `SettleTappable` and navigates cleanly.
- **Sleep Tonight:** Situation picker → guidance card; Close clears plan and returns to situation picker; all sheets (recap, approach switch, home context, more options) have Save/Cancel and close. Every path ends.
- **Tantrum:** Capture → card output; card output "Done" → `/tantrum/capture`; error/card null states have "Back to Capture". Post-reset (from Plan) returns to Plan; no hanging state.

---

## Empty states (verified)

- **Saved Playbook:** `_EmptyState` + error with Try again.
- **Patterns:** `_EmptyPatternsState` with CTA to Plan.
- **Activity feed:** Centered message when no events.
- **Cards library (Deck):** Section empties + error with "Back to Incident."
- **Today/Logs:** `EmptyState` in plan and week tabs.
- **Library home:** Playbook preview empty + error with "Open playbook."

---

## Error / storage behavior

- **main.dart:** Boxes opened one-by-one with try/catch; single box failure no longer crashes app. `_ensureSpineSchemaVersion` only runs if `spine_store` is open.
- **UI error states:** Playbook and Deck show calm copy and a recovery CTA (Try again or Back).

---

## Transitions

- SnackBar durations capped at 800ms where reduced (plan home, plan script log, release ops).
- Flashcard scale animation 3600ms → 300ms.
- Route transitions remain 200–250ms (router). No transition > 300ms for step/UI transitions; only SnackBar display at 800ms.

---

## Dead code / polish

- Stub screens: placeholder text replaced with user-facing copy.
- No new TODOs or placeholder TODOs added; no unused imports introduced in changed files.

---

## Manual QA walkthrough

1. **Reset**
   - From Plan, open Reset → choose state → see card. Tap **Close** → back to Plan.
   - Tap **Keep** → back to Plan.
   - From card, tap **Another** (if available) → then **Close** → back to Plan.
   - When no card (e.g. no card for combination), tap **Close** → back to Plan.

2. **Playbook**
   - Library → My Playbook. Empty → see empty state; open a card from elsewhere (e.g. Reset Keep) and return → see list.
   - Open a card → **Remove** → pops back to list.
   - Open detail for a card that no longer exists (if possible) → see "Back to Playbook" → tap → back to list.
   - Trigger error (e.g. offline/storage issue if testable) → see calm message + "Try again".

3. **Moment**
   - Plan → Moment (or link from Sleep Tonight). Wait or skip calm → choose Boundary/Connection → see script. Tap **Close** → back to Plan.
   - From script step, tap "Need more? → Reset (15s)" → Reset opens; close Reset → back to Plan.
   - From calm or choice step, tap back arrow → back to Plan.

4. **Sleep Tonight**
   - Sleep tab → Tonight. Choose situation → get guidance. On last step tap **Close** → back to situation picker.
   - Tap **Save to Playbook** → plan clears, back to situation picker.
   - Open **More options** → change scenario / open recap / etc. → save or dismiss sheet → no hang.
   - Confirm safety gate and setup flows close cleanly.

5. **Tantrum**
   - Now/Plan → Capture (or equivalent). Fill trigger → Log & Get Card → card output. Tap primary CTA (Done) → back to capture.
   - On card output error or "No card" → "Back to Capture" → returns to capture.
   - Deck: trigger error if possible → "Back to Incident" → lands on Plan (or tantrum root).

6. **Empty states**
   - Library → My Playbook (empty) → friendly empty.
   - Library → Patterns (no data) → friendly empty + CTA.
   - Library → Logs (no data) → friendly empty in both tabs.
   - Family → Activity (no events) → friendly empty.
   - Tantrum Deck sections (no pinned/saved) → section empty messages.

7. **Transitions**
   - Navigate between screens: no transition > 300ms; no jarring jumps.
   - SnackBars (e.g. "Saved to playbook", "Outcome logged") dismiss in ~800ms or less.

8. **Storage / errors**
   - (If testable) Simulate or force storage failure: app should not crash; affected screens show calm message and CTA where implemented.

---

*Slice 5A polish pass completed.*
