# Open Questions

Questions that need a decision from the organization. **Blocking** means Phase 1 can't start in earnest without an answer.

| ID | Question | Blocking | Owner | Answer |
|---|---|---|---|---|
| Q-001 | Which AutoCAD Electrical version(s) are in use, and is the catalog already on SQL Server (instance/database name)? | ~~Yes~~ | IT / Eng lead | **Answered 2026-10-19:** AutoCAD Electrical 2026. The catalog is already on SQL Server. The app must let the user point it at the server and database (connection setup screen). |
| Q-002 | May the app create its own `pnm` schema inside the catalog database, or must it use a separate database on the same instance? | Yes | DBA | **Owner preference 2026-10-19:** the app should *not* need its own area on the server. Compatibility research is under way (`docs/research/`) to confirm a zero-footprint design causes no interference, and to state what it gives up. |
| Q-003 | Which ACADE catalog column should hold our internal part number (`USER1`? another one)? Are any `USER*` columns already in use? | ~~Yes~~ | Eng lead | **Answered 2026-10-19:** `USER1` holds the organization's part number. Still to check: existing `USER1` contents on the server. |
| Q-004 | Approve the PN format: semi-significant `CCC-NNNNNN`, or fully non-significant? Must it match an existing ERP numbering range? | ~~Yes~~ | Eng + Purchasing | **Answered 2026-10-19:** each customer chooses its own structure in the app (presets or custom builder). See `PART_NUMBER_STANDARD.md`. Whether it must line up with existing ERP numbers moves to Q-008. |
| Q-005 | Which business management/ERP system is used, which import format does it accept, and what are its required fields and field lengths? | No (Phase 3) | ERP owner | |
| Q-006 | Who are the roles (creator, reviewer, approver, admin)? Are AD groups available? | No (Phase 2) | Sponsor | |
| Q-007 | What are the max lengths of the description fields in the ERP and ACADE? | No | ERP owner / DBA | |
| Q-008 | How should existing (legacy) part numbers be handled? Keep them, map them to new ones, or both? | No (Phase 3) | Eng + Purchasing | |
| Q-009 | Which categories make up the pilot, and who are the pilot users? | No | Eng lead | |
| Q-010 | Duplicate policy: hard block, or warn with a justification? | No | Eng lead | |
| Q-011 | Should manufacturer alternates (same form/fit/function, different manufacturer) share one part number? ACADE stores one row per CATALOG + MANUFACTURER, so this means several rows with the same `USER1`. | No | Eng lead | |
| Q-012 | Will the app be offered to several customers or organizations (so packaging, licensing and per-customer setup matter), or used by one organization only? | No | Owner | |
| Q-013 | Without an app-owned area: is the review/approval workflow and the audit history still wanted? If so, where should status be kept (e.g. another USER column) and where should history go (e.g. log files)? | Yes (once research is in) | Owner | |
