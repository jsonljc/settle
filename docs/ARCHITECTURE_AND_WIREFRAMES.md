# Settle — Architecture Summary & Wireframe-by-Wireframe

**No-code overview:** app structure, data flow, and every screen as a wireframe description.

---

## Part 1 — Entire Architecture

### High-level flow

1. **Entry:** App starts → **Splash** → if no profile → **Onboarding**; if profile exists → **App shell** (main tabs).
2. **Shell:** Single bottom navigation with four tabs: **Home (Plan)**, **Family**, **Sleep**, **Library**. Each tab has its own stack; settings and some flows live outside the shell.
3. **Data:** Profile and app state in **Hive** (local). **Riverpod** providers expose that state and business logic. No backend in this doc.
4. **Feature control:** **Release rollout** (Hive box `release_rollout_v1`) drives flags (e.g. regulate, pocket, family rules). Router is rebuilt when rollout state changes.

### Core layers

| Layer | Role |
|-------|------|
| **Router** | GoRouter; splash → onboard or shell; shell = 4 branches (Plan, Family, Sleep, Library); compatibility redirects for old paths. |
| **App shell** | Bottom nav (Home, Family, Sleep, Library) + optional Pocket FAB overlay; each branch keeps its own stack. |
| **Models** | Baby/profile, approach, cards, usage/regulation events, patterns, family members, etc.; many with Hive adapters. |
| **Providers** | Profile, user cards, usage events, regulation events, patterns, nudges, family members, rhythm, sleep tonight, rollout, etc. |
| **Services** | Card content, pattern engine, nudge scheduler, notifications, rhythm/sleep guidance, event bus, family rules, spec policy, etc. |
| **Theme** | Settle tokens, glass components, surface mode (day/night), reduce motion. |

### Navigation shape

- **Root:** `/` (Splash) → `/onboard` or `/plan`.
- **Plan tab:** `/plan` (home), `/plan/regulate`, `/plan/card/:id`, `/plan/log`.
- **Family tab:** `/family`, `/family/shared`, `/family/invite`, `/family/activity`.
- **Sleep tab:** `/sleep` (gate), `/sleep/tonight`, `/sleep/rhythm`, `/sleep/update`.
- **Library tab:** `/library`, `/library/learn`, `/library/logs`, `/library/saved`, `/library/patterns`, `/library/insights`, `/library/cards/:id`.
- **Global:** `/settings`; `/breathe` (legacy SOS) redirects to `/plan/regulate` when regulate is enabled; `/rules` → `/family/shared`.
- **Internal-only (gated):** `/release-metrics`, `/release-compliance`, `/release-ops`.

### Data and feature flags

- **Hive boxes:** user_cards, usage_events, regulation_events, patterns, nudges, family_members, profile-related, release_rollout_v1, etc.
- **Rollout flags (examples):** regulate enabled, pocket enabled, family rules enabled, smart nudges, pattern detection, etc. They control which screens/features are shown and which routes exist.

---

## Part 2 — Wireframe by Wireframe

Each section below is one screen (or one major modal/flow). Layout and intent only; no code.

---

### 1. Splash

- **Route:** `/`
- **Purpose:** First screen on launch; short branding then redirect.
- **Wireframe:**
  - Full-screen background (gradient).
  - Centered: moon icon, app name “Settle”, short tagline.
  - No buttons; after a short minimum and once profile load is ready:
    - No profile → go to Onboarding.
    - Profile exists → go to Plan tab (`/plan`).

---

### 2. Onboarding (v2) — Container

- **Route:** `/onboard`
- **Purpose:** New-user flow; collects child + family + challenge + one script + regulation + optional invite + pricing; saves profile and lands in app.
- **Wireframe:**
  - Single scrollable/stepped container.
  - One step visible at a time; “Next” / “Back” to move.
  - Progress implied by step order (no code).

---

### 2a. Onboarding — Step: Child name + age

- **Purpose:** Who is this for?
- **Wireframe:**
  - Title/subtitle about setting up for your child.
  - Child name text field (optional; fallback “your child”).
  - Age control: slider or picker, 12 months–5 years (stored as age in months).
  - Next.

