# KB-T09-003 — Kỳ kế toán và khóa sổ

## Trả lời ngắn
Khóa kỳ bảo vệ lịch sử đã được kiểm tra khỏi thay đổi âm thầm. Đây là business control, không phải một cờ UI.

## Quy tắc đề xuất
- Kỳ `OPEN`: cho posting nếu các điều kiện khác hợp lệ.
- Kỳ `LOCKED`: chặn commit.
- Mở lại kỳ cần permission đặc quyền, lý do và audit.
- Reopen không xóa dấu vết lần khóa cũ.

## Late event
Nếu sự kiện tháng 8 tới sau khi tháng 8 đã khóa, hệ thống phải giữ ngày gốc và báo rõ lựa chọn xử lý; không lén chèn entry vào tháng 8.

## Điều kiện khóa cần chốt thêm
Đề xuất tối thiểu: không còn critical pending posting, unresolved reconciliation trọng yếu và user đã xem close summary.
