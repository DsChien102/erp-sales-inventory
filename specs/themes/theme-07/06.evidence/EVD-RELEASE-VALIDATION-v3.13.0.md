---
id: EVD-RELEASE-VALIDATION-v3.13.0
type: release-evidence
theme: theme-07
title: "Kiểm định candidate Design/HTML v3.13.0"
owner: QA/HARNESS
status: READY_FOR_REVIEW
version: v3.13.0
parent: v3.12.0
---
# EVD — Kiểm định candidate v3.13.0

## 1. Kết luận

**`READY_FOR_REVIEW` cho package Design/HTML v3.13.0.**

Không gọi bản này là `RELEASE_READY`: chưa có production implementation, integration E2E và bằng chứng accessibility trên ứng dụng production.

- BLOCKER: **0**
- HIGH: **0**
- MEDIUM: **0**
- LOW: tên/ID cũ còn tồn tại trong changelog, QA lịch sử và migration alias để phục vụ audit; chúng không còn là nguồn hiện hành.

## 2. Gate

| Gate | Cách kiểm | Trạng thái | Bằng chứng |
|---|---|---|---|
| Parent / impact set | Diff v3.12.0 → v3.13.0 | PASS | `EVD-PACKAGE-DIFF-v3.13.0.md/.json` |
| Bảo toàn semantic | So sánh byte + review 4 UC | PASS | Knowledge/Domain/Technical Contract không đổi; 4 UC chỉ đổi mapping UI |
| Figma Design System | Đọc trực tiếp component + variable trong Figma | PASS | `design-system-profile.md`, `design/EVD-VALUATION-DESIGN-PARITY-v3.13.0.md` |
| Screen/Harness parity | UIF + Screen Registry + Slice | PASS | BJ03 = 4, BJ13 = 4, BJ14 = 3 màn active |
| Runtime toàn Theme | Browser smoke | PASS | **86** route renders, **0** lỗi |
| Tương tác valuation | E2E browser | PASS | **24/24** |
| Mobile/visual | 402×874, edge, overflow, touch target, Bottom Sheet | PASS | **16/16** + contact sheet |
| Recovery / red-team | source thay đổi, input công bố thay đổi, validation, retired route | PASS | **7/7** |
| Link / registry | Static validation | PASS | **1.442** relative links, **0** gãy; package gate **34/34** |
| Archive / checksum | Freeze → checksum → CRC → giải nén đối chiếu | PASS | thực hiện ở bước đóng gói cuối; không sửa candidate sau freeze |

## 3. Review nghiệp vụ độc lập — PASS

Có thể tái dựng rõ chuỗi:

`BJ02 nhận hàng → BJ03 xác lập giá trị nhập ban đầu → BJ13 điều chỉnh giá trị khi có căn cứ mới → BJ14 tính và công bố giá vốn`.

- Nhập nhanh không phụ thuộc Theme 10 để hoàn thành BJ03.
- Chênh lệch nguồn thương mại của nhận theo chứng từ không bị Theme 7 tự lựa chọn giá để bỏ qua.
- BJ03 không tạo giá vốn chính thức.
- BJ13 ghi điều chỉnh tăng/giảm; không dùng để che lỗi nhập liệu.
- BJ14 là nơi duy nhất tính/công bố giá vốn chính thức; phương pháp lấy từ chính sách tenant.

## 4. Mô phỏng bàn giao Design / FE / QA — PASS

Đã kiểm các tuyến đại diện:

1. Nhập nhanh thiếu căn cứ → thêm căn cứ giá trực tiếp → rà soát → xác lập giá trị.
2. Nhận theo chứng từ có chênh lệch nguồn thương mại → hiển thị vấn đề và hướng xử lý; không có lựa chọn ghi đè nguồn.
3. Điều chỉnh giảm giá trị → nguồn/phạm vi/phân bổ → rà soát → kết quả.
4. Công việc cần cập nhật giá vốn → tính/rà soát → Bottom Sheet xác nhận công bố → kết quả.

Design, FE và QA có thể lần theo `Screen → Action → UC/BC` mà không phải suy đoán thêm màn trung gian.

## 5. Red-team — PASS

- Căn cứ giá trực tiếp thiếu dữ liệu không được ghi.
- Control mới có accessible name và touch target tối thiểu 44px.
- Nguồn BJ03 thay đổi sau khi rà soát → `SOURCE_CHANGED`; không ghi snapshot cũ.
- Nguồn BJ13 thay đổi → không ghi điều chỉnh cũ.
- Input BJ14 thay đổi trước công bố → `INPUT_CHANGED`; không công bố kết quả cũ.
- Màn retired không còn active route.

## 6. Giới hạn bằng chứng

- Figma là authority cho Design System; v3.13.0 không ghi ngược product screen vào Figma.
- HTML là prototype/verification artifact, không phải ứng dụng production.
- Transaction/outbox/backend integration và production E2E nằm ngoài bằng chứng của version này.
