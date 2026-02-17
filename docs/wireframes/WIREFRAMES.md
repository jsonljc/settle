# Settle v1.4 — Refined UX Wireframes

**Revision notes:** Every screen from v1.4 has been audited against Settle's core laws (post-situation first, one action per screen, 15s value, no forms). Changes are marked with `△` so your Cursor agent can diff against the prior spec.

---

## Global UI Rules (apply everywhere)

- One primary action per screen. Secondary actions allowed but visually quieter (ghost buttons, small text links).
- No dense text: max 2–3 short lines per block. If you're writing a paragraph, you're writing too much.
- No dashboards: no charts, no counters, no streak UI, no progress bars.
- "Close moment" is the universal exit pattern for all guided flows (Sleep, Tantrum, Reset).
- △ **Consistent terminology:** "Parenting style" everywhere (not "sleep style"). One term, one meaning.
- △ **Loading states:** Every screen that fetches content shows a single centered pulse animation (same as Moment). Never a spinner. Never a skeleton.
- △ **Error states:** If content fails to load, show: "Something went wrong." + single retry button. No technical language.
- △ **Empty states:** Always one sentence, warm tone, no illustrations. Tells the user what will appear here and how.

---

## A) Onboarding (3 screens → △ 4 screens)

**Design goal:** Get to first Reset in under 60 seconds. Every screen earns its existence by improving card quality.

### O1 — Welcome

**Layout**
- App name (large, centered)
- 1 line explanation
- Primary CTA

**Copy**
- Title: "Settle"
- Sub: "Quick repair words after hard moments."
- CTA: "Start"

**Action**
- Start → O2

**△ Refinements**
- No logo animation or splash delay. The screen IS the splash.
- If user has used Settle before (reinstall), detect via Keychain/device ID and offer: "Welcome back. Pick up where you left off?" → skip to tab root with prior data.

---

### O2 — Child basics

**Layout**
- "Child name" single input OR "Skip for now" link
- "Birthdate" date picker OR "Age range" selector (mutually exclusive, not both visible)
- Primary CTA

**Copy**
- Title: "Who's this for?"
- Name field placeholder: "First name (optional)"
- Date field: Show age-range chips by default (e.g., "0–6mo" / "6–12mo" / "1–2yr" / "2–3yr" / "3–5yr"). Tiny link below: "Enter exact birthdate instead"
- CTA: "Continue"

**△ Refinements**
- Default to age-range chips, not a date picker. Faster. Less cognitive load. A stressed parent at 2am doesn't want to scroll a date wheel.
- Exact birthdate is available but buried one tap deeper. It unlocks more precise stage detection later — worth offering but not worth blocking on.
- If "Skip for now" is tapped, default to a generic 18-month profile. Surface a gentle nudge after first Reset: "Adding [child]'s age helps us pick better words."
- This is the ONLY screen with input fields. Treat it as an exception, not a pattern.

---

### △ O3 — Why you're here (single question)

**Layout**
- Title
- Single-select chips (large, tappable)
- Primary CTA

**Copy**
- Title: "What brought you here?"
- Chips: "Sleep" / "Tantrums" / "Big feelings" / "Just exploring"
- CTA: "Continue"

**Routing**
- Sleep → default tab is Sleep
- Tantrums → default tab is Tantrum
- Big feelings → default tab is Reset
- Just exploring → default tab is Reset

**△ Refinements (major change)**
- Removed "parenting style" from onboarding entirely. Asking parents to self-categorize as "responsive" vs "structured" before they've used the app is premature and anxiety-inducing. Many parents don't know, and forcing a choice creates performance anxiety.
- Style is now inferred: after the user's 3rd Reset, surface a low-pressure question (see new screen R5 below).
- Renamed "Stress" to "Big feelings" — more specific, less clinical, and signals that the app understands emotional vocabulary.

---

### △ O4 — First value promise (new screen)

**Layout**
- Single line of text (large)
- Primary CTA

**Copy**
- Line: "Your first repair words are ready."
- CTA: "Let's go"

**Action**
- CTA → Tab root (whichever tab was selected in O3)

**△ Why this screen exists**
- It creates a micro-moment of anticipation. The user just answered 2 quick questions and now they're being told value is already waiting. This primes the first interaction and prevents the "now what?" feeling of landing on an unfamiliar tab bar.

