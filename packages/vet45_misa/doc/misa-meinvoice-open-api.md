# MISA meInvoice Open API — spec reference

Canonical documentation:

https://www.misa.vn/154989/tai-lieu-open-api-tich-hop-hoa-don-dien-tu-misa-meinvoice-dau-ra

This package maps **§13 object models** 1-1 (field coverage + JSON wire keys). Implementation lives under `lib/src/e_invoice/models/misa/`.

## §13 type index

| § | MISA type | Dart class |
| --- | --- | --- |
| 13.1 | Template | `MeInvoiceTemplate` |
| 13.2 | Ticket | `MeInvoiceTicket` |
| 13.3 | InvoiceData | `MeInvoiceInvoiceData` |
| 13.4 | OriginalInvoiceDetail | `MeInvoiceOriginalInvoiceDetail` |
| 13.5 | TaxRateInfo | `MeInvoiceTaxRateInfo` |
| 13.6 | OtherInfo | `MeInvoiceOtherInfo` |
| 13.7 | FeeInfo | `MeInvoiceFeeInfo` |
| 13.8 | ClockInfo | `MeInvoiceClockInfo` |
| 13.9 | OptionUserDefined | `MeInvoiceOptionUserDefined` |
| 13.10 | PublishInvoiceData | `MeInvoicePublishInvoiceData` |
| 13.11 | InvoiceStatus | `MeInvoiceInvoiceStatus` |

## Response envelope (§1.3)

Parsed by `MeInvoiceApiResponse`: `success`, `errorCode`, `descriptionErrorCode`, `createInvoiceResult`, `publishInvoiceResult`, `data`, `customData`, `errors`.

## Supported integration endpoints

| Endpoint | Client method |
| --- | --- |
| `/auth/token` | `MeInvoiceClient.obtainAccessToken()` |
| `/invoice/templates` | `listInvoiceTemplates` / `listTicketTemplates` |
| `/invoice/unpublishview` | `previewUnpublished` |
| `/invoice` | `publish` (SignType 2/5) |
| `/invoice/publishview` | `previewPublished` |
| `/invoice/download` | `download` |
| `/invoice/status` | `getStatus` |
| `/invoice/sendemail` | `sendEmail` |
| `/invoice/voucher-paper` | `convertToPaper` |

## Notes

- Wire key `EnvironmmentFeeAmount` (typo in MISA doc) preserved as-is.
- Date-only fields (`InvDate`, `OrgInvDate`) use `yyyy-MM-dd` strings.
- Status/download/publishview bodies are JSON **arrays** of transaction IDs, not wrapped objects.
