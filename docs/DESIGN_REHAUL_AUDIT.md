# Design Rehaul Audit

**Purpose:** Identify remaining work to complete the "Quiet Hand" design migration (solid surfaces, typography-forward, minimal chrome).  
**Context:** Phases 1–4 are done: design system foundation, main tabs, core flows, secondary screens, and onboarding. Local token classes (`_XxxT`) have been removed app-wide.  
**Last updated:** 2026-02-20.

---

## Status: P0 + P1 + P2 + P3 + P4 started (2026-02-20)

- **P0:** All `BackdropFilter` / `ImageFilter.blur` removed. `pocket_fab` and `option_button` now use solid surfaces only.
- **P1:** All direct `SettleGlassLight` / `SettleGlassDark` references in app code migrated to `SettleSurfaces` / `SettleColors`.
- **P2:** Legacy glass classes (`SettleGlass`, `SettleGlassLight`, `SettleGlassDark`) removed from `settle_design_system.dart`. Design system tests updated (glass test removed, gradient test expects solid colors, color/typography/theme contracts aligned with current code).
- **P3:** Key tap targets migrated from `GestureDetector` to `SettleTappable` with semantic labels: settings (3 rows), release_metrics/release_ops_checklist (refresh), family_rules (link), tantrum_sub_nav (segments), plan_script_log_screen (regulation toggle), library_home_screen (See more), today (alternate link), onboarding/onboarding_v2 (back), step_child_basics_o2 (exact birthday link), sleep_tonight (Moment link), learn (_QuestionCard expand), release_surfaces (3 back buttons), sos (back), weekly_reflection (dismiss). ScreenHeader already uses `Semantics(header: true)`.
- **P4:** Spacing tokens applied in `settings.dart` (SettleGap.*, SettleSpacing.cardGap/md/sm/xs, EdgeInsets), `today.dart` (same), and `sleep_tonight.dart` (SettleGap.sm/xs/xl, SettleSpacing.cardGap). Values without a token (e.g. 2, 6, 12, 14) left as literals. Other heavy files (release_metrics, release_ops_checklist, family_rules, tantrum/library screens) can be done incrementally.

---

## 1. High priority — remove glass and legacy tokens

### 1.1 BackdropFilter / ImageFilter.blur — DONE

All blur removed. `pocket_fab` and `option_button` use solid fills only.

---

### 1.2 Direct use of SettleGlassLight / SettleGlassDark — DONE

All app code now uses `SettleSurfaces` / `SettleColors`. The only remaining references are the class definitions in `settle_design_system.dart`.

**Done (P2):** Legacy glass classes removed from `settle_design_system.dart`. No remaining references in lib or tests.

---

### 1.3 SettleGradients

- **Current state:** `SettleGradients` is already solid (e.g. `_solid(SettleColors.stone50)`). Only references are in `gradient_background.dart` (preset) and comments (`moment_flow_screen.dart`, `saved_playbook_screen.dart`).
- **Action:** Optional: replace preset usage with `SettleColors.stone50` / `SettleColors.night900` directly where a single color is used; then remove or deprecate `SettleGradients` and update comments.

---

## 2. Medium priority — background and gradients

### 2.1 GradientBackgroundFromRoute

- **Usage:** ~45 screens wrap body in `GradientBackgroundFromRoute` (e.g. app_shell, home, today, settings, all tantrum/library/plan/rhythm/family screens).
- **Current behavior:** Renders a **solid** background (stone50 light / night900 dark or crisis); no blobs in presets.
- **Action:** Low urgency. Options for later:
  - Rename to something like `RouteAwareBackground` and document that it’s solid.
  - Or replace with a simple `Container(color: ...)` per route and remove the widget if no longer needed.

### 2.2 GradientBackground / AmbientBlob

- **Defined in:** `lib/widgets/gradient_background.dart` (`GradientBackground`, `AmbientBlob`, `GradientBackgroundPresets`).
- **Usage:** Presets return empty blobs; `GradientBackground` uses first gradient color as solid.
- **Action (Phase 4 cleanup):** Once no callers need blobs or gradient API, you can simplify: remove `AmbientBlob`, `GradientBackgroundPresets.forPath` blobs, and keep only the solid background behavior (or inline it where used).

---

## 3. Consistency and components

### 3.1 GestureDetector vs SettleTappable — P3 done

- **AGENTS.md:** Prefer `SettleTappable` for interactive elements (semantics + consistent tap behavior).
- **P3:** Settings, release screens, family_rules, tantrum_sub_nav, plan_script_log, library_home_screen, today, onboarding (v1/v2), step_child_basics_o2, sleep_tonight, learn, release_surfaces, sos, weekly_reflection now use `SettleTappable` with semantic labels for primary tap targets.
- **Remaining:** Other screens (e.g. plan_progress, help_now, tantrum cards, script_card, app_shell nav, option_button, pocket_fab, glass_card/glass_pill/glass_nav_bar) may still use `GestureDetector`/`InkWell`; can be migrated incrementally when touching those files.

### 3.2 SettleChip / SettleModalSheet

