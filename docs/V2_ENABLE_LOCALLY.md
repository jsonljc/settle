# How to enable v2 locally

**v2 is now the default.** New installs and users who haven’t set rollout state see the v2 shell (Plan, Family, Sleep, Library), Pocket overlay, and regulate flow. Use the steps below to **opt back to v1** (e.g. for testing) or to confirm v2 is on.

---

## Option 1: Release Ops Checklist (in-app)

1. Run the app and sign in or complete onboarding so you have a profile.
2. Open **Settings** (gear in the shell).
3. Scroll to the **Release** section and tap **Release Ops Checklist** (or **Release compliance** / **Release metrics** if your build exposes them).
4. Turn on:
   - **v2 navigation**
   - **Pocket** (for the FAB and overlay)
   - **Regulate** (so /plan/regulate and /sos use the full 5-step flow)
5. Restart the app (cold start). The router is built from Hive at startup, so toggles take effect after restart.

---

## Option 2: Hive box (dev/debug)

The router and `releaseRolloutProvider` read from the Hive box **`release_rollout_v1`**, key **`state`**, which must be a map. Schema version **3** uses these keys (all optional; defaults apply if missing):

| Key | Type | Effect when `true` |
|-----|------|---------------------|
| `v2_navigation_enabled` | bool | v2 shell (Plan, Family, Sleep, Library); splash → /plan when profile exists |
| `v2_onboarding_enabled` | bool | /onboard shows OnboardingV2Screen |
| `pocket_enabled` | bool | Pocket FAB + overlay in v2 shell |
| `regulate_enabled` | bool | /sos and /breathe → /plan/regulate (full flow); when false, /sos → /breathe |

**Minimal v2 setup (e.g. in a debug screen or test):**

```dart
final box = await Hive.openBox<dynamic>('release_rollout_v1');
await box.put('state', {
  'schema_version': 3,
  'v2_navigation_enabled': true,
  'pocket_enabled': true,
  'regulate_enabled': true,
});
// Then restart the app or call refreshRouterFromRollout() and navigate.
```

After writing the box, **restart the app** so `buildRouterFromRolloutState()` runs with the new values. Alternatively, if you have a way to call `refreshRouterFromRollout()` and rebuild the root (e.g. via a dev menu), you can avoid a full restart.

---

## Verifying

- **Splash** → lands on **Plan** (not Help Now).
- **Bottom nav** shows Plan, Family, Sleep, Library.
- **Pocket** FAB appears if `pocket_enabled` is true.
- **Settings → Plan nudges** section is visible in v2.

See **`docs/V2_TIER1_SMOKE_CHECKLIST.md`** for a full manual checklist.
