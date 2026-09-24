# Inventory Audit & Control — Product Correction v1.6.0

Parent: **v1.5.0**. Target: **BJ08/UIF08 + BJ09/UIF09 + BJ10/UIF10**. Product approval status: **PENDING REVIEW**.

## Why this release exists
The prior v4.4.0 experiment was not built from the latest cumulative v1.5.0 lineage. v1.6.0 discards that release lineage and re-applies the validated Product corrections directly on v1.5.0 while protecting Valuation and all non-target UIFs.

## Locked corrections
- BJ08 true blind count + actor handoff + separate cancellation + price-basis blocker + same-operation recovery.
- BJ09 Product condition model + derived expiry + state whitelist + true read-only lock + physical/value invariant.
- BJ10 approval-not-disposal + separate physical completion + actual-qty guard + no price bypass + same-operation recovery.
- Architecture/entry explanation remains outside app UI.

## Release gate
Static, runtime scenario, end-user interaction, protected-flow regression, all-flow smoke and v1.5.0 Valuation regression are required. PASS is evidence, not Product freeze.
