# V2 — Manual Smoke Test & Crisis Validation

Use this when you run the app to confirm everything shows up, routes correctly, and crisis flows hit the 20-second guardrail.

**Before you start:** v2 is the default. To opt back to v1 for testing, set `v2_navigation_enabled: false` in Release Ops or Hive and restart. See [V2_MIGRATION_PLAN.md](V2_MIGRATION_PLAN.md) for details.

---

## 1. Splash and home

- [ ] Cold start → Splash → then **Now** tab (not Help Now).
- [ ] No unexpected redirect or 404.

---

## 2. Now tab

- [ ] **Now** tab shows: header, crisis tiles, optional "Regulate first" banner if profile is stressed/anxious/angry.
- [ ] Tap **Regulate first** (or open regulate from elsewhere) → **Regulate flow** (5 steps: Acknowledge → Breathe → Reframe → Action → Repair). Complete or back → returns to Now.
- [ ] Tap a **trigger pill** in Debrief → card loads; **Log** → **Logs** screen. Back → Now.
- [ ] If **Weekly reflection** banner is shown (Sunday evening): dismiss or tap "Open logs" → Logs. No crash.

---

## 3. Pocket (if `pocket_enabled`)

- [ ] **Pocket FAB** visible bottom-right (above nav). Tap → modal with top pinned script.
- [ ] **This helped** → short **celebration** then overlay closes.
- [ ] **Didn't work** → **after-log** (outcome, optional context, "I used the breathing reset") → Submit → overlay closes.
- [ ] **I need to regulate first** → inline breathe → **Back to script** → back to script view.

---

## 4. Library tab

- [ ] **Library** tab shows: Your patterns (preview), Saved playbook (preview), Learn, Logs, **Monthly insight** card.
- [ ] **Open logs** → Logs screen. Back → Library.
- [ ] **Open learn** → Learn screen. "Open Plan Focus" → Now; "Open Logs" → Logs. No wrong screen.
- [ ] **Open monthly insight** → **Monthly insight** screen (scripts used, "worked great", regulation resets, By situation). Back → Library.
- [ ] **Open patterns** → Patterns screen. Back → Library.
- [ ] **Open saved playbook** → Saved playbook. Tap a card → card detail. Back → Library.
- [ ] If **Weekly reflection** banner is shown here (Sunday evening): tap "Open logs" → Logs. No crash.

---

## 5. Family overlay

- [ ] **Family** shows: layout by family type, Shared playbook, Invite, Activity (preview).
- [ ] **Invite** → Invite screen (copy link / deep link). Back → Family.
- [ ] **Activity** → Activity feed (recent script use). Back → Family.
- [ ] **Shared playbook** → Family rules / shared. Back → Family.

---

## 6. Sleep tab

- [ ] **Sleep** tab: if `sleepProfileComplete` false → mini-onboarding gate/screen; else Sleep hub (Tonight, Rhythm, etc.). No crash.

---

## 7. Settings and redirects

- [ ] **Settings** (from shell or elsewhere) → **Plan nudges** section: toggles (Predictable, Pattern, Content), quiet hours, frequency (Minimal / Smart / More). Change something → no crash; nudges reschedule.
- [ ] With v2 on: open **/now** (e.g. from dev tools or link) → redirects to **Now/Plan**.
- [ ] **/progress** → redirects to **Library**.
- [ ] **/tantrum** or **/tantrum/capture** → redirects to **Now/Plan**.
- [ ] **/sos** → if `regulate_enabled`: **Regulate flow**; else **Breathe** (SOS) screen.
- [ ] **/library/insights**, **/family/invite**, **/plan/regulate** (direct) → correct tab and screen.

---

## 8. Logs and Learn (cross-links)

- [ ] From **Logs**: "Open Plan Focus" → **Now**; "Open Learn Q&A" → **Learn**. Correct screens.
- [ ] From **Learn**: "Open Plan Focus" → **Now**; "Open Logs" → **Logs**. Correct screens.

---

## 9. 20-Second Crisis Path Validation

**Guardrail (AGENTS.md):** First actionable guidance visible in ≤20 seconds on all crisis flows.

Use a stopwatch. Start when you **tap the entry point**; stop when **first actionable content** is visible.

| Flow | Entry point | Stop when |
|------|-------------|-----------|
| **Now → Sleep Tonight** | Tap "Night wake right now" (or other Sleep tile) | First guidance step text visible (e.g. "Do now: ...") |
| **Now → Reset (tantrum)** | Tap "Tantrum happening now" | State pick or first card visible |
| **Now → Moment** | Tap "I need to regulate" | Two script tiles (Boundary / Connection) visible |
| **Sleep tab → Tonight** | Tap "Sleep tonight guidance" | Scenario pick or first guidance step visible |
| **Sleep Tonight (direct)** | Open `/sleep/tonight` (deep link) | First guidance step visible |
| **Reset (direct)** | Open `/plan/reset` or `/plan/reset?context=tantrum` | State pick or first card visible |

**Target:** Every path ≤20 seconds. Sleep Tonight emits `ST_FIRST_GUIDANCE_RENDERED` with `time_to_first_guidance_ms` for automated checks.

### Log / sign-off

| Date | Tester | Now→Sleep | Now→Reset | Now→Moment | Sleep→Tonight | Reset direct | Notes |
|------|--------|-----------|-----------|------------|----------------|--------------|-------|
| _YYYY-MM-DD_ | _name_ | _s_ | _s_ | _s_ | _s_ | _s_ | _optional_ |

---

**If something fails:** note the step (e.g. "4. Open monthly insight → 404") and fix route or link (see `lib/router.dart` and the screen's `context.push` / `context.go`). V2 routing is covered by `test/router_v2_shell_hardening_test.dart`.
