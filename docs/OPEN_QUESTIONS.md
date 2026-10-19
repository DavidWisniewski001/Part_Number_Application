# Open Questions

Questions that need a decision from the organization. **Blocking** means Phase 1 can't start in earnest without an answer.

| ID | Question | Blocking | Owner | Answer |
|---|---|---|---|---|
| Q-001 | Which AutoCAD Electrical version(s) are in use, and is the catalog already on SQL Server (instance/database name)? | Yes | IT / Eng lead | |
| Q-002 | May the app create its own `pnm` schema inside the catalog database, or must it use a separate database on the same instance? | Yes | DBA | |
| Q-003 | Which ACADE catalog column should hold our internal part number (`USER1`? another one)? Are any `USER*` columns already in use? | Yes | Eng lead | |
| Q-004 | Approve the PN format: semi-significant `CCC-NNNNNN`, or fully non-significant? Must it match an existing ERP numbering range? | Yes | Eng + Purchasing | |
| Q-005 | Which business management/ERP system is used, which import format does it accept, and what are its required fields and field lengths? | No (Phase 3) | ERP owner | |
| Q-006 | Who are the roles (creator, reviewer, approver, admin)? Are AD groups available? | No (Phase 2) | Sponsor | |
| Q-007 | What are the max lengths of the description fields in the ERP and ACADE? | No | ERP owner / DBA | |
| Q-008 | How should existing (legacy) part numbers be handled? Keep them, map them to new ones, or both? | No (Phase 3) | Eng + Purchasing | |
| Q-009 | Which categories make up the pilot, and who are the pilot users? | No | Eng lead | |
| Q-010 | Duplicate policy: hard block, or warn with a justification? | No | Eng lead | |
