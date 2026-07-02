# TH-02: Sản phẩm & giá bán

**Trạng thái deliver:** `planned`

Master data sản phẩm, SKU, đơn vị tính, barcode và giá bán — nền tảng cho bán hàng (TH-04), kho (TH-06) và báo cáo.

## Module tham gia

| Module | Vai trò | Package |
| ------ | ------- | ------- |
| catalog | **Owner** (planned) | `modules/catalog/` |
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
| Epic 01 — Quản lý vòng đời sản phẩm | [EPIC-01-product/](EPIC-01-product/) | US-01..05 | 3+3+3+3+5 | planned |
| Epic 02 — Giá niêm yết và giá sàn | [EPIC-02-pricing/](EPIC-02-pricing/) | US-01..02 | 2+3 | planned |

*Harness `harness/` khi chuyển `in_progress` — xem [THEME_DOCUMENTATION_TEMPLATE.md](../THEME_DOCUMENTATION_TEMPLATE.md).*

## Quy ước ID (khi có Epic tree)

```text
TH-02 / Epic-{nn} / US-{nn} / FR-{nn}
Test id: scn_e01_u02_fr06_01 (BE), wgt_e02_u01_fr03_01 (FE), e2e_e01_u02_fr06_01 (E2E)
```
