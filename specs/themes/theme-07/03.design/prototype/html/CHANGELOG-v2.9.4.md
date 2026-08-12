# VET45 Theme 7 Prototype - v2.9.4

Parent: v2.9.3

## Scope

BJ07 visual hierarchy correction for Product/UOM and LOT/non-LOT allocations on SCR-037, SCR-039 and SCR-041.

## Changes

- Replaced the card-like Product Status/Compact List Row in the Product/LOT hierarchy with a lightweight Product group-header composition built from existing VIcon, VText and VBadge primitives.
- Replaced card-like actionable LOT rows with flat nested navigation rows inside one grouped collection surface.
- Added a neutral hierarchy connector and removed duplicated package icons from LOT/non-LOT children.
- Reused the same Product group-header composition in handover review and completed result screens.
- Kept canonical DS v2 Key-value Row for read-only allocation evidence.
- Preserved verification sheet behavior, exact-source rules, source-change invalidation, final commit and recovery semantics.
- No new core Design System component was created.

## QA

- Product/LOT hierarchy gate: 21/21 PASS.
- All-flow runtime: 85/85 renders, 0 browser errors.
- Device frame: 7/7 PASS across 85 screens.
- Prior-BJ regression: 23/23 PASS.
- BJ05/BJ06 regression: 32/32 PASS.
- Review workbench fit: 3/3 PASS.
- Manual focused visual review: SCR-037, SCR-039, SCR-041 and verification sheet at 402x874.
