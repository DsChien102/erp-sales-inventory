# MISA meInvoice Open API — spec reference

Canonical documentation (public):

https://www.misa.vn/154989/tai-lieu-open-api-tich-hop-hoa-don-dien-tu-misa-meinvoice-dau-ra

**Baseline đợt hardening TH-08 (2026-09-16):** tài liệu MISA AIO V2 do BA cung cấp
(`Tài liệu API (AIO) Phát hành hóa đơn - V2-16:9:2026.md`). Khi public Open API và
V2 khác nhau về SignType / retry / serialization, **ưu tiên V2** cho code Theme 8
cho tới khi có xác nhận văn bản mới từ MISA.

This package maps **§13 object models** 1-1 (field coverage + JSON wire keys).
Implementation lives under `lib/src/e_invoice/models/misa/`.

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

Parsed by `MeInvoiceApiResponse`: `success`, `errorCode`, `descriptionErrorCode`,
`createInvoiceResult`, `publishInvoiceResult`, `data`, `customData`, `errors`.

## Supported integration endpoints

| Endpoint | Client method |
| --- | --- |
| `/auth/token` | `MeInvoiceClient.obtainAccessToken()` |
| `/invoice/templates` | `listInvoiceTemplates` / `listTicketTemplates` |
| `/invoice/unpublishview` | `previewUnpublished` |
| `/invoice` | `publish` (**SignType 2 hoặc 5 only**) |
| `/invoice/publishview` | `previewPublished` |
| `/invoice/download` | `download` |
| `/invoice/status` | `getStatus` |
| `/invoice/sendemail` | `sendEmail` — Product envelope `success=true`, empty `errors`, `data=""` → `MeInvoiceSendEmailResponse.envelopeAcknowledgement`; itemized `data[]` with `SendEmailStatus` still supported. `SUCCEEDED` means provider accepted the send, not mailbox delivery. |
| `/invoice/voucher-paper` | `convertToPaper` |

## SignType (V2 freeze)

Theo V2 mục lưu ý trước khi tích hợp:

| Wire | Nghĩa | Vet45 Phase 1 |
| --- | --- | --- |
| `2` | HSM, **có** hiển thị CKS | **Hỗ trợ** — hóa đơn thường (có mã / không mã) |
| `5` | Hóa đơn máy tính tiền (MTT), **không** hiển thị CKS | **Hỗ trợ** — chỉ khi template/ký hiệu là MTT |
| `1` | USB / file mềm | Ngoài scope mobile MVP |
| `3` | HSM async (có CKS) | **Không hỗ trợ** — V2 gạch bỏ; không tự mở lại |
| `4` | Vé không mã | Ngoài scope Theme 08 |
| `6` | HĐ/Vé MTT async | **Không hỗ trợ** — V2 gạch bỏ |

Adapter **không** fallback `SignType=2` khi canonical thiếu dữ liệu. MTT bắt buộc `5`;
template thường HSM bắt buộc `2`.

## Publish serialization & retry (V2)

- Mỗi `InvSeries` chỉ được xử lý **tuần tự** foreground: gửi → nhận → xử lý → lưu,
  rồi mới request kế tiếp cùng ký hiệu. Multi-worker phải dùng lease bền vững
  theo `(tenant, provider connection, invoice series)` — mutex in-memory không đủ.
- Mã lỗi publish cần policy riêng (không gộp transport ambiguity):
  - `InvoiceNumberNotCotinuous` — retry có giới hạn, cùng `RefID` + canonical, backoff.
  - `InvoiceDuplicated` — reconcile-first theo `RefID`; chỉ retry khi definitive-not-found.
  - `DuplicateInvoiceRefID` — reconciliation-only, không blind retry.

## Field mapping — MISA → nguồn nội bộ → blocker

Đối chiếu đầy đủ (Theme 8 harness mirror): [TH-08 harness 07-api-contracts](../../../docs/themes/TH-08-e-invoice/harness/07-api-contracts.md) § MISA V2 field map.

| Trường MISA | Nguồn nội bộ | Blocker khi thiếu / sai |
| --- | --- | --- |
| `InvSeries` | Capability template đã chọn → snapshot bất biến trên attempt | `TEMPLATE_NOT_AVAILABLE` — không fallback template đầu / không bịa `1C26TAA` |
| `SignType` | Signing config resolve → wire `2` \| `5` đóng băng trước dispatch | `SIGNING_CONFIGURATION_NOT_AVAILABLE` / invalid-canonical — không default `2` |
| `IsInvoiceSummary` | Template `IsSendSummary` từ MISA capability | Fail closed nếu capability thiếu khi cần gửi bảng tổng hợp |
| `VATRateName` | Business policy `KCT-only` Theme 8 khi invariant pass | `UNSUPPORTED_TAX_DATA` nếu nguồn Sales vi phạm contract thuế |
| `VATAmount` / `VATAmountOC` | Canonical `0` dưới policy `KCT` | Cùng blocker thuế |
| `TaxRateInfo` | Một group `KCT` nhất quán với dòng | Cùng blocker thuế |
| Buyer MST + tên pháp lý + địa chỉ | `EffectiveBuyerInvoiceData` (org có MST) | `BUYER_TAX_CODE_REQUIRED` / `BUYER_DATA_INCOMPLETE` / `BUYER_ADDRESS_REQUIRED` |

**Thuế:** `KCT-only` là business policy BA (16/09/2026), hard-code **một boundary**
`build_canonical_invoice` trong Theme 8 — không rải Catalog/Sales/UI. Nguồn Sales
vi phạm invariant (tax ≠ 0 hoặc tax snapshot không rỗng) → `UNSUPPORTED_TAX_DATA`,
fail closed trước provider; không ghi đè thành `KCT`. Đổi chính sách chỉ sau quyết
định BA/sản phẩm mới và plan riêng.

## Luồng đã đúng — phải giữ (regression)

Các phần sau đã hoạt động và **không được phá** trong đợt hardening:

| Luồng | Contract giữ |
| --- | --- |
| Endpoints bảng trên | Path + method ổn định |
| Token cache | Per-tenant; TTL/refresh; không singleton mọi tenant |
| `RefID` | Stable UUIDv5 từ business identity; retry giữ cùng `RefID` |
| Preview / official view | Worker-only HTTP; UI poll operation; HTTPS allowlist host MISA |
| Download PDF/XML | Content policy PDF magic / XML·ZIP; native Share Sheet |
| Send email Product | `success=true`, `data=""` → envelope acknowledgement; không suy mailbox |

## Notes

- Wire key `EnvironmmentFeeAmount` (typo in MISA doc) preserved as-is.
- Date-only fields (`InvDate`, `OrgInvDate`) use `yyyy-MM-dd` strings.
- Status/download/publishview bodies are JSON **arrays** of transaction IDs, not wrapped objects.
- Status/download/delivery phải dùng cùng classification (`invoiceWithCode` / MTT) suy từ `InvSeries` đã đóng băng trên attempt — không hard-code `invoiceWithCode: true`.
