# Roadmap

## Phase 0: Discovery and standards (current)
- [ ] Answer the blocking open questions (Q-001 to Q-004)
- [ ] Verify the ACADE catalog schema (D2). Owner: acade-db-specialist
- [ ] Approve the Part Number Standard and Description Standard (D1). Owner: part-standards-engineer + Engineering lead
- [ ] Define attribute sets for 3 pilot categories (Relay, Circuit Breaker, Terminal Block)
- [ ] Agree the ERP export column layout (Q-005). Owner: erp-integration-specialist
- [ ] Accept ADR-0002 and finalize the architecture (D3). Owner: solution-architect

## Phase 1: Core (MVP)
- [ ] Create the solution skeleton, CI build, and test projects
- [ ] `pnm` schema scripts: Category, AttributeDefinition, Manufacturer, Part, PartAttribute, PartNumberSequence, Abbreviation, AuditLog
- [ ] `usp_IssuePartNumber` with a concurrency test
- [ ] Description generator + unit tests for each pilot category
- [ ] Duplicate check (MFR + normalized MPN)
- [ ] WPF: Create Part wizard, Search screen
- [ ] Milestone **M1:** create and search pilot-category parts against a dev DB

## Phase 2: Workflow and ACADE sync
- [ ] Lifecycle, roles and approvals
- [ ] Audit log viewer
- [ ] ACADE sync service + SyncLog + retry
- [ ] Admin screens (categories, attributes, abbreviations, manufacturers)
- [ ] User guide v1
- [ ] Milestone **M2:** released pilot parts show up in AutoCAD Electrical catalog lookup

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
