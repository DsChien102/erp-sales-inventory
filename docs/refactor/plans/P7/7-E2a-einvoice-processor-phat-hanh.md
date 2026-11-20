# 7-E2a — HĐĐT: `einvoice-processor` luồng phát hành — handler `preview_invoice`, `publish_invoice` (+ khoá ký hiệu), `poll_issuance_status` + 2 dead-letter

> Theme 8 (mã cũ P7) · Phần server. 7-E2 tách 3 plan theo luồng (người dùng chốt 2026-11-08): **7-E2a phát hành** → 7-E2b bản chính thức / tài liệu / quan sát → 7-E2c gửi email.
> Gồm: việc 7.4 phần phát hành (3/9 handler + 2/6 dead-letter); ca SQL khoá ký hiệu và thử lại bền (E41–E45).
> Trạng thái: Plan ✅ (viết 2026-11-08, rà lại theo code 7-E1 cùng ngày, duyệt 2026-11-08) | Làm ✅ 2026-11-08 | Review R2 ✅ 2026-11-08
> **Trước: 7-E1 Làm ✅** (xong 2026-11-08, 137 ca xanh). Plan này sửa `handlers/registry.ts`, `index.ts`, `queue/processor_test.ts` của 7-E1 và dùng `CommandHandler`, `CommandContext`, `ClaimedCommand`, `DeadLetterHandler` (`queue/types.ts`), `PublishSeriesLeaseBusyError`, `ProviderUnavailableError` (`queue/errors.ts`), `TenantMisaClientFactory`, `CredentialsReader` (`handlers/misa_client_factory.ts`), `safeFailureReason`, `SyncCapabilitiesDeps` (`handlers/sync_capabilities.ts`), `classifyInvoiceSeries` (`handlers/template_ref.ts`), `mockFetch` (`misa/test_support.ts`), client `misa/mod.ts`. Tên / chữ ký trong plan đã đối chiếu code 7-E1 (mục 3). Sau: 7-E2b, 7-E2c (dùng lại khuôn `handlers/<luồng>/` + `supabase_gateways.ts` của plan này), 7-E3.
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

- `deno test supabase/functions/einvoice-processor` xanh: 137 ca của 7-E1 + 106 ca chép từ Dart (mục 5, bảng Task) + ca mới (2 ở Task 3 / 5, 3 ở `handlers/issuance/processor_integration_test.ts`).
- `deno check supabase/functions/einvoice-processor/index.ts`, `deno lint supabase/functions/einvoice-processor` không lỗi.
- `einvoice.preview_invoice` → `store_preview_result` `READY` / `FAILED` (`PROVIDER_REJECTED_INVOICE_DATA` | `PROVIDER_AUTH_FAILED`, nguồn `PROVIDER`); MISA không phản hồi → thử lại, hết lượt → `FAILED / PROVIDER_UNAVAILABLE / INTERNAL`.
- `einvoice.publish_invoice` → khoá ký hiệu → `prepare_issuance_publish` → (gọi MISA) → đúng một trong `record_issuance_success` / `_failure` / `_undetermined` / `record_retryable_provider_publish_rejection`; khoá bận → dời việc theo `retry_after_seconds`, không tính lượt.
- `einvoice.poll_issuance_status` → `claim_issuance_reconciliation_case` → `getStatus` → ghi kết quả + `resolve_reconciliation_case`, hoặc hẹn lần sau theo lịch 30 s / 2 phút / 10 phút / 30 phút / 2 giờ, quá 5 lần → `POLL_MAX_CHECKS_EXCEEDED`.
- `einvoice_th08.sql` có E41–E45 (người dùng chạy).

**Không làm:** `fetch_official_view`, `download_invoice_document`, `poll_provider_observation` + 2 dead-letter (7-E2b); `send_invoice_email`, `reconcile_invoice_delivery` + 2 dead-letter (7-E2c); xử lý outbox `einvoice.electronic_invoice.registered` / `issuance.failed` mà các `record_issuance_*` đang ghi (7-E3, KI-20); xoá `renew_publish_series_lease` (7-C xét); sửa migration.

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | 7-E2 (8 handler + dead-letter, ~3.000 dòng Dart, ~160 ca test) một plan hay nhiều | **Người dùng chốt 2026-11-08 (A):** 3 plan theo luồng: 7-E2a phát hành, 7-E2b bản chính thức / tài liệu / quan sát, 7-E2c gửi email; làm nối tiếp a → b → c |
| Q2 | Nhịp gia hạn khoá ký hiệu (Dart: `renew` mỗi 30 giây, mất khoá → `PublishSeriesLeaseBusy(1s)` trước khi gọi MISA). Khoá sống 300 giây (`20261031019:65`, `:165`), Edge Function bị cắt ở 150 giây ⇒ trong một lần gọi khoá không bao giờ hết hạn | **Người dùng chốt 2026-11-08 (A):** bỏ nhịp gia hạn và kiểm `isLost`; giữ lấy khoá → `try` … `finally release`. Bỏ 2 ca Dart `renews sequentially while provider call is still running`, `lost lease before provider call prevents MISA dispatch` |
| Q3 | Chép test nào | **Người dùng chốt 2026-11-08 (A):** chép test đơn vị (handler, adapter, phân loại, dead-letter, lịch đối soát), giữ tên ca. Không chép harness SQL giả (`einvoice_publish_invoice_worker_test`, `preview_invoice_worker_test`) — thay bằng 3 ca `FakeQueueRpc` (phần thuộc Edge Function) + E41–E45 SQL (phần thuộc DB). Không chép test hợp đồng SQL / tích hợp / đăng ký DI |
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
| Test SQL | `supabase/tests/einvoice_th08.sql` | chưa có ca nào về khoá ký hiệu / thử lại bền; 7-E1 thêm E32–E34 và **E40** (R1-1, `:823-841`, ngay trước `raise notice 'einvoice_th08: OK'` ở `:843`) ⇒ ca mới đánh số **E41–E45**, đặt sau E40; tránh trùng biến 7-E1 đã khai báo (`v_cmd`, `v_tok`, `v_rc`, `v_due`, `v_n`, `v_case`) |
| KI-23 (7-E1 R1-1) | `…009` (`open_reconciliation_case`, `record_issuance_undetermined`, `record_reconciliation_pending`, `seed_due_issuance_reconciliation_commands`, …) | 7 câu `insert into internal_commands` từng ghi cột `created_at` không có — **đã sửa** ở 7-E1 ⇒ `record_issuance_undetermined` / `record_reconciliation_pending` mà plan này gọi chạy được (sau khi người dùng reset DB) |
| `handlers/registry.ts` (7-E1) | `:5-10` | `buildHandlers(deps: SyncCapabilitiesDeps)`; `DEAD_LETTER_HANDLERS` là hằng `{}`; chỉ `index.ts` dùng (`:78`, `:81`) |
| `index.ts` (7-E1) | `:77-82` | `clientFactory` giữ ở cấp module (`:11-12`, `??=`); `buildHandlers(...)` và `ConnectionRecorder` dựng **mỗi lần gọi** |
| `FakeQueueRpc` (7-E1) | `queue/processor_test.ts:8-68` (cùng `cmd()` `:57`) | lớp **riêng của tệp test**, không export ⇒ Task 5 tách ra `queue/test_support.ts` |
| Trợ giúp test MISA (7-E1) | `misa/test_support.ts` (`mockFetch`, `jsonResponse`, `textResponse`); `handlers/sync_capabilities_test.ts` (`ScriptedClient extends FakeMeInvoiceClient`) | thay `MockClient` / client giả của Dart |
| Kiểu MISA (7-E1) | `misa/models/me_invoice_sign_type.ts`, `misa/models/requests/invoice_query.ts` | enum Dart → `const` object `{ name, wireValue }` (`MeInvoiceSignType.hsmWithCks` = 2, `.hsmNoCks` = 5; `MeInvoiceStatusInputType.transactionId` = 1, `.refId` = 2); `MeInvoiceInvoiceQuery.tryFromInvSeries` có; `MeInvoicePublishRequest(signType, invoiceData[])`; `MeInvoiceResult.isSuccess` = `data !== null && error === null` |
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

