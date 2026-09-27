# Changelog — VET45 Theme 7 Prototype Harness v3.9.3

**Parent:** v3.9.2  
**Scope:** Wave 2 — BJ05 Lấy hàng & bàn giao — Deep-Dive Semantic Traceability hardening.

## Authority / review rule

- v3.9.2 was used as the **single Theme 7 review baseline**.
- No separate legacy Theme 7 source package was used as authority.
- v3.9.3 becomes the next cumulative review baseline after release.
- BJ01 and BJ02 retain their previously locked semantic contracts.

## Approved BJ05 decisions implemented

1. **Allocation / pick / consumption:** `allocated`, cumulative `picked`, and cumulative `consumed` are distinct facts.
2. **Partial handover:** handover increments consumption and writes immutable evidence; it does not shrink requested/allocation/picked history.
3. **Physical correction:** changing or recovering a stale LOT after pick requires explicit return-old/repick-new actor assertion.
4. **UNKNOWN:** fulfillment becomes `Đang xác minh bàn giao`, visible but non-actionable; the same operation identity is handed to BJ17 and blind retry is blocked.
5. **UOM and precision:** source UOM, base normalization, conversion snapshot/version and quantity precision are explicit.
6. **LOT pickability:** `lot_pickable_quantity` is a server-calculated allocation candidate snapshot, not LOT reservation.
7. **Partial policy:** source-owned, fulfillment-level and versioned.
8. **Handover evidence:** each committed handover creates structured immutable `HandoverEvidence` with operation/source/allocation/actor/time/line identity.
9. **Requested vs remaining:** requested source quantity is immutable; remaining-to-handover is derived.

## UX / content cleanup

- Raw `Còn N` quantities are not rendered as status badges.
- LOT candidates preserve original expiry precision (`DAY / MONTH / YEAR`).
- Pick input respects quantity precision instead of assuming integers.
- Physical correction is rendered from structured data and requires explicit confirmation.
- Result shows authoritative `Bàn giao lúc`.
- `Đang xác minh bàn giao` is distinct from generic `Đang chờ`.

## Runtime / data hardening

- Partial handover now updates `consumedQty` and `deliveredQty` only; allocation/requested/picked history remains intact.
- Source fixtures initialize `sourceVersion` consistently with the version guard and HandoverEvidence.
- HandoverEvidence uses the authoritative BJ05 `operationId` and source version.
- UNKNOWN handoff to BJ17 uses the exact same `operationId`, not the order identifier from the older generic wrapper.
- Integrated Warehouse Home disables the corresponding pick task while finality is being verified.

## Contract / documentation propagation

Updated inside the cumulative package:

- BJ05 journey and UC-05-01…05.
- Decision Register: new T7-DR-122…130.
- Shared behavioral contracts: BC-IO-05 / BC-IO-06 / BC-IO-15 semantics.
- Data entity model: PickAllocation extensions and new `ENT-IO-11 HandoverEvidence`.
- UIF-05 and SCR-025…029 screen contracts.
- Screen registry and workbench presentation data.
- Runtime fixtures, renderer behavior, integrated Home patch and QA gates.

## Cross-BJ impact scan

BJ01, BJ04, BJ09, BJ14, BJ15, BJ17 and outbound Theme 5 fulfillment semantics were checked for compatibility. Required shared semantics were propagated; no scheduled future BJ was redesigned ahead of its own review.

## QA

- BJ05 Deep Review: **22/22 PASS**, 5 focused captures, 0 browser errors.
- Current package validation: **25/25 PASS**.
- Full Theme End-user regression: **19/19 PASS**.
- Flow & Logic E2E: **21/21 PASS**.
- All-flow runtime smoke: **89/89 PASS**, 0 errors.
- Runtime UI: **14/14 PASS**, **518 declared states**.
- Representative coherence: **8/8 PASS**.
- Device frame: **7/7 PASS**, **89 screens checked**.
