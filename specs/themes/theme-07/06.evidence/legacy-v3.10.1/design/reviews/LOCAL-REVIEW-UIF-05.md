# LOCAL REVIEW — UIF-05 / BJ-05 — v1.3.7

> Result: `PASS AFTER CORRECTION` · This review supersedes the earlier local PASS that missed end-user/state-machine defects.

## Scope

- BJ: `BJ-05` — Lấy hàng và bàn giao đơn.
- Screens: `SCR-025..SCR-029`.
- Review lens: business state, end-user task, physical warehouse reality, Flutter-DS composition, runtime interaction and result finality.

## Defects corrected in v1.3.7

1. Queue now defaults to `Tất cả`; chip order is `Tất cả / Cần lấy / Đang chờ`; live search has no-result state.
2. Pick data is scoped by Order/Fulfillment; opening one order cannot render another order's lines.
3. Initial fixtures match lifecycle: actionable order is genuinely in-progress, not falsely complete.
4. LOT override Bottom Sheet accepts real click/focus/type. QA no longer treats direct `.fill()` as sufficient evidence for form usability.
5. Alternative LOT is not preselected and shows LOT/HSD/available quantity.
6. Manual LOT override after pick resets affected picked quantity and requires physical return/repick.
7. Stale recovery uses the same physical-correction model; affected pick is invalidated and handover stays blocked until repick.
8. Handover review renders only picked allocations; unpicked lines do not produce zero-quantity controls.
9. Review preserves customer context, supports actual/partial quantity, and shows product-level this-handover/remaining summary without cross-UOM quantity aggregation.
10. Normal physical confirmation rule is helper text, not a routine banner.
11. `SOURCE_CHANGED` blocks commit and routes back to updated pick state.
12. Result states are distinct: full, partial, rejected, permission denied, UNKNOWN.
13. Result has safe CTA and no Back to the already-consumed commit screen.
14. Partial/full commit mutates the prototype domain fixture: actual quantity is consumed, remaining task continues, completed task leaves the active queue.
15. Registry/contracts/UC flow were reconciled; normal handover has no approval state.

## QA gate

- End-user/state QA uses real click/focus/type, not only element presence or programmatic value assignment.
- State matrix includes `PARTIAL_COMPLETED`, `REJECTED_EXECUTION`, `PERMISSION_DENIED`, `UNKNOWN`, and `SOURCE_CHANGED`.
- Visual specimens reviewed at canonical 402×874 Product viewport.

## Verdict

`PASS` for v1.3.7 BJ05 correction scope. Product approval is still separate from automated QA.