- `handlers/registry.ts`: `export type HandlerDeps = SyncCapabilitiesDeps & { issuance: { provider: IssuanceProvider; gateways: IssuanceGateways } }`; `buildHandlers(deps: HandlerDeps)`; trả thêm `'einvoice.preview_invoice'`, `'einvoice.publish_invoice'`, `'einvoice.poll_issuance_status'`. `DEAD_LETTER_HANDLERS` (hằng `{}` của 7-E1) đổi thành `buildDeadLetters(deps: HandlerDeps): Record<string, DeadLetterHandler>` trả `createIssuanceDeadLetters(deps.issuance.gateways)` (cần gateway thật nên không còn là hằng); xoá `DEAD_LETTER_HANDLERS`.
- `index.ts` (`:77-82`): giữ cách 7-E1 — `clientFactory` ở cấp module, phần còn lại dựng mỗi lần gọi: `const deps: HandlerDeps = { clients: clientFactory, recorder: connectionRecorder(client), env, issuance: { provider: createIssuanceProvider({ clients: clientFactory }), gateways: createSupabaseIssuanceGateways(client) } }`; `buildHandlers(deps)`, `deadLetters: buildDeadLetters(deps)`. Token MISA vẫn nằm trong `clientFactory` nên không mất giữa các lần gọi.

## 5. Các bước

**Ràng buộc chung** (mọi task):
- Lệnh test: `deno test supabase/functions/einvoice-processor` (từ gốc repo), không cần quyền mạng. Lệnh kiểm: `deno check supabase/functions/einvoice-processor/index.ts`, `deno lint supabase/functions/einvoice-processor`.
- Test chép từ Dart: **giữ tên ca** (`Deno.test('<group> <ca>', …)`), giữ dữ liệu đầu vào và giá trị so sánh; ca phải đổi (kiểu thời gian, chuỗi `String(e)` theo Q5, cách bắt lỗi) ghi Kết quả. HTTP giả dùng `mockFetch` của `misa/test_support.ts` (thay `MockClient`); client giả dùng `FakeMeInvoiceClient` hoặc lớp con kịch bản như `ScriptedClient` trong `handlers/sync_capabilities_test.ts`.
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

- [x] **1.1** Chép 4 tệp test (7 tệp Dart, bảng trên); chạy, thấy đỏ.
- [x] **1.2** Viết 5 tệp theo G1, G2; chạy, thấy 41 ca xanh.
- [x] **1.3** Ghi Kết quả: số dòng TS / Dart của `canonical_mapper`; chỗ đổi kiểu số (Dart `int` / `double` → `number`: kiểm ca làm tròn tiền, `vndAmountInWords`).

### Task 2: `issuance_provider.ts` (G3)

**Files:** Create: `handlers/issuance/issuance_provider.ts`; Test: `issuance_provider_test.ts` (18 ca)

**Interfaces — Consumes:** Task 1; `TenantMisaClientFactory`, `CredentialsReader`, `MisaEnv`, `safeFailureReason` (7-E1). **Produces:** `IssuanceProvider`, `createIssuanceProvider`, `safePreviewFailureDetail`.

- [x] **2.1** Chép 2 tệp test. Dart dựng adapter với `rpcClient` giả trả dòng mật khẩu ⇒ TS dựng `TenantMisaClientFactory` với `CredentialsReader` giả; ca `rethrows mapped exception on RpcException` ⇒ `CredentialsReader` ném, `assertRejects` cùng lỗi; ca kiểm log ⇒ truyền `log` giả, so `event` + `reason`, và khẳng định chuỗi log không chứa mật khẩu / tên đăng nhập giả. Chạy, thấy đỏ.
- [x] **2.2** Viết theo G3; chạy, thấy 18 ca xanh.

