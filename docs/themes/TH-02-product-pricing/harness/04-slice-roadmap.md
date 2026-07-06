# TH-02 — Slice roadmap (v3)

Thứ tự implement vertical slice. Lane status: `todo` | `in_progress` | `done` | `blocked` | `pending` | `n/a` | `out_of_scope`.

**Slice done** = Contract + BE + FE + E2E đều `done` (hoặc `n/a`). **Prerequisite chỉ bind lane E2E** — không block FE fake / BE handler unit test.

US/FR `pending` hoặc `out_of_scope` → không mở BE/FE/E2E (xem [00-agent-ritual.md](00-agent-ritual.md)).

Foundation MVP: Epic 02 (guided create) → Epic 01 (discovery/control center) → Epic 04–07 core → Epic 03 (thông tin bổ sung). Growth modes (Advanced stock, Costing base price) = **pending** module ngoài.


| #   | Slice                                                                                                     | Type  | Contract | BE      | FE      | E2E     | Parallel group | E2E blocked by / notes                                        |
| --- | --------------------------------------------------------------------------------------------------------- | ----- | -------- | ------- | ------- | ------- | -------------- | ------------------------------------------------------------- |
| 1   | [EPIC-02/US-01](../EPIC-02-guided-creation/US-01/) — Guided create (nhận diện, dup, UOM, khởi tạo)        | write | done     | done    | done    | done    | —              | —                                                             |
| 2   | [EPIC-02/US-02](../EPIC-02-guided-creation/US-02/) — Dữ liệu vận hành ban đầu (tồn, base price, giá)      | write | done     | done    | done    | done    | A              | US-01                                                         |
| 3   | [EPIC-02/US-03](../EPIC-02-guided-creation/US-03/) — Hoàn tất + readiness **summary**                     | write | done     | done    | done    | todo    | A              | US-01                                                         |
| 4   | [EPIC-01/US-01](../EPIC-01-discovery-readiness/US-01/) — Tìm kiếm, lọc, danh sách + readiness chip        | read  | done     | done    | done    | done    | B              | US-01 (data)                                                  |
| 5   | [EPIC-01/US-02](../EPIC-01-discovery-readiness/US-02/) — Product Control Center                           | read  | done     | done    | done    | done    | B              | US-01; **FR-04 checklist pending** (làm FR-01..03, FR-05..06) |
| 6   | [EPIC-04/US-01](../EPIC-04-units/US-01/) — Đơn vị cơ sở                                                   | write | done     | done    | done    | done    | C              | US-01                                                         |
| 7   | [EPIC-04/US-02](../EPIC-04-units/US-02/) — Đơn vị quy đổi                                                 | write | done     | done    | done    | done    | C              | US-01; **FR-02 unit roles pending**                           |
| 8   | [EPIC-05/US-01](../EPIC-05-stock/US-01/) + [US-02](../EPIC-05-stock/US-02/) — Stock profile + Basic stock | write | done     | done    | done    | done    | D              | US-01                                                         |
| 9   | [EPIC-06/US-01](../EPIC-06-pricing/US-01/) — Manual base price                                            | write | done     | done    | done    | done    | E              | US-01                                                         |
| 10  | [EPIC-06/US-02](../EPIC-06-pricing/US-02/) — Store Price Rule                                             | write | todo     | todo    | todo    | todo    | E              | —                                                             |
| 11  | [EPIC-06/US-03](../EPIC-06-pricing/US-03/) — Product Unit Price Band                                      | write | todo     | todo    | todo    | todo    | F              | US-01, US-02 (UOM)                                            |
| 12  | [EPIC-07/US-01](../EPIC-07-lifecycle/US-01/) — Bảo trì hồ sơ                                              | write | todo     | todo    | todo    | todo    | G              | US-01                                                         |
| 13  | [EPIC-07/US-02](../EPIC-07-lifecycle/US-02/) — Ngừng KD / KD lại                                          | write | todo     | todo    | todo    | todo    | G              | US-01                                                         |
| 14  | [EPIC-07/US-03](../EPIC-07-lifecycle/US-03/) — Xóa mềm / khôi phục                                        | write | todo     | todo    | todo    | todo    | H              | US-01                                                         |
| 15  | [EPIC-04/US-03](../EPIC-04-units/US-03/) — Đổi đơn vị cơ sở                                               | write | n/a      | n/a     | n/a     | n/a     | —              | **out_of_scope**                                              |
| 16  | [EPIC-03/US-01](../EPIC-03-industry-fields/US-01/) — Cấu hình nhóm & trường (FR-01..06)                   | write | todo     | todo    | todo    | todo    | J              | onboarding template optional                                  |
| 17  | [EPIC-03/US-02](../EPIC-03-industry-fields/US-02/) — Giá trị thông tin bổ sung trên SP                    | write | todo     | todo    | todo    | todo    | J              | US-01 (config)                                                |
| 18  | [EPIC-03/US-03](../EPIC-03-industry-fields/US-03/) — Search / filter / display on list                    | read  | todo     | todo    | todo    | todo    | J              | US-01, US-02                                                  |
| 19  | [EPIC-06/US-04](../EPIC-06-pricing/US-04/) — Snapshot khung giá cho Sales/Promotions                      | read  | todo     | todo    | n/a     | todo    | F              | US-03 (price band)                                            |
| 20  | [EPIC-07/US-04](../EPIC-07-lifecycle/US-04/) — Change history                                             | read  | todo     | todo    | todo    | todo    | L              | US-01                                                         |
| 21  | [EPIC-05/US-03](../EPIC-05-stock/US-03/) — Advanced stock read                                            | read  | pending  | pending | pending | pending | K              | **pending** (inventory module)                                |
| 22  | [EPIC-05/US-04](../EPIC-05-stock/US-04/) — Basic → Advanced switch                                        | write | pending  | pending | pending | pending | K              | **pending**                                                   |
| 23  | [EPIC-06/US-01](../EPIC-06-pricing/US-01/) FR-03 — Costing base price read                                | read  | pending  | pending | pending | pending | K              | **pending** (costing module)                                  |
| 24  | [EPIC-04/US-04](../EPIC-04-units/US-04/) — Cung cấp UOM cho module khác                                   | read  | pending  | pending | pending | pending | —              | **pending**                                                   |




