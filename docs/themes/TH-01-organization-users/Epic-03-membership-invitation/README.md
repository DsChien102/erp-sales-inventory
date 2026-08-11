# EP-03 — Thành viên & lời mời

**Master spec:** [Theme-1-organization-users.md](../Theme-1-organization-users.md) §4.4

## Mục tiêu epic

Quản lý danh sách thành viên, Tenant Invitation và Membership lifecycle.

## Phạm vi

| Nhóm | Nội dung |
| ---- | -------- |
| Invitation | Mời email, resend, revoke, accept/decline |
| Membership | Xem, deactivate/reactivate, remove; sole-Owner protection |

**Ngoài phạm vi:** Platform User activation invitation; hard delete; self-service leave (chưa có dedicated MVP visual).

## User stories

| US | Tên | Spec |
| -- | --- | ---- |
| US-01 | Xem và tìm kiếm thành viên, lời mời | [US-01.md](US-01.md) |
| US-02 | Mời người dùng tham gia Tenant | [US-02.md](US-02.md) |
| US-03 | Chấp nhận hoặc từ chối lời mời | [US-03.md](US-03.md) |
| US-04 | Gửi lại hoặc thu hồi lời mời | [US-04.md](US-04.md) |
| US-05 | Xem và thay đổi trạng thái thành viên | [US-05.md](US-05.md) |
| US-06 | Loại thành viên khỏi tổ chức | [US-06.md](US-06.md) |

## Cấu trúc đặc tả

Mỗi `US-{nn}.md` gồm 9 section: Business Context, FR, BR, EC, Design Reference, Data/API, **Scenarios**, AC & OQ.

UI Contract và Screen Groups nằm trong [Theme-1-organization-users.md](../Theme-1-organization-users.md) §5; US chỉ giữ link Design Reference tới SG tương ứng.
