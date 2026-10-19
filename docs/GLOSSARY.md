# Glossary

| Term | Meaning |
|---|---|
| ACADE | AutoCAD Electrical |
| Catalog database | ACADE's database of purchasable components, used for catalog lookup and BOM reports |
| PN | Internal part number issued by this application |
| MPN | Manufacturer part number (ACADE `CATALOG` field) |
| MFR | Manufacturer |
| ERP | The business management software that receives parts |
| Category | Grouping of parts with a shared attribute set, description template and PN prefix |
| Noun-modifier | Description convention: `NOUN, MODIFIER: attributes` |
| Released | Lifecycle state in which a part is approved for use (only with the optional workflow) |
| Family table | An ACADE catalog table for one component family (e.g. `CB`, `CR`, `PB`) |
| `USER1` | ACADE catalog user field that holds the organization's part number |
| Shared settings file | JSON file holding format, categories, templates and abbreviations, used by every workstation |
| Companion database | Optional separate database (never the catalog DB) for workflow and history |
| Issuance log | Append-only file listing every part number issued |
| ADR | Architecture Decision Record |
