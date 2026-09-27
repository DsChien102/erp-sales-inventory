# RELEASE VALIDATION — v2.9.2

Parent: `v2.9.1`  
Status: **PASS · REVIEW READY**

## Scope

Cross-BJ Product information-hierarchy correction. BJ07 is the primary correction; the same anti-pattern was audited across all migrated Product UIFs and corrected where found in BJ05 and BJ06. Business behavior is unchanged.

## What changed

- **BJ07 / SCR-037, SCR-039, SCR-041:** Product+UOM identity/status is no longer free-floating `VText + VBadge`. It is now a real `DS v2 / List Row`, `Type=Status`, `Density=Compact`, inside one coherent white bordered Product group surface.
- **BJ07 preparation:** each Product+UOM parent contains its exact LOT/non-LOT allocation children as `List Row / Navigation / Default`. Parent and child now have distinct visual weight and semantics.
- **BJ07 handover/result:** each Product+UOM parent contains allocation facts as canonical `Key-value Row`; quantities remain scoped to exact Product+UOM and are never aggregated across UOM.
- **BJ05 / SCR-028:** ad-hoc Product header was replaced with the same canonical Status/Compact Product summary row; the allocation header was normalized to `Key-value Row`.
- **BJ06 / SCR-035:** free-text result Product header was replaced with the same canonical Status/Compact Product summary row; classification facts remain lower-level Info Rows.
- **BJ01, BJ02, BJ04 and BJ08:** audited for this exact anti-pattern; existing migrated compositions did not require the same correction.

## Figma grounding

The correction was reviewed against the live VET45 Figma Design System and mature Theme 1 Product UI compositions. The decisive pattern is consistent: when multiple rows/facts belong to one business entity, the entity identity is expressed by a canonical DS primitive and the facts are grouped in a coherent bordered surface; badges are not floated independently beside arbitrary text.

Canonical references used include `List Row 525:519`, `Info Row 525:351`, `Key-value Row 525:358`, `VBadge 525:309`, `VBanner 526:4215`, `VBottomSheet 4695:6353`, and Theme 1 detail composition `267:3444`.

## Gates

- BJ07 Figma DS + UX QA: **PASS 32/32**
- Product hierarchy cross-migrated QA: **PASS 18/18**, 33 migrated default renders, 0 browser errors
- Migrated visual integrity QA: **PASS 7/7**, 33 screens checked
- BJ05 + BJ06 regression: **PASS 32/32**
- Prior migrated BJ regression: **PASS 23/23**, 0 browser errors
- All-flow runtime: **PASS 85/85**, 0 failures, 0 browser errors
- Device frame: **PASS 7/7**, 85 screens checked, 0 browser errors
- Review workbench fit: **PASS 3/3**
- Mobile prototype validator: **PASS**, 0 findings
- JavaScript syntax: **PASS** (`app.js`, `workbench-data.js`)
- Product viewport remains **402×874**; no horizontal Product overflow in the migrated-screen audit.

## Locked UX learning

A composition is not permission to assemble arbitrary visual fragments. If the DS already has a semantic primitive for entity identity/status, use it. Product+UOM is a business parent; LOT/non-LOT allocation is a child. They must be visually distinct, grouped on a coherent surface, and never expressed as floating title/subtitle/badge fragments on the page canvas. Before implementing a Theme 7 composition, compare canonical DS, Patterns/Templates, and mature prior-Theme Product screens in Figma.
