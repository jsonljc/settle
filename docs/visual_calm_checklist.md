# Calm Design Checklist

Use this checklist for PR reviews that touch parent-facing UI.

## CTA Hierarchy

- Exactly one primary action is visible per viewport section.
- Secondary actions are either chips, text links, or behind a disclosure panel.
- Optional actions are labeled with `(optional)` when they can be deferred.

## Layout and Density

- Keep paragraph copy to 1-2 short sentences.
- Prefer one card per decision step; collapse non-critical details.
- Default spacing rhythm uses token steps (`T.space.sm`, `T.space.md`, `T.space.lg`).

## Color and Contrast

- Use accent for primary action only.
- Reserve rose/red surfaces for urgent safety content.
- Non-urgent surfaces use neutral glass fills and low-contrast borders.

## Typography

- Heading/body/caption should map to `T.type.h*`, `T.type.body`, `T.type.caption`.
- Avoid introducing ad-hoc font sizes unless there is a clear component reason.
- Keep subtitles and helper text in `textSecondary` or `textTertiary`.

## Interaction

- Advanced controls live behind `ExpansionTile` or equivalent disclosure.
- Timer or “do now” actions are top-placed and visually dominant.
- Back/finish actions should be low emphasis unless safety requires otherwise.

## QA Checks

- Verify one-primary-action behavior on phone viewport.
- Verify expanded optional sections do not push primary action off-screen on first load.
- Verify non-urgent screens do not use alarm color semantics.

