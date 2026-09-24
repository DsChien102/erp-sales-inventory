# RELEASE VALIDATION — v2.9.3

Parent: `v2.9.2`  
Status: **PASS · REVIEW READY**

## Scope

Cross-BJ DS-native density/hierarchy correction. The release removes repeated per-Product outer card boundaries from the affected migrated BJ05/BJ06/BJ07 screens while retaining the exact live Figma component anatomy inside each composition. Business behavior is unchanged.

## What changed

- **BJ07 / SCR-037:** one grouped preparation surface replaces one outer card per Product. Product+UOM stays exact `List Row / Status / Compact` **370×52**; each actionable LOT stays exact `List Row / Navigation / Default` **370×76**.
- **BJ07 / SCR-039 + SCR-041:** one grouped read-only evidence surface replaces repeated Product cards. Product row state is semantic (`Đã kiểm` / `Đã bàn giao`); LOT quantity is canonical `Key-value Row` **338×44** data.
- **BJ07 verification sheet:** badge expresses verification status; required quantity is an `Info Row` fact.
- **BJ05 / SCR-028:** one grouped handover surface; Product state is semantic `Đã lấy`; allocation facts and actual quantity controls retain their canonical DS geometry.
- **BJ06 / SCR-035:** one grouped result surface; child facts remain `Info Row`. A legacy selector that made a nested section title look like H2 was corrected to the canonical H4 hierarchy.
- **BJ01, BJ02, BJ04 and BJ08:** re-audited for the same anti-pattern. Existing surfaces were retained where they represent an independent business unit or already follow DS flat/grouped semantics.

## Figma grounding

The correction follows live `Layout / Surface Grouping 4518:1545`: use the lightest surface treatment that preserves hierarchy and avoid Card soup. `VSection` remains structural grouping, not an automatic Card. Visible UI primitives stay mapped to live components: `List Row 525:519`, `Info Row 525:351`, `Key-value Row 525:358`, `VBadge 525:309`, `VBanner 526:4215`, and `VBottomSheet 4695:6353`. Mature Theme 1 Product composition `267:3444` was used as cross-theme consistency evidence after the canonical DS/Pattern check.

## Gates

- Grouped Collection / Figma DS QA: **PASS 27/27**
- BJ05 + BJ06 regression: **PASS 32/32**
- Prior migrated BJ regression: **PASS 23/23**, 0 browser errors
- Migrated visual integrity: **PASS 7/7**, **33 canonical screens** checked
- Manual visual DS hierarchy review: **PASS**, focused correction captures + full 33-screen migrated contact sheet reviewed
- All-flow runtime: **PASS 85/85**, 0 failures, 0 browser errors
- Device frame: **PASS 7/7**, 85 screens checked, 0 browser errors
- Review workbench fit: **PASS 3/3**
- Official mobile prototype validator: **PASS**, 0 findings
- JavaScript syntax: **PASS** (`app.js`, `workbench-data.js`)
- Registry integrity: **PASS**; action/screen registry hashes remain unchanged
- Product viewport remains **402×874**, with no migrated-screen root horizontal overflow.

## Locked UX/DS learning

**Component-first does not mean Card-first.** Flattening must happen only at the Layout/Pattern composition layer; a canonical Figma component must not be visually deformed just to reduce card count. Use `VBadge` for semantic status, not raw quantity. Use Navigation rows only for navigation/actionable records; use Info/Key-value rows for read-only evidence. Before implementing a Theme 7 composition, check canonical Components, then Patterns/Templates, then mature prior-Theme Product UI in Figma.
