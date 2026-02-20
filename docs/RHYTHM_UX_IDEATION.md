# Rhythm as time schedule — UX ideation (no code)

**Goal:** Better ways to show "rhythm" so it reads clearly as a **time schedule** (what happens when) with low cognitive load for tired parents.

---

## 1. Visual metaphors

- **Horizontal timeline**  
  A single line (or bar) for "today" with marks for wake, first nap, second nap, bedtime. Optional: a "you are here" dot or shaded "next window" so the eye goes to "what’s next" instead of scanning a list.

- **Sun → moon arc**  
  Day shown as an arc: sun (wake), then segments for morning / midday / afternoon / evening, moon (bedtime). Communicates "through the day" in one glance; times can sit on or under the arc.

- **Stacked windows (vertical)**  
  Keep the list but make each row feel like a **time window** (e.g. "9:00–9:45 · Late morning nap") with a subtle bar or block showing length or position in the day. Reinforces "window" not "single clock."

- **Clock face or dial**  
  Single 12/24h circle with a few key anchors (wake, nap, bed). Works for "where we are in the day" but can be heavy; better as an optional "see full day" view than the default.

---

## 2. Emphasize "what’s next" and "now"

- **Next-up first**  
  Lead with one line: "Next: Early afternoon nap around 1:35 PM" (or "Now: Nap window"). Full schedule (wake, naps, bed) below or behind "see full schedule." Reduces scanning when the main question is "what do I do next?"

- **Time-until-next**  
  Add relative time: "Next up: Early afternoon nap in ~2 hours" or "Nap window starts in 45 min." Helps with "do I have time to X before the next thing?"

- **Now / next / later**  
  Three buckets: "Now" (current window or "between windows"), "Next" (next anchor + time), "Later" (rest of day). Schedule becomes "now → next → later" instead of a flat list.

---

## 3. Chunk by part of day (not just anchors)

- **Morning / Afternoon / Evening blocks**  
  Group under labels like "Morning" (wake + first nap), "Afternoon" (nap(s)), "Evening" (wind-down, bedtime). Parents often think in "morning vs afternoon" more than "9:30 vs 1:35."

- **Windows, not only times**  
  Show ranges: "Nap window 9:15–10:00" or "Aim for nap by 9:30." Keeps the "flexible window" mental model and reduces stress about hitting one exact time.

- **"Focus for this part of day"**  
  One short line per block: e.g. "Morning: Protect first nap window." "Evening: Wind down by 7." Schedule becomes "what to focus on when" not only "when."

---

## 4. Density and framing

- **One-line rhythm**  
  Smallest form: "Wake 7 · Nap ~9:30 · Bed 7:30" or "7a → 9:30a nap → 7:30p bed" for headers or secondary spots. Full card only where we want detail.

- **Expandable card**  
  Default: next-up + one-line summary. Tap to expand to full schedule (wake, naps, bed, confidence). Good for Home: glanceable when collapsed, full schedule when needed.

- **Rename for schedule**  
  "Today rhythm" → "Today’s schedule," "Daily windows," or "Your day" so the word "schedule" or "day" primes time-based reading.

---

## 5. Context-aware emphasis

- **Time-of-day**  
  Morning: emphasize wake + first nap. Midday: emphasize nap window(s). Late afternoon/evening: emphasize bedtime and wind-down. Same data, different first line or order.

- **Confidence in line**  
  Instead of "How sure are we? Low" as separate copy, bake it into the schedule: e.g. lighter or italic for low-confidence windows, or a small "est." next to times we’re less sure about.

---

## 6. Placement and hierarchy

- **Hero on Home**  
  Rhythm as the main "your day" block on the Now tab (one card or strip). Everything else (help now, plan, etc.) below. Aligns with "rhythm is the daily home."

- **Strip vs card**  
  "Strip": single compact row (e.g. timeline or one-line) that can sit under the header. "Card": current rounded block. Strip = lighter; card = more space for next-up and CTA.

- **Sleep tab**  
  If Sleep becomes "tonight" only, rhythm summary could be a small "Today: 7a · 9:30a nap · 7:30p bed" with "See full schedule" → Home or a dedicated rhythm screen. Avoids duplicating the full card.

---

## 7. Micro-ideas (quick wins)

- **Colored dots or tags**  
  Small indicator (e.g. green = on track, amber = window opening soon) next to the next anchor so the schedule feels alive, not static.

- **"Repeat through the week"**  
  Keep this line but optionally add "Same times tomorrow" or "Next 7 days" so "rhythm" clearly means "repeating schedule."

- **Progress through the day**  
  Thin progress bar: "You’re here" (e.g. 40% through the day). Complements the list by answering "how far through today?"

---

## Suggested directions (for prioritization)

1. **Next-up first + one-line summary** — Minimal change: reorder so "Next: …" is first; add a single summary line (e.g. "7a · 9:30a nap · 7:30p bed") for scanability.
2. **Horizontal timeline or arc** — Strong "time schedule" metaphor; good for a dedicated rhythm view or expanded card.
3. **Morning / Afternoon / Evening chunks** — Matches how parents talk; can sit on current card or a strip.
4. **Expandable card on Home** — Collapsed = next-up + one line; expanded = full schedule + confidence + CTA. One component, two densities.

No code in this doc; use as a backlog for design and implementation.