---

## B) Reset Tab (Hero Flow)

**Design goal:** Emotional decompression → actionable repair language. The entire flow should feel like exhaling.

### R1 — Reset (Vent Hold)

**Layout**
- Dark screen (true black or very deep navy — test both)
- Center instruction (large, high contrast)
- Subtle timer ring (thin, animated, not a countdown number)
- One primary interaction: long-press anywhere on screen

**Copy**
- "Hold to let it out."
- △ First-time only tooltip (below, smaller): "Press and hold anywhere."
- △ Removed "We'll give you words after" — too transactional for the emotional state. Let the card reveal be a surprise.

**Interaction**
- Long press 3–5s → R2
- △ Timer ring fills during hold. If released early: ring resets with no judgment, no error message. Just resets silently.
- If backgrounded: pause timer. Resume if <5 min, else restart from R1.
- △ Haptic: gentle pulse every second during hold. Crescendo on completion (single strong tap).

**Soft friction interstitial (rare)**
Trigger: 4+ resets within 2 hours (not "heavy + repeated" — now a crisp, codeable threshold).
- Fullscreen, same dark background
- Line: "Quick pause."
- △ Removed the 10-second framing — it felt like a punishment timer. Instead:
- Sub: "You're using Settle a lot right now. That's okay."
- Buttons: "Keep going" (primary) / "Take a break" (secondary, closes app gently)
- △ If "Take a break" is tapped, schedule a push notification for 30 min later: "Ready when you are."

---

### R2 — State Pick

**Layout**
- Title
- Two large tiles (not buttons — tiles with subtle background color, tappable)
- No extra text

**Copy**
- △ Title: "What needs attention?"
- Options:
  - 😔 "How I feel"
  - 😤 "How they feel"

**△ Refinements**
- Changed from "I feel bad" / "They're still upset" to remove the false binary. The new framing acknowledges both states exist but asks where attention should go FIRST.
- "How I feel" routes to cards focused on self-compassion + repair language for your own emotional state.
- "How they feel" routes to cards focused on co-regulation + repair language directed at the child.
- △ Both paths can serve a card that addresses the other state too — the pick determines emphasis, not exclusion.

**Action**
- Tap one → R3

---

### R3 — Card Reveal

**Layout**
- Card appears with light slide-up + fade (200ms, ease-out — not bouncy)
- Card contains 2–3 blocks:
  1. **Wisdom** (1 line, smaller text, muted color — sets context)
  2. **Repair** (2 sentences max, large text, high contrast — the thing to say)
  3. **Next step** (1 line, only if actionable — otherwise omit entirely)
- Actions row below card

**Copy (structure, not literal)**
- Wisdom: A reframe or normalizing statement. e.g., "Yelling doesn't erase what came before."
- Repair: The actual words to say or do. e.g., "You can go back and say: 'I got too loud. I'm sorry. I still love you.'"
- Next step (optional): "Sit near them for 30 seconds. That's enough."

**Actions**
- Primary: "Keep" (saves to Playbook)
- Secondary row: "Copy" · "Send" · "Another" · "Close"

**△ Refinements**
- Renamed "Share" to "Send" — more active, implies sending to partner/co-parent. This is your viral mechanic; give it action-oriented language.
- Renamed "Different one" to "Another" — shorter, less fussy.
- △ "Another" logic: max 3 per session. After 3rd: the "Another" button disappears (not grayed out — gone). Tiny text replaces it: "That's the set for now." Only "Keep" and "Close" remain.
- △ Pattern hint: If the card engine detects a recurring situation (3+ similar resets in 7 days), show a single small line above the Wisdom line: "You've been here before this week." No advice, no link — just acknowledgment. This plants a seed for the Playbook's "Patterns" section without being preachy.
- △ Contextual card selection: Cards are filtered by the context that launched Reset (sleep, tantrum, general) AND the R2 state pick AND the child's developmental stage. This is the engine's job, not the wireframe's — but the wireframe should note that card content varies across these three axes.

**Close behavior**
- "Close" → fade out (200ms) + single haptic tap → return to tab root
- △ After close, if this was the user's 1st or 2nd Reset ever, show a brief toast on the tab root: "That's it. Come back anytime." (disappears after 3s, not tappable)

---

### △ R4 — Send Card View (promoted from optional)

