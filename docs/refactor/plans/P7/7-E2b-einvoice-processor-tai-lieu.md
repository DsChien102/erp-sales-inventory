# 7-E2b — HĐĐT: `einvoice-processor` bản chính thức / tài liệu / quan sát — handler `fetch_official_view`, `download_invoice_document` (+ Storage), `poll_provider_observation` + 2 dead-letter

> Theme 8 (mã cũ P7) · Phần server. 7-E2 tách 3 plan theo luồng (người dùng chốt 2026-11-08): 7-E2a phát hành → **7-E2b bản chính thức / tài liệu / quan sát** → 7-E2c gửi email.
> Gồm: việc 7.4 phần sau phát hành (3/9 handler + 2/6 dead-letter); sửa bucket `einvoice-documents` nhận XML dạng ZIP (KI-24, Q2); ca SQL E46.
> Trạng thái: Plan ✅ (viết 2026-11-08, duyệt 2026-11-08) | Làm ✅ (2026-11-08) | Review R2 ✅ 2026-11-08 (R1: `NOT_FOUND`, log MISA, Kết quả)
> **Trước: 7-E2a Làm ✅ + Review R2 ✅** (2026-11-08, 249 ca xanh). Plan này sửa `handlers/registry.ts`, `index.ts`, `handlers/misa_client_factory.ts` (7-E1 / 7-E2a) và dùng `CommandHandler`, `CommandContext`, `ClaimedCommand`, `DeadLetterHandler` (`queue/types.ts`), `TenantMisaClientFactory`, `CredentialsRow` (`handlers/misa_client_factory.ts`), `FakeQueueRpc`, `cmd()` (`queue/test_support.ts`), `runInvocation` (`queue/processor.ts`), `MAX_ATTEMPTS_BY_COMMAND_TYPE` (`queue/attempt_policy.ts`: official view 2, document 3), client `misa/mod.ts` (`previewPublished`, `download`, `getStatus`, `MeInvoiceInvoiceQuery.tryFromInvSeries`, `MeInvoiceDownloadDataType`, `MeInvoiceViewUrlPolicy`, `MeInvoiceInvoiceDataPublished`, `MeInvoiceInvoiceStatus`), `FakeMeInvoiceClient` (`misa/fake_me_invoice_client.ts`: `enqueuePreviewPublishedResult`, `enqueueDownloadResult`, `enqueueGetStatusResult`, `lastTransactionIds`, `lastCompanyTaxCode`, `lastPreviewPublishedQuery`, `lastDownloadQuery`, `lastDownloadDataType`). Khuôn thư mục / gateway theo `handlers/issuance/` của 7-E2a. Sau: 7-E2c, 7-E3.
> Tài liệu: [TH-08](../../../02-yeu-cau/TH-08-hoa-don-dien-tu.md) US-03.1 (bản chính thức), US-03.2 (PDF / XML), US-03.3 (quan sát), 6.2 "Lệnh nội bộ", 9.1, 9.2 (PR 7.4). Nguồn chép (`modules/einvoice/`):
> - handler: `application/lib/src/electronic_invoice/commands/{fetch_official_invoice_view,download_invoice_document,poll_provider_observation,record_provider_observation}/`
> - kiểu chung: `application/lib/src/electronic_invoice/shared/{official_view_*,invoice_document_*,provider_observation_*,stored_invoice_document_dto,electronic_invoice_provider_context_dto}.dart`; `application/lib/src/exceptions/provider_call_ambiguous_exception.dart`; `domain/lib/src/electronic_invoice/services/invoice_document_content_policy.dart`
> - adapter: `infrastructure/lib/src/adapters/misa/{me_invoice_electronic_invoice_provider_adapter,me_invoice_official_view_classifier,me_invoice_document_classifier,me_invoice_observation_classifier,me_invoice_provider_call_support}.dart`
> - storage: `infrastructure/lib/src/storage/supabase_invoice_document_storage_port.dart`
> - gateway: `infrastructure/lib/src/data_access/supabase_electronic_invoice_command_gateway.dart:77-200`, `electronic_invoice_rpc_mapper.dart:33-99`, `:205-265` (`*ContextFromRow`, `mapDocumentStatus`), `:270-320`
> - dead-letter: `infrastructure/lib/src/configuration/processing/internal_commands/{official_view,invoice_document}_command_dead_letter_handler.dart`
>
> **Cho phiên code:** dùng `superpowers:executing-plans` (tuần tự). Mỗi task xong ghi ngay mục 9 theo mẫu (tệp:dòng, lệch plan, ca test, impact). **Không commit** (người dùng commit sau `detect_changes()`). **Không làm gì với DB** (không chạy SQL, không reset, không push, không deploy function). **Không đụng `modules/`, `packages/`, `apps/`** (chỉ đọc để chép). **Không ghi mục 10.**

**Goal:** Edge Function `einvoice-processor` chạy được 3 loại lệnh sau phát hành — lấy link bản chính thức, tải PDF / XML vào Storage, hỏi trạng thái MISA để ghi quan sát — với cùng RPC, cùng phân loại kết quả MISA, cùng đường lưu tệp như worker Dart cũ; XML dạng ZIP lưu được (KI-24).

**Architecture:** Thư mục mới `handlers/issued_invoice/`: phân loại lỗi MISA dùng chung + 3 bộ phân loại + chính sách nội dung tài liệu (hàm thuần), `issued_invoice_provider.ts` (gọi client MISA qua `TenantMisaClientFactory`), `document_storage.ts` (lưu tệp vào bucket qua interface hẹp `DocumentBucket`), interface gateway hẹp + bản Supabase thật, 3 handler + 1 hàm ghi quan sát + 2 dead-letter. Handler chỉ phụ thuộc interface, test bằng bản giả. 7-E1 / 7-E2a chỉ sửa: `getForTenant` trả thêm `taxCode`; `registry.ts` / `index.ts` thêm dòng đăng ký. Sửa migration gốc `20261031011` (một dòng `allowed_mime_types`).

**Tech Stack:** Deno 2, TypeScript, `npm:@supabase/supabase-js@2` (RPC + Storage), `jsr:@std/assert@1`, Web Crypto (`crypto.subtle.digest('SHA-256')`); PostgreSQL (migration + tệp test SQL).

## 1. Mục tiêu

- `deno test supabase/functions/einvoice-processor` xanh: 249 ca của 7-E1 + 7-E2a + 34 ca chép từ Dart (bảng mục 5) + 16 ca mới (Task 1: 1 ZIP, Task 2: 1 `taxCode`, Task 3: 2, Task 4: 6, Task 5: 4 dead-letter + 1 đăng ký + 3 tích hợp) ⇒ tổng 299.
- `deno check supabase/functions/einvoice-processor/index.ts`, `deno lint supabase/functions/einvoice-processor` không lỗi.
- `einvoice.fetch_official_view` → `load_official_view_operation_context` → (không `PENDING` ⇒ bỏ) → `previewPublished` → `record_official_invoice_view_result` `AVAILABLE` (link + hết hạn sau 5 phút) / `CHECK_REQUIRED` / `FAILED`; MISA không phản hồi ⇒ ném, hàng đợi thử lại; hết 2 lượt ⇒ dead-letter ghi `CHECK_REQUIRED / PROVIDER_RESULT_UNDETERMINED / INTERNAL`.
- `einvoice.download_invoice_document` → `load_invoice_document_operation_context` → `download` → lưu `einvoice-documents/<tenant>/<hoá đơn>/<pdf|xml>/v1/<sha256>.<pdf|xml|zip>` → `record_invoice_document_result` `AVAILABLE` (+ `storage_reference`, `checksum`) / `CHECK_REQUIRED` / `FAILED`; hết 3 lượt ⇒ dead-letter như trên.
- `einvoice.poll_provider_observation` → `load_provider_observation_context` → `getStatus` → `record_provider_observation` (khoá chống trùng `provider_observation:<command_id>`); MISA không phản hồi / lỗi ⇒ ném, không ghi quan sát giả (US-03.3 AC-02).
- Bucket `einvoice-documents` nhận `application/zip`; `einvoice_th08.sql` có E46 (người dùng chạy).

