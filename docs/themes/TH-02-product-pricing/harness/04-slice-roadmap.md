# TH-02 — Slice roadmap (v3)

Thứ tự implement vertical slice. Lane status: `todo` | `in_progress` | `done` | `blocked` | `n/a`.

**Slice done** = Contract + BE + FE + E2E đều `done` (hoặc `n/a`). **Prerequisite chỉ bind lane E2E** — không block FE fake / BE handler unit test.

Foundation MVP ưu tiên Epic 02 (guided create) → Epic 01 (discovery/control center) → Epic 04–07. Epic 03 (custom fields) và Growth modes (Advanced stock, Costing base price) có thể sau.

| # | Slice | Type | Contract | BE | FE | E2E | Parallel group | E2E blocked by |
| - | ----- | ---- | -------- | -- | -- | --- | -------------- | -------------- |
| 1 | [EPIC-02/US-01](../EPIC-02-guided-creation/US-01/) — Guided create (nhận diện, dup, UOM, khởi tạo) | write | todo | todo | todo | todo | — | — |
| 2 | [EPIC-02/US-02](../EPIC-02-guided-creation/US-02/) — Dữ liệu vận hành ban đầu (tồn, base price, giá) | write | todo | todo | todo | todo | A | US-01 |
| 3 | [EPIC-02/US-03](../EPIC-02-guided-creation/US-03/) — Hoàn tất + readiness checklist | write | todo | todo | todo | todo | A | US-01 |
| 4 | [EPIC-01/US-01](../EPIC-01-discovery-readiness/US-01/) — Tìm kiếm, lọc, danh sách + readiness chip | read | todo | todo | todo | todo | B | US-01 (data) |
| 5 | [EPIC-01/US-02](../EPIC-01-discovery-readiness/US-02/) — Product Control Center | read | todo | todo | todo | todo | B | US-01 |
| 6 | [EPIC-04/US-01](../EPIC-04-units/US-01/) — Đơn vị cơ sở | write | todo | todo | todo | todo | C | US-01 |
| 7 | [EPIC-04/US-02](../EPIC-04-units/US-02/) — Đơn vị quy đổi | write | todo | todo | todo | todo | C | US-01 |
| 8 | [EPIC-05/US-02](../EPIC-05-stock/US-02/) — Basic stock (Foundation) | write | todo | todo | todo | todo | D | US-01 |
| 9 | [EPIC-06/US-01](../EPIC-06-pricing/US-01/) — Manual base price | write | todo | todo | todo | todo | E | US-01 |
| 10 | [EPIC-06/US-02](../EPIC-06-pricing/US-02/) — Store Price Rule | write | todo | todo | todo | todo | E | — |
| 11 | [EPIC-06/US-03](../EPIC-06-pricing/US-03/) — Product Unit Price Band | write | todo | todo | todo | todo | F | US-01, US-02 (UOM) |
| 12 | [EPIC-07/US-01](../EPIC-07-lifecycle/US-01/) — Bảo trì hồ sơ | write | todo | todo | todo | todo | G | US-01 |
| 13 | [EPIC-07/US-02](../EPIC-07-lifecycle/US-02/) — Ngừng KD / KD lại | write | todo | todo | todo | todo | G | US-01 |
| 14 | [EPIC-07/US-03](../EPIC-07-lifecycle/US-03/) — Xóa mềm / khôi phục | write | todo | todo | todo | todo | H | US-01 |
| 15 | [EPIC-04/US-03](../EPIC-04-units/US-03/) — Đổi đơn vị cơ sở | write | todo | todo | todo | todo | I | US-02 (UOM) |
| 16 | [EPIC-03/US-01](../EPIC-03-industry-fields/US-01/) — Khởi tạo custom fields | write | todo | todo | n/a | todo | J | onboarding |
| 17 | [EPIC-03/US-02](../EPIC-03-industry-fields/US-02/) — Giá trị custom fields trên SP | write | todo | todo | todo | todo | J | US-01 |
| 18 | [EPIC-05/US-03](../EPIC-05-stock/US-03/) — Advanced stock read (Growth) | read | todo | todo | todo | blocked | K | inventory module |
| 19 | [EPIC-06/US-01](../EPIC-06-pricing/US-01/) FR-03 — Costing base price read (Growth) | read | todo | todo | todo | blocked | K | costing module |
| 20 | [EPIC-07/US-04](../EPIC-07-lifecycle/US-04/) — Change history | read | todo | todo | todo | todo | L | US-01 |

### Parallel groups

| Group | Slices | Ghi chú |
| ----- | ------ | ------- |
| A | EPIC-02 US-02, US-03 | Hoàn thiện guided creation flow |
| B | EPIC-01 US-01, US-02 | Discovery + control center |
| C | EPIC-04 US-01, US-02 | UOM foundation |
| D | EPIC-05 US-02 | Basic stock only (Foundation) |
| E | EPIC-06 US-01 manual, US-02 store rule | Pricing foundation |
| F | EPIC-06 US-03 | Price band per UOM |
| G | EPIC-07 US-01, US-02 | Profile + status |
| H | EPIC-07 US-03 | Soft delete |
| I | EPIC-04 US-03 | Change base unit — phức tạp |
| J | EPIC-03 | Custom fields — sau core SP |
| K | Growth integrations | Blocked until inventory/costing |
| L | Change history | Sau core mutations |

## Definition of Done (per lane)

### CONTRACT

- [ ] Commands/Queries/DTOs exported trong `modules/catalog/application/`
- [ ] Section trong [07-api-contracts.md](07-api-contracts.md) + fake scenario table
- [ ] BE + FE sign-off (review PR)

### BE

- [ ] Domain, handler, validator, gateway, RPC migration
- [ ] Handler annotated `@CommandHandlerFor` / `@QueryHandlerFor`
- [ ] `melos run codegen` + commit generated `*.g.dart`
- [ ] Handler test `scn_*` pass

### FE

- [ ] UI wired `ICatalogModule` / `IModuleMediator`
- [ ] Widget test `wgt_*` với `FakeCatalogModule` (khi FR có SCN)
- [ ] Product Control Center: contextual actions, readiness checklist

### E2E

- [ ] ERP DI real module; integration test qua mediator
- [ ] `melos run test` + `./scripts/ci/verify_harness.sh` pass
- [ ] `cd apps/erp && flutter test` pass (khi slice có UI)

### Chung

- [ ] FR spec đã đọc (BR/EC/SCN)
- [ ] Traceability rows trong [05-traceability.md](05-traceability.md) cập nhật
- [ ] Page ≤ 500 dòng (`guard_presentation_size.sh`)

## Epic → module

| Epic | Owner module | Ghi chú |
| ---- | ------------ | ------- |
| EPIC-01..07 | catalog | Readiness, lifecycle, pricing, UOM, stock profile |
| Growth reads | catalog + inventory/costing gateways | Read-only cross-module |
