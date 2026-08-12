# v0.2.8 — BJ-02 receipt-line UX/logic calibration

Scope: chỉ `BJ-02 / UIF-02`; các UIF khác giữ baseline v0.2.7.

## UX corrections

- Document line editor không còn UOM selector; Product/UOM luôn source-owned read-only.
- Quick UOM selector chỉ xuất hiện khi tạo item mới và Product có nhiều UOM inbound; sau selection UOM chỉ hiển thị một lần trong identity.
- Supplier search result rút gọn còn tên + mã NCC + SĐT; Product result còn tên + SKU + UOM hợp lệ.
- Ghi chú optional không lặp copy `Không bắt buộc`.
- LOT thành accordion mở/đóng thủ công; thêm lô mở lô mới, lô phụ có thể xóa có kiểm soát.
- Duplicate lot code bị chặn và đưa user tới lô đã có.
- Duplicate Quick Product+UOM dừng editor; chỉ giữ warning + CTA mở item hiện có.
- Quick item đã tạo có thể xóa; Document source item không bị xóa.

## Quantity / source feedback

- Document partial receipt là hợp lệ: `VBanner.info` nêu phần còn chưa nhận.
- Document over-source: `VBanner.warning` ngay khi nhập; approval/source guard vẫn do business contract/server quyết định.
- Exact receipt không thêm banner dư thừa.
- Exception quantity vượt tổng actual bị chặn bằng cross-field error.
- `Xong` cập nhật enable/disable theo dữ liệu hiện tại, không giữ trạng thái disabled cũ.

## DS

- Không tạo component/tone mới. Các correction dùng `VCombobox`, `VSelect`, `VCard`, `VBanner`, `VButton`, `VConfirmDialog`, `VEmptyState` theo Flutter DS authority.
