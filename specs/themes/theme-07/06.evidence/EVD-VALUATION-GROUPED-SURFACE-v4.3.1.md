# EVD — Valuation grouped surface v4.3.1

**Kết quả: PASS**

## Phát hiện

v4.3.0 làm các nhóm `Info Row` / `Key-value Row` trong BJ03, BJ13, BJ14 trở thành container trong suốt. Các hàng vẫn đúng dữ liệu nhưng mất ranh giới thị giác, trái với quy tắc Theme 7 đã khóa: **một nhóm dữ liệu đồng nhất = một surface boundary**.

## Sửa

- Khôi phục nền `surface-default`, viền và bo góc cho container chung.
- Không biến từng row thành card riêng.
- Hàng emphasis tiếp tục dùng semantic surface của Design System nhưng nằm trong cùng block.
- Vùng đối chiếu mở rộng cũng dùng một surface chung.
- Không thay đổi BJ, UC, UIF, Screen Contract, dữ liệu hay interaction.

## Kiểm chứng

- Grouped surface: 8/8 PASS.
- E2E: 29/29 PASS.
- Visual/runtime: 19/19 PASS.
- Full state: 54/54 PASS.
- Full Theme runtime: 86/86 PASS.
- Canonical links: 1.980 / 0 broken.
- Browser errors: 0.
