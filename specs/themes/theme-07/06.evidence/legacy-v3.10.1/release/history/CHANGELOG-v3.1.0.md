# CHANGELOG — v3.1.0

Parent: **v3.0.1**

## Scope

Inventory Audit & Control cluster in one cumulative release: **BJ08, BJ09, BJ10, BJ11, BJ12, BJ15, BJ16, BJ17**.

## UI / DS corrections

- Rebuilt generic queues and case lists on canonical `DS v2 / List Row`; leading icons are hidden when they do not carry semantic identity and text reclaims the leading slot.
- Product rows retain Product identity icons; Product and lô/sub-scope data are shown with explicit parent-child hierarchy rather than peer cards.
- BJ08 count/recount uses grouped Product context, nested quantity input, and Key-value evidence.
- BJ09 state history uses canonical `DS v2 / Audit Item` (`525:621`); state choices use `VRadio`.
- BJ10 keeps approval separate from physical disposal completion.
- BJ11 correction strategy uses `VRadio`; operation facts and audit trail use grouped read-only surfaces.
- BJ12 uses a File Drop composition and grouped validation rows instead of one card per validation error.
- BJ15 replaces ad-hoc report/date selectors with `VRadio`; movement/source trace is compact and uses Audit Items.
- BJ16/BJ17 queues, evidence, recovery/finality and results are flattened into DS-native grouped surfaces.
- Removed raw user-facing English/technical vocabulary and revision labels from the Audit & Control cluster.
- No new core Design System component was introduced.

## Behavior

Existing journey topology, screen/state/action contracts and business handlers from v3.0.1 are preserved. Cross-BJ handoffs remain explicit: BJ11/BJ16 → BJ17 for unknown-result verification, and BJ16 → BJ11 for source correction.

## QA

`qa/AUDIT-CONTROL-CLUSTER-QA-v3.1.0.md`: **52/52 PASS**. Scope coverage: **44 canonical routes / 269 declared-state renders**. Full-harness regression: **85 canonical screens / 497 declared-state renders**, no browser errors and no root/content horizontal overflow.
