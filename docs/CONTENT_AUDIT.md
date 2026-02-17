# Content Audit: Card Seed + Moment Scripts

Audit date: 2026-02-17

Files audited:
- `/Users/jasonli/settle/assets/guidance/repair_cards_seed.json`
- `/Users/jasonli/settle/assets/guidance/moment_scripts.json`

Method notes:
- Sentence counts are computed by splitting on sentence-ending punctuation (`.`, `!`, `?`) and counting non-empty text segments.
- Forbidden tone scan is case-insensitive and normalizes curly apostrophes/quotes before matching.

## 1) Required fields and body <= 3 sentences

Status: **FAIL**

- Cards audited: **15**
- Required fields checked: `id`, `title`, `body`, `context`, `state`, `tags`, `warmthWeight`, `structureWeight`
- Cards missing required fields: **0**
- Cards with body <= 3 sentences: **6/15**
- Cards with body > 3 sentences: **9/15**

Cards over sentence limit:
- `gen_1` (4)
- `gen_3` (4)
- `gen_5` (4)
- `sleep_bedtime_1` (4)
- `sleep_night_1` (4)
- `sleep_night_2` (5)
- `tantrum_child_1` (5)
- `tantrum_child_2` (4)
- `tantrum_child_3` (4)

## 2) Context/state coverage (>= 2 cards per context x state)

Status: **FAIL**

Coverage matrix:
- `general x self` = 2 (PASS)
- `general x child` = 3 (PASS)
- `sleep x self` = 0 (FAIL)
- `sleep x child` = 5 (PASS)
- `tantrum x self` = 2 (PASS)
- `tantrum x child` = 3 (PASS)

Gap:
- `sleep x self` needs at least **2** cards (currently **0**).

## 3) Forbidden tone words in card text

Status: **PASS**

Forbidden phrases scanned in card `title` + `body`:
- `urgent`
- `failed`
- `streak`
- `you need to`
- `don't forget`
- `we miss you`
- `hurry`

Matches found: **0**

### Tone fixes applied to seed file

- Required direct string fixes: **none**
- Updated file: `/Users/jasonli/settle/assets/guidance/repair_cards_seed.json`
- Changes made: **none**

## 4) Moment scripts <= 2 sentences each

Status: **FAIL**

Script sentence counts (per variant, combined lines):
- `boundary` = 4 (FAIL)
- `connection` = 4 (FAIL)