**Không làm:** `send_invoice_email`, `reconcile_invoice_delivery` + 2 dead-letter (7-E2c); xếp việc `poll_provider_observation` (hiện không ai gọi `request_provider_observation_refresh` — mục 8); link ký Storage cho app (`InvoiceDocumentSignedUrlResolver` — phía app, 7-A1); quyết định tạo lượt mới / dùng lại của bản chính thức (`OfficialViewOperationPolicy` — đã nằm trong RPC `request_official_invoice_view`); xử lý outbox `einvoice.provider_observation_attention_required` mà `record_provider_observation` ghi (chưa ai nhận, TH-08 "Cảnh báo Theme 11").

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | Chép test nào | Như 7-E2a Q3: chép test đơn vị (handler, adapter, phân loại, storage, chính sách nội dung), giữ tên ca. **Không** chép harness SQL giả (`einvoice_slice4_integration_test`, 17 ca), test hợp đồng SQL (`einvoice_s4a/b/c_sql_contract_test`), test đăng ký DI (`einvoice_s4_registration_test`), test gateway Supabase giả (`supabase_electronic_invoice_gateways_test`), ca phía app (`s4_public_*`, `InvoiceDocumentSignedUrlResolver`, `OfficialViewOperationPolicy`, `WorkerOnlyElectronicInvoiceProviderPort`). Ở `s4_worker_handlers_test.dart` chép 3/6 ca serialization (đọc payload) — bỏ `distinct triggerIds…` (chống trùng nằm ở SQL), `worker attempt number…`, `provider-call correlation…` (khái niệm Dart, TS lấy lượt từ `ctx.attemptNumber`); bỏ ca `PreviewInvoiceCommandHandler interaction audit` (luồng 7-E2a, đã có ca tương đương). Thay phần harness bằng 3 ca `FakeQueueRpc` + ca mới cho đường chưa có test Dart (handler quan sát, tải thành công, 2 dead-letter) |
| Q2 | XML dạng ZIP: Dart upload `application/zip`, đuôi `.zip` (`supabase_invoice_document_storage_port.dart:37-41`) nhưng bucket chỉ cho `application/pdf`, `application/xml`, `text/xml` (`20261031011:40-51`) ⇒ upload bị từ chối ⇒ 3 lượt ⇒ `CHECK_REQUIRED`, không tải được XML | **Người dùng chốt 2026-11-08 (A):** sửa migration gốc — thêm `'application/zip'` vào `allowed_mime_types` (người dùng reset DB); TS giữ đuôi `.zip` + `application/zip` như Dart; ghi **KI-24** ở TH-08; ca SQL **E46** |
| Q3 | `tax_code` cho `previewPublished`: Dart đọc `creds['tax_code']`; `TenantMisaClientFactory.getForTenant` (7-E1) chỉ trả `{client, baseUrl}` | `getForTenant` trả thêm `taxCode: string \| null` (= `row.tax_code`, cả nhánh dùng lại client cũ). Thêm trường, không đổi trường cũ ⇒ 4 chỗ gọi (`sync_capabilities.ts:58`, `issuance_provider.ts:67`, `:115`, `:149`) không phải sửa. Task 2 chạy `impact` |
| Q4 | Lỗi MISA "không phản hồi" (Dart `ProviderCallAmbiguousException` → handler ném `StateError(safeErrorCode)`) | `class ProviderCallAmbiguousError extends Error { constructor(readonly safeErrorCode: string, message: string) }` trong `handlers/issued_invoice/errors.ts`; handler bắt rồi `throw new Error(safeErrorCode)`. Không dùng `ProviderUnavailableError` của 7-E1 (hàng đợi xử lý như nhau; giữ đúng chuỗi lỗi Dart). Outcome `ambiguous` ⇒ `throw new Error(safeErrorCode)` |
| Q5 | Chuỗi lỗi ghi DB | Như 7-E2a Q5: `String(e)` của TS (`Error: x`) khác Dart (`Bad state: x`) — chỉ vào `failure_message` của dead-letter, `internal_commands.error`, log ⇒ không ép giống. **Mã** (`PROVIDER_AUTH_FAILED`, `INVOICE_SERIES_INVALID`, `PROVIDER_TAX_CODE_MISSING`, `DOCUMENT_UNAVAILABLE`, `DOCUMENT_CONTENT_INVALID`, `PROVIDER_IDENTITY_MISMATCH`, `PROVIDER_RESULT_UNDETERMINED`, `UNKNOWN_PROVIDER_FAILURE`, `NOT_FOUND`, `MISMATCH`, `PROVIDER_STATUS_NOT_FOUND`, `PS_*_ES_*`, `NOT_PUBLISHED`, `PUBLISHED`, `UNKNOWN_*`) và chuỗi lỗi storage (`DOCUMENT_CONTENT_INVALID: …`, `SYSTEM_ERROR: storage upload failed`, `SYSTEM_ERROR: storage object checksum mismatch for <path>`) giữ từng ký tự |
| Q6 | `RecordProviderObservationCommand` (Dart chạy qua bus + validator) | Như 7-E2a Q6: hàm thường `recordProviderObservation(gateway, input)` trong `record_provider_observation.ts`, validator chép vào cùng tệp (ném trước khi gọi gateway); `source: 'WORKER'` bỏ (mapper Dart không gửi `p_source`, RPC không có tham số này) |
| Q7 | Kiểu kết quả Dart (`sealed class`), `List<int>` bytes, `DateTime` | Như 7-E2a Q7: union có `kind`; bytes → `Uint8Array`; `DateTime` → `Date`, gửi RPC bằng `toISOString()`; hết hạn link = `now() + 5 phút` |
| Q8 | Storage trong Edge Function | Interface hẹp `DocumentBucket { upload(path, bytes, contentType): Promise<'created' \| 'duplicate'>; download(path): Promise<Uint8Array> }` để test được (thay `FakeInvoiceDocumentStorageSupabase` của Dart). Bản thật `createSupabaseDocumentBucket(client, 'einvoice-documents')`: `upload(path, bytes, { contentType, upsert: false })`; lỗi có mã trạng thái `409` hoặc `400` (đọc `statusCode` rồi `status`, so dạng chuỗi — như Dart `_isDuplicateObjectError`) ⇒ `'duplicate'`; lỗi khác ⇒ `throw new Error('SYSTEM_ERROR: storage upload failed')`. Checksum = hex SHA-256 (Web Crypto) — cùng chuỗi `crypto.sha256` của Dart. `documentVersion` luôn 1 (Dart handler gán cứng) |

## 3. Hiện trạng (đo 2026-11-08)

| Thứ | Ở đâu | Ghi chú |
|---|---|---|
| Xếp `einvoice.fetch_official_view` | `20261031010:149-163` (`request_official_invoice_view`) | payload `{tenant_id, electronic_invoice_id, request_id, correlation_id = request_id}` |
| Xếp `einvoice.download_invoice_document` | `20261031011:206-221` (`request_invoice_document`) | payload `{tenant_id, electronic_invoice_id, document_type ('PDF' \| 'XML'), request_id, correlation_id = request_id}` |
| Xếp `einvoice.poll_provider_observation` | `20261031012:90-158` (`request_provider_observation_refresh`, chỉ `service_role`) | payload `{tenant_id, electronic_invoice_id, provider_connection_id, trigger_id, correlation_id = command id}`; **không có nơi nào gọi** (chỉ test hợp đồng Dart) |
| 6 RPC | `load_official_view_operation_context(p_tenant_id, p_electronic_invoice_id, p_request_id)` `…010:245`; `record_official_invoice_view_result(p_tenant_id, p_electronic_invoice_id, p_request_id, p_status, p_viewer_url, p_viewer_token, p_expires_at, p_failure_code, p_failure_message, p_failure_source)` `…010:289`; `load_invoice_document_operation_context(p_tenant_id, p_electronic_invoice_id, p_document_type, p_request_id)` `…011:340`; `record_invoice_document_result(p_tenant_id, p_electronic_invoice_id, p_document_type, p_request_id, p_status, p_storage_reference, p_checksum, p_failure_code, p_failure_message, p_failure_source)` `…011:388`; `load_provider_observation_context(p_tenant_id, p_command_id)` `…012:161` (không thấy ⇒ `raise NOT_FOUND`); `record_provider_observation(p_tenant_id, p_electronic_invoice_id, p_provider_state_code, p_provider_state_description, p_provider_reference, p_observed_at, p_deduplication_key, p_details_snapshot, p_correlation_id)` `…012:215` | cả 6 `grant` chỉ `service_role` (`…010:381-385`, `…011:478-482`, `…012:392-396`) |
| Tham số / cột đọc về | `electronic_invoice_rpc_mapper.dart:33-99` (tham số; `p_viewer_url`, `p_viewer_token`, `p_expires_at`, `p_failure_code`, `p_failure_message`, `p_storage_reference`, `p_checksum` **chỉ gửi khi khác null**, `p_failure_source` luôn gửi), `:205-247` (cột context), `:249-265` (`mapDocumentStatus`), `:275-285` (`'PROVIDER'` / `'INTERNAL'`, `'PDF'` / `'XML'`), `:300-315` (`record_provider_observation`) | chép đúng tên `p_*` và tên cột |
| Bucket `einvoice-documents` | `20261031011:40-51` | riêng tư, 20 MiB (= `maxBytes` của chính sách nội dung), `allowed_mime_types = ['application/pdf','application/xml','text/xml']` — **thiếu `application/zip`** (Q2); policy `select` cho `authenticated` có quyền `einvoice.download_document` (`:53-67`); `service_role` bỏ qua RLS khi upload |
| `TenantMisaClientFactory.getForTenant` | `handlers/misa_client_factory.ts:36-56` | trả `{client, baseUrl} \| null`; `CredentialsRow.tax_code` có sẵn (`:4-9`) |
| `registry.ts` / `index.ts` (7-E2a) | `handlers/registry.ts:10-29`; `index.ts:79-96` | `HandlerDeps = SyncCapabilitiesDeps & { issuance }`; `buildDeadLetters` trả `createIssuanceDeadLetters(...)` |
| Client giả | `misa/fake_me_invoice_client.ts:43-80` | có hàng đợi kịch bản + biến `last*` cho `previewPublished` / `download` / `getStatus` (thay `FakeMeInvoiceClient` Dart) |
| Test SQL | `supabase/tests/einvoice_th08.sql` | ca cuối E44 lần 4 (`:1051-1075`), `raise notice 'einvoice_th08: OK'` ở `:1077` ⇒ ca mới **E46** (E45 đã dùng) đặt trước `:1077` |
| KI mới nhất ở TH-08 | `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md:1515` (KI-23) | KI mới = **KI-24** |

Không có bảng "Đang làm gì": plan không xoá / tách code cũ (xoá ở 7-C); test parity chính là các ca chép từ Dart.

## 4. Thiết kế

### G1. Kiểu chung — `handlers/issued_invoice/outcomes.ts`, `errors.ts`

```ts
export type DocumentType = 'PDF' | 'XML'
export type DocumentStatus = 'PENDING' | 'AVAILABLE' | 'FAILED' | 'CHECK_REQUIRED'
export type FailureSource = 'PROVIDER' | 'INTERNAL'

export interface ProviderContext { tenantId: string; providerConnectionId: string; electronicInvoiceId: string
  providerInvoiceReference: string; invoiceSeries: string; operationId: string }

export type OfficialViewOutcome =
  | { kind: 'success'; viewerUrl: string; expiresAt: Date; providerReference: string | null }
  | { kind: 'checkRequired'; safeErrorCode: string; providerReference: string | null }
  | { kind: 'definiteFailure'; failureCode: string; failureMessage: string | null; providerReference: string | null }
  | { kind: 'ambiguous'; safeErrorCode: string }

export type DocumentOutcome =
  | { kind: 'success'; bytes: Uint8Array; providerReference: string | null }
  | { kind: 'checkRequired'; safeErrorCode: string; providerReference: string | null }
  | { kind: 'definiteFailure'; failureCode: string; failureMessage: string | null }
  | { kind: 'ambiguous'; safeErrorCode: string }

export type ObservationOutcome =
  | { kind: 'found'; providerStateCode: string; safeDescription: string; observedAt: Date; detailsSnapshot: Record<string, unknown>; providerReference: string | null }
  | { kind: 'notFound' | 'mismatch'; providerStateCode: string; safeDescription: string; observedAt: Date; providerReference: string | null }
  | { kind: 'ambiguous'; safeErrorCode: string }

export const OFFICIAL_VIEW_LEASE_MINUTES = 5
export const OBSERVATION_DETAIL_KEYS: readonly string[]  // 9 khoá của ProviderObservationDetailsPolicy.allowedKeys
```

