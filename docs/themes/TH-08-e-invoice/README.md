# TH-08: Hóa đơn điện tử

**Trạng thái deliver:** `in_progress` (Contract done S1–S5; **S3 FE/E2E `done`**; S3 BE `in_progress` pending draft promote `007`/`008`/`009`; **S4 FE `done`**; **S4 BE/E2E `in_progress`** (draft + live MISA); **S5 FE `done`** (app-owned SG-07 Send/Resend/History trên hai host Theme 05); **S5 BE Dart/Worker `done`**, **BE DB `in_progress`** (drafts `013`–`016`); **S5 E2E `in_progress`** (UI fake/runtime pass; promoted DB + MISA Product live + simulator AC còn mở); Worker done S1–S5)

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
| Harness | [harness/](harness/) | Ritual, domain, contracts, slices |

## Epic index

| Epic | Folder | US | Status |
| ---- | ------ | -- | ------ |
| EP-01 Kết nối NCC & cấu hình phát hành | [Epic-01-provider-connection-config/](Epic-01-provider-connection-config/) | 4 | in_progress (Contract+BE done) |
| EP-02 Phát hành từ đơn hàng | [Epic-02-issue-from-sales-order/](Epic-02-issue-from-sales-order/) | 5 | in_progress (S2a BE done; S2b BE verified; S3 FE/E2E done, S3 BE in_progress pending draft promote) |
| EP-03 Hồ sơ & tài liệu đã phát hành | [Epic-03-issued-invoice-documents/](Epic-03-issued-invoice-documents/) | 3 | in_progress (BE Dart + worker done; FE done; E2E fake pass; DB draft + live MISA pending) |
| EP-04 Gửi & gửi lại HĐĐT | [Epic-04-send-resend-einvoice/](Epic-04-send-resend-einvoice/) | 3 | in_progress (FE done; BE Dart/Worker done; DB draft + live E2E pending) |

Layout US: **flat** `Epic-*/US-{nn}.md` (giống TH-03/04). FR/BR/EC/SC nằm trong file US.

## Quy ước ID

```text
TH-08 / EP-{nn} / US-{nn} / FR-{nn} / BR-{nn} / SC-{nn}
```

FR/BR/SC **local theo US** (FR-01 lặp giữa các US). Trace harness: `EP-0n/US-0m/FR-0k`. Scenario Gherkin trong SRS dùng `SC-*`; khi map test id có thể dùng `SCN-*`.

## Việc tiếp theo

1. **S5 DB + live send** — promote drafts `013`–`016`; MISA Product live send evidence (che token/email); simulator manual AC (CV10 B6–B8); không dùng testapi email làm proof mailbox.
2. **S4 DB + Sales gate** — promote drafts `010`/`011`/`012`/`018`; implement source-owned `sales.can_access_sales_order` trong Sales module.
3. **Promote/apply** bộ draft S2/S3 (`007`, `008`, `009`) khi sẵn sàng ship DB; không promote trong slice implementation thông thường.
4. **Authoritative source contracts** — Theme 05 sales order projection + Theme 03 partner buyer data (S2b hiện dùng fake/read-port seam).
5. Thu thập live MISA evidence cho S1/S4/S5 ở integration gate; focused fake/contract tests vẫn là gate local.
6. Verify: `./scripts/ci/guard_theme_structure.sh` + `./scripts/ci/guard_theme_traceability.sh`

### S2b closeout (honest)

S2b verifies manual start and immediate provider-result landing through Dart fakes, RPC-shape/SQL contract tests and worker tests. S3b poll/reconciliation/recovery is implemented and covered, including the pre-S4 schema-compatibility repair. Production remains fail-closed until authoritative Theme 05/Theme 03 source contracts and approved SQL drafts are promoted/applied.

### S4 closeout (honest)

S4 verifies official view, PDF/XML document retrieval và provider observation qua Dart integration harness (25 scenarios incl. observation trace id), worker tests và SQL contract tests — không live MISA trong CI. **FE lane `done`:** app-owned SG-02/SG-06, `OrderEInvoiceSection` trên chi tiết đơn + kết quả bán hàng, poll theo `operationId`, checksum handoff, SnackBar lỗi an toàn; không observation UI. **E2E lane `in_progress`:** `th08_e2e_e03_u01/u02_sc01_01` pass trên fake Theme 05 hosts; `th08_e2e_e03_u03_sc01_01` pass worker/integration boundary. Aggregate BE lane `in_progress`: `sales.can_access_sales_order` chưa source-owned; drafts `010`/`011`/`012`/`018` chưa promote. `verify_harness.sh` baseline fail tại `modules/einvoice/presentation/pubspec.yaml` (ADR 11 debt) — không phải regression S4.

### S5 closeout (honest)

S5 FE BE–FE plan: app-owned SG-07 Send/Resend/History; `OrderInvoiceDeliveryCubit`; PROCESSING-only lock; UNKNOWN cho phép resend thủ công; không FE `StartAutoDeliveryCommand`. **FE lane `done`** (focused ERP suite + catalog). **E2E `in_progress`:** `th08_e2e_e04_u01_sc01_01`, `th08_e2e_e04_u02_sc01_01`, `th08_e2e_e04_u02_sc06_01`, `th08_e2e_e04_u02_sc08_01`, `th08_e2e_e04_u03_sc04_01` pass trên fake Theme 05 hosts; live promoted DB + MISA Product + simulator AC còn mở. **BE DB `in_progress`:** drafts `013`–`016` chưa promote. Aggregate Slice 5 **không** `done`.

## Platform

[docs/architecture/](../../architecture/README.md)
