# 7-E2a — HĐĐT: `einvoice-processor` luồng phát hành — handler `preview_invoice`, `publish_invoice` (+ khoá ký hiệu), `poll_issuance_status` + 2 dead-letter

> Theme 8 (mã cũ P7) · Phần server. 7-E2 tách 3 plan theo luồng (người dùng chốt 2026-11-08): **7-E2a phát hành** → 7-E2b bản chính thức / tài liệu / quan sát → 7-E2c gửi email.
> Gồm: việc 7.4 phần phát hành (3/9 handler + 2/6 dead-letter); ca SQL khoá ký hiệu và thử lại bền (E35–E39).
> Trạng thái: Plan 📝 (viết 2026-11-08, chờ duyệt) | Làm ⬜ | Review ⬜
> **Trước: 7-E1 Làm ✅** (plan này sửa `handlers/registry.ts`, `index.ts`, `queue/processor_test.ts` của 7-E1 và dùng `CommandHandler`, `CommandContext`, `ClaimedCommand`, `DeadLetterHandler`, `PublishSeriesLeaseBusyError`, `ProviderUnavailableError`, `TenantMisaClientFactory`, `classifyInvoiceSeries`, `FakeQueueRpc`, client `misa/`). Sau: 7-E2b, 7-E2c (dùng lại khuôn `handlers/<luồng>/` + `supabase_gateways.ts` của plan này), 7-E3.
> Tài liệu: [TH-08](../../../02-yeu-cau/TH-08-hoa-don-dien-tu.md) 6.2 "Lệnh nội bộ", 9.1, 9.2 (PR 7.4). Plan khung: [7-E1](7-E1-einvoice-processor-khung.md) (G3 hàng đợi, G4 handler). Nguồn chép (`modules/einvoice/`):
> - handler: `application/lib/src/issuance/commands/{preview_invoice,publish_invoice,poll_issuance_status,record_issuance_result}/`
> - kiểu chung: `application/lib/src/issuance/shared/{issuance_result_evidence_dto,canonical_invoice_integrity_exception,issuance_provider_status_lookup,misa_publish_provider_codes,publish_provider_retry_policy,publish_undetermined_reason_codes,publish_preparation_action,reconciliation_poll_context_dto}.dart`; `application/lib/src/ports/{i_me_invoice_provider_port,me_invoice_publish_outcome,me_invoice_issuance_status_outcome,i_issuance_result_gateway,i_publish_series_lease_gateway,i_invoice_preview_gateway,i_issuance_reconciliation_gateway}.dart`; `domain/lib/src/reconciliation/reconciliation_schedule.dart`
> - adapter: `infrastructure/lib/src/adapters/misa/{me_invoice_canonical_mapper,me_invoice_publish_classifier,me_invoice_issuance_status_classifier}.dart`; `me_invoice_provider_adapter.dart:194-411` (`_safePreviewFailureDetail`, `previewUnpublished`, `validateCanonical`, `publish`, `getStatus`)
> - gateway: `infrastructure/lib/src/domain/issuance/{supabase_issuance_result_gateway,supabase_publish_series_lease_gateway,supabase_issuance_reconciliation_gateway,issuance_rpc_mapper,publish_series_lease_rpc_mapper}.dart`; `infrastructure/lib/src/data_access/supabase_invoice_preview_gateway.dart:70-95`
> - dead-letter: `infrastructure/lib/src/configuration/processing/internal_commands/{preview,publish_invoice}_command_dead_letter_handler.dart`
>
> **Cho phiên code:** dùng `superpowers:executing-plans` (tuần tự). Mỗi task xong ghi ngay mục 9 theo mẫu (tệp:dòng, lệch plan, ca test, impact). **Không commit** (người dùng commit sau `detect_changes()`). **Không làm gì với DB** (không chạy SQL, không reset, không push, không deploy function). **Không đụng `modules/`, `packages/`, `apps/`** (chỉ đọc để chép). **Không ghi mục 10.**

**Goal:** Edge Function `einvoice-processor` chạy được 3 loại lệnh của luồng phát hành — xem trước, phát hành (giữ khoá ký hiệu), đối soát trạng thái — với cùng RPC, cùng phân loại kết quả MISA, cùng số lượt thử như worker Dart cũ; 106 ca test Dart của luồng này chạy xanh bằng Deno.

**Architecture:** Thư mục mới `handlers/issuance/`: bộ chuyển canonical → MISA và 2 bộ phân loại (hàm thuần), `issuance_provider.ts` (gọi client MISA qua `TenantMisaClientFactory` của 7-E1), 4 interface gateway hẹp + bản Supabase thật, 3 handler + 1 hàm ghi kết quả + 2 dead-letter. Handler chỉ phụ thuộc interface, test bằng bản giả. `registry.ts` / `index.ts` của 7-E1 chỉ thêm dòng đăng ký và dựng gateway. Không sửa migration.

**Tech Stack:** Deno 2, TypeScript, `npm:@supabase/supabase-js@2`, `jsr:@std/assert@1` (như 7-E1); PostgreSQL / plpgsql (chỉ tệp test SQL).

## 1. Mục tiêu

- `deno test supabase/functions/einvoice-processor` xanh: ca của 7-E1 + 106 ca chép từ Dart (mục 5, bảng Task) + 3 ca mới trong `queue/processor_test.ts`.
- `deno check supabase/functions/einvoice-processor/index.ts`, `deno lint supabase/functions/einvoice-processor` không lỗi.
- `einvoice.preview_invoice` → `store_preview_result` `READY` / `FAILED` (`PROVIDER_REJECTED_INVOICE_DATA` | `PROVIDER_AUTH_FAILED`, nguồn `PROVIDER`); MISA không phản hồi → thử lại, hết lượt → `FAILED / PROVIDER_UNAVAILABLE / INTERNAL`.
- `einvoice.publish_invoice` → khoá ký hiệu → `prepare_issuance_publish` → (gọi MISA) → đúng một trong `record_issuance_success` / `_failure` / `_undetermined` / `record_retryable_provider_publish_rejection`; khoá bận → dời việc theo `retry_after_seconds`, không tính lượt.
- `einvoice.poll_issuance_status` → `claim_issuance_reconciliation_case` → `getStatus` → ghi kết quả + `resolve_reconciliation_case`, hoặc hẹn lần sau theo lịch 30 s / 2 phút / 10 phút / 30 phút / 2 giờ, quá 5 lần → `POLL_MAX_CHECKS_EXCEEDED`.
- `einvoice_th08.sql` có E35–E39 (người dùng chạy).

