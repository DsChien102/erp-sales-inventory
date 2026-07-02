# TH-03 — Slice roadmap

Thứ tự implement vertical slice. Lane status: `todo` | `in_progress` | `done` | `blocked` | `n/a`.

**Slice done** = Contract + BE + FE + E2E đều `done` (hoặc `n/a`). **Prerequisite chỉ bind lane E2E** — không block FE fake / BE handler unit test.

| # | Slice | Type | Contract | BE | FE | E2E | Parallel group | E2E blocked by |
| - | ----- | ---- | -------- | -- | -- | --- | -------------- | -------------- |
| 1 | [Epic-01/US-02](../Epic-01-partner-profile/US-02/) — Ghi nhận đối tác mới | write | done | done | done | done | — | — |
| 2 | [Epic-01/US-01](../Epic-01-partner-profile/US-01/) — Tìm kiếm danh sách | read | done | done | done | done | A | US-02 (data) |
| 3 | [Epic-01/US-04](../Epic-01-partner-profile/US-04/) — Kiểm tra hồ sơ | read | done | done | done | done | A | US-02 |
| 4 | [Epic-01/US-03](../Epic-01-partner-profile/US-03/) — Bổ sung/chỉnh sửa | write | done | done | done | done | A | US-02 |
| 5 | [Epic-02/US-01](../Epic-02-partner-status/US-01/) — Dừng sử dụng / kích hoạt lại | write | done | done | done | done | B | US-04 |
| 6 | [Epic-02/US-02](../Epic-02-partner-status/US-02/) — Loại bỏ hồ sơ tạo nhầm | write | done | done | done | done | C | US-04 |
| 7 | [Epic-03/US-01](../Epic-03-partner-transaction-history/US-01/) — Lịch sử giao dịch | read cross-module | todo | **blocked** | todo | **blocked** | D | sales/inventory/accounting events |

### Parallel groups

| Group | Slices | Ghi chú |
| ----- | ------ | ------- |
| A | US-01, US-03, US-04 | Retrofit — đã implement tuần tự; E2E cần US-02 data |
| B | Epic-02/US-01 | BE ∥ FE sau CONTRACT; E2E via `FakePartnerModule` page test |
| C | Epic-02/US-02 | Delete soft — done trên branch |
| D | Epic-03/US-01 | FE + CONTRACT không blocked; BE/E2E blocked |

## Definition of Done (per lane)

### CONTRACT

- [ ] Commands/Queries/DTOs exported trong `modules/<owner>/application/`
- [ ] Section trong [07-api-contracts.md](07-api-contracts.md) + fake scenario table
- [ ] BE + FE sign-off (review PR)

### BE

- [ ] Domain, handler, validator, gateway, RPC migration
- [ ] Handler annotated `@CommandHandlerFor` / `@QueryHandlerFor`; message `implements ICommand` / `IQuery`
- [ ] `melos run codegen` + commit `modules/partner/infrastructure/.../generated/*.g.dart`
- [ ] Handler test `scn_*` pass

### FE

- [ ] UI + cubit wired `IPartnerModule` / `IModuleMediator`
- [ ] Widget test `wgt_*` với `FakePartnerModule` scenario (khi FR có dialog/SCN)

### E2E

- [ ] ERP DI real module; integration / flutter test qua mediator thật
- [ ] `melos run test` + `./scripts/ci/verify_harness.sh` pass
- [ ] `cd apps/erp && flutter test` pass (khi slice có UI)

### Chung (mọi lane)

- [ ] Product FR spec đã đọc (BR/EC/SCN)
- [ ] Traceability rows trong [05-traceability.md](05-traceability.md) cập nhật theo Role
- [ ] Page ≤ 500 dòng (`guard_presentation_size.sh` pass)

## Epic → module

| Epic/US | Owner module | Ghi chú |
| ------- | ------------ | ------- |
| Epic-01 | partner | Core profile CRUD |
| Epic-02 | partner | Status mutations |
| Epic-03 | partner (read) + sales/inventory/accounting (publish) | Inbox projection |
