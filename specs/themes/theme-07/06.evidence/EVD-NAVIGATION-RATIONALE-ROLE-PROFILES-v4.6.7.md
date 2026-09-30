# EVD — Navigation rationale & Role Profiles v4.6.7

**Kết quả: PASS — 6/6 checks.**

## Phạm vi

- Bổ sung lập luận thiết kế đã chốt vào `PAT-NAV`.
- Chính thức hóa bốn Navigation Profile đang được prototype mô phỏng: `FULL`, `WAREHOUSE`, `ACCOUNTING`, `SALES`.
- Cập nhật `SCR-090` để tham chiếu profile và tách rõ profile khỏi permission.

## Quy tắc giữ nguyên

- Không thay đổi BJ, UC, UIF hoặc quy tắc nghiệp vụ.
- Không thêm permission mới.
- Không sửa logic hoặc HTML prototype.
- Không tự định nghĩa cách hợp nhất nhiều Navigation Profile.

## Kiểm tra

- PASS — PAT-NAV có phần lập luận thiết kế đã chốt
- PASS — PAT-NAV tách quyền, trách nhiệm và mức độ nổi bật
- PASS — PAT-NAV formalize bốn Navigation Profile
- PASS — PAT-NAV không tự định nghĩa cách gộp nhiều profile
- PASS — SCR-090 tham chiếu Navigation Profile
- PASS — HTML role profile không thay đổi