### Task 3: Gateway + handler xem trước và phát hành (G4, G5)

**Files:** Create: `handlers/issuance/gateways.ts`, `supabase_gateways.ts`, `preview_invoice.ts`, `publish_invoice.ts`, `fake_gateways.ts` (bản giả dùng chung cho test Task 3–5: ghi mọi lời gọi theo thứ tự, trả giá trị dựng sẵn); Test: `preview_invoice_test.ts` (7), `publish_invoice_test.ts` (13)

**Interfaces — Consumes:** Task 1, 2 (`IssuanceProvider` — test dùng bản giả tự viết trong `fake_gateways.ts`: `FakeIssuanceProvider` trả outcome dựng sẵn, ghi lời gọi); `CommandHandler`, `CommandContext`, `ClaimedCommand`, `PublishSeriesLeaseBusyError`, `ProviderUnavailableError` (7-E1). **Produces:** mọi kiểu G4; `createSupabaseIssuanceGateways`; `createPreviewInvoiceHandler`, `createPublishInvoiceHandler`; `FakeIssuanceGateways`, `FakeIssuanceProvider`.

- [x] **3.1** Chép test. Ca `*_json_test` (Dart kiểm `fromJson` / `toJson`) ⇒ TS kiểm handler đọc đúng payload SQL ở mục 3 (dựng `ClaimedCommand` với payload đó, handler gọi provider với đúng `canonical_invoice` / `idempotency_key`). Ca publish `busy lease throws before preparePublish and does not release acquired lease` ⇒ `assertRejects(PublishSeriesLeaseBusyError)`, `retryAfterSeconds` đúng, không có `preparePublish` / `release`. Ca `does not dispatch RecordIssuanceResultCommand` ⇒ khẳng định gateway không nhận `recordSuccess` ngoài nhánh `success`. Thêm 1 ca: `releases the lease when the provider call throws` — `FakeIssuanceProvider.publish` ném ⇒ handler ném lại, `release` được gọi đúng 1 lần với `leaseVersion` của `acquired`. Chạy, thấy đỏ.
- [x] **3.2** Viết `gateways.ts`, `fake_gateways.ts`, `preview_invoice.ts`, `publish_invoice.ts`; chạy, thấy xanh.
- [x] **3.3** Viết `supabase_gateways.ts` (G4, không test đơn vị). Ghi Kết quả bảng: hàm TS → tên RPC → tham số `p_*` → nguồn mapper Dart (tệp:dòng).

### Task 4: Đối soát trạng thái + ghi kết quả (G5)

**Files:** Create: `handlers/issuance/record_issuance_result.ts`, `poll_issuance_status.ts`; Test: `record_issuance_result_test.ts` (14), `poll_issuance_status_test.ts` (9)

**Interfaces — Consumes:** Task 1, 3 (`FakeIssuanceGateways`, `FakeIssuanceProvider`). **Produces:** `recordIssuanceResult`, `createPollIssuanceStatusHandler`.

- [x] **4.1** Chép test (Dart dùng `IEinvoiceCommandDispatcher` giả để bắt `RecordIssuanceResultCommand` ⇒ TS khẳng định `FakeIssuanceGateways.results` nhận `recordSuccess` / `recordDefiniteFailure` với cùng evidence). Chạy, thấy đỏ.
- [x] **4.2** Viết 2 tệp; chạy, thấy xanh.

### Task 5: Dead-letter + đăng ký + `index.ts` (G5, G6)

**Files:** Create: `handlers/issuance/dead_letters.ts`, `queue/test_support.ts`; Modify: `handlers/registry.ts`, `index.ts`, `queue/processor_test.ts` (7-E1, chỉ chuyển `FakeQueueRpc` + `cmd()` sang `test_support.ts` rồi import lại); Test: `handlers/issuance/dead_letters_test.ts` (4 + 1), `handlers/issuance/processor_integration_test.ts` (3)

**Interfaces — Consumes:** Task 1–4; `runInvocation`, `buildHandlers`, `SyncCapabilitiesDeps` (7-E1). **Produces:** `createIssuanceDeadLetters`, `HandlerDeps`, `buildDeadLetters`; `export class FakeQueueRpc`, `export function cmd(commandType: string, retryCount = 0): ClaimedCommand` trong `queue/test_support.ts` (giữ nguyên thân của 7-E1, kèm `type Call`; `cmd()` trả `payload: {}` ⇒ ca cần payload dùng `{ ...cmd(t, n), payload: {...} }`; 7-E2b / c dùng lại).

- [x] **5.1** Chạy `node .gitnexus/run.cjs analyze` (7-E1 chưa chạy được — tệp `.ts` mới chưa vào chỉ mục; hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu bị sửa), rồi `impact({target: "buildHandlers", direction: "upstream"})`, `impact({target: "DEAD_LETTER_HANDLERS", direction: "upstream"})`, `impact({target: "FakeQueueRpc", direction: "upstream"})`. Kỳ vọng theo mục 3: chỉ `index.ts` / `processor_test.ts`. Ghi Kết quả (không chạy được `analyze` thì ghi lý do và dùng `grep -rn` thay).
- [x] **5.1b** Tách `FakeQueueRpc` + `cmd()` sang `queue/test_support.ts` (export), `processor_test.ts` import lại; chạy `deno test supabase/functions/einvoice-processor/queue` ⇒ 14/14 như trước.
- [x] **5.2** `dead_letters_test.ts`: chép 4 ca (2 ca Dart publish chạy qua worker ⇒ TS gọi thẳng handler dead-letter với lỗi tương ứng: `CanonicalInvoiceIntegrityError` → `recordCommandIntegrityFailure(…, 'COMMAND_INTEGRITY')`; lỗi thường → `recordPublishCommandDeadLetter(…, String(error))`). Ca mới `registers dead letters for preview and publish` — `Object.keys(buildDeadLetters(deps)).sort()` = `['einvoice.preview_invoice', 'einvoice.publish_invoice']`.
- [x] **5.3** `handlers/issuance/processor_integration_test.ts` — 3 ca (dùng `runInvocation` + `FakeQueueRpc` / `cmd()` của `queue/test_support.ts` + handler thật dựng từ `FakeIssuanceGateways` / `FakeIssuanceProvider`; đặt ở `handlers/` để `queue/` không phụ thuộc handler, như 7-E1 G3):
  - `publish lease busy reschedules by retry_after without consuming an attempt` — `lease.tryAcquire` trả `busy(17)` ⇒ `reschedule(…, 17)`, không `retryOrDeadLetter` / `fail`.
  - `publish retryable rejection completes the command without dead-letter` — provider trả `retryableRejection` ⇒ `recordRetryableProviderRejection` 1 lần, `complete` 1 lần, không dead-letter.
  - `publish failure on third attempt dead-letters to recordPublishCommandDeadLetter` — `retryCount: 2`, provider ném, `retryOrDeadLetter` trả `DEAD_LETTER` ⇒ `recordPublishCommandDeadLetter(t, attemptId, <String(lỗi)>)` 1 lần.