- **AGENTS.md:** Use `SettleChip` for selection controls and `SettleModalSheet` for bottom sheets.
- **Action:** Audit screens for ad‑hoc chips or custom sheets; replace with these components where it improves consistency and a11y.

### 3.3 ScreenHeader and semantics

- **AGENTS.md:** `Semantics(header: true)` on all `ScreenHeader` instances.
- **Current:** `screen_header.dart` already uses `header: true`. Many screens use `ScreenHeader`; a few may still build custom headers.
- **Action:** Ensure every top-level screen that has a title uses `ScreenHeader` (or an equivalent with `header: true`). Quick grep for `ScreenHeader(` and manual check for screens with custom app bars.

---

## 4. Hardcoded values (P4 — incremental)

- **Spacing:** Prefer `SettleSpacing.*` / `SettleGap` over literal `SizedBox(height: n)`. **Done in:** `settings.dart`, `today.dart`, `sleep_tonight.dart` (height 4/8/10/16/20/24 → SettleGap.xs/sm/md/lg/xl or SettleSpacing.cardGap; padding 8/16 → SettleSpacing.sm/md). Values without a token (2, 6, 12, 14) left as literals.
- **Radii:** Isolated uses of `BorderRadius.circular(18)` etc. can be switched to `SettleRadii.card` / `SettleRadii.surface` where they denote the same intent.
- **Colors:** Scattered `Color(0x...)` or `Colors.*` can be migrated to `SettleColors.*` / `SettleSurfaces.*` when touching those files.

**Remaining heavy files:** `release_metrics.dart`, `release_ops_checklist.dart`, `family_rules.dart`, tantrum and library screens. Good candidates for incremental token cleanup when editing.

---

## 5. Suggested order of work

1. **Remove remaining glass (P0)**  
   - `pocket_fab.dart`: solid FAB, no blur; switch to `SettleSurfaces.*`.  
   - `option_button.dart`: solid fill/border, no `BackdropFilter`; use `SettleSurfaces.*`.

2. **Replace direct SettleGlass* references (P1)**  
   - Widgets: `pocket_fab`, `option_button`, `settle_chip`, `tantrum_sub_nav`, `settle_segmented_choice`.  
   - Screens: `settings`, `library_progress_screen`, `tantrum_insights_screen`, `pattern_view`, `crisis_view_screen`.

3. **Legacy cleanup (P2)**  
   - Deprecate or remove `SettleGlassLight`, `SettleGlassDark`, `SettleGradients` in design system once no direct references remain.  
   - Simplify `GradientBackground` / `AmbientBlob` / presets as above.

4. **Consistency and a11y (P3)** — Done  
   - Key tap targets migrated to `SettleTappable` with semantic labels; `ScreenHeader` already has `header: true`. Optional: continue replacing remaining `GestureDetector`/`InkWell` when editing those screens; use `SettleChip`/`SettleModalSheet` where ad-hoc chips/sheets exist.

5. **Tokens and literals (P4)** — Started  
   - Spacing tokens applied in `settings.dart`, `today.dart`, `sleep_tonight.dart`. Continue in other heavy files when touching them.

---

## 6. Quick reference — files to touch

| Priority | File | Change | Status |
|----------|------|--------|--------|
| P0 | `lib/widgets/pocket_fab.dart` | Remove blur; solid FAB; SettleSurfaces.* | Done |
| P0 | `lib/widgets/option_button.dart` | Remove BackdropFilter; solid; SettleSurfaces.* | Done |
| P1 | `lib/screens/settings.dart` | SettleGlass* → SettleSurfaces.* | Done |
| P1 | `lib/screens/library/library_progress_screen.dart` | Same | Done |
| P1 | `lib/screens/tantrum/tantrum_insights_screen.dart` | Same | Done |
| P1 | `lib/screens/tantrum/pattern_view.dart` | Same | Done |
| P1 | `lib/screens/tantrum/crisis_view_screen.dart` | Same | Done |
| P1 | `lib/widgets/tantrum_sub_nav.dart` | Same | Done |
| P1 | `lib/widgets/settle_chip.dart` | Same | Done |
| P1 | `lib/widgets/settle_segmented_choice.dart` | Same | Done |
| P2 | `lib/theme/settle_design_system.dart` | Remove/deprecate glass + gradient stubs | Done (glass removed; gradients kept, solid) |
| P2 | `lib/widgets/gradient_background.dart` | Simplify; remove blob/preset complexity if unused | Deferred (already solid-only; blobs unused) |
| P3 | Settings, release, family_rules, tantrum_sub_nav, plan_script_log, library/today, onboarding, sleep_tonight, learn, release_surfaces, sos, weekly_reflection, step_child_basics_o2 | GestureDetector → SettleTappable + semanticLabel | Done |
| P4 | `lib/screens/settings.dart` | SettleGap, SettleSpacing for spacing/padding | Done |
| P4 | `lib/screens/today.dart` | Same | Done |
| P4 | `lib/screens/sleep_tonight.dart` | SettleGap.sm/xs/xl, SettleSpacing.cardGap | Done |
| P4 | release_metrics, release_ops_checklist, family_rules, tantrum/library | Tokens when editing | Optional |

This audit gives a single place to track remaining design rehaul work and the order to do it in.
