# CHANGELOG v1.4.5 — BJ13 Late Landed Cost Deep Product Correction

Parent: `v1.4.4`.

## Corrected

- Replaced generic/shared BJ13 Product flow with dedicated `SCR-085 → SCR-086 → SCR-087 → SCR-088 → SCR-089`.
- Queue object is now the **late-cost source component**, not a `VALUATION_PENDING` goods receipt; actionable and source-owned waiting tasks are separated.
- Added `ENT-IV-07 LateLandedCost` and `ENT-IV-08 LateLandedCostAllocation` so source amount/currency, 1..N receipt-line allocations and adjustment linkage are traceable without overloading `ReceiptValuation`.
- Added non-mutating `BC-IV-06 / API-Q-12` for source/tax/FX normalization, allowed allocation methods, allocation preview, posting period, rounding and dirty-scope preview.
- Corrected UC13-01/02 to preview/query semantics; only UC13-03 owns `BC-IV-04 / API-C-23` commit.
- Corrected `BC-IV-04` owner/trace to BJ13 and changed command path to `POST /v1/late-landed-costs`.
- Support 1..N exact affected goods receipt operation lines when source scope contains multiple goods receipt lines; commit is all-or-nothing.
- Allocation-method set remains policy/source authoritative; when multiple valid methods exist, Product UI does not preselect one.
- Final review states quantity unchanged, history preserved and official cost not auto-published; result hands dirty Product/Period scope to BJ14.
- Source version/preview hash stale blocks commit; UNKNOWN keeps same operation identity and forbids blind retry.
- Retired `SCR-018` from active UIF13 and removed BJ13 ownership/action semantics from shared BJ03 screens.

## Protected

- BJ03/UIF03 v1.4.4 foundation behavior remains exact-parent runtime equivalent.
- Inventory Operations and every non-UIF13 flow remain exact-parent runtime equivalent.
- Frozen-source, know-how, outbound contracts, migration history and design-readiness history are not rewritten by this release.

## Product note

Allocation-method labels in HTML are fixture examples returned by the preview model; they are **not** a new Theme 7 business enum. The authoritative production set comes from `BC-IV-06/API-Q-12` with policy version.
