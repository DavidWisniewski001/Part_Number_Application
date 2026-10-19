# Scope of Work: Part Number Application

| | |
|---|---|
| Document status | Draft v0.1, for review |
| Date | 2026-10-19 |
| Owner | Project lead (TBD) |

## 1. Purpose
Build a small internal C# desktop application that uses the AutoCAD Electrical (ACADE) SQL Server catalog database as its backend. It will:
- issue unique, controlled part numbers;
- produce consistent, structured part documentation (descriptions, attributes, manufacturer data);
- keep the ACADE catalog and the business management software (ERP) aligned, so parts are consistent and searchable everywhere.

## 2. Background and problem statement
Parts are currently created by hand, in more than one system, with free-text descriptions. This causes duplicate parts, inconsistent descriptions that defeat search, mismatches between drawing BOMs and purchasing, and rework for engineering and purchasing.

## 3. Objectives and success measures
| # | Objective | Measure |
|---|---|---|
| O1 | Single numbering authority | 100% of new electrical parts get their number from the app |
| O2 | Consistent descriptions | 100% of released parts have template-generated descriptions that pass validation |
| O3 | Fewer duplicates | Duplicate-candidate check runs on every new part; duplicates found in pilot are tracked to zero |
| O4 | ACADE ↔ ERP alignment | A released part appears in the ACADE catalog and the ERP export with identical PN, description, manufacturer and MPN |
| O5 | Findability | A user can find an existing part by keyword, manufacturer, MPN or attribute in under 30 seconds |

## 4. In scope
### 4.1 Functional
1. **Part creation wizard:** pick a category, enter attributes, manufacturer and MPN; see a live preview of the generated description.
2. **Part number issuance:** safe for concurrent users. Stored in `USER1`. Uses the **structure the customer configures** (presets or custom builder, `PART_NUMBER_STANDARD.md`).
3. **Description generation:** template-driven per category, following `DESCRIPTION_STANDARD.md`, including the controlled abbreviation list.
4. **Duplicate detection:** exact and fuzzy match on manufacturer + normalized MPN, plus attribute similarity within the category. Warn and require justification to proceed.
5. **Search and browse:** keyword, category, manufacturer, MPN, attribute filters, and lifecycle status.
6. **Lifecycle workflow (optional, Q-013):** Draft → In Review → Released → Obsolete. Needs the companion database.
7. **Catalog write:** insert a new family-table row (CATALOG, MANUFACTURER, DESCRIPTION, mapped attributes, USER1), or assign a number to an existing row that has an empty USER1.
8. **ERP export:** CSV export (released parts, or changes since the last export) in a column layout agreed with the ERP owner.
9. **Administration:** maintain categories, attribute definitions, templates, abbreviations, manufacturers and users/roles.
10. **Audit trail:** an append-only issuance log (who issued which number, when, for which row). Full change history only with the companion database (Q-013).
11. **Legacy import (one-time):** import existing ACADE catalog and/or ERP part lists into Draft or "Legacy" status for clean-up.

### 4.2 Non-functional
- Windows 10/11 desktop, domain users. Windows Authentication to SQL Server.
- 5–25 concurrent users. Responsive search (<1 s typical) on 100k parts.
- **Zero footprint:** no objects created in the catalog database. Only rows in existing family tables (ADR-0003). Part number in `USER1`.
- Connects to the organization's existing AutoCAD Electrical 2026 SQL Server catalog through a setup screen.
- Installable through MSIX or a simple self-contained publish. No admin rights needed to run.
- Logging to file. Errors are shown to users in plain language.

## 5. Out of scope (this phase)
- Direct, live, two-way API integration with the ERP (CSV first; API is a later phase, see Q-005).
- Editing ACADE symbol libraries, schematic/panel footprints or the footprint lookup database.
- Pricing, inventory, or supplier quoting.
- Web or mobile clients.
- Mechanical/non-electrical part categories (the design allows them; they come later).
- PLM/PDM document vaulting (datasheets are stored as links or paths only).

## 6. Deliverables
| ID | Deliverable | Phase |
|---|---|---|
| D1 | Approved Part Number Standard and Description Standard | 0 |
| D2 | Verified ACADE catalog schema map for the organization's database | 0 |
| D3 | Architecture document + ADRs | 0–1 |
| D4 | Shared settings file schema, setup screens (connection, part number format builder), deployment instructions | 1 |
| D5 | Desktop application (create, search, number issuance, descriptions) | 1–2 |
| D6 | Workflow, audit, admin screens | 2 |
| D7 | Assign numbers to existing catalog rows + USER1 clean-up report | 2 |
| D8 | ERP CSV export | 3 |
| D9 | Legacy import + clean-up report | 3 |
| D10 | User guide, admin guide, release notes | 2–3 |
| D11 | Automated test suite (unit + integration) | ongoing |

## 7. Assumptions
- AutoCAD Electrical 2026 with its catalog on SQL Server (confirmed, Q-001).
- A non-production copy of the catalog database is available for development and testing.
- Users (or an app login) can be granted SELECT/INSERT/UPDATE on the catalog family tables.
- The ERP accepts a CSV (or Excel) item import.

## 8. Constraints and risks
| Risk | Impact | Mitigation |
|---|---|---|
| ACADE schema differs by version or customization | Sync breaks | Verify schema early (D2). Keep table/column mapping configurable |
| ACADE upgrade overwrites or changes catalog | Data loss or sync errors | App data lives in its own schema. Re-runnable sync. Backup before upgrade |
| Users bypass the app and add parts directly in ERP or ACADE | Inconsistency returns | Process change + periodic reconciliation report |
| Numbering standard not agreed | Blocks Phase 1 | Make it the first decision. Draft provided |
| Legacy data is messy | Long clean-up | Import as "Legacy" status. Clean up incrementally |

## 9. Acceptance criteria (Phase 1–3 complete)
1. A user creates a part in under 2 minutes, and gets a unique PN and a description that passes validation.
2. Creating a part whose MFR + MPN already exists is blocked or warned, per the configured policy.
3. Releasing a part makes it appear correctly in the ACADE catalog lookup within AutoCAD Electrical.
4. The ERP export imports cleanly into the ERP test environment with no manual edits.
5. All actions are visible in the audit log.
6. The integration test suite passes against a SQL Server instance with a copy of the catalog schema.

## 10. Stakeholders (to be filled in)
| Role | Name | Responsibility |
|---|---|---|
| Sponsor | | Funding, priority |
| Engineering lead | | Standards approval, ACADE owner |
| Purchasing / ERP owner | | ERP field mapping, import testing |
| IT / DBA | | SQL Server access, backups, deployment |
| Pilot users | | UAT |
