# Migrate to v2 — Clean Migration Plan

**Goal:** Make v2 the default (and eventually only) experience so all users see the Plan / Family / Sleep / Library shell, Pocket, and Regulate flow without toggling Release Ops.

**Reference:** `V2_AUDIT_REPORT.md`, `V2_ENABLE_LOCALLY.md`, `V2_FIX_ALL_PLAN.md`.

---

## Current state

- **Router** is built once at startup from Hive box `release_rollout_v1` (key `state`). It chooses either:
  - **v1 shell:** Help Now, Sleep, Progress, Tantrum (tabs); `/now`, `/progress`, `/tantrum`, etc.
  - **v2 shell:** Plan, Family, Sleep, Library (tabs); `/plan`, `/family`, `/sleep`, `/library`; Pocket overlay when `pocketEnabled`.
- **Defaults** in `ReleaseRolloutState.initial` and in the Hive read path set all v2 flags to `false`, so existing installs see v1 unless they toggle v2 in Release Ops or set Hive manually.
- **Splash** sends users to `/plan` when `v2NavigationEnabled` and profile exists, else `/now` (v1) or onboard.

---

## Principles

1. **Reversible until Phase 3.** Phase 1–2 keep v1 code paths; we only change defaults and add a one-time migration so rollback is “flip default back / clear Hive”.
2. **No big-bang rewrite.** Each phase is shippable and testable.
3. **Deep links and bookmarks.** Keep compatibility redirects so old links (`/now`, `/progress`, `/tantrum`, `/today`, `/learn`, `/sos`, etc.) continue to land on the right v2 screens.
4. **Help Now.** In v2, `/now` and `/help-now` already redirect to `/plan`. Plan (cards, debrief, regulate) is the v2 home for “help now” flows. If you want the legacy Help Now screen still reachable, add a route (e.g. `/plan/help-now` → `HelpNowScreen`) in Phase 2; otherwise treat it as superseded by Plan.

---

## Phase 1 — Default to v2 (low risk, reversible)

**Goal:** New app loads and existing users who have never set rollout state get v2 by default. No removal of v1 code.

### 1.1 Change default rollout state to v2

- **File:** `lib/providers/release_rollout_provider.dart`
- In `ReleaseRolloutState.initial` (or the static default used when Hive is empty), set:
  - `v2NavigationEnabled: true`
  - `v2OnboardingEnabled: true`
  - `pocketEnabled: true`
  - `regulateEnabled: true`
- Ensure the **Hive read** path uses the same defaults when `state` is missing or when keys are absent (so existing users with no `release_rollout_v1` state get v2 after an update).

### 1.2 One-time migration for existing Hive state

- When loading from Hive, if the stored map has **no** `v2_navigation_enabled` key (or schema &lt; 3), treat as “legacy” and **optionally** set v2 flags to `true` and persist. That way existing users who never opened Release Ops also migrate to v2.
- If you prefer not to touch existing users’ state, skip this and rely only on 1.1 for “empty box” and new installs; then only new installs and users who clear app data get v2 until you do a broader migration.

### 1.3 Keep Release Ops as opt-out

- Leave the Release Ops Checklist (and Hive) as the way to **turn v2 off** for internal testing or rollback. So: default = v2, but `v2_navigation_enabled: false` in Hive still forces v1.

### 1.4 Verification

- New install (or clear Hive `release_rollout_v1`): app should show Plan tab and v2 shell after splash.
- Set `v2_navigation_enabled: false` in Hive, restart: app should show Help Now tab (v1).
- Run `V2_TIER1_SMOKE_CHECKLIST.md` with default (v2) and optionally with v1 opt-out.

**Exit criteria:** Default experience is v2; v1 still works when explicitly set; no removal of code.

---

## Phase 2 — Treat v2 as primary (redirects + docs)

**Goal:** All entry points and docs assume v2. v1 remains in code for rollback only.

### 2.1 Splash and root redirects

- **File:** `lib/screens/splash.dart`
- Ensure when rollout is loaded and profile exists, v2 path goes to `/plan` (already the case when `v2NavigationEnabled`). No change needed if Phase 1 defaults are correct.

### 2.2 Compatibility redirects (v2)

- **File:** `lib/router.dart`
- Keep `_compatibilityRoutes` for v2 so that:
  - `/now`, `/help-now`, `/relief` → `/plan`
  - `/progress`, `/progress/logs`, `/progress/learn` → `/library` or `/library/logs`, `/library/learn`
  - `/tantrum`, `/tantrum/capture`, etc. → `/plan`
  - `/today`, `/learn` → `/library/logs`, `/library/learn`
  - `/sos`, `/breathe` → `/plan/regulate` when `regulateEnabled`
- These are already in place; just confirm they stay when v2 is the only path later.

### 2.3 (Optional) Expose legacy Help Now in v2

- If product wants the old Help Now screen still reachable from v2 (e.g. “Crisis now” from Plan):
  - Add a route under the Plan branch, e.g. `path: 'help-now'` → `HelpNowScreen`, or a top-level `/help-now` that pushes Help Now when v2.
  - Add a small entry point from Plan (e.g. card or link) that navigates there. Otherwise, consider Help Now deprecated in favor of Plan + Regulate.