**Không làm:** `fetch_official_view`, `download_invoice_document`, `poll_provider_observation` + 2 dead-letter (7-E2b); `send_invoice_email`, `reconcile_invoice_delivery` + 2 dead-letter (7-E2c); xử lý outbox `einvoice.electronic_invoice.registered` / `issuance.failed` mà các `record_issuance_*` đang ghi (7-E3, KI-20); xoá `renew_publish_series_lease` (7-C xét); sửa migration.

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | 7-E2 (8 handler + dead-letter, ~3.000 dòng Dart, ~160 ca test) một plan hay nhiều | **Người dùng chốt 2026-11-08 (A):** 3 plan theo luồng: 7-E2a phát hành, 7-E2b bản chính thức / tài liệu / quan sát, 7-E2c gửi email; làm nối tiếp a → b → c |
| Q2 | Nhịp gia hạn khoá ký hiệu (Dart: `renew` mỗi 30 giây, mất khoá → `PublishSeriesLeaseBusy(1s)` trước khi gọi MISA). Khoá sống 300 giây (`20261031019:65`, `:165`), Edge Function bị cắt ở 150 giây ⇒ trong một lần gọi khoá không bao giờ hết hạn | **Người dùng chốt 2026-11-08 (A):** bỏ nhịp gia hạn và kiểm `isLost`; giữ lấy khoá → `try` … `finally release`. Bỏ 2 ca Dart `renews sequentially while provider call is still running`, `lost lease before provider call prevents MISA dispatch` |
| Q3 | Chép test nào | **Người dùng chốt 2026-11-08 (A):** chép test đơn vị (handler, adapter, phân loại, dead-letter, lịch đối soát), giữ tên ca. Không chép harness SQL giả (`einvoice_publish_invoice_worker_test`, `preview_invoice_worker_test`) — thay bằng 3 ca `FakeQueueRpc` (phần thuộc Edge Function) + E35–E39 SQL (phần thuộc DB). Không chép test hợp đồng SQL / tích hợp / đăng ký DI |
| Q4 | Số dead-letter | Code Dart đăng ký **6** (`processing_module.dart:76-99`: publish, preview, official view, document, send email, reconcile delivery), không phải 5 như plan 7-E1 / PLAN.md ghi. 7-E2a làm 2; 7-E2b, 7-E2c mỗi plan 2. Task 6 sửa chữ ở plan 7-E1 |
| Q5 | Chuỗi lỗi ghi DB | `String(e)` của TS khác `toString()` Dart (`Error: x` / `Bad state: x`). Chuỗi chỉ vào `failure_message`, `internal_commands.error`, log — app không so khớp ⇒ không ép giống; ca test nào so chuỗi này sửa giá trị mong đợi, ghi Kết quả. **Chuỗi lỗi MISA và mã lý do** (`PROVIDER_*`, `DISPATCH_STATE_UNCERTAIN`, `MISSING_PROVIDER_TRANSACTION_ID`, `POLL_MAX_CHECKS_EXCEEDED`, `PUBLISH_RETRY_SCHEDULED`, …) giữ từng ký tự |
| Q6 | `RecordIssuanceResultCommand` (Dart chạy qua bus + validator) | Hàm thường `recordIssuanceResult(gateway, input)` trong `record_issuance_result.ts`, gọi thẳng từ `poll_issuance_status`; validator chép vào cùng tệp (ném trước khi gọi gateway) |
| Q7 | Kiểu kết quả Dart (`sealed class`, constructor có tên) | Union có trường `kind` (`'success' \| 'definiteFailure' \| …`), tên trường camelCase như Dart; `Duration` → giây (`…Seconds`), `DateTime` → `Date` (như 7-E1 Q5) |
| Q8 | `owner_token` của khoá, `sourceCommandId`, `workerId` | `owner_token` = `ctx.command.commandId` (Dart `command.id`); `sourceCommandId` = `ctx.command.commandId`; `workerId` khi claim đối soát = `payload.correlation_id` (như Dart) |

## 3. Hiện trạng (đo 2026-11-08)

| Thứ | Ở đâu | Ghi chú |
|---|---|---|
| Xếp `einvoice.preview_invoice` | `20261031006:701-713` | payload `{tenant_id, sales_order_id, preview_request_id, order_version, provider_connection_id, canonical_invoice}` |
| Xếp `einvoice.publish_invoice` | `…008:216-227`, `…020:128-139` (lần thử lại, `source_event_id = p_source_command_id`), `…023:573-584` | payload `{tenant_id, attempt_id, canonical_invoice, payload_hash, idempotency_key}` |
| Xếp `einvoice.poll_issuance_status` | `…009:130`, `:276`, `:349`, `:752`, `:896` | payload `{tenant_id, case_id, attempt_id, correlation_id}`; Dart đọc thêm `check_ordinal` mặc định 1 nhưng handler không dùng ⇒ TS bỏ |
| 16 RPC | `store_preview_result` (`…006`), `acquire_` / `release_publish_series_lease` (`…019`), `prepare_issuance_publish`, `mark_issuance_provider_call_started`, `record_issuance_success`, `record_issuance_failure`, `record_issuance_command_integrity_failure`, `record_publish_command_dead_letter` (`…007`), `record_issuance_undetermined`, `record_reconciliation_pending`, `resolve_reconciliation_case` (`…009`), `record_retryable_provider_publish_rejection`, `claim_issuance_reconciliation_case` (`…020`) | cả 16 có, `grant` chỉ `service_role` |
| `acquire_publish_series_lease(p_tenant_id, p_attempt_id, p_owner_token, p_lease_seconds default 300)` | `…019:24-36` | trả `(acquired, provider_connection_id, invoice_series, lease_version, leased_until, retry_after_seconds)` |
| `prepare_issuance_publish` | `…007` | trả `action` ∈ `CALL_PROVIDER` (PREPARING → SUBMITTED), `RECONCILE_ONLY` (SUBMITTED / WAITING_RESULT), `SKIP` (RECONCILING / SUCCEEDED / FAILED) |
| `record_retryable_provider_publish_rejection` | `…020:10-150` | lần 1 hẹn ≥ 5 s, sau ≥ 30 s; lần thứ 4 → `record_issuance_failure` trả `('FAILED', 3, false)`; đã có lệnh con cùng `source_event_id` → trả `scheduled = true`, không đổi gì |
| Tham số RPC | `issuance_rpc_mapper.dart:32-143`, `:364-405`, `:436-452`; `publish_series_lease_rpc_mapper.dart`; `supabase_invoice_preview_gateway.dart:78-90` | chép đúng tên `p_*` và tên cột đọc về |
| Test SQL | `supabase/tests/einvoice_th08.sql` | chưa có ca nào về khoá ký hiệu / thử lại bền; 7-E1 thêm E32–E34 |
| Bản Dart của worker | `einvoice_publish_invoice_worker_test.dart` (9), `preview_invoice_worker_test.dart` (3) | harness SQL giả — không chép (Q3) |

