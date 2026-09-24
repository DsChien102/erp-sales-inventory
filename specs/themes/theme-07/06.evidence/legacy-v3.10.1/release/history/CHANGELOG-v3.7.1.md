# CHANGELOG — v3.7.1

Parent: **v3.7.0**

## Changed

- Refactored the integrated **Kho** root from a long grouped catalog into a **flat task hub**.
- Added a small **Cần xử lý** surface for current work using the same canonical `DS v2 / List Row` anatomy.
- Kept seven high-frequency destinations visible as direct one-tap routes from Kho.
- Moved eleven lower-frequency/contextual/setup destinations behind **inline progressive disclosure** on the same screen.
- Expand/collapse does **not** create a route, push history, or introduce a category screen.
- Preserved direct access to all **17 BJ + CAP-01** after expansion.
- Preserved deterministic flow-entry Back to **Kho** in the integrated tab.
- Preserved the existing **Theo BJ / UIF** workbench mode and all business screen renderers/state objects.

## Navigation rule locked

Visual grouping is not navigation. Theme 7 business clusters may structure documentation and visual hierarchy, but they must not automatically become intermediate product routes. Frequent user tasks should remain reachable as `Kho → BJ`; infrequent tasks may use same-screen progressive disclosure.

## UI authority

No new core Design System component was introduced. The hub reuses:
- `VAppBar`
- `DS v2 / List Row`
- `VBadge`
- `VButton`
- existing Theme 7 spacing/tokens

## QA

- Flat hub navigation: **20/20 PASS**
- Static consistency: **43/43 PASS**
- Runtime UI: **14/14 PASS** across **518 declared route-state renders**
- Semantic flow E2E: **21/21 PASS**
- Full Theme completion: **14/14 PASS**
- Representative coherence: **8/8 PASS**
- List navigation-state: **15/15 PASS**
- List/card rhythm: **9/9 PASS**
- Footer action: **11/11 PASS**
- Radio/helper DS: **9/9 PASS**
- All-flow runtime smoke: **89/89 renders PASS**
- Device frame: **7/7 PASS**
- Browser page errors in the flat-hub navigation gate: **0**
