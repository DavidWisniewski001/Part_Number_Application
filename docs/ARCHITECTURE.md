# Architecture (draft)

## 1. Context

```
 ┌──────────────────────┐        ┌────────────────────────────────────────┐
 │ Part Number App      │  SQL   │ SQL Server (ACADE catalog instance)    │
 │ (WPF desktop, .NET)  │───────▶│  ├─ dbo.*  ACADE catalog tables        │
 └──────────────────────┘        │  └─ pnm.*  App-owned schema            │
          │                      └────────────────────────────────────────┘
          │ CSV export                        ▲
          ▼                                   │ catalog lookup
 ┌──────────────────────┐        ┌────────────┴───────────┐
 │ Business mgmt / ERP  │        │ AutoCAD Electrical     │
 └──────────────────────┘        └────────────────────────┘
```

- **pnm schema** holds the master record for each part: number, attributes, lifecycle and audit.
- **ACADE catalog tables** are a *downstream projection* of released parts, written by the sync service.
- **ERP** receives a downstream projection through export.

The app's master data never depends on ACADE columns it doesn't control. ACADE gets what it needs to do catalog lookups and BOMs.

## 2. Solution structure

```
src/
  PartNumber.Domain/          Entities, value objects, rules (no I/O)
  PartNumber.Application/     Use cases: CreatePart, ReleasePart, Search, Export...
  PartNumber.Infrastructure/  SQL (Dapper), ACADE sync, CSV export, logging
  PartNumber.Desktop/         WPF views + view models (MVVM), DI composition root
tests/
  PartNumber.Domain.Tests/
  PartNumber.Application.Tests/
  PartNumber.Infrastructure.Tests/   (Testcontainers SQL Server)
db/schema/                    Numbered SQL scripts for the pnm schema
```

Dependencies point inward: Desktop → Application → Domain, and Infrastructure → Application/Domain.

## 3. Technology choices
| Concern | Choice | Why |
|---|---|---|
| Runtime | .NET 10 LTS | Current LTS, supported to late 2028 |
| UI | WPF + CommunityToolkit.Mvvm | Mature Windows desktop. Engineers are on Windows anyway (ACADE) |
| Data access | Microsoft.Data.SqlClient + Dapper | ACADE tables are wide, legacy-shaped and vary by category. Plain SQL is clearer than an ORM here |
| DI / config / logging | Microsoft.Extensions.* + Serilog | Standard |
| Tests | xUnit, FluentAssertions, Testcontainers.MsSql | Real SQL Server in tests |
| Auth | Windows Integrated Security; roles in `pnm.UserRole` mapped to AD accounts/groups | No passwords to manage |
| Packaging | MSIX or self-contained single-folder publish | Simple deployment |

See ADRs for decisions that are still open.

## 4. Key domain concepts
- **Category:** e.g. Relay, Circuit Breaker, Terminal Block. It has a PN prefix, an attribute set, a description template, and a mapping to an ACADE catalog table.
- **AttributeDefinition:** name, data type, unit, allowed values, required flag, sort order in the description.
- **Part:** PN, category, attribute values, manufacturer, MPN, generated description, lifecycle status, revision.
- **Manufacturer:** controlled list with a canonical name and aliases.
- **Lifecycle:** Draft → InReview → Released → Obsolete. Released parts are immutable except for an allowed field list. Changes create a revision or a new part, per the standard.

## 5. Critical flows
### 5.1 Issue part number
1. User completes the wizard. The domain validates attributes.
2. The duplicate check runs (application service + SQL query).
3. `pnm.usp_IssuePartNumber @CategoryId` runs in a serializable transaction against `pnm.PartNumberSequence`, returns the next PN, and inserts the Part row. This prevents two users getting the same number.

### 5.2 Release and ACADE sync
1. A reviewer approves. Status becomes Released.
2. The sync service resolves the ACADE target table from `pnm.Category.AcadeTable`, then upserts by `CATALOG` + `MANUFACTURER` (verify key). It writes the internal PN into the configured field (see Q-003).
3. The sync result is logged in `pnm.SyncLog`. Failures are retryable from the admin screen.

### 5.3 ERP export
Export view `pnm.vw_ErpExport` → CSV with a column map from configuration. Delta exports use `pnm.ExportBatch`.

## 6. Security
- Least privilege: the app's AD group gets full rights on `pnm`. On `dbo`, it gets SELECT, plus INSERT/UPDATE only on the mapped ACADE catalog tables.
- All SQL is parameterized. Dynamic table names for ACADE tables are **validated against `pnm.Category.AcadeTable` and `sys.tables`**, then quoted with `QUOTENAME`.

## 7. Open architecture questions
See `docs/OPEN_QUESTIONS.md` (Q-001, Q-002, Q-003, Q-006).