### Parallel groups


| Group | Slices                                 | Ghi chú                                            |
| ----- | -------------------------------------- | -------------------------------------------------- |
| A     | EPIC-02 US-02, US-03                   | Hoàn thiện guided creation flow                    |
| B     | EPIC-01 US-01, US-02                   | Discovery + control center (không FR-04 checklist) |
| C     | EPIC-04 US-01, US-02                   | UOM foundation (không FR-02 roles)                 |
| D     | EPIC-05 US-01, US-02                   | Stock profile + basic stock                        |
| E     | EPIC-06 US-01 manual, US-02 store rule | Pricing foundation                                 |
| F     | EPIC-06 US-03, US-04                   | Price band + snapshot consumers                    |
| G     | EPIC-07 US-01, US-02                   | Profile + status                                   |
| H     | EPIC-07 US-03                          | Soft delete                                        |
| J     | EPIC-03 US-01..03                      | Thông tin bổ sung — sau core SP                    |
| K     | Growth integrations                    | **pending** until inventory/costing                |
| L     | Change history                         | Sau core mutations                                 |




## Definition of Done (per lane)



### CONTRACT

- [ ] Commands/Queries/DTOs exported trong `modules/catalog/application/`
- [ ] Section trong [07-api-contracts.md](07-api-contracts.md) + fake scenario table
- [ ] BE + FE sign-off (review PR)



### BE

- [ ] Domain, handler, validator, gateway, RPC migration (draft SQL trong `_drafts/`)
- [ ] Handler annotated `@CommandHandlerFor` / `@QueryHandlerFor`
- [ ] `melos run codegen` + commit generated `*.g.dart`
- [ ] Handler test `scn_*` pass



### FE

- [ ] UI wired `ICatalogModule` / `IModuleMediator`
- [ ] Widget test `wgt_*` với `FakeCatalogModule` (khi FR có SCN)
- [ ] Product Control Center: contextual actions, custom field group cards, readinessSummary



### E2E

- [ ] ERP DI real module; integration test qua mediator
- [ ] `melos run test` + `./scripts/ci/verify_harness.sh` pass
- [ ] `cd apps/erp && flutter test` pass (khi slice có UI)



### Chung

- [ ] FR spec đã đọc (BR/EC/SCN); bỏ qua FR `pending` / `out_of_scope`
- [ ] Traceability rows trong [05-traceability.md](05-traceability.md) cập nhật
- [ ] Page ≤ 500 dòng (`guard_presentation_size.sh`)



## Epic → module


| Epic         | Owner module                         | Ghi chú                                                              |
| ------------ | ------------------------------------ | -------------------------------------------------------------------- |
| EPIC-01..07  | catalog                              | Readiness, lifecycle, pricing, UOM, stock profile, thông tin bổ sung |
| Growth reads | catalog + inventory/costing gateways | Read-only; **pending**                                               |


