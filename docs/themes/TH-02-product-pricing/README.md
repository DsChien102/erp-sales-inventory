# TH-02: Sản phẩm & giá bán

**Trạng thái deliver:** `in_progress`

Master data sản phẩm, SKU, đơn vị tính, barcode và giá bán — nền tảng cho bán hàng (TH-04), kho (TH-06) và báo cáo.

## Module tham gia

| Module | Vai trò | Package |
| ------ | ------- | ------- |
| catalog | **Owner** (in_progress) | `modules/catalog/` |
| inventory | Supporting — liên kết tồn kho | `modules/inventory/` |
| costing | Supporting — tham chiếu giá vốn | `modules/costing/` |
| iam | Supporting — access | `modules/iam/` |

## Tài liệu

| Nhóm | File |
| ---- | ---- |
| Business scope | [01-business-scope.md](01-business-scope.md) |
| Module map | [02-module-map.md](02-module-map.md) |
| Platform architecture | [docs/architecture/](../../architecture/README.md) |

## Epic index

| Epic | Folder | US | FR | Status |
| ---- | ------ | -- | -- | ------ |
| Epic 01 — Quản lý vòng đời sản phẩm | [EPIC-01-product/](EPIC-01-product/) | US-01..05 | 3+3+3+3+5 | in_progress |
| Epic 02 — Giá niêm yết và giá sàn | [EPIC-02-pricing/](EPIC-02-pricing/) | US-01..02 | 2+3 | in_progress |

## Harness

| File | Mô tả |
| ---- | ----- |
| [harness/00-agent-ritual.md](harness/00-agent-ritual.md) | Thứ tự đọc khi implement slice |
| [harness/01-domain-model.md](harness/01-domain-model.md) | Aggregate, commands, events |
| [harness/02-module-map.md](harness/02-module-map.md) | Owner/supporting, permissions |
| [harness/03-architecture-and-flows.md](harness/03-architecture-and-flows.md) | Flows, RPC |
| [harness/04-slice-roadmap.md](harness/04-slice-roadmap.md) | Slice order, lane status |
| [harness/05-traceability.md](harness/05-traceability.md) | FR → Role → test id |
| [harness/06-harness-notes.md](harness/06-harness-notes.md) | Guards, flywheel |
| [harness/07-api-contracts.md](harness/07-api-contracts.md) | FE↔BE contracts + fake scenarios |

## Quy ước ID (khi có Epic tree)

```text
TH-02 / Epic-{nn} / US-{nn} / FR-{nn}
Test id: scn_e01_u02_fr06_01 (BE), wgt_e02_u01_fr03_01 (FE), e2e_e01_u02_fr06_01 (E2E)
```
