# Changelog — VET45 Theme 7 Prototype Harness v3.9.9

**Parent:** v3.9.8  
**Scope:** Wave 3 — BJ14 Tính & công bố giá vốn — Deep-Dive Semantic Traceability hardening.

## Authority / review rule

- v3.9.8 is the single review baseline for this cumulative update.
- Frozen-source remains historical and byte-identical to the parent ZIP.
- BJ01, all Wave 2 locks, BJ03 and BJ13 remain protected by regression.
- v3.9.9 closes the Wave 3 forensic review cycle after BJ03 → BJ13 → BJ14 cross-BJ consolidation.

## Approved BJ14 decisions implemented

1. Costing consumes one authoritative valuation timeline ordered by `valuation_sequence + within_transaction_ordinal`; quantity/value cursors remain audit cursors only.
2. Every Product in a run materializes an immutable `ProductCostResult`; run totals are aggregates rather than the source of truth.
3. Successor/ad-hoc publication posts only incremental reconciliation delta against authoritative COGS/carrying-value baselines. Re-running the same facts/baseline yields delta 0.
4. Operational `OfficialCostVersion` is forward-effective: Phase 1 never backdates effective time before publication commit.
5. `run_type`, `calculation_period_id`, `posting_period_id` and original-period lineage are distinct. One run publishes into exactly one posting period.
6. Dirty/ad-hoc scope is source-owned and versioned at exact Product + posting-period granularity. It clears only after successful publication reconciles the exact dirty causes.
7. Weighted-average edge cases are explicit: `NEGATIVE_QUANTITY` and `NEGATIVE_VALUATION_RESULT` block; denominator 0 yields `NO_NEW_COST_BASIS`; zero ending quantity may still true-up COGS; zero cost requires authoritative provenance.

## Contract / UX hardening

- UC-14-03 is query-only review through `API-Q-10`; all stale command-envelope, idempotency and mutation-UNKNOWN template residue was removed.
- UC-14-04 exclusively owns publish finality through `BC-IV-03` / `API-C-22`.
- `SCR-075` remains retired. Active Product flow stays `SCR-072 → SCR-073 → SCR-074 → SCR-076 → SCR-077`.
- `SCR-073` treats source-owned dirty scope as read-only; Product UI cannot arbitrarily omit an authoritative dirty Product.
- `SCR-074/076` summarize immutable per-Product results and incremental consequences rather than client-side costing authority.
- `SCR-077` renders command-authoritative publication result. UNKNOWN keeps the same publication identity and hands off to BJ17 without blind retry.
- Product UI no longer shows implementation-centric wording such as `authoritative` or backdated effective-time claims.
- Runtime freshness uses run-input hash / scope / valuation cutoff / Product-result hashes; stale review cannot publish.

## Cross-BJ closure

Wave 3 is now coherent end-to-end:

`BJ03 Direct Valuation` → immutable direct value facts → `BJ13 Late Cost` + exact Product/posting-period DIRTY → `BJ14 ordered costing run` → `ProductCostResult` → incremental reconciliation → atomic publication → forward-effective Official Cost → exact dirty-cause clear.

## QA

- BJ14 Deep Review: **72/72 PASS**.
- BJ14 Fresh-eye: **16/16 PASS**.
- Prior locked regression — BJ01 + Wave 2 + BJ03 + BJ13: **26/26 PASS**.
- Wave 3 Cross-BJ Audit: **35/35 PASS**.
- Frozen-source immutability: **108/108 byte-identical to parent ZIP**.
- Current package validation: **41/41 PASS**.
- Full Theme End-user regression: **19/19 PASS**.
- Flow & Logic E2E: **21/21 PASS**.
- All-flow runtime smoke: **89/89 PASS**, 0 errors.
- Runtime UI: **14/14 PASS**, 514 declared states, 89 canonical routes.
- Representative coherence: **8/8 PASS**.
- Device frame: **7/7 PASS**, 89 screens.
- Focused BJ14 visual captures: **5**, 0 page/console errors.