---

### 2b. Onboarding — Step: Parent type

- **Purpose:** Family structure for personalization and partner invite.
- **Wireframe:**
  - Title about who’s at home.
  - Options: single parent, two parents, co-parent, blended, with support, etc. (from FamilyStructure).
  - One selected; Next.

---

### 2c. Onboarding — Step: Hardest challenge

- **Purpose:** Primary trigger type for scripts.
- **Wireframe:**
  - Title like “What’s been hardest?”
  - Six trigger pills/cards: e.g. transitions, bedtime battles, public meltdowns, “no” to everything, sibling conflict, overwhelmed.
  - One selected; Next.

---

### 2d. Onboarding — Step: Instant value (one script)

- **Purpose:** Give one script and option to save to playbook.
- **Wireframe:**
  - Title about getting one script now.
  - One card shown (Prevent / Say / Do, maybe “if it escalates”) based on selected challenge.
  - “Save to playbook” (optional).
  - Next.

---

### 2e. Onboarding — Step: Regulation check

- **Purpose:** How the parent is doing (calm vs stressed/anxious/angry).
- **Wireframe:**
  - Title about how you’re feeling.
  - Options for regulation level (e.g. calm, stressed, anxious, angry).
  - One selected; Next.

---

### 2f. Onboarding — Step: Partner invite (conditional)

- **Purpose:** Invite partner; only for certain family structures.
- **Wireframe:**
  - Title about inviting partner/caregiver.
  - Short copy + CTA to copy invite link or send invite.
  - Next (or skip if not shown).

---

### 2g. Onboarding — Step: Pricing

- **Purpose:** Product/price teaser; UI only.
- **Wireframe:**
  - Title about plans or value.
  - Pricing or “coming soon” content.
  - Primary CTA: “Finish” or “Get started” → save profile, go to `/plan`.

---

### 3. App shell (main tabs)

- **Routes:** All tab roots under shell.
- **Purpose:** Persistent chrome for the app.
- **Wireframe:**
  - Top: status bar (transparent).
  - Main area: current tab’s stack (full width/height).
  - Bottom: bottom nav bar with four items — Home, Family, Sleep, Library; one highlighted.
  - Optional: settings icon (e.g. top-right) → `/settings`.
  - If Pocket enabled: floating action button (e.g. bottom-right above nav) opening Pocket overlay.

---

### 4. Plan home

- **Route:** `/plan`
- **Purpose:** Daily “plan” hub: regulate-first nudge, debrief, prep nudge, and script cards.
- **Wireframe:**
  - Header: “Home” (or “Plan”), short subtitle; settings affordance.
  - **Regulate First (conditional):** If profile says stressed/anxious/angry, a prominent card/banner: “Regulate first” + CTA → `/plan/regulate`.
  - **Debrief:** “What’s been hardest?” + row of 6 trigger pills; tapping one can lead to a script (card) for that trigger.
  - **Prep nudge (conditional):** “Based on your patterns” or time-based nudge card; can open a script or action.
  - **Script cards:** After selecting a trigger, one or more script cards (Prevent / Say / Do, “if it escalates”); each with Save, Share, Log, “Why this works.”
  - Cards can deep-link to `/plan/card/:id` or open script log `/plan/log`.

---

### 5. Regulate flow (5 steps)

- **Route:** `/plan/regulate`
- **Purpose:** Parent self-regulation: acknowledge → breathe → reframe (optional) → action → repair (optional); logs RegulationEvent on finish.
- **Wireframe:**
  - **Step 1 — Acknowledge:** Short prompt to name how you feel or that it’s hard; “Next.”
  - **Step 2 — Breathe:** Breathing visual (e.g. circle or timer); user follows; “Done” or auto-advance.
  - **Step 3 — Reframe (optional):** Reframe thought; skip if trigger is “need a minute.”
  - **Step 4 — Action:** Choose a small next action; “Next.”
  - **Step 5 — Repair (optional):** Shown if user indicated “already yelled”; repair with child; “Done.”
  - On Done: save event, then pop or go to `/plan`.

---

### 6. Plan card (script detail)

