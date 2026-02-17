# Settle — Final Direction (v1.4 Locked)

## Core identity (do not change)

> **Settle is a post-moment recovery tool that reduces parent mental load.**

Not a crisis app.
Not a tracker.
Not a parenting encyclopedia.
Not a meditation product.

It exists to:

- close the loop after hard moments
- give repair words fast
- quietly improve future behavior

Everything else is secondary.

---

## 1. Product Spine (locked)

**Hero loop**

```
event happens → Reset → repair → save → Playbook → next time is easier
```

Reset is the center of gravity.

Sleep and Tantrum feed Reset.
Playbook preserves learning.
Moment is a small emergency brake — not the core loop.

**How the loop actually works:**

The parent receives repair language in the moment. They save what resonates. Over days and weeks, the same phrases resurface — through Playbook, through "Worked before" prompts, through co-parent sharing. Repetition builds automatic responses. The parent stops needing the card because the words have become their own.

This is not passive. The mechanism is: encounter → save → re-encounter → internalize.

The loop succeeds when the parent no longer needs it.

---

## 2. Reset = sacred ritual (do not bloat)

Reset must remain:

- short
- finishable
- emotionally safe
- zero homework
- zero analysis

It is not a coaching session.
It is a closure ritual.

**Final Reset rules:**

- max 3 "Another" swaps per session; then the option disappears
- soft friction at 4+ resets within 2 hours (not before)
- universal tone → personalized tone over time (driven by style preference + stage)
- pattern hint only when confident (3+ similar resets in 7 days)
- clean haptic closure on exit
- card content varies across three axes: context (sleep/tantrum/general), state pick (self/child), and developmental stage

No additional features go into Reset.
If something doesn't fit in 15 seconds, it does not belong.

---

## 3. Sleep = optimization lane, not dashboard

Sleep exists to reduce nightly chaos.

It is:

- **Tonight** (reactive) — the hero surface. Three situations: bedtime, night wake, early wake. Each is a 3-step max micro-flow ending in a close moment.
- **Rhythm** (proactive) — a one-time background configuration (wake time, nap count, bedtime target) that improves Tonight's guidance quality. Rhythm is not an interactive lane. It is a passive setting that surfaces as a summary line on the Sleep tab.

Tonight IS the Sleep tab. Rhythm lives underneath it.

Methods (responsive/structured) affect copy and defaults only.
They do not create branching flows.

Sleep never becomes:

- charts
- streaks
- analytics
- sleep score
- history screens

It stays tactical.

---

## 4. Tantrum = debrief & prevention

Tantrum is not meltdown control.

It is:

- post-event emotional processing → next-time preparation

**Structure:**

- Just happened → Reset (context=tantrum)
- Optional debrief (shown max once per day, only on 2nd+ tantrum-context Reset that calendar day)
- Prepare for next time → 3 cards max, filtered by stage + debrief category

No long theory.
No education rabbit holes.
"Why this works" stays collapsed.

Tantrum helps the parent regulate themselves,
not "fix" the child.

---

## 5. Moment = emergency brake (realistic scope)

Moment is intentionally small.

It is not a feature system.
It is a reflex tool.

**Final Moment design:**

- 10s silent haptic regulation
- two-choice script (Boundary / Connection)
- tap → close
- optional "Later: Reset · 15s"

**Primary use case:** bedtime and night — but not limited to it. Moment uses a context ladder:

1. Launched from a specific screen → use that context
2. Else last flow context within 6 hours
3. Else universal (no context assumed)
4. Always stage-adapt language

**Activation:**

- lock screen widget (primary — the killer surface)
- in-app chip (from Sleep and Tantrum flows)
- optional app shortcut / Siri

Moment is expected to be used sometimes, not constantly.

Success metric is:
**when it works, it prevents escalation**

Not:
daily engagement

---

## 6. Playbook = sanctuary, not archive

Playbook is:

- saved relief
- not a history log
- not performance tracking

**Playbook holds two content types:**

1. **Repair cards** — saved from Reset (the words to close a moment)
2. **Prevention cards** — saved from Tantrum's "Prepare for next time" (the words to prevent the next one)

Both are valuable. Both are surfaced by recency and relevance, not frequency.

Playbook surfaces:

- saved cards (most recently kept first)
- "Worked before" (high-confidence re-suggestions based on repeated use in similar contexts)
- pattern sentences (only when 5+ resets with debrief data support a confident claim — e.g., "Transitions are the most common trigger this week")