- [x] **5.4** Chạy, thấy đỏ; viết `dead_letters.ts`, sửa `registry.ts`, `index.ts` theo G6; chạy, thấy xanh. `handlers/sync_capabilities_test.ts` không gọi `buildHandlers` ⇒ không phải sửa.
- [x] **5.5** `deno check supabase/functions/einvoice-processor/index.ts`, `deno lint supabase/functions/einvoice-processor`, `deno test supabase/functions/einvoice-processor` — ghi số ca đạt / lỗi (tách: của 7-E1, của 7-E2a).
- [x] **5.6** `grep -rn "password\|access_token\|accessToken\|username" supabase/functions/einvoice-processor/handlers/issuance --include=*.ts | grep -v _test.ts | grep -i "log\|console"` ⇒ không dòng nào log bí mật; ghi Kết quả.

### Task 6: SQL E41–E45 + tài liệu + `detect_changes` + Kết quả

**Files:** Modify: `supabase/tests/einvoice_th08.sql` (sau E40 của 7-E1 `:841`, trước `raise notice 'einvoice_th08: OK'` `:843`), `docs/refactor/PLAN.md`, `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md`, `docs/refactor/plans/P7/7-E1-einvoice-processor-khung.md` (chỉ dòng "Sau:" và mục 1 "Không làm"; **không** sửa mục 9 / 10)

- [x] **6.1** Thêm ca vào `einvoice_th08.sql` (biến mới ở `declare`; chạy dưới `reset role`; dùng lượt của đơn `v_oa` — `v_att_e41 := public._th08_attempt_id(v_oa, 1)`, đang `PREPARING` từ E10; **không** dùng `v_att1` vì E19 đã gán lại):
  - **E41** khoá bận: `acquire_publish_series_lease(v_ta, v_att_e41, 'owner-a')` ⇒ `acquired`; gọi lại với `'owner-b'` ⇒ `acquired = false`, `retry_after_seconds > 0`.
  - **E42** chủ cũ không nhả được: `release_publish_series_lease(v_ta, <provider_connection_id của E41>, <invoice_series>, 'owner-b', <lease_version>)` ⇒ dòng `publish_series_leases` vẫn `owner_token = 'owner-a'`, `leased_until > now()`. (Đọc chữ ký `release_…` ở `…019` trước khi viết.)
  - **E43** khoá hết hạn: `update einvoice.publish_series_leases set leased_until = now() - interval '1 second'` cho dòng đó; `acquire(…, 'owner-b')` ⇒ `acquired`, `lease_version` > của E41.
  - **E44** thử lại bền: lệnh nguồn = dòng `internal_commands` loại `einvoice.publish_invoice` có `source_event_id = v_att_e41`; chuyển lượt sang `SUBMITTED` (`update … set status = 'SUBMITTED'`); gọi `record_retryable_provider_publish_rejection(v_ta, v_att_e41, <id lệnh nguồn>, <idempotency_key>, <canonical_payload_hash>, 'InvoiceNumberNotCotinuous', 'th08', 5)` ⇒ `('PREPARING', 1, true)`, có đúng 1 lệnh con `source_event_id = <id lệnh nguồn>` với `enqueued_at >= now() + interval '4 seconds'`; lặp 2 lần nữa (mỗi lần: lượt về `SUBMITTED`, nguồn = lệnh con vừa tạo) ⇒ `retry_count` 2, 3, lần 3 hẹn ≥ 29 giây; lần thứ 4 ⇒ `attempt_status = 'FAILED'`, `scheduled_publish_retry = false`, không thêm lệnh con.
  - **E45** gọi lại cùng nguồn: trước lần thứ 4 của E44, gọi lại với nguồn của lần 3 ⇒ `scheduled_publish_retry = true`, `retry_count` vẫn 3, số lệnh `publish_invoice` của lượt không đổi. (Viết E45 xen giữa lần 3 và lần 4 của E44.)
- [x] **6.2** PLAN.md (dòng 7-E2a / b / c đã tách lúc viết plan): dòng **7-E2a** Làm ✅ + ngày; dòng 7-C thêm "xét xoá `renew_publish_series_lease` (Edge Function không gia hạn khoá, 7-E2a Q2)".
- [x] **6.3** TH-08: 9.2 dòng 7.4 ghi "7-E1 / 7-E2a / 7-E2b / 7-E2c"; 9.1 "Sau refactor" thêm "khoá ký hiệu không gia hạn (khoá 300 giây > giới hạn 150 giây của Edge Function)".
- [x] **6.4** Plan 7-E1 (nếu tệp còn — plan Làm ✅ + Review ✅ thì đã xoá, khi đó bỏ bước này): dòng "Sau:" — "7-E2 (8 handler còn lại + 5 dead-letter …)" → "7-E2a / 7-E2b / 7-E2c (8 handler còn lại + 6 dead-letter …)"; mục 1 "Không làm" "5 dead-letter" → "6 dead-letter". Chỉ hai chỗ đó.
- [x] **6.5** `node .gitnexus/run.cjs analyze` (lại) rồi `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory --scope all`: chỉ tệp trong plan; ghi số tệp / symbol / luồng / rủi ro. Hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu `analyze` sửa.

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
- DB local: reset rồi `psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/einvoice_th08.sql` → `einvoice_th08: OK` (gồm E32–E34, E40–E45). Ca nào FAIL ⇒ báo phiên sửa.
- (Tuỳ chọn, sau 7-E3) xem trước / phát hành trên MISA sandbox theo checklist 7-E3.

