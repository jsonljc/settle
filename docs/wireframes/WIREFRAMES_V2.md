# Settle v2 — Revised Wireframes

**What changed from v1.4:** This is a ground-up rewrite of the wireframe spec. The reactive repair flows are preserved but resequenced. A proactive "Make it better" lane is added. Copy is rewritten in parent voice. Progress reflection replaces the dashboard ban with lightweight acknowledgment. Every change is marked with `▲` so agents can diff against the prior spec.

**Canon compliance:** This spec proposes changes to Canon decisions #1 and #6. These require `[CANON OVERRIDE]` approval before implementation. All other canon decisions are respected as-is.

**Proposed Canon changes:**
- **Canon #1:** Expand from "post-moment recovery tool" → "post-moment recovery + proactive parenting guidance tool." The reactive loop remains the hero. The proactive lane is additive, not a replacement.
- **Canon #6:** Expand from "exactly 4 screens" → "exactly 4 screens, with copy rewritten per this spec." Structure unchanged, content improved.

---

## Design Philosophy (new)

### The parent we're designing for

She's 34. Two kids, 18 months and 4 years. She opened this app at 9:47pm after putting the toddler down for the third time. She yelled. She feels guilty. She also feels resentful that bedtime took 90 minutes again. She wants two things that feel contradictory:

1. **"Tell me what to say right now"** — immediate relief
2. **"Make this stop happening every night"** — lasting change

Settle must serve both. The first is reactive (Reset, Moment, Sleep Tonight). The second is proactive (weekly focus, plays, progress reflection). Neither works without the other — relief without progress feels like a band-aid; progress without relief feels like homework.

### Three promises

Every screen, every flow, every word in Settle should serve one of these:

1. **"You'll know what to say."** — Immediate. The words are right here.
2. **"It gets easier."** — Progressive. Things are measurably improving.
3. **"You're doing this."** — Reflective. Evidence that you're a good parent.

### Emotional design sequence

The correct order for a distressed parent is:

```
Acknowledge → Equip → Regulate (optional)
```

NOT regulate → categorize → equip. You don't ask a drowning person to breathe before throwing them a rope.

---

## Global UI Rules (apply everywhere)

- One primary action per screen. Secondary actions visually quieter (ghost buttons, small text links).
- No dense text: max 2–3 short lines per block.
- No dashboards: no charts, no counters, no streak UI, no progress bars.
- "Close moment" is the universal exit pattern for all guided flows.
- **Consistent terminology:** "Parenting style" everywhere (not "sleep style").
- **Loading states:** Centered pulse animation. Never a spinner. Never a skeleton.
- **Error states:** "Something went wrong." + single retry button. No technical language.
- **Empty states:** One sentence, warm tone. Tells the user what will appear and how.
- ▲ **Copy voice:** Every piece of copy must pass this test: "Would a tired parent at 2am understand this instantly and not feel judged?" If no, rewrite.
- ▲ **Progress reflection:** Settle does not show dashboards, but it DOES reflect progress back as single sentences at the right moments. This is not a dashboard — it's a mirror.

---

## A) Onboarding (4 screens — structure unchanged, copy rewritten)

**Design goal:** Get to first value in under 60 seconds. Every screen earns its existence. The parent should feel understood, not interrogated.

### O1 — Welcome

**Layout**
- App name (large, centered)
- 1 line
- Primary CTA

**Copy**
- Title: "Settle"
- ▲ Sub: "Know what to say after the hard parts."
- CTA: "Start"

**▲ Why the copy changed**
- Old: "Quick repair words after hard moments." — "Repair words" is app jargon. No parent thinks in those terms.
- New: Speaks to the parent's actual desire. They feel stuck after a blowup — they don't know what to say. This promises that Settle solves that.

**Action**
- Start → O2

**Reinstall detection**
- If prior data found via Keychain/device ID: "Welcome back. Pick up where you left off?" → skip to tab root with prior data.

---

### O2 — Child basics (only screen with input fields)

**Layout**
- "Child name" single input OR "Skip" link
- Age-range chips (default) OR exact birthdate (buried one tap deeper)
- Primary CTA

**Copy**
- Title: "Who's this for?"
- Name field placeholder: "First name (optional)"
- ▲ Age chips: "Under 1" / "1–2" / "2–3" / "3–5"
- Tiny link: "Enter exact birthday instead"
- CTA: "Next"

**▲ Refinements**
- Simplified age chips from "0–6mo / 6–12mo / 1–2yr / 2–3yr / 3–5yr" to four options. Fewer choices = faster decision. The engine can infer sub-stages from behavior patterns over time.
- If "Skip" is tapped: default to 18-month profile. After first Reset: gentle nudge "Adding [child]'s age helps us pick better words for them."

---

### O3 — What brought you here (single question)

**Layout**
- Title
- Single-select chips (large, tappable)
- Primary CTA

**Copy**
- ▲ Title: "What's been hardest lately?"
- ▲ Chips: "Bedtime battles" / "Meltdowns" / "Big feelings" / "Just exploring"
- CTA: "Next"

**Routing**
- Bedtime battles → default tab is Sleep
- Meltdowns → default tab is Now
- Big feelings → default tab is Now
- Just exploring → default tab is Now

