# Settle — Implementation Plan

**Purpose:** Single reference for what’s done, what’s next, and how to slice work.  
**Sources:** [AGENTS.md](../AGENTS.md), [V2_MIGRATION_PLAN.md](V2_MIGRATION_PLAN.md).  
**Last updated:** 2026-02-19.

---

## 1. Current status (done)

| Area | Status | Notes |
|------|--------|--------|
| **Navigation (UXV2-001, UXV2-013)** | Done | 3 tabs (Now / Sleep / Library), Family + Settings as overlays via Menu, legacy redirects in place. |
| **Entry + Sleep root (UXV2-002–004)** | Done | Splash → `/sleep` when profile exists; onboarding → `/sleep`; Sleep root = Rhythm daily; inline setup card when setup incomplete. |
| **Sleep tab title (P3)** | Done | Header: “Sleep” + “Today’s rhythm.” |
| **Close moment (P1)** | Done | After last Sleep Tonight step, sheet: “Close the moment” → “Reset · 15s” \| “I’m good” → clear plan + go to `/sleep` or push Reset. |
| **Regulate discoverability (P2)** | Done | Now: “Need a longer reset? Regulate →”; Moment footer: “Regulate →”. |
| **Onboarding O3/O4 (P4)** | Done | Step “What brought you here?” (Sleep/Tantrums/Big feelings/Just exploring) + “Your first repair words are ready” / “Let’s go”; completion routes to `/sleep` or `/plan` by choice. |
| **Glass / CTA (run fix)** | Done | `theme/glass_components.dart` and `widgets/settle_cta.dart` restored; SettleCta/GlassCta use liquid glass (blur, translucent fill, specular); GlassCardAccent/Rose/Teal use design-system tints. |

---

## 2. Implementation phases (remaining)

### Phase A — Validation and polish (no new features)

**Goal:** Lock in 20s rule and close one wireframe gap.

| ID | Task | Scope | Done when |
|----|------|--------|-----------|
| **P5** | 20s validation | Manual stopwatch: Now → first guidance, Sleep Tonight → first guidance, Reset → first card. Log or document results. | All paths ≤20s confirmed or issues filed. See [V2_TIER1_SMOKE_CHECKLIST.md](V2_TIER1_SMOKE_CHECKLIST.md). |
| **Optional** | Close moment 7-day suppression | Per wireframe: if user taps “I’m good” 3+ times in a row, don’t show Close moment for 7 days. Persist count + suppress_until (Hive). | **Done.** `CloseMomentSuppress` + Hive box `close_moment_suppress`; Reset clears count. |

**Files (optional task):** `lib/screens/sleep_tonight.dart`, `lib/services/close_moment_suppress.dart`, `lib/main.dart` (box init).

---

### Phase B — Sleep Tonight and Now (crisis path)

**Goal:** Simplify crisis path and keep primary CTA obvious (UXV2-005, UXV2-012).

| ID | Task | Scope | Done when |
|----|------|--------|-----------|
| **UXV2-005** | Sleep Tonight simplification | Trim “More options” to max 4: Switch scenario, Why this works, Mark done, Change approach. No free-text note on main crisis path. Primary CTA always visible; copy ≤2 short lines per block. | **Done.** More options sheet trimmed to 4 items; recap sheet has no note field; primary CTA unchanged. |
| **UXV2-005** | Now crisis speed | Confirm Now has one dominant CTA, max 3 crisis tiles above fold, no keyboard on crisis path. | **Done.** One primary (START HERE) + 2 secondary = 3 tiles; no keyboard. Run [V2_TIER1_SMOKE_CHECKLIST.md](V2_TIER1_SMOKE_CHECKLIST.md) for stopwatch. |

**Files:** `lib/screens/sleep_tonight.dart`, `lib/screens/plan/plan_home_screen.dart`.

---

### Phase C — Library (After surface)

**Goal:** Library reads as “After” (review, reflect), not dashboard (UXV2-007).

| ID | Task | Scope | Done when |
|----|------|--------|-----------|
| **UXV2-007** | Library split | Progress (supportive trend) and Logs (timeline) clearly separated; Progress needs min data before trend. Learn, Saved, Patterns, Insights remain. Calm CTA hierarchy. | Done “After” clear; **Done.** PROGRESS / TIMELINE / LEARN & SAVED sections; subtitle "Reflect and grow"; Progress + Logs hero cards; 2×2 compact (Learn, Saved, Patterns, Insights); min 3 data points for trend. |

**Files:** `lib/screens/library/library_home_screen.dart`, `lib/screens/library/library_progress_screen.dart`, `lib/screens/library/library_logs_screen.dart`, `lib/screens/plan/plan_script_log_screen.dart` (if reused), `lib/router.dart`.

---

### Phase D — Overlays and shell