**Layout**
- Fullscreen card, optimized for screenshot/share
- Card background: warm, branded (not the dark Reset background)
- Settle watermark (very subtle, bottom corner)
- Two actions

**Copy**
- Card content identical to R3 (Wisdom + Repair only — no Next step on shareable version)
- △ Small line above card: "Send this to your co-parent"

**Actions**
- "Send" (opens native share sheet)
- "Close" (returns to R3 actions row)

**△ Why this is promoted**
- A parent texting their partner "say this when you go in next" is Settle's strongest organic growth loop. This screen should feel intentional, not afterthought. The "Send" button in R3 opens R4 directly.

---

### △ R5 — Style Discovery (new, post-3rd-Reset)

**Trigger:** After the user's 3rd Reset (any context), shown once.

**Layout**
- Card-style overlay (not a new screen — slides up over tab root)
- Title
- Two options
- Dismiss link

**Copy**
- Title: "Quick question"
- Sub: "The repair words can lean more toward…"
- Option A: "Warmth first" (maps to Responsive)
- Option B: "Structure first" (maps to Structured)
- Dismiss: "No preference" (maps to blended/default)

**△ Why this exists**
- Replaces the onboarding style question. By the 3rd Reset, the user has experienced the product and can make an informed choice. The framing avoids identity labels ("responsive parent") and instead focuses on the output they want ("warmth first" vs "structure first").
- "Gentle" as a separate category is removed — it's a spectrum between warmth and structure, not a third option.

---

## C) Sleep Tab

**Design goal:** Tonight is the hero. Rhythm is a one-time setup that then lives quietly in the background.

### △ S0 — Sleep Home (restructured)

**Layout**
- Title area: "Sleep"
- △ Three large entry tiles (no toggle — Tonight is always visible):
  - "Bedtime"
  - "Night wake"
  - "Early wake"
- △ Below tiles: Rhythm summary (if configured) — passive, not interactive
  - 1–2 lines: "Wake ~6:30 · 1 nap · Bed ~7:15"
  - Tiny edit link: "Edit rhythm"
- △ If Rhythm not configured: soft prompt below tiles
  - "Set a rhythm to get better sleep guidance."
  - Link: "Set up · 30s"

**△ Major structural change**
- Removed the Tonight / Rhythm segmented toggle entirely. The toggle created a risk of a 3am parent accidentally landing on Rhythm setup. Tonight IS the Sleep tab. Rhythm is a background configuration that improves Tonight's guidance quality.
- Rhythm summary is always visible (when configured) as passive context, not an interactive lane.
- No stats. No history. No "last night" recaps.

---

### S1 — Tonight: Situation-specific entry

**△ This screen is eliminated.** Tapping a tile on S0 goes directly into the first guidance step (S2). One fewer screen = one fewer decision for a sleep-deprived parent.

---

### S2 — Tonight Guidance Step (micro-flow)

Each Tonight situation (Bedtime / Night wake / Early wake) is a **3-step max micro-flow.** Each step is one screen.

**Layout (each step)**
- Title (what to do — imperative verb)
- 1 short instruction line
- Primary CTA: "Next" (steps 1–2) or "Done" (step 3)

**△ Bedtime flow example:**

**Step 1**
- Title: "Keep it boring."
- Line: "Same words, same tone, same order."
- CTA: "Next"

**Step 2**
- Title: "One thing to say."
- △ Large quoted text, styled distinctly from instruction text:
  > "It's time for sleep. I love you. See you in the morning."
- △ Below quote, muted: "Adjust the words, keep the pattern."
- CTA: "Next"

**Step 3**
- Title: "If they call out…"
- △ Two selectable rows (radio-style, not two CTAs):
  - ○ "Brief check: 'I'm here. Back to sleep.'" ← highlighted if style = Warmth
  - ○ "Wait 2 minutes before going in." ← highlighted if style = Structure
- △ Tiny text below options: "Both work. Pick what feels right tonight."
- CTA: "Done"

**△ Night wake flow example:**

**Step 1**
- Title: "Don't turn on lights."
- Line: "Keep your voice flat and boring."
- CTA: "Next"

**Step 2**
- Title: "Say this."
- > "It's still nighttime. Back to sleep."
- CTA: "Next"

