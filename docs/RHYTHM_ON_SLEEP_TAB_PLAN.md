# Plan: Fix duplicate "Today rhythm" under Sleep tab

**Problem:** The same "Today rhythm" card (Wake, First nap, Bedtime, next up, confidence, Sleep tonight guidance) appears in two places:

1. **Home (Now tab)** — `TodayRhythmCard` we added; shows when rhythm data exists and Sleep is enabled.
2. **Sleep tab** — Inside **CurrentRhythmScreen**, which is the **default screen** when you tap the Sleep tab.

So when the user says "I still see this under sleep," they mean: tapping **Sleep** in the bottom nav lands on a screen that shows "Tonight is the hero. Rhythm is here when you need it." and then the full **Today** section with the same Today rhythm card, plus PLAN VIEW (Relaxed/Precise, Today windows), Adjustments, Tools, etc. That screen is **CurrentRhythmScreen** at route `/sleep`.

---

## Where it comes from

| Location | Route | What shows the "Today rhythm" block |
|----------|--------|-------------------------------------|
| **Sleep tab (default)** | `/sleep` | `CurrentRhythmScreen` — builds the card inline in its "Today" section (SolidCard + _AnchorRow + SettleCta). |
| **Now tab** | `/plan` → **PlanHomeScreen** | If the rhythm card is to appear on Now tab, it should live in **PlanHomeScreen** (or the screen that actually renders at `/plan`). We added `TodayRhythmCard` to **HomeScreen** (`home.dart`); that screen is **not** in the v2 shell (Now tab uses PlanHomeScreen). So either move the card into PlanHomeScreen or make Now tab use HomeScreen. |

So the duplicate is:

- **Sleep:** `lib/screens/current_rhythm_screen.dart` (inline "Today rhythm" block, lines ~447–537).
- **Home:** `lib/widgets/today_rhythm_card.dart` used in `lib/screens/home.dart` (and `home.dart` is used for the Now tab’s home; confirm which route shows it — e.g. Plan home vs a dedicated home).

**Important:** In v2, the **Now tab** default is `/plan` → **PlanHomeScreen**, not HomeScreen. The rhythm card was added to **HomeScreen** (`home.dart`), which is not mounted in the v2 bottom-nav shell. So right now the card may only appear in tests or legacy routes. When fixing, either (1) add `TodayRhythmCard` to **PlanHomeScreen** so it shows on the Now tab, or (2) change the Now tab to show HomeScreen so the existing card is visible.

---

## Options to fix (choose one direction)

### Option A — Sleep tab = “Tonight” only (recommended)

- **Change Sleep tab default** from `CurrentRhythmScreen` to a **Tonight-focused** screen:
  - Either **SleepTonightScreen** at `/sleep` (tonight scenarios + guidance), or
  - A thin **Sleep hub** that only shows: “Night wake” / “Early wake” (and maybe “Sleep tonight guidance”), plus a single link: “See today’s rhythm” → navigates to Current Rhythm or to Now tab.
- **Today rhythm card** lives in **one place only**: the **Now tab** (e.g. on the screen we call “Home” that already uses `TodayRhythmCard`). No full “Today rhythm” block on the Sleep tab.
- **CurrentRhythmScreen** becomes a **secondary** screen: reached via “See today’s rhythm” (or “Rhythm & plan”) from the Sleep menu or from the Home rhythm card (e.g. “Full rhythm & plan” link). So “Today rhythm” summary = Home; full rhythm + PLAN VIEW + adjustments = one dedicated screen.

**Pros:** Clear mental model: Sleep tab = what’s happening tonight; daily schedule = Home. No duplicate card.  
**Cons:** Requires changing default route for Sleep branch and possibly adding a small hub or making `/sleep` redirect to `/sleep/tonight`.

---

### Option B — Keep Sleep as “Rhythm” but remove the big card

- **Keep** Sleep tab default = `CurrentRhythmScreen` at `/sleep`.
- **Remove** the full “Today rhythm” card from CurrentRhythmScreen (the inline SolidCard with Wake / First nap / Bedtime / next up / confidence / “Sleep tonight guidance”).
- Replace that block with either:
  - A **one-liner**: e.g. “Today: Wake 7:00, First nap 9:30, Bedtime 7:30” and a link “Sleep tonight guidance”, or
  - A link: “See today’s rhythm on Home” that switches to the Now tab (or deep-links to the Home screen that shows `TodayRhythmCard`).
- **Canonical “Today rhythm” card** stays only on **Home** (Now tab).

**Pros:** No duplicate card; Sleep tab still has “Rhythm” in the name but focuses on Tonight hero + PLAN VIEW + Tools; minimal route changes.  
**Cons:** Sleep tab still shows a lot of “rhythm” (PLAN VIEW, adjustments); the “today schedule” is no longer on Sleep, which might feel like a demotion if users expect it there.

---

### Option C — Home shows only a link; Sleep keeps full rhythm

- **Remove** `TodayRhythmCard` from the Home (Now) screen (or replace with a single line + “Open rhythm” that goes to `/sleep`).
- **Keep** the Sleep tab as it is: default = CurrentRhythmScreen with the full “Today rhythm” card and PLAN VIEW.
- So the **only** place the full “Today rhythm” card appears is under **Sleep**.

**Pros:** One canonical place (Sleep); no change to Sleep tab structure.  
**Cons:** Conflicts with your earlier ask to have “this” (the Today rhythm card) on the **home** screen; “rhythm” would stay under “sleep assess” instead of being the daily home.

---

## Recommendation

- **Option A** best matches “I want this on the home screen” and “I still see this under sleep” (i.e. you don’t want the same thing under Sleep). It gives:
  - **One** place for the “Today rhythm” **card**: **Now tab (Home)**.
  - **Sleep tab** = tonight (and optionally a link to “full rhythm & plan” = CurrentRhythmScreen).

**Implementation steps (when you’re ready):**

1. **Change Sleep tab default**  
   - In `router.dart`, make `/sleep` show a Tonight-only screen (e.g. a small Sleep hub or `SleepTonightScreen`) instead of `CurrentRhythmScreen`.
2. **Keep `/sleep/rhythm` or add `/sleep/rhythm`**  
   - Route to `CurrentRhythmScreen` so “Full rhythm & plan” (PLAN VIEW, adjustments, tools) is still available from the Sleep menu or from a link on the Tonight screen.
3. **Remove the inline “Today rhythm” block** from `CurrentRhythmScreen` (the SolidCard with Wake/First nap/Bedtime/next up/confidence/CTA). Optionally replace with a short summary line + “Sleep tonight guidance” and “View full rhythm” that goes to the same screen or to Home.
4. **Confirm** the Now tab’s home screen is the only place that shows `TodayRhythmCard` (or the only place that shows the full “Today rhythm” card).

No code changes have been made yet; this is the plan only.
