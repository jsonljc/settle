# Migrate to v2 — Migration Plan

**Goal:** Make v2 the only experience; remove v1 shell code.

---

## Status

- **Phase 1 (default to v2):** Done. v2 is the default for new installs and existing users.
- **Phase 2 (treat v2 as primary):** Done. Docs and redirects assume v2.
- **Phase 3 (remove v1 shell):** Not started. This is the remaining work.
- **Phase 4 (cleanup):** Not started.

---

## Principles

1. **Deep links and bookmarks.** Keep compatibility redirects so old links (`/now`, `/progress`, `/tantrum`, `/today`, `/learn`, `/sos`, etc.) land on the right v2 screens.
2. **Help Now.** `/now` and `/help-now` redirect to `/plan`. Plan (cards, debrief, regulate) is the v2 replacement.

---

## Phase 3 — Remove v1 shell (v2-only codebase)

**Goal:** Only the v2 shell exists. No `v2NavigationEnabled` branch; less code, no confusion.

### 3.1 Router: always build v2 shell

- **File:** `lib/router.dart`
- Remove `_buildV1ShellRoute()` and all v1-only branches.
- Build a single shell: always use `_buildV2ShellRoute(regulateEnabled: regulateEnabled)`.
- Root redirects: always `/home` → `/plan`, `/` (after splash) → `/plan` when profile exists.
- Compatibility routes: keep only the v2 redirect list (no `if (!v2NavigationEnabled)` branch).
- Remove `v2NavigationEnabled` from the router API; keep reading `regulateEnabled` and `pocketEnabled` from rollout.

### 3.2 Release rollout state and provider

- **File:** `lib/providers/release_rollout_provider.dart`
- Remove `v2NavigationEnabled` and `v2OnboardingEnabled` from state and Hive. Onboarding always uses v2 flow; shell is always v2.

### 3.3 Release Ops UI

- **File:** `lib/screens/release_ops_checklist.dart`
- Remove toggles for "v2 navigation" and "v2 onboarding". Keep toggles for Pocket and Regulate.

### 3.4 Screens and references

- **Help Now:** Remove or repurpose `HelpNowScreen` (superseded by Plan + Regulate).
- **Home / Today / Learn / Progress:** Already redirected; remove v1-only references and `v2NavigationEnabled` checks.
- **Splash:** Simplify to always go to `/plan` when profile exists; remove v1-specific branch.

### 3.5 Tests and cleanup

- Update tests that assume v1 (e.g. expect Help Now tab, `/now` as home). Point at `/plan` and v2 shell.
- Run full test suite and fix failures.
- Remove dead code: `_v1NavItems`, v1 tab indices, v1-only helpers.

**Exit criteria:** One shell (v2 only), no v1 routes, no `v2NavigationEnabled` in router logic; app runs and tests pass.

---

## Phase 4 — Optional cleanup

- **Hive:** Bump schema version if v2 flags are removed.
- **Deep links:** Confirm all documented deep links work and old v1 links redirect correctly.

---

## Dev reference: toggling v2/v1 locally

**v2 is now the default.** Use the steps below to opt back to v1 for testing.

### Option 1: Release Ops Checklist (in-app)

1. Complete onboarding so you have a profile.
2. Open **Settings** → **Release** section → **Release Ops Checklist**.
3. Toggle **v2 navigation**, **Pocket**, **Regulate** on or off.
4. Restart the app (cold start). The router reads from Hive at startup.

### Option 2: Hive box (dev/debug)

The router reads from Hive box **`release_rollout_v1`**, key **`state`** (a map). Schema version **3** keys:

| Key | Type | Effect when `true` |
|-----|------|---------------------|
| `v2_navigation_enabled` | bool | v2 shell; splash → /plan when profile exists |
| `v2_onboarding_enabled` | bool | /onboard shows OnboardingV2Screen |
| `pocket_enabled` | bool | Pocket FAB + overlay in v2 shell |
| `regulate_enabled` | bool | /sos and /breathe → /plan/regulate |

```dart
final box = await Hive.openBox<dynamic>('release_rollout_v1');
await box.put('state', {
  'schema_version': 3,
  'v2_navigation_enabled': true,
  'pocket_enabled': true,
  'regulate_enabled': true,
});
// Then restart the app or call refreshRouterFromRollout().
```

### Verifying

- **Splash** → lands on **Plan** (not Help Now).
- **Bottom nav** shows Now, Sleep, Library.
- **Pocket** FAB appears if `pocket_enabled` is true.
- **Settings → Plan nudges** section is visible.

See [V2_TIER1_SMOKE_CHECKLIST.md](V2_TIER1_SMOKE_CHECKLIST.md) for the full manual checklist.
