# BJ07 Static / Contract Conformance v1.3.9

**Result: PASS · 39/39 checks**

Coverage: decisions/SRS/UC source, exact-source physical semantics, queue ownership, Product+UOM multi-LOT model, mismatch/source-delta behavior, final review/result finality, registry/action/workbench parity and UIF07 CSS scoping.

## Checks

- PASS — Decision register locks exact-source supplier handover
- PASS — Decision register locks granular source invalidation
- PASS — BJ07 references v1.3.9 exact source amendment
- PASS — UC07-01 distinguishes source fact from physical verification
- PASS — UC07-02 removes manual state-change task
- PASS — UC07-03 defines affected-only invalidation and system release
- PASS — UC07-04 forbids arbitrary warehouse partial/LOT substitution
- PASS — UC07-04 locks result finality and UNKNOWN
- PASS — Queue default is ALL
- PASS — Queue filters all/prepare/ready/waiting
- PASS — Waiting source-owned row is read-only
- PASS — Search has no-result state
- PASS — Data model groups Product+UOM to allocations
- PASS — Mixed UOM fixture exists for same Product
- PASS — Source quantity is read-only in verification UI
- PASS — LOT scan is optional and mismatch blocker exists
- PASS — Physical mismatch does not offer quantity/LOT override
- PASS — Granular source update resets only affected allocation
- PASS — Source remove releases pending scope copy
- PASS — Source cancel closes task system-side
- PASS — Final review rechecks source version
- PASS — Final review has no second confirmation modal
- PASS — Final review explicitly avoids mixed-UOM aggregation
- PASS — Result creates immutable-like operation snapshot fields
- PASS — Result distinguishes completed/rejected/unknown/permission
- PASS — All result terminal states disable Back
- PASS — UNKNOWN has no blind retry and references BJ17
- PASS — Manifest version is 1.3.9
- PASS — Screen registry version is 1.3.9
- PASS — Action registry version is 1.3.9
- PASS — UIF07 active screen order is exactly 036/037/039/041
- PASS — UIF07 registry excludes state-change action
- PASS — UIF07 transition count is 8
- PASS — SCR039 states exclude approval and include source/mismatch
- PASS — ACT08RTV is one explicit review without repeat modal
- PASS — Workbench UIF07 has corrected patterns
- PASS — BJ/UI map has four active BJ07 screens
- PASS — Component usage version is v1.3.9
- PASS — All v1.3.9 CSS selectors are scoped to UIF07
