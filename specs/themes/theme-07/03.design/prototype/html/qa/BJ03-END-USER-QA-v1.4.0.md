# BJ03 End-user / State QA v1.4.0

**Result: PASS · 71/71 checks**

Coverage: valuation worklist/search/filter; identified quantity slice and partial confirmation; evidence missing; provenance-first calculation; source conflict selection/reason; FX provenance; value vs sellability; source-version stale guard; exact partial commit; result finality; permission masking; UIF13 shared-screen fallback; 402×874 geometry.

## Checks

- PASS — Queue title is business-facing
- PASS — Queue uses receipt task summaries
- PASS — Queue does not use old 118 hộp aggregate
- PASS — Queue has 3 filters
- PASS — Missing filter isolates missing evidence receipt
- PASS — Search no-result is explicit
- PASS — Missing evidence banner is shown
- PASS — Missing evidence slice is disabled
- PASS — No price input on scope screen
- PASS — Scope groups same receipt by Product+UOM
- PASS — Scope distinguishes sellable and quarantine
- PASS — Calculation CTA disabled with no scope
- PASS — Partial selected quantity retained in model
- PASS — Scope CTA enables after selection
- PASS — Scope content remains reachable above sticky footer
- PASS — Authoritative price is not rendered as editable money input
- PASS — Ready source shows provenance read-only
- PASS — Calculation shows discount line
- PASS — Conflict warning is explicit
- PASS — Conflict source has two candidates
- PASS — Conflict has no preselection
- PASS — Review CTA disabled before conflict resolution
- PASS — Reason is required after explicit source selection
- PASS — Review CTA enables after source+reason
- PASS — Review has one direct valuation commit CTA
- PASS — Late cost action is not visible in UIF03
- PASS — No second approval copy in UIF03
- PASS — Mixed UOM quantities stay separate
- PASS — Quarantine availability is explicitly not released
- PASS — Review separates availability semantics
- PASS — Source update increments source version
- PASS — Affected group source selection reset
- PASS — Unaffected conflict group reason preserved
- PASS — Stale commit is blocked
- PASS — Stale review shows business delta before reconciliation
- PASS — Stale review removes commit CTA
- PASS — Stale review offers safe reconciliation
- PASS — Completed result is explicit
- PASS — Commit decrements exact selected slice only
- PASS — Unselected product slice remains pending
- PASS — Result distinguishes sellable and quarantine effects
- PASS — Completed partial result offers continue remaining
- PASS — Completed result has no Back to consumed commit
- PASS — Remaining scope screen shows only pending values
- PASS — FX fixture shows foreign unit price
- PASS — FX fixture shows accounting provenance
- PASS — FX guidance remains reachable above sticky footer
- PASS — UNKNOWN distinct result
- PASS — UNKNOWN has no Back
- PASS — UNKNOWN has no commit retry CTA
- PASS — REJECTED_EXECUTION distinct result
- PASS — REJECTED_EXECUTION has no Back
- PASS — REJECTED_EXECUTION has no commit retry CTA
- PASS — PERMISSION_DENIED distinct result
- PASS — PERMISSION_DENIED has no Back
- PASS — PERMISSION_DENIED has no commit retry CTA
- PASS — UNKNOWN explicitly forbids resubmission
- PASS — UNKNOWN hides technical operation id
- PASS — Rejected result offers provenance reconciliation
- PASS — Rejected result returns to calculation, matching flow contract
- PASS — Permission denied omits source prices
- PASS — Review permission denied omits financial total
- PASS — UIF13 shared review remains on baseline generic renderer
- PASS — UIF13 does not render UIF03 custom source-slice review
- PASS — Product viewport is 402x874
- PASS — SCR-014 no horizontal overflow
- PASS — SCR-015 no horizontal overflow
- PASS — SCR-016 no horizontal overflow
- PASS — SCR-017 no horizontal overflow
- PASS — SCR-019 no horizontal overflow
- PASS — No page JavaScript errors
