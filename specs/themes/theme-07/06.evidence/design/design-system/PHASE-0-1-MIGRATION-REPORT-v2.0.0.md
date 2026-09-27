# Phase 0 + Phase 1 — Figma DS migration report v2.0.0

## Scope completed

- Parent `v1.9.0` copied cumulatively; no SRS/BJ/UC/business flow content rewritten.
- Live Figma DS v2.0.2 locked by file/page IDs.
- 4 variable collections / 119 variables inventoried.
- 15 typography styles and 4 live effect styles frozen into a local translation manifest; 21 paint styles recorded as semantic-variable convenience styles.
- 49 Component Sets + 15 standalone canonical Components locked by exact node ID.
- 22 Pattern/Template assets locked by exact node ID.
- Legacy Flutter DS authority deprecated for v2.0.0; historical lock remains in package only for provenance.
- `tokens.generated.css` converted from Flutter snapshot to a Figma-first foundation adapter while retaining compatibility aliases so the unchanged v1.9.0 renderer can still execute.
- Known Figma documentation/live-definition conflicts are explicit in `ds-gap-register.md`; no silent reconciliation.

## Intentionally not done yet

- No screen composition has been migrated to exact Figma Component/Pattern/Template anatomy yet.
- No existing Theme 7 product flow/action/permission/state topology has been redesigned.
- Inspect mode has not yet been rewritten from legacy DS naming to exact Figma node/variant mapping.
- No claim that the 73 screens are visually Figma-conformant yet.

## Next gate

Phase 2: build the HTML ↔ Figma component registry and Inspect mapping, then run representative calibration on BJ02/BJ05/BJ08-BJ10/BJ15/BJ17 before broad screen migration.
