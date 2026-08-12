# Theme 7 — Phase 2 Mapping Report v2.0.1

Parent: **v2.0.0**  
UI authority: **live Figma Design System v2.0.2**  
Business/behavior authority: existing Product/BJ/UC/decision/contract baseline carried forward from v2.0.0.

## Scope

Phase 2 establishes the translation layer from the cumulative legacy HTML annotations to the completed Figma Design System. It does **not** visually recompose Product screens.

Completed in v2.0.1:

- Added one canonical HTML ↔ Figma registry covering component, contextual/profile, Theme 7 composition and internal-slot mappings.
- Bound exact mappings to live Figma node IDs where a canonical asset exists.
- Added runtime mapping data for Inspect without changing Product business behavior.
- Migrated Inspect output to Figma-native target name, node ID, DS layer, mapping status, contextual pattern and canonical props/variants.
- Marked all 17 UIF component-usage documents as **legacy mapping input only**; Figma DS v2.0.2 is the current UI authority.
- Updated stale UI-authority metadata in current flow/screen/prototype documentation to Figma DS v2.0.2 without changing business semantics.
- Added screen-registry migration metadata while keeping the 17 UIF / 73 canonical screen / 497 state topology unchanged.
- Resolved the former timeline gap to live `DS v2 / Timeline Item` (`525:587`).
- Preserved unresolved DS decisions explicitly instead of inventing local conventions.

## Key mapping outcomes

- Exact canonical examples: `VButton → 521:529`, `VTextField → 522:7186`, `VAppBar → 547:1594`, `VEmptyState → 526:4352`.
- Pattern ownership examples: destructive confirmation → `DS v2 / Confirmation Sheet` (`550:1058`); list search/filter → `DS v2 / Search & Filter Header` (`547:2306`).
- Theme 7 migration targets include `List Row`, `Summary Card`, `Info Row`, `Timeline Item`, `Search Results Dropdown`, `Mobile / Form`, and `Mobile / State`.
- Generic `VCard` is explicitly migration debt; each usage must be resolved by information anatomy in Phase 3/4.
- `VQuantitySelector` remains `OPEN_DS_GAP`; no new canonical master is fabricated.

## Release boundary

Protected and unchanged from parent v2.0.0:

- Business SRS
- `flows/ui-flow-registry.json`
- `contracts/action-registry.json`
- Screen/flow **business content**; only stale UI-authority metadata is allowed to change
- Phase 1 `html/tokens.generated.css`
- `theme.manifest.yaml`
- Product screen visual/composition output

Allowed Phase 2 changes are limited to mapping metadata, component-usage migration notices, workbench/Inspect implementation and QA evidence.

## Next phase

**Phase 3 — Representative calibration** is the first phase allowed to change Product composition. Calibrate the Figma DS renderer on representative archetypes before any full 73-screen migration:

- BJ02 — search, form, LOT, approval
- BJ05 — dense operational list
- BJ08/BJ10 — approval and destructive workflows
- BJ15 — read-only/report/filter
- BJ17 — recovery/state

Only after the representative set passes business, interaction, renderer and visual QA should Phase 4 migrate all 73 screens by structural pattern.