### 2.4 Documentation

- Update `README.md` or onboarding docs to describe the app as Plan / Family / Sleep / Library (v2).
- In `V2_ENABLE_LOCALLY.md`, add a short note: “v2 is now the default; use Release Ops or Hive to opt back to v1 if needed.”
- Optionally add a “V2 migration” section to `V2_AUDIT_REPORT.md` or `V2_FIX_ALL_PLAN.md` pointing to this plan.

**Exit criteria:** Docs and behavior assume v2; v1 still available via flag for rollback.

---

## Phase 3 — Remove v1 shell (v2-only codebase)

**Goal:** Only the v2 shell exists. No `v2NavigationEnabled` branch for v1; less code and no confusion.

### 3.1 Router: always build v2 shell

- **File:** `lib/router.dart`
- Remove `_buildV1ShellRoute()` and all v1-only branches.
- Build a single shell: always use `_buildV2ShellRoute(regulateEnabled: regulateEnabled)` (or a wrapper that reads `regulateEnabled` from the same place as today).
- Root redirects: always `/home` → `/plan`, `/` (after splash) → `/plan` when profile exists.
- Compatibility routes: keep only the v2 redirect list (no `if (!v2NavigationEnabled)` branch).
- Remove `v2NavigationEnabled` from the router API if it’s only used to choose v1 vs v2; keep reading `regulateEnabled` (and optionally `pocketEnabled`) from rollout for overlay and /sos behavior.

### 3.2 Release rollout state and provider

- **File:** `lib/providers/release_rollout_provider.dart`
- Option A: Remove `v2NavigationEnabled` and `v2OnboardingEnabled` from state and Hive; delete any “set v2” / “flip to v1” logic. Onboarding always uses v2 flow; shell is always v2.
- Option B: Keep the keys in Hive for a while but ignore them in the router (always v2). Then remove in a later cleanup.

### 3.3 Release Ops UI

- **File:** `lib/screens/release_ops_checklist.dart`
- Remove toggles for “v2 navigation” and “v2 onboarding” (or hide them). Keep toggles that still matter (e.g. Pocket, Regulate) if you want to turn those off without code changes.

### 3.4 Screens and references

- **Help Now:** If you did not add `/plan/help-now` (or similar), remove or repurpose `HelpNowScreen` only if product agrees it’s deprecated. Otherwise keep it behind the optional route added in 2.3.
- **Home / Today / Learn / Progress:** These are already redirected in v2; remove any v1-only references (e.g. `releaseRolloutProvider.v2NavigationEnabled` checks that only hide v2 or show v1). Replace with “always v2” behavior.
- **Splash:** Simplify to always go to `/plan` when profile exists (or keep one redirect based on onboarded vs not); remove v1-specific branch.

### 3.5 Tests and cleanup

- Update tests that assume v1 (e.g. expect Help Now tab, `/now` as home). Point them at `/plan` and v2 shell.
- Run full test suite and fix failures.
- Remove dead code: `_v1NavItems`, v1 tab indices, any helpers only used by v1 shell.

**Exit criteria:** One shell (v2 only), no v1 routes, no `v2NavigationEnabled` in router logic; app runs and tests pass.

---

## Phase 4 — Optional cleanup and polish

- **Hive:** If you removed v2 flags from schema, bump schema version and document in release notes.
- **Deep links:** Confirm all documented deep links (e.g. `/library/insights`, `/family/invite`, `/plan/regulate`) work and that old v1 links still redirect correctly.
- **Analytics:** If you track “v1 vs v2” or “shell version”, switch to “v2 only” or remove the dimension.

---

## Execution order and risk

| Phase | Action | Risk | Reversible |
|-------|--------|------|------------|
| **1** | Default to v2 in state + Hive read; optional one-time migration | Low | Yes (revert defaults / clear Hive) |
| **2** | Docs + optional Help Now route | Low | Yes |
| **3** | Remove v1 shell and flag from router + provider | Medium | Only via code revert |
| **4** | Cleanup and analytics | Low | Yes |

Recommendation: ship **Phase 1** first, monitor for a release or two, then do **Phase 2** and **Phase 3** when confident. Phase 4 can follow at any time.

---

## File checklist (Phase 1)

- [x] `lib/providers/release_rollout_provider.dart` — default `v2NavigationEnabled`, `v2OnboardingEnabled`, `pocketEnabled`, `regulateEnabled` (and plan/family/library tab) to `true` in `ReleaseRolloutState.initial` and in Hive read when keys are missing.
- [x] `lib/router.dart` — default `v2NavigationEnabled`, `v2OnboardingEnabled`, `regulateEnabled` to `true` in `_buildRouterFromRolloutState()` when box is empty or keys are missing.
- [ ] Manual test: fresh install or cleared Hive → v2 shell; set `v2_navigation_enabled: false` in Release Ops → v1 shell after restart.
- [ ] Run `V2_TIER1_SMOKE_CHECKLIST.md` with default v2.