**▲ Why the copy changed**
- Old: "What brought you here?" — too open-ended, too therapeutic. Feels like intake at a counselor's office.
- New: "What's been hardest lately?" — validates that something IS hard. Chips are concrete situations, not abstract categories. "Bedtime battles" is more vivid than "Sleep." "Meltdowns" is what parents actually say instead of "Tantrums."

---

### O4 — Value promise

**Layout**
- Single line of text (large)
- Primary CTA

**Copy**
- ▲ Line: "Next time it gets hard, you'll know what to say."
- CTA: "Let's go"

**Action**
- CTA → Tab root (whichever tab was selected in O3)

**▲ Why the copy changed**
- Old: "Your first repair words are ready." — Promise about the app.
- New: Promise about the PARENT. Reframes the value from "we have content" to "you'll be equipped." This is the difference between a content app and a confidence-building tool.

---

## B) Tab Bar

**Layout**
- ▲ 3 tabs: Now · Sleep · Library
- Active tab: solid icon + label
- Inactive tabs: outline icon, no label
- No badge counts. No notification dots. The tab bar is calm.

**▲ Structural change from v1.4**
- v1.4 had: Reset · Sleep · Tantrum · Playbook (4 tabs)
- v2 has: Now · Sleep · Library (3 tabs)
- **Rationale:** "Tantrum" as a standalone tab forced parents to self-identify their crisis type before getting help. "Now" serves all crisis contexts (sleep, tantrum, regulation) through a single entry. "Playbook" is folded into Library alongside progress reflection. Family + Settings are overlays via the shell menu, not tabs.

**Tab purposes:**
- **Now** = "I need help right now" (reactive)
- **Sleep** = "Help me with sleep" (reactive tonight + proactive rhythm)
- **Library** = "Show me what's working" (reflection + saved words + proactive plays)

---

## C) Now Tab (Hero Flow)

**Design goal:** Emotional decompression → actionable words → optional regulation. The entire flow should feel like someone handing you exactly the right sentence at exactly the right time.

### N0 — Now Home

**Layout**
- ▲ Hero tile (largest, full-width): context-aware primary action
- ▲ Two secondary tiles below (half-width each)
- ▲ Tiny "I just need words" text link at bottom

**▲ Context-aware hero tile logic:**
- Default (no recent context): "I lost my cool" → Reset flow
- If bedtime window (1hr before configured bedtime to 6am): "Bedtime isn't working" → Sleep Tonight
- If a tantrum-context Reset was done in last 2 hours: "Still processing that" → new Reset with prior context carried
- If first time ever: "Start here" → Reset flow

**Hero tile copy examples:**
- "I lost my cool" (default)
- "Bedtime isn't working" (evening/night)
- "That was a big one" (post-tantrum context)
- "Start here" (first use)

**Secondary tiles:**
- ▲ Tile 1: "Meltdown just happened" → Reset with context=tantrum
- ▲ Tile 2: "I need to calm down" → Regulate flow (if enabled) or Moment

**▲ "I just need words" link:**
- Skips ALL context-gathering. Goes directly to two-script view (same as M1) with universal context.
- This is for the parent who knows exactly what happened and doesn't need a flow — they need a sentence in 2 seconds.
- Footer text, small, unobtrusive. But always present.

**▲ Major change from v1.4:**
- v1.4 Now tab (PlanHomeScreen) had 3 crisis tiles with "START HERE" branding. This was an app telling the parent what to do.
- v2 Now tab reads the parent's likely context and leads with the most relevant entry. The hero tile changes. This makes the tab feel responsive to the parent's life, not static.

---

### R1 — Reset: Acknowledge

**▲ THIS IS THE BIGGEST FLOW CHANGE IN THE SPEC.**

v1.4 sequence: Hold to vent (R1) → Pick who needs help (R2) → Card (R3)
v2 sequence: ▲ Who needs help (R1) → Card (R2) → Optional regulation (R3)

**Why:** A dysregulated parent asked to do a breathing exercise BEFORE getting help is a parent who closes the app. Acknowledge first, equip second, regulate third.

**Layout**
- ▲ Title (large, validating)
- ▲ Two large tiles
- No extra text

**Copy**
- ▲ Title: "Who needs help right now?"
- ▲ Tiles:
  - "Me" — routes to cards focused on self-compassion + the parent's emotional state
  - "My kid" — routes to cards focused on co-regulation + words to say to the child

**▲ Why the copy changed**
- Old: "What needs attention?" with "How I feel" / "How they feel" — too clinical. Parsed as cognitive triage rather than emotional first aid.
- New: "Who needs help right now?" with "Me" / "My kid" — direct, warm, zero parsing required. A parent can answer this in under a second.

**Action**
- Tap either tile → R2 (card reveal)

---

### R2 — Reset: Card Reveal (the value moment)

**Layout**
- Card appears with light slide-up + fade (200ms, ease-out)
- Card contains 2–3 blocks:
  1. ▲ **Acknowledgment** (1 line, smaller text, muted — normalizes what happened)
  2. **Words to say** (2 sentences max, large text, high contrast — the actual script)
  3. **One thing to do** (1 line, only if actionable — otherwise omit)
- Actions row below card

**Copy (structure, not literal)**
- ▲ Acknowledgment: "You yelled. That doesn't erase everything good you've done today."
- Words to say: "'I got too loud. I'm sorry. I still love you.'"
- One thing to do: "Sit near them for 30 seconds. That's enough."