Trường / giá trị mặc định chép đúng `official_view_provider_outcome.dart`, `invoice_document_provider_outcome.dart`, `provider_observation_outcome.dart` (đọc trước khi viết; trường nào Dart có mà ở trên thiếu thì thêm, ghi Kết quả).

`errors.ts`: `ProviderCallAmbiguousError` (Q4).

### G2. Hàm thuần

- `provider_call_support.ts` — chép `MeInvoiceProviderCallSupport` 1:1: `isTransportAmbiguous`, `isAuthOrConfigRejection`, `isEmptyProviderPayload`, `safeErrorCode` (regex `^[A-Za-z][A-Za-z0-9_]{0,63}`, mặc định `UNKNOWN_PROVIDER_FAILURE`), `throwIfTransportAmbiguous` (ném `ProviderCallAmbiguousError(safeErrorCode(error), error)`).
- `document_content_policy.ts` — chép `InvoiceDocumentContentPolicy`: `MAX_BYTES = 20 * 1024 * 1024`, `validate(type, bytes): string | null`, `isZip(bytes)`, `looksLikeXml` (BOM UTF-8 / UTF-16, bỏ khoảng trắng + byte 0, ZIP ⇒ hợp lệ).
- `official_view_classifier.ts` — `classifyOfficialView({ result: MeInvoiceResult<string>, providerInvoiceReference, now }): OfficialViewOutcome`; chép đúng `me_invoice_official_view_classifier.dart` (thứ tự: transport ⇒ ném, auth ⇒ `checkRequired PROVIDER_AUTH_FAILED`, payload rỗng ⇒ `definiteFailure DOCUMENT_UNAVAILABLE` có `providerReference`, còn lại ⇒ `checkRequired safeErrorCode`; thành công mà `MeInvoiceViewUrlPolicy.tryParse` null ⇒ `definiteFailure DOCUMENT_UNAVAILABLE` **không** có `providerReference`).
- `document_classifier.ts` — `classifyDocument({ result, documentType, providerInvoiceReference }): DocumentOutcome`; chép đúng `me_invoice_document_classifier.dart` (gồm `PROVIDER_IDENTITY_MISMATCH` khi `transactionId` khác và không rỗng; chính sách nội dung ⇒ `checkRequired`).
- `observation_classifier.ts` — `classifyObservation({ result, providerInvoiceReference, now }): ObservationOutcome`; chép đúng `me_invoice_observation_classifier.dart` (`PS_<n>_ES_<n>` / `UNKNOWN`, mô tả theo `publishStatus`, `observedAt = publishedTime ?? now`, `detailsSnapshot` chỉ các khoá có giá trị, `publishedTime` ⇒ `toISOString()`; lỗi không phải transport ⇒ `ambiguous`).

### G3. `issued_invoice_provider.ts`

```ts
export interface IssuedInvoiceProvider {
  fetchOfficialView(ctx: ProviderContext): Promise<OfficialViewOutcome>
  downloadDocument(ctx: ProviderContext, documentType: DocumentType): Promise<DocumentOutcome>
  observe(ctx: ProviderContext): Promise<ObservationOutcome>
}
export function createIssuedInvoiceProvider(deps: { clients: TenantMisaClientFactory; now?: () => Date
  log?: (event: string, data: Record<string, unknown>) => void }): IssuedInvoiceProvider
```

Chép `me_invoice_electronic_invoice_provider_adapter.dart:58-217`. Thứ tự giữ nguyên: `tryFromInvSeries` null ⇒ `INVOICE_SERIES_INVALID` (official / document: `checkRequired`; observe: `ambiguous`) → `getForTenant` null ⇒ `PROVIDER_AUTH_FAILED` (cùng kiểu outcome như trên) → (chỉ official) `taxCode?.trim()` rỗng ⇒ `checkRequired PROVIDER_TAX_CODE_MISSING` → gọi client → bộ phân loại. `download`: `PDF` ⇒ `MeInvoiceDownloadDataType.pdf`, `XML` ⇒ `.xml`. `getStatus`: `ids: [ref]`, `inputType: MeInvoiceStatusInputType.transactionId`. Lỗi `getForTenant` (RPC) để ném nguyên.

Log (thay `_logProviderFailure`): `log('misa_resource_failed', { operation: 'publishview' | 'download(pdf)' | 'download(xml)', invoiceSeries, invoiceWithCode, invoiceCalcu, providerReference, detail })` — `detail` cắt 400 ký tự + `…`; khi tải thành công mà không có byte: `detail = 'items=<n> without document bytes item={<diagnostics>}'`. Không log mật khẩu / token / tên đăng nhập / byte tài liệu.

### G4. `document_storage.ts`

```ts
export interface DocumentBucket {
  upload(path: string, bytes: Uint8Array, contentType: string): Promise<'created' | 'duplicate'>
  download(path: string): Promise<Uint8Array>
}
export interface StoredDocument { storageReference: string; checksum: string; contentType: string; fileName: string; fileSize: number }
export const DOCUMENT_BUCKET = 'einvoice-documents'
export function createDocumentStorage(bucket: DocumentBucket): {
  store(i: { tenantId: string; electronicInvoiceId: string; documentType: DocumentType; documentVersion: number; bytes: Uint8Array }): Promise<StoredDocument>
}
export function createSupabaseDocumentBucket(client: SupabaseClient, bucketName?: string): DocumentBucket
export async function sha256Hex(bytes: Uint8Array): Promise<string>
```

Chép `SupabaseInvoiceDocumentStoragePort.store`: kiểm nội dung (lỗi ⇒ `throw new Error('DOCUMENT_CONTENT_INVALID: <mã>')`); `checksum = sha256Hex`; đuôi `pdf` / `zip` / `xml`; content-type `application/pdf` / `application/zip` / `application/xml`; đường dẫn `${tenantId}/${electronicInvoiceId}/${documentType.toLowerCase()}/v${documentVersion}/${checksum}.${ext}`; `duplicate` ⇒ `download` + so checksum, lệch ⇒ `throw new Error(\`SYSTEM_ERROR: storage object checksum mismatch for ${path}\`)`. `createSupabaseDocumentBucket` theo Q8 (không test đơn vị, review đối chiếu).

### G5. Gateway — `gateways.ts`, `supabase_gateways.ts`

```ts
export interface OfficialViewContext { tenantId: string; electronicInvoiceId: string; requestId: string; status: DocumentStatus
  providerConnectionId: string; providerInvoiceReference: string; invoiceSeries: string }
export interface DocumentContext extends OfficialViewContext { documentType: DocumentType }
export interface ObservationContext { commandId: string; tenantId: string; electronicInvoiceId: string; providerConnectionId: string
  providerInvoiceReference: string; invoiceSeries: string; triggerId: string; correlationId: string }
export interface IssuedInvoiceGateway {
  loadOfficialViewContext(tenantId: string, electronicInvoiceId: string, requestId: string): Promise<OfficialViewContext | null>
  loadDocumentContext(tenantId: string, electronicInvoiceId: string, documentType: DocumentType, requestId: string): Promise<DocumentContext | null>
  loadObservationContext(tenantId: string, commandId: string): Promise<ObservationContext | null>
  recordOfficialViewResult(r: { tenantId: string; electronicInvoiceId: string; requestId: string; status: DocumentStatus
    viewerUrl?: string; expiresAt?: Date; failureCode?: string; failureMessage?: string | null; failureSource?: FailureSource }): Promise<void>
  recordDocumentResult(r: { tenantId: string; electronicInvoiceId: string; documentType: DocumentType; requestId: string; status: DocumentStatus
    storageReference?: string; checksum?: string; failureCode?: string; failureMessage?: string | null; failureSource?: FailureSource }): Promise<void>
  recordProviderObservation(r: { tenantId: string; electronicInvoiceId: string; providerStateCode: string; safeDescription: string | null
    providerReference: string | null; observedAt: Date; deduplicationKey: string; detailsSnapshot: Record<string, unknown>; correlationId: string }): Promise<void>
}
export interface IssuedInvoiceDeps { provider: IssuedInvoiceProvider; gateway: IssuedInvoiceGateway; storage: ReturnType<typeof createDocumentStorage> }
```

`supabase_gateways.ts`: `createSupabaseIssuedInvoiceGateway(client): IssuedInvoiceGateway`; mọi hàm `client.schema('einvoice').rpc(<tên>, <tham số theo mapper Dart, mục 3>)`; `error` ⇒ `throw new Error(\`${tên}: ${error.message}\`)`; `load*` không có dòng ⇒ `null`; trạng thái / loại tài liệu lạ ⇒ ném như Dart `mapDocumentStatus` / `mapDocumentType`. Viewer token không dùng (Dart không gán). Không test đơn vị (như 7-E2a); review đối chiếu bảng mục 3.

### G6. Handler + dead-letter

Mỗi handler là `create…Handler(deps: IssuedInvoiceDeps): CommandHandler`. Payload đọc từ `ctx.command.payload`; khoá bắt buộc thiếu / sai kiểu ⇒ `throw new Error('<command_type> payload missing <key>')`.

