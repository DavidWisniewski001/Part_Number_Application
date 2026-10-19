# Roadmap

## Phase 0: Discovery and standards (current)
- [x] Q-001, Q-003, Q-004 answered. Q-002 settled as zero footprint (ADR-0003)
- [x] Compatibility research (`docs/research/`). Owner: acade-compatibility-researcher
- [ ] Run `db/discovery/` scripts on the server and the copy-only tests from the research report (D2). Owner: acade-db-specialist
- [ ] Decide Q-013 (workflow/history wanted?)
- [ ] Approve the Part Number Standard and Description Standard (D1). Owner: part-standards-engineer + Engineering lead
- [ ] Define attribute sets for 3 pilot categories (Relay, Circuit Breaker, Terminal Block)
- [ ] Agree the ERP export column layout (Q-005). Owner: erp-integration-specialist
- [ ] Finalize the architecture after the server tests (D3). Owner: solution-architect

## Phase 1: Core (MVP)
- [ ] Create the solution skeleton, CI build, and test projects
- [ ] Connection setup screen + test connection
- [ ] Shared settings file (schema, loader, validation)
- [ ] Part number format engine (template → generator + matching pattern) + format builder screen with presets
- [ ] Issuance flow (`sp_getapplock` + highest USER1 + re-check) with a parallel-users integration test
- [ ] Description generator + unit tests for each pilot category
- [ ] Duplicate check (MFR + normalized MPN)
- [ ] WPF: Create Part wizard, Search screen
- [ ] Milestone **M1:** create and search pilot-category parts against a dev DB

## Phase 2: Existing catalog and admin
- [ ] Assign numbers to existing catalog rows with an empty USER1
- [ ] USER1 clean-up report (values that don't match the format, duplicates)
- [ ] Issuance log viewer
- [ ] (If Q-013 = yes) companion database: workflow, roles, history
- [ ] Admin screens (categories, attributes, abbreviations, manufacturers)
- [ ] User guide v1
- [ ] Milestone **M2:** parts created by the app show up in the AutoCAD Electrical Catalog Browser and BOM with USER1

## Phase 3: ERP and legacy
- [ ] ERP CSV export (full + delta)
- [ ] Legacy import from the ACADE catalog / ERP list, plus a duplicate clean-up report
- [ ] Reconciliation report (ERP vs app vs ACADE)
- [ ] Pilot UAT, then production rollout
- [ ] Milestone **M3:** go-live for electrical parts

## Later (not committed)
- Direct ERP API integration
- Datasheet attachment storage
- Non-electrical categories
- Bulk edit and mass re-description when templates change
