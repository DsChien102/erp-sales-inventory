# Changelog — VET45 Theme 7 Prototype Harness v3.9.4

**Parent:** v3.9.3  
**Scope:** Wave 2 — BJ06 Khách trả hàng — Deep-Dive Semantic Traceability hardening.

## Authority / review rule

- v3.9.3 was used as the **single Theme 7 review baseline**.
- Frozen-source remains historical and byte-identical.
- BJ01, BJ02 and BJ05 retain their locked semantic contracts.
- v3.9.4 becomes the next cumulative review baseline after release.

## Approved BJ06 decisions implemented

1. Theme 5 `ReturnExchangeLine.authorized_return_quantity` is the current request upper bound; Theme 7 may physically receive a smaller quantity.
2. Theme 5 `ReturnCondition` is declared commercial context only; Theme 7 physical classification is authoritative for inventory disposition.
3. Existing actual LOT resolves authoritative lot identity/version; a new LOT progressively requires policy-owned attributes and cannot bypass data-integrity conflicts via approval.
4. Wrong-LOT reason taxonomy is reduced to `RETURNED_DIFFERENT_LOT` and `OTHER`; source-integrity failures are blockers/reconciliation, not approvable reasons.
5. `ApprovalCase` supports `OPERATION | LINE_EXCEPTION`; BJ06 uses one immutable subject per wrong-LOT line and allows multiple concurrent line exceptions in one receipt operation.
6. `EXPIRED` is `SYSTEM_DERIVED` from LOT expiry + tenant business date; user only allocates Sellable/Quarantine/Damaged on non-expired lines.
7. Result identity remains source return request + SalesOrder + authoritative timestamps; no synthetic return-receipt number is invented. UNKNOWN hands the same operation identity to BJ17 and blocks blind retry.

## UX / runtime cleanup

- Waiting return requests are true read-only/status-only rows.
- Quantity is displayed as data, not a status badge.
- Source LOT and actual LOT are labeled facts rather than compressed metadata.
- Approver view shows maker, source return/order context, Product/UOM, actual quantity, LOT comparison, reason and evidence; raw case/hash/version IDs remain contract-only.
- Evidence approval binding uses evidence id/version/content hash; SHA-256 is used when secure crypto is available, with deterministic offline content-hash fallback in the prototype.
- New LOT required expiry blocks save until completed.
- Routine return classification has no invented reason/evidence/default approval in Phase 1.

## Contract / documentation propagation

Updated in the cumulative package:

- Decision Register: `T7-DR-131…137`.
- BJ06 journey and UC-06-01…04.
- Shared behavioral contracts `BC-IO-07`, `BC-IO-08`, `BC-IC-06`.
- `ApprovalCase` data model.
- UIF-06 and SCR-030…035 screen contracts.
- Component usage contract, screen registry, workbench presentation data.
- Runtime prototype and QA gates.

## QA

- BJ06 Deep Review: **40/40 PASS**, 6 focused UI captures, 0 browser/console errors.
- Prior locked BJ regression (BJ01/BJ02/BJ05): **8/8 PASS**.
- Frozen-source immutability: **PASS**.
- Current package validation: **26/26 PASS**.
- Full Theme End-user regression: **19/19 PASS**.
- Flow & Logic E2E: **21/21 PASS**.
- All-flow runtime smoke: **89/89 PASS**, 0 errors.
- Runtime UI: **14/14 PASS**, 518 declared states.
- Representative coherence: **8/8 PASS**.
- Device frame: **7/7 PASS**, 89 screens checked.