- `fetch_official_view.ts` — chép `fetch_official_invoice_view_command_handler.dart:25-84`: context null hoặc khác `PENDING` ⇒ return; `ProviderContext.operationId = requestId`; `ProviderCallAmbiguousError` ⇒ `throw new Error(e.safeErrorCode)`; `success` ⇒ `AVAILABLE` + `viewerUrl` + `expiresAt`; `checkRequired` ⇒ `CHECK_REQUIRED` + `failureCode = safeErrorCode`, `PROVIDER`; `definiteFailure` ⇒ `FAILED` + mã + thông điệp, `PROVIDER`; `ambiguous` ⇒ ném.
- `download_invoice_document.ts` — chép `download_invoice_document_command_handler.dart:29-108`: `document_type` đọc `toUpperCase()`, khác `PDF` / `XML` ⇒ `throw new Error('Unknown document type: <raw>')`; `success` ⇒ `storage.store({…, documentVersion: 1})` rồi `AVAILABLE` + `storageReference` + `checksum`; các nhánh còn lại như official view.
- `record_provider_observation.ts` — `recordProviderObservation(gateway, input)` (Q6): validator chép `record_provider_observation_command_validator.dart` (6 trường bắt buộc không rỗng, `detailsSnapshot` chỉ khoá trong `OBSERVATION_DETAIL_KEYS` ⇒ `throw new Error('detailsSnapshot key not allowed: <key>')`).
- `poll_provider_observation.ts` — chép `poll_provider_observation_command_handler.dart:28-115`: kiểm `trigger_id` không rỗng sau `trim` (Dart `fromJson` ném `FormatException('trigger_id must not be blank')` ⇒ TS `throw new Error('trigger_id must not be blank')`); `loadObservationContext(tenant, ctx.command.commandId)` null ⇒ return; `operationId = commandId`; `found` / `notFound` / `mismatch` ⇒ `recordProviderObservation` với `deduplicationKey = \`provider_observation:${commandId}\``, `correlationId = context.correlationId`, `detailsSnapshot = {}` cho `notFound` / `mismatch`; `ambiguous` hoặc `ProviderCallAmbiguousError` ⇒ `throw new Error(safeErrorCode)`.
- `dead_letters.ts` — `createIssuedInvoiceDeadLetters(gateway): Record<string, DeadLetterHandler>` trả 2 khoá:
  - `'einvoice.fetch_official_view'`: thiếu / rỗng `electronic_invoice_id` hoặc `request_id` ⇒ bỏ qua; `loadOfficialViewContext` null hoặc khác `PENDING` ⇒ bỏ qua; còn lại ghi `CHECK_REQUIRED`, `PROVIDER_RESULT_UNDETERMINED`, `failureMessage = String(error)`, `INTERNAL`.
  - `'einvoice.download_invoice_document'`: như trên, thêm `document_type` không phải `PDF` / `XML` (không phân biệt hoa thường) ⇒ bỏ qua.

### G7. Nối vào 7-E1 / 7-E2a

- `handlers/misa_client_factory.ts`: kiểu trả `{ client; baseUrl; taxCode: string | null }`; cả 2 nhánh `return` thêm `taxCode: row.tax_code` (Q3).
- `handlers/registry.ts`: `HandlerDeps` thêm `issuedInvoice: IssuedInvoiceDeps`; `buildHandlers` trả thêm `'einvoice.fetch_official_view'`, `'einvoice.download_invoice_document'`, `'einvoice.poll_provider_observation'`; `buildDeadLetters` trả `{ ...createIssuanceDeadLetters(deps.issuance.gateways), ...createIssuedInvoiceDeadLetters(deps.issuedInvoice.gateway) }`.
- `index.ts`: thêm `issuedInvoice: { provider: createIssuedInvoiceProvider({ clients: clientFactory }), gateway: createSupabaseIssuedInvoiceGateway(client), storage: createDocumentStorage(createSupabaseDocumentBucket(client)) }` vào `deps` (dựng mỗi lần gọi như `issuance`).
- Test 7-E1 / 7-E2a có dựng `HandlerDeps` (vd. `handlers/issuance/dead_letters_test.ts` ca đăng ký, `processor_integration_test.ts`) ⇒ thêm `issuedInvoice` giả; ca `registers dead letters for preview and publish` đổi mong đợi thành 4 khoá (ghi Kết quả).

### G8. Migration + SQL

- `supabase/migrations/20261031011_einvoice_document_operations_rpcs.sql:46`: `array['application/pdf','application/xml','text/xml']` → `array['application/pdf','application/xml','text/xml','application/zip']`. Chỉ dòng đó (`on conflict … do update` đã cập nhật `allowed_mime_types` nên DB cũ cũng nhận khi chạy lại).
- `supabase/tests/einvoice_th08.sql` **E46**: `select allowed_mime_types from storage.buckets where id = 'einvoice-documents'` ⇒ chứa đủ `application/pdf`, `application/xml`, `text/xml`, `application/zip`; `public = false`; `file_size_limit = 20971520`. Biến mới khai báo ở `declare` (vd. `v_mimes_e46 text[]`), tên không trùng biến 7-E1 / 7-E2a.

## 5. Các bước

**Ràng buộc chung** (mọi task):
- Lệnh test: `deno test supabase/functions/einvoice-processor` (từ gốc repo), không cần quyền mạng. Lệnh kiểm: `deno check supabase/functions/einvoice-processor/index.ts`, `deno lint supabase/functions/einvoice-processor`.
- Test chép từ Dart: **giữ tên ca** (`Deno.test('<group> <ca>', …)`), giữ dữ liệu đầu vào và giá trị so sánh; ca phải đổi (kiểu thời gian / byte, chuỗi `String(e)` theo Q5, cách bắt lỗi) ghi Kết quả. Client giả: `FakeMeInvoiceClient` (`misa/fake_me_invoice_client.ts`) + hàng đợi kịch bản; `TenantMisaClientFactory` dựng với `CredentialsReader` giả và `create` trả client giả (như `issuance_provider_test.ts` của 7-E2a).
- Mỗi task: viết test trước, chạy thấy đỏ, viết mã, chạy thấy xanh.
- Test ở `supabase/functions/einvoice-processor/handlers/issued_invoice/*_test.ts`.

| Dart (`modules/einvoice/`) | TS test | Ca | Task |
|---|---|---|---|
| `domain/test/electronic_invoice/invoice_document_content_policy_test.dart` | `document_content_policy_test.ts` | 2 | 1 |
| `infrastructure/test/adapters/misa/me_invoice_observation_classifier_test.dart` + group `MeInvoiceObservationClassifier` của `me_invoice_electronic_invoice_provider_adapter_test.dart` (`:370-443`) | `observation_classifier_test.ts` | 1 + 4 | 1 |
| group `MeInvoiceElectronicInvoiceProviderAdapter` của `me_invoice_electronic_invoice_provider_adapter_test.dart` (`:133-368`) | `issued_invoice_provider_test.ts` | 13 | 2 |
| group `SupabaseInvoiceDocumentStoragePort` của `infrastructure/test/storage/supabase_invoice_document_storage_port_test.dart` | `document_storage_test.ts` | 3 | 3 |
| `application/test/electronic_invoice/s4_worker_handlers_test.dart` — 3 ca serialization (Q1) + group `FetchOfficialInvoiceViewCommandHandler` (3) + `DownloadInvoiceDocumentCommandHandler` (2) | `fetch_official_view_test.ts`, `download_invoice_document_test.ts`, `poll_provider_observation_test.ts` | 3 + 3 + 2 | 4 |
| `application/test/electronic_invoice/record_provider_observation_command_handler_test.dart` | `record_provider_observation_test.ts` | 3 | 4 |
| | **Tổng chép** | **34** | |

### Task 1: Kiểu chung + hàm thuần (G1, G2)

**Files:** Create: `handlers/issued_invoice/outcomes.ts`, `errors.ts`, `provider_call_support.ts`, `document_content_policy.ts`, `official_view_classifier.ts`, `document_classifier.ts`, `observation_classifier.ts`; Test: `document_content_policy_test.ts` (2 + 1), `observation_classifier_test.ts` (5)

**Interfaces — Consumes:** `misa/mod.ts` (`MeInvoiceResult`, `MeInvoiceInvoiceDataPublished`, `MeInvoiceInvoiceStatus`, `MeInvoiceViewUrlPolicy`). **Produces:** mọi kiểu / hằng / hàm ở G1, G2.

- [x] **1.1** Chép 2 tệp test (bảng trên). Thêm 1 ca `document content policy accepts zipped XML` — `validate('XML', [0x50,0x4B,0x03,0x04, …])` ⇒ `null`, `isZip` ⇒ `true` (Q2; Dart không có ca này). Chạy, thấy đỏ.
- [x] **1.2** Viết 7 tệp theo G1, G2; chạy, thấy 8 ca xanh. `official_view_classifier` / `document_classifier` được phủ qua test của Task 2 (Dart cũng vậy).
- [x] **1.3** Ghi Kết quả: số dòng TS / Dart từng tệp; trường outcome nào thêm so với G1.

### Task 2: `issued_invoice_provider.ts` + `taxCode` (G3, G7 phần factory)

**Files:** Create: `handlers/issued_invoice/issued_invoice_provider.ts`; Modify: `handlers/misa_client_factory.ts` (kiểu trả + 2 `return`), `handlers/misa_client_factory_test.ts` (thêm 1 ca); Test: `issued_invoice_provider_test.ts` (13)

**Interfaces — Consumes:** Task 1; `TenantMisaClientFactory`, `CredentialsReader`, `MisaEnv` (7-E1). **Produces:** `IssuedInvoiceProvider`, `createIssuedInvoiceProvider`; `getForTenant(...).taxCode`.

- [x] **2.1** `node .gitnexus/run.cjs analyze` (hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu bị sửa), rồi `impact({target: "getForTenant", direction: "upstream"})`, `impact({target: "buildHandlers", direction: "upstream"})`, `impact({target: "buildDeadLetters", direction: "upstream"})`. Kỳ vọng: `getForTenant` ← `sync_capabilities.ts`, `issuance_provider.ts` (+ test); `buildHandlers` / `buildDeadLetters` ← `index.ts` (+ test 7-E2a). Ghi Kết quả (không chạy được ⇒ ghi lý do, dùng `grep -rn` thay). HIGH / CRITICAL ⇒ dừng, báo người dùng.
- [x] **2.2** `misa_client_factory_test.ts` thêm ca `getForTenant returns tax code from credentials row` (cả lần đầu và lần dùng lại client). Chép 13 ca adapter: Dart dựng `_FakeEinvoiceRpcSupabase` trả dòng mật khẩu + `setClientForTesting` ⇒ TS dựng `TenantMisaClientFactory(env, credentialsReaderGiả, () => fakeClient)`; `now: () => new Date(Date.UTC(2026, 7, 31, 9))`; ca `transport failure throws ProviderCallAmbiguousException` ⇒ `assertRejects(…, ProviderCallAmbiguousError)`. Chạy, thấy đỏ.
- [x] **2.3** Sửa `misa_client_factory.ts`, viết `issued_invoice_provider.ts` theo G3; chạy, thấy xanh; chạy lại cả `handlers/` ⇒ test 7-E1 / 7-E2a vẫn xanh.

