# Part Number Standard

The app does **not** impose one part number format. Each organization (customer) chooses its structure during setup, from a preset or with a custom format. This document defines what a format may contain and the rules every format must follow.

The organization's part number is stored in **`USER1`** of the AutoCAD Electrical catalog row (decision Q-003).

## 1. Rules that apply to every format
1. **Only the app issues numbers.** Users never type a part number by hand.
2. **Numbers are unique** across *all* catalog tables. The check runs against `USER1` in every catalog table, not only the current category. The one possible exception is manufacturer alternates that share a number (Q-011).
3. **Numbers are never deliberately reused**, even after a part is made obsolete. See the research note on deletions in `docs/research/`.
4. **A format must contain exactly one sequence segment.** That is what guarantees uniqueness.
5. **Allowed characters:** `A–Z`, `0–9` and the chosen separator (`-`, `.`, `_` or none). Always stored in upper case.
6. **Maximum length** is the smaller of the `USER1` column length (verify on the organization's server) and the ERP item-number length (Q-005). The setup screen refuses formats that could exceed it.
7. **Format changes affect only new numbers.** Existing numbers are never renumbered. Changing the format once parts exist needs an admin confirmation, and the change is logged.
8. **One form, fit and function = one part number.**

## 2. Format building blocks
An admin builds the format from segments in the setup screen, with a live preview. Internally it is stored as a template string.

| Segment | Template token | Options | Example output |
|---|---|---|---|
| Fixed text | `ACME`, `E` (any literal) | 1–10 characters | `E` |
| Separator | `-` `.` `_` | Or no separator | `-` |
| Category code | `{CAT}` | Code per category, 1–5 characters, defined by the admin | `RLY` |
| Sequence | `{SEQ:n}` | Width `n` (3–10), zero-padded, start value, **scope** (see below) | `000123` |
| Year | `{YY}` / `{YYYY}` | Optional "restart the sequence each year" | `26` |
| Attribute code | `{ATTR:Name}` | Short code mapped from an attribute value (e.g. a voltage class). Use sparingly, because it makes numbers "significant" | `24` |
| Check digit | `{CHK}` | Mod-10 (Luhn) over the digits; catches typing errors | `7` |

### Sequence scope
| Scope | Meaning | Example run |
|---|---|---|
| Global | One counter for all parts | `E000001`, `E000002` … |
| Per category | One counter per category code | `RLY-000001`, `CBK-000001` … |
| Per year | Counter restarts each year (needs `{YY}`/`{YYYY}`) | `26-0001` … `27-0001` |

## 3. Presets offered at setup
| # | Preset | Template | Example |
|---|---|---|---|
| 1 | Category + sequence (default) | `{CAT}-{SEQ:6}` | `RLY-000123` |
| 2 | Plain sequential | `{SEQ:6}` | `100245` |
| 3 | Fixed prefix + sequence | `E{SEQ:6}` | `E000123` |
| 4 | Category + year + sequence | `{CAT}-{YY}-{SEQ:4}` | `RLY-26-0042` |
| 5 | Sequence + check digit | `{SEQ:6}{CHK}` | `1002457` |
| 6 | Custom | Built by the admin | |

**Recommendation:** use preset 1 or 2. Keep the number meaningless and put the meaning into attributes and the description. Formats that encode attributes run out of codes, and get "wrong" when a part is re-categorized.

## 4. Matching existing numbers
Every template compiles into a matching pattern (for example `{CAT}-{SEQ:6}` → `^[A-Z]{1,5}-\d{6}$`). The app uses this to:
- find the highest existing sequence value when it issues the next number;
- flag existing `USER1` values that don't fit the current format (legacy or hand-typed numbers) in a clean-up report;
- validate imports.

If an organization already has numbers in its ERP, the sequence start value can be set above the highest existing number, so the ranges never collide (Q-008).

## 5. Starter category codes (editable at setup)
| Code | Category | ACADE catalog table (verify) |
|---|---|---|
| RLY | Relays, contactors (control) | CR |
| CBK | Circuit breakers | CB |
| FUS | Fuses, fuse holders | FU |
| PBN | Push buttons | PB |
| SEL | Selector switches | SS |
| LIT | Pilot lights | LT |
| TRM | Terminal blocks + accessories | TRMS / TB (verify) |
| MTR | Motors | MO |
| PLC | PLC modules, I/O | PLCIO (verify) |
| MSC | Miscellaneous electrical | MISC_CAT |

## 6. Revisions vs. new numbers
| Change | Action |
|---|---|
| Description typo, datasheet link added | Edit in place (logged), no new number |
| Manufacturer alternate with identical form/fit/function | Same part number; record it as an alternate (see Q-011) |
| Change that breaks interchangeability | **New part number.** The old part is marked obsolete and points to the new one |
