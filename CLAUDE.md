# CLAUDE.md

Working rules for Claude Code (and its subagents) in this repository.

## Project in one sentence
A C# / WPF desktop app that issues controlled part numbers (stored in `USER1`) and generates standardized descriptions, directly in the AutoCAD Electrical 2026 SQL Server catalog, with export to the ERP.

## Ground rules
1. **Zero footprint in the catalog database (ADR-0003).** Never create, alter or drop anything there: no tables, views, schemas, procedures, triggers, indexes or columns. Only row INSERT/UPDATE on existing family tables, with explicit column lists. Never write `RECNUM`/`ROWGUID`. Never DELETE. Use short transactions with a lock timeout.
2. **Part numbers are issued only by the issuance flow** in ARCHITECTURE §5.1 (`sp_getapplock` + highest matching `USER1` + uniqueness re-check, all in one transaction). Never assign a number outside that flow.
3. **Descriptions are generated, not typed.** Any change to description rules goes through `docs/DESCRIPTION_STANDARD.md` first, then code.
4. **Standards documents are the source of truth.** If code and `docs/*_STANDARD.md` disagree, raise it. Do not silently "fix" either one.
5. **Record significant decisions** as an ADR in `docs/adr/` (copy the format of ADR-0001).
6. **Unverified facts about the ACADE schema** must be marked `(verify)` until they have been checked against the organization's real catalog database.
7. **Open questions** for the business go in `docs/OPEN_QUESTIONS.md` with an ID (`Q-###`). Don't guess at business rules.

## Tech stack (planned; see docs/ARCHITECTURE.md)
- .NET 10 (LTS), C# latest, nullable enabled, warnings as errors
- WPF + CommunityToolkit.Mvvm
- Microsoft.Data.SqlClient + Dapper
- xUnit + FluentAssertions; Testcontainers (SQL Server) for integration tests
- Target DB: SQL Server 2019+ (the ACADE catalog instance)

## Conventions
- Solution layout: `src/PartNumber.{Domain,Application,Infrastructure,Desktop}`, `tests/PartNumber.*.Tests`
- All values are parameters. The only dynamic SQL allowed is family-table names, whitelisted from `INFORMATION_SCHEMA` and wrapped in `QUOTENAME` (ADR-0003 §6).
- `db/discovery/` holds read-only inspection scripts. `db/companion-db/` is optional and must never be run in the catalog database.
- Commit messages: imperative mood, short summary line, body explains why.

## Agents
See `.claude/agents/`. Use `project-lead` to coordinate multi-role work. Use the specialist directly for focused tasks.