## 8. Rủi ro / lưu ý

- **Outbox chưa ai đọc:** `record_issuance_success` / `_failure` / `record_publish_command_dead_letter` vẫn ghi `einvoice.outbox_messages` (`electronic_invoice.registered`, `issuance.failed`, `issuance.processing`); không còn worker đọc ⇒ gửi email tự động sau phát hành chưa chạy tới 7-E3 (KI-20). Không chặn 7-E2a.
- **Khoá treo khi function bị cắt:** khoá ký hiệu giữ tới 300 giây ⇒ lệnh phát hành khác cùng ký hiệu bị dời tới 5 phút. Bản Dart cũng vậy khi worker chết.
- **Một lệnh phát hành có thể chiếm gần hết ngân sách:** MISA chờ tối đa 60 giây; ngân sách 90 giây của 7-E1 chỉ kiểm giữa các việc (7-E1 Review Focus 5).
- **Plan dựa trên interface của plan 7-E1, chưa phải code:** nếu 7-E1 Kết quả ghi lệch tên / chữ ký, phiên code 7-E2a theo code thật và ghi lệch vào Kết quả.
- **SQL E44 đổi trạng thái lượt bằng `update` tay** (giả lập handler đã `prepare` → `SUBMITTED`); ca chỉ kiểm hàm SQL, không kiểm handler.

## 9. Kết quả (phiên làm code ghi)

**Task 1 — ✅**
- Tệp:
  - `supabase/functions/einvoice-processor/handlers/issuance/outcomes.ts:1-75` (tạo mới, 75 dòng)
  - `supabase/functions/einvoice-processor/handlers/issuance/errors.ts:1-21` (tạo mới, 21 dòng)
  - `supabase/functions/einvoice-processor/handlers/issuance/canonical_mapper.ts:1-456` (tạo mới, 456 dòng so với Dart 570 dòng)
  - `supabase/functions/einvoice-processor/handlers/issuance/publish_classifier.ts:1-211` (tạo mới, 211 dòng)
  - `supabase/functions/einvoice-processor/handlers/issuance/issuance_status_classifier.ts:1-121` (tạo mới, 121 dòng)
  - `supabase/functions/einvoice-processor/handlers/issuance/outcomes_test.ts:1-36` (tạo mới, 36 dòng)
  - `supabase/functions/einvoice-processor/handlers/issuance/canonical_mapper_test.ts:1-315` (tạo mới, 315 dòng)
  - `supabase/functions/einvoice-processor/handlers/issuance/publish_classifier_test.ts:1-266` (tạo mới, 266 dòng)
  - `supabase/functions/einvoice-processor/handlers/issuance/issuance_status_classifier_test.ts:1-88` (tạo mới, 88 dòng)
- Lệch plan + lý do: Không có. Chỗ đổi kiểu số Dart `int`/`double` sang TS `number` sử dụng `Math.floor` cho phép chia nguyên trong `vndAmountInWords` và `Math.round` cho tính `discountRate`.
- Ca test: `deno test supabase/functions/einvoice-processor/handlers/issuance/` đạt 41/41 (outcomes: 4, canonical_mapper: 19, publish_classifier: 13, issuance_status_classifier: 5). `deno check` và `deno lint` sạch.
- Impact: Thêm module mới `handlers/issuance`, chưa nối vào `registry.ts`.

**Task 2 — ✅**
- Tệp:
  - `supabase/functions/einvoice-processor/handlers/issuance/issuance_provider.ts:1-175` (tạo mới, 175 dòng)
  - `supabase/functions/einvoice-processor/handlers/issuance/issuance_provider_test.ts:1-512` (tạo mới, 512 dòng)
- Lệch plan + lý do: Không có. Adapter dùng `TenantMisaClientFactory`, `safeFailureReason` và kiểm soát không log secret/password. Thêm 1 ca test cho `safePreviewFailureDetail` (tổng 19 ca).
- Ca test: `deno test supabase/functions/einvoice-processor/handlers/issuance/issuance_provider_test.ts` đạt 19/19 (18 ca chép từ Dart + 1 ca helper detail). `deno check` và `deno lint` sạch.
- Impact: Cung cấp `createIssuanceProvider`, `IssuanceProvider`, `safePreviewFailureDetail`.

**Task 3 — ✅**
- Tệp:
  - `supabase/functions/einvoice-processor/handlers/issuance/gateways.ts:1-104` (tạo mới, 104 dòng)
  - `supabase/functions/einvoice-processor/handlers/issuance/fake_gateways.ts:1-302` (tạo mới, 302 dòng)
  - `supabase/functions/einvoice-processor/handlers/issuance/preview_invoice.ts:1-62` (tạo mới, 62 dòng)
  - `supabase/functions/einvoice-processor/handlers/issuance/publish_invoice.ts:1-141` (tạo mới, 141 dòng)
  - `supabase/functions/einvoice-processor/handlers/issuance/supabase_gateways.ts:1-372` (tạo mới, 372 dòng)
  - `supabase/functions/einvoice-processor/handlers/issuance/preview_invoice_test.ts:1-135` (tạo mới, 135 dòng, 7 ca)
  - `supabase/functions/einvoice-processor/handlers/issuance/publish_invoice_test.ts:1-277` (tạo mới, 277 dòng, 14 ca)
