# Changelog — VET45 Theme 7 Prototype Harness v3.4.0

Parent: **v3.3.0**

## Visual architecture corrections

- Reworked the remaining Product/context compositions to the Figma DS rule **one semantic group = one boundary**.
- BJ08 count/recount now uses one grouped surface per product task. Product identity is the canonical `DS v2 / List Row`; facts are canonical `Key-value Row`; quantity remains the existing numeric field/keypad composition.
- Removed repetitive `Cần đếm` badges from count rows. On recount/review, `Chênh lệch` is presented as evidence in the aligned fact region rather than as a competing status badge.
- BJ08 approval review now uses the same product-task grouping as count/recount instead of alternating Product card / fact card / Product card / fact card.
- BJ07 preparation/review now uses **one grouped surface per Product + UOM**, with flat LOT/non-LOT child rows inside that boundary. Product groups are separated by semantic whitespace. The old collection-level card / connector treatment is removed.
- Audit & Control detail screens with an immediate Product row + fact surface are visually joined into one grouped surface rather than rendering two touching cards.
- Dense `VChip` collections now wrap complete canonical chips within the 370 px Product content width. Partial/clipped chips and half-visible horizontal-scroll endings are blocked.
- No new core component, Theme-specific card family, or feature-specific DS pattern was introduced.

## Business behavior

No BJ/UC rule, state machine, approval boundary, inventory commit behavior, screen route, action id, or handler contract was intentionally changed.