**Step 3**
- Title: "If they won't settle…"
- ○ "Sit beside them silently. Hand on back."
- ○ "Brief comfort, then leave. Return in 5 min."
- CTA: "Done"

**△ Early wake flow example:**

**Step 1**
- Title: "Decide your threshold."
- Line: "Before 6am = treat it like a night wake."
- CTA: "Next"

**Step 2**
- Title: "If it's too early."
- > "It's still sleep time. I'll come get you when it's morning."
- CTA: "Next"

**Step 3**
- Title: "If they won't go back."
- ○ "Quiet time in crib/bed. Boring presence."
- ○ "Get up, but keep it dim and dull for 30 min."
- CTA: "Done"

**△ Refinements**
- Style-adaptive highlighting: Step 3 always shows both options, but pre-highlights the one matching the user's style preference (from R5). If no style is set, neither is highlighted.
- △ Stage-adaptive copy: The quoted scripts vary by developmental stage. A 6-month-old flow uses different language than a 3-year-old flow. This is a content/engine concern, but the wireframe should note that copy is not static.

---

### S3 — Close moment (mandatory end of every Tonight flow)

**Layout**
- Title
- One sentence
- Primary CTA
- Secondary link

**Copy**
- Title: "Close the moment."
- Line: "Want a quick repair before you go back?"
- Primary: "Reset · 15s"
- Secondary: "I'm good"

**△ Refinements**
- Changed "Not now" to "I'm good" — warmer, more affirming. "Not now" implies obligation to come back; "I'm good" validates the parent's state.
- △ If user picks "I'm good" 3+ times consecutively: stop showing S3 for the next 7 days. Respect the signal. Resume after 7 days.
- When Reset opens from here, it carries context=sleep so card selection is sleep-relevant.

---

### S4 — Rhythm Setup (30–60s)

**Layout**
- Tiny wizard, 3 screens, single action per screen

**Step 1: Wake anchor**
- Title: "When does the day start?"
- △ Scrollable time selector with 15-min increments (not a text input, not a full clock picker)
- Default: 6:30 AM (pre-selected)
- CTA: "Next"

**Step 2: Nap count**
- Title: "How many naps?"
- △ Options are stage-limited and shown as large tappable numbers:
  - If <6mo: 3 / 4 (grayed: "Usually 3–4 at this age")
  - If 6–12mo: 2 / 3
  - If 12–18mo: 1 / 2
  - If 18mo+: 0 / 1
- CTA: "Next"

**Step 3: Bedtime target**
- Title: "Bedtime around…"
- △ Scrollable time selector, same as Step 1
- △ Smart default based on wake time + nap count (e.g., wake 6:30 + 1 nap = default bedtime 7:15)
- CTA: "Save"

**After save**
- △ Single confirmation line (not a new screen — overlay on S0):
  "Rhythm set. Repeat it daily until something changes."
- Auto-dismiss after 3s or tap anywhere

**△ Refinements**
- Added smart defaults throughout. Parents shouldn't have to calculate — the app should suggest, and they adjust.
- Nap count options are stage-limited to prevent impossible configurations (a 3-year-old selecting 4 naps).
- No "Done" CTA after save — the confirmation auto-dismisses to reduce one more tap.

---

## D) Tantrum Tab

**Design goal:** After-the-fact emotional processing first, prevention tools second. Never judgmental.

### T0 — Tantrum Home

**Layout**
- △ Two large tiles (not a toggle — both visible):
  - "Just happened" (→ T1, Reset entry)
  - "Prepare for next time" (→ T3, prevention cards)
- No extra copy on this screen

**△ Refinements**
- Replaced the "After / Next time" segmented toggle with two always-visible tiles. Reason: toggles hide content; tiles show both options immediately. A parent post-meltdown needs to see "Just happened" without parsing a toggle.
- Renamed "After" to "Just happened" — more emotionally accurate and creates urgency to tap.
- Renamed "Next time" to "Prepare for next time" — clearer intent.

---

### T1 — Just Happened (Reset entry)

**Layout**
- Title
- 1 supportive line
- Primary CTA
- Secondary chip

**Copy**
- Title: "Take a breath first."
- △ Line: "Then we'll find the right words."
- Primary: "Reset · 15s"
- △ Secondary chip: "Just need 10 seconds" → launches Moment (M0) with context=tantrum

