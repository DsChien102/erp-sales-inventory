# Changelog — VET45 Theme 7 Prototype Harness v3.3.0

Parent: **v3.2.1**  
Scope: cumulative Theme 7 prototype; visual-hierarchy correction for the UI compositions reviewed in BJ08 and BJ07, with the same density rule applied to Audit & Control chip regions.

## Changed

- BJ08 count/recount no longer wraps all products in one rounded collection surface.
- Each count/recount product task now uses canonical `DS v2 / List Row` as the identity row, with subordinate facts and quantity entry placed below it; product tasks are separated by semantic whitespace.
- BJ08 product identity rows return to the canonical white surface instead of using gray pseudo-header bands.
- Recount facts stay flat and subordinate; no nested fact card or divider stack is introduced.
- BJ07 Product → LOT preparation no longer wraps the entire product collection in one rounded surface. Product groups are separated by whitespace.
- BJ07 keeps the Product as the canonical compact List Row; LOT/non-LOT rows are visually subordinate via indentation, a light vertical boundary and row dividers, not peer cards.
- Audit & Control dense `VChip` regions are kept as a single canonical row with horizontal scrolling instead of creating multi-row chip blocks.

## Locked UI rule

Hierarchy must be created with component responsibility, typography, alignment and semantic spacing before adding surfaces. A page section is not automatically a card. Repeated nested/peer cards are blocked when canonical rows + spacing + dividers express the same hierarchy.

## Business behavior

No BJ/UC rule, state machine, action topology, approval boundary, inventory commit behavior or screen routing is changed from v3.2.1.
