# Settle Design Architecture Audit

> Generated 2026-02-18 | Audit scope: `lib/` (98 Dart files, 4-tab Flutter parenting app)

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Repo Map](#2-repo-map)
3. [Audit Scores (A–H)](#3-audit-scores-ah)
4. [P0 Plan](#4-p0-plan)
5. [P1 Plan](#5-p1-plan)
6. [Rules Contract](#6-rules-contract)
7. [Quick Wins](#7-quick-wins)
8. [Tech Debt Register](#8-tech-debt-register)
9. [Appendix: Evidence Links](#9-appendix-evidence-links)

---

## 1. Executive Summary

1. **Two fully-specified, mutually incompatible design systems co-exist** — `settle_tokens.dart` (System A: Nunito, `T` alias) and `settle_design_system.dart` (System B: Inter + Fraunces, `SettleColors/SettleTypography/...`). Both are actively consumed in the same screens, causing silently divergent spacing (xxl: 24 vs 28), blur (sigma 12 vs 40), and typography at runtime.

2. **Five components have direct duplicates**: `GlassCard` (two files), `GlassPill` (two files), `SettleTheme` (two classes, same name), `GlassNavBar` vs `SettleBottomNav`, and `SettleGap` (bound to System A values while the app migrates to System B).

3. **Screen-state coverage is severely incomplete**: `CalmLoading` is well-designed but used in only ~6 live screens; 8+ active screens still show raw `CircularProgressIndicator`. No skeleton screens or shimmer patterns exist.

4. **Error recovery is absent**: zero retry tap targets in any live screen. Error-branch widgets passively display "something went wrong" text with navigational escapes but no tap-to-retry. `FamilyRulesState.error` is set by the provider but never rendered in the UI.

5. **~25–30 files are dead code**: the entire `lib/screens/tantrum/` directory (16 files), 5+ legacy flat-root screens, `TantrumSubNav`, dead providers, and 30+ compatibility redirect routes.

6. **Spacing is inconsistently sourced**: `plan_home_screen.dart` mixes `T.space.md`, `SettleSpacing.screenPadding`, and bare `SizedBox(height: 8)` in a single file. `SettleGap.xxl` emits 24px (System A) while `SettleSpacing.xxl` is 28px (System B).

7. **Navigation architecture is well-structured**: GoRouter `StatefulShellRoute.indexedStack` with 4 branches preserves per-tab state correctly. Route-responsive light/dark theme switching with animated transitions is elegant.

8. **Accessibility foundations are above average**: reduce-motion support, systematic haptics, semantic labels on interactive elements, 48x48 minimum touch targets via `SettleTappable`. Primary gap: `EmptyState` uses bare `GestureDetector`.

9. **Performance posture is strong**: fully offline-first via Hive, no network images. The only runtime network dependency is Google Fonts (three families) which would silently fail on first cold-start without connectivity.

10. **Recommended path**: designate System B as canonical, tombstone System A behind `@Deprecated`, align `SettleGap` to System B values, and execute screen-by-screen migration in user-facing priority order.

---

## 2. Repo Map

### App Entry Points

| File | Role |
|---|---|
| `lib/main.dart` | `main()` → Hive init → `ProviderScope(child: SettleApp())` |
| `lib/main.dart:236` | `_SmartThemeWrapper` → `MaterialApp.router(routerConfig: router)` |
| `lib/main.dart:277` | `AnimatedTheme` 300ms crossfade between `SettleTheme.light` / `SettleTheme.dark` |

### Routing — `lib/router.dart`

**GoRouter** with `StatefulShellRoute.indexedStack` (4 branches):

| Tab | Index | Root path | Key screens |
|---|---|---|---|
| Home/Plan | 0 | `/plan` | `PlanHomeScreen`, `ResetFlowScreen`, `MomentFlowScreen`, `PlanScriptLogScreen` |
| Family | 1 | `/family` | `FamilyHomeScreen`, `FamilyRulesScreen`, `InviteScreen`, `ActivityFeedScreen` |
| Sleep | 2 | `/sleep` | `SleepMiniOnboardingGate`, `SleepTonightScreen`, `CurrentRhythmScreen`, `UpdateRhythmScreen` |
| Library | 3 | `/library` | `LibraryHomeScreen`, `SavedPlaybookScreen`, `PatternsScreen`, `MonthlyInsightScreen` |

**Outside shell**: `/` (Splash), `/onboard` (OnboardingV2), `/breathe` (SOS), `/settings`, `/plan/regulate` (RegulateFlow)

**Compatibility redirects**: ~30 legacy routes (`/relief`, `/help-now`, `/now/*`, `/tantrum/*`, `/night-mode`, etc.) all redirect to current paths.

### Navigation Widgets

| Widget | File | Status |
|---|---|---|
| `GlassNavBar` | `lib/widgets/glass_nav_bar.dart` | **Active** — bottom nav, blur=48, 64px height |
| `SettleBottomNav` | `lib/widgets/settle_bottom_nav.dart` | **Legacy** — not rendered; `SettleBottomNavItem` type still imported |
| `ScreenHeader` | `lib/widgets/screen_header.dart` | **Active** — back + title + trailing, used on every sub-screen |
| `TantrumSubNav` | `lib/widgets/tantrum_sub_nav.dart` | **Dead** — references nonexistent routes |

### App Shell — `lib/screens/app_shell.dart`

```
Scaffold
  body: GradientBackgroundFromRoute
    Stack[child, overlay?]
  bottomNavigationBar: GlassNavBar
```

### Screen Folders

```
lib/screens/
  plan/           ← 4 screens + 2 section widgets + 1 stub  [ACTIVE]
  family/         ← 3 screens                                [ACTIVE]
  library/        ← 5 screens                                [ACTIVE]
  sleep/          ← 1 gate/onboarding screen                 [ACTIVE]
  regulate/       ← 1 flow + 5 step widgets                  [ACTIVE, feature-flagged]
  pocket/         ← 1 FAB + 3 overlay views                  [ACTIVE, feature-flagged]
  onboarding/     ← 2 screens + steps/ subfolder             [ACTIVE]
  tantrum/        ← 16 files                                 [DEAD — all routes redirect]
  *.dart (root)   ← 14 flat files, ~6 legacy/unreferenced    [MIXED]
```

### Shared UI Components — `lib/widgets/`

**Glass surfaces**: `glass_card.dart` (new), `glass_pill.dart` (new), `glass_chip.dart`, `glass_nav_bar.dart`
**Interaction**: `settle_tappable.dart`, `settle_chip.dart`, `settle_segmented_choice.dart`, `settle_disclosure.dart`
**Layout**: `settle_gap.dart`, `screen_header.dart`, `gradient_background.dart`, `settle_modal_sheet.dart`
**Content**: `script_card.dart`, `output_card.dart`, `option_button.dart`
**State feedback**: `calm_loading.dart`, `empty_state.dart`, `micro_celebration.dart`, `release_surfaces.dart`
**Other**: `pocket_fab.dart`, `wake_arc.dart`, `weekly_reflection.dart`

### Design System Artifacts

| Artifact | System A (`settle_tokens.dart`) | System B (`settle_design_system.dart`) |
|---|---|---|
| Access pattern | `T.pal.*`, `T.type.*`, `T.space.*` | `SettleColors.*`, `SettleTypography.*`, `SettleSpacing.*` |
| Fonts | Nunito (via `settle_theme.dart`) | Inter + Fraunces |
| Glass blur | sigma 6–12 | blur 40.0 |
| Screen padding | 20 | 18 |
| xxl spacing | 24 | 28 |
| Theme builder | `SettleTheme.data` (dark only) | `SettleTheme.light` / `SettleTheme.dark` |
| Old glass components | `lib/theme/glass_components.dart` | `lib/widgets/glass_card.dart`, `lib/widgets/glass_pill.dart` |

### State Management

**Riverpod exclusively** (`flutter_riverpod ^2.6.1`). All business state via `StateNotifierProvider`. Async data via `FutureProvider`. Constructor-initiated async load pattern. Hive for persistence.

Key providers: `profileProvider`, `rhythmProvider`, `sleepTonightProvider`, `familyRulesProvider`, `resetFlowProvider`, `planProgressProvider`, `userCardsProvider`, `wakeWindowProvider`, `nudgeSettingsProvider`, `patternsProvider`.

---

## 3. Audit Scores (A–H)

### A. Visual Consistency — 5/10

**What's working:**
- Route-responsive gradient backgrounds via `GradientBackgroundFromRoute` (`lib/widgets/gradient_background.dart`)
- System B color palette is coherent: sage, dusk, blush, warmth semantic tints
- Glass effect well-specified in System B (blur=40, light vs dark variants)

**Violations:**
- `T.space.xxl = 24` vs `SettleSpacing.xxl = 28` — 4px gap in every xxl-spaced section
- `T.space.screen = 20` vs `SettleSpacing.screenPadding = 18` — 2px content-edge shift per screen
- `T.glass.sigma = 12` vs `SettleGlassLight.blur = 40` — dramatic visual difference on any remaining old GlassCard
- `ScreenHeader` uses `T.type.h2` (Nunito 22px w700) while newer headings use `SettleTypography.heading` (Inter 20px w600)

**Evidence:**
- `lib/screens/plan/plan_home_screen.dart:14` — explicitly hides old GlassCard/GlassPill: `import '../../theme/glass_components.dart' hide GlassCard, GlassPill;`
- `lib/screens/plan/plan_home_screen.dart:74` — mixes `SettleSpacing.screenPadding` with `T.space.md` in the same padding expression
- `lib/screens/family_rules.dart` — uses `T.type.h3` (Nunito) inside a layout using `SettleSpacing.screenPadding`

**Recommendations:**
1. Tombstone System A, designate System B as sole source of truth
2. Migrate `ScreenHeader`, `CalmLoading`, `SettleGap` off System A (propagates to all screens automatically)
3. Add a lint rule or CI check to flag new `T.*` imports

---

### B. Component Consistency — 4/10

**What's working:**
- `GlassCta` + `GlassPill` (new) pattern is semantically clear and well-implemented
- `SettleChip` and `SettleSegmentedChoice` are self-contained with good accessibility
- `SettleTappable` is an excellent accessible primitive

**Violations:**

| Duplicate | Old location | New location | Old still used by |
|---|---|---|---|
| `GlassCard` | `lib/theme/glass_components.dart` | `lib/widgets/glass_card.dart` | `script_card.dart`, `settle_modal_sheet.dart` |
| `GlassPill` | `lib/theme/glass_components.dart` | `lib/widgets/glass_pill.dart` | `script_card.dart` |
| `SettleTheme` | `lib/theme/settle_theme.dart` | `lib/theme/settle_design_system.dart` | Orphaned (not called by main.dart) |
| Bottom nav | `lib/widgets/settle_bottom_nav.dart` | `lib/widgets/glass_nav_bar.dart` | Only `SettleBottomNavItem` type imported |

- `SettleGap.xxl()` emits 24px (System A) while `SettleSpacing.xxl` is 28px — direct contradiction
- `GlassNavBar` hardcodes `GoogleFonts.inter(fontSize: 10)` at line 61 instead of using `SettleTypography.caption`

**Recommendations:**
1. Retire `lib/theme/glass_components.dart` after migrating `script_card.dart` and `settle_modal_sheet.dart`
2. Rename/remove old `SettleTheme` in `settle_theme.dart` to eliminate name collision
3. Extract `SettleBottomNavItem` into `glass_nav_bar.dart`, then delete `settle_bottom_nav.dart`

---

### C. Navigation & IA — 7/10

**What's working:**
- `StatefulShellRoute.indexedStack` preserves per-tab scroll/nav state
- `ScreenHeader` implements `context.canPop() ? pop() : go(fallbackRoute)` universally
- Route-responsive theme switching (dark for sleep/reset, light for home/family/library)
- GoRouter error page properly wired to `RouteUnavailableView`

**Violations:**
- 30+ compatibility redirects in `_compatibilityRoutes()` with no comments explaining origin
- `TantrumSubNav` compiled but references dead routes
- `learn.dart` reachable via `/library/learn` but sits at root `screens/` level (breaks file-system IA)
- `ScreenHeader.fallbackRoute` defaults to `'/now'` — a legacy redirect that works but is semantically confusing
- Sleep branch resets to root on any tab tap, which may disorient users mid-flow

**Recommendations:**
1. Add `// LEGACY REDIRECT` comments to all compat routes
2. Move `learn.dart` into `screens/library/`
3. Change `ScreenHeader` default fallbackRoute from `'/now'` to `'/plan'`

---

### D. Screen States — 3/10

**What's working:**
- `CalmLoading` widget design is excellent: reduce-motion-aware opacity pulse, calm message text
- `EmptyState` widget exists with optional action link
- `FamilyRulesState` and `SleepTonightState` carry explicit `error` fields

**Violations:**

**Loading — CalmLoading adoption is incomplete:**

| Uses CalmLoading | Uses CircularProgressIndicator |
|---|---|
| `family_rules.dart` | `plan_home_screen.dart` |
| `today.dart` | `plan_script_log_screen.dart` |
| `sleep_tonight.dart` | `saved_playbook_screen.dart` |
| `update_rhythm_screen.dart` | `library_home_screen.dart` |
| `current_rhythm_screen.dart` | `playbook_card_detail_screen.dart` |
| | `step_action.dart` (regulate) |
| | `step_instant_value.dart` (onboarding) |
| | `reset_flow_screen.dart` |

**Errors — zero retry, missing renders:**
- No `AsyncValue.error` branch in any live screen offers a tap-to-retry button; error branches show text like "Something went wrong" with a navigational escape (e.g., "Open playbook") but no retry
- `FamilyRulesState.error` is set by the provider (`family_rules_provider.dart:181`) but **never rendered** in `family_rules.dart` — the UI silently shows stale data
- Dead tantrum providers return `const []` on error, silently hiding failures

**Empty states — ad-hoc patterns:**
- Most screens handle empty data with inline ad-hoc text instead of `EmptyState` widget
- `EmptyState` action uses `GestureDetector` (no haptics, no semantics, no 48x48 target)

**Recommendations:**
1. Create `SettleErrorState` widget with retry button (companion to `EmptyState`)
2. Replace all `CircularProgressIndicator` in active screens with `CalmLoading`
3. Audit every `AsyncValue.when(error:)` to ensure error-appropriate rendering

---

### E. Interaction Design — 7/10

**What's working:**
- CTA hierarchy: `GlassCta` (primary, full-width, accent) + `GlassPill` (secondary, inline)
- Single-primary-CTA rule followed per section on most screens
- `SettleTappable` enforces 48x48 min touch target, haptics, semantics
- `GlassPill` min height 48px, `GlassCta` min height enforced
- Scale-on-press (0.97, 100ms) provides tactile feedback
- Disabled states (55% opacity, tap suppressed) consistent across `GlassCta` and `GlassPill`

**Violations:**
- `EmptyState` action link uses bare `GestureDetector` — missing haptics, semantics, min touch target
- `GlassCard._GlassCardTapWrapper` uses `Listener`/`GestureDetector` instead of `SettleTappable`
- `SettleTappable` only imported in ~8 files — adoption is low; bare `GestureDetector` appears in more

**Recommendations:**
1. Fix `EmptyState` to use `SettleTappable`
2. Establish lint/review rule: bare `GestureDetector` in screen-level code = review flag

---

### F. Content Patterns — 6/10

**What's working:**
- Guidance content is JSON-driven (`assets/guidance/`), not hardcoded Dart
- Tone is calm and empathetic throughout ("Getting things ready...", "Still okay. Short nap noted.")
- Loading messages are contextually meaningful

**Violations:**
- All UI strings hardcoded inline — no centralized strings file, no localization (`intl`)
- Error messages like "Something went wrong" scattered across individual screen files
- `ScreenHeader.fallbackRoute` defaults to `'/now'` (legacy string)

**Recommendations:**
1. For now: centralize error/empty/loading strings into a `lib/strings.dart` constants file
2. Future: evaluate `intl` + ARB files if multi-language support is needed

---

### G. Accessibility — 7/10

**What's working:**
- `T.reduceMotion(context)` checked in `CalmLoading`, `SettleDisclosure`, `SettleBottomNav`, `MomentFlowScreen`, `ReduceMotionAnimate` extension
- `SettleTappable` wraps interactive elements with `Semantics(button: true, label: ..., hint: ...)`
- `GlassNavBar` items: `Semantics(label: '${item.label} tab', selected: isActive)`
- `SettleModalSheet`: `Semantics(header: true)` on title, `liveRegion: true` on root, `SemanticsService.announce()` on open
- Haptic feedback systematic: `lightImpact` on taps, `selectionClick` on chips
- 24-hour clock support in rhythm screens

**Violations:**
- `EmptyState` action has no semantic label — screen readers cannot identify the action
- Dynamic text scale not clamped — Inter at 200% would overflow `ScreenHeader` and `GlassNavBar` labels
- `GlassNavBar._labelStyle` hardcodes `fontSize: 10` — unresponsive to text scaling
- No contrast validation tooling; `nightMuted` on dark backgrounds may not meet WCAG AA at small sizes

**Recommendations:**
1. Fix `EmptyState` semantic label (QW-1)
2. Add `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)` at `AppShell` level
3. Add a golden-file or integration test for large text scale

---

### H. Performance & Perceived Speed — 7/10

**What's working:**
- Fully offline-first: Hive persistence, no network API calls in normal use
- No network images (all visual via icons, gradients, glass)
- `BouncingScrollPhysics` globally, no overscroll glow
- `ReduceMotionAnimate` skips heavy animation on accessibility devices
- `AnimatedTheme` 300ms crossfade for theme switches

**Concerns:**
- Three Google Font families (Nunito, Inter, Fraunces) downloaded at runtime — first cold-start without network shows unstyled text
- `BackdropFilter(sigma=40–48)` on every `GlassCard` and nav bar is GPU-intensive; no performance budget
- 11 Hive boxes opened sequentially at launch (try/catch per box, but `Future.wait` would be faster)
- No `ListView.builder` pagination — all lists load fully into memory

**Recommendations:**
1. Pre-cache Google Fonts at build time or bundle font files
2. Consider a `repaintBoundary` strategy for glass-heavy list views
3. Parallelize Hive box opening with `Future.wait`

---

## 4. P0 Plan

> P0 = must fix to prevent bad UX or active inconsistency in current live screens.

### P0.1 — Tombstone System A to Prevent New Drift

**Problem:** New code can accidentally import `settle_tokens.dart` and use `T.*` tokens, deepening the dual-system inconsistency with every commit.

**Definition of done:** `T` class and all System A classes carry `@Deprecated` annotations. Old `SettleTheme` in `settle_theme.dart` is renamed to `_LegacySettleTheme`. `settle_design_system.dart` has a clear "CANONICAL" header comment.

**Files:**
- `lib/theme/settle_tokens.dart` — add `@Deprecated` to class `T` and all inner classes
- `lib/theme/settle_theme.dart` — rename `SettleTheme` to `_LegacySettleTheme`, add `@Deprecated`
- `lib/theme/settle_design_system.dart` — add canonical header comment

**Approach:** Add deprecation annotations only. Do not change values or delete code. This is a zero-risk warning-only change.

**Risk:** Deprecation warnings will appear in IDE for every file using `T.*` (~30 files). This is the desired effect — it creates visible migration pressure.

**Test checklist:**
- [ ] `flutter analyze` passes (deprecation warnings are warnings, not errors)
- [ ] App builds and runs normally
- [ ] No runtime behavior change

**Execution order: 1**

---

### P0.2 — Migrate High-Traffic Shared Widgets Off System A

**Problem:** `ScreenHeader`, `CalmLoading`, and `SettleGap` use System A tokens. Because these widgets appear on every screen, the inconsistency propagates everywhere.

**Definition of done:** These 3 widgets import only from `settle_design_system.dart`. `SettleGap.xxl` emits 28px (matching `SettleSpacing.xxl`). `ScreenHeader` uses Inter heading style. `CalmLoading` uses Inter body style.

**Files:**
- `lib/widgets/screen_header.dart` — replace `T.type.h2` → `SettleTypography.heading`, `T.pal.textSecondary` → brightness-aware `SettleColors.nightSoft`/`ink500`, `T.type.caption` → `SettleTypography.caption`, `T.radius.pill` → `SettleRadii.pill`. Fix `fallbackRoute` default from `'/now'` to `'/plan'`.
- `lib/widgets/calm_loading.dart` — replace `T.type.body` → `SettleTypography.body`, `T.pal.textSecondary` → brightness-aware color. Keep `MediaQuery.of(context).disableAnimations` directly instead of `T.reduceMotion`.
- `lib/widgets/settle_gap.dart` — replace `T.space.*` references with `SettleSpacing.*` constants. Note: `SettleSpacing.xxl = 28` (not 24).

**Approach:** One widget at a time. After each, run the app and visually check that headers/loading/spacing look correct.

**Risk:** Font change from Nunito to Inter in `ScreenHeader` titles is a visible change. Heading weight drops from w700 to w600 and size from 22px to 20px. This aligns with the new design direction but should be visually verified on each screen.

**Test checklist:**
- [ ] `flutter analyze` passes
- [ ] Run app → navigate to each of the 4 tabs → verify header text renders correctly
- [ ] Trigger a loading state (e.g., family rules) → verify CalmLoading text style
- [ ] Check spacing between sections on Plan Home

**Execution order: 2**

---

### P0.3 — Fix Error States in Active Screens

**Problem:** No live screen offers a retry button on error. Error branches show text like "Something went wrong" but provide only a navigational escape (e.g., "Open playbook"), not a retry. `FamilyRulesState.error` is set but never shown in the UI.

**Definition of done:** New `SettleErrorState` widget exists. All `AsyncValue.error` branches in active screens include a retry button alongside existing error text. `family_rules.dart` renders its error state.

**Files to create:**
- `lib/widgets/error_state.dart` — `SettleErrorState(message, onRetry?)` using `SettleTappable` for retry, `GlassPill` button, 48px min target, haptics, semantic label

**Files to modify:**
- `lib/screens/library/library_home_screen.dart` — add retry `GlassPill` to existing error Column
- `lib/screens/library/saved_playbook_screen.dart` — add retry to error GlassCard
- `lib/screens/library/playbook_card_detail_screen.dart` — add retry to error branch
- `lib/screens/plan/plan_script_log_screen.dart` — add error state with retry
- `lib/screens/family_rules.dart` — add rendering of `rulesState.error` when non-null

**Approach:** Create the `SettleErrorState` widget first (mirrors `EmptyState` structure). Then sweep through each screen replacing error branches. Use `ref.invalidate(provider)` for retry in `FutureProvider` screens and `ref.read(provider.notifier).load()` for `StateNotifierProvider` screens.

**Risk:** Low. Error states are currently broken; any change is an improvement. The retry callback must match the provider's reload pattern.

**Test checklist:**
- [ ] Force an error in `FamilyRulesNotifier` (e.g., corrupt Hive box) → verify error text appears + retry button works
- [ ] For each library screen, verify `AsyncValue.error` renders `SettleErrorState` not a spinner
- [ ] Tap retry → verify state reloads

**Execution order: 3**

---

### P0.4 — Fix EmptyState Touch Target & Accessibility

**Problem:** `EmptyState`'s action link uses bare `GestureDetector` — no haptic feedback, no semantic label, no 48x48 min touch target. This violates the app's own accessibility contract established by `SettleTappable`.

**Definition of done:** `EmptyState` action wraps in `SettleTappable`. Action has a semantic label. Spacing uses `SettleSpacing.md` instead of magic number `12`.

**Files:**
- `lib/widgets/empty_state.dart` — replace `GestureDetector` → `SettleTappable(semanticLabel: actionLabel!, onTap: onAction!, child: ...)`. Replace `const SizedBox(height: 12)` → `const SizedBox(height: SettleSpacing.md)`.

**Risk:** None. Pure improvement.

**Test checklist:**
- [ ] Find a screen showing `EmptyState` with an action → verify tap triggers haptic + action
- [ ] Enable TalkBack/VoiceOver → verify action is announced with label
- [ ] Verify touch target is at least 48x48

**Execution order: 4**

---

## 5. P1 Plan

> P1 = important improvements after P0 is complete.

### P1.1 — Delete All Dead Code

**Problem:** ~25–30 compiled files are unreachable, adding to build time, IDE noise, and cognitive load.

**Definition of done:** All dead files deleted. No route references broken. Build succeeds.

**Files to delete:**
- `lib/screens/tantrum/` — entire directory (16 files)
- `lib/widgets/tantrum_sub_nav.dart`
- `lib/tantrum/` — providers, models, services (verify no live imports first)
- `lib/screens/home.dart` (legacy, not routed)
- `lib/screens/help_now.dart` (legacy, not routed)
- `lib/screens/plan_progress.dart` (legacy, not routed)
- `lib/screens/relief_hub.dart` (legacy, not routed)
- `lib/screens/sleep_hub_screen.dart` (legacy, not routed)

**Files to modify:**
- `lib/router.dart` — remove tantrum-specific compat redirects; keep `/tantrum/just-happened` → `/plan/reset?context=tantrum` if deep-linked externally

**Approach:** Delete in dependency order — widgets first, then screens, then providers/models. Run `flutter analyze` after each batch.

**Risk:** Medium. Must verify each file has zero live imports before deletion. The 30 compat redirects in `router.dart` should be audited for external deep-link usage (push notifications, shared links) before removal.

**Test checklist:**
- [ ] `flutter analyze` passes after each deletion batch
- [ ] App builds and all 4 tabs render correctly
- [ ] All navigation paths in router work

**Execution order: 5**

---

### P1.2 — Complete CalmLoading Migration

**Problem:** 8 active screens still use `CircularProgressIndicator` instead of the branded `CalmLoading`.

**Definition of done:** All loading indicators in active screens are `CalmLoading` with contextual messages.

**Files:**
- `lib/screens/plan/plan_home_screen.dart` → `CalmLoading(message: 'Finding the right approach...')`
- `lib/screens/plan/plan_script_log_screen.dart` → `CalmLoading(message: 'Loading session log...')`
- `lib/screens/plan/reset_flow_screen.dart` → `CalmLoading(message: 'Preparing your reset...')`
- `lib/screens/library/saved_playbook_screen.dart` → `CalmLoading(message: 'Loading your playbook...')`
- `lib/screens/library/library_home_screen.dart` → `CalmLoading(message: 'Loading library...')`
- `lib/screens/library/playbook_card_detail_screen.dart` → `CalmLoading(message: 'Loading card...')`
- `lib/screens/regulate/step_action.dart` → `CalmLoading(message: 'Getting your next step...')`
- `lib/screens/onboarding/steps/step_instant_value.dart` → `CalmLoading(message: 'Almost there...')`

**Risk:** Low. Direct widget swap with no logic change.

**Execution order: 6**

---

### P1.3 — Retire Old glass_components.dart

**Problem:** Old `GlassCard`/`GlassPill`/`GlassCta`/`SettleBackground` in `glass_components.dart` use System A tokens and different blur values (sigma 12 vs 40).

**Definition of done:** All consumers migrated to new widgets. `glass_components.dart` and `surface_mode_resolver.dart` deleted.

**Files to modify:**
- `lib/widgets/script_card.dart` — replace old `GlassPill` import with `lib/widgets/glass_pill.dart`
- `lib/widgets/settle_modal_sheet.dart` — replace old `GlassCard` with new `GlassCard`
- `lib/widgets/micro_celebration.dart` — replace `GlassCardAccent` with new `GlassCard(variant: .lightStrong)` or similar
- `lib/widgets/weekly_reflection.dart` — replace `GlassCardTeal` with new `GlassCard` + teal border
- `lib/widgets/release_surfaces.dart` — replace old `GlassCard` + `GlassCta`

**Files to delete after migration:**
- `lib/theme/glass_components.dart`
- `lib/theme/surface_mode_resolver.dart`

**Risk:** Medium. The `GlassCta` widget (solid accent button) has no direct equivalent in the new widgets — it may need to be recreated or absorbed into `GlassPill` with a new variant. `SettleBackground` (animated gradient wrapper) is used by some screens and may need a replacement in `gradient_background.dart`.

**Execution order: 7**

---

### P1.4 — Retire SettleBottomNav Widget

**Problem:** `settle_bottom_nav.dart` renders a nav bar that is never shown, but its `SettleBottomNavItem` type is still imported by `router.dart` and `app_shell.dart`.

**Definition of done:** `SettleBottomNavItem` moved. Old file deleted.

**Files:**
- Move `SettleBottomNavItem` class into `lib/widgets/glass_nav_bar.dart` (or new `lib/models/nav_item.dart`)
- Update imports in `lib/router.dart` and `lib/screens/app_shell.dart`
- Delete `lib/widgets/settle_bottom_nav.dart`

**Risk:** Low. Pure refactor.

**Execution order: 8**

---

### P1.5 — Fix GlassNavBar Font Reference

**Problem:** `GlassNavBar` hardcodes `GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 0.02)` instead of using `SettleTypography.caption`.

**Definition of done:** Nav bar label uses `SettleTypography.caption.copyWith(letterSpacing: 0.02)`.

**Files:** `lib/widgets/glass_nav_bar.dart:61`

**Risk:** None. Font is already Inter; this just routes through the token.

**Execution order: 9**

---

### P1.6 — Complete System A → B Migration for Remaining Widgets

**Problem:** ~10 widgets still import `settle_tokens.dart` for spacing, colors, or typography.

**Files (in priority order):**
1. `lib/widgets/settle_disclosure.dart`
2. `lib/widgets/settle_chip.dart`
3. `lib/widgets/settle_modal_sheet.dart`
4. `lib/widgets/settle_segmented_choice.dart`
5. `lib/widgets/option_button.dart`
6. `lib/widgets/output_card.dart`
7. `lib/widgets/wake_arc.dart`
8. `lib/widgets/weekly_reflection.dart`

**Approach:** For each, replace `T.type.*` → `SettleTypography.*`, `T.pal.*` → `SettleColors.*`, `T.space.*` → `SettleSpacing.*`, `T.radius.*` → `SettleRadii.*`, `T.glass.*` → `SettleGlass.*`, `T.anim.*` → keep as-is (animation tokens have no System B equivalent yet; consider migrating later).

**Risk:** Low per file. Tedious but mechanical.

**Execution order: 10**

---

### P1.7 — Add Text Scaling Guards

**Problem:** Inter at 200% text scale would overflow `ScreenHeader`, `GlassNavBar` labels, and most card titles.

**Definition of done:** Text scale clamped at app shell level. Golden-file test for large text exists.

**Files:**
- `lib/screens/app_shell.dart` — wrap body with `MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3)`
- Add integration test: `test/core_screens_text_scale_test.dart`

**Risk:** Clamping text scale may frustrate users who need very large text. Consider 1.5 as max instead of 1.3. Test with actual accessibility users if possible.

**Execution order: 11**

---

## 6. Rules Contract

> These rules are binding for all new code and for every file touched during P0/P1 migration.

### RC-01: Single Design System — System B Is Canonical

All new code MUST import from `lib/theme/settle_design_system.dart` only:
- Colors: `SettleColors.*`
- Typography: `SettleTypography.*`
- Spacing: `SettleSpacing.*`
- Radii: `SettleRadii.*`
- Glass: `SettleGlass.light.*` / `SettleGlass.dark.*`
- Gradients: `SettleGradients.*`
- Theme: `SettleTheme.light` / `SettleTheme.dark`

`import 'settle_tokens.dart'` is **PROHIBITED** in any new file. Any PR touching a file that uses `T.*` must migrate that file's usages as part of the PR.

**Exception process:** If a legitimate need for a System A token arises (e.g., `T.anim.breathe` has no System B equivalent), document it in the PR description and propose adding the token to System B.

---

### RC-02: Allowed Spacing Scale

| Token | Value | Usage |
|---|---|---|
| `SettleSpacing.xs` | 4 | Micro gaps, icon-to-label |
| `SettleSpacing.sm` | 8 | Card-internal line gaps, chip padding |
| `SettleSpacing.md` | 12 | Default vertical rhythm between elements |
| `SettleSpacing.lg` | 16 | Section subdivisions, card-to-card |
| `SettleSpacing.xl` | 20 | Section gaps, top padding below header |
| `SettleSpacing.xxl` | 28 | Major section separations |
| `SettleSpacing.screenPadding` | 18 | Horizontal screen edge padding (all screens) |
| `SettleSpacing.cardPadding` | 20 | GlassCard internal padding |
| `SettleSpacing.cardGap` | 8 | Gap between stacked cards |
| `SettleSpacing.sectionGap` | 20 | Gap between sections |

**Vertical rhythm rules:**
- Screen top (below header): `SettleSpacing.xl` (20)
- Between sections: `SettleSpacing.sectionGap` (20) or `SettleSpacing.xxl` (28) for major breaks
- Between cards in a list: `SettleSpacing.cardGap` (8)
- Between elements in a card: `SettleSpacing.sm` (8) or `SettleSpacing.md` (12)

**PROHIBITED:** `SizedBox(height: N)` where N is not a named `SettleSpacing` constant. `EdgeInsets.all(N)` where N is not a named constant. Use `SettleGap.*` in Column/Row or `SizedBox(height: SettleSpacing.*)`.

---

### RC-03: Allowed Type Scale

| Token | Font | Size | Weight | Usage |
|---|---|---|---|---|
| `SettleTypography.display` | Fraunces | 28 | w400 | Moment/Reset greetings, emotional headings |
| `SettleTypography.heading` | Inter | 20 | w600 | Screen titles, section headers |
| `SettleTypography.body` | Inter | 14 | w400 | Body copy, descriptions, guidance text |
| `SettleTypography.caption` | Inter | 11.5 | w500 | Labels, timestamps, nav bar text |

**Max lines by context:**
- Hero/display text: 2 lines max
- Guidance body in cards: 4 lines max, then disclosure/expand
- CTA label: 1 line, `maxLines: 1, overflow: TextOverflow.ellipsis`
- Nav bar label: 1 line

**Emphasis rules:**
- Prefer size + spacing over bold to create hierarchy
- Use `fontWeight: FontWeight.w600` (Inter heading weight) for emphasis within body text
- Do not use `FontWeight.w700` or `w800` in body contexts
- No direct `GoogleFonts.*` calls in widget code — all font access through `SettleTypography.*`

---

### RC-04: Allowed Components

**Primary interactive:**
- `GlassCta` — primary CTA, full-width, accent fill. ONE per visible section.
- `GlassPill` — secondary action, inline. Multiple allowed per section.
- `SettleTappable` — accessible tap wrapper. REQUIRED for all custom tap targets.
- `SettleChip` / `SettleSegmentedChoice` — selection controls.

**Containers:**
- `GlassCard` (from `lib/widgets/glass_card.dart` ONLY) — glass surface container.
- `SettleModalSheet` / `showSettleSheet()` — bottom sheet.
- `SettleDisclosure` — expand/collapse section.

**Layout:**
- `ScreenHeader` — screen-level back + title + trailing.
- `SettleGap` — token-based spacing in Column/Row.
- `GradientBackground` / `GradientBackgroundFromRoute` — screen background.

**Feedback:**
- `CalmLoading` — all loading states.
- `EmptyState` — all empty collection states.
- `SettleErrorState` (P0.3) — all error states with retry.
- `MicroCelebration` — success confirmation.

**DISALLOWED patterns:**
- `Container` with inline `padding`/`margin`/`decoration` for layout (use `Padding` + `SizedBox` + tokens)
- Raw `CircularProgressIndicator` in any screen-level widget
- Raw `GestureDetector` or `InkWell` in screen-level code (use `SettleTappable`)
- Ad-hoc `TextStyle(...)` construction (use `SettleTypography.*` with `.copyWith()`)
- Nested `SingleChildScrollView` inside a `ListView`
- Multiple `GlassCta` buttons in the same visible section
- Importing from `lib/theme/glass_components.dart`

---

### RC-05: Navigation Patterns

**Tab destinations:**
| Tab | Label | Path | Meaning |
|---|---|---|---|
| 0 | Home | `/plan` | "What should I do right now?" |
| 1 | Family | `/family` | "Shared family tools" |
| 2 | Sleep | `/sleep` | "Tonight's sleep plan" |
| 3 | Library | `/library` | "Past logs, saved cards, patterns" |

**Back behavior:** All sub-screens use `ScreenHeader` with `context.canPop() ? pop() : go(fallbackRoute)`. The `fallbackRoute` MUST be the tab root path (e.g., `/plan`, `/family`).

**Route naming:** All new routes MUST follow `/<tab>/<feature>` pattern. Parameters via path segments (`/library/cards/:id`) or query params (`/plan/reset?context=tantrum`). No orphan routes outside the shell.

**New route location:** All new routes MUST be added under the appropriate `StatefulShellBranch` in `router.dart`. New entries in `_compatibilityRoutes()` are PROHIBITED unless needed for deep-link backward compatibility (with a comment explaining the origin).

---

### RC-06: State Conventions

**For every screen, the following states MUST be handled:**

| State | Required | Widget |
|---|---|---|
| Loading | Yes | `CalmLoading(message: '...')` with contextual message |
| Empty | Yes | `EmptyState(message: '...', actionLabel: '...', onAction: ...)` |
| Error | Yes | `SettleErrorState(message: '...', onRetry: ...)` |
| Success | Yes | Normal content |
| Offline | No* | Not required (app is offline-first via Hive) |

*If a screen makes a network call (future feature), offline state becomes required.

**Retry conventions:**
- `FutureProvider`: retry via `ref.invalidate(provider)`
- `StateNotifierProvider`: retry via `ref.read(provider.notifier).load()`
- Retry button: `GlassPill(label: 'Try again', onTap: ...)` inside `SettleErrorState`

**Skeleton vs spinner:** Use `CalmLoading` (text pulse) for all loading states. No skeletons or shimmers required at this time. If loading takes >3s, the `CalmLoading` message should acknowledge the wait: "Still working on this..."

**State logic location:** All async state lives in Riverpod providers (`StateNotifierProvider` or `FutureProvider`). Screens are stateless consumers (`ConsumerWidget`) except when local ephemeral UI state (animation controllers, text controllers) requires `ConsumerStatefulWidget`.

---

### RC-07: Content Density Rules

**"20-second win" rule:** A parent in crisis must be able to open the app and reach actionable guidance within 20 seconds. The Plan Home → card selection → script display flow must not exceed 3 taps.

**"One CTA" rule:** Each visible section has at most ONE `GlassCta` (primary) button. Secondary options use `GlassPill`. If a section needs 3+ actions, use a `SettleDisclosure` or modal sheet.

**Guidance card density:**
- Title: 1 line max
- Scenario/context badge: 1 line
- Summary: 3 lines max, then "Show more" via `SettleDisclosure`
- Action steps: 4 bullets max visible, rest behind disclosure

**No paragraphs in crisis flows:** Reset and Regulate flows use short declarative sentences (1-2 lines each). Body text in these flows must not exceed 2 lines per step.

---

### RC-08: Glass Component Variant Selection

| Background | Card variant | Pill variant |
|---|---|---|
| Light gradient (home, library, family) | `GlassCardVariant.light` | `GlassPillVariant.primaryLight` / `secondaryLight` |
| Light gradient, emphasis | `GlassCardVariant.lightStrong` | `GlassPillVariant.primaryLight` |
| Dark gradient (sleep, reset) | `GlassCardVariant.dark` | `GlassPillVariant.primaryDark` / `secondaryDark` |
| Dark gradient, emphasis | `GlassCardVariant.darkStrong` | `GlassPillVariant.primaryDark` |

---

### RC-09: Animation Conventions

Animation duration tokens (from `T.anim` — to be migrated to System B):
| Token | Duration | Usage |
|---|---|---|
| `fast` | 150ms | Quick state changes (chip select, toggle) |
| `normal` | 250ms | Standard transitions (disclosure expand, pill swap) |
| `slow` | 400ms | Deliberate transitions (card appear, screen enter) |
| `modeSwitch` | 800ms | Day/night gradient transition |

All animations MUST check `MediaQuery.of(context).disableAnimations` and use `Duration.zero` when true. Use `ReduceMotionAnimate` extension for entry animations or `createSettleAnimation()` utility for controllers.

---

### RC-10: Reduce-Motion & Reduce-Transparency

- All `AnimationController` durations MUST be `Duration.zero` when `MediaQuery.disableAnimations` is true
- All `BackdropFilter` widgets SHOULD fall back to a solid fill when `MediaQuery.highContrast` is true (future improvement)
- The `ReduceMotionAnimate` extension (`lib/theme/reduce_motion.dart`) is the preferred API for entry animations

---

## 7. Quick Wins

Low-effort, high-impact fixes. Each takes <30 minutes.

| # | Fix | File | Effort | Impact |
|---|---|---|---|---|
| QW-1 | Fix EmptyState GestureDetector → SettleTappable | `lib/widgets/empty_state.dart` | 15 min | Every screen using EmptyState gains proper a11y |
| QW-2 | Fix GlassNavBar hardcoded font | `lib/widgets/glass_nav_bar.dart:61` | 5 min | Aligns nav label with design system |
| QW-3 | Mark `settle_theme.dart` deprecated | `lib/theme/settle_theme.dart` | 10 min | Prevents name collision confusion |
| QW-4 | Fix ScreenHeader fallbackRoute `/now` → `/plan` | `lib/widgets/screen_header.dart` | 5 min | Removes confusing legacy default |
| QW-5 | Render FamilyRulesState.error in UI | `lib/screens/family_rules.dart` | 20 min | Users can see and understand errors |
| QW-6 | Add retry button to library error branches | `lib/screens/library/library_home_screen.dart`, `saved_playbook_screen.dart` | 20 min | Error states become actionable instead of dead-ends |
| QW-7 | Align SettleGap.xxl to 28px | `lib/widgets/settle_gap.dart` | 10 min | Fixes 4px spacing mismatch everywhere |
| QW-8 | Add LIVE/LEGACY comments to router.dart | `lib/router.dart` | 20 min | Prevents devs building on dead routes |

---

## 8. Tech Debt Register

| ID | Area | Issue | Impact | Fix Effort | Module |
|---|---|---|---|---|---|
| TD-01 | Design System | System A (`settle_tokens.dart`) co-exists with System B across ~30 files | Critical | XL | `lib/theme/` |
| TD-02 | Component | Duplicate GlassCard in `glass_components.dart` | High | S | `lib/theme/`, `lib/widgets/` |
| TD-03 | Component | Duplicate GlassPill in `glass_components.dart` | High | S | `lib/theme/`, `lib/widgets/` |
| TD-04 | Design System | Old SettleTheme class name-collides with new SettleTheme | High | XS | `lib/theme/settle_theme.dart` |
| TD-05 | Navigation | SettleBottomNav compiled but not rendered | Medium | S | `lib/widgets/settle_bottom_nav.dart` |
| TD-06 | Dead Code | 16 tantrum screens compiled, all routes redirect | High | M | `lib/screens/tantrum/` |
| TD-07 | Dead Code | 5+ legacy flat-root screens unreferenced | Medium | S | `lib/screens/*.dart` |
| TD-08 | Dead Code | TantrumSubNav references nonexistent routes | Medium | XS | `lib/widgets/tantrum_sub_nav.dart` |
| TD-09 | Screen States | Zero retry buttons in any live error state | Critical | M | All screens |
| TD-10 | Screen States | CircularProgressIndicator in 8 active screens | High | M | Multiple screens |
| TD-11 | Screen States | No retry button in any AsyncValue.error branch | High | S | Multiple screens |
| TD-12 | Screen States | FamilyRulesState.error never rendered in UI | High | XS | `family_rules.dart` |
| TD-13 | Accessibility | EmptyState uses GestureDetector (no haptics/semantics) | High | XS | `empty_state.dart` |
| TD-14 | Typography | GlassNavBar hardcodes GoogleFonts.inter() | Low | XS | `glass_nav_bar.dart` |
| TD-15 | Spacing | SettleGap token values misalign with SettleSpacing | High | XS | `settle_gap.dart` |
| TD-16 | Spacing | Mixed T.space / SettleSpacing / raw SizedBox in same files | High | XL | Multiple screens |
| TD-17 | Typography | ScreenHeader uses T.type.h2 (System A) | High | XS | `screen_header.dart` |
| TD-18 | Typography | CalmLoading uses T.type.body (System A) | Medium | XS | `calm_loading.dart` |
| TD-19 | Performance | Three Google Font families with no pre-caching | Medium | M | `main.dart`, `pubspec.yaml` |
| TD-20 | Accessibility | No text scale clamping — UI breaks at 200% | Medium | S | `app_shell.dart` |
| TD-21 | Localization | All UI strings hardcoded — no centralized strings | Low | XL | All screens |
| TD-22 | Navigation | ScreenHeader fallbackRoute defaults to `/now` | Low | XS | `screen_header.dart` |
| TD-23 | Navigation | 30+ compat redirects without comments | Low | S | `router.dart` |
| TD-24 | Performance | BackdropFilter sigma=40-48 on all glass — no perf budget | Low | M | Glass widgets |
| TD-25 | Dead Code | SurfaceModeResolver only used by deprecated GlassCard | Low | XS | `surface_mode_resolver.dart` |

---

## 9. Appendix: Evidence Links

### Design System Files
- `lib/theme/settle_tokens.dart` — System A tokens (T alias)
- `lib/theme/settle_theme.dart` — System A theme builder (Nunito, dark-only)
- `lib/theme/settle_design_system.dart` — System B tokens + theme (Inter, Fraunces, light+dark)
- `lib/theme/glass_components.dart` — Old GlassCard/GlassPill/GlassCta/SettleBackground
- `lib/theme/surface_mode_resolver.dart` — SurfaceMode (day/night/focus), used only by old GlassCard
- `lib/theme/reduce_motion.dart` — ReduceMotionAnimate extension

### New Glass Components
- `lib/widgets/glass_card.dart` — New GlassCard (GlassCardVariant enum)
- `lib/widgets/glass_pill.dart` — New GlassPill (GlassPillVariant enum)
- `lib/widgets/glass_chip.dart` — GlassChip (domain-tinted)
- `lib/widgets/glass_nav_bar.dart` — GlassNavBar (active bottom nav)

### Screen State Widgets
- `lib/widgets/calm_loading.dart` — CalmLoading (opacity pulse)
- `lib/widgets/empty_state.dart` — EmptyState (text + optional action)
- `lib/widgets/release_surfaces.dart` — FeaturePausedView, ProfileRequiredView, RouteUnavailableView

### Navigation & Layout
- `lib/router.dart` — GoRouter, all routes, compat redirects
- `lib/screens/app_shell.dart` — Root shell scaffold
- `lib/widgets/screen_header.dart` — Back + title header
- `lib/widgets/gradient_background.dart` — Route-responsive gradient backgrounds

### Interaction & Feedback
- `lib/widgets/settle_tappable.dart` — Accessible tap primitive (48x48, haptics, semantics)
- `lib/widgets/settle_chip.dart` — SettleChip (tag/action/frequency variants)
- `lib/widgets/settle_segmented_choice.dart` — Single-select chip group
- `lib/widgets/settle_disclosure.dart` — Expand/collapse accordion
- `lib/widgets/micro_celebration.dart` — Success celebration banner

### Duplicate Component Evidence
- `lib/screens/plan/plan_home_screen.dart:14` — `import '../../theme/glass_components.dart' hide GlassCard, GlassPill;`
- `lib/screens/plan/plan_home_screen.dart:74` — mixes `SettleSpacing.screenPadding` with `T.space.md`

### Dead Code
- `lib/screens/tantrum/` — 16 files, all routes redirect to `/plan`
- `lib/screens/home.dart` — legacy, not routed
- `lib/screens/help_now.dart` — legacy, not routed
- `lib/screens/plan_progress.dart` — legacy, not routed
- `lib/screens/relief_hub.dart` — legacy, not routed
- `lib/screens/sleep_hub_screen.dart` — legacy, not routed
- `lib/widgets/tantrum_sub_nav.dart` — references dead routes
- `lib/widgets/settle_bottom_nav.dart` — widget not rendered (type still imported)

### State Management
- `lib/providers/profile_provider.dart` — profileProvider (constructor-initiated async load)
- `lib/providers/rhythm_provider.dart` — rhythmProvider (RhythmState with isLoading)
- `lib/providers/sleep_tonight_provider.dart` — sleepTonightProvider (lastError field)
- `lib/providers/family_rules_provider.dart` — familyRulesProvider (error field, never rendered)
- `lib/providers/reset_flow_provider.dart` — resetFlowProvider
- `lib/providers/user_cards_provider.dart` — userCardsProvider