- Lệch plan + lý do: Không có. Thêm 1 ca `releases the lease when the provider call throws` vào `publish_invoice_test.ts` theo đúng yêu cầu Task 3.1.
- Ca test: 21 ca đạt (preview: 7 ca, publish: 14 ca). Lũy kế `handlers/issuance/` đạt 81 ca xanh.
- Bảng đối chiếu RPC `supabase_gateways.ts`:
  | Hàm TS | Tên RPC | Tham số `p_*` | Nguồn mapper Dart |
  |---|---|---|---|
  | `preview.store` | `store_preview_result` | `p_tenant_id`, `p_sales_order_id`, `p_request_id`, `p_status`, `p_viewer_ref`, `p_failure_code`, `p_failure_message`, `p_failure_source` | `supabase_invoice_preview_gateway.dart:78-91` |
  | `lease.tryAcquire` | `acquire_publish_series_lease` | `p_tenant_id`, `p_attempt_id`, `p_owner_token`, `p_lease_seconds` (300) | `publish_series_lease_rpc_mapper.dart:5-17` |
  | `lease.release` | `release_publish_series_lease` | `p_tenant_id`, `p_provider_connection_id`, `p_invoice_series`, `p_owner_token`, `p_lease_version` | `publish_series_lease_rpc_mapper.dart:19-33` |
  | `results.preparePublish` | `prepare_issuance_publish` | `p_tenant_id`, `p_attempt_id`, `p_idempotency_key`, `p_payload_hash`, `p_canonical_payload` | `issuance_rpc_mapper.dart:32-46` |
  | `results.markProviderCallStarted` | `mark_issuance_provider_call_started` | `p_tenant_id`, `p_attempt_id` | `issuance_rpc_mapper.dart:48-53` |
  | `results.recordSuccess` | `record_issuance_success` | `p_tenant_id`, `p_attempt_id`, `p_idempotency_key`, `p_payload_hash`, `p_provider_reference`, `p_invoice_number`, `p_invoice_series`, `p_issued_at` | `issuance_rpc_mapper.dart:55-70` |
  | `results.recordDefiniteFailure` | `record_issuance_failure` | `p_tenant_id`, `p_attempt_id`, `p_idempotency_key`, `p_payload_hash`, `p_provider_code`, `p_provider_message` | `issuance_rpc_mapper.dart:72-85` |
  | `results.recordUndetermined` | `record_issuance_undetermined` | `p_tenant_id`, `p_attempt_id`, `p_idempotency_key`, `p_payload_hash`, `p_reason_code` | `issuance_rpc_mapper.dart:87-99` |
  | `results.recordRetryableProviderRejection` | `record_retryable_provider_publish_rejection` | `p_tenant_id`, `p_attempt_id`, `p_source_command_id`, `p_idempotency_key`, `p_payload_hash`, `p_provider_code`, `p_provider_message`, `p_retry_after_seconds` | `issuance_rpc_mapper.dart:101-118` |
  | `results.recordCommandIntegrityFailure` | `record_issuance_command_integrity_failure` | `p_tenant_id`, `p_attempt_id`, `p_reason_code` | `issuance_rpc_mapper.dart:120-130` |
  | `results.recordPublishCommandDeadLetter` | `record_publish_command_dead_letter` | `p_tenant_id`, `p_attempt_id`, `p_reason_code` | `issuance_rpc_mapper.dart:132-142` |
  | `reconciliation.claim` | `claim_issuance_reconciliation_case` | `p_tenant_id`, `p_case_id`, `p_worker_id` | `issuance_rpc_mapper.dart:364-374` |
  | `reconciliation.recordPendingCheck` | `record_reconciliation_pending` | `p_tenant_id`, `p_case_id`, `p_claim_token`, `p_next_delay_seconds`, `p_check_sequence` | `issuance_rpc_mapper.dart:376-390` |
  | `reconciliation.resolve` | `resolve_reconciliation_case` | `p_tenant_id`, `p_case_id`, `p_outcome`, `p_evidence` (optional) | `issuance_rpc_mapper.dart:392-404` |
- Impact: Cung cấp `createPreviewInvoiceHandler`, `createPublishInvoiceHandler`, `createSupabaseIssuanceGateways`.

**Task 4 — ✅**
- Tệp:
  - `supabase/functions/einvoice-processor/handlers/issuance/record_issuance_result.ts:1-84` (tạo mới, 84 dòng)
  - `supabase/functions/einvoice-processor/handlers/issuance/poll_issuance_status.ts:1-205` (tạo mới, 205 dòng)
  - `supabase/functions/einvoice-processor/handlers/issuance/record_issuance_result_test.ts:1-337` (tạo mới, 337 dòng, 14 ca)
  - `supabase/functions/einvoice-processor/handlers/issuance/poll_issuance_status_test.ts:1-333` (tạo mới, 333 dòng, 9 ca)
- Lệch plan + lý do: Không có. Tương thích hoàn toàn chữ ký `getStatus` nhận 1 tham số đối tượng `input`.
- Ca test: 23 ca đạt (record_issuance_result: 14 ca, poll_issuance_status: 9 ca). Lũy kế `handlers/issuance/` đạt 104 ca xanh. `deno check` và `deno lint` sạch.
- Impact: Cung cấp `recordIssuanceResult`, `validateRecordIssuanceResult`, `createPollIssuanceStatusHandler`.

**Task 5 — ✅**
- Tệp:
  - `supabase/functions/einvoice-processor/handlers/issuance/dead_letters.ts:1-55` (tạo mới, 55 dòng)
  - `supabase/functions/einvoice-processor/queue/test_support.ts:1-66` (tạo mới, 66 dòng)
  - `supabase/functions/einvoice-processor/handlers/registry.ts:1-30` (sửa, cập nhật `HandlerDeps`, `buildHandlers`, `buildDeadLetters`)
  - `supabase/functions/einvoice-processor/index.ts:1-101` (sửa, import và truyền `HandlerDeps` kèm `issuance` provider/gateways và `buildDeadLetters`)
  - `supabase/functions/einvoice-processor/queue/processor_test.ts:1-164` (sửa, import `FakeQueueRpc`, `cmd` từ `./test_support.ts`)
  - `supabase/functions/einvoice-processor/handlers/issuance/dead_letters_test.ts:1-109` (tạo mới, 109 dòng, 5 ca)
  - `supabase/functions/einvoice-processor/handlers/issuance/processor_integration_test.ts:1-103` (tạo mới, 103 dòng, 3 ca)
