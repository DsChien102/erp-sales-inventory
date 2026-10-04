# CHANGELOG v1.4.4 — BJ03 Inventory Valuation Foundation Correction

Parent: `v1.4.3`.

## Corrected

- Data entity: `TransactionalBalance` now materializes valuation state as a separate axis from physical stock state.
- ReceiptValuation supports multiple partial direct confirmations on one technical goods receipt line through identified scope/version/quantity semantics.
- Added `BC-IV-05 / API-Q-11` non-mutating valuation preview; UC03-01/02 no longer trace to commit API.
- BC-IV-01 now confirms exact identified scope, preserves physical state and uses authoritative availability evaluation.
- Queue distinguishes actionable vs waiting evidence; waiting rows are read-only.
- Scope shows LOT/non-LOT + physical state identity; partial quantity is progressive disclosure.
- Happy path bypasses SCR016; SCR016 is conflict/provenance surface.
- Final review includes actual unit cost, exact slices, authoritative availability delta, source and initial official-cost side effect.
- Result avoids dead-end continuation when only waiting-evidence scope remains; UNKNOWN is non-actionable recovery.

## Protected

Inventory Operations UIF01/02/04/05/06/07 and non-target UIF08–UIF17 behavior must remain runtime-equivalent unless a shared screen mode explicitly belongs to UIF03.
