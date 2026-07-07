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

Mỗi `US-{nn}.md` — scenarios (`SCN-01` …) thuộc trực tiếp US.

FR specs cũ đã archive — [_archive/fr-specs-legacy/](../_archive/fr-specs-legacy/)