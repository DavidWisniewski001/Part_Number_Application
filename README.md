# Part Number Application

A small Windows desktop application (C# / .NET) that works directly with the **AutoCAD Electrical 2026 SQL Server catalog database**. It creates nothing on the server, and stores the organization's part number in `USER1`. It is the single place where the organization creates part numbers and standardized part documentation, so that every part entered into the business management (ERP) system is consistent, de-duplicated, and searchable.

> Status: **Project kickoff / Phase 0 (Discovery).** No application code yet. See [docs/ROADMAP.md](docs/ROADMAP.md).

## The problem

- The same physical part gets entered several times under different descriptions ("24V RELAY", "Relay 24VDC 4PDT", "RLY,24VDC,4PDT").
- Part numbers are assigned by hand, with no single numbering authority.
- The ACADE catalog and the ERP drift apart, so BOMs from drawings don't match what purchasing sees.

## The solution (summary)

1. **One numbering authority.** The app issues part numbers in the structure each customer chooses (presets or custom). Nobody types a number in by hand.
2. **Structured descriptions.** Users fill in category-specific attributes. The app generates the description from a template (noun, modifier, ordered attributes, controlled abbreviations).
3. **Duplicate prevention.** Before a number is issued, the app checks the manufacturer, the normalized manufacturer part number, and key attributes.
4. **Zero footprint.** Parts are written straight into the ACADE family tables. No extra tables, schemas or procedures, so ACADE works exactly as before.
5. **Optional approval workflow** (only with a companion database, Q-013).
6. **ERP export.** A clean, validated export (CSV first) for import into the business management software.

## Repository layout

| Path | Contents |
|---|---|
| `docs/SCOPE_OF_WORK.md` | What is in and out of scope, deliverables, acceptance criteria |
| `docs/ARCHITECTURE.md` | Solution structure, technology choices, data flow |
| `docs/PART_NUMBER_STANDARD.md` | Draft part number format and lifecycle rules |
| `docs/DESCRIPTION_STANDARD.md` | Draft description and attribute conventions |
| `docs/ACADE_DATABASE_NOTES.md` | What we know (and must verify) about the ACADE catalog schema |
| `docs/ROADMAP.md` | Phases, milestones, initial backlog |
| `docs/OPEN_QUESTIONS.md` | Decisions needed from the organization |
| `docs/GLOSSARY.md` | Terms |
| `docs/adr/` | Architecture Decision Records |
| `docs/research/` | AutoCAD Electrical 2026 compatibility research |
| `db/discovery/` | Read-only scripts to inspect the catalog database |
| `db/companion-db/` | Optional companion database (on hold, never in the catalog database) |
| `.claude/agents/` | Claude Code subagents for each project role |
| `CLAUDE.md` | Working rules for Claude Code in this repo |

## Project agents

The `.claude/agents/` folder defines one specialist subagent per role. In Claude Code, ask for one by name (for example, "use the acade-db-specialist to map the relay table").

| Agent | Role |
|---|---|
| `project-lead` | Owns scope, roadmap, open questions, and coordination between agents |
| `solution-architect` | Solution structure, layering, ADRs, technology decisions |
| `acade-db-specialist` | AutoCAD Electrical catalog schema, SQL, migrations, sync rules |
| `part-standards-engineer` | Part number format, description templates, attribute dictionaries |
| `csharp-developer` | Domain, services and data access in C# |
| `wpf-ui-developer` | WPF / MVVM desktop UI |
| `erp-integration-specialist` | Export and import with the business management software |
| `qa-test-engineer` | Test strategy, unit and integration tests, code review for defects |
| `technical-writer` | User guide, admin guide, release notes |
| `acade-compatibility-researcher` | Researches ACADE 2026 catalog behavior, so the app never interferes |
