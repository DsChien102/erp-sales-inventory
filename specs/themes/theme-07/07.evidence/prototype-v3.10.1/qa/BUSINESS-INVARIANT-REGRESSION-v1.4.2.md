# Business Invariant Regression v1.4.2

**Result: PASS · 17/17 checks**

Purpose: prove the semantic-hierarchy correction did not change core BJ03/BJ05/BJ06/BJ07 business behavior.

## Checks

- PASS — BJ03 selected quantity participates in valuation scope
- PASS — BJ03 pending received quantity is not mutated before commit
- PASS — BJ03 source conflict blocks readiness without explicit resolution
- PASS — BJ03 conflict becomes ready after source + reason
- PASS — BJ05 partial-enabled order can review after some valid pick
- PASS — BJ05 waiting order cannot review
- PASS — BJ06 wrong-LOT creates non-normal approval state
- PASS — BJ06 receipt not ready while request lines/approvals incomplete
- PASS — BJ07 fixture starts with all current allocations verified
- PASS — BJ07 source delta invalidates only one affected allocation
- PASS — BJ07 unaffected allocations retain evidence
- PASS — BJ07 affected allocation is marked for recheck
- PASS — BJ07 final review is blocked until all current allocations verified
- PASS — BJ07 physical mismatch hard-blocks handover readiness
- PASS — BJ07 same Product different UOM remains separate groups
- PASS — BJ07 UNKNOWN has no blind handover retry
- PASS — No JavaScript errors in regression
