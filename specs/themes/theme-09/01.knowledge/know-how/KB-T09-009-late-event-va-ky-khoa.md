# KB-T09-009 — Late event và kỳ đã khóa

## Trả lời ngắn
Late event là dữ liệu đúng nhưng đến sau thời điểm kỳ mong muốn đã khóa. Hệ thống phải bảo toàn cả ngày gốc và kỳ thực tế ghi nhận.

## Ví dụ
Một điều chỉnh giá vốn có ngày hiệu lực 31/08 nhưng Theme 7 chỉ final ngày 05/09, trong khi kỳ tháng 8 đã khóa.

## Hướng Phase 1 đề xuất
1. Không tự ghi ngược tháng 8.
2. Trả `PERIOD_LOCKED` hoặc mở work item.
3. Người có quyền chọn mở lại kỳ hoặc theo policy ghi kỳ hiện tại.
4. Entry vẫn lưu `source_effective_at=31/08` để audit.

## Chưa chốt
Mặc định “ghi kỳ mở gần nhất” hay “bắt buộc user quyết định” còn là OQ-06.
