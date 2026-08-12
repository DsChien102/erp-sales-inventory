# Changelog — VET45 Theme 7 Prototype Harness v3.9.6

**Parent:** v3.9.5  
**Scope:** Wave 2 — BJ04 Quản lý vòng đời giữ hàng — Deep-Dive Semantic Traceability hardening + Wave 2 Cross-BJ consolidation.

## Authority / review rule

- v3.9.5 was used as the **single Theme 7 review baseline**.
- Frozen-source remains historical and byte-identical.
- BJ01, BJ02, BJ05, BJ06 and BJ07 retain their locked semantic contracts.
- v3.9.6 becomes the next cumulative review baseline after release.

## Approved BJ04 decisions implemented

1. Reservation is an explicit source capability with `reservation_policy = NONE | ALL_OR_NOTHING | PARTIAL_ALLOWED`; Theme 7 reservation exists only for **Advanced Stock**. Current POS flow uses `NONE` and does not enter BJ04.
2. Reservation preserves the source transaction-UOM snapshot, precision/step, conversion-to-base and conversion version. `reserved_base_quantity` means **current held quantity**; `consumed_base_quantity` preserves cumulative committed handover history.
3. Remaining demand and shortage are derived from current facts: `remaining_required = max(0, requested - consumed)` and `shortage = max(0, remaining_required - reserved)`. ReservationBucket sums current held quantity only.
4. Capacity reduction uses deterministic priority: `reservation_priority → source_confirmed_at (older first) → stable source_line_id`. Capacity returning later does **not** auto top-up a reservation; the source must explicitly amend/re-evaluate.
5. BJ04 owns reservation capacity only. Once an active PickAllocation exists, BJ04 never mutates it; a relevant reservation change emits `allocation_review_required`, and BJ05 owns allocation revalidation/supersession and physical correction.
6. Combo reservation is modeled by `ReservationGroup` + child component reservations and commits atomically by complete combo quantity. Partial reservation never creates an incomplete component fragment.
7. `SCR-021` is a contextual, read-only **per-source-line current projection**. It no longer exposes global business states `FULL/PARTIAL/SHORT/RELEASED/STALE`; mixed lifecycle facts can coexist in one order.
8. Source-owned expiry is explicit through `expires_at`; Theme 7 does not invent an implicit reservation TTL.

## UX / runtime cleanup

- Current rows show `Cần giữ còn lại`, `Đang giữ`, shortage and meaningful lifecycle facts.
- Consumed lines retain committed handover history without remaining in ReservationBucket.
- Combo is shown as the source combo line; internal component reservations are not dumped into the Sales-facing surface.
- When no current hold remains, the screen shows the concise information `Không còn hàng đang giữ cho đơn này.` instead of rebuilding historical requested quantities.
- The static helper “Giữ hàng làm giảm khả dụng, không làm giảm tồn vật lý.” is removed from the normal product surface.
- Reservation remains contextual from the source order; the warehouse function catalog keeps BJ04 disabled/contextual rather than presenting it as a manual operational module.
- Legacy global BJ04 states safely fall back to the current projection during cumulative runtime compatibility, but are no longer declared in the active screen contract.

## Contract / documentation propagation

Updated in the cumulative package:

- Decision Register: `T7-DR-144…149`.
- BJ04 journey and UC-04-01…04.
- Shared behavioral contracts `BC-IO-03` and `BC-IO-06`.
- Technical contract/API-C-06 and reservation change event payload.
- `Reservation` quantity/UOM/priority model.
- New `ReservationGroup` aggregate for atomic combo reservation.
- UC-05-04 boundary: BJ05/`BC-IO-15` owns stale PickAllocation recovery.
- UIF-04 and `SCR-021` screen/component contracts.
- Screen registry/catalog, workbench presentation data and harness current registries.
- Runtime prototype overlay and QA gates.

## Wave 2 consolidation

After BJ04 regression, a horizontal cross-BJ audit was run across:

`BJ02 → BJ05 → BJ06 → BJ07 → BJ04`

The audit locks source identity/versioning, Product/UOM/LOT semantics, quantity authority, reservation/allocation ownership, evidence/approval boundaries, handover finality and UNKNOWN recovery consistently across Inventory Operations.

## QA

- BJ04 Deep Review: **52/52 PASS**, 4 focused UI captures, 0 browser/console errors.
- Prior locked BJ regression — BJ01/BJ02/BJ05/BJ06/BJ07: **15/15 PASS**.
- Wave 2 Cross-BJ Audit: **30/30 PASS**.
- Frozen-source immutability: **PASS · 108/108 files byte-identical**.
- Current package validation: **27/27 PASS**.
- Full Theme End-user regression: **19/19 PASS**.
- Flow & Logic E2E: **21/21 PASS**.
- All-flow runtime smoke: **89/89 PASS**, 0 errors.
- Runtime UI: **14/14 PASS**, 514 declared states.
- Representative coherence: **8/8 PASS**.
- Device frame: **7/7 PASS**, 89 screens checked.
