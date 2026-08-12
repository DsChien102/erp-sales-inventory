# Changelog — v3.8.3

## Warehouse Home clarity polish

- Replaced the mixed `Xem 2 việc khác | Tạo thao tác` row with one section-level disclosure action in **Việc của bạn**: `Xem tất cả (5)` when collapsed and `Thu gọn` when expanded.
- Replaced system-centric **Tạo thao tác** terminology with **Bắt đầu việc mới**.
- Rendered **Bắt đầu việc mới** as a canonical `DS v2 / List Row · Type=Navigation`, with helper `Nhập hàng nhanh, kiểm kê hoặc xử lý hàng`; it no longer competes visually with task disclosure.
- Renamed the manual-start bottom sheet to **Bắt đầu việc mới**. The sheet still exposes exactly four genuinely user-initiated starts and keeps backdrop/Escape dismissal with no redundant `Đóng` CTA.
- Removed explanatory `VBadge` usage from **Tất cả chức năng kho**. Conditions such as `Khi có sai sót`, `Khi có chênh lệch`, `Khi cần xác minh`, `Từ đơn bán`, `Khởi tạo`, and `Thiết lập` are not object statuses.
- `Giữ hàng theo đơn bán` is now a canonical **Disabled Navigation List Row** in the generic catalog, with helper `Thực hiện từ chi tiết đơn bán`, because the real entry remains contextual from the Sales Order.
- Preserved all **17 BJ + CAP-01**, existing business behavior, route/state renderers, task destinations, and the two-tab workbench architecture.

## QA

- Warehouse Home Clarity: **28/28 PASS**
- All-flow runtime smoke: **89/89 PASS**
- Runtime UI: **14/14 PASS** across **518 declared states**
- Device frame: **7/7 PASS**, **89 screens checked**, canonical **402×874** product viewport preserved
- Flow/logic E2E: **21/21 PASS**
- Focused browser errors: **0**
