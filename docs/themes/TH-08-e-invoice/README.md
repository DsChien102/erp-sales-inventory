# TH-08: Hóa đơn điện tử

**Trạng thái deliver:** `in_progress` (Contract + BE S1/S2a done; **S2b BE verified, lane still in_progress** pending migration promote + S3b poll consumer; FE/E2E todo)

## Mục tiêu

Lập, phát hành, theo dõi và gửi hóa đơn điện tử từ đơn hàng Hoàn tất — tích hợp MISA meInvoice (Phase 1), không có danh sách HĐĐT độc lập trong MVP.

> **Mã theme:** HĐĐT = **TH-08** (`TH-08-e-invoice/`). Catalog cũ từng ghi TH-07 — đã chuyển sang đây.

## Module tham gia (dự kiến)

| Module | Vai trò | Package |
| ------ | ------- | ------- |
| einvoice | **Owner** — config, issuance, hồ sơ HĐ, delivery | `modules/einvoice/` *(contract lane)* |
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
| EP-01 Kết nối NCC & cấu hình phát hành | [Epic-01-provider-connection-config/](Epic-01-provider-connection-config/) | 4 | in_progress (Contract+BE done) |
| EP-02 Phát hành từ đơn hàng | [Epic-02-issue-from-sales-order/](Epic-02-issue-from-sales-order/) | 5 | in_progress (S2a BE done; S2b BE verified, lane in_progress) |
| EP-03 Hồ sơ & tài liệu đã phát hành | [Epic-03-issued-invoice-documents/](Epic-03-issued-invoice-documents/) | 3 | planned |
| EP-04 Gửi & gửi lại HĐĐT | [Epic-04-send-resend-einvoice/](Epic-04-send-resend-einvoice/) | 3 | planned |

Layout US: **flat** `Epic-*/US-{nn}.md` (giống TH-03/04). FR/BR/EC/SC nằm trong file US.

## Quy ước ID

```text
TH-08 / EP-{nn} / US-{nn} / FR-{nn} / BR-{nn} / SC-{nn}
```

FR/BR/SC **local theo US** (FR-01 lặp giữa các US). Trace harness: `EP-0n/US-0m/FR-0k`. Scenario Gherkin trong SRS dùng `SC-*`; khi map test id có thể dùng `SCN-*`.

## Việc tiếp theo

1. **Promote** draft `supabase/migrations/_drafts/007_einvoice_s2b_schema_and_rpc.sql` khi sẵn sàng ship DB.
2. **S3b BE** — poll consumer, callback ingestion, reconciliation resolution/recovery (ReconciliationCase `next_check_at` handoff từ S2b).
3. **Authoritative source contracts** — Theme 05 sales order projection + Theme 03 partner buyer data (S2b hiện dùng fake/read-port seam).
4. Slice **S2 FE/E2E** — confirmation sheet, processing poll projection ([04-slice-roadmap.md](harness/04-slice-roadmap.md)).
5. Verify: `./scripts/ci/guard_theme_structure.sh` + `./scripts/ci/guard_theme_traceability.sh`

### S2b closeout (honest)

S2b verifies manual start and immediate provider-result landing through Dart fakes, RPC-shape/SQL contract tests and worker tests. Production remains fail-closed until authoritative Theme 05/Theme 03 source contracts and the approved SQL migration land. Unknown-result cases land as pending ReconciliationCases with `next_check_at` and are inert until the S3b poll consumer scans them, so S2b carries no poison-row risk; those cases are only acted on once S3b ships its poll consumer.

## Platform

[docs/architecture/](../../architecture/README.md)
