# Release validation — Theme 7 Prototype Harness v3.6.2

**Verdict: PASS — INDEPENDENT LIST/CARD RHYTHM CORRECTION**

Parent: **v3.6.1**  
Date: **2026-09-15**

## Defect found during full-runtime QA

The spacing issue reported on the BJ08 `Kiểm kê kho` list was not treated as a single-screen defect. The effective v3.6.1 runtime was scanned across all **518 declared route-state renders** for vertically adjacent surfaced cards/List Rows.

The audit found **8 true independent card-collision pairs** across three defect classes:

1. **BJ08 / UIF-08 — Inventory count sessions**: the two session cards on `SCR-042 / READY` had an effective gap of `0 px`.
2. **BJ09 / UIF-09 — State history**: two peer timeline cards touched in `CONFLICT`, `LOCKED` and `FINANCIAL_RESTRICTED` states.
3. **BJ15 / UIF-15 — Inventory result fallback states**: peer result cards touched in `ARCHIVED_DATA` and `STALE` states.

The same audit found **5 zero-gap pairs that are intentionally joined parent→child composite surfaces**. Those are not spacing defects: their border radii deliberately join the upper and lower surfaces into one semantic group. They remain unchanged.

## Correction

Independent peer surfaces now use the existing Figma Design System spacing token:

- inter-item gap: **12 px** (`--vet45-v2-space-3`)
- collection layer: transparent
- each row/card continues to own its own border, radius and white surface
- intentionally joined parent→child surfaces remain joined

The correction is applied at the relevant collection/composition layers rather than by inserting arbitrary margins into individual cards.

No business rule, field, permission, state, action, transition or navigation was changed. No new Design System component or pattern was introduced.

## QA gates

| Gate | Result |
|---|---:|
| List Surface Rhythm — all declared states | **9/9 PASS** |
| Independent collision pairs after fix | **0** |
| Footer Action regression | **11/11 PASS** |
| Static consistency | **34/34 PASS** |
| Semantic flow/logic E2E | **21/21 PASS** |
| Full Theme completion | **14/14 PASS** |
| Representative coherence | **8/8 PASS** |
| Runtime UI | **14/14 PASS** |
| All-flow runtime smoke | **89/89 PASS** |
| Canonical device frame | **7/7 PASS** |
| Current package validation | **13/13 PASS** |
| Browser page errors | **0** |

The list/card-specific gate scanned **518/518** declared route-state renders. The reported BJ08 pair now measures **12 px**; BJ09 affected timeline pairs measure **12 px**; BJ15 affected result pairs measure **12 px**. Product content has no horizontal overflow in the scan.

## QA evidence

- `specs/themes/theme-07/prototype/html/qa/LIST-SURFACE-RHYTHM-QA-v3.6.2.md`
- `specs/themes/theme-07/prototype/html/qa/RUNTIME-UI-QA-v3.6.2.md`
- `specs/themes/theme-07/prototype/html/qa/FOOTER-ACTION-QA-v3.6.2.md`
- `specs/themes/theme-07/prototype/html/qa/CURRENT-PACKAGE-VALIDATION-v3.6.2.md`

## Evidence boundary

This validates the browser prototype and represented UI/flow/state behavior. It does not prove production backend persistence, transaction, concurrency, outbox, network or crash/restart atomicity.
