# CHANGELOG — v2.9.1

Parent: `v2.9.0`

## BJ07 UX hierarchy correction

- SCR-036: removed interleaved work-stage headings. All supplier-return requests now live in one `Navigation / Default` List Row collection; waiting uses the same row with `State=Disabled`.
- SCR-037: redesigned hierarchy to `request context → Product+UOM structural heading → exact LOT/non-LOT allocation rows`. Product and LOT no longer share the same visual weight.
- SCR-039: reduced context to decision-relevant facts and changed handover evidence to Product+UOM heading + grouped `Key-value Row` allocation facts.
- SCR-041: reused the same evidence hierarchy; finality hero remains distinct from factual evidence.
- Kept source-owned commercial rules, granular source-update invalidation, actual-handover commit boundary, cross-UOM prohibition and UNKNOWN/no-blind-retry behavior unchanged.
- Added v2.9.1 QA gates for collection homogeneity, parent/child hierarchy, multi-LOT scaling, final evidence reachability and prior-BJ regression.

No new Theme 7 component was created.