Không có bảng "Đang làm gì": plan không xoá / tách code cũ (xoá ở 7-C); test parity chính là các ca chép từ Dart.

## 4. Thiết kế

### G1. Kiểu chung — `handlers/issuance/outcomes.ts`, `errors.ts`

```ts
export type PreviewOutcome =
  | { kind: 'success'; viewerRef: string }
  | { kind: 'providerUnavailable' }
  | { kind: 'invalidData'; detail: string | null }
  | { kind: 'authFailed' }

export interface SafeProviderEvidence { refId?: string | null; transactionId?: string | null; invoiceNumber?: string | null
  invoiceSeries?: string | null; providerCode?: string | null; providerMessage?: string | null }

export type PublishOutcome =
  | { kind: 'success'; providerReference: string; invoiceNumber: string; invoiceSeries: string; issuedAt: Date; safeProviderEvidence: SafeProviderEvidence }
  | { kind: 'definiteFailure'; providerCode: string; providerMessage: string; safeProviderEvidence: SafeProviderEvidence }
  | { kind: 'retryableRejection'; providerCode: string; providerMessage: string; retryAfterSeconds: number; safeProviderEvidence: SafeProviderEvidence }
  | { kind: 'undetermined'; reasonCode: string; safeProviderEvidence: SafeProviderEvidence }

export type IssuanceResultEvidence =
  | { kind: 'success'; idempotencyKey: string; payloadHash: string; providerReference: string; invoiceNumber: string; invoiceSeries: string; issuedAt: Date }
  | { kind: 'definiteFailure'; idempotencyKey: string; payloadHash: string; providerCode: string; providerMessage: string }
  | { kind: 'undetermined'; idempotencyKey: string; payloadHash: string; reasonCode: string }
  | { kind: 'retryableProviderRejection'; idempotencyKey: string; payloadHash: string; providerCode: string; providerMessage: string }

export type IssuanceStatusOutcome =
  | { kind: 'success'; evidence: Extract<IssuanceResultEvidence, { kind: 'success' }> }
  | { kind: 'definiteFailure'; evidence: Extract<IssuanceResultEvidence, { kind: 'definiteFailure' }> }
  | { kind: 'pending' }
  | { kind: 'undetermined'; reasonCode: string }

export type StatusLookup = 'providerTransactionId' | 'refId'
export const PUBLISH_UNDETERMINED_REASON = { duplicateInvoiceRefId: 'DUPLICATE_INVOICE_REF_ID', invoiceDuplicatedReconcileFirst: 'INVOICE_DUPLICATED_RECONCILE_FIRST' } as const
export const MISA_PUBLISH_PROVIDER_CODES = { invoiceNumberNotContinuous: 'InvoiceNumberNotCotinuous', invoiceDuplicated: 'InvoiceDuplicated' } as const
export const RECONCILIATION_MAX_CHECKS = 5
export function delayBeforeCheckSeconds(checkSequence: number): number  // 1→30, 2→120, 3→600, 4→1800, 5→7200; ngoài 1..5 → throw RangeError
export function shouldMarkUnresolved(completedChecks: number): boolean   // >= 5
export const MIN_INVOICE_NUMBER_NOT_CONTINUOUS_BACKOFF_SECONDS = 5
```

`errors.ts`: `class CanonicalInvoiceIntegrityError extends Error { constructor(readonly attemptId: string, readonly reasonCode = 'COMMAND_INTEGRITY', message: string) }`; `class CanonicalValidationFault extends Error { constructor(readonly reasonCode: string, message: string) }` (chép `me_invoice_canonical_mapper.dart:562-570`).

### G2. Bộ chuyển + phân loại (hàm thuần)

- `canonical_mapper.ts` — chép `MeInvoiceCanonicalMapper` 1:1: `validate(canonical)`, `toPreviewInvoice(canonical): MeInvoiceInvoiceData`, `toPublishRequest({canonicalInvoice, idempotencyKey}): MeInvoicePublishRequest`, `vndAmountInWords(amount)`, `resolveSignType` (export để test `th08_hardening_resolve_sign_type`). `_classifyInvSeries` dùng `classifyInvoiceSeries` của 7-E1 (`handlers/template_ref.ts`), không chép lần hai. Lỗi → `throw new CanonicalValidationFault(reasonCode, message)` cùng mã Dart.
- `publish_classifier.ts` — `classifyPublish({idempotencyKey, result: MeInvoiceResult<MeInvoicePublishInvoiceResultItem[]>, canonicalInvoice}): PublishOutcome`; thứ tự nhánh, mã lý do, cắt 200 ký tự, `_resolveIssuedAt` (ngày `YYYY-MM-DD` → `Date.UTC`) chép đúng `me_invoice_publish_classifier.dart`. Dùng `MeInvoicePublishErrorCodes` của `misa/`.
- `issuance_status_classifier.ts` — `classifyIssuanceStatus({statusResult, idempotencyKey, payloadHash}): IssuanceStatusOutcome`; chép đúng (thất bại chắc chắn chỉ khi mã ∈ `definiteFailureCodes`, không dùng `publishRejectionCodes`).

