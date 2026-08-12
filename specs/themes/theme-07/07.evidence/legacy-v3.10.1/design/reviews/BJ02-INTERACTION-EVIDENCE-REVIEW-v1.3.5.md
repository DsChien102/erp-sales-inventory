# BJ02 — Interaction & Evidence Review v1.3.5

## Kết luận
Feedback Product được chấp nhận. Cả ba điểm đều có cùng một nguyên nhân gốc: UI trước đó chưa phản ánh đúng **semantic của dữ liệu**, tạo thêm tap không cần thiết hoặc dùng control/copy khiến user hiểu sai hành động.

## 1. Thông tin nhập hàng nhanh — SCR-008
- **Kho nhận:** về semantic vẫn là một selector; Phase 1 chỉ khóa ở kho mặc định. Vì vậy dùng `VSelect` disabled với giá trị `Kho mặc định`, không đổi thành text/card chỉ vì hiện tại không cho thay đổi.
- **Ngày nhận:** mặc định ngày hiện hành; UI không cho chọn ngày trước ngày hiện hành của tenant và server phải kiểm lại rule này khi submit.
- **Căn cứ giao nhận:** đây là artifact/bằng chứng, không phải mô tả. Dùng `VFileDropZone` bắt buộc; text field chỉ dành cho `Ghi chú`.

## 2. Chọn Product/UOM — SCR-009
- Search Product nằm trực tiếp trên `Hàng thực nhận`.
- Product chỉ có một UOM hợp lệ: dùng UOM đó ngay và mở thẳng `SCR-084`.
- Product có nhiều UOM hợp lệ: hiển thị toàn bộ UOM dạng lựa chọn trực tiếp, bắt buộc chọn một; không giấu trong dropdown tạo thêm một tap.
- Khi Product+UOM đã xác định, user đã hoàn thành mental task “chọn mục hàng”; UI mở thẳng one-item editor `SCR-084`. `Xong` mới quay lại list.

## 3. LOT collection — SCR-084
Nhãn `Thêm lô` có thể bị đọc như một completion action của lô hiện tại. Chốt đổi thành **`Thêm lô khác`** và đặt ở cấp collection. Nó chỉ có nghĩa append một LOT mới. **`Xong` là CTA duy nhất hoàn tất mục hàng.**

## 4. Similar-root-cause correction
BJ06 wrong-LOT trước đó cũng có nguy cơ dùng text như một surrogate cho evidence. v1.3.5 chuyển sang:
- reason code hiển thị trực tiếp;
- `Khác` cần mô tả;
- ít nhất một ảnh nhãn lô thực nhận;
- approver thấy chênh lệch lô, lý do, evidence và maker.

BJ05/BJ07 normal handover không bị làm nặng bởi upload/chữ ký tự phát: server tạo immutable evidence từ dữ liệu operation, user chỉ xác nhận việc bàn giao vật lý đã xảy ra; scan LOT là hỗ trợ, không bắt buộc Phase 1.

## 5. Guardrail để không lặp lại
- `LOCKED_CONTROL_FIDELITY`: field là selector thì khi bị khóa vẫn giữ selector disabled.
- `VISIBLE_MANDATORY_CHOICE`: tập lựa chọn nhỏ + bắt buộc + đủ chỗ mobile thì hiển thị trực tiếp.
- `EVIDENCE_INPUT_MATCHES_ARTIFACT`: file/ảnh dùng upload; lý do/mô tả dùng text.
- `DECISIVE_SELECTION_ADVANCES`: lựa chọn đã đủ để bắt đầu task kế tiếp thì chuyển thẳng, không bắt tap lại.
- `APPEND_IS_NOT_COMPLETE`: action thêm phần tử phải được đặt tên/position như append, không giống completion.
- `TEMPORAL_GUARD_IN_CONTROL`: ngày không hợp lệ phải bị chặn ngay trong control và recheck server-side.