**▲ Copy voice change**
- Old label "Wisdom" → new label "Acknowledgment." Wisdom implies the app is teaching. Acknowledgment implies the app understands.
- Old label "Repair" → new label "Words to say." Repair is jargon. "Words to say" is exactly what the parent wants.
- Old label "Next step" → new label "One thing to do." More specific. Implies one action, not a to-do list.

**Actions**
- Primary: "Keep" (saves to Library/Playbook)
- ▲ Secondary row: "Copy" · "Send" · "Another" · "Done"

**Refinements**
- ▲ Renamed "Close" to "Done" — "Close" implies shutting something down. "Done" implies completion, which feels better emotionally.
- "Another" logic: max 3 per session. After 3rd: button disappears. Tiny text: "That's the set for now."
- "Send" opens R4 (Send Card View) — see below.
- ▲ Pattern hint: If 3+ similar Resets in 7 days, show one small line above Acknowledgment: "You've been here before this week. That's normal." — acknowledges the pattern without preaching.
- Cards filtered by: context (sleep/tantrum/general) + R1 pick (me/kid) + child's developmental stage + style preference.

**After "Done"**
- ▲ If this was the parent's 1st or 2nd Reset: toast on tab root: "That's it. Come back anytime."
- ▲ Transition to R3 (optional regulation offer) — NOT directly to tab root.

---

### R3 — Reset: Regulation Offer (optional, post-card)

**▲ This screen is NEW. It replaces the old R1 hold-to-vent as the regulation moment.**

**Layout**
- Single sentence
- Two actions
- Auto-dismiss timer

**Copy**
- ▲ Line: "Need a minute for yourself?"
- Primary: "Breathe · 10s" → launches Moment (M0) with context carried from Reset
- Secondary: "I'm good" → return to tab root

**Behavior**
- If the parent taps "I'm good" 3+ times consecutively: stop showing R3 for 7 days. Respect the signal. Resume after 7 days. (Uses `CloseMomentSuppress` service.)
- ▲ If this is a Sleep-context Reset: the secondary text changes to "Back to sleep stuff" → returns to Sleep tab, not Now tab.

**▲ Why regulation moved here**
- The old flow gated value behind a regulation exercise. This flow delivers value first, then offers regulation as a gift. The parent has their words. Now they can choose to regulate if they want — or not. No pressure.

---

### R4 — Send Card View

**Layout**
- Fullscreen card, optimized for screenshot/share
- Warm branded background (not the dark Reset background)
- Subtle Settle watermark (bottom corner)
- Two actions

**Copy**
- Card shows Acknowledgment + Words to say only (no "One thing to do" on shareable version)
- ▲ Small line above card: "Send this to your partner"

**Actions**
- "Send" (opens native share sheet)
- "Back" (returns to R2 actions row)

**Share text format**
- ▲ Just the words. No branding in the message body. Tiny link at the end: "— from Settle"
- Example: "'I got too loud. I'm sorry. I still love you.' — from Settle"

---

### R5 — Style Discovery (post-3rd Reset, shown once)

Unchanged from v1.4. Trigger: after the user's 3rd Reset. Overlay on tab root.

**Copy**
- Title: "Quick question"
- Sub: "The words can lean more toward…"
- Option A: "Warmth first" (maps to Responsive)
- Option B: "Structure first" (maps to Structured)
- Dismiss: "No preference" (maps to blended/default)

---

### Soft friction interstitial (unchanged)

Trigger: 4+ Resets within 2 hours.
- "Quick pause."
- "You're using Settle a lot right now. That's okay."
- "Keep going" (primary) / "Take a break" (secondary → schedule 30-min push notification)

---

## D) Sleep Tab

**Design goal:** Tonight is the hero. Rhythm is background configuration. ▲ NEW: "This week's play" gives one proactive thing to try.

### S0 — Sleep Home

**Layout**
- Title: "Sleep"
- ▲ Hero section: "Tonight" — one large tile showing the MOST LIKELY scenario
  - If before bedtime: "Bedtime" tile
  - If 10pm–6am: "Night wake" or "Early wake" (based on time)
  - If no rhythm configured: "Set up your sleep rhythm · 30s"
- ▲ Below hero: "Other situations" row (the two non-hero tiles, smaller)
  - e.g., if hero is "Bedtime," row shows "Night wake" and "Early wake"
- ▲ NEW section: "This week" card (appears after 3+ days of use)
  - Single proactive play for the week
  - e.g., "Try this: same 3 words every night at lights-out. Repetition builds the cue."
  - Tap → expands to show the full play (2–3 lines + "Why this works" collapsible)
  - Changes weekly. Stage-appropriate. Context-appropriate.
- Rhythm summary (if configured) — passive, not interactive
  - "Wake ~6:30 · 1 nap · Bed ~7:15"
  - Edit link: "Edit rhythm"

**▲ Major changes from v1.4**
- Hero tile is context-aware (time-of-day determines which scenario is prominent)
- "This week" card introduces the proactive lane — one thing to try, not a curriculum
- All three scenarios still accessible, but the most relevant one is largest

---

### S1 — Tonight: Qualifier (▲ NEW)

**▲ This screen is NEW. The old spec skipped directly from tile to guidance steps.**

**Layout**
- Title
- 3–4 large tappable chips
- "Just give me the steps" skip link

**Copy (varies by scenario)**

**Bedtime qualifier:**
- ▲ Title: "What's happening?"
- Chips: "Won't stay in bed" / "Fighting sleep" / "Too wired" / "Crying at door"
- Skip: "Just give me the steps"

