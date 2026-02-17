# Content Audit: Repair Cards + Moment Scripts

Audit date: 2026-02-17  
Files audited:
- `/Users/jasonli/settle/assets/guidance/repair_cards_seed.json`
- `/Users/jasonli/settle/assets/guidance/moment_scripts.json`

## 1) Required fields + body <= 3 sentences

Status: **PARTIAL FAIL**

- Cards audited: **15**
- Required fields checked: `id`, `title`, `body`, `context`, `state`, `tags`, `warmthWeight`, `structureWeight`
- Missing required fields: **0**
- Body sentence limit pass (`<= 3`): **6/15**
- Body sentence limit fail (`> 3`): **9/15**

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

## 2) Context x state coverage (>=2 each combo)

Status: **FAIL**

Observed matrix:
- `general x self` = 2
- `general x child` = 3
- `sleep x self` = 0
- `sleep x child` = 5
- `tantrum x self` = 2
- `tantrum x child` = 3

Coverage gap:
- `sleep x self` has **0** cards (requires >=2)

## 3) Forbidden tone words in card text

Status: **PASS**

Forbidden phrases scanned in `title`, `body`, `tags`:
- `"urgent"`
- `"failed"`
- `"streak"`
- `"you need to"`
- `"don't forget"`
- `"we miss you"`
- `"hurry"`

Matches found: **0**

## 4) Moment scripts <= 2 sentences each

Status: **FAIL**

Moment scripts found: **2** (`boundary`, `connection`)  
Sentence count per script variant (combined lines):
- `boundary`: 4 sentences
- `connection`: 4 sentences

Both exceed the <=2 sentence requirement.

## Manual QA

### Repository checks (runtime)

Command: `flutter test test/manual_content_qa_tmp_test.dart`  
Result: **PASS**

Validated:
- `CardRepository.instance.loadAll()` returns **15**
- `filter(context: RepairCardContext.sleep, state: RepairCardState.child)` returns **5**, all `sleep+child`
- `pickOne(context: RepairCardContext.tantrum)` returns tantrum cards and varies across samples
- `MomentScriptRepository.instance.loadAll()` returns **2**
- `getByVariant(MomentScriptVariant.connection)` returns non-null connection script

### Build check

Command: `flutter build apk --debug`  
Result: **FAIL**

Errors reported:
- Android NDK mismatch (`26.3.11579264` configured; plugins require `27.0.12077973`)
- Core library desugaring required by `flutter_local_notifications`

## Fixes Applied

- Tone violations in seed file: **none found**
- String changes made in `/Users/jasonli/settle/assets/guidance/repair_cards_seed.json`: **none**