### G3. `issuance_provider.ts`

```ts
export interface IssuanceProvider {
  previewUnpublished(tenantId: string, canonicalInvoice: Record<string, unknown>): Promise<PreviewOutcome>
  validateCanonical(canonicalInvoice: Record<string, unknown>): void
  publish(tenantId: string, canonicalInvoice: Record<string, unknown>, idempotencyKey: string): Promise<PublishOutcome>
  getStatus(input: { tenantId: string; statusLookupKey: string; invoiceSeries: string; idempotencyKey: string
    payloadHash: string; statusLookup: StatusLookup }): Promise<IssuanceStatusOutcome>
}
export function createIssuanceProvider(deps: { clients: TenantMisaClientFactory
  log?: (event: string, data: Record<string, unknown>) => void }): IssuanceProvider
export function safePreviewFailureDetail(message: string): string | null
```

Chép `me_invoice_provider_adapter.dart:194-411` và dùng `safeFailureReason` của 7-E1 (`handlers/sync_capabilities.ts`). Khác Dart:
- `getForTenant` trả `null` (không có dòng mật khẩu) thay cho `_readCredentials` rỗng: preview → `authFailed`; publish → `undetermined('PROVIDER_AUTH_FAILED', {refId: idempotencyKey})`; status → `undetermined('PROVIDER_AUTH_FAILED')`.
- `validateCanonical` và `toPublishRequest` lỗi → ném `CanonicalValidationFault` (Dart đổi sang `MeInvoiceCanonicalValidationException`; handler publish bọc thành `CanonicalInvoiceIntegrityError` nên không cần lớp thứ ba).
- Lỗi RPC (`read_provider_credentials`) để ném nguyên (Dart `mapEinvoiceRpcError`) — hàng đợi xử lý.
- Log: `misa_preview_failed` với `reason` + `detail` (đã lọc), `misa_preview_canonical_invalid` với `reasonCode`; không log mật khẩu / token / tên đăng nhập.

### G4. Gateway — `gateways.ts`, `supabase_gateways.ts`

```ts
export interface PreviewResultStore {
  store(input: { tenantId: string; salesOrderId: string; requestId: string; status: 'READY' | 'FAILED'; viewerRef?: string
    failureCode?: string; failureMessage?: string | null; failureSource?: 'PROVIDER' | 'INTERNAL' }): Promise<void>
}
export type PublishPreparationAction = 'CALL_PROVIDER' | 'RECONCILE_ONLY' | 'SKIP'
export interface IssuanceResultGateway {
  preparePublish(i: { tenantId: string; attemptId: string; idempotencyKey: string; payloadHash: string; canonicalInvoice: Record<string, unknown> }): Promise<PublishPreparationAction>
  markProviderCallStarted(tenantId: string, attemptId: string): Promise<void>
  recordSuccess(tenantId: string, attemptId: string, e: Extract<IssuanceResultEvidence, { kind: 'success' }>): Promise<void>
  recordDefiniteFailure(tenantId: string, attemptId: string, e: Extract<IssuanceResultEvidence, { kind: 'definiteFailure' }>): Promise<void>
  recordUndetermined(tenantId: string, attemptId: string, e: Extract<IssuanceResultEvidence, { kind: 'undetermined' }>): Promise<void>
  recordRetryableProviderRejection(i: { tenantId: string; attemptId: string; sourceCommandId: string
    evidence: Extract<IssuanceResultEvidence, { kind: 'retryableProviderRejection' }>; retryAfterSeconds: number }): Promise<void>
  recordCommandIntegrityFailure(tenantId: string, attemptId: string, reasonCode: string): Promise<void>
  recordPublishCommandDeadLetter(tenantId: string, attemptId: string, reasonCode: string): Promise<void>
}
export type LeaseAcquireOutcome =
  | { kind: 'acquired'; providerConnectionId: string; invoiceSeries: string; leaseVersion: number }
  | { kind: 'busy'; retryAfterSeconds: number }
export interface PublishSeriesLeaseGateway {
  tryAcquire(tenantId: string, attemptId: string, ownerToken: string): Promise<LeaseAcquireOutcome>
  release(i: { tenantId: string; providerConnectionId: string; invoiceSeries: string; ownerToken: string; leaseVersion: number }): Promise<void>
}
export interface ReconciliationPollContext { caseId: string; attemptId: string; claimToken: string; idempotencyKey: string
  payloadHash: string; invoiceSeries: string; providerReference: string | null; reconciliationReasonCode: string | null
  checkSequence: number; maxChecks: number }
export interface ReconciliationGateway {
  claim(tenantId: string, caseId: string, workerId: string): Promise<ReconciliationPollContext | null>
  recordPendingCheck(i: { tenantId: string; caseId: string; claimToken: string; nextDelaySeconds: number; checkSequence: number }): Promise<void>
  resolve(i: { tenantId: string; caseId: string; outcome: 'SUCCESS' | 'FAILURE' | 'PUBLISH_RETRY_SCHEDULED' | 'UNRESOLVED'; evidence?: Record<string, unknown> }): Promise<void>
}
export interface IssuanceGateways { preview: PreviewResultStore; results: IssuanceResultGateway; lease: PublishSeriesLeaseGateway; reconciliation: ReconciliationGateway }
```

`markUnresolved` của Dart (`supabase_issuance_reconciliation_gateway.dart:115-130`) chỉ là `resolve({outcome: 'UNRESOLVED', evidence: {claim_token, reason_code}})` ⇒ handler TS gọi `resolve` như vậy, không thêm hàm. Hằng `LEASE_SECONDS = 300`.

`supabase_gateways.ts`: `createSupabaseIssuanceGateways(client: SupabaseClient): IssuanceGateways`; mọi hàm `client.schema('einvoice').rpc(<tên>, <tham số theo mapper Dart>)`; `error` → `throw new Error(\`${tên}: ${error.message}\`)`; hàm Dart ném khi rỗng (`prepare_issuance_publish returned no rows`, `… missing action`, `acquire_publish_series_lease returned no rows`, `record issuance result returned missing attempt_status`) → ném cùng chuỗi. Không test đơn vị (như `SupabaseQueueRpc` của 7-E1); review đối chiếu bảng mục 3.

### G5. Handler + dead-letter

