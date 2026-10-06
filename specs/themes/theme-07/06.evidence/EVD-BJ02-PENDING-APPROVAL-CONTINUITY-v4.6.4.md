# Bằng chứng BJ02 - liên tục trạng thái chờ phê duyệt - v4.6.4

**Kết quả: PASS**

Phạm vi thay đổi chỉ tập trung BJ02 và phần tích hợp tối thiểu vào Hub Kho.

- `SCR-010 / PENDING_APPROVAL`: thêm CTA chính **Về Kho**; Back cũng quay về Hub Kho, không quay lại editor của revision đã khóa.
- `Cần chú ý`: thêm **Nhận hàng chờ phê duyệt** và danh sách các lần nhận đang chờ xử lý.
- `SCR-011`: cho phép vào từ danh sách chờ duyệt và Back trở lại đúng danh sách.
- Fixture chờ duyệt dùng các dòng hàng đã hoàn tất; case mẫu có `Vượt chứng từ` để lý do phê duyệt nhất quán với dữ liệu hiển thị.

## Kiểm chứng

- Focused interaction/visual QA: **21/21 PASS**, 0 browser error.
- Toàn bộ 17 UIF runtime smoke: **85/85 PASS**, 0 failure.
- Mobile prototype static gate: **PASS**, 0 BLOCKER/HIGH.
- Current package validation: **23/23 PASS**.

## Giới hạn bằng chứng

Hub Kho candidate vẫn là bề mặt review/compare; bản Hub hiện hành vẫn là mặc định. Bằng chứng này không thay cho production authorization, integration hoặc E2E.
