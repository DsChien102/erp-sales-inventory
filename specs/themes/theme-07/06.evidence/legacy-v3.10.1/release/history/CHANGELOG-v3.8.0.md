# CHANGELOG — v3.8.0

Parent: **v3.7.1**

## Changed

- Replaced the integrated `Kho` flat operation hub with a **task-driven Warehouse Home**.
- Product-like `Toàn Theme 7` mode no longer exposes all 17 BJ + CAP-01 as normal menu choices.
- Added **inventory search** as the first accelerator for product / SKU / lot context.
- Added **Việc của bạn** as a concrete work projection. Three current tasks are visible by default; two more expand inline without pushing navigation history.
- Work items route directly into the existing owning BJ screen, for example:
  - purchase receipt → BJ02 `SCR-009`;
  - picking → BJ05 `SCR-026`;
  - active stock count → BJ08 `SCR-044`.
- Added a small **Tra cứu** utility surface with only `Tồn kho` and `Báo cáo & thẻ kho`.
- Added a single **Tạo thao tác** CTA opening the canonical bottom sheet for user-initiated operations:
  - `Nhập hàng nhanh`;
  - `Tạo phiên kiểm kê`;
  - `Chuyển tình trạng hàng`;
  - `Tạo yêu cầu tiêu hủy`.
- Direct task/manual entry screens use a **return-to-Kho entry boundary** so Back does not force the user through irrelevant prerequisite/menu screens.
- Contextual, exception, setup and recovery journeys are intentionally absent from Product navigation and remain fully accessible in the separate **Theo BJ / UIF** review tab.
- Preserved all existing 17 BJ + CAP-01 screen renderers, business rules, state machines, actor boundaries and result semantics.

## Navigation rule locked

> **Business-journey completeness belongs to the review harness; Product navigation exposes only concrete work, useful lookup and genuinely user-initiated actions.**

The user should not need to understand Theme 7 domain taxonomy in order to choose the next task.

## UI authority

No new core Design System component was introduced. The Warehouse Home reuses existing Figma DS primitives/patterns:
- `VAppBar`
- `VSearchBar`
- `DS v2 / List Row`
- `VBadge`
- `VButton`
- `VBottomSheet`
- existing spacing, typography, state and disabled conventions

## QA

- Task-driven Warehouse Home: **29/29 PASS**
- Static consistency: **48/48 PASS**
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
- Current package validation: **17/17 PASS**
- Browser errors in task-driven home gate: **0**