### Task 3: Lưu tài liệu (G4)

**Files:** Create: `handlers/issued_invoice/document_storage.ts`, `fake_bucket.ts` (bản giả `DocumentBucket`: giữ đối tượng trong `Map`, lần upload thứ hai cùng đường dẫn trả `'duplicate'`, ghi `lastPath` / `lastContentType`, đếm lần gọi); Test: `document_storage_test.ts` (3 + 2)

**Interfaces — Consumes:** Task 1 (`validate`, `isZip`). **Produces:** `DocumentBucket`, `StoredDocument`, `DOCUMENT_BUCKET`, `createDocumentStorage`, `createSupabaseDocumentBucket`, `sha256Hex`, `FakeDocumentBucket`.

- [x] **3.1** Chép 3 ca (Dart `upsert: false` ⇒ TS không kiểm vì interface không có `upsert`; kiểm `lastContentType`). Thêm 2 ca: `stores zipped XML with zip extension and application/zip` — đường dẫn `…/xml/v1/<sha>.zip`, content-type `application/zip` (Q2); `throws checksum mismatch when existing object differs` — bucket giả có sẵn byte khác ở đúng đường dẫn ⇒ `assertRejects` với thông điệp `SYSTEM_ERROR: storage object checksum mismatch for <path>`. Chạy, thấy đỏ.
- [x] **3.2** Viết `document_storage.ts`, `fake_bucket.ts`; chạy, thấy 5 ca xanh. `sha256Hex('%PDF-1.4 test')` so với giá trị hex tính sẵn (ghi giá trị vào test, tính bằng `shasum -a 256`).
- [x] **3.3** Viết `createSupabaseDocumentBucket` (Q8, không test đơn vị). Ghi Kết quả: cách đọc mã trạng thái lỗi của `@supabase/storage-js` bản đang dùng (`statusCode` / `status`) — đọc kiểu trong `npm:@supabase/supabase-js@2` mà `deno.lock` khoá.

### Task 4: Gateway + 3 handler + ghi quan sát (G5, G6)

**Files:** Create: `handlers/issued_invoice/gateways.ts`, `supabase_gateways.ts`, `fake_gateways.ts` (`FakeIssuedInvoiceGateway` ghi mọi lời gọi theo thứ tự, context dựng sẵn; `FakeIssuedInvoiceProvider` trả outcome dựng sẵn hoặc ném lỗi dựng sẵn), `fetch_official_view.ts`, `download_invoice_document.ts`, `record_provider_observation.ts`, `poll_provider_observation.ts`; Test: `fetch_official_view_test.ts` (1 + 3 + 1 mới), `download_invoice_document_test.ts` (1 + 2 + 2 mới), `poll_provider_observation_test.ts` (1 + 3 mới), `record_provider_observation_test.ts` (3)

**Interfaces — Consumes:** Task 1–3; `CommandHandler`, `CommandContext`, `ClaimedCommand` (7-E1). **Produces:** mọi kiểu G5; `createSupabaseIssuedInvoiceGateway`; `createFetchOfficialViewHandler`, `createDownloadInvoiceDocumentHandler`, `createPollProviderObservationHandler`, `recordProviderObservation`; `FakeIssuedInvoiceGateway`, `FakeIssuedInvoiceProvider`.

- [x] **4.1** Chép test. Ca serialization (Q1) ⇒ kiểm handler đọc payload SQL ở mục 3: `FetchOfficialInvoiceViewCommand round-trips without row id` ⇒ handler gọi `loadOfficialViewContext(tenant, 'ei-1', 'req-1')`; `DownloadInvoiceDocumentCommand round-trips document type wire values` ⇒ payload `document_type: 'xml'` (chữ thường) ⇒ `loadDocumentContext(…, 'XML', …)`; `PollProviderObservationCommand rejects blank triggerId` ⇒ `trigger_id: '  '` ⇒ `assertRejects(…, 'trigger_id must not be blank')`, không gọi gateway. Ca `MISA ambiguous throws…` ⇒ `assertRejects`, gateway không nhận `record*`. Ca mới:
  - `fetch official view skips when operation is no longer PENDING` — context `AVAILABLE` ⇒ không gọi provider, không ghi.
  - `download stores document then records AVAILABLE with storage reference and checksum` — provider `success` (byte `%PDF-…`) ⇒ `FakeDocumentBucket` có 1 đối tượng ở `tenant-1/ei-1/pdf/v1/<sha>.pdf`, `recordDocumentResult` `AVAILABLE` với cùng đường dẫn + checksum.
  - `download rejects unknown document type before loading context` — `document_type: 'DOCX'` ⇒ ném `Unknown document type: DOCX`.
  - `poll observation records found fact with command-scoped deduplication key` — provider `found` ⇒ `recordProviderObservation` 1 lần, `deduplicationKey = 'provider_observation:<commandId>'`, `correlationId` = của context, `detailsSnapshot` giữ nguyên.
  - `poll observation does not record when MISA is ambiguous` — provider ném `ProviderCallAmbiguousError('PROVIDER_TIMEOUT', …)` ⇒ ném `PROVIDER_TIMEOUT`, không ghi.
  - `poll observation returns quietly when context is missing` — `loadObservationContext` trả null ⇒ không gọi provider.
  Chạy, thấy đỏ.
- [x] **4.2** Viết `gateways.ts`, `fake_gateways.ts`, 4 tệp handler / hàm; chạy, thấy xanh.
- [x] **4.3** Viết `supabase_gateways.ts` (G5). Ghi Kết quả bảng: hàm TS → tên RPC → tham số `p_*` (đánh dấu tham số chỉ gửi khi khác null) → nguồn mapper Dart (tệp:dòng).

### Task 5: Dead-letter + đăng ký + `index.ts` (G6, G7)

**Files:** Create: `handlers/issued_invoice/dead_letters.ts`; Modify: `handlers/registry.ts`, `index.ts`, các test 7-E2a dựng `HandlerDeps` (G7); Test: `handlers/issued_invoice/dead_letters_test.ts` (4 + 1), `handlers/issued_invoice/processor_integration_test.ts` (3)

**Interfaces — Consumes:** Task 1–4; `runInvocation`, `FakeQueueRpc`, `cmd()` (7-E1 / 7-E2a). **Produces:** `createIssuedInvoiceDeadLetters`, `HandlerDeps.issuedInvoice`.

- [x] **5.1** `dead_letters_test.ts` (Dart không có test đơn vị cho 2 handler này ⇒ ca mới):
  - `official view dead letter records CHECK_REQUIRED for pending operation` — context `PENDING` ⇒ `recordOfficialViewResult` `CHECK_REQUIRED`, `PROVIDER_RESULT_UNDETERMINED`, `failureMessage = String(error)`, `INTERNAL`.
  - `official view dead letter skips when operation already settled` — context `AVAILABLE` ⇒ không ghi.
  - `document dead letter records CHECK_REQUIRED for pending operation` — như trên với `recordDocumentResult`, đúng `documentType`.
  - `document dead letter skips unknown document type` — `document_type: 'DOCX'` ⇒ không gọi `loadDocumentContext`.
  - `registers dead letters for issuance and issued invoice commands` — `Object.keys(buildDeadLetters(deps)).sort()` = `['einvoice.download_invoice_document', 'einvoice.fetch_official_view', 'einvoice.preview_invoice', 'einvoice.publish_invoice']`.
- [x] **5.2** `processor_integration_test.ts` — 3 ca (`runInvocation` + `FakeQueueRpc` + handler thật dựng từ bản giả):
  - `official view failure on second attempt fails the command and records CHECK_REQUIRED` — `retryCount: 1`, provider ném `ProviderCallAmbiguousError` ⇒ `fail` 1 lần (không `retryOrDeadLetter`), dead-letter ghi `CHECK_REQUIRED` (giới hạn 2 lượt của `attempt_policy.ts`).
  - `document failure on first attempt is retried without dead-letter` — `retryCount: 0`, provider ném ⇒ `retryOrDeadLetter` 1 lần trả `RETRY`, không `record*`.
  - `document storage error on third attempt fails and records CHECK_REQUIRED` — `retryCount: 2`, provider `success` nhưng `FakeDocumentBucket.upload` ném `SYSTEM_ERROR: storage upload failed` ⇒ `fail` + dead-letter `CHECK_REQUIRED`.
- [x] **5.3** Chạy, thấy đỏ; viết `dead_letters.ts`, sửa `registry.ts`, `index.ts`, test 7-E2a theo G7; chạy, thấy xanh.
- [x] **5.4** `deno check supabase/functions/einvoice-processor/index.ts`, `deno lint supabase/functions/einvoice-processor`, `deno test supabase/functions/einvoice-processor` — ghi số ca đạt / lỗi (tách: 7-E1 + 7-E2a, 7-E2b).
- [x] **5.5** `grep -rn -E "password|access_token|accessToken|username|bytes" supabase/functions/einvoice-processor/handlers/issued_invoice --include="*.ts" | grep -v "_test.ts" | grep -i -E "log\(|console"` ⇒ không dòng nào log bí mật hay byte tài liệu; ghi Kết quả.

### Task 6: Migration + SQL E46 + tài liệu + `detect_changes` + Kết quả

**Files:** Modify: `supabase/migrations/20261031011_einvoice_document_operations_rpcs.sql` (`:46`), `supabase/tests/einvoice_th08.sql` (`declare` + trước `:1077`), `docs/refactor/PLAN.md`, `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md`

