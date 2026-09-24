# Changelog — Theme 7 Prototype Harness v3.6.2

Parent: **v3.6.1**  
Date: **2026-09-15**

## Independent list/card rhythm correction

- Fixes the reported BJ08 `Kiểm kê kho` defect where independent session cards visually touched because their collection had no effective vertical gap.
- Expands the correction from the reported screen to the complete runtime instead of patching one screen locally.
- Whole-runtime audit across **518 declared route-state renders** identified **8 independent card-collision pairs** in three real defect classes:
  - BJ08 / UIF-08 — inventory-count session list.
  - BJ09 / UIF-09 — state-history timeline cards in conflict/locked/financial-restricted states.
  - BJ15 / UIF-15 — fallback inventory-result cards in archived/stale states.
- All independent peer surfaces now use the existing Figma DS spacing rhythm **12 px** (`--vet45-v2-space-3`) and keep the collection background transparent so page background remains visible between cards.
- The audit also identified **5 zero-gap pairs that are intentional joined parent→child composite surfaces**. They are preserved and explicitly excluded from the independent-card rule.

## QA expansion

- New `LIST-SURFACE-RHYTHM-QA-v3.6.2` scans all **518** declared route-state renders, distinguishes independent cards from joined composites, and checks Product-content horizontal overflow plus browser page errors.
- Post-fix independent collision pairs: **0**.
- Existing footer correction remains intact: **11/11 PASS**, with all **17** dual-action footers still horizontal and correctly ordered.
- Full regression remains green: static consistency **34/34**, semantic flow logic **21/21**, full-theme completion **14/14**, representative coherence **8/8**, runtime UI **14/14**, all-flow runtime smoke **89/89**, device frame **7/7**, current package validation **13/13**, and **0 browser page errors**.

## Scope lock

- UI composition/spacing correction only.
- No business rule, field, permission, state, action, transition or navigation change.
- No new Design System component or pattern.