- Lệch plan + lý do: Không có. Thêm getter alias `get deadLetterCalls()` trên `FakeIssuanceResultGateway` trỏ về `publishDeadLetterCalls` để test code đọc tự nhiên.
- GitNexus Impact:
  - `buildHandlers`: direct callers = `index.ts` (1 file, risk LOW).
  - `DEAD_LETTER_HANDLERS`: direct = 0 (risk LOW).
  - `FakeQueueRpc`: chỉ dùng trong `processor_test.ts` (và sau tách sang `test_support.ts` dùng thêm trong `processor_integration_test.ts`).
  - Hoàn nguyên `AGENTS.md` và `CLAUDE.md` sau `analyze`.
- Ca test:
  - `deno check supabase/functions/einvoice-processor/index.ts`: 0 errors.
  - `deno lint supabase/functions/einvoice-processor`: Checked 90 files, 0 problems.
  - `deno test supabase/functions/einvoice-processor`: 249/249 passed (137 ca của 7-E1, 112 ca của 7-E2a gồm 104 ca unit/mock + 8 ca dead-letters/integration).
- Rà soát bí mật: `grep -rn -E "password|access_token|accessToken|username" supabase/functions/einvoice-processor/handlers/issuance --include="*.ts" | grep -v "_test.ts" | grep -i -E "log|console"` → 0 dòng log bí mật.
- Impact: Đã đăng ký đầy đủ 3 command phát hành (`preview_invoice`, `publish_invoice`, `poll_issuance_status`) và 2 dead-letter handlers vào queue processor.

**Task 6 — ✅**
- Tệp:
  - `supabase/tests/einvoice_th08.sql:337-349,853-1077` (sửa, thêm khai báo biến và các ca E41–E45 kiểm tra khoá ký hiệu phát hành và cơ chế thử lại bền `InvoiceNumberNotCotinuous`)
  - `docs/refactor/PLAN.md:537,544` (sửa, 7-E2a Làm ✅; 7-C ghi chú xét xoá `renew_publish_series_lease`)
  - `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md:1550,1562` (sửa, 9.1 ghi chú khoá ký hiệu không gia hạn; 9.2 dòng 7.4 ghi 7-E1 / 7-E2a / 7-E2b / 7-E2c)
  - `docs/refactor/plans/P7/7-E1-einvoice-processor-khung.md:6,26` (sửa, cập nhật tham chiếu 7-E2a/b/c và 6 dead-letter)
  - `docs/refactor/plans/P7/7-E2a-einvoice-processor-phat-hanh.md` (cập nhật trạng thái Làm ✅, tích các task và ghi nhận kết quả)
- Lệch plan + lý do: Không có.
- GitNexus Detect-changes:
  - Lệnh: `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory --scope all`
  - Kết quả: 8 tệp đã theo dõi (gồm `registry.ts`, `index.ts`, `processor_test.ts`, `einvoice_th08.sql`, 4 tài liệu), 25 symbol, 0 luồng, LOW; 26 tệp mới chưa `git add` nên `detect_changes` không thấy — người dùng chạy lại sau `git add`.
  - Hoàn nguyên `AGENTS.md` / `CLAUDE.md` sạch sẽ.
- Ca test:
  - `deno check supabase/functions/einvoice-processor/index.ts`: 0 errors.
  - `deno lint supabase/functions/einvoice-processor`: Checked 90 files, 0 problems.
  - `deno test supabase/functions/einvoice-processor`: 249/249 tests passed (0 failed).
- Phần việc của người dùng tiếp theo:
  - Reset local DB và chạy test SQL: `psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/einvoice_th08.sql` kỳ vọng in `einvoice_th08: OK` (bao gồm E32–E34, E40 từ 7-E1 và E41–E45 từ 7-E2a).
  - Commit mã nguồn sau khi kiểm tra.

## 10. Review (phiên review ghi)

### R1 — 2026-11-08 — **CHƯA ĐẠT** (1 lỗi ca SQL, 1 sửa Kết quả)

| Hạng mục | Kết quả |
|---|---|
| `deno check index.ts` / `deno lint` | ✅ sạch (lint 90 tệp, 0 lỗi) — review chạy lại |
| `deno test supabase/functions/einvoice-processor` | ✅ 249/249 (7-E1 137 + 7-E2a 112) — review chạy lại; `handlers/issuance` 112/112 |
| Số ca so với bảng mục 5 | ✅ 106 ca chép + 6 ca thêm (provider +1 `safePreviewFailureDetail`, publish +1 `releases the lease…`, dead-letter +1 đăng ký, tích hợp 3); tên ca giữ đúng Dart (soát `publish_invoice_test.ts`) |
| Đối chiếu Dart (RF2, RF4) | ✅ `publish_classifier`, `issuance_status_classifier`, `canonical_mapper` (gồm `vndAmountInWords`, làm tròn `discountRate`), `issuance_provider`, `publish_invoice` (trừ heartbeat theo Q2), `poll_issuance_status`, `record_issuance_result`, 2 dead-letter — thứ tự nhánh, mã lý do, chuỗi MISA giữ từng ký tự |
| `supabase_gateways.ts` ↔ chữ ký SQL | ✅ 14 RPC, tên `p_*` và kiểu trả (`returns table` / `void`) khớp `…006/007/009/019/020`; bảng Task 3 đúng |
| RF1 phát hành trùng | ✅ `prepare_issuance_publish` đổi PREPARING → SUBMITTED **trước** khi trả `CALL_PROVIDER` ⇒ mọi `throw` sau đó (mark, MISA, ghi kết quả, `release`) → lần sau `RECONCILE_ONLY`, không gọi MISA lần hai |
| RF3 `release` ném đè lỗi gốc | ✅ chấp nhận như Dart: sau khi đã ghi kết quả, lần thử lại → `SKIP`; nếu thành dead-letter thì `record_publish_command_dead_letter` bỏ qua lượt `SUCCEEDED/FAILED/RECONCILING` |
| RF5 lộ bí mật | ✅ log chỉ có `reason` / `detail` đã lọc, `reasonCode`; grep 5.6 lặp lại 0 dòng |
| SQL E41–E43, E45 | ✅ đọc đối chiếu `…019` (dùng `clock_timestamp()`), `…020` — đúng |
| SQL E44 | ❌ **R1-1** |
| Mục 9 Kết quả | ❌ **R1-2** (số dòng, `detect_changes`, ô đánh dấu) |
| `detect_changes` (review chạy lại) | 8 tệp đã theo dõi, 25 symbol, 0 luồng, LOW — **không thấy 26 tệp mới chưa `git add`** (`handlers/issuance/*`, `queue/test_support.ts`) |

