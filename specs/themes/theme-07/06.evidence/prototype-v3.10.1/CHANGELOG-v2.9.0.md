# Changelog — v2.9.0

Parent: v2.8.2.

## BJ07 / UIF-07

- Migrated `SCR-036`, `SCR-037`, `SCR-039` and `SCR-041` to the live Figma Design System.
- Rebuilt the queue into semantic collections so actionable and ready requests use one Navigation/Default List Row anatomy while source-owned waiting work is an independent read-only Status collection.
- Reorganized physical preparation as request context → Product+UOM → exact source allocations. Multi-LOT scales with one 76px row per allocation instead of stacked repeated forms.
- Added canonical `VBottomSheet 4695:6353` physical verification: no X, content-hug geometry, optional comparison-only LOT field, mismatch blocker and no warehouse-side LOT/quantity substitution.
- Preserved granular source-version invalidation: only affected verification is reset; unaffected evidence remains valid.
- Rebuilt final review with grouped `Info Row`, compact Product+UOM context and per-allocation `Key-value Row`; removed redundant normal-state commit prose and duplicate confirmation.
- Rebuilt completed result with the same evidence hierarchy and preserved terminal no-back / UNKNOWN no-blind-retry / permission masking semantics.
- Corrected legacy UIF07 allocation-list padding that caused hidden horizontal drift; canonical Search & Filter Header remains its live 402px full-width composition.

No new feature component and no business-rule expansion.