**△ Refinements**
- Changed title from "After" to "Take a breath first" — directive, supportive, and matches the emotional state.
- Changed line from "Let's close the loop first" (too casual/corporate) to something that promises value.
- Moment chip is more clearly labeled — "Just need 10 seconds" tells the parent exactly what they're getting.

**Action**
- Reset opens with context=tantrum

---

### T2 — Debrief (conditional, post-Reset)

**△ Trigger conditions (tightened to be codeable):**
1. User completed a Reset with context=tantrum, AND
2. It's the 2nd+ tantrum-context Reset in the same calendar day, AND
3. Debrief hasn't been shown today already

This means: shown max once per day, only on repeat tantrum days. Never on a single-tantrum day.

**Layout**
- Title
- One question
- Single-select chips
- Primary CTA
- Quiet skip link

**Copy**
- Title: "Want a better guess for next time?"
- △ Sub: "What set it off?" (replaces the options list title — more direct)
- Chips:
  - "Transition" (leaving park, ending screen time)
  - "Told no"
  - "Needed connection"
  - "Tired or hungry"
  - "Wanted control"
  - "Not sure"
- CTA: "Done"
- Skip: "Skip" (plain text link, no explanation needed)

**△ Refinements**
- Renamed "Denied request" to "Told no" — parent language, not clinical language.
- Renamed "Power struggle" to "Wanted control" — less adversarial framing. The child isn't an opponent.
- Renamed "Connection" to "Needed connection" — makes the child the subject, which is more empathetic.
- Renamed "Tired / hungry / sensory" to "Tired or hungry" — sensory is too clinical for most parents. If sensory processing is a factor, it's likely a special-needs path that deserves its own handling later.
- △ Data handling: The selection is stored locally as a lightweight event (timestamp + category). Not logged to any server in v1. Used only to improve "Prepare for next time" card selection.
- △ "Not sure" is valid and should never feel like a cop-out. If selected, the app should respond with the same respect as any other choice.

**Action**
- Done → Tantrum home (T0)

---

### T3 — Prepare for Next Time

**Layout**
- △ Up to 3 stacked cards (card preview style, not full cards)
- Each card preview shows:
  - Title (short, imperative)
  - One-line preview of the script
  - "Save" (small, right-aligned)
- Bottom: "Done" (primary CTA, returns to T0)

**Copy (example cards for a 2-year-old, tantrum category = "Told no")**

Card 1:
- Title: "Offer the feeling first."
- Script: "'You really wanted that. I get it.'"
- Save

Card 2:
- Title: "Name the boundary simply."
- Script: "'The answer is no, and I'm staying with you.'"
- Save

Card 3:
- Title: "After the storm."
- Script: "'That was hard. Let's sit together.'"
- Save

**△ Refinements**
- Cards are filtered by: child's developmental stage + most recent debrief category (if available) + parenting style preference.
- △ If no debrief data exists yet, show general-purpose prevention cards for the child's stage.
- △ Each card has a collapsed "Why this works" link. Tap expands 1–2 sentences of developmental reasoning inline (no new screen). Collapse on second tap.
- △ "Save" adds the card to Playbook. On save, tiny toast: "Saved to Playbook."
- Max 3 cards per visit. If user returns to T3 in the same day, show the same 3. New set daily.
- △ If user has saved all 3, the "Save" buttons change to "Saved ✓" (muted, not tappable).

---

## E) Moment (10s Brake)

**Design goal:** The fastest possible intervention. From activation to script in 10 seconds.

### M0 — Moment (haptic regulation)

**Activation sources**
- iOS lock screen widget (primary — this is the killer surface)
- In-app chip (from Sleep flows, Tantrum T1)
- iOS Shortcut / Siri: "Hey Siri, Settle moment"
- △ Apple Watch complication (future — note in spec for architecture planning)

**Layout**
- Dark screen (matches Reset R1 aesthetic)
- Small label: "10 seconds" (top, muted)
- Center: slow pulse animation (circle that breathes)
- △ No text instructions. The pulse IS the instruction.

**Copy**
- △ Removed "Slow down." — the dark screen + pulse communicates this nonverbally. Text during a crisis moment is noise.

**Behavior**
- 10s haptic metronome (1 tap per second, gentle)
- △ At second 8: pulse begins to fade
- At second 10: pulse gone → transition to M1
- △ If user taps screen during the 10s: skip to M1 immediately. Don't force them to wait if they're ready.

