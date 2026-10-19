# CLAUDE.md

Working rules for Claude Code (and its subagents) in this repository.

## Project in one sentence
A C# / WPF desktop app that issues controlled part numbers and generates standardized descriptions, stored alongside the AutoCAD Electrical SQL Server catalog and exported to the ERP.

## Ground rules
1. **Never alter AutoCAD Electrical's own table structure.** No dropping, renaming or retyping of ACADE catalog columns. The app's own data lives in the `pnm` schema (see ADR-0002). Writes to ACADE catalog tables only insert or update rows, through the sync service, inside transactions.
2. **Part numbers are issued only by the database sequence logic** (`pnm.usp_IssuePartNumber`). Never generate them client-side.
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
- All SQL is parameterized. No string-concatenated SQL, ever.
- SQL schema changes are numbered scripts in `db/schema/NNN_description.sql`, idempotent where possible.
- Commit messages: imperative mood, short summary line, body explains why.

## Agents
See `.claude/agents/`. Use `project-lead` to coordinate multi-role work. Use the specialist directly for focused tasks.
