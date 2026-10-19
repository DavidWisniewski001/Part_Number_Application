# Architecture (draft)

Key decision: **ADR-0003, zero footprint.** The app creates nothing in the AutoCAD Electrical catalog database. It reads and writes rows in the existing ACADE family tables only, and stores the organization's part number in `USER1`.

## 1. Context

```
 ┌───────────────────────────┐  SQL (rows only) ┌──────────────────────────────────┐
 │ Part Number App           │─────────────────▶│ SQL Server: ACADE 2026 catalog   │
 │ (WPF desktop, .NET 10)    │                  │  family tables (CB, CR, PB, ...) │
 └───────────────────────────┘                  │  USER1 = organization PN         │
     │            │                             └──────────────────────────────────┘
     │ reads      │ CSV export                              ▲
     ▼            ▼                                         │ Catalog Browser / BOM
 ┌─────────────┐ ┌──────────────────────┐        ┌──────────┴──────────────┐
 │ Shared      │ │ Business mgmt / ERP  │        │ AutoCAD Electrical 2026 │
 │ settings    │ └──────────────────────┘        └─────────────────────────┘
 │ file (JSON) │
 └─────────────┘
       ┆ optional, only if Q-013 = yes
 ┌─────────────────────────────────────────────┐
 │ Companion DB (same instance, NOT catalog DB)│  workflow, history, attributes
 └─────────────────────────────────────────────┘
```

- **The ACADE catalog is the system of record** for parts. A part exists once its catalog row exists, with `USER1` filled in.
- **Shared settings file:** connection, part number format, categories (code → family table), attribute definitions, description templates, abbreviations, manufacturer list and aliases, ERP export map. An admin owns it. Every workstation reads the same file (network share or deployed copy).
- **Companion database:** only built if the organization wants approvals, history or stored attributes (Q-013). It is never inside the catalog database.

## 2. Solution structure

```
src/
  PartNumber.Domain/          Format engine, description generator, rules (no I/O)
  PartNumber.Application/     Use cases: CreatePart, Search, Export, CheckDuplicates...
  PartNumber.Infrastructure/  ACADE catalog access (Dapper), settings file, CSV export, logging
  PartNumber.Desktop/         WPF views + view models (MVVM), DI composition root
tests/
  PartNumber.Domain.Tests/
  PartNumber.Application.Tests/
  PartNumber.Infrastructure.Tests/   (Testcontainers SQL Server with a copy of the catalog schema)
db/discovery/                 Read-only scripts to inspect the organization's catalog
db/companion-db/              Optional companion database (on hold)
```

## 3. Technology choices
| Concern | Choice | Why |
|---|---|---|
| Runtime | .NET 10 LTS | Current LTS |
| UI | WPF + CommunityToolkit.Mvvm | Windows desktop, the same machines that run ACADE |
| Data access | Microsoft.Data.SqlClient + Dapper | Wide, legacy-shaped ACADE tables. Explicit SQL is clearer |
| Settings | JSON file + JSON schema validation | No database objects needed |
| Logging | Serilog: rolling local log + append-only **issuance log** on the shared path | Audit trail without a database |
| Tests | xUnit, FluentAssertions, Testcontainers.MsSql | Real SQL Server in tests |
| Auth | Windows Integrated (default) or SQL login | Same as ACADE seats |

## 4. Key domain concepts
- **PartNumberFormat:** template from `PART_NUMBER_STANDARD.md` (e.g. `{CAT}-{SEQ:6}`). Compiles to a generator and a matching pattern. Has a sequence scope and an optional floor.
- **Category:** code, name, noun/modifier, attribute definitions, target ACADE family table, and a map from attributes to ACADE columns (e.g. coil voltage → `RATING1`; verify per table).
- **CatalogPart:** one row in a family table. Contains `CATALOG` (MPN), `MANUFACTURER`, `DESCRIPTION`, `ASSEMBLYCODE`, `USER1` (PN), plus mapped attribute columns.

## 5. Critical flows
### 5.1 Create part and issue number (one short transaction)
1. The user completes the wizard. The domain validates attributes and generates the description.
2. Duplicate check: the same `MANUFACTURER + CATALOG + ASSEMBLYCODE` in any family table, plus fuzzy MPN and description matches.
3. `BEGIN TRAN` with `SET LOCK_TIMEOUT 5000`, then `sp_getapplock 'PartNumberApp.Issue', 'Exclusive', 'Transaction'`.
4. Read the matching `USER1` values across the whitelisted family tables (filtered by format prefix and scope) and take the highest sequence value (or the floor, if higher). Add 1 and build the PN.
5. Re-check that `USER1 = @PN` exists nowhere.
6. Insert the row with an explicit column list (never `RECNUM`/`ROWGUID`), or update `USER1` on an existing row that has no number yet. `COMMIT`.
7. Write a line to the append-only issuance log (PN, MFR, MPN, table, user, time).

### 5.2 Search
A query across family tables on `USER1`, `CATALOG`, `MANUFACTURER` and `DESCRIPTION`. Filters by category (table) and attributes (mapped columns). Read-committed, short queries.

### 5.3 Assign numbers to existing catalog rows
Lists rows with an empty `USER1`. The admin picks rows, and the app issues numbers through flow 5.1 steps 3–7 (update instead of insert).

### 5.4 ERP export
Reads rows with `USER1` set that match the format → CSV through the configured column map. A delta export uses the issuance log.

## 5a. Connecting to the catalog server
AutoCAD Electrical 2026 already uses a SQL Server catalog, so the app connects to the **same server and database that ACADE uses**.

- **First-run setup screen:** server/instance (e.g. `SQLSRV01\ACADE`), database name, and authentication (Windows Integrated by default; SQL login optional). Includes a **Test connection** button that checks:
  1. the connection opens;
  2. the database contains recognizable ACADE family tables (with `CATALOG`, `MANUFACTURER`, `DESCRIPTION`, `USER1` columns);
  3. the `USER1` length in each table is at least the longest number the format can produce;
  4. the current user's rights (read / write on the family tables).
- The path to the shared settings file is saved per machine in `%ProgramData%\PartNumberApp\local.json`. SQL passwords, if used, are encrypted with Windows DPAPI.
- The connection string is built with `SqlConnectionStringBuilder`. `Encrypt=True` by default, with an option to trust the server certificate on-premises.
- **Read-only mode** activates automatically if the user has no write rights.

## 6. Security and safety
- **No DDL, ever,** in the catalog database. The SQL login used by the app needs only `SELECT`, plus `INSERT`/`UPDATE` on family tables. No `DELETE`, no `ALTER`.
- All values are parameters. Family-table names are the only dynamic SQL: whitelisted from `INFORMATION_SCHEMA.COLUMNS` (the table must have the core columns) and wrapped in `QUOTENAME` (ADR-0003 §6).
- Transactions are short, with a lock timeout. They never stay open while waiting on user input.
- Text lengths are checked against the real column lengths before writing. Truncation is an error.

## 7. Open items
Q-005 (ERP), Q-011 (alternates), Q-013 (workflow/history), and the server tests in `docs/research/ACADE_2026_CATALOG_COMPATIBILITY.md`.
