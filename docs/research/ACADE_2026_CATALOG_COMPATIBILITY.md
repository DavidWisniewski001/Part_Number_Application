# AutoCAD Electrical 2026 – SQL Server Catalog Compatibility Research

- Author: acade-compatibility-researcher (Claude Code subagent)
- Date: 2026-10-19
- Scope: how ACADE 2026 uses its SQL Server catalog database, and what the Part Number Application (PNA) must do, and avoid, so that it never interferes with ACADE.
- Owner context: ACADE 2026; the catalog is already on SQL Server; the app must use a configurable connection; the owner prefers **no app-owned objects** on the server; `USER1` holds the organization's internal part number; the PN format is configurable per organization.

## How to read this report

**Confidence levels**
- **Confirmed by source**: stated in Autodesk documentation, an Autodesk support article, or Microsoft documentation.
- **Likely**: supported by forum, reseller or blog sources, or a reasonable inference from documented behavior. Not to be relied on without the listed test.
- **Unknown**: no source found. A test is proposed.

**Research limits (important).** During this research the sandbox could not open Autodesk, Arkance, IMAGINiT or forum pages directly (the egress proxy refused the connections). The findings come from **search-engine excerpts** of those pages. Where an excerpt quotes Autodesk help text, it is marked "Confirmed by source". However, nobody has read the full pages in context, and several excerpts come from 2020–2025 help, not 2026. The 2026 help still has the same pages (same GUIDs), but anyone who has a browser should spot-check the cited pages before ADR-0002 is finalized. Under CLAUDE.md rule 6, every statement about the schema is still **(verify)** until it has been checked against the organization's real catalog database.

---

## Summary of key findings

| # | Topic | Finding | Confidence |
|---|---|---|---|
| 1 | Connection | You set it with `AECATALOGCONFIG` / Configure Database (server, Windows or SQL authentication, catalog and footprint databases). Only the catalog and footprint databases can live on SQL. Project, PLC and standards databases stay in Access. | Confirmed by source |
| 2 | Table discovery | ACADE treats tables as categories. **New tables show up as categories.** ACADE itself creates `_PINLIST_<MFR>` / `_TERMPROPS_<MFR>` tables on save. Global Search reads across family tables. Whether it filters by schema, or ignores views and procedures, is **Unknown**. | Likely (tables appear) / Unknown (schemas, views) |
| 3 | USER1 | It is a user field, documented width **100**. ACADE does not fill it automatically. BOM and panel BOM reports can show it, looked up from the catalog at report time by MFG + CAT (+ assembly code). Catalog Browser edit mode lets users type in it. | Confirmed (width, BOM field) / Likely (lookup and no auto-write) |
| 4 | Structure rules | Do not add or remove columns, change their order, labels, data types or sizes, or remove `RECNUM`. ACADE locates fields **by position**. On SQL there are also `ROWGUID`/`RECNUM` columns that must stay automatic. | Confirmed by source |
| 5 | Uniqueness | The Catalog Browser refuses exact duplicate records. Users recall the key as MFG + CATALOG + ASSEMBLYCODE. SQL constraints are Unknown. | Likely |
| 6 | Upgrades / migration | `AEMIGRATION` and the Content Migration Utility merge and **overwrite matching entries**. Databases modified outside ACADE "may not migrate". | Likely |
| 7 | Locking | No source on locks or open transactions held by the Catalog Browser. Lookups do whole-database reads, and there is an SQL timeout variable (default 30 s). | Unknown |
| 8 | Permissions | Autodesk documents **db_owner** for read/write users. The app's account should be much narrower. | Confirmed by source |

**Zero-footprint recommendation:** it is feasible for the core function: issue a number, write a catalog row, check uniqueness. It is not feasible for workflow, audit and reservation history. See section 9.

---

## Q1. How ACADE 2026 connects to a SQL Server catalog

**Finding**
- In standalone installs, the user runs `AECATALOGCONFIG` (Project > Project Tools > Configure Catalog Database) to open the Configure Database dialog. They connect to an instance and pick the catalog and footprint databases. In deployment mode, the instance is created by an administrator in advance.
- **Authentication:** Windows Authentication, or a SQL user name and password, chosen in the dialog's Server Details section.
- **Databases:** only the catalog (`default_cat`) and footprint lookup databases can move to SQL Server. The project, PLC, electrical standards, schematic lookup and language databases stay in Access. Access is still required, and secondary catalog databases are not available with SQL.
- The Content Migration Utility (installed separately from the install media) creates the SQL database and migrates `.mdb` content into it.
- `AESETSQLSERVERTIMEOUT` (since 2022) sets the SQL timeout. The default is 30 s, and the range is 15–500 s.
- SQL Server Browser must be running, or ACADE and the migration tool cannot find named instances.
- Where the SQL connection settings are stored (per user or per project, registry or `wd.env`) is **Unknown**. `wd.env` and project settings hold the Access catalog path. No source describes where the SQL connection is persisted.

