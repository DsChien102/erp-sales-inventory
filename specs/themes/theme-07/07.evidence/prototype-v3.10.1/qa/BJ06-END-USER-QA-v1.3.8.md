# BJ06 End-user / State QA v1.3.8

**Result: FAIL · 54/65 checks**

Coverage: queue defaults/filter/search; physical verification; multi-LOT + combo trace; wrong-LOT evidence; multi-case approval; exact approval-case binding/finality; real reject typing; snapshot invalidation; cumulative-cap conflict; permission masking; receipt result finality; direct classification re-entry; classification draft/cancel/hard guard; mixed-UOM result semantics; completed-task removal; result state matrix; mobile overflow.

## Checks

- FAIL — Queue default filter is Tất cả
- PASS — Queue chip order is Tất cả/Cần xử lý/Đang chờ
- PASS — Queue all shows actionable and waiting
- PASS — Actionable filter hides waiting request
- PASS — Live search shows no-result state
- PASS — Receipt overview starts 0 lines verified
- FAIL — Source LOT is not treated as actual confirmation
- FAIL — Same Product/UOM can appear for multiple source LOT allocations
- FAIL — Combo component context is visible
- PASS — Receipt commit disabled before physical verification
- PASS — Actual quantity is blank before user verification
- PASS — Normal LOT is direct choice
- PASS — Free-text LOT hidden on normal path
- PASS — Saving normal line marks only that line verified
- PASS — Wrong LOT reveals mandatory reason choices
- PASS — Evidence upload produces visible preview
- PASS — Wrong LOT saves as request draft, not approver navigation
- FAIL — Overview labels wrong LOT as ready to submit
- PASS — Request offers one batch submit for multiple line exceptions
- PASS — Each wrong-LOT line creates its own approval case
- PASS — Maker request becomes waiting while any case pending
- FAIL — Waiting overview is read-only
- PASS — Approver actor context lists exact pending cases
- PASS — Approver detail is bound to selected approval_case_id
- FAIL — Approver can view evidence image, not only filename
- PASS — Reject reason accepts real click/focus/type
- PASS — Rejected decision is final with no decision actions
- PASS — Rejected case stores decision reason
- PASS — One rejected + one approved returns request to maker instead of staying pending
- PASS — Changing rejected snapshot to normal LOT invalidates old exception binding
- PASS — Receipt becomes ready after rejected line is corrected and remaining mismatch is approved
- PASS — Changing approved quantity invalidates prior approval snapshot
- PASS — Return-cap changed state removes commit CTA
- PASS — Return-cap changed gives safe refresh CTA
- PASS — Permission denied masks protected return details
- PASS — Fully verified normal request enables receipt commit
- FAIL — Receipt result uses line count instead of mixed-UOM numeric sum
- PASS — Receipt result shows per-line quantities/UOM
- PASS — Receipt result has no Back to consumed commit screen
- PASS — Receipt result has primary classify and secondary defer actions
- PASS — Deferred receipt remains actionable as Cần phân loại
- PASS — Classification re-entry goes directly to SCR-033
- PASS — Cần phân loại queue routes directly to classification
- PASS — Classification fixture starts 0/2, not pre-completed
- PASS — Classification editor has safe cancel action
- FAIL — Expired hard guard visible for known expired stock
- PASS — Cancel discards classification draft
- PASS — Classification CTA enables only after all lines valid
- FAIL — Final result keeps per-line/UOM semantics
- FAIL — Final result does not aggregate mixed UOM as generic products
- PASS — Final result has safe queue CTA and no Back
- PASS — Completed request is removed from active queue
- PASS — REJECTED_EXECUTION renders distinct non-success result
- PASS — REJECTED_EXECUTION has no back to mutation
- PASS — PERMISSION_DENIED renders distinct non-success result
- PASS — PERMISSION_DENIED has no back to mutation
- PASS — UNKNOWN renders distinct non-success result
- PASS — UNKNOWN has no back to mutation
- PASS — SCR-030 no horizontal overflow
- PASS — SCR-031 no horizontal overflow
- PASS — SCR-032 no horizontal overflow
- PASS — SCR-034 no horizontal overflow
- PASS — SCR-033 no horizontal overflow
- PASS — SCR-035 no horizontal overflow
- PASS — No page JavaScript errors
