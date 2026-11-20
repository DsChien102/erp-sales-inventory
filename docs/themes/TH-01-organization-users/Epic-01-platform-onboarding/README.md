# EP-01 — Quản lý người dùng nền tảng, khởi tạo & kích hoạt tổ chức

**Master spec:** [Theme-1-organization-users.md](../Theme-1-organization-users.md) §4.2

## Mục tiêu epic

Platform Admin quản lý Platform User, khởi tạo Tenant và Owner đầu tiên; Owner hoàn thiện readiness và kích hoạt tổ chức trong Tenant App.

## Phạm vi

| Nhóm | Nội dung |
| ---- | -------- |
| Platform User | Xem, tìm kiếm, lọc; lifecycle activation/password-reset/suspend/restore |
| Onboarding | Khởi tạo Tenant provisioning + Owner + role Chủ cửa hàng |
| Readiness | Hiển thị blocker/warning; kích hoạt khi đủ điều kiện |

**Ngoài phạm vi:** Tenant user tự tạo Tenant; đặt/xem password; auto-activate ngay sau khởi tạo.

## User stories

| US | Tên | Spec |
| -- | --- | ---- |
| US-01 | Xem và tra cứu Platform User | [US-01.md](US-01.md) |
| US-02 | Quản lý lifecycle của Platform User | [US-02.md](US-02.md) |
| US-03 | Khởi tạo Tenant và Owner đầu tiên | [US-03.md](US-03.md) |
| US-04 | Xem mức độ sẵn sàng của tổ chức | [US-04.md](US-04.md) |
| US-05 | Kích hoạt tổ chức | [US-05.md](US-05.md) |

## Cấu trúc đặc tả

Mỗi `US-{nn}.md` gồm 9 section: Business Context, FR, BR, EC, Design Reference, Data/API, **Scenarios**, AC & OQ.

UI Contract và Screen Groups nằm trong [Theme-1-organization-users.md](../Theme-1-organization-users.md) §5; US chỉ giữ link Design Reference tới SG tương ứng.
