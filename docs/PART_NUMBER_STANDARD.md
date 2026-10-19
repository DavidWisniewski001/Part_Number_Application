# Part Number Standard (DRAFT, needs approval, see Q-004)

## 1. Principles
1. **A part number identifies a part. It does not describe it.** The meaning lives in the attributes and the description. Encoding specs into the number causes conflicts and runs out of codes.
2. **One form, fit and function = one part number.** If two items are interchangeable in every use, they share a PN.
3. **Numbers are never reused**, even after a part is obsoleted or deleted as a draft.
4. **Only the system issues numbers.**

## 2. Proposed format (semi-significant)

```
CCC-NNNNNN
│    └──── 6-digit sequential number, zero-padded, unique per prefix
└───────── 3-letter category prefix (from pnm.Category)
```

Examples: `RLY-000123` (relay), `CBK-000045` (circuit breaker), `TRM-001002` (terminal block).

- Allowed characters: `A–Z`, `0–9`, `-`. Upper case only. Fixed length of 10 characters.
- The prefix is for human convenience and sorting only. **It never changes.** If a part was categorized wrongly, it keeps its number and gets re-categorized in data.
- An alternative is a fully non-significant number, e.g. `E000123`, decided in Q-004.

### Starter category prefixes (to be refined with Engineering)
| Prefix | Category | Likely ACADE catalog table (verify) |
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
| PSU | Power supplies | MISC_CAT (verify) |
| ENC | Enclosures + panel hardware | MISC_CAT (verify) |
| WIR | Wire, cable | W / CBL (verify) |
| MSC | Miscellaneous electrical | MISC_CAT |

## 3. Revisions vs. new numbers
| Change | Action |
|---|---|
| Description typo, added datasheet link | Edit in place (audited), no revision |
| Change that keeps form/fit/function (e.g. a manufacturer alternate) | Add an approved alternate MPN to the same PN |
| Change that breaks interchangeability | **New PN.** Old PN → Obsolete, "superseded by" new PN |

## 4. Lifecycle
| Status | Who | Meaning |
|---|---|---|
| Draft | Creator | Number reserved, may be edited, not synced or exported |
| In Review | Creator → Reviewer | Locked for review |
| Released | Reviewer/Approver | Synced to ACADE, included in ERP export |
| Obsolete | Approver | Not for new designs. Stays searchable |
| Legacy | Import only | Imported, awaiting clean-up |

Drafts abandoned for more than N days (configurable) are flagged. Their numbers are **voided, not reused**.
