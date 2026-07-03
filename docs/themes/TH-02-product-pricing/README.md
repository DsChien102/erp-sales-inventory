# TH-02: Sản phẩm & Giá bán

**Trạng thái deliver:** `in_progress`  
**Spec version:** v3 (2026-07)

Master data sản phẩm, readiness, đơn vị tính, tồn kho cơ bản, Giá cơ sở định giá, khung giá bán (Giá niêm yết / Giá sàn) và custom fields theo ngành — nền tảng cho bán hàng (TH-04), kho (TH-06) và báo cáo.

## Triết lý v3

Theme không chỉ lưu danh sách sản phẩm mà đưa sản phẩm vào **trạng thái sẵn sàng vận hành** qua:

- **Product Readiness** — checklist + blocker rõ ràng
- **Guided Product Creation** — tạo tối thiểu rồi hoàn thiện dần
- **Product Control Center** — màn chi tiết điều phối hành động theo ngữ cảnh
- **Custom fields** — thay `medical_info` hard-coded; retail-first, industry-extensible

## Module tham gia

| Module | Vai trò | Package |
| ------ | ------- | ------- |
| catalog | **Owner** (planned) | `modules/catalog/` |
| inventory | Supporting — Advanced stock read | `modules/inventory/` |
| costing | Supporting — base price read (Growth) | `modules/costing/` |
| iam | Supporting — access | `modules/iam/` |

## Tài liệu

| Nhóm | File |
| ---- | ---- |
| Business scope (v3 overview) | [01-business-scope.md](01-business-scope.md) |
| Module map | [02-module-map.md](02-module-map.md) |
| Phụ lục (flows, ERD, permissions) | [appendices/](appendices/) |
| Platform architecture | [docs/architecture/](../../architecture/README.md) |

## Epic index

| Epic | Folder | US | FR | Status |
| ---- | ------ | -- | -- | ------ |
| 01 — Tra cứu & điều hướng readiness | [EPIC-01-discovery-readiness/](EPIC-01-discovery-readiness/) | 2 | 10 | todo |
| 02 — Tạo sản phẩm có hướng dẫn | [EPIC-02-guided-creation/](EPIC-02-guided-creation/) | 3 | 12 | todo |
| 03 — Thông tin đặc thù ngành | [EPIC-03-industry-fields/](EPIC-03-industry-fields/) | 3 | 12 | todo |
| 04 — Đơn vị đo lường | [EPIC-04-units/](EPIC-04-units/) | 4 | 15 | todo |
| 05 — Chế độ tồn kho | [EPIC-05-stock/](EPIC-05-stock/) | 4 | 15 | todo |
| 06 — Định giá & khung giá bán | [EPIC-06-pricing/](EPIC-06-pricing/) | 4 | 16 | todo |
| 07 — Vòng đời & kiểm soát | [EPIC-07-lifecycle/](EPIC-07-lifecycle/) | 4 | 16 | todo |

Slice order: [harness/04-slice-roadmap.md](harness/04-slice-roadmap.md)

## Harness

| File | Mô tả |
| ---- | ----- |
| [harness/00-agent-ritual.md](harness/00-agent-ritual.md) | Thứ tự đọc khi implement slice |
| [harness/01-domain-model.md](harness/01-domain-model.md) | Aggregate, commands, events (v3) |
| [harness/02-module-map.md](harness/02-module-map.md) | Owner/supporting, permissions |
| [harness/03-architecture-and-flows.md](harness/03-architecture-and-flows.md) | Flows, RPC |
| [harness/04-slice-roadmap.md](harness/04-slice-roadmap.md) | Slice order, lane status |
| [harness/05-traceability.md](harness/05-traceability.md) | FR → Role → test id |
| [harness/06-harness-notes.md](harness/06-harness-notes.md) | Guards, flywheel |
| [harness/07-api-contracts.md](harness/07-api-contracts.md) | FE↔BE contracts + fake scenarios |

## Quy ước ID

```text
TH-02 / EPIC-{nn}-* / US-{nn} / FR-{nn}
Test id: scn_e02_u01_fr01_01 (BE), wgt_e02_u01_fr01_01 (FE), e2e_e02_u01_fr01_01 (E2E)
```

Epic folder dùng prefix `EPIC-{nn}-*` (ví dụ `EPIC-02-guided-creation`).