- **Route:** `/plan/card/:id` (or `/library/cards/:id` with library fallback)
- **Purpose:** Full view of one script card.
- **Wireframe:**
  - Back to Plan (or Library).
  - Card content: Prevent, Say, Do, “If it escalates,” evidence (“Why this works”).
  - Actions: Save to playbook, Share, Copy script, Log use (outcome).
  - If from Plan, back goes to `/plan`; if from Library, back goes to `/library`.

---

### 7. Plan script log

- **Route:** `/plan/log` (e.g. with `?card_id=…`)
- **Purpose:** Log or view usage of a script (plan context).
- **Wireframe:**
  - Header: “Log” or “Script log.”
  - Context for which card (if card_id present).
  - Form or list to log outcome (e.g. helped / didn’t work) and optional notes.
  - May show recent logs for that card.

---

### 8. Family home

- **Route:** `/family`
- **Purpose:** Family alignment: members and shared playbook.
- **Wireframe:**
  - Header: “Family,” subtitle about staying aligned.
  - **If partner layout:** List of members (e.g. primary, partner) with roles/avatars; optional invite CTA.
  - **If single parent:** “Your support network” card — invite grandparents/babysitters; CTA.
  - **Shared playbook:** Card “Open shared scripts” → `/family/shared`.
  - Optional: “Activity” or “Invite” entry points → `/family/activity`, `/family/invite`.

---

### 9. Family shared (family rules)

- **Route:** `/family/shared` (or `/rules`)
- **Purpose:** Caregiver agreement and shared scripts (family rules).
- **Wireframe:**
  - Header: “Shared scripts” or “Family rules.”
  - List of rule/script tiles (e.g. public boundary, screens default, snacks, bedtime routine).
  - Each tile: title, short description, expand or open for full script.
  - If feature off: “Feature paused” or unavailable message.

---

### 10. Family invite

- **Route:** `/family/invite`
- **Purpose:** Invite partner/caregiver via link.
- **Wireframe:**
  - Title: “Invite” or “Invite partner.”
  - Short copy about sharing the app.
  - Copy-invite-link button; optional share sheet.
  - Back to Family.

---

### 11. Family activity feed

- **Route:** `/family/activity`
- **Purpose:** See family/caregiver activity (e.g. who used which script or logged what).
- **Wireframe:**
  - Header: “Activity.”
  - List of recent items: e.g. “Partner used ‘Bedtime routine’,” “You logged …”.
  - Chronological; optional filters. Back to Family.

---

### 12. Sleep gate (mini-onboarding)

- **Route:** `/sleep`
- **Purpose:** Gate: no sleep profile → mini onboarding; otherwise → Sleep hub.
- **Wireframe (gate logic only):**
  - If no profile: “Profile required” or redirect.
  - If profile exists but sleep profile not complete: show Sleep mini-onboarding screen.
  - If sleep profile complete: show Sleep hub.

---

### 12a. Sleep mini-onboarding

- **Route:** `/sleep` (when sleep profile not complete)
- **Purpose:** Collect sleep approach and feeding type; set sleep profile complete.
- **Wireframe:**
  - Title about sleep setup.
  - Approach selector (e.g. 5 options: gentle, gradual, etc.).
  - Feeding type (e.g. 4 options).
  - “Save” → set sleepProfileComplete, then go to `/sleep` (hub).

---

### 13. Sleep hub

- **Route:** `/sleep` (when sleep profile complete)
- **Purpose:** Central sleep screen: rhythm summary and “tonight” plan.
- **Wireframe:**
  - Header: “Sleep” or “Sleep hub.”
  - **Rhythm summary:** Wake time, nap(s), bedtime (from schedule); “Update rhythm” → `/sleep/update`.
  - **Tonight:** Summary of tonight’s plan (method, wind-down); CTA “Sleep tonight” or “Tonight” → `/sleep/tonight`.
  - Optional: “Current rhythm” → `/sleep/rhythm`.

---

### 14. Sleep tonight

