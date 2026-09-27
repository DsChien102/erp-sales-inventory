# BJ05 End-user / State QA v1.3.7

**Result: PASS · 48/48 checks**

Coverage: queue defaults/filter/search; per-order data scoping; real click/focus/type LOT override; alternative LOT information; physical pick invalidation for manual override/stale; partial/full handover; state mutation; result finality/state matrix; source-changed blocker; mobile overflow.

## Checks

- PASS — Queue default filter is Tất cả
- PASS — Queue chip order is Tất cả/Cần lấy/Đang chờ
- PASS — Queue all shows actionable and waiting
- PASS — Cần lấy filters source-waiting out
- PASS — Live search has no-result state
- PASS — Waiting order shows its own customer/lines
- PASS — Waiting order does not leak first order lines
- PASS — Waiting order has no handover CTA
- PASS — Waiting item rows are read-only without navigation affordance
- PASS — Actionable order is in-progress fixture
- PASS — Overview does not repeat success badge on untouched line
- PASS — Override reason accepts real click/focus/type
- PASS — Override does not preselect alternative
- PASS — Alternative LOT shows expiry and availability
- PASS — Override resets picked evidence
- PASS — Override gives physical return/repick instruction
- PASS — Unresolved physical correction blocks handover
- PASS — Completed physical correction clears blocker
- PASS — Stale replaces LOT in actual row
- PASS — Stale tells user exactly what to return/take
- PASS — Stale blocks handover until repick
- PASS — Review renders only picked allocations
- PASS — Review keeps customer at irreversible commit
- PASS — Review updates handover summary
- PASS — Normal physical rule is helper, not info banner
- PASS — Partial result is explicit
- PASS — Partial result has continuation CTA
- PASS — Result cannot Back to commit screen
- PASS — Partial commit consumes only actual handover quantity
- PASS — Continuation goes to current order pick state
- PASS — Full result is explicit
- PASS — Full result CTA returns queue
- PASS — Full result no Back
- PASS — Completed order removed from active queue
- PASS — REJECTED_EXECUTION renders distinct result
- PASS — REJECTED_EXECUTION has no back to commit
- PASS — PERMISSION_DENIED renders distinct result
- PASS — PERMISSION_DENIED has no back to commit
- PASS — UNKNOWN renders distinct result
- PASS — UNKNOWN has no back to commit
- PASS — SOURCE_CHANGED blocks commit
- PASS — SOURCE_CHANGED gives safe recovery CTA
- PASS — SCR-025 no horizontal overflow
- PASS — SCR-026 no horizontal overflow
- PASS — SCR-027 no horizontal overflow
- PASS — SCR-028 no horizontal overflow
- PASS — SCR-029 no horizontal overflow
- PASS — No page JavaScript errors