**Night wake qualifier:**
- ▲ Title: "What's going on?"
- Chips: "Won't stop crying" / "Keeps calling out" / "Got out of bed" / "I don't know, I'm just tired"
- Skip: "Just give me the steps"

**Early wake qualifier:**
- ▲ Title: "How early?"
- Chips: "Before 5am" / "5–6am" / "After 6am but too early"
- Skip: "Just give me the steps"

**▲ Why this screen exists**
- The old spec gave the same 3-step script regardless of situation. A parent whose kid is screaming at the door needs different words than a parent whose kid is quietly awake but won't settle. This one question makes the guidance feel personalized without adding burden — it's a recognition question ("which one is it?") not a diagnostic question ("analyze what's happening").
- "I don't know, I'm just tired" is a valid answer that routes to the most general guidance. It should never feel like a failure to pick this.

**Action**
- Tap chip → S2 (guidance steps, filtered by qualifier)
- Skip link → S2 (general guidance for the scenario)

---

### S2 — Tonight Guidance Steps (micro-flow)

Each qualifier routes to a **3-step max micro-flow.** Each step is one screen.

**Layout (each step)**
- Title (imperative verb — what to do)
- 1 short instruction line
- CTA: "Next" (steps 1–2) or "Done" (step 3)

**▲ Bedtime: "Won't stay in bed" example:**

**Step 1**
- ▲ Title: "Walk them back. No talking."
- Line: "Same action every time. Boring is the point."
- CTA: "Next"

**Step 2**
- ▲ Title: "If they come out again, say this."
- Large quoted text:
  > "It's bedtime. Back to bed."
- Below quote, muted: "No new words. No negotiation. Same sentence."
- CTA: "Next"

**Step 3**
- ▲ Title: "Pick your approach."
- Two selectable rows (radio-style):
  - "Stay in the hallway. Let them know you're close." ← highlighted if style = Warmth
  - "Close the door. Come back in 3 minutes." ← highlighted if style = Structure
- ▲ Tiny text: "Both work. Pick what feels right tonight."
- CTA: "Done"

**▲ Night wake: "Won't stop crying" example:**

**Step 1**
- ▲ Title: "Don't turn on lights."
- Line: "Keep your voice flat. You're a boring wall."
- CTA: "Next"

**Step 2**
- ▲ Title: "Say this, nothing else."
- > "Shh. It's sleep time. I'm here."
- CTA: "Next"

**Step 3**
- ▲ Title: "If they keep going."
- ○ "Hand on back. No eye contact. Wait it out."
- ○ "Leave the room. Come back in 5. Repeat."
- ▲ Tiny text: "They'll cry harder before they stop. That's normal."
- CTA: "Done"

**▲ Night wake: "I don't know, I'm just tired" example:**

**Step 1**
- ▲ Title: "You don't have to fix this."
- Line: "Go in. Do the minimum. Come back to bed."
- CTA: "Next"

**Step 2**
- ▲ Title: "Say one thing."
- > "It's still nighttime. Back to sleep."
- CTA: "Next"

**Step 3**
- ▲ Title: "Then come back here."
- Line: "You did enough. Tomorrow you can think about it."
- CTA: "Done"

**▲ Copy refinements**
- Every step 3 "Pick your approach" shows both options but pre-highlights the one matching style preference (R5). If no style set, neither is highlighted.
- All quoted scripts vary by developmental stage. A 10-month-old flow uses different language than a 3-year-old flow.
- ▲ The "I don't know, I'm just tired" path is deliberately gentler. Its job isn't to optimize — it's to get the parent back to bed with minimal guilt.

---

### S3 — Close Moment (end of every Tonight flow)

**Layout**
- Title
- One sentence
- Primary CTA
- Secondary link

**Copy**
- Title: "You handled it."
- ▲ Line: "Want 10 seconds for yourself before you go back?"
- Primary: "Breathe · 10s" → Moment (M0) with context=sleep
- ▲ Secondary: "I'm good" → return to Sleep tab

**▲ Copy changes**
- Old title: "Close the moment." — app-speak.
- New title: "You handled it." — affirming. Tells the parent they did something, not that they need to do more.
- Old CTA: "Reset · 15s" — too much time commitment and unclear what "Reset" means.
- New CTA: "Breathe · 10s" — concrete, shorter, and the word "breathe" has universal positive associations.

**Suppression**
- If parent taps "I'm good" 3+ times: stop showing S3 for 7 days.

---

### S4 — Rhythm Setup (30–60s, unchanged structure)

3-screen wizard:

**Step 1: Wake anchor**
- Title: "When does the day start?"
- Scrollable time selector, 15-min increments
- Default: 6:30 AM
- CTA: "Next"

**Step 2: Nap count**
- Title: "How many naps?"
- Stage-limited options as large tappable numbers
- Age-appropriate guidance text in muted style
- CTA: "Next"

**Step 3: Bedtime target**
- ▲ Title: "Bedtime around…"
- Smart default based on wake + nap count
- CTA: "Save"

**After save**
- Overlay on S0: "Rhythm set. Same thing every day — that's the whole strategy."
- Auto-dismiss 3s or tap anywhere.

---

## E) Moment (10s Brake)

**Design goal:** Fastest possible intervention. From activation to script in under 10 seconds. ▲ Also accessible in 2 seconds via "I just need words" fast path.

### M0 — Moment (haptic regulation)

