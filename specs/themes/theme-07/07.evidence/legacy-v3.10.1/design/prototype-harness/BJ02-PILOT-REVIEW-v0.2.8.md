# BJ-02 / UIF-02 — Pilot Review v0.2.8

## Scope

Calibration UX/logic cho `SCR-008`, `SCR-009`, `SCR-084` và các bề mặt BJ-02 liên quan. Không redesign các UIF khác.

## Decisions preserved

- Một receipt = một Supplier; không tạo Supplier/Product trong BJ-02.
- Document Product/UOM lấy từ source; Quick UOM chỉ chọn khi cần.
- Multi-product và same Product/different UOM dùng separate receipt items.
- `SCR-009` là overview; `SCR-084` là one-item editor; LOT là substructure trong editor.
- Quick luôn approval; execution tự động sau quyết định hợp lệ.

## v0.2.8 findings fixed

1. Bỏ duplicate UOM control ở Document và sau Quick selection.
2. LOT editor có manual accordion + delete extra lot + duplicate lot guard.
3. Khôi phục source variance feedback đúng semantics: partial=info, over=warning, exact=no noise.
4. Search Supplier/Product chỉ giữ dữ kiện giúp chọn đúng master, không phình card.
5. Duplicate Quick Product+UOM không render editor thừa.
6. Quick receipt item có delete có kiểm soát; Document source item dùng `Chưa nhận lần này`.
7. Master Supplier phải resolve thành master ID; text tự do không đủ điều kiện submit header.
8. Live validation cập nhật footer và cross-field feedback ngay khi user nhập.

## Design principle

Visible UI chỉ chứa thông tin giúp user ra quyết định hoặc hoàn tất task. Thông tin kỹ thuật/enum/Phase không xuất hiện trong product viewport.
