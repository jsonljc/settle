# Settle — UX Rules

> These are laws, not guidelines. Every screen, every PR, every agent task must pass these checks. If a screen violates a rule, it ships broken.

**See also:** [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) (visual tokens), [wireframes/WIREFRAMES.md](wireframes/WIREFRAMES.md) (screen layouts), [CANON.md](CANON.md) (precedence).

---

## The 7 Laws

### 1. One action per screen

Every screen has exactly one primary action. The user should never wonder "what do I do here?"

**What this means:**
- One visually dominant CTA (SettleButton primary)
- Secondary actions are allowed but must be visually quieter (ghost buttons, text links, small chips)
- If a screen has two equally prominent buttons, one of them needs to be demoted
- "Close" is always secondary, never primary

**Fail test:** Cover the primary CTA with your thumb. Can the user still complete the screen's purpose? If yes, your primary CTA is wrong.

---

### 2. 15-second value

From the moment a user enters any flow, they must receive something useful within 15 seconds. Not a loading state. Not a setup step. Actual value — words they can say, a thing they can do.

**What this means:**
- Reset: hold 3–5s → state pick → card. Under 15s to first repair language.
- Moment: 10s haptic → two scripts. Under 15s to actionable words.
- Sleep Tonight: tap tile → first guidance step. Under 5s to first instruction.
- Tantrum Just Happened: tap → Reset entry. Under 5s to the Reset flow.

**Fail test:** Start a timer when the user taps into a flow. If 15 seconds pass without the user seeing words they can use or an action they can take, the flow is too long.

---

### 3. No dense text

Maximum 2–3 short lines per content block. If you're writing a paragraph, rewrite it as one sentence.

**What this means:**
- Card Wisdom: 1 line
- Card Repair: 2 sentences max
- Card Next step: 1 line (or omit)
- Screen instructions: 1 line
- Toast messages: under 6 words
- "Why this works" expanded: 2 sentences max

**Fail test:** If a content block takes more than 3 seconds to read at 3am with blurry eyes, it's too long.

---

### 4. No forms

O2 (child name + age) is the only screen in the entire app with input fields. Every other interaction is taps and selections.

**What this means:**
- Chips, not text inputs
- Time selectors, not text fields
- Single-select taps, not dropdowns
- Toggles, not checkboxes with labels

**Fail test:** Does the screen require a keyboard to appear? If yes (and it's not O2), redesign it.

---

### 5. No dashboards

No charts, counters, streaks, scores, progress bars, or analytics of any kind. Anywhere. Ever.

**What this means:**
- Playbook shows cards, not stats about cards
- Sleep shows guidance, not sleep data
- Tantrum shows scripts, not tantrum frequency
- Patterns are expressed as one sentence ("Transitions are tough this week"), not as a chart
- No number badges on tabs
- No "you've used Settle X times" anywhere

**Fail test:** Does the screen contain a number that goes up over time? Remove it.

---

### 6. Close moment is universal

Every guided flow ends with the Close moment pattern (or a direct equivalent). No flow leaves the user in a dead end.

**What this means:**
- Sleep Tonight → S3 Close moment ("Want a quick repair?")
- Tantrum Just Happened → Reset → Close (built into Reset flow)
- Reset → R3 card → Close (haptic punctuation, return to tab root)
- Moment → M1 script tap → instant dismiss
- Even settings flows end with "Save" → return to settings root

**Fail test:** Can the user reach a state where no action is available and no exit is visible? If yes, the flow is broken.

---

### 7. Post-situation first

Settle serves parents AFTER the hard moment, not during it (with the narrow exception of Moment). Every flow assumes the crisis has peaked and the parent is ready for repair.

**What this means:**
- Reset opens after yelling, not to prevent yelling
- Sleep Tonight opens when the child is awake at 3am, not to plan bedtime 8 hours early
- Tantrum "Just happened" means it just happened, not "is happening right now"
- Copy never says "while your child is crying, do X" — it says "now that it's calmer, say X"
- Moment is the only exception: it intervenes in-the-moment, but even Moment is designed to be over in 10 seconds

**Fail test:** Does the screen's copy assume the parent is mid-crisis with a screaming child? If yes, rewrite for post-crisis. The only exception is Moment, and Moment has no text instructions.

---

## Operational Checks (apply to every screen)

### Content hierarchy check

Every screen's content must follow this priority order:

1. **What to do** (the action or the words)
2. **Why it matters** (only if it fits in 1 line — usually omit)
3. **What's next** (the CTA or the exit)

If "why it matters" is pushing the screen past 3 content blocks, cut it.

### Emotional safety check

Before shipping any screen, ask:

- Could this make a guilty parent feel worse? → Rewrite.
- Could this feel like homework? → Simplify.
- Could this feel like judgment? → Soften.
- Could this feel like a quiz? → Remove the question or make it clearly optional.
- Could a sleep-deprived parent misread this at 3am? → Clarify.

### Copy voice check

Every piece of copy must pass these filters:

- Calm > clever
- Warm > smart
- Quiet > motivational
- Dignified > cute
- Direct > hedging
- Short > thorough

If the copy sounds like it was written by a wellness brand's marketing team, rewrite it. Settle speaks like a calm friend who's been through this, not a coach or a therapist.

### Night mode check

Every screen must be tested in:
- Dark mode at minimum brightness
- Bright room and dim room
- One-handed use (right hand, left hand)

Reset and Moment screens use forced dark regardless of system theme and must be comfortable to look at in a pitch-dark room at 3am.

---

## Anti-Patterns (never build these)

| Anti-pattern | Why it's banned | What to build instead |
|-------------|-----------------|----------------------|
| Streak counter | Creates guilt on missed days | Nothing — absence is healthy |
| Daily check-in prompt | Adds to parent's mental load | Evening check-in (1hr before bed) only |
| "You haven't opened the app in X days" | Shame mechanic | Nothing — silence is respect |
| Progress bar | Implies a destination; parenting has none | Nothing |
| Star rating on cards | Gamifies emotional support | "Keep" is the only signal |
| Before/after comparison | Implies the parent was failing before | Pattern sentence (one line, rare) |
| Onboarding tutorial overlay | Adds steps before value | Inline first-use tooltips (disappear after 1 use) |
| Confirmation dialogs for safe actions | Slows down a stressed user | Toast feedback instead |
| Multi-step modals | Cognitive overload in a stressed state | One question per screen, max |
| Skeleton loading screens | Feels like waiting for a slow product | Centered pulse animation |