**Activation sources**
- iOS lock screen widget
- In-app "I need to calm down" tile (Now tab)
- ▲ In-app "Breathe · 10s" CTA (from R3, S3)
- iOS Shortcut / Siri: "Hey Siri, Settle moment"
- ▲ "I just need words" fast path skips M0 entirely → goes to M1

**Layout**
- Dark screen (matches Reset aesthetic)
- Small label: "10 seconds" (top, muted)
- Center: slow pulse animation (circle that breathes)
- No text instructions. The pulse IS the instruction.

**Behavior**
- 10s haptic metronome (1 tap/second, gentle)
- At second 8: pulse fades
- At second 10: transition to M1
- ▲ If user taps screen during 10s: skip to M1 immediately.

**Context ladder (determines M1 content)**
1. Launched from specific context → use that context
2. Else: last flow context within 6 hours
3. Else: universal (no context)
4. Always stage-adapt to child's developmental level

---

### M1 — Two-Script Choice

**Layout**
- Two large tiles (full-width, stacked vertically)
- Each tile: label (large, bold) + script (large text)

**Copy (universal context, toddler stage)**

Tile 1:
- Label: "Boundary"
- Script: "'I won't let you do that. I'm right here.'"

Tile 2:
- Label: "Connection"
- Script: "'I can see you're upset. Come here.'"

**▲ Copy (sleep context, toddler stage)**

Tile 1:
- Label: "Boundary"
- Script: "'It's sleep time. I'll check on you soon.'"

Tile 2:
- Label: "Connection"
- Script: "'I know this is hard. I'm right outside.'"

**Interaction**
- Tap either tile → instant dismiss. No animation. Parent needs to act NOW.
- ▲ Footer (appears 1s after tiles, very small): "Need more? Reset · 15s"
  - Tapping opens Reset with whatever context was determined.

---

## F) Library Tab

**▲ MAJOR REDESIGN. This is where the proactive lane lives alongside the reflective lane.**

**Design goal:** Two jobs — "show me what's working" (reflection) and "help me make it better" (proactive). Neither should feel like homework. Both should feel like a calm friend sharing an observation.

### L0 — Library Home

**Layout**
- ▲ Section 1: "This week's focus" (proactive — appears after 3+ days of use)
- ▲ Section 2: "How it's going" (reflective — appears after 5+ Resets)
- Section 3: "Your words" (saved cards from Playbook)
- Section 4: "Learn more" (expandable Q&A)

**▲ Section 1: "This week's focus"**

A single card showing ONE thing to work on this week. Not a curriculum. Not a course. One focus.

**Layout**
- Card with title + 1–2 line description
- "Try this" CTA → expands inline to show the play
- ▲ Progress marker: "Day 3 of 7" (small, bottom of card) — not a progress bar, just a text label

**How focus is selected:**
- If Debrief data exists: focus on the most common trigger (e.g., "Transitions are hardest right now. This week: make transitions boring.")
- If Sleep Tonight used frequently: focus on sleep consistency (e.g., "This week: same 3 words at lights-out, every night.")
- If no pattern data: rotate through universal plays appropriate for the child's stage
- Changes every Monday. If the parent opens Library on a new week, the old focus is gone. No backlog. No guilt.

**Example focuses:**
- "This week: boring bedtime. Same words, same order, every single night."
- "This week: name the feeling first. Before you say no, say what they feel."
- "This week: the 2-minute wait. When they melt down, wait 2 minutes before going in."
- "This week: repair within the hour. After a tough moment, circle back before bed."

**Each focus expands to show:**
- The play (3–5 lines of specific, actionable guidance)
- "Why this works" (1–2 sentences of developmental reasoning, collapsible)
- ▲ "How it's going" micro-check (appears after Day 3): two tappable chips — "Getting easier" / "Still hard" — no form, no text input. This data informs next week's focus.

**▲ Section 2: "How it's going"**

NOT a dashboard. NOT stats. ONE sentence that reflects progress, shown when there's enough data to say something meaningful.

**Layout**
- Single line of text
- Tiny "See more" link → L1 (full reflection view)

**Copy examples (generated from local event data):**
- "You've had 3 fewer tough moments this week than last." — if reset count decreased
- "Bedtime has been under 30 minutes for 4 nights." — if sleep tonight usage decreased AND rhythm is configured
- "You haven't needed the night wake flow in 8 days." — if night wake usage dropped to zero
- "Transitions are still the trigger. That's okay — it takes a few weeks." — if pattern is persistent but focus is active
- ▲ "Not enough data yet. Keep going — we'll have something for you soon." — if insufficient data (shown once, then this section hides until there IS data)

**Rules for this section:**
- Never show if it would be discouraging (e.g., "You had more tough moments this week" is NEVER shown)
- Only show improvement or steady state, never regression
- If there's no improvement to report, show the focus instead, or hide the section entirely
- ▲ This is the "it's working" signal that keeps parents coming back. It must always feel good to read.

**Section 3: "Your words" (Playbook)**

Saved cards from Reset. Most recently kept first.

**Layout (cards exist):**
- Stacked card previews: Acknowledgment line + first line of Words to say
- Tap → L2 (full card view)
- ▲ If a saved card matches the current weekly focus: small tag "This week's focus" on the card

**Layout (empty state):**
- ▲ "Words you keep will live here. Try a Reset to get your first ones."
- Tappable → opens Reset

