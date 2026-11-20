# EP-02 — Quản lý trạng thái đối tác

**Master spec:** [Theme-3-partner.md](../Theme-3-partner.md) §6

## Mục tiêu epic

Lifecycle/status của Partner: ngừng hoạt động, kích hoạt lại và xóa mềm hồ sơ tạo nhầm.

## Phạm vi

| Nhóm | Nội dung |
| ---- | -------- |
| Ngừng hoạt động | Active → Inactive |
| Kích hoạt lại | Inactive → Active |
| Xóa mềm | Active/Inactive → Deleted (nếu đủ điều kiện) |
| Audit | Ghi nhận người thao tác, thời điểm, lý do |

## User stories

| US | Tên | Spec |
| -- | --- | ---- |
| US-01 | Dừng sử dụng và sử dụng lại đối tác | [US-01.md](US-01.md) |
| US-02 | Loại bỏ hồ sơ đối tác tạo nhầm | [US-02.md](US-02.md) |

## Cấu trúc đặc tả

Mỗi `US-{nn}.md` gồm Business Context, FR, BR, EC, Design Reference, Data/API, **Scenarios**, AC & OQ.

UI Contract, Low-fi wireframes và Visual Design nằm tập trung trong [Theme-3-partner.md](../Theme-3-partner.md) Appendix A / Screen Groups; US chỉ giữ link truy vết đến SG tương ứng.

FR specs cũ đã archive — [_archive/fr-specs-legacy/](../_archive/fr-specs-legacy/)
