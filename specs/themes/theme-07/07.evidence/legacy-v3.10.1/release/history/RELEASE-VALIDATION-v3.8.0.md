# Release Validation — VET45 Theme 7 v3.8.0

**Status: PASS**

## Release objective

Reduce decision load for end users in the integrated Theme 7 experience without changing Theme 7 business decomposition. The `Kho` root must stop acting as an operation catalog and instead behave like a production-oriented Warehouse Work Center.

## Result

The integrated **Thêm → Kho** mode now follows **Task-driven Warehouse Home**:

- **Search first** — users can search product / SKU / lot context instead of choosing an inventory business process.
- **Việc của bạn** — the home surfaces concrete actionable work from current business context. Three tasks are visible by default; two more expand inline.
- **Tra cứu** — only two utility destinations stay directly visible: `Tồn kho` and `Báo cáo & thẻ kho`.
- **Tạo thao tác** — one CTA opens a bottom sheet with only four actions that users genuinely initiate themselves.
- Contextual / exception / setup / recovery journeys are not presented as ordinary Product menu choices.
- Exhaustive access to **17 BJ + CAP-01** is preserved in the separate **Theo BJ / UIF** workbench tab.
- Direct work/manual entries reuse the existing cumulative BJ runtime and return straight to Kho from the direct entry screen.
- No business renderer is cloned, no BJ is merged, and no state machine is redefined.

## Product-visible choice reduction

Before v3.8.0, the integrated Kho home ultimately exposed the complete Theme 7 journey catalog. In v3.8.0:

- default concrete work items: **3**;
- expanded concrete work items: **5**;
- direct utility destinations: **2**;
- manual operation entry points behind one CTA: **4**;
- exhaustive journey catalog in Product UI: **0**.

This preserves capability completeness while removing the requirement for end users to understand Theme 7 business architecture.

## Regression gates

- Task-driven Warehouse Home QA: **29/29 PASS**
- Static Consistency QA: **48/48 PASS**
- Runtime UI QA: **14/14 PASS** — **518** declared states
- Flow Logic E2E QA: **21/21 PASS**
- Full Theme Completion QA: **14/14 PASS**
- Representative Coherence QA: **8/8 PASS**
- List Navigation State QA: **15/15 PASS** — **0** mixed-peer defects
- List Surface Rhythm QA: **9/9 PASS** — **0** independent collisions
- Footer Action QA: **11/11 PASS**
- Radio / Helper DS QA: **9/9 PASS**
- All-flow Runtime Smoke: **89/89 renders PASS**
- Device Frame QA: **7/7 PASS**
- Current Package Validation: **17/17 PASS**
- Task-driven Home browser errors: **0**

## Scope boundary

This release changes only Theme-level presentation/read-model navigation in the integrated Product-like tab. It does **not** merge, split or redefine any Business Journey, business rule, state machine, commit point, approval boundary, recovery rule or persistence contract.

`CAP-01` production entry uncertainty (`BG-006`) remains unchanged. The capability is still fully reviewable in `Theo BJ / UIF` but is intentionally not exposed as an ordinary Warehouse Home menu choice.
