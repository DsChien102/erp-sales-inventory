# Changelog — v2.8.2

Parent: v2.8.1.

## BJ05

- Replaced stacked per-LOT field blocks on SCR-027 with canonical `DS v2 / List Row (Navigation, Default)` overview rows.
- Each LOT now shows only the high-value scan facts: LOT identity, quantity required, quantity picked.
- Tapping a LOT opens one canonical `VBottomSheet` for quantity editing; LOT override remains contextual from that editor.
- Large allocation sets scale as a standard list instead of multiplying form controls in the page.

## BJ06

- Fixed the maker Back-navigation defect caused by using the review catalog order as navigation history. `SCR-033` now backs to `SCR-030`, never to approver-only `SCR-034`; `SCR-032→031` and `SCR-031→030` are explicit.
- Reordered the review catalog so maker route screens are contiguous and approver work remains visibly independent.
- Compressed repeated request metadata on SCR-031 and SCR-033 into one canonical Compact Status List Row with progress.
- Kept required business milestones and CTAs: all-or-nothing goods receipt, optional defer after goods receipt, independent wrong-LOT approval, and final classification.

No business rule or inventory finality rule changed.
