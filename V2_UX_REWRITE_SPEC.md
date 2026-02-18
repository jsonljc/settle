# V2 UX Rewrite Spec (Commit-Ready Checklist)

Status: Draft for implementation
Owner: Product + Engineering
Last updated: 2026-02-18

## 1) Goal

Ship the canonical v2 experience with:

- Bottom nav: `Now / Sleep / Library`
- Overlays: `Family`, `Settings`
- Persistent Pocket shortcut
- Default first-open behavior to Sleep daily Rhythm

Locked visual constraints:

- Keep current background system (`GradientBackgroundFromRoute`)
- Keep current liquid glass style (cards, pills, nav bar)

## 2) Guardrails (Non-Negotiable)

- Crisis flow first guidance visible in <= 20 seconds
- No typing required in crisis flows
- One clear primary action per screen
- Offline-safe behavior preserved for core flows
- Small, atomic PRs only
- No broad refactor outside listed scope

## 3) Task Index

Use these IDs in commits/PR descriptions.

- `UXV2-001` Router IA rewrite to 3 tabs + 2 overlays
- `UXV2-002` Default landing to Sleep root
- `UXV2-003` Sleep root becomes Rhythm daily surface
- `UXV2-004` Sleep setup gate demoted to inline setup card
- `UXV2-005` Sleep Tonight crisis-path simplification
- `UXV2-006` Pocket contextual ordering and a11y pass
- `UXV2-007` Library split: Progress vs Logs
- `UXV2-008` Family converted from tab to overlay entry
- `UXV2-009` Settings converted from tab to overlay entry
- `UXV2-010` Glass component unification (single source in widgets)
- `UXV2-011` Interaction/a11y cleanup (`SettleTappable`, semantics)
- `UXV2-012` Spacing/token cleanup in touched screens
- `UXV2-013` Compatibility redirects retained and validated
- `UXV2-014` Release QA + regression verification

## 4) PR Slicing Plan

Each PR is independently reviewable and shippable.

---

## PR-01: Navigation + Routing Foundation

Tasks: `UXV2-001`, `UXV2-013`

### Scope

- Replace 4-tab shell with 3-tab shell (`Now`, `Sleep`, `Library`)
- Move `Family` and `Settings` to overlay entry points
- Preserve legacy compatibility redirects

### Files

- `lib/router.dart`
- `lib/screens/app_shell.dart`
- `lib/widgets/glass_nav_bar.dart`
- `lib/widgets/nav_item.dart` (if needed)

### Checklist

- [ ] Nav items changed to `Now`, `Sleep`, `Library`
- [ ] Family removed as bottom tab and exposed via overlay trigger
- [ ] Settings removed from tab model and exposed via overlay trigger
- [ ] Legacy routes still redirect cleanly (`/help-now`, `/home`, v1 paths)
- [ ] Deep links continue to open target flows directly

### Done When

- [ ] App boots into 3-tab shell without runtime route errors
- [ ] Legacy links verified manually

---

## PR-02: Entry Behavior + Sleep Root

Tasks: `UXV2-002`, `UXV2-003`, `UXV2-004`

### Scope

- Existing users land on Sleep root (Rhythm daily view)
- Onboarding completion routes to Sleep root
- Sleep setup gate becomes inline prompt, not a hard gate

### Files

- `lib/screens/splash.dart`
- `lib/screens/onboarding/onboarding_v2_screen.dart`
- `lib/router.dart`
- `lib/screens/sleep/sleep_mini_onboarding.dart`
- `lib/screens/current_rhythm_screen.dart`

### Checklist

- [ ] Splash redirect updated from `/plan` to `/sleep`
- [ ] Onboarding completion redirect updated from `/plan` to `/sleep`
- [ ] `/sleep` root renders Rhythm daily surface by default
- [ ] Missing sleep setup shows inline setup card on Sleep root
- [ ] Sleep root remains usable even if setup incomplete

### Done When

- [ ] New and returning user paths both reach Sleep daily surface
- [ ] No blocking setup wizard before seeing Sleep value

---

## PR-03: Now Surface + Crisis Speed

Tasks: `UXV2-005`

### Scope

- Replace Plan-style Now root with explicit crisis launcher
- Keep fast entries to Sleep Tonight / Reset / Moment / Tantrum context

### Files

- `lib/screens/plan/plan_home_screen.dart` (repurpose to Now home)
- `lib/router.dart` (route naming/aliases if needed)
- `lib/screens/plan/reset_flow_screen.dart` (only if CTA integration needed)
- `lib/screens/plan/moment_flow_screen.dart` (only if CTA integration needed)

### Checklist

- [ ] Now screen has one dominant primary action hierarchy
- [ ] Max 3 crisis entry tiles on first viewport
- [ ] No dense preamble copy before action
- [ ] No keyboard-triggering input on crisis path
- [ ] Time-to-first-guidance measured and logged <= 20s

### Done When

- [ ] Manual stopwatch pass for all Now entry routes

---

## PR-04: Sleep Tonight Simplification

Tasks: `UXV2-005`, `UXV2-012`

### Scope

- Keep current Sleep Tonight visual language
- Reduce option density and remove non-critical branching from crisis path

