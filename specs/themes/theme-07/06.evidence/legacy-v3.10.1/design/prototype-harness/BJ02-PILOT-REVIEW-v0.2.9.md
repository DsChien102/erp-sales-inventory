# BJ-02 / UIF-02 — Pilot Review v0.2.9

## Scope

End-user QA calibration trên baseline v0.2.8. Kiến trúc `SCR-008 → SCR-009 → SCR-084 → SCR-010` được giữ; vòng này sửa information hierarchy, read-only semantics, review evidence và recovery UX. Không redesign các UIF khác.

## End-user issues fixed

1. `SCR-007` thêm search mã chứng từ/NCC; filter-empty giữ đúng context.
2. `SCR-008` supplier text tự do chưa resolve master ID có inline guidance rõ; note không có copy optional thừa.
3. `SCR-009` tách quantity/source relation khỏi classification/LOT; EMPTY đúng nghĩa; READ_ONLY mở detail ở true read-only.
4. `SCR-084` bỏ orphan copy “Theo chứng từ”; dùng `Còn chờ nhận` tại decision context, multi-LOT có derived total; partial=info, over=warning, exact=no noise.
5. LOT accordion header chỉ làm open/close; `Xóa lô` nằm cuối expanded content; existing exceptions tự mở; `Chưa nhận lần này` vẫn khả dụng sau khi đã nhập dữ liệu với confirm.
6. `SCR-010` review actual LOT code/quantity/expiry và Quick note; Quick mandatory approval = info; không duplicate approval banners.
7. `SCR-011` approver có đủ receipt context + request info + actual LOT evidence; chỉ Duyệt/Từ chối.
8. `SCR-012` dùng `Kết quả theo mục hàng`, đúng cả handled-zero; valuation notice chỉ ở valuation-pending.
9. `SCR-013` UNKNOWN chỉ một loading state; EMPTY dùng `VEmptyState`; timeline bỏ approval/movement/version IDs kỹ thuật, giữ tối đa một mã lần nhận có ích.

## Business semantics preserved

- Một Receipt = một Supplier.
- BJ-02 không tạo Supplier/Product.
- Document Product/UOM source-owned; Quick UOM chỉ chọn khi cần.
- Same Product + different UOM = separate items; same Product+same UOM Quick = duplicate blocker.
- Quick luôn approval; Document approval theo policy/exception.
- Execution system-owned; UNKNOWN không blind retry.

## Documentation impact

Không phát sinh business rule mới cần sửa SRS core. Thay đổi v0.2.9 được back-propagate vào UIF-02 flow, 9 Screen Contracts, UIF-02 Component Usage, Workbench metadata và registry BJ-02.
