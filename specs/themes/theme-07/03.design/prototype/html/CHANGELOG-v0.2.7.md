# v0.2.7 — BJ-02 multi-product mobile receiving redesign

## Scope

Chỉ BJ-02/UIF-02 được redesign. Các UIF khác giữ nguyên baseline v0.2.6.

## UX / UI

- Tách nhập hàng nhanh thành goods receipt header (`SCR-008`) và shared items overview (`SCR-009`).
- `SCR-009` không còn giant single-product form; hỗ trợ nhiều sản phẩm cho cả Document và Quick.
- Thêm `SCR-084 — Chi tiết hàng thực nhận` để chỉnh một Product + UOM ở một thời điểm.
- Document goods receipt preload toàn bộ source items; nhập hàng nhanh dùng `Thêm sản phẩm`.
- Product/UOM identity compact, neutral; không decorative badges hoặc colored icons.
- Quantity model: total actual + progressive exceptions; `Đạt` được derive.
- LOT quantity được nhập ở từng lot; total item derive từ lot totals, không nhập trùng.
- Multi-lot, expiry required/optional, manufacture date optional.
- Source item có thể `Chưa nhận lần này`.
- Quick duplicate same Product + UOM bị block; same Product + different UOM được phép là item khác.
- End-user copy dọn khỏi phase/enum/implementation jargon.

## Business / contracts

- Khóa one Goods receipt = one Supplier.
- Khóa no Product/Supplier creation inside BJ-02.
- Clarify UI mục hàng nhận = Product + transaction UOM; một item có thể materialize thành nhiều technical `InventoryOperationLine` theo lot/state.
- Add `receipt_item_ref` grouping field to `InventoryOperationLine` and supplier identity to goods receipt operation contract.
- Add decisions `T7-DR-103`..`T7-DR-105`.
- Back-propagate to BJ-02, UC-02-01/02/03, shared behavior, data entities, decision register, wiki, glossary, UIF-02 flow and component usage.

## DS

- Flutter DS remains authority; no new HTML design-system primitives.
- `VCard`, `VCombobox`, `VSelect`, `VQuantitySelector`, `VDatePicker`, `VButton`, `VBanner`, `VEmptyState`, `VBottomSheet`, `VToast` mapped explicitly.
- Mobile frame remains 402 × 874 px.