**Context ladder (determines M1 content)**
1. Launched from a specific screen → use that context (sleep, tantrum)
2. Else: last flow context within 6 hours
3. Else: universal (no context assumed)
4. Always stage-adapt language to child's developmental level

---

### M1 — Two-choice script

**Layout**
- Two large tiles (full-width, stacked vertically)
- Each tile contains:
  - Label (large, bold): "Boundary" or "Connection"
  - Script (large text, below label): the exact words to say

**Copy (example: universal context, toddler stage)**

Tile 1:
- Label: "Boundary"
- Script: "'I won't let you do that. I'm right here.'"

Tile 2:
- Label: "Connection"
- Script: "'I can see you're upset. Come here.'"

**△ Copy (example: sleep context, toddler stage)**

Tile 1:
- Label: "Boundary"
- Script: "'It's sleep time. I'll check on you soon.'"

Tile 2:
- Label: "Connection"
- Script: "'I know this is hard. I'm right outside.'"

**Interaction**
- Tap either tile → dismiss M1 (return to wherever the user was)
- △ No animation on dismiss. Instant. The parent needs to act NOW.
- △ Footer (appears 1s after tiles render, very small): "Later: Reset · 15s"
  - This is a text link, not a button. Tapping it opens Reset with whatever context was determined.
  - It's deliberately delayed 1s so it doesn't compete with the two main tiles.

**△ Refinements**
- Scripts are context-aware (sleep/tantrum/universal) AND stage-aware. This is the engine's job but the wireframe must specify that M1 is not showing the same two scripts every time.
- The tiles should feel like two valid paths, not a right answer and a wrong answer. Visual weight must be identical.

---

## F) Playbook Tab

**Design goal:** A quiet, growing collection of what works for THIS family. Never feels empty; never feels overwhelming.

### △ P0 — Playbook Home (restructured)

**Layout — when cards exist (1+):**
- Section 1: "Your words" (saved cards, most-recently-kept first)
  - Each card shows: Wisdom line + first line of Repair
  - Tap → P1 (full card view)
- △ Section 2: "Worked before" (only appears when a previously saved card was used in a similar context and the user kept it again)
  - Max 2 cards shown here
  - These are cards the system has high confidence were helpful
- △ Section 3: "Patterns" (appears after 5+ resets with debrief data)
  - Single line summary: e.g., "Transitions are the most common trigger this week."
  - Not a chart. Not a stat. Just a sentence.
  - Tap → shows the 2–3 "Prepare" cards most relevant to that pattern

**△ Layout — empty state (no saved cards yet):**
- Single sentence: "Cards you keep will live here."
- △ Below: "Try a Reset to get your first card." (tappable → opens Reset)
- △ This addresses the "dead tab" problem: even in empty state, there's a clear path to populating it.

**△ Architectural note for Playbook viability:**
- The Playbook tab earns its place in the tab bar ONLY because it serves a distinct job: reviewing and reusing proven repair language. If after 4 weeks of usage testing, <20% of users visit Playbook unprompted, demote it to a pull-up drawer accessible from the Reset card (R3) "Keep" action. The tab bar slot could then go to a "Family" tab for co-parent features.

---

### P1 — Playbook Card View

**Layout**
- Full card (same layout as R3: Wisdom + Repair + optional Next step)
- Actions row

**Actions**
- "Copy" · "Send" · "Close"
- △ No "Delete" — removing saved cards should be intentional. Add a long-press → "Remove from Playbook?" confirmation instead. This prevents accidental deletions while keeping the action available.

---

## G) Settings

**Design goal:** Minimal. Settings exist to correct things, not to configure an experience. The app should work well without the user ever visiting Settings.

### ST0 — Settings Home

**Layout**
- Simple list:
  - "Child" → ST1
  - "Parenting style" → ST2
  - "Notifications" → ST3
  - △ "About Settle" → external link or simple info screen
  - △ "Reset Settle" → confirmation dialog → clears all local data, restarts onboarding

**△ Refinements**
- Removed "Stage override" as a standalone settings item. Stage is derived from the child's age and shouldn't be manually overridable in normal flow. The stage update banner (ST4) handles transitions. If a parent truly needs to override (e.g., developmental delay), it can be a secondary option inside the Child profile (ST1).
- Added "Reset Settle" for users who want a fresh start — important for the partner who takes over the phone, or for a new child.

