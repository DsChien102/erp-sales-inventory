# BJ09 Fresh-eye QA — v3.10.1

**Result: PASS · 31/31**

Captures: **10**

- PASS — list uses user-facing Dùng thử and no technical enum leakage
- PASS — list keeps search and five business filters
- PASS — filter strip stays compact/horizontal without forcing screen overflow
- PASS — sellable detail shows business identity, physical and available facts
- PASS — sellable detail exposes one contextual state-change CTA
- PASS — expired detail explains automatic expiry from business date
- PASS — expired detail has no manual state-change CTA
- PASS — stock-count locked detail is true read-only
- PASS — state-change form presents current state as read-only context
- PASS — destinations contain policy-allowed business states only
- PASS — partial quantity is explicit user input
- PASS — form does not expose valuation/balance/hash/version controls
- PASS — form copy stays Vietnamese/business-facing
- PASS — validation is persistent inline/banner and keeps entered quantity
- PASS — maker pending surface explicitly says inventory has not changed
- PASS — maker pending surface has no approve/reject/state-write CTA
- PASS — approval focuses on business evidence and impact
- PASS — approval hides basis hashes, policy versions and valuation slices
- PASS — approval exposes only decision actions
- PASS — reject confirmation starts disabled without a reason
- PASS — reject CTA enables immediately after valid reason
- PASS — reject result is final and explicitly zero stock effect
- PASS — approve enters system-processing surface instead of claiming immediate stock write
- PASS — completed result states physical quantity is unchanged
- PASS — completed result states book value is unchanged
- PASS — completed result exposes actionable reservation impact
- PASS — history is business-readable without technical identifiers
- PASS — stale result says no stock change and requires a new request
- PASS — UNKNOWN prohibits blind resubmit and routes to verification
- PASS — focused BJ09 surfaces fit 402x874 and AppBar back target is at least 44x44
- PASS — fresh-eye run has no browser errors and exactly ten captures
