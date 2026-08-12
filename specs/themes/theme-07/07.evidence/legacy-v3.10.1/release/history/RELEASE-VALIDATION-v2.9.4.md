# RELEASE VALIDATION - v2.9.4

Parent: `v2.9.3`  
Status: **PASS - REVIEW READY**

## Scope

BJ07 Product/UOM to LOT/non-LOT visual hierarchy correction. Business behavior is unchanged.

## What changed

- SCR-037 now has one grouped collection surface. Product/UOM is a lightweight group header, while LOT/non-LOT allocations are flat nested navigation rows.
- LOT children no longer repeat the Product package icon and no longer use rounded card boundaries.
- A neutral hierarchy connector makes the parent-child relationship explicit.
- SCR-039 and SCR-041 reuse the same Product group-header hierarchy; allocation evidence remains canonical 338x44 Key-value Row.
- The verification bottom sheet, source-change handling, handover commit and recovery behavior are unchanged.
- No new core Design System component was created.

## Figma grounding

The implementation follows the live VET45 Figma Design System rule to prefer generic display primitives and reusable compositions. Theme 1 frame `267:3444` was used as a mature Product UI reference for making primary entity/context visually stronger than supporting facts without turning each fact into a card.

## Gates

- Product/LOT hierarchy: **PASS 21/21**
- All-flow runtime: **PASS 85/85**, 0 browser errors
- Device frame: **PASS 7/7**, 85 screens checked, 0 browser errors
- Prior-BJ regression: **PASS 23/23**, 0 browser errors
- BJ05/BJ06 regression: **PASS 32/32**
- Review workbench fit: **PASS 3/3**
- JavaScript syntax: **PASS**
- Focused visual review: **PASS** at 402x874 for SCR-037, verification sheet, SCR-039 and SCR-041

## UX lock

Product is the parent context; LOT/non-LOT is a child allocation. They must not be rendered as peer cards. Use one grouped surface, a visually stronger Product header and flat nested child rows. Preserve canonical DS components where they fit the semantic responsibility; use composition when no single component should carry the whole hierarchy.
