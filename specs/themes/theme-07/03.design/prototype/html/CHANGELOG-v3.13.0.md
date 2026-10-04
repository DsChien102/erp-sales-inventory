# CHANGELOG — v3.13.0

Parent: `v3.12.0`.

## Scope

Design + HTML parity for `BJ03 → BJ13 → BJ14`; no new business semantic.

## Topology

- BJ03: `SCR-014 → SCR-015 → SCR-017 → SCR-019`; retire `SCR-016` and legacy `SCR-018`.
- BJ13: `SCR-085 → SCR-086 → SCR-088 → SCR-089`; retire `SCR-087`.
- BJ14: `SCR-072 → SCR-074 → SCR-077`; retire `SCR-073/075/076`.

## Product UX

- nhập hàng nhanh can add a direct price basis without Theme 10 dependency.
- Document commercial conflict remains source-owned and cannot be bypassed by arbitrary price selection.
- Initial value result no longer bootstraps Official Cost.
- Later value changes are signed adjustments.
- Costing method is inherited from tenant policy and is read-only in BJ14.
- Technical identity remains in Inspect/audit, not product copy.

## Figma DS alignment

- Live source: file `QVJolM5tAdFKkhP7RIwe3y`, Components page `505:5890`.
- Canonical components used include VAppBar, List Row, Info Row, Key-value Row, Summary Card, VBanner, VEmptyState, Readiness Item, VButton, VTextField and VBottomSheet.
- Canonical mobile values: 402×874, edge 16, touch 44, disabled opacity 0.4.

## QA

- All-flow runtime smoke: 86 active renders, 0 failures/browser errors.
- Valuation interaction E2E: 24/24 PASS.
- 402×874 visual captures generated for active valuation topology.