**Confidence:** Confirmed by source (dialog, auth options, database scope). Unknown (where the settings are stored).

**Sources**
- [SQL Server Configuration for AutoCAD Electrical Catalog Content (2026 install help)](https://help.autodesk.com/cloudhelp/2026/ENU/Installation-AutoCAD/files/Install_ACE/Installation_AutoCAD_Install_ACE_SQL_server_html.html)
- [About the Catalog Database (2026)](https://help.autodesk.com/cloudhelp/2026/ENU/AutoCAD-Electrical/files/GUID-9AAD41B7-437B-41CC-A89A-2DC7F8165006.htm)
- [Configure Database Dialog Box (2021)](https://help.autodesk.com/cloudhelp/2021/ENU/AutoCAD-Electrical/files/GUID-58244262-705A-4491-94B8-D48349FD9A6A.htm)
- [About Autodesk Content Migration Utility (2023)](https://help.autodesk.com/cloudhelp/2023/ENU/AutoCAD-Electrical-SQLSetup/files/GUID-44DFD2CD-7195-4F25-BB00-7B6DCA902A35.htm)
- [IMAGINiT – ACADE SQL Migration Part 1](https://resources.imaginit.com/how-tos/autodesk-autocad-electrical-sql-migration-part-1-of-2), [Part 2](https://resources.imaginit.com/support-blog/autodesk-autocad-electrical-sql-migration-part-2-of-2)
- [IMAGINiT – SQL Server Timeout Variable](https://resources.imaginit.com/support-blog/autodesk-autocad-electrical-sql-server-timeout-variable)
- [Forum – Migrating from Access to SQL issues (SQL Browser, roles)](https://forums.autodesk.com/t5/autocad-electrical-forum/migrating-from-access-to-sql-issues-resolved/td-p/10292410)

**Impact on the design**
- The app reads its own connection string from configuration. It must never read or modify ACADE's configuration. The owner's requirement is met.
- The app should support both Windows (integrated) and SQL authentication, like ACADE. Prefer integrated authentication with an AD group.
- Use a **dedicated, least-privilege login** for the app (see Q7). Do not reuse the db_owner accounts that Autodesk recommends for ACADE editors.

**Test on the organization's server**
- T1.1 Record the instance, database names and authentication mode from a seat's Configure Database dialog. Confirm that every seat points at the same database (Q-001).

---

## Q2. How ACADE finds catalog tables, and whether extra objects show up or break anything

**Finding**
- The catalog has **one table per family** (CB, FU, MO, …). The table name matches the symbol's `WDBLKNAM` attribute, or the block name if that attribute is missing. `MISC_CAT` is the fallback. Support tables start with an underscore: `_PINLIST`, `_PINLIST_<MFR>`, `_TERMPROPS`, `_FAMILY_DESCRIPTION`, and a schema-version table on SQL only.
- **Tables added to the database become categories.** Autodesk documents "Add Table to Catalog Database" for new categories, and users report that the new table then appears in the Category list (after a restart or project switch). From this it is **Likely** that ACADE enumerates the tables in the database rather than reading a fixed list. So **any table the app put in the catalog database could show up as a bogus category.**
- `_FAMILY_DESCRIPTION` supplies the category descriptions. Autodesk says do not remove it or change its columns.
- **ACADE creates tables itself.** Saving a record in Catalog Browser edit mode with a new manufacturer creates `_PINLIST_<MFR>` / `_TERMPROPS_<MFR>` if needed. So ACADE users need DDL rights, and the table set is not static. The app must re-discover tables each time and must never assume a fixed list.
- **Global Search** (2021+) searches CATALOG, MANUFACTURER and ASSEMBLYCODE values across family tables. A foreign table or view that lacks those columns could cause an error there. **Unknown.**
- **Schemas, views, stored procedures:** no source says whether ACADE filters by schema (for example, only `dbo`) or by object type. An object in a separate schema (`pnm`) or a view may be harmless, or may appear as a category. **Unknown.** Stored procedures and functions are very unlikely to be enumerated as tables (**Likely**), but there is no source for that either.
- A **separate database** on the same instance is outside anything ACADE enumerates, because ACADE is pointed at one catalog database. **Likely** safe.

**Confidence:** Likely (extra tables appear as categories). Unknown (schemas, views, procedures).

**Sources**
- [About the Catalog Database Structure (2025)](https://help.autodesk.com/cloudhelp/2025/ENU/AutoCAD-Electrical/files/GUID-EB444995-30FB-4814-B41A-3BA8DDDD02D8.htm)
- [Best Practices for Customizing the Catalog Database (2023)](https://help.autodesk.com/view/ACAD_E/2023/ENU/?guid=GUID-0EEFFB23-2229-4D1B-A4E7-F070220F5BD3)
- [To Work With Catalog Database Tables (2021)](https://help.autodesk.com/cloudhelp/2021/ENU/AutoCAD-Electrical/files/GUID-6D3193BD-E270-4BC8-9A5D-63405D664A2F.htm)
- [Catalog Browser (2025)](https://help.autodesk.com/cloudhelp/2025/ENU/AutoCAD-Electrical/files/GUID-3CB94487-CF38-4F0A-ACAA-A0E8438DA009.htm)
- [Forum – Adding a category to the catalog](https://forums.autodesk.com/t5/autocad-electrical-forum/adding-a-category-to-the-catalog/td-p/7158459)
- [SolidCAD – How to add a new Table/Family](https://www.solidcad.ca/how-to-add-a-new-table-family-in-autocad-electrical/)
- [Arkance – Global Search within the Catalogue Browser (2021)](https://ukcommunity.arkance.world/hc/en-us/articles/21564741720594-AutoCAD-Electrical-2021-Global-Search-Within-The-Catalogue-Browser)
- [Autodesk – About catalog family names of different symbol types](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/About-catalog-family-names-of-different-symbol-types-in-AutoCAD-Electrical.html)

**Impact on the design**
- **ADR-0002 (the `pnm` schema inside the catalog database) carries an unquantified risk.** If ACADE enumerates all user tables regardless of schema, `pnm.*` tables would show up as categories, and Global Search could break. This supports the owner's preference not to create objects there.
- If the app ever needs its own storage, a **separate database on the same instance** is the safer option, and is Likely invisible to ACADE.
- Category discovery in the app: list the family tables from `sys.tables` (schema `dbo` (verify)), excluding names that start with `_`. Require the standard columns (`CATALOG`, `MANUFACTURER`, `USER1`, …) to be present before a table counts as a catalog table.

**Tests (non-production copy of the catalog database only)**
- T2.1 Create `dbo.ZZ_PNA_PROBE` (no ACADE columns), then a view `dbo.ZZ_PNA_VIEW`, then a schema `pnm` with table `pnm.Probe`. After each one, restart ACADE and check: the Category list, Catalog Lookup on a symbol, Global Search, Catalog Browser edit/save, a BOM report. Record which objects appear or cause errors. Then drop the objects.
- T2.2 Run a SQL Server Extended Events / Profiler trace (filtered to ACADE's host or application name) while ACADE starts, opens the Catalog Browser and runs Global Search. Capture the **metadata queries** it issues, for example `INFORMATION_SCHEMA.TABLES`, `sys.tables`, `sys.objects`, or ADO/OLE DB schema rowsets. This answers the schema and view question definitively.

---

## Q3. How ACADE uses USER1–USER3, QUERY1–3, ASSEMBLYCODE and DESCRIPTION

**Finding**
- **USER1, USER2, USER3:** documented as "user field #1 … for other information", width **100** (Access text). One 2014 third-party guide says 24 characters, which conflicts with current Autodesk help. The SQL data type created by the migration tool (for example `nvarchar(100)`) is **Unknown**.
- **Display names:** USER column headings in the Catalog Browser can be renamed, and Arkance documents a way to do this within SQL for 2024. Arkance gives "internal part number, MRP/ERP number" as a typical USER1 use, which matches this project's plan.
- **Does ACADE write USER1?** No source shows ACADE filling USER1 automatically. It is a free user field. **Likely** ACADE never writes it on its own. However: (a) users can type into USER1 in Catalog Browser edit mode; (b) `AEMIGRATION` / content migration merges can overwrite rows (Q5); (c) some catalog content already uses USER1 (a forum user mentions drive specifications in it). Existing USER1 values in the organization's data must be inventoried before USER1 is claimed (Q-003).
- **BOM and reports:** the BOM "Data Fields to Report" dialog lists "USER1–USER3: User fields in the catalog database table for the assigned catalog" (**Confirmed**). Reports match the component's MFG/CAT (+ assembly code) to the catalog **at report time** and pull the extra fields from there (**Likely**). So an updated USER1 shows up on the next report. Some users report having to re-assign the catalog or run `AEREBUILD` before stale values refresh. Trailing spaces in CATALOG cause blank USER1/DESCRIPTION values. Panel BOMs need the attributes on the footprint. USER fields can be blank for "multiple catalog" sub-items and secondary-database items.
- **DESCRIPTION:** used by lookups and the BOM. When a catalog is assigned, ACADE also copies DESC data and `TEXTVALUE` pairs into the symbol's attributes. So **descriptions already copied into drawings do not update** when the catalog row changes (**Likely**).
- **ASSEMBLYCODE / ASSEMBLYLIST / ASSEMBLYQUANTITY:** sub-assembly linkage. Part of the record identity (see Q4).
- **QUERY1–QUERY3:** **not found** in any Autodesk field list. The documented fields are CATALOG, MANUFACTURER, DESCRIPTION, TYPE, RATING*, MISCELLANEOUS1/2, ASSEMBLYCODE, ASSEMBLYLIST, ASSEMBLYQUANTITY, USER1–3, TEXTVALUE, WEBLINK and RECNUM. `docs/ACADE_DATABASE_NOTES.md` §2 lists QUERY1–3. That entry may be wrong, or they may be per-table columns. **Unknown.** Raise this with the project lead; do not populate them until checked.

**Confidence:** Confirmed (USER1 width 100 in help; USER1 available in the BOM). Likely (no automatic write; looked up at report time). Unknown (SQL type; QUERY1–3).

**Sources**
- [About the Catalog Database Structure (2025)](https://help.autodesk.com/cloudhelp/2025/ENU/AutoCAD-Electrical/files/GUID-EB444995-30FB-4814-B41A-3BA8DDDD02D8.htm)
- [Bill of Material Data Fields to Report (2025)](https://help.autodesk.com/cloudhelp/2025/ENU/AutoCAD-Electrical/files/GUID-D7D515A7-AE42-4994-9BD3-D966B8344BD9.htm), [Panel BOM version](https://help.autodesk.com/cloudhelp/2025/ENU/AutoCAD-Electrical/files/GUID-3A3BCEB5-C781-4E41-B0E5-C7B00F5EF7A2.htm)
- [Arkance – Renaming the Catalog Browser USER# Column Names within SQL (2024)](https://ukcommunity.arkance.world/hc/en-us/articles/21564956814098-AutoCAD-Electrical-2024-Renaming-the-Catalog-Browser-USER-Column-Names-within-SQL)
- [Forum – User1 Field Customization](https://forums.autodesk.com/t5/autocad-electrical-forum/user1-field-customization/td-p/6814730)
- [Forum – BOM Report Missing User1 and Description](https://forums.autodesk.com/t5/autocad-electrical-forum/bom-report-missing-user1-and-description-infomation/td-p/8487746)
- [Forum – BOM and Panel Report missing user fields](https://forums.autodesk.com/t5/autocad-electrical-forum/bom-report-and-panel-report-missing-cable-descriptions-and-user/td-p/10849125)
- [Autodesk – BOM missing Description (trailing spaces)](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/BOM-Description-not-showing.html)
- [Nate Holt – Sorting BOM report on USER1](https://nateholt.wordpress.com/2010/06/28/sorting-bom-report-on-user1-field-autocad-electrical/)

**Impact on the design**
- Maximum PN length is ≤ the real USER1 length. It is probably 100, but the setup screen must read `CHARACTER_MAXIMUM_LENGTH` per table. Tables may differ.
- Writes must trim CATALOG and MANUFACTURER values and refuse leading or trailing spaces, so that BOM lookups work.
- The app must assume **USER1 can be edited by ACADE users**. A hand-typed or duplicated USER1 has to be detected (reconciliation report), not just prevented.
- Description changes after release will not reach existing drawings. Document this for users.

**Tests**
- T3.1 `SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, ORDINAL_POSITION FROM INFORMATION_SCHEMA.COLUMNS ORDER BY 1,2,ORDINAL_POSITION;` Record the USER1 type and length per table, and check whether any QUERY* columns exist.
- T3.2 USER1 inventory: per table, count the non-empty USER1 values and sample the distinct ones.
- T3.3 On a copy: set USER1 on one row, place that part in a test project, and run BOM and panel BOM with USER1 as a column. Then change USER1 in SQL and rerun without re-assigning. Does the report show the new value?

---

## Q4. Keys, indexes, column order, and uniqueness of rows

**Finding**
- **Column order matters.** "The fields must remain in this order." A forum answer says ACADE finds fields **by position**, not by name. Do not add or remove columns, change their order, labels, data types (Text/Memo/AutoNumber) or sizes, and do not remove `RECNUM`. (**Confirmed**: Autodesk Best Practices.)
- **RECNUM** is an AutoNumber record identifier marked "Do not modify". On SQL there is also **ROWGUID**. Autodesk's article on failed SQL edits blames "ROWGUID or RECNUM columns not … automated or positioned at the wrong position", and the fix is to re-run the Content Migration Utility. The exact SQL definitions (IDENTITY? `uniqueidentifier DEFAULT NEWID()`/`ROWGUIDCOL`?) are **Unknown**.
- **Uniqueness:** the Catalog Browser refuses to save a record whose fields all exactly match another. A user recalls the check as MANUFACTURER + CATALOG + ASSEMBLYCODE (**Likely**). Out-of-the-box data may already contain duplicates. Whether SQL constraints or unique indexes enforce any of this is **Unknown**.
- **Indexes:** one forum user traced slow SQL lookups to tables that were not "properly keyed". No Autodesk guidance on indexes was found.

**Confidence:** Confirmed (order, structure, RECNUM). Likely (uniqueness key). Unknown (SQL keys and indexes).

**Sources**
- [Best Practices for Customizing the Catalog Database (2023)](https://help.autodesk.com/view/ACAD_E/2023/ENU/?guid=GUID-0EEFFB23-2229-4D1B-A4E7-F070220F5BD3)
- [About the Catalog Database Structure (2018)](https://help.autodesk.com/cloudhelp/2018/ENU/AutoCAD-Electrical/files/GUID-EB444995-30FB-4814-B41A-3BA8DDDD02D8.htm)
- [Autodesk – Unable to edit or add records to SQL database tables](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Unable-to-edit-or-add-records-to-SQL-database-tables-from-AutoCAD-Electrical.html)
- [Autodesk – Position of the RECNUM column](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/The-position-of-the-RECNUM-column-in-the-default-catalog-of-AutoCAD-Electrical.html)
- [Forum – Catalog Database (fields found by order)](https://forums.autodesk.com/t5/autocad-electrical-forum/catalog-database/td-p/7586462)
- [Forum – Unable to add duplicate record to catalog](https://forums.autodesk.com/t5/autocad-electrical-forum/unable-to-add-duplicate-record-to-catalog/td-p/8942662)
- [Forum – Catalog Lookup Slow When Using SQL](https://forums.autodesk.com/t5/autocad-electrical-forum/catalog-lookup-slow-when-using-sql/td-p/11294637)

**Impact on the design**
- **Every INSERT names its columns explicitly** and never supplies `RECNUM` or `ROWGUID`. Let the database defaults or identity fill them. If T4.1 shows they are *not* automatic on SQL, stop: the app must not invent values.
- **Adding an index on USER1** (for fast uniqueness checks) is a structural change to an ACADE table. It is not a column change, but it is still a footprint, and it could interact with the Migration Utility. **Don't**, unless the owner explicitly approves it.
- Upsert key: CATALOG + MANUFACTURER + ASSEMBLYCODE (not just CATALOG + MANUFACTURER). Handle existing duplicates as a report, not by merging them.

**Tests**
- T4.1 For a few family tables: `sp_help 'dbo.CB'`. Also query `sys.identity_columns`, `sys.default_constraints`, `sys.indexes`, `sys.key_constraints` and `sys.triggers` for the catalog database. Record how RECNUM and ROWGUID are generated, and whether any key or trigger exists.
- T4.2 Look for duplicates: `GROUP BY MANUFACTURER, CATALOG, ASSEMBLYCODE HAVING COUNT(*)>1` per table.
- T4.3 On a copy: insert a row through the app's planned column list, then open it, edit it and save it in the Catalog Browser. Check that RECNUM and ROWGUID were filled and that ACADE accepts the row.

---

## Q5. What upgrades, migration tools and Catalog Browser edits do to rows another app added

**Finding**
- Moving to a new release: Autodesk recommends `AEMIGRATION` to merge a custom catalog into the new release's default catalog. Merging **overwrites existing entries that match** incoming ones. Back up first. (**Likely**: the Autodesk article title is confirmed, but the overwrite detail comes from a forum answer.)
- For SQL catalogs, the **Content Migration Utility** is the tool. A reseller warns that "if the database has manually been modified outside of AutoCAD Electrical the database may not migrate." It is also the documented repair for SQL tables whose RECNUM or ROWGUID is broken. Whether it **drops and re-creates** tables (which would remove any index or trigger the app added, and any objects in the database) is **Unknown**.
- Catalog Browser edit/save: may create `_PINLIST_<MFR>` / `_TERMPROPS_<MFR>` tables. Whether saving rewrites only the changed rows or the whole table is **Unknown**. Autodesk has an article on "records disappear or do not get saved", which shows saving is not always atomic from the user's point of view.
- No source describes ACADE touching USER1 during a release upgrade, beyond the overwrite on merge.

**Confidence:** Likely (merge overwrites). Unknown (exact SQL behavior on upgrade).

**Sources**
- [Autodesk – Migrating custom MDB catalog to newer release](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Migrating-custom-MDB-catalog-to-newer-release-of-AutoCAD-Electrical.html)
- [Forum – Updating ACADE Catalog & Footprint Databases – SQL](https://forums.autodesk.com/t5/autocad-electrical-forum/updating-autocad-electrical-catalog-amp-footprint-databases-sql/td-p/8155317)
- [Autodesk – Add or modify records disappear or are not saved](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Add-or-modify-records-in-the-catalog-database-disappear-or-do-not-get-saved-in-AutoCAD-Electrical.html)
- [Autodesk – Converting catalog and footprint databases from Access to SQL results in errors](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/AutoCAD-Electrical-Converting-catalog-and-footprint-databases-from-Access-to-SQL-results-in-errors.html)
- [IMAGINiT – SQL Migration Part 2](https://resources.imaginit.com/how-tos/autodesk-autocad-electrical-sql-migration-part-2-of-2)

**Impact on the design**
- With zero footprint, **the catalog is the only record of issued numbers**. A merge that overwrites rows, or a rebuilt database, can **silently erase or change USER1 values**. The app cannot detect this unless it keeps an independent copy of what it issued (see Q9 and the export recommendation).
- Procedure: before any ACADE upgrade or migration run, take a full database backup and an app-side "USER1 snapshot" export. Afterwards, run a reconciliation (expected vs. actual USER1 per MFG/CAT/ASSEMBLYCODE).

**Tests**
- T5.1 On a restored copy, run the 2026 Content Migration Utility / `AEMIGRATION` in merge mode against it, using a custom row with USER1 set by the app. Compare before and after: row present? USER1 kept? RECNUM changed? Were the tables re-created (`sys.tables.create_date`)?

---

## Q6. Locking and concurrency: does ACADE hold long locks or open transactions?

**Finding**
- **No source** describes ACADE's transaction or lock behavior on SQL Server. Known facts: lookups "search the entire database for loading the content" (wide reads); there is a configurable query timeout (default 30 s); users report slowness over VPN. Nothing indicates that the Catalog Browser holds a transaction open while it is displayed, but nothing rules it out.
- The database's isolation settings (`READ_COMMITTED_SNAPSHOT`, `ALLOW_SNAPSHOT_ISOLATION`) are under the organization's control. **Changing them would be an interference**, so the app must work with whatever is set.

**Confidence:** Unknown.

**Sources**
- [Autodesk – SQL Server Timeout Error during catalog lookup](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/SQL-Server-Timeout-Error-when-performing-catalog-database-lookup-in-AutoCAD-Electrical.html)
- [Autodesk – Performance issue opening Catalog lookup through VPN](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Performance-issue-while-opening-Catalog-lookup-in-AutoCAD-Electrical-through-VPN.html)

**Impact on the design**
- Keep app transactions **very short**: milliseconds, no user interaction inside a transaction. A long app lock would make ACADE users hit the 30 s timeout.
- Set `LOCK_TIMEOUT` on the app's connections (for example 5 s) so that the app fails fast instead of queueing behind ACADE.

**Tests**
- T6.1 With the Catalog Browser open in edit mode (and separately in lookup mode, and during a BOM run), query `sys.dm_tran_active_transactions`, `sys.dm_tran_session_transactions`, `sys.dm_tran_locks` and `sys.dm_exec_sessions` (filter on ACADE's `program_name` / `host_name`). Record whether open transactions or X/IX/S locks persist.
- T6.2 `SELECT name, is_read_committed_snapshot_on, snapshot_isolation_state_desc FROM sys.databases WHERE name = '<catalog db>';`
- T6.3 While an ACADE user saves in the Catalog Browser, run the app's issue transaction in a loop. Watch for blocking (`sys.dm_os_waiting_tasks`) and for timeouts on either side.

---

## Q7. Safest pattern for another application to read and write catalog rows alongside ACADE

**Recommended pattern** (based on Microsoft-documented SQL Server behavior plus the ACADE constraints above; the ACADE side is still **Likely** until the tests pass):
1. **Least-privilege login** for the app: `db_datareader`, plus `INSERT`/`UPDATE` granted only on the family tables it maps to. No `DELETE`, no DDL, never `db_owner`. (Autodesk documents db_owner for ACADE read/write users; that is ACADE's need, not the app's.) `sp_getapplock` needs only membership in `public`.
2. **Discover tables and columns at run time** from `sys.tables` / `INFORMATION_SCHEMA.COLUMNS`. Check that the columns exist and their lengths. Refuse values that would be truncated.
3. **Inserts and updates name columns explicitly**. Never touch `RECNUM`, `ROWGUID` or any column the app does not own. Updates touch only the mapped columns (USER1, DESCRIPTION, …) and use `WHERE RECNUM = @recnum`, with an optimistic check that the old values are unchanged.
4. **Short transactions**, a `LOCK_TIMEOUT`, and retries on deadlock or timeout.
5. **Table names cannot be SQL parameters.** Build them only from a whitelist read from `sys.tables` and wrap them with `QUOTENAME()`. All values stay parameterized. *Note for the project lead:* CLAUDE.md says "No string-concatenated SQL, ever". Dynamic table names need a stated exception (whitelist + QUOTENAME) in the conventions. This is raised here, not decided.
6. Trim and upper-case keys; refuse leading or trailing spaces in CATALOG/MANUFACTURER.

**Sources**
- [Autodesk – SQL Server and Database Permissions for AutoCAD Electrical](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/SQL-Server-and-Database-Permissions-for-AutoCAD-Electrical.html)
- [Microsoft – Database-level roles](https://learn.microsoft.com/en-us/sql/relational-databases/security/authentication-access/database-level-roles?view=sql-server-ver17)
- [Microsoft – sp_getapplock](https://learn.microsoft.com/en-us/sql/relational-databases/system-stored-procedures/sp-getapplock-transact-sql)

**Test**
- T7.1 Create the app login on a copy with only the grants above. Run issue, insert and update end to end, and confirm that nothing needs more rights.

---

## Q8. Deleted rows and number reuse (the research note referenced by PART_NUMBER_STANDARD §1.3)

If the next sequence number is derived from `MAX(USER1)`, then **deleting the row that holds the highest number makes the next issue reuse that number**. Other failure modes:
- A USER1 value that ACADE users type by hand above the current maximum makes the sequence **jump**. If they type a format-valid value *below* the maximum, it can later **collide**. (The uniqueness check before commit catches the collision, but not the jump.)
- AEMIGRATION / merge or a restore from an older backup can remove high numbers. After that the next number is reused, and the ERP may already hold it.
- A format change (new prefix or width) changes which existing values match the pattern. The new format must start above the old maximum (PART_NUMBER_STANDARD §4 already notes this).
- Per-year scope: a reset is only safe when the year segment is part of the matching pattern.

Mitigations that need **no** app-owned objects:
- **Business rule: never delete released rows.** Mark them obsolete instead (for example a description prefix or a USER2/USER3 flag (needs a business decision, Q-###)). DELETE stays revoked from the app login. ACADE users with db_owner can still delete, so this is a policy, not an enforcement.
- **ERP cross-check:** when issuing, take the max over the catalog *and* the last ERP export (or the ERP itself, if it can be read). Numbers that have already left for the ERP then cannot be reused.
- **Configured floor:** a "next number must be ≥ N" value in the app's configuration file, raised automatically after each issue. This is weak: there is a single file per installation, and it diverges across seats unless it lives on a shared path.
- Append-only **export log** (CSV/JSON on a controlled file share) of every issued number. This is the app's own system of record outside SQL Server, and it is also the reconciliation source after ACADE upgrades.

---

## Q9. Zero-footprint feasibility

### Proposed mechanism
```sql
-- One short transaction, app login, READ COMMITTED (whatever the DB default is)
BEGIN TRAN;
DECLARE @rc int;
EXEC @rc = sp_getapplock @Resource = N'PNA:issue:<scope-key>',   -- e.g. global, or per {CAT}/{YY}
                          @LockMode = N'Exclusive',
                          @LockOwner = N'Transaction',
                          @LockTimeout = 5000;
IF @rc < 0 THROW 50001, 'Could not acquire PN issue lock', 1;

-- For each whitelisted family table (QUOTENAME), read candidate USER1 values that match
-- the format's LIKE prefix. Parse and validate the sequence segment in the app (regex from the template),
-- take the max, add 1, format, and recheck that the result is not present in ANY table.
-- INSERT/UPDATE the catalog row with the new USER1 (explicit column list).
COMMIT;   -- releases the app lock automatically
```
- `sp_getapplock` creates **no database objects**. The lock lives in the lock manager, and transaction-owned locks are released on COMMIT or ROLLBACK, including when the connection drops. This is Confirmed by Microsoft documentation. It serializes only PNA instances that use the same resource name. It does **not** block ACADE users (who don't take it), so the final "not present in any table" check inside the transaction is still required.
- The app lock does not stop an ACADE user from inserting the same USER1 between the check and the commit. To narrow that window, read with `UPDLOCK, HOLDLOCK` on the rows matching the prefix. This would take range locks on catalog tables that have no index on USER1, so it could escalate to a table scan and table locks, which conflicts with Q6. Recommendation: **don't** add those hints. Accept a tiny window and catch it with the reconciliation report. ACADE users don't issue numbers, by policy (rule 2).

### Costs and risks
- **Performance:** every issue scans USER1 in every family table (no index, and we should not add one). This is fine for tens of thousands of rows. Measure it on the real database (T9.1).
- **Reuse after deletion, restore or merge:** see Q8. Without a persistent high-water mark, the guarantee "never reused" (PART_NUMBER_STANDARD §1.3) **cannot be fully met** using SQL Server alone. It needs the ERP cross-check or the external log.
- **Legacy and hand-typed USER1 values** that happen to match the pattern affect the maximum. The clean-up report (§4 of the standard) becomes a prerequisite for go-live.
- **No reservation step:** a number exists only once it has been written to a catalog row. "Reserve a number while the request is under review" is not possible without storage. The number has to be issued together with the row insert.

### What the app gives up with zero objects
| Capability | Zero footprint | With an app-owned area (separate DB preferred) |
|---|---|---|
| Issue a unique next number | Yes (applock + MAX + recheck) | Yes (sequence table), with a reliable high-water mark |
| Never reuse after delete or restore | Only with ERP cross-check / external log | Yes |
| Draft → review → approve workflow, roles | No shared state (would need files or the ERP) | Yes |
| Audit trail / history of description changes | External log files only | Yes |
| Structured attributes for description generation | Only what fits in ACADE columns (TYPE, RATING*, MISC*, USER2/3, TEXTVALUE) | Yes |
| Format and settings shared by all users | Shared config file | Yes, in the DB |
| Recovery after ACADE upgrade or merge | Re-create from the external log | Re-sync from the system of record |

### Recommendation
1. **Zero footprint inside the catalog database is feasible, and is the right default** for the issue-and-write function, given the owner's preference and the unresolved risk that objects (even in a `pnm` schema) appear as ACADE categories (Q2). Use: a configurable connection; a least-privilege login; `sp_getapplock` (transaction-owned, resource name per sequence scope); MAX over pattern-matching USER1 values across whitelisted family tables; a re-check of uniqueness across all tables before commit; and an explicit-column INSERT/UPDATE, all in one short transaction.
2. **Do not claim the "never reused" guarantee** unless one of these is also in place: (a) a no-delete policy plus revoked DELETE, (b) an ERP high-water cross-check, or (c) an append-only issued-number log on a controlled share. (b) together with (c) is the strongest combination that needs no SQL objects.
3. **If workflow, approval, audit or attribute storage is in scope** (as SCOPE_OF_WORK and ADR-0002 assume), the app needs storage. Put it in a **separate database on the same instance**, not in the catalog database. This keeps ACADE's enumeration untouched (Likely) and avoids the Q2 risk. ADR-0002's primary option (the `pnm` schema in the catalog database) should be downgraded until T2.1/T2.2 prove that ACADE ignores other schemas. The project lead should put this to the owner, perhaps as a new open question.
4. Never add indexes, triggers, constraints or columns to ACADE tables, and never change database options (RCSI, recovery model, compatibility level).

---

## Tests to run on the organization's server

Run them on a **restored copy** of the catalog database, with an ACADE 2026 seat pointed at the copy, unless a test is marked read-only.

| ID | Test | Read-only on production? |
|---|---|---|
| T1.1 | Record the connection details and authentication from Configure Database on each seat; confirm all seats use one database | Yes |
| T2.1 | Add a probe table, a view and a `pnm` schema table one at a time; check the Category list, Lookup, Global Search, Browser save and BOM | No (copy) |
| T2.2 | Trace ACADE's metadata queries (Extended Events) at start-up, in the Catalog Browser and during Global Search | Yes (trace only) |
| T3.1 | Export INFORMATION_SCHEMA.COLUMNS: USER1 type and length per table, and whether QUERY1–3 exist | Yes |
| T3.2 | USER1 inventory: non-empty counts and distinct samples per table | Yes |
| T3.3 | BOM / panel BOM showing USER1; change USER1 in SQL and check whether the report refreshes without re-assigning | No (copy) |
| T4.1 | How RECNUM and ROWGUID are generated; identity, defaults, indexes, keys, triggers | Yes |
| T4.2 | Duplicate MFG + CATALOG + ASSEMBLYCODE per table | Yes |
| T4.3 | Insert a row the way the app would, then edit and save it in the Catalog Browser | No (copy) |
| T5.1 | Run Content Migration Utility / AEMIGRATION merge over app-written rows; is USER1 kept, are tables re-created? | No (copy) |
| T6.1 | Open transactions and locks held by ACADE sessions with the Browser open (edit and lookup) and during a BOM run | Yes (DMV reads) |
| T6.2 | Database RCSI and snapshot settings | Yes |
| T6.3 | Concurrent app issue loop while ACADE saves; watch blocking and timeouts | No (copy) |
| T7.1 | The app login with least-privilege grants completes the end-to-end flow | No (copy) |
| T9.1 | Time the MAX(USER1) scan across all family tables at production row counts | Yes (reads) |
| T9.2 | Two app instances issue numbers in parallel (1,000 each); expect no duplicates and no gaps from collisions | No (copy) |
| T9.3 | Delete the highest-numbered row and issue again; confirm the reuse is detected by the ERP / log cross-check | No (copy) |