### Files

- `lib/screens/sleep_tonight.dart`

### Checklist

- [ ] Keep situation picker + 3-step guidance card
- [ ] `More options` trimmed to max 4 actions:
  - [ ] Switch scenario
  - [ ] Why this works
  - [ ] Mark done
  - [ ] Change approach
- [ ] Free-text note removed from immediate crisis path
- [ ] Primary CTA always visible without hunt
- [ ] Supporting copy per block <= 2 short lines where possible

### Done When

- [ ] Crisis flow feels linear and low-friction
- [ ] No regression in active plan lifecycle

---

## PR-05: Library Restructure (After Surface)

Tasks: `UXV2-007`

### Scope

- Split Library into:
  - Progress (supportive trend framing)
  - Logs (chronological events)
- Reduce dashboard feel in current Logs screen

### Files

- `lib/screens/library/library_home_screen.dart`
- `lib/screens/today.dart` (repurpose or split)
- `lib/screens/plan/plan_script_log_screen.dart` (source for logs path)
- `lib/router.dart` (library subroutes)

### Checklist

- [ ] `/library` clearly presents `Progress`, `Logs`, `Learn`, `Saved`
- [ ] Progress view requires minimum data threshold before chart/trend
- [ ] Logs view is timeline-first, not analytics-first
- [ ] CTA hierarchy remains calm and simple

### Done When

- [ ] Library mental model reads as "After" not "dashboard"

---

## PR-06: Family + Settings as Overlays

Tasks: `UXV2-008`, `UXV2-009`

### Scope

- Remove Family/Settings from tab ownership
- Launch both as overlays from shell-level actions

### Files

- `lib/screens/app_shell.dart`
- `lib/screens/family/family_home_screen.dart`
- `lib/screens/settings.dart`
- `lib/widgets/settle_modal_sheet.dart` (or equivalent overlay container)
- `lib/router.dart` (entry points)

### Checklist

- [ ] Family opens as overlay and preserves existing routes inside feature
- [ ] Settings opens as overlay and preserves existing settings sections
- [ ] Overlay close/back behavior is consistent
- [ ] No tab reintroduction of Family/Settings

### Done When

- [ ] Overlay flows work from all three tabs

---

## PR-07: Component + A11y + Consistency Cleanup

Tasks: `UXV2-006`, `UXV2-010`, `UXV2-011`, `UXV2-012`, `UXV2-014`

### Scope

- Consolidate glass primitives to one implementation family
- Improve semantics and tap-target consistency
- Normalize spacing usage in all touched files
- Final regression pass

### Files

- `lib/theme/glass_components.dart`
- `lib/widgets/glass_card.dart`
- `lib/widgets/glass_pill.dart`
- `lib/widgets/settle_tappable.dart`
- `lib/screens/pocket/pocket_fab_and_overlay.dart`
- `lib/screens/pocket/pocket_overlay.dart`
- Any touched screen from prior PRs

### Checklist

- [ ] No dual-implementation conflict for GlassCard/GlassPill in feature screens
- [ ] Remove `hide GlassCard` style import workarounds where possible
- [ ] Replace bare `GestureDetector` on user-facing controls with `SettleTappable` where applicable
- [ ] Semantics labels present on all new interactive controls
- [ ] Spacing in touched files uses `SettleGap` and tokenized values
- [ ] Pocket ordering is contextual first, pinned fallback second

### Done When

- [ ] No new a11y regressions in VoiceOver/TalkBack smoke test
- [ ] Visual language still matches current background + liquid glass

---

## 5) QA Checklist (Run Per PR + Final)

- [ ] `flutter analyze` passes for touched files
- [ ] Manual dark/light checks on key flows (`Now`, `Sleep`, `Library`)
- [ ] Crisis-path stopwatch checks:
  - [ ] Now -> first guidance <= 20s
  - [ ] Sleep Tonight -> first guidance <= 20s
  - [ ] Reset -> first card <= 20s
- [ ] One-handed reachability pass (primary actions in thumb zone)
- [ ] Large text scale smoke test (no critical overflow on primary actions)
- [ ] Reduce-motion behavior still respected where already implemented
- [ ] Offline smoke test for core script/rhythm access

## 6) Suggested Commit Strategy

Use atomic commits tied to task IDs.

Examples:

- `feat(nav): v2 3-tab shell + compatibility redirects (UXV2-001 UXV2-013)`
- `feat(entry): default landing to sleep rhythm root (UXV2-002 UXV2-003 UXV2-004)`
- `feat(now): simplify crisis launcher surface (UXV2-005)`
- `feat(sleep): trim sleep tonight option density (UXV2-005 UXV2-012)`
- `feat(library): split progress and logs surfaces (UXV2-007)`
- `feat(overlays): family/settings overlay entry points (UXV2-008 UXV2-009)`
- `refactor(ui): glass unification + a11y consistency pass (UXV2-006 UXV2-010 UXV2-011 UXV2-012)`

## 7) Out of Scope (This Rewrite)

- New clinical content authoring
- New monetization/paywall mechanics
- Major data model migrations
- Big-bang folder structure migration (`screens/widgets/providers/services` to `ui/state/domain/data`)

