# TH-02 — Traceability (v3)

Ma trận truy vết FR → Role → contract → artifact → test.

```text
e{epic}/u{us}/fr{fr}/{TYPE}-{id}   ví dụ: e02/u01/fr01/SCN-01
Test id: scn_e02_u01_fr01_01 (BE), wgt_e02_u01_fr01_01 (FE), e2e_e02_u01_fr01_01 (E2E)
```

**Trạng thái:** Reset theo spec v3 (2026-07). Cập nhật row khi slice lane `in_progress` / `done`.

Contracts: [07-api-contracts.md](07-api-contracts.md) — **đang cập nhật theo v3**; ưu tiên slice EPIC-02/US-01.

---

## Platform — Catalog codegen (infrastructure)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| TH-02-PLATFORM | BE | — | infrastructure | `build.yaml`, `CatalogCommandPipeline`, `CatalogModuleDefinition` | — | todo |
| TH-02-PLATFORM | BE | — | infrastructure | `registerGeneratedCatalogHandlers`, `catalog_access_metadata.g.dart` | catalog_access_metadata_registry_test | todo |

Codegen ritual: mirror [modules/partner/README.md](../../../../modules/partner/README.md).

---

## EPIC-02 / US-01 — Guided create (slice #1)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §EPIC-02-US-01 | application | `CreateProductCommand`, `CheckDuplicateProductCodeQuery`, DTOs | — | todo |
| FR-01 | BE | §EPIC-02-US-01 | application | Create handler (nhận diện + ảnh) | scn_e02_u01_fr01_01 | todo |
| FR-02 | BE | §EPIC-02-US-01 | application | Dup check query/handler | scn_e02_u01_fr02_01 | todo |
| FR-03 | BE | §EPIC-02-US-01 | application | Base unit in create flow | scn_e02_u01_fr03_01 | todo |
| FR-04 | BE | §EPIC-02-US-01 | application | Initial status + readiness seed | scn_e02_u01_fr04_01 | todo |
| FR-01..04 | FE | §EPIC-02-US-01 | presentation | Guided create flow, form widgets | wgt_e02_u01_fr01_01 | todo |
| FR-01 | E2E | §EPIC-02-US-01 | integration | ERP via `ICatalogModule` | e2e_e02_u01_fr01_01 | todo |

---

## EPIC-01 / US-01 — Tra cứu danh mục (slice #4)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-01 | CONTRACT | §EPIC-01-US-01 | application | `SearchProductsQuery`, readiness filter DTOs | — | todo |
| FR-01 | BE | §EPIC-01-US-01 | application | Search + barcode handler | scn_e01_u01_fr01_01 | todo |
| FR-03 | BE | §EPIC-01-US-01 | application | Readiness chip in list DTO | scn_e01_u01_fr03_01 | todo |
| FR-01..04 | FE | §EPIC-01-US-01 | presentation | Product list page + filters | wgt_e01_u01_fr01_01 | todo |
| FR-01 | E2E | §EPIC-01-US-01 | integration | Search E2E | e2e_e01_u01_fr01_01 | todo |

---

## EPIC-01 / US-02 — Product Control Center (slice #5)

| Req ID | Role | Contract § | Enforce layer | Artifact | Test id | Status |
| ------ | ---- | ---------- | ------------- | -------- | ------- | ------ |
| US-02 | CONTRACT | §EPIC-01-US-02 | application | `GetProductControlCenterQuery`, action DTOs | — | todo |
| FR-04 | BE | §EPIC-01-US-02 | application | Readiness checklist projection | scn_e01_u02_fr04_01 | todo |
| FR-05 | BE | §EPIC-01-US-02 | application | Contextual actions by permission/status | scn_e01_u02_fr05_01 | todo |
| FR-01..06 | FE | §EPIC-01-US-02 | presentation | `product_control_center_page.dart` | wgt_e01_u02_fr01_01 | todo |
| FR-01 | E2E | §EPIC-01-US-02 | integration | Detail E2E | e2e_e01_u02_fr01_01 | todo |

---

## Các slice còn lại

Thêm row theo [04-slice-roadmap.md](04-slice-roadmap.md) khi bắt đầu CONTRACT lane. Tổng: 7 epic, 24 US, 96 FR (xem [README.md](../README.md#epic-index)).