**Section 4: "Learn more"**

Expandable Q&A cards. Short, practical questions. Not articles.

**Examples:**
- "Why does my toddler hit when they're frustrated?"
- "Is it okay to let them cry?"
- "How long should bedtime take at this age?"

Each expands to 2–3 sentences. Stage-appropriate. Collapsible. Not a separate screen.

---

### L1 — Reflection View (▲ NEW)

**Reached from:** "See more" link in Section 2 of L0.

**Layout**
- ▲ Title: "Your progress"
- ▲ 3–5 reflection sentences (generated from local data, most recent first)
- ▲ "Patterns" section (appears after 5+ Resets with debrief data)
- "Done" CTA → back to L0

**Reflection sentences** are the same type as Section 2 but showing a longer history:
- "This week: 2 tough moments. Last week: 5."
- "Bedtime is averaging 25 minutes this week."
- "You've kept 7 cards. Your favorites: connection words."
- "Most common trigger: transitions. Your focus this week targets that."

**Patterns section:**
- Single summary sentence: "Transitions trigger most meltdowns. Bedtime is the second."
- ▲ Below: "This week's focus was chosen because of this pattern."
- Tap → shows the 2–3 "Prepare" cards most relevant to that pattern (same as v1.4's T3 cards, but accessed from Library instead of a standalone Tantrum tab)

**▲ Important:** This screen never shows numbers in a way that feels like a report card. No percentages. No "you're at level 3." Just human sentences.

---

### L2 — Card Detail View

**Layout**
- Full card (same as R2: Acknowledgment + Words to say + One thing to do)
- Actions row

**Actions**
- "Copy" · "Send" · "Done"
- Long-press → "Remove from saved?" confirmation (no visible delete button — prevents accidental deletion)

---

## G) Tantrum / Meltdown Flow (▲ RESTRUCTURED)

**▲ Tantrums no longer have their own tab.** They're accessed from the Now tab, either through the hero tile or the "Meltdown just happened" secondary tile. The flow is:

### Entry: From Now Tab

- Tap "Meltdown just happened" (or hero tile if context suggests tantrum)
- ▲ Goes directly to R1 (Reset: Acknowledge) with context=tantrum
- No intermediate "Take a breath first" screen — the old T1 added friction at the worst time

### Post-Reset: Debrief (conditional)

**Trigger (same as v1.4, tightened):**
1. User completed a Reset with context=tantrum, AND
2. It's the 2nd+ tantrum-context Reset in the same calendar day, AND
3. Debrief hasn't been shown today

**Layout**
- Title
- One question
- Single-select chips
- Primary CTA
- Skip link

**Copy**
- ▲ Title: "Want better words for next time?"
- ▲ Sub: "What set it off?"
- Chips: "Transition" / "Told no" / "Needed connection" / "Tired or hungry" / "Wanted control" / "Not sure"
- CTA: "Done"
- Skip: "Skip"

**▲ Refinement:** "Not sure" is treated with equal respect. If selected: "That's okay. We'll keep the words general."

**Action**
- Done → Now tab (N0)
- Debrief data stored locally. Informs weekly focus selection and "Prepare" card filtering.

### Prepare for Next Time (▲ moved to Library)

The old T3 "Prepare for next time" cards now live in the Library tab as part of the weekly focus system. When a parent's debrief data shows recurring triggers, the weekly focus targets that trigger with specific plays and scripts.

This means the parent doesn't have to remember to go to a "Tantrum" tab and tap "Prepare." Instead, the Library surfaces the right preparation at the right time.

---

## H) Proactive Plays System (▲ NEW)

**This is the engine behind the "This week's focus" and "Try this" features.**

### What is a Play?

A play is a specific, actionable thing to try for one week. It has:
- **Title:** Imperative, short (e.g., "Boring bedtime")
- **Description:** 1 line (e.g., "Same words, same order, every night this week")
- **The play:** 3–5 lines of specific guidance
- **Why it works:** 1–2 sentences of developmental reasoning
- **Duration:** Always 7 days. No extensions. No "you didn't finish."
- **Category:** Sleep / Meltdowns / General / Connection
- **Stage range:** Which developmental stages this applies to

### Play Selection Logic

Priority order:
1. If debrief data shows a dominant trigger in the last 14 days → play targeting that trigger
2. If Sleep Tonight used 3+ times in last 7 days → sleep-focused play
3. If parent's style preference is set → play aligned with that preference
4. Else: stage-appropriate universal play

### Play Lifecycle

- New play surfaces every Monday
- Old plays disappear without judgment — no "you didn't complete last week's focus"
- If the parent taps "Getting easier" on the mid-week check, next week's play escalates slightly (e.g., from "same words at bedtime" to "leave the room after the words")
- If the parent taps "Still hard," next week's play stays at the same level or pivots to a different approach for the same trigger
- ▲ No guilt mechanics. A parent who never checks in on their focus still gets a new one next week.

### Example Play Library (initial set)

**Sleep plays:**
- "Boring bedtime" — same 3 words, same order, every night
- "The boring walk-back" — when they get out of bed, walk them back silently
- "Split bedtime" — one parent does routine, other stays away (for two-parent homes)
- "Earlier bedtime" — move bedtime 15 minutes earlier for one week

**Meltdown plays:**
- "Name it first" — before you say no, say what they feel
- "The 2-minute wait" — wait 2 minutes before intervening
- "Transition warnings" — 5-minute and 1-minute warnings before every transition
- "After the storm" — repair within the hour, every time

**Connection plays:**
- "10 minutes of floor time" — 10 unstructured minutes, child leads
- "The morning yes" — say yes to the first request of the day
- "Bedtime repair" — one sentence before lights out: "I loved [specific thing] today"

**General plays:**
- "One less battle" — pick one daily conflict and stop fighting it for a week
- "The broken record" — pick one phrase for limits and use only that phrase
- "Bored is fine" — resist the urge to entertain for one week

---

## I) Settings

**Design goal:** Minimal. Settings correct things, not configure experiences.

### ST0 — Settings Home

**Layout**
- Simple list:
  - "Child" → ST1
  - "Parenting approach" → ST2
  - "Notifications" → ST3
  - "About Settle" → info screen
  - "Start over" → confirmation → clears data, restarts onboarding

---

### ST1 — Child Profile

- Name (editable)
- Age info (editable)
- Stage display: human-readable (e.g., "Young toddler · 14 months")
- Collapsed: "Stage doesn't seem right?" → manual override
- CTA: "Save"

---

### ST2 — Parenting Approach

**Copy**
- ▲ Title: "Your approach" (not "Parenting style" — less identity-loaded)
- Options: "Warmth first" / "Structure first" / "Mix of both"
- Current selection highlighted
- Brief explainers (collapsible):
  - Warmth first: "Words lean toward connection and comfort first."
  - Structure first: "Words lean toward clarity and consistency first."
  - Mix of both: "Depends on the situation."
- CTA: "Save"

---

### ST3 — Notifications

**Copy**
- Toggle 1: "Evening heads-up"
  - ▲ Description: "A nudge to prep for tonight. About an hour before bedtime."
- Toggle 2: "Weekly focus"
  - ▲ Description: "A Monday reminder with this week's thing to try."
- ▲ Toggle 3: "Progress check" (NEW)
  - Description: "A quick note when things are going well. Never more than once a week."
- All default ON.

**▲ Refinements:**
- Evening heads-up time: auto-set to 1 hour before configured bedtime. If no rhythm, defaults to 6pm.
- Weekly focus notification: Monday at 9am.
- Progress check: only fires when there's genuine positive data to share. NEVER fires with negative data. Max once per week.

---

### ST4 — Stage Transition Banner (non-blocking, unchanged)

- Banner at top of any tab when child crosses a stage boundary.
- "[Name] is growing. Update to [new stage]?"
- "Update" / "Not yet" (reappears in 2 weeks)
- If exact birthdate known AND transition unambiguous: auto-update + toast.

---

## J) Cross-Surface Micro-Interactions

### "Keep" feedback
- On Keep (R2): toast "Saved to your words" (2s, bottom)
- Toast is tappable → opens Library directly to that card
- Haptic: single light tap

### "Send" flow
- On Send (R2 or L2): opens R4, then native share sheet
- Pre-populated text: just the words. No branding in body. Tiny link at end.

### ▲ Playbook resurfacing (high confidence)
- On R2 card reveal: if a previously saved card matches current context with high confidence:
  - Show tiny line below actions: "Worked before: [card title]"
  - Tap → mini-preview (not full Library)
- Threshold: card was kept AND used in similar context at least twice in last 14 days.

### Co-parent prompt (after 5th Reset, shown once)
- "Does someone else help with [child name]?"
- "Invite them" (native share with app store link)
- "Just me" (dismisses permanently)

### ▲ Progress toast (NEW, rare)
When the parent opens the app and there's positive progress to share (checked locally):
- Toast at top of whatever tab they land on: "4 days without a night wake. Keep going."
- Auto-dismiss 4s. Not tappable.
- Max frequency: once per week. Only positive data.
- If no positive data: no toast. Silence is respect.

---

## K) State Machine Notes

### Reset flow states (▲ resequenced)
```
N0_TAP_TILE → R1_ACKNOWLEDGE (who needs help)
R1_ACKNOWLEDGE → (tap_me | tap_kid) → R2_CARD_REVEAL
R2_CARD_REVEAL → (keep) → SAVE_TO_LIBRARY → R3_REGULATION_OFFER
R2_CARD_REVEAL → (another, count < 3) → R2_CARD_REVEAL (new card)
R2_CARD_REVEAL → (another, count >= 3) → R2_CARD_REVEAL (another hidden)
R2_CARD_REVEAL → (send) → R4_SEND_VIEW → R2_CARD_REVEAL
R2_CARD_REVEAL → (done) → R3_REGULATION_OFFER
R3_REGULATION_OFFER → (breathe) → M0_MOMENT → TAB_ROOT
R3_REGULATION_OFFER → (im_good) → TAB_ROOT
R3_REGULATION_OFFER → (suppressed) → TAB_ROOT (skip R3 entirely)
```

### Sleep Tonight flow states (▲ qualifier added)
```
S0_TAP_TILE → S1_QUALIFIER (what's happening?)
S1_QUALIFIER → (tap_chip | skip) → S2_STEP_1
S2_STEP_1 → S2_STEP_2 → S2_STEP_3 → S3_CLOSE_MOMENT
S3_CLOSE_MOMENT → (breathe) → M0_MOMENT (context=sleep)
S3_CLOSE_MOMENT → (im_good) → S0_HOME
S3_CLOSE_MOMENT → (suppressed) → S0_HOME (skip S3)
```

### Tantrum flow states (▲ simplified)
```
N0_TAP_MELTDOWN → R1_ACKNOWLEDGE (context=tantrum)
  → (complete_reset) → DEBRIEF (if conditions met) → N0_HOME
  → (complete_reset, no debrief) → R3_REGULATION_OFFER → TAB_ROOT
```

### Moment flow states (unchanged)
```
M0_ACTIVATED → (10s_complete | tap_skip) → M1_SCRIPT_CHOICE
M1_SCRIPT_CHOICE → (tap_tile) → DISMISS
M1_SCRIPT_CHOICE → (tap_later_reset) → R1_ACKNOWLEDGE (context from ladder)
```

### ▲ Fast path states (NEW)
```
N0_TAP_JUST_NEED_WORDS → M1_SCRIPT_CHOICE (universal context)
M1_SCRIPT_CHOICE → (tap_tile) → DISMISS
```

### ▲ Weekly focus lifecycle (NEW)
```
MONDAY → NEW_FOCUS_GENERATED (from play library + pattern data)
DAY_1-2 → FOCUS_VISIBLE (Library Section 1)
DAY_3 → MICRO_CHECK_APPEARS ("Getting easier" / "Still hard")
DAY_4-7 → FOCUS_VISIBLE (with check result stored)
NEXT_MONDAY → OLD_FOCUS_DISCARDED → NEW_FOCUS_GENERATED
```

---

## L) Event Tracking (minimal, privacy-first, local-only)

All events local-only. No server. No analytics SDK.

| Event | Data stored | Purpose |
|-------|------------|---------|
| reset_complete | timestamp, context, who_pick (me/kid), card_id, action (keep/done/another) | Card engine, pattern detection |
| tonight_complete | timestamp, scenario, qualifier, style_choice | Script personalization |
| debrief_complete | timestamp, category | Weekly focus selection, pattern detection |
| moment_complete | timestamp, context, choice (boundary/connection) | Script relevance |
| card_saved | timestamp, card_id | Library population |
| card_sent | timestamp, card_id | Viral loop (future) |
| rhythm_configured | timestamp, wake/nap/bed values | Sleep guidance |
| style_set | timestamp, style | Card filtering |
| ▲ focus_viewed | timestamp, focus_id | Weekly focus engagement |
| ▲ focus_check | timestamp, focus_id, result (easier/still_hard) | Next week's focus selection |
| ▲ fast_path_used | timestamp | Usage pattern for "just need words" |
| ▲ qualifier_selected | timestamp, scenario, qualifier | Script personalization |

No event is required for the app to function. If storage fails, app still works with universal content.

---

## M) First-Run Experience Summary

1. O1 (Welcome) → O2 (Child basics) → O3 (What's been hardest) → O4 (Value promise)
2. Land on default tab (based on O3)
3. User taps into first flow (Reset from Now, or Sleep Tonight)
4. ▲ Complete flow → regulation offer (optional) → first card saved
5. Tab root shows toast: "That's it. Come back anytime."
6. ▲ Day 3: "This week's focus" appears in Library

**Time to first value: under 60 seconds** (including onboarding).
**Time to first proactive play: 3 days.**

---

## N) Migration Notes (v1.4 → v2)

| v1.4 Concept | v2 Concept | Change type |
|-------------|-----------|-------------|
| Reset tab | Now tab | Renamed + restructured |
| Tantrum tab | Removed (merged into Now) | Structural |
| Playbook tab | Library tab, Section 3 | Merged |
| R1 hold-to-vent | Removed (regulation moved to R3) | Resequenced |
| R2 state pick | R1 acknowledge ("Me" / "My kid") | Simplified + moved earlier |
| R3 card reveal | R2 card reveal | Same content, new labels |
| T1 "Take a breath first" | Removed (direct to Reset) | Removed |
| T3 "Prepare for next time" | Library weekly focus + plays | Elevated |
| S1 (eliminated in v1.4) | S1 qualifier (restored as new screen) | Added |
| No progress reflection | Library "How it's going" section | Added |
| No proactive guidance | Weekly focus + plays system | Added |
| "Repair words" copy | "Words to say" copy | Rewritten |
| "Wisdom" card label | "Acknowledgment" label | Renamed |
| "Close" action | "Done" action | Renamed |

---

## O) Canon Changes Required

This spec requires approval for two canon modifications:

### Canon #1: Product identity expansion
- **Current:** "Settle is a post-moment recovery tool."
- **Proposed:** "Settle is a post-moment recovery tool with a proactive guidance lane. The reactive loop (event → Reset → repair → save → Playbook → internalize) remains the hero. The proactive lane (weekly focus + plays) helps parents reduce the frequency and duration of hard moments over time."
- **Rationale:** Recovery without progress makes Settle a band-aid. Parents want fewer hard moments, not just better recovery from them. The proactive lane respects all existing constraints (no courses, no homework, no dashboards) while adding forward-looking value.

### Canon #6: Onboarding copy update
- **Current:** "Onboarding has exactly 4 screens: Welcome → Child basics → Why you're here → Value promise."
- **Proposed:** "Onboarding has exactly 4 screens: Welcome → Child basics → What's been hardest → Value promise. Copy for each screen follows WIREFRAMES_V2.md."
- **Rationale:** Structure unchanged. Copy improved to use parent voice instead of product voice.

All other 11 canon decisions are fully respected by this spec.
