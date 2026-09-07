# TH-08: Hóa đơn điện tử

**Trạng thái deliver:** `in_progress` (Contract done S1–S4; **S4 BE Dart + worker verified**, lane `in_progress` pending Sales scope gate + draft promote `010`/`011`/`012`; S2b/S3 lanes in_progress; Worker done S1–S4; S3 E2E done; FE todo S4 EP-03)

## Mục tiêu

Lập, phát hành, theo dõi và gửi hóa đơn điện tử từ đơn hàng Hoàn tất — tích hợp MISA meInvoice (Phase 1), không có danh sách HĐĐT độc lập trong MVP.

> **Mã theme:** HĐĐT = **TH-08** (`TH-08-e-invoice/`). Catalog cũ từng ghi TH-07 — đã chuyển sang đây.

## Module tham gia (dự kiến)

| Module | Vai trò | Package |
| ------ | ------- | ------- |
| einvoice | **Owner** — config, issuance, hồ sơ HĐ, delivery | `modules/einvoice/` *(contract lane)* |
| sales (TH-05) | Supporting — SalesOrder scope gate `sales.can_access_sales_order` for S4 reads | `modules/sales/` |
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
| EP-01 Kết nối NCC & cấu hình phát hành | [Epic-01-provider-connection-config/](Epic-01-provider-connection-config/) | 4 | in_progress (Contract+BE done) |
| EP-02 Phát hành từ đơn hàng | [Epic-02-issue-from-sales-order/](Epic-02-issue-from-sales-order/) | 5 | in_progress (S2a BE done; S2b BE verified, lane in_progress) |
| EP-03 Hồ sơ & tài liệu đã phát hành | [Epic-03-issued-invoice-documents/](Epic-03-issued-invoice-documents/) | 3 | in_progress (BE Dart + worker done; DB draft; FE todo) |
| EP-04 Gửi & gửi lại HĐĐT | [Epic-04-send-resend-einvoice/](Epic-04-send-resend-einvoice/) | 3 | planned |

Layout US: **flat** `Epic-*/US-{nn}.md` (giống TH-03/04). FR/BR/EC/SC nằm trong file US.

## Quy ước ID

```text
TH-08 / EP-{nn} / US-{nn} / FR-{nn} / BR-{nn} / SC-{nn}
```

FR/BR/SC **local theo US** (FR-01 lặp giữa các US). Trace harness: `EP-0n/US-0m/FR-0k`. Scenario Gherkin trong SRS dùng `SC-*`; khi map test id có thể dùng `SCN-*`.

## Việc tiếp theo

1. **S4 DB + Sales gate** — promote drafts `010`/`011`/`012` khi sẵn sàng; implement source-owned `sales.can_access_sales_order` trong Sales module (không stub allow-all).
2. **S4 FE** — SG-02 official view action + SG-06 document sheet trên Theme 05 order row.
3. **Promote/apply** bộ draft S2/S3 (`007`, `008`, `009`) khi sẵn sàng ship DB; không promote trong slice implementation thông thường.
4. **Authoritative source contracts** — Theme 05 sales order projection + Theme 03 partner buyer data (S2b hiện dùng fake/read-port seam).
5. Slice **S2 FE** — confirmation sheet, processing poll projection và host-page integration ([04-slice-roadmap.md](harness/04-slice-roadmap.md)).
6. Thu thập live MISA sandbox evidence cho S1/S4 ở integration gate; focused fake/contract tests vẫn là gate local.
7. Verify: `./scripts/ci/guard_theme_structure.sh` + `./scripts/ci/guard_theme_traceability.sh`

### S2b closeout (honest)

S2b verifies manual start and immediate provider-result landing through Dart fakes, RPC-shape/SQL contract tests and worker tests. S3b poll/reconciliation/recovery is implemented and covered, including the pre-S4 schema-compatibility repair. Production remains fail-closed until authoritative Theme 05/Theme 03 source contracts and approved SQL drafts are promoted/applied.

### S4 closeout (honest)

S4 verifies official view, PDF/XML document retrieval và provider observation qua Dart integration harness (17 scenarios), worker tests và SQL contract tests — không live MISA trong CI. Aggregate BE lane `in_progress`: `sales.can_access_sales_order` chưa source-owned; drafts `010`/`011`/`012` chưa promote. FE/E2E EP-03 vẫn `todo`.

## Platform

[docs/architecture/](../../architecture/README.md)
