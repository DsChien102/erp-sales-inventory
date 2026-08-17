# TH-08: Hóa đơn điện tử

**Trạng thái deliver:** `planned` (canonical + harness exemplar-complete; chưa slice code)

## Mục tiêu

Lập, phát hành, theo dõi và gửi hóa đơn điện tử từ đơn hàng Hoàn tất — tích hợp MISA meInvoice (Phase 1), không có danh sách HĐĐT độc lập trong MVP.

> **Mã theme:** HĐĐT = **TH-08** (`TH-08-e-invoice/`). Catalog cũ từng ghi TH-07 — đã chuyển sang đây.

## Module tham gia (dự kiến)

| Module | Vai trò | Package |
| ------ | ------- | ------- |
| einvoice | **Owner** — config, issuance, hồ sơ HĐ, delivery | `modules/einvoice/` *(greenfield)* |
| sales (TH-05) | Supporting — SalesOrder, BuyerInvoiceSnapshot, màn nguồn | `modules/sales/` |
| partner (TH-03) | Supporting — resolve completion buyer (trước khóa) | `modules/partner/` |
| iam / org (TH-01) | Supporting — tenant, permission, hồ sơ pháp lý bên bán | `modules/iam/` |
| catalog | Supporting — snapshot sản phẩm / thuế nếu cần lineage | `modules/catalog/` |

Chi tiết boundary: [harness/02-module-map.md](harness/02-module-map.md), [OVERVIEWS.md](OVERVIEWS.md).

## Tài liệu

| Nhóm | File | Ghi chú |
| ---- | ---- | ------- |
| **Product spec (canonical)** | [Theme-8-e-invoice.md](Theme-8-e-invoice.md) | SSOT đầy đủ |
| Business scope | [OVERVIEWS.md](OVERVIEWS.md) | Purpose, scope, epic map |
| Appendices | [APPENDICES.md](APPENDICES.md) | CJ / UF / SG index |
| References | [references.md](references.md) | Cross-theme, MISA, platform |
| Raw dump | [_incoming/](_incoming/) | Chỉ file thô trước ingest |
| Harness | [harness/](harness/) | Ritual, domain, contracts, slices |

## Epic index

| Epic | Folder | US | Status |
| ---- | ------ | -- | ------ |
| EP-01 Kết nối NCC & cấu hình phát hành | [Epic-01-provider-connection-config/](Epic-01-provider-connection-config/) | 4 | planned |
| EP-02 Phát hành từ đơn hàng | [Epic-02-issue-from-sales-order/](Epic-02-issue-from-sales-order/) | 5 | planned |
| EP-03 Hồ sơ & tài liệu đã phát hành | [Epic-03-issued-invoice-documents/](Epic-03-issued-invoice-documents/) | 3 | planned |
| EP-04 Gửi & gửi lại HĐĐT | [Epic-04-send-resend-einvoice/](Epic-04-send-resend-einvoice/) | 3 | planned |

Layout US: **flat** `Epic-*/US-{nn}.md` (giống TH-03/04). FR/BR/EC/SC nằm trong file US.

## Quy ước ID

```text
TH-08 / EP-{nn} / US-{nn} / FR-{nn} / BR-{nn} / SC-{nn}
```

FR/BR/SC **local theo US** (FR-01 lặp giữa các US). Trace harness: `EP-0n/US-0m/FR-0k`. Scenario Gherkin trong SRS dùng `SC-*`; khi map test id có thể dùng `SCN-*`.

## Việc tiếp theo

1. Slice đầu: [harness/04-slice-roadmap.md](harness/04-slice-roadmap.md) **S1** (EP-01 — scaffold `modules/einvoice/`).
2. Contract lane: freeze §S1a–S1d trong [harness/07-api-contracts.md](harness/07-api-contracts.md) khi bắt đầu implement.
3. Khi bắt đầu slice code đầu: cập nhật **Trạng thái deliver** trên README (`planned` → đang giao).
4. Verify: `./scripts/ci/guard_theme_structure.sh` + `./scripts/ci/guard_theme_traceability.sh`

## Platform

[docs/architecture/](../../architecture/README.md)
