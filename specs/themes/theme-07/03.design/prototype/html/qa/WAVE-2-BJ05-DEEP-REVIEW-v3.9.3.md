# Wave 2 — BJ05 Deep Review Closure — v3.9.3

**Journey:** BJ05 — Lấy hàng & bàn giao  
**Baseline reviewed:** v3.9.2  
**Result:** Deep-Reviewed / Lock candidate  
**Authority:** cumulative Prototype Harness only; no separate legacy Theme 7 source package used.

## 1. Review objective

BJ05 was reviewed at field/data/action/finality level rather than only by screen flow. The review traced the full path `SCR-025 → SCR-026 → SCR-027 → SCR-028 → SCR-029`, including partial handover, LOT override, stale allocation, source-version guard, result finality and UNKNOWN recovery.

The main semantic gap was that the previous model blurred three different facts:

1. **Allocation plan** — quantity planned against a LOT.
2. **Pick evidence** — cumulative physical quantity actually picked.
3. **Handover consumption** — cumulative quantity actually handed over / issued.

v3.9.3 separates these facts and keeps their history immutable enough for partial fulfillment, audit and UNKNOWN recovery.

## 2. Approved decisions applied

| Decision | Applied semantic |
|---|---|
| BJ05-D01 | `PickAllocation` keeps separate allocated / picked / consumed quantities. Allocation is not reduced by handover. |
| BJ05-D02 | Partial handover writes immutable handover evidence and increments consumed quantity; requested/allocation/pick history is not rewritten. |
| BJ05-D03 | LOT change/stale recovery after physical pick creates a structured physical-correction assertion; entering new picked quantity cannot clear it. |
| BJ05-D04 | UNKNOWN becomes `Đang xác minh bàn giao`, remains visible but non-actionable, preserves the same operation identity and hands finality to BJ17. |
| BJ05-D05 | Source UOM, base quantity, conversion snapshot/version and quantity precision are explicit; UI uses source UOM while guards/ledger normalize to base UOM. |
| BJ05-D06 | `lot_pickable_quantity` is a server-calculated snapshot candidate, not a LOT reservation, and is revalidated before commit. |
| BJ05-D07 | Partial handover policy is fulfillment-level, source-owned and versioned. |
| BJ05-D08 | Each handover creates structured immutable `HandoverEvidence`; the handover CTA is the actor assertion. |
| BJ05-D09 | Requested quantity is immutable; remaining-to-handover is derived rather than a mutable replacement of requested quantity. |

## 3. Contract / model changes

- Added `picked_base_quantity`, `consumed_base_quantity` and `physical_correction_assertion` to the PickAllocation semantic model.
- Added owned entity `ENT-IO-11 — HandoverEvidence`.
- Total owned-entity catalog is corrected to **26** (11 Inventory Operations + 7 Inventory Control + 8 Inventory Valuation).
- Added decisions `T7-DR-122` through `T7-DR-130`.
- BC-IO-05 / BC-IO-06 / BC-IO-15 now distinguish plan, physical pick evidence, handover consumption, source-version recheck and finality.
- Workbench contracts for `SCR-025..029` were updated so the review surface describes the same semantics as the runtime.

## 4. Runtime / UX changes

### SCR-025 — Đơn cần lấy hàng
- `WAITING` remains source-owned waiting/shortage.
- UNKNOWN work becomes **Đang xác minh bàn giao**.
- Verification work remains visible for user awareness but is disabled/non-actionable.

### SCR-026 — Hàng cần lấy
- Requested quantity remains immutable.
- Remaining and progress are derived from delivered/picked/consumed facts.
- Stale correction is scoped to affected allocations.

### SCR-027 — Chi tiết lấy hàng
- Raw `Còn N` quantity is no longer treated as a status badge.
- LOT alternatives display server-calculated pickable quantity and preserve DAY/MONTH/YEAR expiry precision.
- LOT change after pick creates pending physical correction.
- User must explicitly confirm the physical return/repick correction; entering picked quantity alone does not clear it.
- Quantity input uses the UOM precision contract.

### SCR-028 — Rà soát bàn giao
- Maximum actual handover is `picked − consumed` per allocation.
- Source/allocation version is rechecked before commit.
- Partial handover does not shrink allocation or cumulative pick history.
- Commit creates immutable HandoverEvidence.

### SCR-029 — Kết quả bàn giao
- Completed/partial result shows authoritative `Bàn giao lúc`.
- UNKNOWN preserves exact `operationId`, locks retry, and hands the same operation to BJ17.

## 5. Fresh-eye findings fixed before closure

The post-change pass found and corrected two integration-level issues before closure:

1. **Source-version identity alignment:** runtime fulfillment fixtures now initialize `sourceVersion` consistently with the source/fulfillment version used by the stale-source review guard and HandoverEvidence.
2. **UNKNOWN operation identity:** the BJ17 handoff now carries the exact BJ05 `operationId`, not the order ID used by an older generic recovery wrapper.

These were fixed before the final QA run.

## 6. Shared / cross-BJ impact

Semantic impact was scanned without redesigning later journeys:

- **BJ01:** reservation remains Product+Warehouse authority; BJ05 LOT pickability is explicitly a pick-time candidate, not LOT reservation.
- **BJ04:** reservation consumption/release semantics remain compatible.
- **BJ09:** eligibility may invalidate allocation; physical correction contract can consume such invalidation later.
- **BJ14:** handover evidence can provide the issue/finality context required by valuation without exposing cost in warehouse UI.
- **BJ15:** immutable handover evidence provides provenance for later stock-card/history review.
- **BJ17:** UNKNOWN receives the same operation identity for safe finality verification.
- **Theme 5/source fulfillment:** partial policy and requested/source version remain source-owned; Theme 7 consumes rather than invents them.

No local redesign of those journeys was performed ahead of their scheduled deep review.

## 7. Final QA

| Gate | Result |
|---|---|
| BJ05 Deep Review | **22/22 PASS** |
| Current package validation | **25/25 PASS** |
| Full Theme End-user regression | **19/19 PASS** |
| Flow & Logic E2E | **21/21 PASS** |
| All-flow runtime smoke | **89/89 PASS** |
| Runtime UI | **14/14 PASS; 518 declared states** |
| Representative coherence | **8/8 PASS** |
| Device frame | **7/7 PASS; 89 screens checked** |
| Focused BJ05 captures | **5 generated** |
| Browser errors | **0** |

## 8. Closure

After the approved changes and fresh-eye corrections above, no remaining **P0/P1 semantic blocker** was found in BJ05. BJ05 is therefore a **Deep-Reviewed / Lock candidate** for Wave 2.

Future changes to allocation/pick/consumption semantics, partial policy, LOT pickability, physical correction, handover evidence or UNKNOWN finality must be treated as shared contract changes rather than local screen patches.
