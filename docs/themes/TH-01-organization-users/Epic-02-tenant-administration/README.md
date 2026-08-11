# EP-02 — Quản lý tổ chức & lịch sử quản trị

**Master spec:** [Theme-1-organization-users.md](../Theme-1-organization-users.md) §4.3

## Mục tiêu epic

Quản lý hồ sơ tổ chức, Legal Profile, lifecycle Tenant cấp nền tảng, ownership privileged và lịch sử quản trị.

## Phạm vi

| Nhóm | Nội dung |
| ---- | -------- |
| Tenant App | Xem/cập nhật hồ sơ; Legal Profile; lịch sử quản trị Tenant |
| Platform Admin | Xem Tenant/thành viên; transfer Owner; suspend/restore; Platform Audit |

**Ngoài phạm vi:** Tenant-facing transfer/close (Post-MVP); restore closed Tenant; chỉnh timezone/base currency.

## User stories

| US | Tên | Spec |
| -- | --- | ---- |
| US-01 | Xem hồ sơ tổ chức | [US-01.md](US-01.md) |
| US-02 | Cập nhật hồ sơ tổ chức | [US-02.md](US-02.md) |
| US-03 | Tạo hoặc cập nhật hồ sơ pháp lý | [US-03.md](US-03.md) |
| US-04 | Chuyển quyền sở hữu tổ chức | [US-04.md](US-04.md) |
| US-05 | Đóng tổ chức | [US-05.md](US-05.md) |
| US-06 | Tạm ngừng hoặc khôi phục Tenant | [US-06.md](US-06.md) |
| US-07 | Xem lịch sử quản trị Tenant | [US-07.md](US-07.md) |
| US-08 | Xem Tenant và thành viên ở cấp nền tảng | [US-08.md](US-08.md) |
| US-09 | Thay đổi Owner ở cấp nền tảng | [US-09.md](US-09.md) |
| US-10 | Xem nhật ký quản trị nền tảng | [US-10.md](US-10.md) |

## Cấu trúc đặc tả

Mỗi `US-{nn}.md` gồm 9 section: Business Context, FR, BR, EC, Design Reference, Data/API, **Scenarios**, AC & OQ.

UI Contract và Screen Groups nằm trong [Theme-1-organization-users.md](../Theme-1-organization-users.md) §5; US chỉ giữ link Design Reference tới SG tương ứng.
