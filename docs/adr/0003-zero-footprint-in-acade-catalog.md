# ADR-0003: Zero footprint in the AutoCAD Electrical catalog database

- Status: **Accepted** (pending the server tests in Phase 0)
- Date: 2026-10-19
- Supersedes: ADR-0002

## Context
- The owner wants the app to need **no area of its own** on the server (Q-002).
- The compatibility research (`docs/research/ACADE_2026_CATALOG_COMPATIBILITY.md`) found that extra tables in the catalog database are likely to show up as Catalog Browser categories. ACADE also creates its own tables (`_PINLIST_<MFR>`, `_TERMPROPS_<MFR>`). Whether other schemas or views are listed is unknown.
- ACADE finds catalog columns **by position**. `RECNUM` and `ROWGUID` must stay automatic. Columns must not be added, reordered or retyped.
- `USER1` is a user field of width 100. It can be shown on BOM reports and isn't written by ACADE automatically, so it suits the organization's part number (Q-003).

## Decision
1. **The app creates no objects in the catalog database:** no tables, views, schemas, procedures, triggers or indexes.
2. The only writes are **row inserts and updates** on existing ACADE family tables. Each statement names its columns explicitly, never supplies `RECNUM` or `ROWGUID`, and runs in a short transaction with a lock timeout.
3. **Part-number issuance** runs as one short transaction:
   1. `sp_getapplock @Resource = 'PartNumberApp.Issue', @LockMode = 'Exclusive', @LockOwner = 'Transaction'`. This creates no objects.
   2. Find the highest sequence value among `USER1` values that match the configured format, across all family tables.
   3. Build the next number. Re-check that it is unique across all tables.
   4. Insert the catalog row (or update `USER1` on an existing one). Commit, which releases the lock.
4. **Settings** (connection, part number format, categories, description templates, abbreviations) live in a **shared configuration file** that an admin deploys or places on a network share. All workstations must use the same file. The app shows a fingerprint of the format, so differences can be spotted.
5. The **upsert key** is `MANUFACTURER + CATALOG + ASSEMBLYCODE` (Likely, verify with test T4.2).
6. Dynamic family-table names are the one exception to "no concatenated SQL". They are allowed only after a whitelist check against `sys.tables`/`INFORMATION_SCHEMA.COLUMNS`, and are always wrapped in `QUOTENAME`. All values remain parameters.
7. If approvals, history or stored attributes are wanted (Q-013), they go in an **optional companion database on the same instance**, never in the catalog database. The draft script is in `db/companion-db/`.

## Consequences
- ACADE behaves exactly as before. There is no new category, and no schema drift during ACADE upgrades or migrations.
- **Number reuse risk:** if the row holding the highest number is deleted, restored from an older backup, or overwritten by a catalog merge (`AEMIGRATION`), that number can be issued again. Mitigations: a "don't delete, mark obsolete" policy; an optional **sequence floor** in the shared settings; an append-only issuance log file; and a cross-check against the ERP export before release.
- No reservations (draft numbers) and no review workflow without the companion database. Parts become catalog rows once they are created.
- Issuance scans every family table. This is fine for typical catalog sizes; test T9.1 measures it.
- A hand-typed `USER1` value that matches the format affects the sequence. A clean-up report flags those values.