**Goal:** Family and Settings only as overlays; no tab (UXV2-008, UXV2-009).

| ID | Task | Scope | Done when |
|----|------|--------|-----------|
| **UXV2-008** | Family overlay | Family only reachable via shell Menu (or deep link). Sub-routes (shared, invite, activity) work inside overlay. | **Done.** No Family tab; Menu → Family; _overlaySheet; sub-routes shared/invite/activity in overlay; back/dismiss consistent. |
| **UXV2-009** | Settings overlay | Settings only via shell Menu. All settings sections work in overlay. | **Done.** No Settings tab; Menu → Settings; _overlaySheet; back/dismiss consistent. |

**Files:** `lib/screens/app_shell.dart`, `lib/screens/family/family_home_screen.dart`, `lib/screens/settings.dart`, `lib/router.dart`.  
**Note:** Shell already uses Menu → Family/Settings; confirm behavior and back/dismiss are consistent.

---

### Phase E — Components, a11y, spacing

**Goal:** One glass family, consistent semantics and spacing (UXV2-006, UXV2-010, UXV2-011, UXV2-012, UXV2-014).

| ID | Task | Scope | Done when |
|----|------|--------|-----------|
| **UXV2-010** | Glass unification | Single source for glass: `theme/glass_components.dart` + `widgets/glass_card.dart`, `glass_pill.dart`, `settle_cta.dart`. Remove any duplicate or “hide” workarounds. | **Done.** Doc comment in glass_components; no duplicate implementations. |
| **UXV2-011** | A11y | SettleTappable (or equivalent) for interactive controls; semantics on new controls; tap targets ≥44px. VoiceOver/TalkBack smoke test. | **Done.** Pocket FAB 56px + semantics; overlay dismiss; QA + ACCESSIBILITY.md for smoke. |
| **UXV2-012** | Spacing/tokens | Touched screens use `SettleGap` and design-system tokens; no hardcoded spacing/colors in new code. | **Done.** Sleep Tonight More options + recap use SettleGap; Library uses SettleGap. |
| **UXV2-006** | Pocket | Contextual ordering (path + time); a11y for Pocket FAB and overlay. | **Done.** _orderPocketCandidates(path, isNight); FAB 56px + semantics; overlay dismiss. |
| **UXV2-014** | Release QA | Full QA checklist (see below) before release. | **Done.** Section 3 references ACCESSIBILITY.md; a11y smoke item in checklist. |

**Files:** `lib/theme/glass_components.dart`, `lib/widgets/glass_card.dart`, `lib/widgets/glass_pill.dart`, `lib/widgets/settle_cta.dart`, `lib/widgets/settle_tappable.dart`, `lib/screens/pocket/pocket_fab_and_overlay.dart`, `lib/screens/pocket/pocket_overlay.dart`, plus any screens touched in Phases A–D.

---

## 3. QA checklist (per PR and release) — UXV2-014

Run before release; see [ACCESSIBILITY.md](ACCESSIBILITY.md) for a11y fail conditions and VoiceOver/TalkBack smoke.

- [ ] `flutter analyze` clean for changed files.
- [ ] Manual dark/light on Now, Sleep, Library.
- [ ] Crisis stopwatch: Now → first guidance ≤20s; Sleep Tonight → first guidance ≤20s; Reset → first card ≤20s.
- [ ] One-handed use: primary actions in thumb zone.
- [ ] Large text: no critical overflow.
- [ ] Reduce motion respected where implemented.
- [ ] Offline: core script + rhythm usable without network.
- [ ] VoiceOver/TalkBack: Pocket FAB, overlay dismiss, primary CTAs announced (see ACCESSIBILITY.md).

---

## 4. Suggested order of work

1. **Phase A** — Quick win: run P5 stopwatch, optionally add 7-day Close moment suppression.  
2. **Phase B** — Highest impact on crisis feel: Sleep Tonight trim + Now confirmation.  
3. **Phase C** — Library clarity (Progress vs Logs).  
4. **Phase D** — Overlay confirmation (likely already correct).  
5. **Phase E** — Component/a11y/spacing and release QA.

---

## 5. Out of scope (this plan)

- New clinical content or new flows.
- Monetization/paywall.
- Large data or folder migrations.
- Big-bang rename to `ui/state/domain/data` (AGENTS.md says migrate incrementally).

---

## 6. Commit message tags

Use task IDs in commits, e.g.:

- `fix(flow): 20s validation pass + doc (P5)`
- `feat(sleep): close moment 7-day suppression (wireframe S3)`
- `feat(sleep): trim Sleep Tonight more options (UXV2-005 UXV2-012)`
- `feat(library): progress vs logs split (UXV2-007)`
- `refactor(ui): glass + a11y + spacing pass (UXV2-006 UXV2-010 UXV2-011 UXV2-012)`
