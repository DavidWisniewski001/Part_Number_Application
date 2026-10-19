# ADR-0002: App-owned `pnm` schema alongside the ACADE catalog

- Status: **Proposed** (depends on Q-002)
- Date: 2026-10-19

## Context
The app must use the ACADE SQL catalog as its backend. ACADE owns its catalog tables. Their structure can change between versions, and ACADE upgrades or catalog migrations may rewrite them. If we store part-number master data (sequences, attributes, workflow, audit) in ACADE tables, that data is at risk, and the app gets tightly coupled to ACADE internals.

## Decision
- Create a dedicated `pnm` schema in the same SQL Server database as the ACADE catalog. Fallback: a separate database on the same instance.
- `pnm` is the **system of record** for part numbers and documentation.
- ACADE catalog tables (`dbo.*`) are treated as a **downstream target**. Released parts are upserted there by a sync service, through a configurable table/column mapping.
- The app never alters ACADE table structures.

## Consequences
- ACADE upgrades can't destroy part-number history. The sync can be re-run to repopulate catalog rows.
- We need a mapping layer and a sync log (more code than writing straight to ACADE tables).
- The same database makes joins for reconciliation easy, and needs no cross-database permissions.