Mỗi handler là `create…Handler(deps): CommandHandler` (kiểu 7-E1). Payload đọc từ `ctx.command.payload`; khoá bắt buộc thiếu / sai kiểu → `throw new Error('<command_type> payload missing <key>')` (hàng đợi thử lại rồi dead-letter, như Dart ném ở `fromJson`).

- `preview_invoice.ts` — `createPreviewInvoiceHandler({provider, gateways})`; chép `preview_invoice_command_handler.dart:20-63`: thêm `refId = preview_request_id` nếu thiếu; `success` → store `READY`; `providerUnavailable` → `throw new ProviderUnavailableError()`; còn lại → store `FAILED`, mã `PROVIDER_REJECTED_INVOICE_DATA` (`invalidData`) hoặc `PROVIDER_AUTH_FAILED`, `failureMessage = detail`, `failureSource = 'PROVIDER'`.
- `publish_invoice.ts` — `createPublishInvoiceHandler({provider, gateways})`; chép `publish_invoice_command_handler.dart:33-187` **trừ** heartbeat (Q2): `validateCanonical` lỗi → `CanonicalInvoiceIntegrityError(attemptId, 'COMMAND_INTEGRITY', message)` (lỗi đã là `CanonicalInvoiceIntegrityError` thì ném lại); `tryAcquire(tenant, attempt, commandId)` → `busy` → `throw new PublishSeriesLeaseBusyError(retryAfterSeconds)`; `acquired` → `try { dispatch } finally { release }`. `dispatch`: `SKIP` → return; `RECONCILE_ONLY` → `recordUndetermined(reasonCode 'DISPATCH_STATE_UNCERTAIN')`; `CALL_PROVIDER` → `markProviderCallStarted` → `publish` → `success` / `definiteFailure` / `retryableRejection` (`sourceCommandId = commandId`, `retryAfterSeconds` của outcome) / `undetermined`.
- `record_issuance_result.ts` — `recordIssuanceResult(results: IssuanceResultGateway, i: { tenantId; attemptId; correlationId; evidence: IssuanceResultEvidence }): Promise<void>`; validator chép `record_issuance_result_command_validator.dart` (ném `Error` cùng thông điệp); `retryableProviderRejection` → `throw new Error('retryable provider rejection must use publish retry gateway path')`.
- `poll_issuance_status.ts` — `createPollIssuanceStatusHandler({provider, gateways})`; chép `poll_issuance_status_command_handler.dart:44-188`: `claim(tenant, case_id, correlation_id)`; thứ tự nhánh, mã lý do, lịch, evidence của `resolve` (`issued_at` = `toISOString()`) giữ nguyên.
- `dead_letters.ts` — `createIssuanceDeadLetters(gateways): Record<string, DeadLetterHandler>` trả 2 khoá:
  - `'einvoice.preview_invoice'`: thiếu `sales_order_id` / `preview_request_id` (rỗng) → bỏ qua; còn lại store `FAILED`, `PROVIDER_UNAVAILABLE`, `failureMessage = String(error)`, `failureSource = 'INTERNAL'`.
  - `'einvoice.publish_invoice'`: `error instanceof CanonicalInvoiceIntegrityError` → `recordCommandIntegrityFailure(tenant, error.attemptId, error.reasonCode)`; còn lại cần `payload.attempt_id` (thiếu → `throw new Error('PublishInvoiceCommand payload missing attempt_id')`) → `recordPublishCommandDeadLetter(tenant, attemptId, String(error))`.

### G6. Nối vào 7-E1

- `handlers/registry.ts`: `buildHandlers(deps)` — `deps` thêm `issuance: { provider: IssuanceProvider; gateways: IssuanceGateways }`; trả thêm `'einvoice.preview_invoice'`, `'einvoice.publish_invoice'`, `'einvoice.poll_issuance_status'`. `DEAD_LETTER_HANDLERS` (hằng `{}` của 7-E1) đổi thành `buildDeadLetters(deps): Record<string, DeadLetterHandler>` trả `createIssuanceDeadLetters(deps.issuance.gateways)` (cần gateway thật nên không còn là hằng).
- `index.ts`: dựng `createSupabaseIssuanceGateways(client)`, `createIssuanceProvider({clients})` một lần ở cấp module cạnh `TenantMisaClientFactory`; truyền `buildDeadLetters(deps)` vào `runInvocation`.

## 5. Các bước

**Ràng buộc chung** (mọi task):
- Lệnh test: `deno test supabase/functions/einvoice-processor` (từ gốc repo), không cần quyền mạng. Lệnh kiểm: `deno check supabase/functions/einvoice-processor/index.ts`, `deno lint supabase/functions/einvoice-processor`.
- Test chép từ Dart: **giữ tên ca** (`Deno.test('<group> <ca>', …)`), giữ dữ liệu đầu vào và giá trị so sánh; ca phải đổi (kiểu thời gian, chuỗi `String(e)` theo Q5, cách bắt lỗi) ghi Kết quả. HTTP giả theo cách 7-E1 Task 3 (hàm `FetchLike`); client giả dùng `FakeMeInvoiceClient` khi Dart dùng fake tương ứng.
- Mỗi task: viết test trước, chạy thấy đỏ, viết mã, chạy thấy xanh.
- Test chép ở `supabase/functions/einvoice-processor/handlers/issuance/*_test.ts`.

