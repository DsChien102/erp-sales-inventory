# E-Invoice presentation example

Flutter catalog app để **preview / audit** widget của bounded context E-Invoice (TH-08) trước khi gắn vào `apps/erp`.

Không phải ERP shell. Không gọi live Supabase. Không cần `env:doctor`.

Đây là **audit scaffold** — Overview liệt kê 38 specimen SRS §6.5; tab SG chỉ placeholder cho đến khi slice FE land.

## Chạy

```bash
vet45 run einvoice_presentation debug
vet45 run einvoice_presentation debug:web
vet45 run einvoice_presentation debug:ios

cd modules/einvoice/presentation/example
flutter pub get
flutter run
```

```bash
cd modules/einvoice/presentation/example && flutter analyze
```

## Tabs

| Tab | Nội dung |
| --- | --- |
| Overview | Intro + audit checklist 38 specimen §6.5 |
| SG-01 | EP-01 — Thiết lập & readiness (placeholder) |
| SG-02 | EP-02 — Row HĐĐT & preview (placeholder) |
| SG-03 | EP-02 — Xác nhận & theo dõi phát hành (placeholder) |
| SG-06 | EP-03 — Tài liệu XML/PDF (placeholder) |
| SG-07 | EP-04 — Gửi / gửi lại (placeholder) |

SG-04 và SG-05 **không** có trong MVP.

## Fake module (slice FE sau)

Wire `FakeEInvoiceModule` từ `vet45_einvoice_application/testing.dart` — scenario ids khớp [07-api-contracts.md](../../../docs/themes/TH-08-e-invoice/harness/07-api-contracts.md).

Public reusable widget mới trong `modules/einvoice/presentation/lib` → **cùng PR** thêm `PreviewSection` dưới tab SG phù hợp và cập nhật `audit_manifest.dart` (`AuditStatus`).