- [x] **6.1** Sửa migration theo G8 (một dòng).
- [x] **6.2** Thêm E46 vào `einvoice_th08.sql` theo G8.
- [x] **6.3** PLAN.md: dòng **7-E2b** Làm ✅ + ngày + "(chưa commit; còn `db reset` + `einvoice_th08.sql` E46 — người dùng)".
- [x] **6.4** TH-08: thêm **KI-24** sau KI-23 (`:1515`) — "Bucket `einvoice-documents` không nhận `application/zip` trong khi MISA có thể trả XML nén ZIP ⇒ tải XML lỗi, hết 3 lượt thành `CHECK_REQUIRED` | Thêm `application/zip` vào `allowed_mime_types` (`…011`) | Đã sửa 7-E2b"; US-03.3 (quanh `:878`) thêm câu "Hiện chưa có nơi nào gọi `request_provider_observation_refresh` (không có nút, không có lịch) ⇒ bộ xử lý có handler nhưng chưa nhận việc".
- [x] **6.5** `node .gitnexus/run.cjs analyze` (lại) rồi `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory --scope all`: chỉ tệp trong plan; ghi số tệp / symbol / luồng / rủi ro, và số tệp mới chưa `git add` (lệnh không thấy — người dùng chạy lại sau `git add`, như 7-E2a). Hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu `analyze` sửa.

## 6. Review Focus (chưa ca nào chạy — phiên review soi)

1. **Bộ phân loại lệch Dart:** đổi thứ tự `isTransportAmbiguous` / `isAuthOrConfigRejection` / `isEmptyProviderPayload` (vd. lỗi chứa cả `unavailable` và `auth`) ⇒ lỗi tạm thời thành `CHECK_REQUIRED` vĩnh viễn hoặc ngược lại. Review đặt `provider_call_support.ts` và 3 bộ phân loại cạnh bản Dart.
2. **Lưu trùng / ghi đè tệp:** `upsert: false` + `duplicate` ⇒ so checksum. Kiểm `createSupabaseDocumentBucket` nhận đúng lỗi "đã có" của storage-js (409 / 400) và không coi mọi lỗi 400 khác (vd. MIME bị từ chối trước khi sửa KI-24) là "đã có" — Dart cũng gộp 400; nếu gộp thì `download` sẽ lỗi 404 ⇒ ném ⇒ thử lại: chấp nhận được, ghi nhận.
3. **Checksum:** `sha256Hex` phải là hex chữ thường 64 ký tự giống Dart `sha256.convert(...).toString()` — app so checksum khi tải về (TH-08 US-03.2 FR-04); sai định dạng ⇒ app báo lỗi lưu tệp.
4. **Bộ nhớ Edge Function:** tệp tối đa 20 MiB, MISA trả base64 ⇒ chuỗi + `Uint8Array` + bản tải về khi trùng ≈ 3 lần kích thước. Review xem có giữ bản sao thừa không.
5. **Lộ dữ liệu:** `detail` trong log (thân lỗi MISA, cắt 400 ký tự) và `String(error)` trong `failure_message` của dead-letter đi vào DB; review xem có chứa mật khẩu / token / dữ liệu người mua không.
6. **`taxCode` của client dùng lại:** nhánh trả client cũ trong `getForTenant` phải trả `taxCode` của dòng mật khẩu **vừa đọc**, không phải của lần tạo client.

## 7. Kiểm tra

### 7.1 Tự động
Task 5.4 (`deno check`, `deno lint`, `deno test`), Task 6.5 (`detect-changes`). Không có test Dart (plan không đổi app).

### 7.2 Việc của người dùng
- DB local: reset rồi `psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/einvoice_th08.sql` ⇒ `einvoice_th08: OK` (gồm E46). Ca nào FAIL ⇒ báo phiên sửa.
- (Tuỳ chọn, sau 7-E3) mở bản chính thức, tải PDF / XML trên MISA sandbox theo checklist 7-E3.

## 8. Rủi ro / lưu ý

- **Quan sát chưa có việc:** `request_provider_observation_refresh` chỉ `service_role` và không ai gọi ⇒ handler `poll_provider_observation` đúng nhưng chưa chạy trong thực tế. Không thêm lịch / nút (TH-08 US-03.3 FR-02: app không có màn); để nguyên như Dart.
- **Outbox chưa ai đọc:** `record_provider_observation` ghi `einvoice.provider_observation_attention_required` khi `NOT_FOUND` / sai lệch; chưa có ai nhận (TH-08 "Cảnh báo Theme 11"). Không chặn 7-E2b.
- **Sửa migration đã chạy:** `…011` đã ở Dev ⇒ người dùng reset Dev (quy ước sửa migration tại chỗ trước Prod). `on conflict do update` cũng cập nhật nếu chỉ chạy lại tệp.
- **Một lần tải chiếm nhiều thời gian:** MISA chờ tối đa 60 giây + upload Storage; ngân sách 90 giây của 7-E1 chỉ kiểm giữa các việc (7-E1 Review Focus 5).
- **Plan dựa trên code 7-E1 / 7-E2a tại `321adae58`:** nếu tên / chữ ký lệch, phiên code theo code thật và ghi lệch vào Kết quả.

## 9. Kết quả (phiên làm code ghi)

Mẫu cho mỗi task:

**Task N — ✅ / ⚠️**
- Tệp: `đường/dẫn.ts:1-N` (tạo mới / sửa, N dòng — đo bằng `wc -l` **sau** `deno fmt` nếu có chạy)
- Lệch plan + lý do:
- Ca test: lệnh + số ca đạt / tổng
- Impact (task có sửa symbol cũ): symbol → số chỗ gọi, rủi ro

**Task 1 — ✅**
- Tệp:
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/outcomes.ts:1-58` (58 dòng)
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/errors.ts:1-7` (7 dòng)
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/provider_call_support.ts:1-49` (49 dòng)
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/document_content_policy.ts:1-91` (91 dòng)
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/official_view_classifier.ts:1-61` (61 dòng)
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/document_classifier.ts:1-89` (89 dòng)
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/observation_classifier.ts:1-124` (124 dòng)
  - Test: `supabase/functions/einvoice-processor/handlers/issued_invoice/document_content_policy_test.ts:1-59` (59 dòng), `supabase/functions/einvoice-processor/handlers/issued_invoice/observation_classifier_test.ts:1-112` (112 dòng)
- Lệch plan + lý do: Có một lệch chủ động: thêm trường `documentType?: DocumentType | null` vào `ProviderContext` (trong plan ban đầu không liệt kê, nhưng Dart `ElectronicInvoiceProviderContextDto` có trường này, giúp tái dùng context và xác định loại tài liệu khi cần).
- Ca test: `deno test supabase/functions/einvoice-processor/handlers/issued_invoice/` đạt 8/8; toàn bộ `supabase/functions/einvoice-processor` đạt 257/257 (+8 ca mới).
- Impact: Không sửa symbol cũ (tạo tệp mới trong `handlers/issued_invoice/`).

**Task 2 — ✅**
- Tệp:
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/issued_invoice_provider.ts:1-187` (tạo mới, 187 dòng)
  - `supabase/functions/einvoice-processor/handlers/misa_client_factory.ts:1-63` (sửa, 63 dòng)
  - Test: `supabase/functions/einvoice-processor/handlers/issued_invoice/issued_invoice_provider_test.ts:1-239` (tạo mới, 239 dòng), `supabase/functions/einvoice-processor/handlers/misa_client_factory_test.ts:1-96` (sửa, 96 dòng)
- Lệch plan + lý do: Không có.
- Ca test:
  - `deno test supabase/functions/einvoice-processor/handlers/misa_client_factory_test.ts supabase/functions/einvoice-processor/handlers/issued_invoice/issued_invoice_provider_test.ts`: đạt 21/21 (13 ca adapter + 8 ca factory).
  - Toàn bộ suite `supabase/functions/einvoice-processor`: đạt 271/271 (249 baseline + 8 Task 1 + 14 Task 2).
- Impact:
  - `getForTenant`: gọi tại `sync_capabilities.ts:58`, `issuance_provider.ts:67,115,149`, `misa_client_factory_test.ts`. Thêm trường `taxCode: string | null` vào kiểu trả về, không đổi trường cũ (`client`, `baseUrl`). Rủi ro: LOW.
  - `buildHandlers` / `buildDeadLetters`: được kiểm tra trước bằng grep (gọi tại `index.ts:89,92`, `dead_letters_test.ts:104`). Sẽ sửa ở Task 5.

**Task 3 — ✅**
- Tệp:
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/document_storage.ts:1-131` (tạo mới, 131 dòng)
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/fake_bucket.ts:1-38` (tạo mới, 38 dòng)
  - Test: `supabase/functions/einvoice-processor/handlers/issued_invoice/document_storage_test.ts:1-127` (tạo mới, 127 dòng)
- Lệch plan + lý do: Không có. Trong `sha256Hex`, cắt ArrayBuffer từ `bytes.buffer` để tương thích chặt chẽ với định kiểu Web Crypto `BufferSource`.
- Ca test: `deno test supabase/functions/einvoice-processor/handlers/issued_invoice/document_storage_test.ts` đạt 5/5; toàn bộ suite đạt 276/276 (+5 ca mới).
- Impact: Không sửa symbol cũ.
- Ghi nhận Task 3.3: `createSupabaseDocumentBucket` đọc `statusCode` (từ `StorageError` của `@supabase/storage-js`), sau đó `status` (mã HTTP chuẩn), kiểm tra chuỗi '409' hoặc '400' cùng nội dung lỗi ('duplicate', 'already exists') để phân loại `duplicate`.

