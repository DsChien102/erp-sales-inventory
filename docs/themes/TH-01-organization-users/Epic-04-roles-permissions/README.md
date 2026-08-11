# EP-04 — Vai trò & quyền truy cập

**Master spec:** [Theme-1-organization-users.md](../Theme-1-organization-users.md) §4.5

## Mục tiêu epic

Xem bốn system role MVP, permission composition và thay role hiện hành của Membership.

## Phạm vi

| Nhóm | Nội dung |
| ---- | -------- |
| Catalog | Bốn role read-only: Chủ cửa hàng, Nhân viên bán hàng, Kế toán, Thủ kho |
| Assign | Đổi role từ member detail kèm permission delta |

**Ngoài phạm vi:** Custom role; Tenant edit role–permission; nhiều role/Membership; role OWNER; màn tự tra EffectivePermissions.

## User stories

| US | Tên | Spec |
| -- | --- | ---- |
| US-01 | Xem system-role catalog | [US-01.md](US-01.md) |
| US-02 | Xem permission của vai trò | [US-02.md](US-02.md) |
| US-03 | Thay đổi vai trò hiện hành của Membership | [US-03.md](US-03.md) |

## Cấu trúc đặc tả

Mỗi `US-{nn}.md` gồm 9 section: Business Context, FR, BR, EC, Design Reference, Data/API, **Scenarios**, AC & OQ.

UI Contract và Screen Groups nằm trong [Theme-1-organization-users.md](../Theme-1-organization-users.md) §5; US chỉ giữ link Design Reference tới SG tương ứng.
