# EP-01 — Quản lý danh sách, hồ sơ và lịch sử đối tác

**Master spec:** [Theme-3-partner.md](../Theme-3-partner.md) §5

## Mục tiêu epic

Bao phủ luồng người dùng từ tìm đối tác, tạo mới, xem/chỉnh sửa hồ sơ, quản lý người liên hệ, transform Cá nhân → Tổ chức và xem lịch sử làm việc.

## Phạm vi

| Nhóm | Nội dung |
| ---- | -------- |
| Danh sách | Tìm kiếm, lọc, xem danh sách Partner |
| Tạo mới | Tạo Person hoặc Organization |
| Cập nhật | Bổ sung/chỉnh sửa thông tin hiện tại |
| Hồ sơ | Xem chi tiết Person/Organization |
| Contact | Quản lý người liên hệ của Organization |
| Transform | Chuyển Person thành Organization |
| History | Xem lịch sử làm việc read-only |

**Ngoài phạm vi:** lifecycle status và soft delete → [EP-02](../Epic-02-partner-status/).

## User stories

| US | Tên | Spec |
| -- | --- | ---- |
| US-01 | Tìm kiếm và rà soát danh sách đối tác | [US-01.md](US-01.md) |
| US-02 | Ghi nhận đối tác mới | [US-02.md](US-02.md) |
| US-03 | Bổ sung và chỉnh sửa thông tin đối tác | [US-03.md](US-03.md) |
| US-04 | Kiểm tra hồ sơ đối tác | [US-04.md](US-04.md) |
| US-05 | Quản lý người liên hệ của tổ chức | [US-05.md](US-05.md) |
| US-06 | Chuyển cá nhân thành tổ chức | [US-06.md](US-06.md) |
| US-07 | Theo dõi lịch sử làm việc với đối tác | [US-07.md](US-07.md) |

## Cấu trúc đặc tả

Mỗi `US-{nn}.md` gồm 9 section: Business Context, FR, BR, EC, UI Contract, Design Contract, Data/API, **Scenarios**, AC & OQ.

FR specs cũ (`FR-*.md` trong thư mục US) đã archive — [_archive/fr-specs-legacy/](../_archive/fr-specs-legacy/).