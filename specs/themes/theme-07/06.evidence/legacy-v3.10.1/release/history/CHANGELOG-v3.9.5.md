# Changelog — VET45 Theme 7 Prototype Harness v3.9.5

**Parent:** v3.9.4  
**Scope:** Wave 2 — BJ07 Trả hàng cho nhà cung cấp — Deep-Dive Semantic Traceability hardening.

## Authority / review rule

- v3.9.4 was used as the **single Theme 7 review baseline**.
- Frozen-source remains historical and byte-identical.
- BJ01, BJ02, BJ05 and BJ06 retain their locked semantic contracts.
- v3.9.5 becomes the next cumulative review baseline after release.

## Approved BJ07 decisions implemented

1. Supplier-return intake and `RTV_PENDING` are system/source-owned effects. Purchase/source provides an already-authorized supplier-return intent; warehouse users do not perform a fake “move to pending return” mutation.
2. Supplier-return source identity is stable across source versions: `source_request_id + source_version → source_line_id → source_allocation_id`.
3. Every supplier-return allocation resolves to exact inventory source slices that preserve original stock state, LOT, quantity and balance version. Deterministic composition is automatic; only genuinely ambiguous composition asks warehouse users to identify source stock.
4. `HandoverEvidence` is generalized as immutable source-agnostic evidence shared by BJ05/BJ07, with source-specific context as extensions rather than mandatory fulfillment-only columns.
5. Physical mismatch is an immutable structured observation (`QUANTITY | LOT | ITEM_NOT_FOUND | OTHER`) with no stock effect. Warehouse records what it physically sees; the source owner publishes the corrected version.
6. Commercial supplier price is not a physical handover blocker. Theme 7 owns quantity issue, official inventory cost and physical/value reduction; Purchase/Accounting owns supplier accepted price, debit note, payable and commercial difference.

## UX / runtime cleanup

- Source changes show concrete business deltas rather than generic “source changed” copy.
- Waiting-for-source-update detail is true read-only.
- Product/UOM remains the parent identity; LOT/source slices are subordinate facts rather than peer cards.
- “Xác định nguồn tồn” appears only when multiple stock-state compositions are actually valid.
- Final review shows supplier, return request, source document and warehouse without raw source-version noise.
- Handover result includes server-authoritative handover time.
- Search copy now matches actual searchable scope: request, supplier and source document.
- `SCR-038` is explicitly outside active UIF-07 and remains owned by UIF-09.
- UNKNOWN preserves the same operation identity and hands prolonged recovery to BJ17 without blind retry.
- Shared `SCR-041` delegation was regression-tested so BJ07 hardening does not override BJ09/BJ10 result semantics.

## Contract / documentation propagation

Updated in the cumulative package:

- Decision Register: `T7-DR-138…143`.
- BJ07 journey and UC-07-01…04.
- Shared behavioral contracts, including new `BC-IO-17` supplier-return synchronization ownership.
- Technical contracts and supplier-return sync event/handler mapping.
- `InventoryOperationLine` source-slice fields.
- Generalized `HandoverEvidence`.
- New `SupplierReturnPhysicalObservation` entity.
- UIF-07 and SCR-036/SCR-037/SCR-039/SCR-041 screen contracts.
- Component usage contract, screen registry/catalog, workbench presentation data.
- Runtime prototype and QA gates.

## QA

- BJ07 Deep Review: **52/52 PASS**, 5 focused UI captures, 0 browser/console errors.
- Prior locked BJ regression (BJ01/BJ02/BJ05/BJ06): **12/12 PASS**.
- Frozen-source immutability: **PASS · 108/108 files byte-identical**.
- Current package validation: **32/32 PASS**.
- Full Theme End-user regression: **19/19 PASS**.
- Flow & Logic E2E: **21/21 PASS**.
- All-flow runtime smoke: **89/89 PASS**, 0 errors.
- Runtime UI: **14/14 PASS**, 518 declared states.
- Representative coherence: **8/8 PASS**.
- Device frame: **7/7 PASS**, 89 screens checked.