| Dart (`modules/einvoice/`) | TS test | Ca | Task |
|---|---|---|---|
| `domain/test/reconciliation/reconciliation_schedule_test.dart` | `outcomes_test.ts` | 4 | 1 |
| `infrastructure/test/me_invoice_canonical_mapper_test.dart`, `infrastructure/test/adapters/misa/me_invoice_canonical_mapper_preview_test.dart`, `infrastructure/test/adapters/misa/th08_hardening_resolve_sign_type_test.dart` | `canonical_mapper_test.ts` | 8 + 6 + 5 | 1 |
| `infrastructure/test/me_invoice_publish_classifier_test.dart`, `…_th08_retry_test.dart` | `publish_classifier_test.ts` | 9 + 4 | 1 |
| `infrastructure/test/me_invoice_issuance_status_classifier_test.dart` | `issuance_status_classifier_test.ts` | 5 | 1 |
| `infrastructure/test/me_invoice_provider_adapter_preview_test.dart`, `me_invoice_provider_adapter_publish_test.dart` | `issuance_provider_test.ts` | 7 + 11 | 2 |
| `application/test/issuance/preview_invoice_command_handler_test.dart`, `preview_invoice_command_json_test.dart` | `preview_invoice_test.ts` | 6 + 1 | 3 |
| `application/test/issuance/publish_invoice_command_handler_test.dart` (bỏ 2 ca Q2), `publish_invoice_command_json_test.dart` | `publish_invoice_test.ts` | 12 + 1 | 3 |
| `application/test/issuance/record_issuance_result_command_handler_test.dart` | `record_issuance_result_test.ts` | 14 | 4 |
| `application/test/issuance/poll_issuance_status_command_handler_test.dart` | `poll_issuance_status_test.ts` | 9 | 4 |
| `infrastructure/test/configuration/einvoice_preview_dead_letter_test.dart` (bỏ ca đăng ký DI), `einvoice_publish_dead_letter_test.dart` | `dead_letters_test.ts` | 2 + 2 | 5 |
| | **Tổng** | **106** | |

### Task 1: Kiểu chung, bộ chuyển canonical, 2 bộ phân loại (G1, G2)

**Files:** Create: `handlers/issuance/outcomes.ts`, `errors.ts`, `canonical_mapper.ts`, `publish_classifier.ts`, `issuance_status_classifier.ts`; Test: `outcomes_test.ts`, `canonical_mapper_test.ts`, `publish_classifier_test.ts`, `issuance_status_classifier_test.ts` (41 ca)

**Interfaces — Consumes:** `misa/mod.ts` (`MeInvoiceInvoiceData`, `MeInvoicePublishRequest`, `MeInvoiceResult`, `MeInvoicePublishInvoiceResultItem`, `MeInvoiceInvoiceStatus`, `MeInvoicePublishErrorCodes`, `MeInvoiceSignType`), `classifyInvoiceSeries` (7-E1). **Produces:** mọi kiểu / hằng / hàm ở G1, G2.

- [ ] **1.1** Chép 4 tệp test (7 tệp Dart, bảng trên); chạy, thấy đỏ.
- [ ] **1.2** Viết 5 tệp theo G1, G2; chạy, thấy 41 ca xanh.
- [ ] **1.3** Ghi Kết quả: số dòng TS / Dart của `canonical_mapper`; chỗ đổi kiểu số (Dart `int` / `double` → `number`: kiểm ca làm tròn tiền, `vndAmountInWords`).

### Task 2: `issuance_provider.ts` (G3)

**Files:** Create: `handlers/issuance/issuance_provider.ts`; Test: `issuance_provider_test.ts` (18 ca)

**Interfaces — Consumes:** Task 1; `TenantMisaClientFactory`, `CredentialsReader`, `MisaEnv`, `safeFailureReason` (7-E1). **Produces:** `IssuanceProvider`, `createIssuanceProvider`, `safePreviewFailureDetail`.

- [ ] **2.1** Chép 2 tệp test. Dart dựng adapter với `rpcClient` giả trả dòng mật khẩu ⇒ TS dựng `TenantMisaClientFactory` với `CredentialsReader` giả; ca `rethrows mapped exception on RpcException` ⇒ `CredentialsReader` ném, `assertRejects` cùng lỗi; ca kiểm log ⇒ truyền `log` giả, so `event` + `reason`, và khẳng định chuỗi log không chứa mật khẩu / tên đăng nhập giả. Chạy, thấy đỏ.
- [ ] **2.2** Viết theo G3; chạy, thấy 18 ca xanh.

### Task 3: Gateway + handler xem trước và phát hành (G4, G5)

**Files:** Create: `handlers/issuance/gateways.ts`, `supabase_gateways.ts`, `preview_invoice.ts`, `publish_invoice.ts`, `fake_gateways.ts` (bản giả dùng chung cho test Task 3–5: ghi mọi lời gọi theo thứ tự, trả giá trị dựng sẵn); Test: `preview_invoice_test.ts` (7), `publish_invoice_test.ts` (13)

**Interfaces — Consumes:** Task 1, 2 (`IssuanceProvider` — test dùng bản giả tự viết trong `fake_gateways.ts`: `FakeIssuanceProvider` trả outcome dựng sẵn, ghi lời gọi); `CommandHandler`, `CommandContext`, `ClaimedCommand`, `PublishSeriesLeaseBusyError`, `ProviderUnavailableError` (7-E1). **Produces:** mọi kiểu G4; `createSupabaseIssuanceGateways`; `createPreviewInvoiceHandler`, `createPublishInvoiceHandler`; `FakeIssuanceGateways`, `FakeIssuanceProvider`.

- [ ] **3.1** Chép test. Ca `*_json_test` (Dart kiểm `fromJson` / `toJson`) ⇒ TS kiểm handler đọc đúng payload SQL ở mục 3 (dựng `ClaimedCommand` với payload đó, handler gọi provider với đúng `canonical_invoice` / `idempotency_key`). Ca publish `busy lease throws before preparePublish and does not release acquired lease` ⇒ `assertRejects(PublishSeriesLeaseBusyError)`, `retryAfterSeconds` đúng, không có `preparePublish` / `release`. Ca `does not dispatch RecordIssuanceResultCommand` ⇒ khẳng định gateway không nhận `recordSuccess` ngoài nhánh `success`. Thêm 1 ca: `releases the lease when the provider call throws` — `FakeIssuanceProvider.publish` ném ⇒ handler ném lại, `release` được gọi đúng 1 lần với `leaseVersion` của `acquired`. Chạy, thấy đỏ.
- [ ] **3.2** Viết `gateways.ts`, `fake_gateways.ts`, `preview_invoice.ts`, `publish_invoice.ts`; chạy, thấy xanh.
- [ ] **3.3** Viết `supabase_gateways.ts` (G4, không test đơn vị). Ghi Kết quả bảng: hàm TS → tên RPC → tham số `p_*` → nguồn mapper Dart (tệp:dòng).

### Task 4: Đối soát trạng thái + ghi kết quả (G5)

