# Changelog — VET45 Theme 7 v3.8.1

Parent: **v3.8.0**

## Objective

Preserve the task-driven Warehouse Home introduced in v3.8.0 while restoring long-tail discoverability from the integrated Product-like experience, without putting the 17-BJ catalog back on the Kho home screen.

## Changes

### 1. Secondary full-function access

- Added one low-emphasis `Tất cả chức năng kho` navigation row at the end of the Kho home.
- The primary Warehouse Home remains task-driven: Search → Việc của bạn → Tra cứu → Tạo thao tác.
- `Tất cả chức năng kho` opens one secondary catalog screen rather than expanding the Home itself.
- The catalog exposes all **17 Business Journeys + CAP-01** through the same existing Theme 7 runtime; no business renderer is cloned.
- The catalog uses six visual groups only for scanning. Group headings do not create category routes.
- Contextual/exception/setup capabilities carry short origin cues such as `Từ đơn bán`, `Khi có sai sót`, `Khi cần xác minh`, and `Thiết lập`.
- A flow opened from the catalog returns to the catalog from its entry screen; Back from the catalog returns to the task-driven Kho home.

### 2. `Tạo thao tác` bottom-sheet cleanup

- Kept exactly four genuinely user-initiated actions:
  - Nhập hàng nhanh
  - Tạo phiên kiểm kê
  - Chuyển tình trạng hàng
  - Tạo yêu cầu tiêu hủy
- Removed the explanatory helper `Chỉ chọn khi bạn chủ động bắt đầu một việc mới.` because the sheet title already provides the needed context.
- Removed the redundant `Đóng` CTA.
- The sheet remains dismissible by backdrop click and Escape/system dismissal semantics.

### 3. Cross-theme bottom-sheet audit

Removed pure `Đóng` buttons from dismissible/view-only sheets where dismissal is already provided by the sheet/backdrop contract:

- BJ02 review-detail sheet;
- BJ08 select/search sheet;
- BJ15 product-detail viewer sheet.

Explicit cancel/decision actions remain where they protect user edits or mark a semantic boundary, including `Hủy`, `Quay lại`, `Xong`, `Lưu`, and confirmation actions.

## Non-changes

- No Business Journey was merged or split.
- No business rule, state machine, approval boundary, commit point, recovery rule, or persistence contract changed.
- The `Theo BJ / UIF` tab remains exhaustive and unchanged in purpose.
- CAP-01 production IA uncertainty `BG-006` remains open.

## QA summary

- Function Catalog & Bottom-sheet QA: **27/27 PASS**
- Static Consistency QA: **52/52 PASS**
- Radio / Helper DS QA: **9/9 PASS** across **518** route-state renders
- List Navigation State QA: **15/15 PASS** across **518** route-state renders
- List Surface Rhythm QA: **9/9 PASS**, **0** independent collisions
- Footer Action QA: **11/11 PASS**
- Flow Logic E2E QA: **21/21 PASS**
- Full Theme Completion QA: **14/14 PASS**
- Representative Coherence QA: **8/8 PASS**
- Runtime UI QA: **14/14 PASS** across **518** declared states
- All-flow Runtime Smoke: **89/89 PASS**
- Device Frame QA: **7/7 PASS**
- Current Package Validation: **17/17 PASS**
- Browser errors in focused v3.8.1 QA: **0**
