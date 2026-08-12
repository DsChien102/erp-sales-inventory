# Changelog — VET45 Theme 7 Prototype Harness v3.9.8

**Parent:** v3.9.7  
**Scope:** Wave 3 — BJ13 Chi phí mua bổ sung — Deep-Dive Semantic Traceability hardening.

## Authority / review rule

- v3.9.7 was used as the **single Theme 7 review baseline**.
- Frozen-source remains historical and byte-identical.
- BJ01, Wave 2 (BJ02, BJ05, BJ06, BJ07, BJ04) and BJ03 retain their locked semantic contracts.
- v3.9.8 becomes the cumulative baseline for the next Wave 3 review, BJ14.

## Approved BJ13 decisions implemented

1. Late cost uses a stable **`source_component_key`** for economic identity. Source revision is freshness/provenance only and can never manufacture a second economic cost. A committed component that later changes routes to correction/reconciliation rather than bypassing dedup.
2. Target membership is source/policy-authoritative through `target_scope_key + version + hash`. Fixed scope cannot be arbitrarily unchecked; user subset judgment is allowed only when the authoritative scope contract explicitly permits it and the selection is audited.
3. Allocation targets an immutable **`ValuationExposure`**, not just a receipt operation line. Exposure binds receipt item/technical lineage, transaction/base-UOM normalization, cumulative initial-valued quantity/value, ReceiptValuation lineage, receipt business date and period mapping.
4. Allocation metrics are immutable and independent of late-cost entry order. Value-based allocation uses initial/direct receipt value before prior late-cost adjustments; quantity-based allocation uses normalized base quantity. Rounding residual follows stable `valuation_exposure_key` order, never visual row order.
5. Final commit rechecks complete **`late_cost_basis_hash + allocation_hash`**, covering source revision/evidence, amount/currency, tax, FX, policy/method, target scope, valuation exposures/metrics and period mapping. Any selected fact change rejects the entire command before mutation.
6. One source component has exactly one accounting route: **DIRECT** or **LATE**. If no target has Direct Valuation when first recognized, the component belongs to BJ03. If any target is already initial-valued, the entire component belongs to BJ13 and waits until all authoritative targets are initial-valued before allocation. A component is never split between BJ03 and BJ13.
7. Business/original/posting period is retained per allocation. One late-cost component may create **1..N posting-period adjustment batches atomically**, and the exact successor dirty scope is **Product + posting period**, not Product+UOM.

## UX / runtime cleanup

- Active BJ13 Product flow is `SCR-085 → SCR-086 → SCR-087 → SCR-088 → SCR-089`; historical `SCR-014/015/017/018/019` are no longer active BJ13 surfaces.
- Source revision, raw fixture filename, undefined aging and normal-state actionable badges are removed from the Product UI.
- `SCR-086` represents authoritative target scope / valuation exposures; fixed scope is read-only.
- `SCR-087` renders server-owned immutable metric allocation preview and deterministic rounding.
- `SCR-088` prioritizes amount, allocation, posting-period grouping and exact recalculation scopes rather than architecture narration.
- `SCR-089` uses command-authoritative results and may summarize 1..N posting-period batches. It does not imply Official Cost has already been republished.
- Waiting reasons are concrete and read-only, including `Chờ tỷ giá`, `Chờ xác nhận giá ban đầu` and source-scope waiting.
- Financially restricted values stay server-masked/omitted from the DOM.
- Mutation `UNKNOWN` preserves the same command identity and hands off to BJ17; no blind retry is introduced.

## Contract / documentation propagation

Updated in the cumulative package:

- Decision Register: `T7-DR-157…163` plus clarified `T7-DR-058`.
- BJ13 journey and UC-13-01…03.
- Shared behavioral contracts `BC-IV-06` and `BC-IV-04`.
- Technical contracts `API-Q-12`, `API-C-23` and late-cost event/concurrency semantics.
- `LateLandedCost`, derived `ValuationExposure` and `LateLandedCostAllocation` data contracts.
- UIF-13 and `SCR-085…089` current screen contracts.
- Design-readiness screen inventory, screen registry/workbench, action registry and harness contract registry.
- Current runtime prototype overlay `v398-bj13-semantic-hardening.*`.

## QA

- BJ13 Deep Review: **83/83 PASS**, 5 focused visual captures, 0 browser/console errors.
- BJ13 fresh-eye re-walk: **16/16 PASS**.
- Prior locked regression — BJ01 + Wave 2 + BJ03: **20/20 PASS**.
- Wave 2 Cross-BJ Audit baseline remains **30/30 PASS**.
- Frozen-source immutability: **PASS · 108/108 files byte-identical**.
- Current package validation: **34/34 PASS**.
- Full Theme End-user regression: **19/19 PASS**.
- Flow & Logic E2E: **21/21 PASS**.
- All-flow runtime smoke: **89/89 PASS**, 0 errors.
- Runtime UI: **14/14 PASS**, 514 declared states.
- Representative coherence: **8/8 PASS**.
- Device frame: **7/7 PASS**, 89 screens checked.