It occasionally affirms:

*You've been showing up.*

No numbers.
No streaks.
No score.

It affirms effort, not performance.

---

## 7. Sharing & co-parenting

Settle is built for one parent but designed to extend to two.

**Core sharing mechanic:** Any card (repair or prevention) can be sent to a co-parent via native share sheet. The shared content is the repair language only — no app chrome, no branding beyond a small link. The co-parent receives words they can use tonight, not an advertisement.

**Co-parent invite:** After the 5th Reset, the app asks once: "Does someone else help with [child name]?" with an option to share an app store link. This is Settle's primary organic acquisition mechanic.

**Architecture implication:** v1 is fully local — no sync, no shared accounts, no family plan backend. Sharing works through native OS share sheets. Co-parent features (shared Playbook, family accounts) are a v2 consideration and do not influence v1 architecture decisions.

Sharing is never forced. A solo parent should never feel like they're missing a feature.

---

## 8. Notifications philosophy

Settle does not chase attention.
It whispers, rarely.

**Allowed:**

- evening check-in (timed to 1 hour before configured bedtime, or 6pm default)
- rare gentle nudge after a pattern is detected (e.g., "Transitions have been tough this week. Here's a card for next time.")

**Never:**

- daily nudges
- streak pressure
- "we miss you"
- panic language
- anything that adds to the parent's mental load

Parents are overloaded already.
The app must not become another demand.

---

## 9. Parenting style (how personalization works)

Settle does not ask parents to self-identify during onboarding. Style is discovered after the parent has used the app enough to have context.

**Discovery:** After the 3rd Reset, the app asks once: "The repair words can lean more toward… Warmth first / Structure first / No preference."

**What style affects:**

- Card selection emphasis (connection-first vs. clarity-first)
- Sleep Tonight step 3 option highlighting
- Tantrum prevention card ordering

**What style does not affect:**

- Available content (both styles always see both options)
- App structure or navigation
- Anything visible as a "mode" or "setting" (style is a quiet filter, not a personality)

Style can be changed anytime in Settings. Default is blended.

---

## 10. What Settle explicitly refuses to become

Lock this. It protects the product.

Settle will never become:

- a behavior tracker
- a sleep analytics dashboard
- a parenting course
- a meditation app
- a crisis hotline interface
- a streak system
- a guilt engine
- a productivity tool
- a social feed
- a gamified parenting app
- a form-heavy onboarding experience
- a dashboard with charts or counters

It is relief + repair + prevention.
That's the moat.

---

## 11. Emotional tone (brand lock)

Settle is:

- calm > clever
- warm > smart
- quiet > motivational
- dignified > cute

Humor exists, but never at the child's expense.
Never sarcastic.
Never meme-y.

Language rules:

- "Parenting style" not "sleep style" — one term everywhere
- "Evening check-in" not "evening repair reminder" — repair implies something is broken
- "Just happened" not "After" — emotionally accurate
- "I'm good" not "Not now" — affirming, not deferring
- "Another" not "Different one" — shorter, less fussy
- "Send" not "Share" — active verb, implies sending to a specific person

Parents are vulnerable here.
Tone must protect them.

---

## 12. The real success metric

Not DAU.
Not time in app.

Success looks like:
**parents need Settle less over time**

If a parent says:

*I haven't opened it in weeks because things are smoother*

That's a win.

The intermediate metrics that matter:

- Time to first kept card (should be under 90 seconds from app install)
- Cards sent to co-parent (viral loop health)
- Return after 7-day gap (the app is useful enough to come back to, even without habit pressure)
- Playbook "Worked before" resurfacing rate (the learning loop is functioning)

This is anti-addictive by design.
That's rare. That's trust.

---

## 13. Technical boundaries (for implementation)

These rules prevent scope creep at the code level:

- **v1 is local-only.** No server, no sync, no accounts. All data lives on device.
- **Events are stored locally.** Lightweight events (timestamp + category + card_id) power personalization. No analytics SDK. No server logging.
- **If storage fails, the app still works.** Personalization degrades gracefully — the app falls back to universal content.
- **No onboarding forms beyond child basics.** O2 (name + age) is the only screen with input fields. Every other interaction is taps and selections.
- **Every flow must end.** No open-ended states. Every entry has an exit. Close moment is the universal exit pattern.
- **Stage is derived, not configured.** Developmental stage comes from the child's age. Manual override exists in Settings but is buried. The app never asks the parent to assess their child's development.
