# V2 Tier 1 — Manual smoke test checklist

Use this when you run the app with v2 enabled to confirm everything shows up and routes correctly.

**Before you start:** Enable v2 (Release Ops Checklist → enable v2 navigation, pocket, regulate; or set Hive `release_rollout_v1` box key `state` with `v2_navigation_enabled: true`, `pocket_enabled: true`, `regulate_enabled: true`). Restart the app.

---

## 1. Splash and home

- [ ] Cold start → Splash → then **Plan** tab (not Help Now).
- [ ] No unexpected redirect or 404.

---

## 2. Plan tab

- [ ] **Plan** tab shows: header “Plan”, Debrief section (“What’s been hardest?”), Prep section, optional “Regulate first” banner if profile is stressed/anxious/angry.
- [ ] Tap **Regulate first** (or open regulate from elsewhere) → **Regulate flow** (5 steps: Acknowledge → Breathe → Reframe → Action → Repair). Complete or back → returns to Plan.
- [ ] Tap a **trigger pill** in Debrief → card loads; **Log** → **Logs** screen (TodayScreen). Back → Plan.
- [ ] If **Weekly reflection** banner is shown (Sunday evening): dismiss or tap “Open logs” → Logs. No crash.

---

## 3. Pocket (if `pocket_enabled`)

- [ ] **Pocket FAB** visible bottom-right (above nav). Tap → modal with top pinned script.
- [ ] **This helped** → short **celebration** then overlay closes.
- [ ] **Didn’t work** → **after-log** (outcome, optional context, “I used the breathing reset”) → Submit → overlay closes.
- [ ] **I need to regulate first** → inline breathe → **Back to script** → back to script view.

---

## 4. Library tab

- [ ] **Library** tab shows: Your patterns (preview), Saved playbook (preview), Learn, Logs, **Monthly insight** card.
- [ ] **Open logs** → Logs screen. Back → Library.
- [ ] **Open learn** → Learn screen. “Open Plan Focus” → Plan; “Open Logs” → Logs. No wrong screen.
- [ ] **Open monthly insight** → **Monthly insight** screen (scripts used, “worked great”, regulation resets, By situation). Back → Library.
- [ ] **Open patterns** → Patterns screen. Back → Library.
- [ ] **Open saved playbook** → Saved playbook. Tap a card → card detail. Back → Library.
- [ ] If **Weekly reflection** banner is shown here (Sunday evening): tap “Open logs” → Logs. No crash.

---

## 5. Family tab

- [ ] **Family** tab shows: layout by family type, Shared playbook, Invite, Activity (preview).
- [ ] **Invite** → Invite screen (copy link / deep link). Back → Family.
- [ ] **Activity** → Activity feed (recent script use). Back → Family.
- [ ] **Shared playbook** → Family rules / shared. Back → Family.

---

## 6. Sleep tab

- [ ] **Sleep** tab: if `sleepProfileComplete` false → mini-onboarding gate/screen; else Sleep hub (Tonight, Rhythm, etc.). No crash.

---

## 7. Settings and redirects

- [ ] **Settings** (from shell or elsewhere) → **Plan nudges** section: toggles (Predictable, Pattern, Content), quiet hours, frequency (Minimal / Smart / More). Change something → no crash; nudges reschedule.
- [ ] With v2 on: open **/now** (e.g. from dev tools or link) → redirects to **Plan**.
- [ ] **/progress** → redirects to **Library**.
- [ ] **/tantrum** or **/tantrum/capture** → redirects to **Plan**.
- [ ] **/sos** → if `regulate_enabled`: **Regulate flow**; else **Breathe** (SOS) screen.
- [ ] **/library/insights**, **/family/invite**, **/plan/regulate** (direct) → correct tab and screen.

---

## 8. Logs and Learn (cross-links)

- [ ] From **Logs**: “Open Plan Focus” → **Plan**; “Open Learn Q&A” → **Learn**. Correct screens.
- [ ] From **Learn**: “Open Plan Focus” → **Plan**; “Open Logs” → **Logs**. Correct screens.

---

**If something fails:** note the step (e.g. “4. Open monthly insight → 404”) and fix route or link (see `lib/router.dart` and the screen’s `context.push` / `context.go`). V2 routing is covered by `test/router_v2_shell_hardening_test.dart`.
