# EP-05 — Chọn tổ chức & kiểm soát Tenant context

**Master spec:** [Theme-1-organization-users.md](../Theme-1-organization-users.md) §4.6

## Mục tiêu epic

Xem Tenant accessible, chuyển Tenant đang làm việc và xử lý an toàn khi TenantContext không còn hợp lệ.

## Phạm vi

| Nhóm | Nội dung |
| ---- | -------- |
| Selector | Hiển thị Tenant + role; disabled khi suspended |
| Switch | Confirmation, loading, reload permission |
| Preference | Validate LastSelectedTenant; context invalidation |

**Ngoài phạm vi:** Tự tạo Tenant; TA-SG-08 độc lập; Store/Warehouse selector.

## User stories

| US | Tên | Spec |
| -- | --- | ---- |
| US-01 | Xem các Tenant có thể truy cập | [US-01.md](US-01.md) |
| US-02 | Chuyển sang Tenant khác | [US-02.md](US-02.md) |
| US-03 | Dùng lại Tenant gần nhất | [US-03.md](US-03.md) |
| US-04 | Xử lý TenantContext không còn hợp lệ | [US-04.md](US-04.md) |

## Cấu trúc đặc tả

Mỗi `US-{nn}.md` gồm 9 section: Business Context, FR, BR, EC, Design Reference, Data/API, **Scenarios**, AC & OQ.

UI Contract và Screen Groups nằm trong [Theme-1-organization-users.md](../Theme-1-organization-users.md) §5; US chỉ giữ link Design Reference tới SG tương ứng.
