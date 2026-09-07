# vet45_misa

MISA vendor adapters for Vet45. Phase A covers **meInvoice outbound** (e-invoice phát hành) only.

## Import

```dart
import 'package:vet45_misa/e_invoice.dart';
```

## meInvoice (`e_invoice.dart`)

Blackbox adapter — public models mirror [MISA Open API §13](https://www.misa.vn/154989/tai-lieu-open-api-tich-hop-hoa-don-dien-tu-misa-meinvoice-dau-ra) with Dart `lowerCamelCase` fields and MISA PascalCase JSON keys via `toJson()` / `fromJson()`.

- `IMeInvoiceClient` — port
- `MeInvoiceClient` — real HTTP (injectable `http.Client`)
- `FakeMeInvoiceClient` — unit tests, no network

### Methods (outbound)

| Method | MISA endpoint |
| --- | --- |
| `listInvoiceTemplates` | GET `/invoice/templates?ticket=false` |
| `listTicketTemplates` | GET `/invoice/templates?ticket=true` |
| `previewUnpublished` | POST `/invoice/unpublishview` |
| `publish` | POST `/invoice` (SignType 2 or 5) |
| `previewPublished` | POST `/invoice/publishview` |
| `download` | POST `/invoice/download` |
| `getStatus` | POST `/invoice/status` |
| `sendEmail` | POST `/invoice/sendemail` |
| `convertToPaper` | POST `/invoice/voucher-paper` |

### Core models (§13)

| Dart type | MISA type |
| --- | --- |
| `MeInvoiceTemplate` | Template |
| `MeInvoiceTicket` | Ticket |
| `MeInvoiceInvoiceData` | InvoiceData |
| `MeInvoiceOriginalInvoiceDetail` | OriginalInvoiceDetail |
| `MeInvoiceTaxRateInfo` | TaxRateInfo |
| `MeInvoiceInvoiceStatus` | InvoiceStatus |
| `MeInvoicePublishInvoiceResultItem` | publishInvoiceResult[] item |

### Publish (HSM)

```dart
final result = await client.publish(
  MeInvoicePublishRequest(
    signType: MeInvoiceSignType.hsmWithCks, // 2
    invoiceData: [invoiceData],
  ),
);
```

SignType **2** (HSM + CKS) and **5** (MTT, no CKS) only. USB/SignService (SignType 1) is out of scope.

### Config

`MeInvoiceConfig`: `baseUrl`, `appId`, `taxCode`, `username`, `password`, optional seeded `accessToken`.

Default base URLs:

- test: `https://testapi.meinvoice.vn/api/integration`
- prod: `https://api.meinvoice.vn/api/integration`

## Live smoke

```bash
cd packages/vet45_misa
cp .env.misa.local.example .env.misa.local

dart run tool/smoke_me_invoice.dart token
dart run tool/smoke_me_invoice.dart templates
dart run tool/smoke_me_invoice.dart preview
dart run tool/smoke_me_invoice.dart status --tx=<TRANSACTION_ID>
```

Publish requires `MISA_SMOKE_CONFIRM_PUBLISH=1`. Token cache: `.meinvoice_token.local` (~7 days refresh; ~14 days MISA TTL).

## Out of scope (Phase A)

- USB/File signing (SignType 1) + SignService `:12019`
- SignType 3/4/6 (async / vé MTT flows)
- ERP module / messaging worker wiring (Phase B TH-08)

## References

- [Canonical spec snapshot](doc/misa-meinvoice-open-api.md)
- [MISA Open API (đầu ra)](https://www.misa.vn/154989/tai-lieu-open-api-tich-hop-hoa-don-dien-tu-misa-meinvoice-dau-ra/)
