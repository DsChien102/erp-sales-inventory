# TH-03 — Slice roadmap (v2)

Thứ tự implement vertical slice. Lane status: `todo` | `in_progress` | `done` | `blocked` | `n/a`.

**Reboot 2026-07-07:** Toàn bộ lane reset `todo` — code partner cũ đã gỡ; rebuild greenfield theo domain model v2.

**Slice done** = Contract + BE + FE + E2E đều `done` (hoặc `n/a`). **Prerequisite chỉ bind lane E2E** — FE fake và BE unit test chạy song song sau CONTRACT.

| # | Slice | Type | Contract | BE | FE | E2E | Parallel group | E2E blocked by |
| - | ----- | ---- | -------- | -- | -- | --- | -------------- | -------------- |
| S1 | [EP-01/US-02](../Epic-01-partner-profile/US-02.md) — Tạo Partner (Person + Organization) | write | done | done | done | done | — | — |
| S2 | [EP-01/US-01](../Epic-01-partner-profile/US-01.md) — Tìm kiếm danh sách | read | done | done | todo | todo | A | S1 (data) |
| S3 | [EP-01/US-04](../Epic-01-partner-profile/US-04.md) — Xem hồ sơ chi tiết | read | done | done | todo | todo | A | S1 |
| S4 | [EP-01/US-03](../Epic-01-partner-profile/US-03.md) — Cập nhật hồ sơ + role | write | done | done | todo | todo | A | S1 |
| S5 | [EP-01/US-05](../Epic-01-partner-profile/US-05.md) — Quản lý người liên hệ | write | done | done | todo | todo | B | S3 (org detail) |
| S6 | [EP-01/US-06](../Epic-01-partner-profile/US-06.md) — Transform Person→Organization | write | done | done | todo | todo | B | S3 |
| S7 | [EP-02/US-01](../Epic-02-partner-status/US-01.md) — Ngừng hoạt động / kích hoạt lại | write | done | done | todo | todo | C | S3 |
| S8 | [EP-02/US-02](../Epic-02-partner-status/US-02.md) — Xóa mềm | write | done | done | todo | todo | C | S3 |
| S9 | [EP-01/US-07](../Epic-01-partner-profile/US-07.md) — Lịch sử làm việc | read cross-module | done | done | todo | **blocked** | D | sales/inventory/accounting events |

### Parallel groups

| Group | Slices | Ghi chú |
| ----- | ------ | ------- |
| A | S2, S3, S4 | Sau S1 CONTRACT; E2E cần S1 data |
| B | S5, S6 | Cần Organization detail (S3) cho E2E |
| C | S7, S8 | Status lifecycle |
| D | S9 | BE+FE có thể làm trước; E2E blocked cross-module |

## Definition of Done (per lane)

### CONTRACT

- [x] Commands/Queries/DTOs exported trong `modules/partner/application/`
- [x] Section trong [07-api-contracts.md](07-api-contracts.md) + fake scenario table
- [ ] BE + FE sign-off (review PR)

### BE

- [x] Domain, handler, validator, gateway, draft SQL trong `_drafts/`
- [x] Handler annotated `@CommandHandlerFor` / `@QueryHandlerFor`
- [x] `melos run codegen` + commit `generated/*.g.dart`
- [x] Handler test `scn_*` pass

### FE

- [x] UI + cubit wired `IPartnerModule`
- [x] Widget test `wgt_*` với `FakePartnerModule` scenario

### E2E

- [x] ERP DI real module; integration / flutter test qua mediator
- [x] `melos run test` + `./scripts/ci/verify_harness.sh` pass
- [x] `cd apps/erp && flutter test` pass (partner + DI scope)

### Chung

- [x] US spec đã đọc (FR/BR/EC/SCN trong `US-{nn}.md`)
- [x] Traceability rows trong [05-traceability.md](05-traceability.md) cập nhật
- [x] Page ≤ 500 dòng

## Epic → module

| Epic/US | Owner module | Ghi chú |
| ------- | ------------ | ------- |
| EP-01 | partner | Profile CRUD, contact, transform, history read |
| EP-02 | partner | Status lifecycle + soft delete |
