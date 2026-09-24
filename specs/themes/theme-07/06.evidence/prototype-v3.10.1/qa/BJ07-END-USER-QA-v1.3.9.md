# BJ07 End-user / State QA v1.3.9

**Result: PASS · 65/65 checks**

Coverage: queue ownership/filter/search; waiting read-only; Product+UOM multi-LOT/mixed-UOM structure; real physical verification sheet; optional LOT typing; mismatch blocking; resume; exact-source final review; source-version stale guard; granular source invalidation add/change/remove; source cancellation; completed/rejected/unknown/permission finality; no Back-to-commit/blind retry; permission masking; mobile overflow.

## Checks

- PASS — Queue default filter is Tất cả
- PASS — Queue chip order is All/prepare/ready/waiting
- PASS — All queue shows actionable, ready and waiting requests
- PASS — Source-cancelled task is excluded from active queue
- PASS — Waiting task is not navigable
- PASS — Prepare filter excludes ready and waiting
- PASS — Ready filter shows fully verified task
- PASS — Waiting filter shows source-owned task
- PASS — Live search shows no-result
- PASS — Preparation begins with 0/4 physical allocations verified
- PASS — Same Product different UOM is represented as separate groups
- PASS — Same Product+UOM preserves multiple LOT allocations
- PASS — Non-LOT allocation remains explicit
- PASS — Review CTA disabled before full physical verification
- PASS — Source quantity has no editable quantity field
- PASS — LOT verify sheet opens as VBottomSheet
- PASS — Optional scan field starts blank
- PASS — Wrong typed LOT renders blocker
- PASS — Wrong LOT disables confirm
- PASS — Wrong LOT does not mutate authoritative source LOT
- PASS — Matching typed LOT enables confirm
- PASS — One allocation becomes physically verified
- PASS — Leave/resume preserves unaffected verification
- PASS — Physical mismatch renders source-amendment guidance
- PASS — Physical mismatch keeps source quantity unchanged
- PASS — Physical mismatch disables final review
- PASS — All exact-source allocations enable final review
- PASS — Final review reports Product+UOM and allocation counts
- PASS — Final review keeps mixed UOM quantities separate
- PASS — Final review has one handover commit CTA
- PASS — Final review does not show a second confirmation modal
- PASS — Final commit detects source version change
- PASS — Stale final review removes commit CTA
- PASS — Changed allocation resets verification
- PASS — Unaffected verified allocations stay verified
- PASS — Business-facing source delta is visible
- PASS — Existing source-delta fixture preserves unaffected evidence
- PASS — Repeated source change invalidates only changed allocation
- PASS — Source add creates unverified affected allocation
- PASS — Source remove system-releases allocation from current scope
- PASS — Source remove delta is business-facing
- PASS — Source cancel removes request without warehouse restore action
- PASS — Successful handover result is explicit
- PASS — Successful result keeps line-level mixed UOM evidence
- PASS — Successful result hides technical operation identity
- PASS — Successful result has no Back to consumed commit
- PASS — Successful result has safe queue CTA
- PASS — Completed request leaves active queue after safe CTA
- PASS — REJECTED_EXECUTION renders distinct non-success result
- PASS — REJECTED_EXECUTION result has no Back
- PASS — REJECTED_EXECUTION result has no handover retry CTA
- PASS — UNKNOWN renders distinct non-success result
- PASS — UNKNOWN result has no Back
- PASS — UNKNOWN result has no handover retry CTA
- PASS — PERMISSION_DENIED renders distinct non-success result
- PASS — PERMISSION_DENIED result has no Back
- PASS — PERMISSION_DENIED result has no handover retry CTA
- PASS — UNKNOWN explains safe reconciliation without technical IDs
- PASS — Permission denied masks supplier-return detail
- PASS — Final review permission state masks detail
- PASS — SCR-036 no horizontal overflow at mobile canvas
- PASS — SCR-037 no horizontal overflow at mobile canvas
- PASS — SCR-039 no horizontal overflow at mobile canvas
- PASS — SCR-041 no horizontal overflow at mobile canvas
- PASS — No page JavaScript errors
