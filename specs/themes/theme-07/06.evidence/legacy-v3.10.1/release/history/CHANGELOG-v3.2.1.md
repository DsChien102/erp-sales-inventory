# Changelog — VET45 Theme 7 Prototype Harness v3.2.1

Parent: **v3.2.0**  
Scope: cumulative Theme 7 prototype; UI-composition correction for Inventory Audit & Control plus the same Product→LOT presentation defect in BJ07.

## Corrected

- BJ08 counting/recount no longer uses the custom `ds24-count-card` / per-product card-on-card treatment.
- Product context now delegates to canonical `DS v2 / List Row`; read-only recount evidence delegates to `DS v2 / Key-value Row`; editable quantity remains the canonical field/keypad composition.
- One Product + its subordinate count/recount content is visually treated as one grouped surface, with flat facts and no nested bordered surface.
- BJ07 preparation hierarchy no longer presents LOT/non-LOT child rows as rounded peer cards. Child rows are flat subordinate List Rows with dividers under the Product parent.
- Audit & Control filter collections no longer leave the last `VChip` partially clipped. Dense chip sets wrap complete canonical chips within the content width.
- Previously corrected redundant list headings and browse-list destructive actions remain blocked.

## Locked design rule

Theme 7 must not invent feature-specific cards/patterns when existing Figma DS primitives can express Product identity, facts, fields, status and child records. Product→context must use semantic hierarchy within one grouped surface; repeated nested cards are a release-blocking anti-pattern.

## Business behavior

No business rule, state machine, action topology, commit semantics, approval boundary or inventory effect was changed from v3.2.0.

## QA

- Composition/release QA: **16/16 PASS**.
- Audit & Control: **269/269 declared-state renders PASS**.
- Cumulative Theme 7: **497/497 declared-state renders PASS**.
- Browser errors: **0**.
- Audit & Control screen/state/action topology: unchanged from v3.2.0.
- `VChip`: all six BJ09 state filters fully visible; no partial horizontal clipping.
- BJ08: one grouped collection; no per-product count cards; canonical Product List Rows + Key-value facts + quantity fields.
- BJ07: one Product/LOT collection surface; LOT child rows have no peer-card radius/border treatment.
