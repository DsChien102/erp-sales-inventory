# Changelog — v3.9.0

## Full Theme 7 end-user hardening

This release follows a full end-user review of all **17 Business Journeys + CAP-01**. It preserves the Theme 7 business decomposition and existing BJ state machines, and hardens the layer that joins those journeys into one production-like `Thêm → Kho` experience.

### Theme-level orchestration

- Replaced the fixed Warehouse Home work fixture with a **persona-aware work projection** for three review personas: `Nhân viên kho`, `Kiểm soát kho`, and `Quản lý kho`.
- `Việc của bạn` now changes with persona and current session outcome. A resolved task leaves the originating queue; the prototype can project downstream work such as valuation after a receiving handoff.
- Concrete work rows deep-link to the **exact business object/case/session** rather than reopening a generic queue:
  - receipt task → exact receiving context,
  - picking task → exact sales order,
  - stock-count task → exact active count,
  - valuation task → exact receipt,
  - reconciliation task → exact reconciliation case.
- The integrated review inspector gains a **Vai trò mô phỏng** control outside Product UI so persona projection can be reviewed without adding role-switching UI to the product.

### Safer manual entry

- `Chuyển tình trạng hàng` started from Kho now opens the item/product/lot selection list before editing a state.
- `Tạo yêu cầu tiêu hủy` started from Kho now opens the eligible-item list before request creation.
- A fixture product is no longer silently preselected when the user has not supplied object context.

### Entry-context-aware navigation

- Task-originated terminal/handoff screens receive an explicit **Về Kho** exit and resolve the originating work item.
- Catalog-originated flows can return to **Tất cả chức năng kho** rather than losing the discovery context.
- Existing internal BJ navigation remains unchanged.
- Supported `PENDING_APPROVAL` handoffs no longer expose Back into an editable draft revision.

### Permission / lifecycle projection

- Warehouse Home, `Bắt đầu việc mới`, and `Tất cả chức năng kho` are filtered by the active simulated persona.
- The long-tail catalog now includes **Tìm chức năng kho**.
- One-time opening-balance setup is hidden from the integrated catalog after successful initialization in the current session.
- The exhaustive **Theo BJ / UIF** tab remains unchanged and continues to expose every BJ/state for design review.

### Cross-BJ UX semantics

- BJ06 inspection screen is distinguished as **Kiểm hàng khách trả** rather than repeating the same generic title on consecutive screens.
- BJ09 action copy changes from system-centric `Gửi xử lý` to **Gửi chờ duyệt**, matching the actual handoff.
- BJ17 replaces implementation-centric `Định danh` / `Định danh xử lý` with **Lần xử lý** in Product UI.
- A completed approved over-receipt no longer retains unresolved-warning wording `Vượt chứng từ`; the final result uses **Đã duyệt vượt** with success semantics.
- Warehouse Home no longer shows an unbound `3 cần chú ý` badge on `Tồn kho` until a deterministic attention-filter destination exists.

## QA

- Full Theme End-user Hardening: **19/19 PASS**
- Semantic flow/logic regression: **21/21 PASS**
- All-flow runtime smoke: **89/89 PASS**
- Runtime UI: **14/14 PASS** across **518 declared states**
- Representative coherence: **8/8 PASS**
- Device frame: **7/7 PASS**, **89 screens checked**, canonical **402×874** Product viewport preserved
- Current package validation: **15/15 PASS**
- Focused visual captures: **5**
- Browser errors in focused hardening QA: **0**
