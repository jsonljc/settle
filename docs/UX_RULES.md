# Settle — UX Rules

> Guidance for interaction and content. Screens and flows should align with these where applicable.

**See also:** [wireframes/WIREFRAMES.md](wireframes/WIREFRAMES.md) (screen layouts), [CANON.md](CANON.md) (precedence).

---

## Value and Flow

### 15-second value

From the moment a user enters any flow, they should receive something useful within 15 seconds. Not a loading state. Not a setup step. Actual value — words they can say, a thing they can do.

- Reset: hold 3–5s → state pick → card. Under 15s to first repair language.
- Moment: 10s haptic → two scripts. Under 15s to actionable words.
- Sleep Tonight: tap tile → first guidance step. Under 5s to first instruction.
- Tantrum Just Happened: tap → Reset entry. Under 5s to the Reset flow.

### No forms (except O2)

O2 (child name + age) is the only screen in the entire app with input fields. Every other interaction is taps and selections.

- Chips, not text inputs
- Time selectors, not text fields
- Single-select taps, not dropdowns
- Toggles, not checkboxes with labels

### No dashboards

No charts, counters, streaks, scores, progress bars, or analytics of any kind. Anywhere. Ever.

- Playbook shows cards, not stats about cards
- Sleep shows guidance, not sleep data
- Tantrum shows scripts, not tantrum frequency
- Patterns are expressed as one sentence ("Transitions are tough this week"), not as a chart
- No number badges on tabs
- No "you've used Settle X times" anywhere

### Close moment is universal

Every guided flow ends with the Close moment pattern (or a direct equivalent). No flow leaves the user in a dead end.

- Sleep Tonight → S3 Close moment ("Want a quick repair?")
- Tantrum Just Happened → Reset → Close (built into Reset flow)
- Reset → R3 card → Close (haptic punctuation, return to tab root)
- Moment → M1 script tap → instant dismiss
- Even settings flows end with "Save" → return to settings root

### Post-situation first

Settle serves parents AFTER the hard moment, not during it (with the narrow exception of Moment). Every flow assumes the crisis has peaked and the parent is ready for repair.

- Reset opens after yelling, not to prevent yelling
- Sleep Tonight opens when the child is awake at 3am, not to plan bedtime 8 hours early
- Tantrum "Just happened" means it just happened, not "is happening right now"
- Copy never says "while your child is crying, do X" — it says "now that it's calmer, say X"
- Moment is the only exception: it intervenes in-the-moment, but even Moment is designed to be over in 10 seconds

---

## Operational Checks (apply where applicable)

### Emotional safety

Before shipping any screen, ask:

- Could this make a guilty parent feel worse? → Rewrite.
- Could this feel like homework? → Simplify.
- Could this feel like judgment? → Soften.
- Could this feel like a quiz? → Remove the question or make it clearly optional.
- Could a sleep-deprived parent misread this at 3am? → Clarify.

### Copy voice

Every piece of copy should pass these filters:

- Calm > clever
- Warm > smart
- Quiet > motivational
- Dignified > cute
- Direct > hedging
- Short > thorough

Settle speaks like a calm friend who's been through this, not a coach or a therapist.

### Night mode check

Every screen should be tested in:

- Dark mode at minimum brightness
- Bright room and dim room
- One-handed use (right hand, left hand)

Reset and Moment screens use forced dark regardless of system theme and should be comfortable to look at in a pitch-dark room at 3am.

---

## Anti-Patterns (avoid)

| Anti-pattern | Why it's discouraged | What to build instead |
|-------------|----------------------|------------------------|
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
