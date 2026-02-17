# V2 Fix-All Plan

**Purpose:** Prioritized approach to finish and harden v2 so everything shows up correctly and behaves as intended.

**Reference:** `docs/V2_AUDIT_REPORT.md` (all phases marked complete); `PLAN.md`.

---

## Current status (already done)

- **Phases 0–8:** Implemented per audit (regulate flow, Pocket, Family, pattern engine, nudge scheduler, retention).
- **Routing:** v2 shell, compatibility redirects, Logs/Learn links fixed for v2 paths; tests in `router_v2_shell_hardening_test.dart` pass.
- **Blockers:** Splash→/plan when v2, /sos→/breathe when !regulateEnabled, regulate flow, Pocket, pattern engine — all resolved.

---

## Best approach: three tiers

### Tier 1 — Verify & harden (do first)

Goal: Confirm everything shows up and routes correctly in the app; fix any remaining routing/visibility bugs.

| # | Task | Effort | Notes |
|---|------|--------|--------|
| 1.1 | **Manual v2 smoke test** | ~30 min | Enable v2 + pocket + regulate in Release Ops (or Hive). Walk: Splash→Plan, Regulate First→regulate flow, Debrief→card→Log, Pocket FAB→This helped→celebration, Library→Logs/Learn/Insights/Patterns/Saved, Family→Invite/Activity, Settings→Plan nudges. Confirm no 404s or wrong screens. |
| 1.2 | **Deep-link and redirect checks** | ~15 min | Open `/library/insights`, `/family/invite`, `/plan/regulate` from external link or dev tools; confirm correct tab and screen. Test `/now`, `/progress`, `/tantrum`, `/sos` redirects when v2 is on. |
| 1.3 | **Fix any issues found** | 1–2 hrs | Log any wrong route, missing screen, or bad state; fix in router or screen (same pattern as Logs/Learn path fixes). |

**Outcome:** High confidence that all v2 surfaces and routes work in the real app.

**Checklist:** Use **`docs/V2_TIER1_SMOKE_CHECKLIST.md`** when you run the app with v2 enabled; tick each item as you verify.

---

### Tier 2 — Optional product/UX polish ✅ DONE

Goal: Small improvements that make v2 feel complete; no new features.

| # | Task | Status | Notes |
|---|------|--------|--------|
| 2.1 | **Use NudgeFrequency in scheduler** | ✅ | Candidates in next 7 days; minimal=1, smart=3, more=7. |
| 2.2 | **Weekly reflection dismiss persistence** | ✅ | Optionally persist “dismissed this week” in Hive or a provider so the Sunday banner doesn’t reappear after dismiss until next week. Currently Plan dismiss hides for session only. |
| 2.3 | **Share flow placeholder** | ~15 min | Plan OutputCard “Share” still shows “Share flow coming in Phase 6”. Either wire to a minimal share (e.g. copy script text) or set copy to “Share coming soon” so it’s clearly placeholder. |

**Outcome:** Nudges respect frequency; reflection and share UX are clearer.

---

### Tier 3 — Quality and maintainability ✅ DONE

Goal: Easier to regress and safer to change.

| # | Task | Status | Notes |
|---|------|--------|--------|
| 3.1 | **Add routing tests** | ✅ | e.g. `/plan/log` shows TodayScreen; from Logs, “Open Plan Focus” navigates to `/plan` when v2; compatibility routes for `/today`, `/learn` land on `/library/logs`, `/library/learn`. |
| 3.2 | **Document how to enable v2 locally** | ✅ | See **docs/V2_ENABLE_LOCALLY.md** |
| 3.3 | **Run full test suite** | ✅ | Settings frequency Row→Wrap fix; v2 router tests pass; other failures pre-existing |

**Outcome:** Fewer regressions, clearer onboarding for devs.

---

## Suggested order

1. **Tier 1** (verify & harden) — Do first so “fix all” means “everything works in the app.”
2. **Tier 2** (polish) — Pick 2.1 and/or 2.2 if you want product completeness; 2.3 is trivial.
3. **Tier 3** (quality) — Do when you have a short window; 3.2 is high value for little effort.

---

## What “fix all” does not include (by default)

- New features beyond the audit (e.g. real share, real family sync).
- v1 parity or v1→v2 migration beyond existing tantrum-deck migration.
- Backend or analytics changes unless you add them to Tier 2/3.

If you want, we can turn Tier 1 into a short checklist and you can tick items as you run through the app, then we fix only what you find.