**Task 4 — ✅**
- Tệp:
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/gateways.ts:1-97` (tạo mới, 97 dòng)
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/supabase_gateways.ts:1-263` (tạo mới, 263 dòng)
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/fake_gateways.ts:1-150` (tạo mới, 150 dòng)
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/record_provider_observation.ts:1-48` (tạo mới, 48 dòng)
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/fetch_official_view.ts:1-87` (tạo mới, 87 dòng)
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/download_invoice_document.ts:1-111` (tạo mới, 111 dòng)
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/poll_provider_observation.ts:1-79` (tạo mới, 79 dòng)
  - Test:
    - `supabase/functions/einvoice-processor/handlers/issued_invoice/fetch_official_view_test.ts:1-139` (tạo mới, 139 dòng)
    - `supabase/functions/einvoice-processor/handlers/issued_invoice/download_invoice_document_test.ts:1-162` (tạo mới, 162 dòng)
    - `supabase/functions/einvoice-processor/handlers/issued_invoice/poll_provider_observation_test.ts:1-122` (tạo mới, 122 dòng)
    - `supabase/functions/einvoice-processor/handlers/issued_invoice/record_provider_observation_test.ts:1-67` (tạo mới, 67 dòng)
- Lệch plan + lý do: Không có.
- Ca test:
  - `deno test supabase/functions/einvoice-processor/handlers/issued_invoice/{fetch_official_view,download_invoice_document,poll_provider_observation,record_provider_observation}_test.ts`: đạt 17/17 (5 + 5 + 4 + 3).
  - Toàn bộ suite `supabase/functions/einvoice-processor`: đạt 293/293 (+17 ca mới).
- Impact: Không sửa symbol cũ.
- Bảng RPC Task 4.3:
  | Hàm TS | Tên RPC | Tham số `p_*` (* = chỉ gửi khi khác null) | Nguồn mapper Dart |
  |---|---|---|---|
  | `loadOfficialViewContext` | `load_official_view_operation_context` | `p_tenant_id`, `p_electronic_invoice_id`, `p_request_id` | `electronic_invoice_rpc_mapper.dart:33-42` |
  | `loadDocumentContext` | `load_invoice_document_operation_context` | `p_tenant_id`, `p_electronic_invoice_id`, `p_document_type`, `p_request_id` | `electronic_invoice_rpc_mapper.dart:44-56` |
  | `loadObservationContext` | `load_provider_observation_context` | `p_tenant_id`, `p_command_id` | `electronic_invoice_rpc_mapper.dart:58-63` |
  | `recordOfficialViewResult` | `record_official_invoice_view_result` | `p_tenant_id`, `p_electronic_invoice_id`, `p_request_id`, `p_status`, `p_viewer_url`*, `p_viewer_token`*, `p_expires_at`*, `p_failure_code`*, `p_failure_message`*, `p_failure_source` | `electronic_invoice_rpc_mapper.dart:65-82` |
  | `recordDocumentResult` | `record_invoice_document_result` | `p_tenant_id`, `p_electronic_invoice_id`, `p_document_type`, `p_request_id`, `p_status`, `p_storage_reference`*, `p_checksum`*, `p_failure_code`*, `p_failure_message`*, `p_failure_source` | `electronic_invoice_rpc_mapper.dart:84-100` |
  | `recordProviderObservation` | `record_provider_observation` | `p_tenant_id`, `p_electronic_invoice_id`, `p_provider_state_code`, `p_provider_state_description`, `p_provider_reference`, `p_observed_at`, `p_deduplication_key`, `p_details_snapshot`, `p_correlation_id` | `electronic_invoice_rpc_mapper.dart:301-315` |

**Task 5 — ✅**
- Tệp:
  - `supabase/functions/einvoice-processor/handlers/issued_invoice/dead_letters.ts:1-82` (tạo mới, 82 dòng)
  - `supabase/functions/einvoice-processor/handlers/registry.ts:1-56` (sửa, 56 dòng)
  - `supabase/functions/einvoice-processor/index.ts:1-113` (sửa, 113 dòng)
  - Test:
    - `supabase/functions/einvoice-processor/handlers/issued_invoice/dead_letters_test.ts:1-164` (tạo mới, 164 dòng)
    - `supabase/functions/einvoice-processor/handlers/issued_invoice/processor_integration_test.ts:1-157` (tạo mới, 157 dòng)
    - `supabase/functions/einvoice-processor/handlers/issuance/dead_letters_test.ts:1-119` (sửa ca đăng ký 4 dead-letters, 119 dòng)
- Lệch plan + lý do: Không có.
- Ca test:
  - `deno check supabase/functions/einvoice-processor/index.ts`: 0 lỗi.
  - `deno lint supabase/functions/einvoice-processor`: 0 lỗi.
  - `deno test supabase/functions/einvoice-processor`: 301 passed | 0 failed (249 baseline 7-E1/7-E2a + 52 ca mới 7-E2b).
- Impact:
  - `buildHandlers` và `buildDeadLetters` trong `registry.ts` nhận thêm 3 handler và 2 dead-letter của `issuedInvoice`. Đã cập nhật `index.ts` và test `dead_letters_test.ts`. Rủi ro: LOW.
- Bảo mật (Task 5.5):
  - Lệnh `grep -rn -E "password|access_token|accessToken|username|bytes" supabase/functions/einvoice-processor/handlers/issued_invoice --include="*.ts" | grep -v "_test.ts" | grep -i -E "log\(|console"` trả về rỗng. Không có dòng log nào chứa bí mật hay byte tài liệu.

**Task 6 — ✅**
- Tệp:
  - `supabase/migrations/20261031011_einvoice_document_operations_rpcs.sql:46` (sửa 1 dòng thêm `'application/zip'`)
  - `supabase/tests/einvoice_th08.sql:350,1079-1100` (sửa declare + thêm ca E46 kiểm bucket)
  - `docs/refactor/PLAN.md:538` (sửa trạng thái 7-E2b Làm ✅)
  - `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md:879,1516` (thêm ghi chú US-03.3 + KI-24)
- Lệch plan + lý do: Không có.
- Ca test:
  - Deno test suite: `deno test supabase/functions/einvoice-processor` đạt 301/301 (0 failed).
- GitNexus detect-changes (Task 6.5):
  - `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory --scope all`:
    - Changed files: 9 files, 12 symbols (chỉ các file trong plan: `TH-08`, `PLAN.md`, `misa_client_factory.ts`, `registry.ts`, `index.ts`, `dead_letters_test.ts`, `misa_client_factory_test.ts`, migration `...011`, test `einvoice_th08.sql`).
    - Affected processes: 1 (`Build → ReturnExchangeMutationRequest` do `TenantMisaClientFactory`). Luồng này là dương tính giả của chỉ mục (do trùng tên symbol `TenantMisaClientFactory`, không liên quan đến logic đổi trả hàng).
    - Risk level: medium.
    - Untracked files (người dùng sẽ `git add`): `docs/refactor/plans/P7/7-E2b-einvoice-processor-tai-lieu.md`, `supabase/functions/einvoice-processor/handlers/issued_invoice/` (28 tệp).
  - Không có thay đổi ngoài phạm vi. `AGENTS.md` / `CLAUDE.md` không bị sửa.

### R1 — sửa (2026-11-08)

Đã xác nhận và sửa toàn bộ các điểm review R1:

- **R1-1 — `loadObservationContext` không nuốt lỗi `NOT_FOUND`:**
  - Tệp: `supabase/functions/einvoice-processor/handlers/issued_invoice/supabase_gateways.ts:124`
  - Đã xoá dòng `if (error.message.includes('NOT_FOUND')) return null;`, giữ nguyên `throw new Error(\`load_provider_observation_context: ${error.message}\`)`. Lỗi từ RPC `load_provider_observation_context` được ném ra để hàng đợi retry và chuyển sang trạng thái lỗi có ghi nhận thay vì coi như thành công âm thầm, đúng với hành vi của Dart (`SupabaseElectronicInvoiceCommandGateway`).
- **R1-2 — Log lỗi MISA trong `index.ts`:**
  - Tệp: `supabase/functions/einvoice-processor/index.ts:89-98`
  - Đã định nghĩa hàm `const log = (event: string, data: Record<string, unknown>) => console.log(JSON.stringify({ event, ...data }));` và truyền `log` vào cả `createIssuanceProvider({ clients: clientFactory, log })` (khắc phục thiếu log preview thất bại từ 7-E2a) và `createIssuedInvoiceProvider({ clients: clientFactory, log })` (ghi log `misa_resource_failed` khi MISA từ chối cung cấp view / tài liệu).
- **Ghi nhận — Bỏ biến trùng lặp:**
  - Đã xoá hằng số `OFFICIAL_VIEW_LEASE_MINUTES` khai báo thừa tại `supabase/functions/einvoice-processor/handlers/issued_invoice/provider_call_support.ts:3` (chỉ dùng bản chuẩn tại `outcomes.ts:45`).
- **R1-3 — Cập nhật kết quả mục 9:**
  - Cập nhật số dòng `wc -l` chính xác cho tất cả 31 tệp code/test.
  - Sửa số tệp untracked trong thư mục `handlers/issued_invoice/` từ 15 thành 28 tệp.
  - Ghi nhận lệch chủ động: thêm `documentType?: DocumentType | null` vào `ProviderContext` (khớp Dart `ElectronicInvoiceProviderContextDto`).
  - Ghi nhận luồng `Build → ReturnExchangeMutationRequest` trong `detect_changes` là dương tính giả do trùng tên symbol.
- **Kết quả kiểm tra sau sửa R1:**
  - `deno check supabase/functions/einvoice-processor/index.ts`: 0 lỗi.
  - `deno lint supabase/functions/einvoice-processor`: 0 lỗi.
  - `deno test supabase/functions/einvoice-processor`: 301 passed | 0 failed (đạt 100% toàn bộ test suite).

## 10. Review (phiên review ghi)

### R1 — 2026-11-08 — **CHƯA ĐẠT** (1 lệch Dart chưa ghi, 1 thiếu log, 1 sửa Kết quả)

| Hạng mục | Kết quả |
|---|---|
| `deno check index.ts` / `deno lint` | ✅ sạch — review chạy lại |
| `deno test supabase/functions/einvoice-processor` | ✅ 301/301 — review chạy lại; `handlers/issued_invoice` 51/51 + 1 ca `taxCode` ở `misa_client_factory_test.ts` = 52 ca mới. Mục 1 của plan ghi "16 ca mới ⇒ 299" là **plan cộng sai** (đúng: 1 + 1 + 2 + 6 + 4 + 1 + 3 = 18 ⇒ 301), không phải lỗi code |
| Số ca so với bảng mục 5 | ✅ 34 ca chép; tên ca giữ đúng Dart (soát 13 ca adapter, 5 ca observation classifier, 2 ca content policy, 3 ca storage, 8 ca handler / payload, 3 ca record observation) |
| Đối chiếu Dart (RF1) | ✅ `provider_call_support`, `official_view_classifier`, `document_classifier`, `observation_classifier`, `document_content_policy`, `issued_invoice_provider` (thứ tự series → credentials → tax code → gọi MISA), 3 handler, `recordProviderObservation`, 2 dead-letter — thứ tự nhánh, mã lý do giữ từng ký tự |
| `supabase_gateways.ts` ↔ chữ ký SQL | ✅ 6 RPC, tên `p_*`, tham số chỉ gửi khi khác null khớp `electronic_invoice_rpc_mapper.dart` và `…010/011/012`; bảng Task 4.3 đúng — **trừ** `loadObservationContext` (R1-1) |
| RF2 lưu trùng | ✅ `upsert: false` + `duplicate` ⇒ tải về so checksum; nhận diện "đã có" bằng 409 / 400 **và** thông điệp `duplicate` / `already exists` (rộng hơn Q8, đã ghi ở Task 3.3) — chấp nhận |
| RF3 checksum | ✅ `sha256Hex` hex chữ thường 64 ký tự, cắt `ArrayBuffer` theo `byteOffset` / `byteLength` đúng |
| RF4 bộ nhớ | ✅ không giữ bản sao thừa ngoài phần cần thiết (byte MISA → upload; chỉ tải về khi trùng) |
| RF5 lộ dữ liệu | ✅ log chỉ có series / query / mã tham chiếu / `detail` cắt 400 ký tự; grep 5.5 lặp lại 0 dòng — nhưng log **không bao giờ ra** ở bản chạy thật (R1-2) |
| RF6 `taxCode` | ✅ cả 2 nhánh `getForTenant` trả `row.tax_code` của dòng vừa đọc |
| Migration + E46 | ✅ `20261031011:46` thêm `'application/zip'`; E46 (`einvoice_th08.sql:1079-1100`) kiểm `public`, `file_size_limit`, đủ 4 MIME |
| TH-08 / PLAN.md | ✅ KI-24 (`:1516`), US-03.3 FR-02 (`:879`), dòng 7-E2b |
| `detect_changes` (review chạy lại) | 9 tệp đã theo dõi, 12 symbol, 1 luồng, medium — khớp Kết quả. Luồng `Build → ReturnExchangeMutationRequest` là **dương tính giả** của chỉ mục (trùng tên, `TenantMisaClientFactory` không liên quan đổi trả hàng) |
| Mục 9 Kết quả | ❌ **R1-3** |

#### R1 — việc cần sửa

- **R1-1 — `loadObservationContext` nuốt lỗi `NOT_FOUND` (lệch Dart, chưa ghi Kết quả).** `handlers/issued_invoice/supabase_gateways.ts:126` có `if (error.message.includes('NOT_FOUND')) return null`. RPC `load_provider_observation_context` **ném** `NOT_FOUND` khi không thấy lệnh hoặc hoá đơn (`20261031012:181-200`); Dart không bắt (`supabase_electronic_invoice_command_gateway.dart:130-151` ⇒ `mapEinvoiceRpcError` ⇒ ném) ⇒ hàng đợi thử lại rồi để lệnh `failed` có ghi lỗi. TS trả `null` ⇒ handler `return` ⇒ lệnh `complete`, không còn dấu vết. Plan G5 ghi "`error` ⇒ `throw`". **Sửa:** xoá dòng `:126` (giữ `throw new Error(\`load_provider_observation_context: ${error.message}\`)`). Không cần ca test mới (gateway Supabase không test đơn vị); `poll observation returns quietly when context is missing` vẫn đúng vì kiểm nhánh `rows.length === 0`.
- **R1-2 — log lỗi MISA không bao giờ ra ở bản chạy thật.** `index.ts:95` dựng `createIssuedInvoiceProvider({ clients: clientFactory })` không truyền `log` ⇒ `deps.log?.(…)` ở `issued_invoice_provider.ts:43` không chạy. Dart ghi `warning` này vì "command still succeeds, so this line is the only trace of why" (`me_invoice_electronic_invoice_provider_adapter.dart:41-43`) — `FAILED` / `CHECK_REQUIRED` do MISA từ chối không còn cách nào biết lý do. (Plan G7 bỏ sót, không phải lỗi phiên code.) **Sửa:** trong `index.ts` khai báo một hàm `const log = (event: string, data: Record<string, unknown>) => console.log(JSON.stringify({ event, ...data }))` (giống `defaultLog` của `queue/processor.ts:28-29`) và truyền `log` cho `createIssuedInvoiceProvider` **và** `createIssuanceProvider` (`index.ts:91`, cùng lỗi ở 7-E2a: `misa_preview_failed` / `misa_preview_canonical_invalid` cũng không ra). Chỉ sửa `index.ts`; `deno check` / `deno test` chạy lại.
- **R1-3 — Kết quả mục 9 lệch số thật.**
  - Số dòng (so `wc -l` hiện tại): `outcomes.ts` 57 → 58, `errors.ts` 6 → 7, `provider_call_support.ts` 50 → 51, `document_content_policy.ts` 90 → 91, `official_view_classifier.ts` 60 → 61, `document_classifier.ts` 88 → 89, `observation_classifier.ts` 123 → 124, `document_content_policy_test.ts` 57 → 59, `observation_classifier_test.ts` 114 → 112, `issued_invoice_provider.ts` 186 → 187, `issued_invoice_provider_test.ts` 238 → 239, `fake_bucket.ts` 37 → 38, `document_storage_test.ts` 128 → 127, `gateways.ts` 96 → 97, `supabase_gateways.ts` 263 → 264, `fake_gateways.ts` 149 → 150, `record_provider_observation.ts` 47 → 48, `fetch_official_view.ts` 86 → 87, `download_invoice_document.ts` 110 → 111, `poll_provider_observation.ts` 78 → 79, `record_provider_observation_test.ts` 66 → 67, `dead_letters.ts` 81 → 82, `dead_letters_test.ts` (issued_invoice) 163 → 164, `processor_integration_test.ts` 156 → 157. Sửa theo `wc -l` **sau** khi làm R1-1 / R1-2.
  - Task 6: "`handlers/issued_invoice/` (15 tệp)" — thật **28 tệp**.
  - Task 1 "Lệch plan: Không có" nhưng có thêm `ProviderContext.documentType` ⇒ ghi là lệch (lý do: Dart `ElectronicInvoiceProviderContextDto` có trường này).
  - Task 6 `detect_changes`: thêm câu "luồng `Build → ReturnExchangeMutationRequest` là dương tính giả của chỉ mục".
  - Ghi Kết quả cho R1-1 / R1-2 (tệp:dòng, test chạy lại) dưới tiêu đề **R1 — sửa**.

#### Ghi nhận (không bắt sửa)

- `OFFICIAL_VIEW_LEASE_MINUTES` khai báo 2 lần (`outcomes.ts:45`, `provider_call_support.ts:3`); chỉ bản ở `outcomes.ts` được dùng ⇒ có thể xoá bản kia khi sửa R1.
- `InvoiceDocumentContentPolicy` (`document_content_policy.ts:82-91`) chỉ test dùng — vỏ bọc trùng `validateDocumentContent` / `isZip`; chấp nhận.
- `supabase_gateways.ts` dùng `String(row.x)` ⇒ cột null thành chuỗi `"null"` (Dart `as String` ném). Các RPC `load_*` lấy hoá đơn đã phát hành nên tham chiếu MISA không null trong thực tế — chấp nhận.
- `handlers/issuance/dead_letters_test.ts:98` ca `registers dead letters for preview and publish` giờ kiểm 4 khoá — tên ca cũ, trùng ý với ca mới ở `issued_invoice/dead_letters_test.ts`; chấp nhận.
- E46 kiểm `v_bucket_e46 is null` (bản ghi toàn null khi không thấy) — đúng; `if not found` sẽ rõ hơn.
- Handler lấy `tenant_id` từ payload, rơi về `ctx.tenantId` — cùng cách 7-E2a.

### R2 — 2026-11-08 — **ĐẠT**

| Hạng mục | Kết quả |
|---|---|
| R1-1 `NOT_FOUND` | ✅ `supabase_gateways.ts:120-125` không còn nhánh nuốt lỗi; lỗi RPC ⇒ `throw new Error(\`load_provider_observation_context: …\`)` như Dart |
| R1-2 log MISA | ✅ `index.ts:86` khai báo `log` (JSON ra `console.log`, giống `defaultLog` của hàng đợi), truyền cho `createIssuanceProvider` và `createIssuedInvoiceProvider` (`index.ts:92`, `:96`) |
| Ghi nhận R1 `OFFICIAL_VIEW_LEASE_MINUTES` | ✅ chỉ còn bản ở `outcomes.ts:45` |
| R1-3 số dòng | ✅ 31 mục `tệp:1-N` ở mục 9 khớp `wc -l` từng tệp (review đối chiếu tự động) |
| R1-3 số tệp / lệch / `detect_changes` | ✅ 28 tệp; Task 1 ghi lệch `ProviderContext.documentType`; Task 6 ghi luồng dương tính giả |
| Hồi quy | ✅ review chạy lại: `deno check` exit 0, `deno lint` 118 tệp 0 lỗi, `deno test` 301/301 |

Ghi nhận (không bắt sửa): mục "R1 — sửa" ghi R1-2 ở `index.ts:89-98`, thật `:86` (khai báo `log`) và `:92`, `:96` (chỗ truyền).

Còn lại (người dùng): `git add` các tệp mới (`handlers/issued_invoice/`, plan) rồi chạy lại `detect_changes` trước commit; reset DB local (migration `…011` đã sửa) rồi chạy `einvoice_th08.sql` → `einvoice_th08: OK` (E46). Plan giữ tới khi chạy SQL xong.

