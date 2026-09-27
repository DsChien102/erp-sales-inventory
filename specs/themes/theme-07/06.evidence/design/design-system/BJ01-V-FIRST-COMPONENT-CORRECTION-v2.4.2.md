# BJ01 — V-first Component Selection Correction v2.4.2

**Parent:** v2.4.1  
**Business behavior:** unchanged  
**UI authority:** live Figma DS v2.0.3

## Finding

v2.4.1 had strong visual fidelity, but the reuse rule was only partially enforced. The concrete miss was the LOT/provenance context overlay: HTML rendered a custom Theme7 sheet shell although live Figma provides canonical `VBottomSheet` (`4695:6353`). Several List Rows and layout-only groupings were also redundantly labeled as Theme7 component identities even though direct V/non-V components already represented the rendered responsibility.

## Correction

- Replace BJ01 custom sheet shell with direct `VBottomSheet` identity and exact live geometry.
- Preserve Theme7 business content only inside the VBottomSheet content slot.
- Remove redundant Theme7 component identities from quick filters, Product list/identity, Product/LOT/provenance rows. Layout-only wrappers are not components; use `VChip`, `VText`, and `DS v2 / List Row` directly.
- Keep `DS v2 / Info Row` only because no live `VInfoRow` exists.
- Keep `Theme7AvailabilitySummary` as Product composition with explicit rejection rationale for Metric Card/Summary Card.
- Promote the V-first selection order into the Theme 7 component-usage profile and Figma DS lock.

## Acceptance

BJ01 is compliant only if each custom/Product composition can point to a failed higher-priority candidate check. A custom component cannot exist merely because implementation is easier.