- **Route:** `/sleep/tonight`
- **Purpose:** Tonight’s plan: steps, wind-down, method-specific guidance.
- **Wireframe:**
  - Header: “Sleep tonight” or “Tonight.”
  - Time or “Tonight” label.
  - Steps or checklist: e.g. wind-down, routine, put-down.
  - Method-specific copy (from approach).
  - Optional: link to rhythm or update rhythm.

---

### 15. Current rhythm

- **Route:** `/sleep/rhythm`
- **Purpose:** View current wake/nap/bed rhythm.
- **Wireframe:**
  - Header: “Current rhythm.”
  - Visual or list: wake, nap blocks, bedtime.
  - Optional: “Update rhythm” → `/sleep/update`. Back to Sleep.

---

### 16. Update rhythm

- **Route:** `/sleep/update`
- **Purpose:** Change wake/nap/bed times or blocks.
- **Wireframe:**
  - Header: “Update rhythm.”
  - Inputs: wake time, nap count/times, bedtime (or duration).
  - Save → persist, then back to Sleep hub or rhythm.

---

### 17. Library home

- **Route:** `/library`
- **Purpose:** Hub for saved scripts, learning, patterns, logs.
- **Wireframe:**
  - Header: “Library,” subtitle about scripts and learning.
  - **Weekly reflection (conditional):** Banner; dismissible.
  - **Monthly insight:** Card preview → `/library/insights`.
  - **Patterns:** Preview “Your patterns” → `/library/patterns`.
  - **Saved playbook:** Preview “Saved scripts” → `/library/saved`.
  - **Learn:** Card “Open learn” → `/library/learn`.
  - **Logs:** Card “Open logs” → `/library/logs`.

---

### 18. Library — Learn

- **Route:** `/library/learn`
- **Purpose:** Evidence-based articles or guidance.
- **Wireframe:**
  - Header: “Learn.”
  - List or grid of topics (e.g. regulation, sleep, boundaries).
  - Tap topic → in-page content or sub-screen. Back to Library.

---

### 19. Library — Logs (Today)

- **Route:** `/library/logs`
- **Purpose:** Day/week logs (e.g. sleep history, plan usage).
- **Wireframe:**
  - Header: “Logs” or “Today.”
  - Tabs or segments: e.g. “Plan” (usage) vs “Learn” or “Sleep” history.
  - List of entries: date, summary, optional details.
  - Empty state if no logs. Back to Library.

---

### 20. Library — Saved playbook

- **Route:** `/library/saved`
- **Purpose:** User’s saved script cards.
- **Wireframe:**
  - Header: “Saved playbook” or “Saved scripts.”
  - List of saved cards (title or trigger type); tap → `/library/cards/:id`.
  - Empty state: “Save scripts from Home to see them here.” Back to Library.

---

### 21. Library — Patterns

- **Route:** `/library/patterns`
- **Purpose:** Detected patterns (e.g. when meltdowns happen, what helps).
- **Wireframe:**
  - Header: “Patterns.”
  - Cards or list: e.g. “Transitions at 5pm,” “Script X helped most.”
  - Optional filters or time range. Back to Library.

---

### 22. Library — Monthly insight

- **Route:** `/library/insights`
- **Purpose:** Monthly summary (e.g. usage, patterns, wins).
- **Wireframe:**
  - Header: “Monthly insight” or “Insights.”
  - Single month or selector; summary text and maybe simple charts.
  - Back to Library.

---

### 23. Library — Card detail

- **Route:** `/library/cards/:id`
- **Purpose:** Same as Plan card but with “Back to Library” behavior.
- **Wireframe:** Same as **Plan card (script detail)**; back goes to `/library`.

---

### 24. Pocket FAB + overlay

- **Context:** Shown when Pocket enabled; overlay on top of shell.
- **Purpose:** Quick access to top pinned script; log outcome or “regulate first.”
- **Wireframe:**
  - **FAB:** Floating button (e.g. bottom-right); tap opens overlay.
  - **Overlay — Script view:** Top pinned script (Prevent/Say/Do); “This helped” / “Didn’t work”; optional “I need to regulate first.”
  - **Overlay — Regulate:** Inline regulate CTA or short flow; then back to script.
  - **Overlay — After log:** If “Didn’t work,” outcome/context form; submit → optional celebration.
  - **Overlay — Celebration:** Short confirmation; close overlay.