---

### ST1 — Child Profile

**Layout**
- Name (editable text field)
- Age info (birthdate or age range, editable)
- △ Stage display: human-readable label (e.g., "Young toddler · 14 months")
- △ Collapsed section: "Stage doesn't seem right?" → opens manual stage selector
- CTA: "Save"

**△ Refinements**
- Stage override is available but buried. Most parents should never need it.
- If birthdate is entered, age auto-calculates and stage auto-assigns. If only age range was given in onboarding, show: "Add a birthdate for more accurate guidance" as a gentle prompt.

---

### ST2 — Parenting Style

**Layout**
- △ Two options (matching R5 framing):
  - "Warmth first"
  - "Structure first"
  - △ "Blended" (shown as a third option here, not in R5)
- Current selection highlighted
- CTA: "Save"

**△ Refinements**
- Terminology matches R5 exactly. No "Responsive" / "Gentle" / "Structured" labels — those are internal system categories, not user-facing.
- "Blended" is the default if the user never answered R5 or dismissed it.
- △ Brief explainer under each option (collapsible):
  - Warmth first: "Repair cards emphasize connection and comfort before boundaries."
  - Structure first: "Repair cards emphasize clarity and consistency before comfort."
  - Blended: "A mix of both, depending on the situation."

---

### ST3 — Notifications

**Layout**
- Two toggles with descriptions
- CTA: "Save"

**Copy**
- Toggle 1: "Evening check-in"
  - △ Description: "A reminder to prep for tonight. Usually around 6pm."
- Toggle 2: "Gentle nudges"
  - △ Description: "Occasional prompts based on patterns we notice."
- △ Both default to ON during onboarding.

**△ Refinements**
- Renamed "Evening repair reminder" to "Evening check-in" — "repair" implies something is broken.
- Renamed "Gentle check-ins" to "Gentle nudges" — "check-in" implies monitoring.
- Added descriptions so parents know what they're opting into.
- △ Evening check-in time is auto-set to 1 hour before the configured bedtime (from Rhythm). If no Rhythm, defaults to 6:00 PM. Not user-configurable in v1 — simplicity over flexibility.

---

### ST4 — Stage Transition Banner (non-blocking)

**Trigger:** When the child's age crosses a developmental stage boundary (calculated from birthdate or age range midpoint).

**Layout**
- Banner appears at top of any tab (not a modal, not blocking)
- One line + two actions

**Copy**
- "[Name] is growing. Update to [new stage]?"
- △ Changed from "might be ready for" — if the birthdate is known and the stage boundary is clear, don't hedge.
- "Update" (primary) / "Not yet" (secondary)

**If "Update" tapped:**
- △ Single inline confirmation: "Updated to [stage]." (toast, 3s, auto-dismiss)
- △ No separate confirm screen. The banner WAS the confirmation prompt. One tap should be enough.

**If "Not yet" tapped:**
- Banner dismisses. Reappears in 2 weeks.

**△ Refinements**
- Simplified from a two-step flow (banner → confirm screen) to a single-tap action. The banner itself provides enough context.
- △ Auto-update exception: If the child's exact birthdate is known AND the stage transition is unambiguous (e.g., 12 months → toddler), auto-update silently and show a post-hoc toast: "[Name]'s guidance updated for toddler stage." No prompt needed. The parent didn't make a choice — biology did. "Not yet" is only relevant for ambiguous transitions.

---

## H) Cross-Surface Micro-Interactions

### "Keep" feedback
- On Keep (R3): toast "Saved to Playbook" (2s, bottom of screen)
- △ Toast is tappable → opens Playbook directly to that card
- Haptic: single light tap

### "Send" flow
- On Send (R3 or P1): opens R4 (Send Card View), then native share sheet
- △ Pre-populated share text: the Repair lines only (no Wisdom, no branding in the text — just the words the co-parent needs)
- △ If sharing via Messages: include a tiny Settle link at the end: "From Settle — settle.app" (short, not spammy)

### Playbook resurfacing (high confidence only)
- On R3 card reveal: if a previously saved card matches the current context with high confidence (same trigger category + same stage + saved within last 14 days):
  - Show a tiny line below the actions row: "Worked before: [card title]"
  - Tap → opens that card in a mini-preview (not full Playbook)