**Files:** Create: `handlers/issuance/record_issuance_result.ts`, `poll_issuance_status.ts`; Test: `record_issuance_result_test.ts` (14), `poll_issuance_status_test.ts` (9)

**Interfaces — Consumes:** Task 1, 3 (`FakeIssuanceGateways`, `FakeIssuanceProvider`). **Produces:** `recordIssuanceResult`, `createPollIssuanceStatusHandler`.

- [ ] **4.1** Chép test (Dart dùng `IEinvoiceCommandDispatcher` giả để bắt `RecordIssuanceResultCommand` ⇒ TS khẳng định `FakeIssuanceGateways.results` nhận `recordSuccess` / `recordDefiniteFailure` với cùng evidence). Chạy, thấy đỏ.
- [ ] **4.2** Viết 2 tệp; chạy, thấy xanh.

### Task 5: Dead-letter + đăng ký + `index.ts` (G5, G6)

**Files:** Create: `handlers/issuance/dead_letters.ts`; Modify: `handlers/registry.ts`, `index.ts`, `queue/processor_test.ts` (7-E1); Test: `dead_letters_test.ts` (4 + 1)

**Interfaces — Consumes:** Task 1–4; `runInvocation`, `FakeQueueRpc`, `buildHandlers` (7-E1). **Produces:** `createIssuanceDeadLetters`, `buildDeadLetters`; `buildHandlers` nhận `deps.issuance`.

- [ ] **5.1** Chạy `impact({target: "buildHandlers", direction: "upstream"})` và `impact({target: "DEAD_LETTER_HANDLERS", direction: "upstream"})` (GitNexus; TS mới có thể chưa có trong index — ghi "không có trong index" nếu vậy). Ghi Kết quả.
- [ ] **5.2** `dead_letters_test.ts`: chép 4 ca (2 ca Dart publish chạy qua worker ⇒ TS gọi thẳng handler dead-letter với lỗi tương ứng: `CanonicalInvoiceIntegrityError` → `recordCommandIntegrityFailure(…, 'COMMAND_INTEGRITY')`; lỗi thường → `recordPublishCommandDeadLetter(…, String(error))`). Ca mới `registers dead letters for preview and publish` — `Object.keys(buildDeadLetters(deps)).sort()` = `['einvoice.preview_invoice', 'einvoice.publish_invoice']`.
- [ ] **5.3** `queue/processor_test.ts` thêm 3 ca (dùng `runInvocation` + `FakeQueueRpc` + handler thật dựng từ `FakeIssuanceGateways` / `FakeIssuanceProvider`):
  - `publish lease busy reschedules by retry_after without consuming an attempt` — `lease.tryAcquire` trả `busy(17)` ⇒ `reschedule(…, 17)`, không `retryOrDeadLetter` / `fail`.
  - `publish retryable rejection completes the command without dead-letter` — provider trả `retryableRejection` ⇒ `recordRetryableProviderRejection` 1 lần, `complete` 1 lần, không dead-letter.
  - `publish failure on third attempt dead-letters to recordPublishCommandDeadLetter` — `retryCount: 2`, provider ném, `retryOrDeadLetter` trả `DEAD_LETTER` ⇒ `recordPublishCommandDeadLetter(t, attemptId, <String(lỗi)>)` 1 lần.
- [ ] **5.4** Chạy, thấy đỏ; viết `dead_letters.ts`, sửa `registry.ts`, `index.ts` theo G6; chạy, thấy xanh.
- [ ] **5.5** `deno check supabase/functions/einvoice-processor/index.ts`, `deno lint supabase/functions/einvoice-processor`, `deno test supabase/functions/einvoice-processor` — ghi số ca đạt / lỗi (tách: của 7-E1, của 7-E2a).
- [ ] **5.6** `grep -rn "password\|access_token\|accessToken\|username" supabase/functions/einvoice-processor/handlers/issuance --include=*.ts | grep -v _test.ts | grep -i "log\|console"` ⇒ không dòng nào log bí mật; ghi Kết quả.

### Task 6: SQL E35–E39 + tài liệu + `detect_changes` + Kết quả

**Files:** Modify: `supabase/tests/einvoice_th08.sql` (sau E34 của 7-E1, trước `reset role; raise notice 'einvoice_th08: OK'`), `docs/refactor/PLAN.md`, `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md`, `docs/refactor/plans/P7/7-E1-einvoice-processor-khung.md` (chỉ dòng "Sau:" và mục 1 "Không làm"; **không** sửa mục 9 / 10)

- [ ] **6.1** Thêm ca vào `einvoice_th08.sql` (biến mới ở `declare`; chạy dưới `reset role`; dùng lượt của đơn `v_oa` — `v_att_e35 := public._th08_attempt_id(v_oa, 1)`, đang `PREPARING` từ E10; **không** dùng `v_att1` vì E19 đã gán lại):
  - **E35** khoá bận: `acquire_publish_series_lease(v_ta, v_att_e35, 'owner-a')` ⇒ `acquired`; gọi lại với `'owner-b'` ⇒ `acquired = false`, `retry_after_seconds > 0`.
  - **E36** chủ cũ không nhả được: `release_publish_series_lease(v_ta, <provider_connection_id của E35>, <invoice_series>, 'owner-b', <lease_version>)` ⇒ dòng `publish_series_leases` vẫn `owner_token = 'owner-a'`, `leased_until > now()`. (Đọc chữ ký `release_…` ở `…019` trước khi viết.)
  - **E37** khoá hết hạn: `update einvoice.publish_series_leases set leased_until = now() - interval '1 second'` cho dòng đó; `acquire(…, 'owner-b')` ⇒ `acquired`, `lease_version` > của E35.
  - **E38** thử lại bền: lệnh nguồn = dòng `internal_commands` loại `einvoice.publish_invoice` có `source_event_id = v_att_e35`; chuyển lượt sang `SUBMITTED` (`update … set status = 'SUBMITTED'`); gọi `record_retryable_provider_publish_rejection(v_ta, v_att_e35, <id lệnh nguồn>, <idempotency_key>, <canonical_payload_hash>, 'InvoiceNumberNotCotinuous', 'th08', 5)` ⇒ `('PREPARING', 1, true)`, có đúng 1 lệnh con `source_event_id = <id lệnh nguồn>` với `enqueued_at >= now() + interval '4 seconds'`; lặp 2 lần nữa (mỗi lần: lượt về `SUBMITTED`, nguồn = lệnh con vừa tạo) ⇒ `retry_count` 2, 3, lần 3 hẹn ≥ 29 giây; lần thứ 4 ⇒ `attempt_status = 'FAILED'`, `scheduled_publish_retry = false`, không thêm lệnh con.
  - **E39** gọi lại cùng nguồn: trước lần thứ 4 của E38, gọi lại với nguồn của lần 3 ⇒ `scheduled_publish_retry = true`, `retry_count` vẫn 3, số lệnh `publish_invoice` của lượt không đổi. (Viết E39 xen giữa lần 3 và lần 4 của E38.)
