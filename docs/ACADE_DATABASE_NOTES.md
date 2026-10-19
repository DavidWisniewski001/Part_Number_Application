# AutoCAD Electrical Catalog Database Notes

Organization setup: **AutoCAD Electrical 2026, catalog on SQL Server** (Q-001). Research behind these notes: `docs/research/ACADE_2026_CATALOG_COMPATIBILITY.md`.

> Everything marked **(verify)** must be checked against the organization's actual catalog database and ACADE version before the app writes to the catalog. Deliverable D2 replaces this file's guesses with facts.

## 1. Background
- By default, ACADE ships its catalog as a Microsoft Access file (`default_cat.mdb`). Newer releases can point the catalog at **SQL Server** instead, through Autodesk's Content Migration Utility. This organization runs **2026 on SQL Server** (confirmed, Q-001).
- The catalog holds **one table per component category**, typically named by the family code of the schematic symbols (e.g. `CR`, `PB`, `LT`, `SS`, `CB`, `FU`, `MO`), plus `MISC_CAT` for general items. **(verify the list)**
- There are helper tables such as `_PINLIST` (pin lists) and manufacturer/description lookup tables. **(verify names)**
- Separate databases exist for footprint lookup (panel) and other uses. These are **out of scope**.

## 2. Typical catalog table columns (verify per table)
| Column | Typical use |
|---|---|
| `CATALOG` | Manufacturer catalog / part number (MPN) |
| `MANUFACTURER` | Manufacturer code |
| `DESCRIPTION` | Part description shown in lookup and BOM |
| `ASSEMBLYCODE`, `ASSEMBLYLIST`, `ASSEMBLYQTY` | Sub-assembly / multi-part definitions |
| `TEXTVALUE` | Value text for some symbol types |
| `QUERY1`, `QUERY2`, `QUERY3` | **Not found in any Autodesk field list.** May not exist. Do not populate until checked with `db/discovery/01` (verify) |
| `RECNUM`, `ROWGUID` | Automatic record ID columns. **Never write them** (confirmed) |
| `WEBLINK` | Datasheet or web link (verify) |
| `TYPE`, `STYLE`, `RATING1`…`RATINGn` | Category-specific attributes |
| `USER1` | **Organization part number (decided, Q-003).** Width 100 per Autodesk help; real SQL type and length to be verified per table. Can be shown on BOM reports |
| `USER2`, `USER3` | User-defined, free for now |
| `MISC1`, `MISC2` | Misc |
| `WDBLKNAM` | Symbol block name filter |

## 3. Rules for the app
1. **Zero footprint (ADR-0003):** create nothing in the catalog database. ACADE finds fields **by position**, so never add, reorder or retype columns. Extra tables would likely appear as Catalog Browser categories.
2. The target family table and column mapping come from the shared settings file, not hard-coded.
3. Before any write, check that the table and columns exist in `INFORMATION_SCHEMA.COLUMNS`. Fail clearly if they don't.
4. Respect existing column lengths. Truncation is an error, not a silent cut.
5. Upsert key: `MANUFACTURER` + `CATALOG` + `ASSEMBLYCODE` (likely; verify with `db/discovery/02`). Existing duplicates are reported, never merged automatically.
6. Back up the catalog DB before the app's first write and before any ACADE upgrade.
7. Catalog merges (`AEMIGRATION`) and Catalog Browser edits can overwrite `USER1`. Back up before them, and re-run the USER1 report afterwards.

## 4. Discovery tasks (for acade-db-specialist)
- [x] ACADE version: 2026, catalog on SQL Server
- [ ] Confirm all seats point at the same SQL catalog database
- [ ] Run `db/discovery/01_catalog_inventory.sql` (tables, USER1 length, RECNUM/ROWGUID, keys, triggers)
- [ ] Run `db/discovery/02_user1_and_duplicates.sql` (what is already in USER1, duplicate rows)
- [ ] Run the remaining server tests listed in the research report (probe table on a copy, BOM refresh, locks, concurrency)
- [ ] Confirm whether `QUERY1-3` exist at all (they're not in Autodesk's field list)
- [ ] Replace the "(verify)" entries above with the real results
