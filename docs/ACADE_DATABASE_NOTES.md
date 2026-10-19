# AutoCAD Electrical Catalog Database Notes

> Everything marked **(verify)** must be checked against the organization's actual catalog database and ACADE version before the sync is built. Deliverable D2 replaces this file's guesses with facts.

## 1. Background
- By default, ACADE ships its catalog as a Microsoft Access file (`default_cat.mdb`). Newer releases can point the catalog at **SQL Server** instead (Project Properties / catalog settings; Autodesk provides a migration utility). **(verify version and setup in use, Q-001)**
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
| `QUERY1`, `QUERY2`, `QUERY3` | Filter columns used by the catalog browser (often type, style, rating) |
| `TYPE`, `STYLE`, `RATING1`…`RATINGn` | Category-specific attributes |
| `USER1`, `USER2`, `USER3` | User-defined. **Candidate for our internal PN (Q-003)** |
| `MISC1`, `MISC2` | Misc |
| `WDBLKNAM` | Symbol block name filter |

## 3. Rules for the app
1. **Do not alter ACADE tables** (no new columns, no type changes). Our data goes in the `pnm` schema.
2. The sync target table and column mapping come from `pnm.Category` / `pnm.AcadeColumnMap`, not hard-coded.
3. Before any write, check that the table and columns exist in `INFORMATION_SCHEMA.COLUMNS`. Fail clearly if they don't.
4. Respect existing column lengths. Truncation is an error, not a silent cut.
5. Upsert key: `CATALOG` + `MANUFACTURER` **(verify uniqueness; ACADE tables may have duplicates and no primary key)**.
6. Back up the catalog DB before the first sync run and before any ACADE upgrade.

## 4. Discovery tasks (for acade-db-specialist)
- [ ] Confirm ACADE version(s) and whether all seats point at the same SQL catalog.
- [ ] Export the full table/column list: `SELECT TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH FROM INFORMATION_SCHEMA.COLUMNS ORDER BY 1, ORDINAL_POSITION;`
- [ ] Row counts per table; check for duplicate `CATALOG`+`MANUFACTURER`.
- [ ] Identify which `USER*` columns are already in use.
- [ ] Check for keys, indexes and triggers on the catalog tables.
- [ ] Document how ACADE uses `QUERY1-3` per table, so we populate them correctly.
