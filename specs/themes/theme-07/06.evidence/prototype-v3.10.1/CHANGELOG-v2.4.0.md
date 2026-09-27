# v2.4.1 — BJ01 migration + BJ08 deep correction

- Cumulative from v2.3.0.
- Migrated UIF-01/BJ01 against the live Figma DS: one list, Search & Filter Header, VChip, canonical List Row, single-primary availability detail, LOT/provenance contextual sheets and BJ15 trace handoff.
- Removed legacy BJ01 tabs/card-per-product/redundant action patterns from the active renderer.
- Deep-corrected UIF-08/BJ08 after v2.3.0 audit.
- Corrected maker/approver task separation, session-owned cancellation, request-review mutation, terminal result finality and UNKNOWN recovery semantics.
- Removed the temporary Theme7TimeField from active BJ08; cut-off is rendered read-only because the current Product flow resolves it before SCR-043.
- Reworked blind-count DOM behavior and recount interaction; evidence/price-basis remains authoritative status rather than invented input schema.
- Applied live Figma component anatomy references and semantic variables; Core DS labels are not used for Theme7-only compositions.
- Added dedicated 36-check BJ01/BJ08 Product + Figma DS QA and v2.4.1 all-flow smoke.