#### R1 — việc cần sửa

- **R1-1 — E44 so `enqueued_at` với `clock_timestamp()` ⇒ ca gần như chắc FAIL.** `record_retryable_provider_publish_rejection` ghi `enqueued_at = now() + v_delay` (`20261031020:140`, `now()` = giờ **bắt đầu giao dịch**; cả khối `do $$` là một giao dịch). Test so `enqueued_at >= clock_timestamp() + interval '4 seconds'` / `'29 seconds'` (`supabase/tests/einvoice_th08.sql:957`, `:986`, `:1015`) ⇒ chỉ đúng khi từ đầu khối tới E44 trôi ≤ 1 giây; E1–E40 chạy trước nên thường > 1 giây ⇒ `FAIL E44 round 1: child command not found…`. Plan 6.1 ghi `now()`. **Sửa:** ở 3 dòng đổi `clock_timestamp()` → `now()` (giữ `4 seconds` / `29 seconds`). Không đổi chỗ khác: E42 / E43 dùng `clock_timestamp()` là đúng vì `acquire_` / `release_publish_series_lease` dùng `clock_timestamp()`.
- **R1-2 — Kết quả mục 9 lệch số thật.**
  - Số dòng: `canonical_mapper.ts` ghi 408, thật 456; `supabase_gateways.ts` 294 → 372; `poll_issuance_status.ts` 182 → 205; `publish_invoice.ts` 137 → 141; `gateways.ts` 85 → 104; `fake_gateways.ts` 247 → 302 (có vẻ đo trước `deno fmt`). Sửa theo `wc -l` hiện tại.
  - Task 6 `detect_changes`: câu "Chỉ gồm các tệp tài liệu và test đã quy định" sai — 8 tệp gồm cả `handlers/registry.ts`, `index.ts`; và lệnh không thấy tệp chưa theo dõi. Ghi lại: "8 tệp đã theo dõi (gồm `registry.ts`, `index.ts`, `processor_test.ts`, `einvoice_th08.sql`, 4 tài liệu), 25 symbol, 0 luồng, LOW; 26 tệp mới chưa `git add` nên `detect_changes` không thấy — người dùng chạy lại sau `git add`".
  - Ô `- [ ]` của Task 1.1–3.3 chưa đánh dấu dù Kết quả ghi ✅ ⇒ đánh `[x]`.

#### Ghi nhận (không bắt sửa)

- `poll_issuance_status.ts:85`, `:157` dùng `context.attemptId` (dòng claim) thay `payload.attempt_id` như Dart (`command.attemptId`); hai giá trị cùng nguồn `…009` nên tương đương — lệch plan chưa ghi Kết quả, chấp nhận.
- `record_issuance_result.ts:56`: validator ném `'retryable provider rejection must use publish retry gateway path'`; Dart validator ném `'… is not valid RecordIssuanceResult evidence'` (câu kia là của handler). Chuỗi không vào DB / app (Q5) — chấp nhận.
- `vndAmountInWords` với ≥ 10¹² đồng: Dart ném `RangeError` (`digits[10]`), TS ra `"undefined trăm"`. Ngoài thực tế — chấp nhận.
- E44 lần 1 không kiểm "đúng 1 lệnh con" như plan 6.1 (chỉ `select … into`); có ràng buộc duy nhất `(tenant_id, source_event_id, command_type)` nên không thể > 1 — chấp nhận.

### R2 — 2026-11-08 — **ĐẠT**

| Hạng mục | Kết quả |
|---|---|
| R1-1 E44 | ✅ `supabase/tests/einvoice_th08.sql:957`, `:986`, `:1015` so `enqueued_at >= now() + …` (4 s / 29 s / 29 s), khớp `20261031020:140`; E42 / E43 vẫn `clock_timestamp()` (`:893`, `:900`) — đúng |
| R1-2 số dòng | ✅ 26 tệp mới (`handlers/issuance/*.ts`, `queue/test_support.ts`): `tệp:1-N` trong mục 9 khớp `wc -l` từng tệp |
| R1-2 `detect_changes` | ✅ ghi lại: 8 tệp đã theo dõi (gồm `registry.ts`, `index.ts`), 25 symbol, 0 luồng, LOW; 26 tệp mới chưa `git add` |
| R1-2 ô đánh dấu | ✅ Task 1–6 đều `[x]` |
| Hồi quy | ✅ review chạy lại: `deno check` sạch, `deno lint` 90 tệp 0 lỗi, `deno test` 249/249; R2 không đổi code TS (`git diff --stat` chỉ thêm `einvoice_th08.sql` + tài liệu) |

Còn lại (người dùng): `git add` 26 tệp mới rồi chạy lại `detect_changes` trước commit; reset DB local rồi chạy `einvoice_th08.sql` → `einvoice_th08: OK` (E41–E45). Plan giữ tới khi chạy SQL xong (quy ước xoá plan: còn chờ kiểm tay thì giữ).
