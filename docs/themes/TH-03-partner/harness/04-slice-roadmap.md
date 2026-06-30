# TH-03 — Slice roadmap

Thứ tự implement vertical slice. Status: `todo` | `in_progress` | `done` | `blocked`.

| # | Slice | Type | Prerequisites | Status |
| - | ----- | ---- | ------------- | ------ |
| 1 | [Epic-01/US-02](../Epic-01-partner-profile/US-02/) — Ghi nhận đối tác mới | write | — | todo |
| 2 | [Epic-01/US-01](../Epic-01-partner-profile/US-01/) — Tìm kiếm danh sách | read | US-02 (data) | todo |
| 3 | [Epic-01/US-04](../Epic-01-partner-profile/US-04/) — Kiểm tra hồ sơ | read | US-02 | done |
| 4 | [Epic-01/US-03](../Epic-01-partner-profile/US-03/) — Bổ sung/chỉnh sửa | write | US-02 | in_progress |
| 5 | [Epic-02/US-01](../Epic-02-partner-status/US-01/) — Dừng sử dụng / kích hoạt lại | write | US-04 | todo |
| 6 | [Epic-02/US-02](../Epic-02-partner-status/US-02/) — Loại bỏ hồ sơ tạo nhầm | write | US-04 | todo |
| 7 | [Epic-03/US-01](../Epic-03-partner-transaction-history/US-01/) — Lịch sử giao dịch | read cross-module | sales/inventory/accounting publish events | **blocked** |

## Definition of Done (một FR slice)

- [ ] Product FR spec đã đọc (BR/EC/SCN)
- [ ] Widget manifest khớp FR (dialog/section đã tách file)
- [ ] Page ≤ 500 dòng (`guard_presentation_size.sh` pass)
- [ ] Widget test cho dialog xác nhận (khi FR có SCN dialog)
- [ ] Traceability row trong [05-traceability.md](05-traceability.md) cập nhật khi slice `in_progress`
- [ ] Code + test theo layer rules
- [ ] `melos run test` + `./scripts/ci/verify_harness.sh` pass
- [ ] `cd apps/erp && flutter test` pass (khi slice có UI)

## Epic → module (planned)

| Epic/US | Owner module | Ghi chú |
| ------- | ------------ | ------- |
| Epic-01 | partner | Core profile CRUD |
| Epic-02 | partner | Status mutations |
| Epic-03 | partner (read) + sales/inventory/accounting (publish) | Inbox projection |
