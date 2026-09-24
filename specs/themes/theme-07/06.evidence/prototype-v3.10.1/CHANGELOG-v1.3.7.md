# CHANGELOG — v1.3.7

Parent: `v1.3.6`  
Scope: **BJ-05 / UIF-05 deep correction after Product review**.

## Product / UX

- `SCR-025` queue defaults to `Tất cả`; chip order is `Tất cả / Cần lấy / Đang chờ`.
- Live search now has a real no-result surface that preserves query/filter context.
- Waiting work remains inspectable but is visually/read-only separated from warehouse-actionable pick work.
- `SCR-026` reads lines from the selected Order/Fulfillment only; cross-order fixture leakage removed.
- In-progress fixtures now match lifecycle instead of showing a `Cần lấy` task that is already fully picked.
- Stale allocation invalidates affected picked evidence and explicitly requires return/repick before handover.
- Read-only/waiting item rows no longer show an item chevron that implies an available action.
- `SCR-027` LOT override Bottom Sheet accepts real click/focus/type and no longer closes when the reason field is focused.
- Alternative LOT is not preselected and exposes LOT code, expiry and available quantity.
- Manual LOT replacement after pick resets affected picked quantity; old physical evidence is never transferred to the replacement LOT.
- `SCR-028` renders picked allocations only, preserves customer context, supports actual/partial handover quantity and blocks commit after source change.
- Handover summary avoids adding quantities across incompatible UOMs; actual quantities remain visible per Product/UOM/LOT.
- `SCR-029` distinguishes full, partial, rejected execution, permission denied and UNKNOWN results.
- Result surfaces have a safe CTA, no Back into the consumed commit screen and no blind-retry path.
- Partial commit mutates remaining work and continues the same order; full commit closes/removes the active task.

## Business/source consistency

- UC-05-01 clarifies allocation preparation as system-owned rather than a user CTA.
- UC-05-02/04 clarify physical correction: LOT change/stale invalidates old picked evidence and requires repick.
- UC-05-03 clarifies actual handover, partial continuation and result finality.
- UIF05 flow, Screen Contracts `SCR-025..029`, component usage and registries were reconciled with the corrected behavior.
- Normal BJ05 handover has no approval state.

## QA/process correction

- Added real pointer/focus/keyboard coverage for Bottom Sheet form interaction; programmatic `.fill()` alone is no longer accepted as proof of usability.
- Added order-scoping, stale/override physical correction, partial/full domain transition, result-state matrix, source-changed blocker and finality checks.
- Visual evidence expanded to queue, actionable/waiting details, override, stale, handover, source change and full/partial/rejected results.

## Protected scope

BJ01, BJ02, BJ04, BJ06, BJ07 and unrelated UIF flows/contracts remain outside the intended redesign scope of v1.3.7.