---

### 25. Breathe / SOS (legacy)

- **Route:** `/breathe` (or redirect from `/sos` when regulate off)
- **Purpose:** Zero-interaction calming: breathing + affirmations.
- **Wireframe:**
  - Full screen: breathing visual (e.g. concentric circles, 8s cycle).
  - Phases: “Breathe in,” “Hold,” “Breathe out,” “Hold” (e.g. 5s each).
  - Rotating permission/affirmation lines (e.g. “I am the adult. I am safe.”).
  - Optional: crisis resources at bottom. No buttons required.

---

### 26. Settings

- **Route:** `/settings`
- **Purpose:** Profile summary and app toggles.
- **Wireframe:**
  - Header: “Settings.”
  - **Profile card:** Avatar, name/child name, age; tap to edit if supported.
  - **Toggles:** Wake nudges, auto night mode, wellbeing check-ins, simplified mode, one-handed, grief-aware, nap transition, partner sync, etc.
  - **Approach / focus:** Approach switcher; focus mode (if allowed for age).
  - **Internal (if enabled):** Links to release metrics, compliance checklist, release ops checklist.
  - Back or done.

---

### 27. Release metrics (internal)

- **Route:** `/release-metrics`
- **Purpose:** Internal metrics dashboard.
- **Wireframe:** Header “Release metrics”; list or simple charts; internal only.

---

### 28. Release compliance checklist (internal)

- **Route:** `/release-compliance`
- **Purpose:** Internal compliance checklist.
- **Wireframe:** Header “Release compliance”; checklist items; internal only.

---

### 29. Release ops checklist (internal)

- **Route:** `/release-ops`
- **Purpose:** Internal release ops checklist.
- **Wireframe:** Header “Release ops”; checklist; internal only.

---

### 30. Route unavailable / error

- **Context:** 404 or invalid route; or feature gated.
- **Wireframe:** Title “Unavailable” or “Internal tools unavailable”; short message; optional back or home.

---

### 31. Profile required view

- **Context:** Shown when a tab or feature needs profile but none exists.
- **Wireframe:** Title (e.g. “Family” or “Sleep”); message “Complete onboarding first”; CTA to onboarding or home.

---

### 32. Feature paused view

- **Context:** Feature turned off by rollout (e.g. family rules disabled).
- **Wireframe:** Title; “This feature is paused”; optional back.

---

## Summary table

| # | Screen / flow | Route / context |
|---|----------------|------------------|
| 1 | Splash | `/` |
| 2–2g | Onboarding v2 (container + 7 steps) | `/onboard` |
| 3 | App shell (tabs + Pocket FAB) | All tab routes |
| 4 | Plan home | `/plan` |
| 5 | Regulate flow (5 steps) | `/plan/regulate` |
| 6 | Plan card | `/plan/card/:id` |
| 7 | Plan script log | `/plan/log` |
| 8 | Family home | `/family` |
| 9 | Family shared (rules) | `/family/shared` |
| 10 | Family invite | `/family/invite` |
| 11 | Family activity | `/family/activity` |
| 12–12a | Sleep gate + mini-onboarding | `/sleep` |
| 13 | Sleep hub | `/sleep` |
| 14 | Sleep tonight | `/sleep/tonight` |
| 15 | Current rhythm | `/sleep/rhythm` |
| 16 | Update rhythm | `/sleep/update` |
| 17 | Library home | `/library` |
| 18 | Learn | `/library/learn` |
| 19 | Logs (Today) | `/library/logs` |
| 20 | Saved playbook | `/library/saved` |
| 21 | Patterns | `/library/patterns` |
| 22 | Monthly insight | `/library/insights` |
| 23 | Library card | `/library/cards/:id` |
| 24 | Pocket overlay | When Pocket enabled |
| 25 | Breathe / SOS | `/breathe` |
| 26 | Settings | `/settings` |
| 27–29 | Internal: metrics, compliance, ops | `/release-*` |
| 30–32 | Error / profile required / feature paused | As needed |

---

*Document generated from codebase structure and routes; no code included.*
