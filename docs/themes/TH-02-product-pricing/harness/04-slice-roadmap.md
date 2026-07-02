# TH-02 — Slice roadmap

Thứ tự implement vertical slice. Lane status: `todo` | `in_progress` | `done` | `blocked` | `n/a`.

**Slice done** = Contract + BE + FE + E2E đều `done` (hoặc `n/a`). **Prerequisite chỉ bind lane E2E** — không block FE fake / BE handler unit test.

| # | Slice | Type | Contract | BE | FE | E2E | Parallel group | E2E blocked by |
| - | ----- | ---- | -------- | -- | -- | --- | -------------- | -------------- |
| 1 | [EPIC-01-product/US-01](../EPIC-01-product/US-01/) — Ghi nhận sản phẩm mới | write | todo | todo | todo | todo | — | — |
| 2 | [EPIC-01-product/US-02](../EPIC-01-product/US-02/) — Tra cứu danh sách (FR-01, FR-02) | read | todo | todo | todo | todo | A | US-01 (data) |
| 3 | [EPIC-01-product/US-02](../EPIC-01-product/US-02/) — Xem chi tiết (FR-03) | read | todo | todo | todo | todo | A | US-01 |
| 4 | [EPIC-01-product/US-03](../EPIC-01-product/US-03/) — Chỉnh sửa hồ sơ / ảnh / tồn | write | todo | todo | todo | todo | B | US-01 |
| 5 | [EPIC-01-product/US-04](../EPIC-01-product/US-04/) — Trạng thái KD (ngừng / KD lại / xóa) | write | todo | todo | todo | todo | C | US-03 (detail) |
| 6 | [EPIC-01-product/US-05](../EPIC-01-product/US-05/) — Đơn vị đo lường & quy đổi | write | todo | todo | todo | todo | D | US-01 |
| 7 | [EPIC-02-pricing/US-01](../EPIC-02-pricing/US-01/) — Giá cấp cửa hàng | write | todo | todo | todo | todo | E | — |
| 8 | [EPIC-02-pricing/US-02](../EPIC-02-pricing/US-02/) — Giá cấp sản phẩm & theo UOM | write | todo | todo | todo | todo | F | US-01, US-05 (UOM) |

### Parallel groups

| Group | Slices | Ghi chú |
| ----- | ------ | ------- |
| A | US-02 search + list | FE fake sau CONTRACT; E2E cần US-01 data |
| B | US-03 edit | Profile / images / stock — có thể tách lane nhỏ hơn khi implement |
| C | US-04 status | Mirror Epic-02/US-01 partner status pattern |
| D | US-05 UOM | Phức tạp nhất Epic-01 — change base unit cuối |
| E | Epic-02/US-01 | Store pricing — không phụ thuộc SP data |
| F | Epic-02/US-02 | Product pricing — cần SP + UOM |

## Definition of Done (per lane)

### CONTRACT

- [ ] Commands/Queries/DTOs exported trong `modules/catalog/application/`
- [ ] Section trong [07-api-contracts.md](07-api-contracts.md) + fake scenario table
- [ ] BE + FE sign-off (review PR)

### BE

- [ ] Domain, handler, validator, gateway, RPC migration
- [ ] Handler annotated `@CommandHandlerFor` / `@QueryHandlerFor`; message `implements ICommand` / `IQuery`
- [ ] `melos run codegen` + commit `modules/catalog/infrastructure/.../generated/*.g.dart`
- [ ] Handler test `scn_*` pass

### FE

- [ ] UI + cubit wired `ICatalogModule` / `IModuleMediator`
- [ ] Widget test `wgt_*` với `FakeCatalogModule` scenario (khi FR có dialog/SCN)

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
| Epic-01 | catalog | Product lifecycle + UOM + basic stock |
| Epic-02 | catalog (+ costing read) | Pricing; giá vốn read-only từ costing |