- [ ] **6.2** PLAN.md (dòng 7-E2a / b / c đã tách lúc viết plan): dòng **7-E2a** Làm ✅ + ngày; dòng 7-C thêm "xét xoá `renew_publish_series_lease` (Edge Function không gia hạn khoá, 7-E2a Q2)".
- [ ] **6.3** TH-08: 9.2 dòng 7.4 ghi "7-E1 / 7-E2a / 7-E2b / 7-E2c"; 9.1 "Sau refactor" thêm "khoá ký hiệu không gia hạn (khoá 300 giây > giới hạn 150 giây của Edge Function)".
- [ ] **6.4** Plan 7-E1: dòng "Sau:" — "7-E2 (8 handler còn lại + 5 dead-letter …)" → "7-E2a / 7-E2b / 7-E2c (8 handler còn lại + 6 dead-letter …)"; mục 1 "Không làm" "5 dead-letter" → "6 dead-letter". Chỉ hai chỗ đó.
- [ ] **6.5** `node .gitnexus/run.cjs analyze` rồi `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory --scope all`: chỉ tệp trong plan; ghi số tệp / symbol / luồng / rủi ro. Hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu `analyze` sửa.

## 6. Review Focus (chưa ca nào chạy — phiên review soi)

1. **Phát hành trùng:** mọi nhánh sau `markProviderCallStarted` mà lỗi (RPC ghi kết quả lỗi, function bị cắt ở 150 giây, `release` lỗi) phải dẫn tới `prepare_issuance_publish` → `RECONCILE_ONLY` ở lần chạy sau, không bao giờ `CALL_PROVIDER` lần hai. Review lần theo từng `throw` trong `publish_invoice.ts` và trạng thái lượt trong `…007`.
2. **Bộ phân loại lệch Dart:** một nhánh đổi thứ tự (vd. `PROVIDER_UNCORRELATED_RESPONSE` trước / sau `isSuccess`) hoặc lẫn `definiteFailureCodes` với `publishRejectionCodes` ⇒ lỗi chưa rõ thành thất bại chắc chắn ⇒ người dùng phát hành lại ⇒ trùng. Review đặt `publish_classifier.ts` / `issuance_status_classifier.ts` cạnh bản Dart.
3. **`release` lỗi che lỗi gốc:** `finally { await release }` ném ⇒ lỗi gốc của dispatch bị mất (JS `finally` ném đè). Dart cũng vậy; review chấp nhận hoặc đề xuất bắt lỗi `release` + log `lease_release_error`.
4. **Số tiền / chữ số:** `canonical_mapper` đổi `int` / `double` Dart sang `number` — làm tròn VND, `vndAmountInWords` với số lớn, `toStringAsFixed` → `toFixed`; review so ca test tiền và đọc `_normalizeCanonicalAmounts`.
5. **Lộ bí mật:** `failure_message` của preview (`safePreviewFailureDetail`, 180 ký tự) và `String(error)` trong dead-letter / `internal_commands.error` đi vào DB và màn hình; review xem chuỗi lỗi client MISA có bao giờ chứa mật khẩu / token / thân phản hồi chứa dữ liệu người mua.

## 7. Kiểm tra

### 7.1 Tự động
Task 5.5 (`deno check`, `deno lint`, `deno test`), Task 6.5 (`detect-changes`). Không có test Dart (plan không đổi app).

### 7.2 Việc của người dùng
- DB local: reset rồi `psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/einvoice_th08.sql` → `einvoice_th08: OK` (gồm E32–E39). Ca nào FAIL ⇒ báo phiên sửa.
- (Tuỳ chọn, sau 7-E3) xem trước / phát hành trên MISA sandbox theo checklist 7-E3.

## 8. Rủi ro / lưu ý

- **Outbox chưa ai đọc:** `record_issuance_success` / `_failure` / `record_publish_command_dead_letter` vẫn ghi `einvoice.outbox_messages` (`electronic_invoice.registered`, `issuance.failed`, `issuance.processing`); không còn worker đọc ⇒ gửi email tự động sau phát hành chưa chạy tới 7-E3 (KI-20). Không chặn 7-E2a.
- **Khoá treo khi function bị cắt:** khoá ký hiệu giữ tới 300 giây ⇒ lệnh phát hành khác cùng ký hiệu bị dời tới 5 phút. Bản Dart cũng vậy khi worker chết.
- **Một lệnh phát hành có thể chiếm gần hết ngân sách:** MISA chờ tối đa 60 giây; ngân sách 90 giây của 7-E1 chỉ kiểm giữa các việc (7-E1 Review Focus 5).
- **Plan dựa trên interface của plan 7-E1, chưa phải code:** nếu 7-E1 Kết quả ghi lệch tên / chữ ký, phiên code 7-E2a theo code thật và ghi lệch vào Kết quả.
- **SQL E38 đổi trạng thái lượt bằng `update` tay** (giả lập handler đã `prepare` → `SUBMITTED`); ca chỉ kiểm hàm SQL, không kiểm handler.

## 9. Kết quả (phiên làm code ghi)

<!-- Mẫu mỗi task:
**Task N — ✅/🔄**
- Tệp: `đường/dẫn:dòng` (tạo / sửa), số dòng.
- Lệch plan + lý do:
- Ca test: tên + số ca đạt / lỗi (lệnh đã chạy).
- Impact: symbol / luồng / rủi ro (Task 5.1, 6.5).
-->

## 10. Review (phiên review ghi)
