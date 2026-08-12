# Release validation — v3.4.0

Parent: **v3.3.0**

## What changed

- BJ08 count/recount/review uses one grouped surface per product task: canonical Product `List Row` + aligned `Key-value Row` facts + canonical quantity entry.
- Removed repetitive `Cần đếm` badges; recount variance is evidence in the fact region instead of a competing status badge.
- BJ07 preparation/review uses one boundary per Product + UOM with flat LOT/non-LOT children and semantic whitespace between product groups.
- Audit & Control Product row + immediate fact surface pairs are visually joined instead of rendering two touching cards.
- Dense canonical `VChip` collections wrap and remain fully visible; partial clipping is blocked.
- No new core DS component or feature-specific DS pattern was introduced.

## Automated QA

- **PASS — 21/21 professional-composition gates.**
- **PASS — 497/497 declared-state renders** across all 17 BJ at the canonical 402 × 874 Product viewport.
- **PASS — 269/269 Audit & Control state renders.**
- **PASS — 0 browser page errors.**
- **PASS — no root/content horizontal overflow in declared states.**
- **PASS — all rendered canonical chip instances remain fully inside their chip container.**
- **PASS — BJ08 count rows do not repeat `Cần đếm`.**
- **PASS — BJ08 recount presents three aligned facts per product and no variance badge.**
- **PASS — BJ08 approval uses two grouped product review units.**
- **PASS — BJ07 collection-level boundary is removed; each Product/UOM group owns one boundary; LOT children remain flat.**

Detailed machine-readable QA: `specs/themes/theme-07/prototype/html/qa/PROFESSIONAL-COMPOSITION-QA-v3.4.0.json`.

## Business regression boundary

No intentional change to BJ/UC rules, state machines, action IDs, approval boundaries, inventory commit behavior, or navigation contracts.