- △ Threshold: only show if the prior card was kept AND used in a similar context at least twice. This prevents random resurfacing.

### △ Co-parent prompt (new)
- After the user's 5th Reset: show once on tab root:
  - "Does someone else help with [child name]?"
  - "Invite them" (opens native share with app store link)
  - "Just me" (dismisses permanently)
- This is Settle's primary acquisition mechanic beyond organic sharing. Time it after the user has experienced enough value to recommend.

---

## I) Tab Bar

**Layout**
- 4 tabs: Reset · Sleep · Tantrum · Playbook
- △ Reset tab icon pulses subtly (once, on first app open each day) to reinforce it as the hero action
- Active tab: solid icon + label
- Inactive tabs: outline icon, no label
- △ Moment is NOT a tab — it's a widget/shortcut surface. It lives outside the app's navigation.

**△ Refinements**
- No badge counts. No notification dots on tabs. The tab bar should feel calm.
- Tab order matters: Reset is leftmost (thumb-friendly for right-handed users holding a phone while holding a child with their left arm). Consider mirroring for left-handed users in a future accessibility pass.

---

## J) First-Run Experience Summary

To make the first session feel complete, here's the ideal first-run path:

1. O1 (Welcome) → O2 (Child basics) → O3 (Why you're here) → O4 (Value promise)
2. Land on default tab (based on O3 selection)
3. User taps into their first flow (Reset, Sleep Tonight, or Tantrum)
4. Complete the flow → Close moment → first card saved to Playbook
5. △ Tab root shows toast: "That's it. Come back anytime."

**Time to first value: under 90 seconds** (including onboarding).

---

## K) State Machine Notes (for Cursor implementation)

### Reset flow states
```
R1_IDLE → (long_press_start) → R1_HOLDING → (3-5s complete) → R2_STATE_PICK
R2_STATE_PICK → (tap_option) → R3_CARD_REVEAL
R3_CARD_REVEAL → (keep) → SAVE_TO_PLAYBOOK → TAB_ROOT
R3_CARD_REVEAL → (another, count < 3) → R3_CARD_REVEAL (new card)
R3_CARD_REVEAL → (another, count >= 3) → R3_CARD_REVEAL (another hidden)
R3_CARD_REVEAL → (send) → R4_SEND_VIEW
R3_CARD_REVEAL → (close) → TAB_ROOT
R4_SEND_VIEW → (share_complete | close) → R3_CARD_REVEAL
```

### Sleep Tonight flow states
```
S0_TAP_TILE → S2_STEP_1 → S2_STEP_2 → S2_STEP_3 → S3_CLOSE_MOMENT
S3_CLOSE_MOMENT → (reset) → R1_IDLE (context=sleep)
S3_CLOSE_MOMENT → (im_good) → S0_HOME
```

### Tantrum flow states
```
T0_TAP_JUST_HAPPENED → T1_RESET_ENTRY → R1_IDLE (context=tantrum)
  → (post_reset) → T2_DEBRIEF (if conditions met) → T0_HOME
T0_TAP_PREPARE → T3_CARDS → T0_HOME
```

### Moment flow states
```
M0_ACTIVATED → (10s_complete | tap_skip) → M1_SCRIPT_CHOICE
M1_SCRIPT_CHOICE → (tap_tile) → DISMISS
M1_SCRIPT_CHOICE → (tap_later_reset) → R1_IDLE (context from ladder)
```

---

## L) Event Tracking (minimal, privacy-first)

All events are local-only in v1. No server logging. No analytics SDK.

| Event | Data stored | Purpose |
|-------|------------|---------|
| reset_complete | timestamp, context, state_pick, card_id, action (keep/close/another) | Card engine improvement |
| tonight_complete | timestamp, situation, style_choice (step 3) | Style inference |
| debrief_complete | timestamp, category | Pattern detection for Playbook |
| moment_complete | timestamp, context, choice (boundary/connection) | Script relevance |
| card_saved | timestamp, card_id | Playbook population |
| card_sent | timestamp, card_id | Viral loop measurement (future) |
| rhythm_configured | timestamp, wake/nap/bed values | Sleep guidance quality |
| style_set | timestamp, style | Card filtering |

△ No event is required for the app to function. If storage fails, the app still works — it just can't personalize as effectively.
