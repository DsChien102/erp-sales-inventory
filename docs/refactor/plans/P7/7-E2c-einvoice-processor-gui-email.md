# 7-E2c — HĐĐT: `einvoice-processor` gửi email — handler `send_invoice_email`, `reconcile_invoice_delivery` + 2 dead-letter

> Theme 8 (mã cũ P7) · Phần server. 7-E2 tách 3 plan theo luồng (người dùng chốt 2026-11-08): 7-E2a phát hành → 7-E2b bản chính thức / tài liệu / quan sát → **7-E2c gửi email**.
> Gồm: việc 7.4 phần gửi (2/9 handler cuối + 2/6 dead-letter cuối); sửa dead-letter đối soát gửi đọc payload camelCase (KI-25, Q2). Không đổi SQL.
> Trạng thái: Plan ✅ (viết 2026-11-08, duyệt 2026-11-08) | Làm ✅ 2026-11-08 (chưa commit) | Review R2 ✅ 2026-11-08 (R1: tên ca, gateway bool / int, Kết quả)
> **Trước: 7-E2b Làm ✅ + Review R2 ✅** (2026-11-08; `deno test supabase/functions/einvoice-processor` đo lúc viết plan: **301 ca xanh**). Plan này sửa `handlers/registry.ts`, `index.ts`, `handlers/issuance/dead_letters_test.ts:97-120`, `handlers/issued_invoice/dead_letters_test.ts:140-160` và dùng `CommandHandler`, `CommandContext`, `ClaimedCommand`, `DeadLetterHandler` (`queue/types.ts`), `TenantMisaClientFactory`, `CredentialsReader` (`handlers/misa_client_factory.ts`), `FakeQueueRpc`, `cmd()` (`queue/test_support.ts`), `runInvocation` (`queue/processor.ts`), `maxAttemptsFor` (`queue/attempt_policy.ts`: send 3, reconcile 3 — đã có), `safeErrorCode` (`handlers/issued_invoice/provider_call_support.ts`), `FailureSource` (`handlers/issued_invoice/outcomes.ts`), client `misa/mod.ts` (`MeInvoiceResult` — `data`, `error`, `rateLimited`, `isSuccess`; `MeInvoiceSendEmailRequest`, `MeInvoiceSendEmailData`, `MeInvoiceSendEmailResponse`, `MeInvoiceSendEmailResponseKind`, `MeInvoiceSendEmailResultItem`, `MeInvoiceInvoiceQuery.tryFromInvSeries`, `MeInvoicePublishErrorCodes.isDefiniteFailure`), `FakeMeInvoiceClient` (`enqueueSendEmailResult`, `enqueueSendEmailEnvelopeAcknowledgement`, `sendEmailCount`, `getStatusCount`, `lastSendEmailRequest`). Khuôn thư mục / gateway / bản giả theo `handlers/issued_invoice/` của 7-E2b. Sau: 7-E3.
> Tài liệu: [TH-08](../../../02-yeu-cau/TH-08-hoa-don-dien-tu.md) US-04.1, US-04.2, US-04.3 (FR-01: MISA không có API kiểm kết quả gửi ⇒ `DELIVERY_RESULT_OBSERVATION_UNSUPPORTED` ⇒ `UNRESOLVED`), 6.2 "Lệnh nội bộ", 9.1, 9.2 (PR 7.4). Nguồn chép (`modules/einvoice/`):
> - handler: `application/lib/src/delivery/commands/{send_invoice_email,reconcile_invoice_delivery,record_delivery_result}/`
> - kiểu chung: `application/lib/src/delivery/shared/{delivery_command_payload,prepare_delivery_provider_call_result,delivery_result_evidence,delivery_result_kind,delivery_observation_kind,delivery_observation_outcome,delivery_provider_outcome,delivery_provider_context_dto,delivery_attempt_context_dto,delivery_reconciliation_context_dto,delivery_reconciliation_check_record,delivery_result_record}.dart`; `application/lib/src/electronic_invoice/shared/provider_call_correlation_id.dart`
> - adapter: `infrastructure/lib/src/adapters/misa/{me_invoice_delivery_classifier,me_invoice_delivery_provider_adapter,me_invoice_delivery_observation_provider_adapter}.dart`
> - gateway: `infrastructure/lib/src/domain/delivery/{supabase_delivery_command_gateway,supabase_delivery_reconciliation_gateway}.dart`, `delivery_rpc_mapper.dart:32-111` (tham số), `:199-262` (`attemptContextFromRow`, `prepareResultFromRow`, `prepareResultFromRowWithTenant`), `:113-128` (`reconciliationContextFromRow`), `:399-415` (`_outcomeKindToRpc`, `_observationKindToRpc`)
> - dead-letter: `infrastructure/lib/src/configuration/processing/internal_commands/{delivery_command_dead_letter_handler,delivery_reconciliation_command_dead_letter_handler}.dart`
>
> **Cho phiên code:** dùng `superpowers:executing-plans` (tuần tự). Mỗi task xong ghi ngay mục 9 theo mẫu (tệp:dòng, lệch plan, ca test, impact). **Không commit** (người dùng commit sau `detect_changes()`). **Không làm gì với DB** (không chạy SQL, không reset, không push, không deploy function). **Không đụng `modules/`, `packages/`, `apps/`** (chỉ đọc để chép). **Không ghi mục 10.**

**Goal:** Edge Function `einvoice-processor` chạy được 2 loại lệnh gửi hoá đơn — gửi email qua MISA với chốt `SUBMITTED` (không gửi hai lần), đối soát lần gửi chưa rõ kết quả — cùng RPC, cùng phân loại kết quả MISA như worker Dart cũ; dead-letter đối soát đọc đúng payload SQL ghi (KI-25).

**Architecture:** Thư mục mới `handlers/delivery/`: hàm thuần (đọc payload, mã tham chiếu lượt gọi, bộ phân loại `sendEmail`), `delivery_provider.ts` (gọi `sendEmail` qua `TenantMisaClientFactory`), `delivery_observation_provider.ts` (bản MISA luôn `unsupported`), interface gateway hẹp + bản Supabase thật, 2 handler + 1 hàm ghi kết quả + 2 dead-letter. Handler chỉ phụ thuộc interface, test bằng bản giả. 7-E1 / 7-E2a / 7-E2b chỉ sửa: `registry.ts` / `index.ts` thêm dòng đăng ký; 2 ca đăng ký dead-letter đổi mong đợi.

**Tech Stack:** Deno 2, TypeScript, `npm:@supabase/supabase-js@2` (RPC), `jsr:@std/assert@1`, Web Crypto (`crypto.subtle.digest('SHA-256')`).

## 1. Mục tiêu

- `deno test supabase/functions/einvoice-processor` xanh: 301 ca hiện có + 72 ca chép từ Dart (bảng mục 5) + 8 ca mới (Task 1: 2, Task 3: 3, Task 4: 3) ⇒ tổng **381**.
- `deno check supabase/functions/einvoice-processor/index.ts`, `deno lint supabase/functions/einvoice-processor` không lỗi.
- `einvoice.send_invoice_email` → `load_delivery_attempt_context` (null ⇒ bỏ) → `prepare_delivery_provider_call(p_request_reference = mã lượt gọi)` → `SKIP` ⇒ bỏ; `RECORD_UNKNOWN` ⇒ ghi `UNDETERMINED / DISPATCH_STATE_UNCERTAIN / INTERNAL`, không gọi MISA; `CALL_PROVIDER` ⇒ `sendEmail` đúng **một** lần → phân loại → `record_delivery_result`. MISA ném lỗi sau chốt ⇒ `UNDETERMINED / PROVIDER_TRANSPORT_FAILURE / INTERNAL`. Ghi kết quả lỗi ⇒ ném, lần chạy sau gặp `RECORD_UNKNOWN`. Hết 3 lượt ⇒ dead-letter `record_delivery_command_dead_letter(…, 'WORKER_EXHAUSTED_BEFORE_DISPATCH')` (SQL tự chia `QUEUED` → `FAILED`, `SUBMITTED` → `UNKNOWN` + hồ sơ đối soát).
- `einvoice.reconcile_invoice_delivery` → `load_delivery_reconciliation_context` (null ⇒ bỏ) → không hỗ trợ quan sát ⇒ `record_delivery_reconciliation_check` `UNSUPPORTED / DELIVERY_RESULT_OBSERVATION_UNSUPPORTED`; có ⇒ quan sát rồi ghi theo kết quả. Hết 3 lượt ⇒ dead-letter ghi `UNSUPPORTED / DELIVERY_RECONCILIATION_WORKER_EXHAUSTED` — đọc được payload camelCase.

**Không làm:** đổi migration / SQL (không có ca SQL mới); xếp việc gửi tự động khi phát hành xong (`start_auto_delivery`, KI-19 / KI-20 — 7-E3); seed lại việc đối soát gửi đã hỏng (Q2: chỉ sửa dead-letter); xử lý outbox `einvoice.delivery.result_recorded` / `einvoice.delivery.attention_required` (chưa ai nhận); các RPC phía app (`send_electronic_invoice`, `get_send_invoice_sheet_context`, `get_invoice_delivery_history` — 7-A1).

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | Chép test nào | Như 7-E2b Q1: chép test đơn vị (handler, payload, adapter, phân loại, dead-letter), giữ tên ca. **Không** chép harness `infrastructure/test/einvoice_slice5_integration_test.dart` (27 ca) + `support/slice5_delivery_integration_harness.dart`, test gateway Supabase giả (`supabase_delivery_*_gateway_test`), test hợp đồng SQL (`einvoice_s5_*_sql_contract_test`, `einvoice_goi4_delivery_sql_contract_test`), test đăng ký DI (`einvoice_s5_registration_test`, `einvoice_s5_worker_composition_test`, ca `observation unsupported adapter resolves in composition` của `einvoice_s5_reconciliation_registration_test`), ca phía app (`send_electronic_invoice_*`, `start_auto_delivery_*`, `delivery_query_handlers_test`, `electronic_invoice_registered_integration_event_handler_test`). Chép thêm ca `provider-call correlation differs per worker attempt` của `s4_worker_handlers_test.dart:104-115` (7-E2b bỏ vì chưa dùng; 7-E2c dùng cho `p_request_reference`) |
| Q2 | Payload `reconcile_invoice_delivery` do SQL ghi camelCase (`tenantId`, `reconciliationCaseId`, `checkSequence` — `20261031014:106-111`, `20261031015:394-399`); claim trả payload thô (`20261031002:420-470`, `supabase_queue_rpc.ts:37`); Dart truyền payload thô vào dead-letter (`process_internal_commands_command_handler.dart:81,100`) mà dead-letter chỉ đọc `reconciliation_case_id` (`delivery_reconciliation_command_dead_letter_handler.dart:28-35`) ⇒ luôn `return` ⇒ hồ sơ kẹt `PENDING` (không ai seed đối soát gửi — `processor.ts:99` chỉ seed phát hành) | **Người dùng chốt 2026-11-08 (A):** dead-letter TS đọc cả hai kiểu khoá (snake_case trước, như handler Dart `fromJson`); không đổi SQL; ca mới dùng payload camelCase đúng như SQL ghi; ghi **KI-25** ở TH-08 |
| Q3 | Mã `p_request_reference` (Dart `ProviderCallCorrelationId.forWorkerAttempt(commandId, workerAttemptNumber)`; `workerAttemptNumber = retry_count + 1`, `process_internal_commands_command_handler.dart:49`) | `providerCallReference(commandId: string, attemptNumber: number): Promise<string>` — hex SHA-256 chữ thường của `` `${commandId}|provider-call|${attemptNumber}` ``, ghép `8-4-4-4-12` từ 32 ký tự đầu. Handler gọi với `ctx.command.commandId`, `ctx.attemptNumber` (= `retryCount + 1`, `processor.ts:65`). Giá trị mẫu: `('cmd-1', 1)` ⇒ `7d99ddea-18d5-bea4-c874-7b0de44f56a5` (đo bằng `shasum -a 256`) |
| Q4 | Đối soát gửi khi MISA không có API quan sát (`sync_capabilities.ts:115` luôn ghi `supports_delivery_result_observation: false`; adapter Dart luôn `DeliveryObservationUnsupported`) | Giữ interface hẹp `DeliveryObservationProvider` + bản MISA `createMisaDeliveryObservationProvider()` **không nhận tham số** (không có client ⇒ không thể gọi MISA), luôn trả `{ kind: 'unsupported' }`. Ca Dart `adapter source never references getStatus or sendEmail` (quét mã nguồn) đổi thành `assertEquals(createMisaDeliveryObservationProvider.length, 0)` để `deno test` không cần `--allow-read`; ghi Kết quả |
| Q5 | `RecordDeliveryResultCommand` (Dart chạy qua bus + validator) | Như 7-E2b Q6: hàm thường `recordDeliveryResult(gateway, record)` trong `record_delivery_result.ts`, validator chép vào cùng tệp (ném trước khi gọi gateway): `tenantId is required`, `deliveryId is required`, `retryCount must be between 0 and 2` |
| Q6 | Dòng RPC `record_*` trả về (`delivery_status`, `display_state`, …) | Handler Dart không dùng ⇒ gateway TS **không** phân tích; 0 dòng ⇒ `throw new Error('<rpc> returned no rows')` như Dart. `record_delivery_command_dead_letter` trả `void` ⇒ chỉ kiểm `error`. `prepare_delivery_provider_call` / `load_*` phân tích theo mapper Dart (mục 3) |
| Q7 | Tenant trong payload | `send_invoice_email` (handler + dead-letter): như dead-letter Dart — payload thiếu cả `tenant_id` lẫn `tenantId` ⇒ dùng tenant đang chạy; có mà khác ⇒ `throw new Error('Delivery tenant does not match claimed tenant')`. `reconcile_invoice_delivery`: dùng `ctx.tenantId` (claim theo tenant), không đọc tenant trong payload — ghi lệch Dart vào Kết quả |
| Q8 | Chuỗi lỗi | Như 7-E2b Q5: `String(e)` của TS chỉ vào `internal_commands.error` / log ⇒ không ép giống Dart. **Giữ từng ký tự:** mã an toàn (`DISPATCH_STATE_UNCERTAIN`, `PROVIDER_TRANSPORT_FAILURE`, `WORKER_EXHAUSTED_BEFORE_DISPATCH`, `DELIVERY_RESULT_OBSERVATION_UNSUPPORTED`, `DELIVERY_RECONCILIATION_WORKER_EXHAUSTED`, `INVOICE_SERIES_INVALID`, `PROVIDER_AUTH_FAILED`, `PROVIDER_UNEXPECTED_SUCCESS_SHAPE`, `PROVIDER_EMAIL_NOT_CONFIRMED`, `PROVIDER_EMAIL_FAILED`, `RATE_LIMITED`) — SQL so khớp một số mã để chọn thông điệp (`…014:306-318`, `…014:454-459`, `…015:270-284`); thông điệp `FormatException` của payload (`Invalid or missing delivery identity: <key>`, `Conflicting delivery identity aliases: <key>`) |

## 3. Hiện trạng (đo 2026-11-08)

| Thứ | Ở đâu | Ghi chú |
|---|---|---|
| Xếp `einvoice.send_invoice_email` | `20261031013:265-275` (`_start_invoice_delivery`, lượt 0), `20261031014:341-350` (`record_delivery_result` `RETRYABLE_FAILURE` khi `retry_count < 2`) | payload snake_case `{tenant_id, delivery_id, retry_count}`; id lệnh `_delivery_send_command_id(delivery, retry)` |
| Xếp `einvoice.reconcile_invoice_delivery` | `20261031014:37-115` (`_open_delivery_reconciliation_case`, lần 1, chạy sau 30 giây), `20261031015:380-401` (`record_delivery_reconciliation_check` `UNDETERMINED`, lần 2…4) | payload **camelCase** `{tenantId, reconciliationCaseId, checkSequence}` (Q2); `enqueued_at = next_check_at` ⇒ claim chờ tới hạn |
| 6 RPC (đều chỉ `service_role`) | `load_delivery_attempt_context(p_tenant_id, p_delivery_id, p_retry_count)` `…013:949` (không thấy / lệch lượt ⇒ 0 dòng); `prepare_delivery_provider_call(p_tenant_id, p_delivery_id, p_retry_count, p_request_reference)` `…014:125` (trả `action`, `delivery_version`, `provider_connection_id`, `provider_transaction_id`, `invoice_series`, `recipient_email`, `recipient_name`); `record_delivery_result(p_tenant_id, p_delivery_id, p_retry_count, p_expected_version, p_outcome_kind, p_provider_reference, p_safe_code, p_failure_source)` `…014:219` (`p_failure_source` bắt buộc khi khác `SUCCESS`); `record_delivery_command_dead_letter(p_tenant_id, p_delivery_id, p_retry_count, p_safe_failure_code)` `…014:424`; `load_delivery_reconciliation_context(p_tenant_id, p_reconciliation_case_id, p_check_sequence)` `…015:12` (không `PENDING` / lệch lần ⇒ 0 dòng); `record_delivery_reconciliation_check(p_tenant_id, p_reconciliation_case_id, p_expected_case_version, p_check_sequence, p_observation_kind, p_provider_reference, p_safe_code)` `…015:109` | Dart gửi **mọi** tham số kể cả null (`delivery_rpc_mapper.dart:58-71`, `:99-111`) |
| Cột đọc về | `delivery_rpc_mapper.dart:199-213` (attempt context), `:215-262` (prepare: `CALL_PROVIDER` / `SKIP` / `RECORD_UNKNOWN`, lạ ⇒ ném `Unknown prepare delivery action: <x>`), `:113-128` (reconciliation context; `supports_delivery_result_observation` phải là boolean) | chép đúng tên cột; chuỗi bắt buộc rỗng ⇒ ném `RPC row missing required field: <key>` |
| Giá trị wire | `delivery_rpc_mapper.dart:399-415` | kết quả gửi: `SUCCESS`, `DEFINITE_FAILURE`, `RETRYABLE_FAILURE`, `UNDETERMINED`; quan sát: `SUCCESS`, `DEFINITE_FAILURE`, `UNDETERMINED`, `UNSUPPORTED` ⇒ TS dùng thẳng giá trị wire làm kiểu |
| Giới hạn lượt | `queue/attempt_policy.ts:2-7` | send 3, reconcile 3 — đã có, không sửa |
| `MeInvoiceSendEmailData` (TS) | `misa/models/requests/send_email_request.ts:4-11` | tham số **theo vị trí** `(transactionId, receiverName, receiverEmail, ccEmail, replyEmail)` — khác thứ tự tham số đặt tên của Dart (`transactionId, receiverEmail, receiverName`) |
| `registry.ts` / `index.ts` (7-E2b) | `handlers/registry.ts:19-56`; `index.ts:84-100` | `HandlerDeps = SyncCapabilitiesDeps & { issuance; issuedInvoice }` |
| Ca đăng ký dead-letter | `handlers/issuance/dead_letters_test.ts:97-120`, `handlers/issued_invoice/dead_letters_test.ts:140-160` | so toàn bộ danh sách 4 khoá ⇒ đổi thành 6 khoá |
| KI mới nhất ở TH-08 | `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md:1516` (KI-24) | KI mới = **KI-25** |

Không có bảng "Đang làm gì": plan không xoá / tách code cũ (xoá ở 7-C); test parity chính là các ca chép từ Dart.

## 4. Thiết kế

### G1. Kiểu chung — `handlers/delivery/outcomes.ts`

```ts
import type { FailureSource } from '../issued_invoice/outcomes.ts'
export type DeliveryResultKind = 'SUCCESS' | 'DEFINITE_FAILURE' | 'RETRYABLE_FAILURE' | 'UNDETERMINED'
export type ObservationKind = 'SUCCESS' | 'DEFINITE_FAILURE' | 'UNDETERMINED' | 'UNSUPPORTED'
export interface DeliveryResultEvidence { kind: DeliveryResultKind; providerReference?: string | null
  safeCode?: string | null; failureSource?: FailureSource | null }
export interface DeliveryProviderContext { tenantId: string; providerConnectionId: string; providerTransactionId: string
  invoiceSeries: string; recipientEmail: string; recipientName: string | null }
export type DeliveryProviderOutcome =
  | { kind: 'succeeded'; providerReference: string | null }
  | { kind: 'definiteFailure' | 'retryableFailure' | 'undetermined'; safeErrorCode: string }
export interface DeliveryObservationContext { tenantId: string; reconciliationCaseId: string; deliveryId: string
  providerConnectionId: string; providerDeliveryReference: string | null }
export type DeliveryObservationOutcome =
  | { kind: 'succeeded'; providerReference: string | null }
  | { kind: 'definiteFailure' | 'undetermined'; safeCode: string }
  | { kind: 'unsupported' }
```

### G2. Hàm thuần

- `delivery_payload.ts`
  - `parseDeliveryPayload(payload: Record<string, unknown>, claimedTenantId: string): { tenantId: string; deliveryId: string; retryCount: number }` — chép `DeliveryCommandPayload.fromJson` 1:1 (hai khoá cùng có mà khác giá trị ⇒ `Conflicting delivery identity aliases: <key>`; định danh không phải chuỗi / rỗng sau `trim` / có khoảng trắng đầu cuối ⇒ `Invalid or missing delivery identity: <key>`; `retry_count` phải là số nguyên 0..2 — `'0'`, `1.5`, `-1`, `3`, `null` ⇒ `Invalid or missing delivery identity: retry_count`) cộng Q7 (thiếu tenant ⇒ `claimedTenantId`; khác ⇒ `Delivery tenant does not match claimed tenant`). Ném `Error` (TS không có `FormatException` ở tầng này — ghi Kết quả nếu dùng `misa/internal/format_exception.ts`).
  - `parseReconciliationPayload(payload): { reconciliationCaseId: string | null; checkSequence: number }` — `reconciliation_case_id ?? reconciliationCaseId` (chuỗi, `trim` rỗng ⇒ `null`); `check_sequence ?? checkSequence`: số ⇒ `Math.trunc`, chuỗi số ⇒ `parseInt`, còn lại ⇒ `1` (gộp `fromJson` của handler và `switch` của dead-letter Dart).
- `provider_call_reference.ts` — `providerCallReference` (Q3).
- `delivery_classifier.ts` — `classifyDelivery(result: MeInvoiceResult<MeInvoiceSendEmailResponse>, transactionId: string): DeliveryProviderOutcome`; chép đúng `me_invoice_delivery_classifier.dart:30-138`, giữ thứ tự: (1) `rateLimited` hoặc lỗi chứa `rate_limited` / `429` ⇒ `retryableFailure safeErrorCode(error ?? 'RATE_LIMITED')`; (2) thành công: `data` null ⇒ `undetermined PROVIDER_UNEXPECTED_SUCCESS_SHAPE`; `envelopeAcknowledgement` ⇒ `succeeded`; `transactionId` rỗng / số dòng ≠ 1 / `transactionId` lệch ⇒ `PROVIDER_UNEXPECTED_SUCCESS_SHAPE`; `sendEmailStatus === 3` và `errorCode` rỗng ⇒ `succeeded`; `=== 2` ⇒ `definiteFailure safeErrorCode(errorCode ?? 'PROVIDER_EMAIL_FAILED')`; còn lại ⇒ `undetermined PROVIDER_EMAIL_NOT_CONFIRMED`; (3) lỗi: `isAmbiguousTransport` **riêng của tệp này** (`timeout`, `meinvoice_network`, `connection`, `meinvoice_5xx`, `unavailable`, `meinvoice_invalid_response`, `not a json object`, `malformed` — **không** gồm `429`, khác `isTransportAmbiguous` của 7-E2b) ⇒ `undetermined`; mã thuộc 12 mã xác thực (`:14-27`) hoặc từ sau dấu `:` khớp regex `^[A-Za-z][A-Za-z0-9_]{0,63}` thuộc 12 mã ⇒ `definiteFailure PROVIDER_AUTH_FAILED`; `MeInvoicePublishErrorCodes.isDefiniteFailure(code)` ⇒ `definiteFailure code`; còn lại ⇒ `undetermined code`. Bộ phân loại trả `succeeded` với `providerReference: null`; provider gắn tham chiếu (G3). `safeErrorCode` import từ `../issued_invoice/provider_call_support.ts`.

### G3. Provider — `delivery_provider.ts`, `delivery_observation_provider.ts`

```ts
export interface DeliveryProvider { sendEmail(ctx: DeliveryProviderContext): Promise<DeliveryProviderOutcome> }
export function createDeliveryProvider(deps: { clients: TenantMisaClientFactory
  log?: (event: string, data: Record<string, unknown>) => void }): DeliveryProvider
export interface DeliveryObservationProvider { observe(ctx: DeliveryObservationContext): Promise<DeliveryObservationOutcome> }
export function createMisaDeliveryObservationProvider(): DeliveryObservationProvider
```

`sendEmail` chép `me_invoice_delivery_provider_adapter.dart:39-104`: `tryFromInvSeries` null ⇒ `definiteFailure INVOICE_SERIES_INVALID` (không gọi MISA) → `getForTenant` null ⇒ `definiteFailure PROVIDER_AUTH_FAILED` → `client.sendEmail(new MeInvoiceSendEmailRequest([new MeInvoiceSendEmailData(ctx.providerTransactionId, ctx.recipientName, ctx.recipientEmail)], query.invoiceWithCode, query.invoiceCalcu))` (thứ tự vị trí — mục 3) → `classifyDelivery` → `succeeded` ⇒ `providerReference = ctx.providerTransactionId`. Lỗi `getForTenant` / client ném ⇒ để ném nguyên (handler bắt — G5). Log `log('einvoice_email_provider_result', { tenantId, providerTransactionId, outcomeKind: 'succeeded' | 'definite_failure' | 'retryable_failure' | 'undetermined', safeCode: string | null })` — **không** log email / tên người nhận, thân phản hồi MISA.

### G4. Gateway — `gateways.ts`, `supabase_gateways.ts`

```ts
export interface DeliveryAttemptContext { tenantId: string; deliveryId: string; retryCount: number; deliveryVersion: number
  providerConnectionId: string; providerTransactionId: string; invoiceSeries: string; recipientEmail: string; recipientName: string | null }
export type PrepareResult =
  | { action: 'CALL_PROVIDER'; deliveryVersion: number; providerContext: DeliveryProviderContext }
  | { action: 'SKIP' }
  | { action: 'RECORD_UNKNOWN'; deliveryVersion: number }
export interface DeliveryResultRecord { tenantId: string; deliveryId: string; retryCount: number
  expectedDeliveryVersion: number; evidence: DeliveryResultEvidence }
export interface ReconciliationContext { tenantId: string; reconciliationCaseId: string; deliveryId: string
  providerConnectionId: string; supportsDeliveryResultObservation: boolean; checkSequence: number
  caseVersion: number; providerDeliveryReference: string | null }
export interface ReconciliationCheckRecord { tenantId: string; reconciliationCaseId: string; expectedCaseVersion: number
  checkSequence: number; kind: ObservationKind; providerReference?: string | null; safeCode?: string | null }
export interface DeliveryGateway {
  loadAttemptContext(tenantId: string, deliveryId: string, retryCount: number): Promise<DeliveryAttemptContext | null>
  prepareProviderCall(tenantId: string, deliveryId: string, retryCount: number, requestReference: string): Promise<PrepareResult>
  recordResult(r: DeliveryResultRecord): Promise<void>
  recordCommandDeadLetter(tenantId: string, deliveryId: string, retryCount: number, safeFailureCode: string): Promise<void>
  loadReconciliationContext(tenantId: string, reconciliationCaseId: string, checkSequence: number): Promise<ReconciliationContext | null>
  recordReconciliationCheck(r: ReconciliationCheckRecord): Promise<void>
}
export interface DeliveryDeps { provider: DeliveryProvider; observation: DeliveryObservationProvider; gateway: DeliveryGateway }
```

`supabase_gateways.ts`: `createSupabaseDeliveryGateway(client): DeliveryGateway`; mọi hàm `client.schema('einvoice').rpc(<tên>, <tham số theo mục 3>)`, gửi đủ tham số, trường vắng ⇒ `null`; `error` ⇒ `throw new Error(\`${tên}: ${error.message}\`)`; `prepare` 0 dòng / `record_delivery_result` / `record_delivery_reconciliation_check` 0 dòng ⇒ `throw new Error(\`${tên} returned no rows\`)` (Q6); `load_*` 0 dòng ⇒ `null`; `prepare` gắn `providerContext.tenantId = tenantId` tham số (như `prepareResultFromRowWithTenant`); `delivery_version` / `case_version` (bigint) đọc bằng `Number(...)`. Không test đơn vị (như 7-E2a / 7-E2b); review đối chiếu mục 3.

### G5. Handler + dead-letter

Mỗi handler là `create…Handler(deps: DeliveryDeps): CommandHandler`.

- `record_delivery_result.ts` — `recordDeliveryResult(gateway: DeliveryGateway, record: DeliveryResultRecord): Promise<void>` (Q5).
- `send_invoice_email.ts` — chép `send_invoice_email_command_handler.dart:31-135`: `parseDeliveryPayload(ctx.command.payload, ctx.tenantId)` → `loadAttemptContext` null ⇒ return → `prepareProviderCall(…, await providerCallReference(ctx.command.commandId, ctx.attemptNumber))` → `SKIP` ⇒ return; `RECORD_UNKNOWN` ⇒ ghi `{ kind: 'UNDETERMINED', safeCode: 'DISPATCH_STATE_UNCERTAIN', failureSource: 'INTERNAL' }`; `CALL_PROVIDER` ⇒ `try { evidence = evidenceFor(await deps.provider.sendEmail(providerContext)) } catch { evidence = { kind: 'UNDETERMINED', safeCode: 'PROVIDER_TRANSPORT_FAILURE', failureSource: 'INTERNAL' } }` rồi ghi. `evidenceFor`: `succeeded` ⇒ `SUCCESS` + `providerReference` (không `failureSource`); 3 nhánh lỗi ⇒ kind tương ứng + `safeCode = safeErrorCode` + `PROVIDER`. Ghi qua `recordDeliveryResult` với `expectedDeliveryVersion` của `prepare`; lỗi ghi ⇒ để ném.
- `reconcile_invoice_delivery.ts` — chép `reconcile_invoice_delivery_command_handler.dart:24-105`: `parseReconciliationPayload`; `reconciliationCaseId` null ⇒ `throw new Error('reconcile_invoice_delivery payload missing reconciliation_case_id')`; `loadReconciliationContext(ctx.tenantId, …)` null ⇒ return; `!supportsDeliveryResultObservation` ⇒ ghi `UNSUPPORTED / DELIVERY_RESULT_OBSERVATION_UNSUPPORTED`, không gọi `observe`; có ⇒ `observe` một lần, ghi `succeeded` ⇒ `SUCCESS` + `providerReference`; `definiteFailure` ⇒ `DEFINITE_FAILURE` + `safeCode`; `undetermined` ⇒ `UNDETERMINED` + `safeCode`; `unsupported` ⇒ `UNSUPPORTED / DELIVERY_RESULT_OBSERVATION_UNSUPPORTED`. `expectedCaseVersion = context.caseVersion`, `checkSequence` của payload.
- `dead_letters.ts` — `createDeliveryDeadLetters(gateway: DeliveryGateway): Record<string, DeadLetterHandler>` trả 2 khoá:
  - `'einvoice.send_invoice_email'`: `parseDeliveryPayload(command.payload, tenantId)` (lỗi ⇒ ném — `processor.ts:42-49` log `dead_letter_error`) → `recordCommandDeadLetter(tenantId, deliveryId, retryCount, 'WORKER_EXHAUSTED_BEFORE_DISPATCH')`.
  - `'einvoice.reconcile_invoice_delivery'`: `parseReconciliationPayload` (Q2 — đọc cả camelCase); case id null ⇒ bỏ qua; `loadReconciliationContext` null ⇒ bỏ qua; còn lại ghi `UNSUPPORTED / DELIVERY_RECONCILIATION_WORKER_EXHAUSTED`, `expectedCaseVersion = context.caseVersion`. Không gọi `observe` / `sendEmail`.

### G6. Nối vào

- `handlers/registry.ts`: `HandlerDeps` thêm `delivery: DeliveryDeps`; `buildHandlers` thêm `'einvoice.send_invoice_email'`, `'einvoice.reconcile_invoice_delivery'`; `buildDeadLetters` thêm `...createDeliveryDeadLetters(deps.delivery.gateway)`.
- `index.ts`: `delivery: { provider: createDeliveryProvider({ clients: clientFactory, log }), observation: createMisaDeliveryObservationProvider(), gateway: createSupabaseDeliveryGateway(client) }` vào `deps`.
- `handlers/issuance/dead_letters_test.ts:97-120`, `handlers/issued_invoice/dead_letters_test.ts:140-160`: thêm `delivery: { gateway: new FakeDeliveryGateway(), provider: {} as never, observation: {} as never }` vào `deps`; danh sách khoá mong đợi thành 6: `['einvoice.download_invoice_document', 'einvoice.fetch_official_view', 'einvoice.preview_invoice', 'einvoice.publish_invoice', 'einvoice.reconcile_invoice_delivery', 'einvoice.send_invoice_email']`. Tên ca giữ nguyên.

## 5. Các bước

**Ràng buộc chung** (mọi task):
- Lệnh test: `deno test supabase/functions/einvoice-processor` (từ gốc repo), không cần quyền mạng / đọc tệp. Lệnh kiểm: `deno check supabase/functions/einvoice-processor/index.ts`, `deno lint supabase/functions/einvoice-processor`.
- Test chép từ Dart: **giữ tên ca** (`Deno.test('<group> <ca>', …)`; ca Dart sinh trong vòng `for` ⇒ một `Deno.test` mỗi giá trị, tên thay `$x` bằng giá trị như Dart in ra, vd. `status null …`, `invalid retry count 1.5 rejects`), giữ dữ liệu đầu vào và giá trị so sánh; ca phải đổi (kiểu, cách bắt lỗi, Q4, Q7) ghi Kết quả. Client giả: `FakeMeInvoiceClient` + `TenantMisaClientFactory(env, credentialsReaderGiả, () => fakeClient)` như `issued_invoice_provider_test.ts`.
- Mỗi task: viết test trước, chạy thấy đỏ, viết mã, chạy thấy xanh.
- Test ở `supabase/functions/einvoice-processor/handlers/delivery/*_test.ts`.

| Dart (`modules/einvoice/`) | TS test | Ca | Task |
|---|---|---|---|
| `application/test/delivery/send_invoice_email_payload_test.dart` (2 + vòng 4 định danh + vòng 5 lượt) | `delivery_payload_test.ts` | 11 | 1 |
| group `SendInvoiceEmailCommand` của `send_invoice_email_command_handler_test.dart:83-112` ⇒ kiểm `parseDeliveryPayload` trả đúng 3 trường, không có trường khác | `delivery_payload_test.ts` | 2 | 1 |
| group `ReconcileInvoiceDeliveryCommand` của `reconcile_invoice_delivery_command_handler_test.dart:72-99` ⇒ kiểm `parseReconciliationPayload` (payload snake_case, `check_sequence: 3`) | `delivery_payload_test.ts` | 2 | 1 |
| `application/test/electronic_invoice/s4_worker_handlers_test.dart:104-115` | `provider_call_reference_test.ts` | 1 | 1 |
| `infrastructure/test/adapters/misa/me_invoice_delivery_classifier_test.dart` (14 + vòng 7 trạng thái + vòng 4 danh sách) | `delivery_classifier_test.ts` | 25 | 1 |
| `infrastructure/test/adapters/misa/me_invoice_delivery_provider_adapter_test.dart` | `delivery_provider_test.ts` | 7 | 2 |
| `infrastructure/test/adapters/misa/me_invoice_delivery_observation_provider_adapter_test.dart` (ca 2 đổi theo Q4) | `delivery_observation_provider_test.ts` | 2 | 2 |
| groups `prepare branches` + `provider outcomes` của `send_invoice_email_command_handler_test.dart:114-324` | `send_invoice_email_test.ts` | 8 | 3 |
| group `ReconcileInvoiceDeliveryCommandHandler` của `reconcile_invoice_delivery_command_handler_test.dart:101-212` | `reconcile_invoice_delivery_test.ts` | 5 | 3 |
| `application/test/delivery/record_delivery_result_command_handler_test.dart` | `record_delivery_result_test.ts` | 3 | 3 |
| `infrastructure/test/configuration/einvoice_s5_dead_letter_test.dart` (ca 1 ⇒ `maxAttemptsFor('einvoice.send_invoice_email') === 3`; ca 4 qua `runInvocation`) | `dead_letters_test.ts` | 4 | 4 |
| 2 ca dead-letter của `einvoice_s5_reconciliation_registration_test.dart:43-110` | `dead_letters_test.ts` | 2 | 4 |
| | **Tổng chép** | **72** | |

### Task 1: Kiểu chung + hàm thuần (G1, G2)

**Files:** Create: `handlers/delivery/outcomes.ts`, `delivery_payload.ts`, `provider_call_reference.ts`, `delivery_classifier.ts`; Test: `delivery_payload_test.ts` (15 + 1), `provider_call_reference_test.ts` (1 + 1), `delivery_classifier_test.ts` (25)

**Interfaces — Consumes:** `misa/mod.ts` (`MeInvoiceResult`, `MeInvoiceSendEmailResponse`, `MeInvoiceSendEmailResponseKind`, `MeInvoiceSendEmailResultItem`, `MeInvoicePublishErrorCodes`); `safeErrorCode` (7-E2b). **Produces:** mọi kiểu G1; `parseDeliveryPayload`, `parseReconciliationPayload`, `providerCallReference`, `classifyDelivery`.

- [x] **1.1** Chép test (bảng trên). Thêm 2 ca:
  - `reconciliation payload reads camelCase keys written by SQL` — `parseReconciliationPayload({ tenantId: 't', reconciliationCaseId: 'case-1', checkSequence: 2 })` ⇒ `{ reconciliationCaseId: 'case-1', checkSequence: 2 }` (Q2).
  - `provider call reference matches Dart vector` — `await providerCallReference('cmd-1', 1)` ⇒ `'7d99ddea-18d5-bea4-c874-7b0de44f56a5'` (Q3).
  Chạy, thấy đỏ.
- [x] **1.2** Viết 4 tệp theo G1, G2; chạy, thấy 43 ca xanh.
- [x] **1.3** Ghi Kết quả: số dòng TS / Dart từng tệp; tên ca vòng `for` đã đặt.

### Task 2: Provider gửi + provider quan sát (G3)

**Files:** Create: `handlers/delivery/delivery_provider.ts`, `delivery_observation_provider.ts`; Test: `delivery_provider_test.ts` (7), `delivery_observation_provider_test.ts` (2)

**Interfaces — Consumes:** Task 1; `TenantMisaClientFactory`, `CredentialsReader`, `MisaEnv` (7-E1). **Produces:** `DeliveryProvider`, `createDeliveryProvider`, `DeliveryObservationProvider`, `createMisaDeliveryObservationProvider`.

- [x] **2.1** Chép 9 ca. Ca `selects tenant client and maps transaction, receiver, and series flags` ⇒ kiểm `fake.lastSendEmailRequest.sendEmailDatas[0]` có `transactionId`, `receiverEmail`, `receiverName` đúng giá trị Dart (bắt lỗi đảo thứ tự vị trí — mục 3) và `isInvoiceCode` / `isInvoiceCalculatingMachine`. Ca `missing credentials …` ⇒ `CredentialsReader` giả trả `null`, `sendEmailCount === 0`. Ca `never calls getStatus` ⇒ `getStatusCount === 0`. Chạy, thấy đỏ.
- [x] **2.2** Viết 2 tệp theo G3; chạy, thấy xanh.
- [x] **2.3** Ghi Kết quả: ca đổi theo Q4.

### Task 3: Gateway + 2 handler + ghi kết quả (G4, G5)

**Files:** Create: `handlers/delivery/gateways.ts`, `supabase_gateways.ts`, `fake_gateways.ts` (`FakeDeliveryGateway`: context / `prepareResult` dựng sẵn, `throwOnRecord`, ghi mọi lời gọi theo thứ tự vào mảng `calls` và các mảng riêng `prepareCalls`, `results`, `deadLetters`, `checks`; `FakeDeliveryProvider`: `outcome` dựng sẵn hoặc `throwOnSend`, đếm `sendCalls`; `FakeDeliveryObservationProvider`: `outcome`, đếm `observeCalls`), `record_delivery_result.ts`, `send_invoice_email.ts`, `reconcile_invoice_delivery.ts`; Test: `send_invoice_email_test.ts` (8 + 3), `reconcile_invoice_delivery_test.ts` (5), `record_delivery_result_test.ts` (3)

**Interfaces — Consumes:** Task 1–2; `CommandHandler`, `CommandContext` (7-E1). **Produces:** mọi kiểu G4; `createSupabaseDeliveryGateway`; `recordDeliveryResult`, `createSendInvoiceEmailHandler`, `createReconcileInvoiceDeliveryHandler`; `FakeDeliveryGateway`, `FakeDeliveryProvider`, `FakeDeliveryObservationProvider`.

- [x] **3.1** `node .gitnexus/run.cjs analyze` (hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu bị sửa), rồi `impact({target: "buildHandlers", direction: "upstream"})`, `impact({target: "buildDeadLetters", direction: "upstream"})`. Kỳ vọng: ← `index.ts` + 2 tệp `dead_letters_test.ts`. Ghi Kết quả (không chạy được ⇒ ghi lý do, dùng `grep -rn`). HIGH / CRITICAL ⇒ dừng, báo người dùng.
- [x] **3.2** Chép test. Dữ liệu theo `send_invoice_email_command_handler_test.dart:30-80` (`tenant-1`, `del-1`, `retry_count: 0`, `deliveryVersion: 1`, `tx-inv-1`, `1C25TYY`, `buyer@test.com`, `Buyer`); payload lệnh `{ tenant_id: 'tenant-1', delivery_id: 'del-1', retry_count: 0 }`, `commandId: 'cmd-1'`, `attemptNumber: 1`. Ca `record failure rethrows and the next run records UNKNOWN` ⇒ lần 1 `assertRejects`, lần 2 đổi `prepareResult` thành `RECORD_UNKNOWN` (`deliveryVersion: 2`), `throwOnRecord = false` ⇒ `results.length === 2`, kết quả cuối `UNDETERMINED` + `expectedDeliveryVersion === 2`, `sendCalls === 1`. Ca mới:
  - `send handler passes provider call reference to prepare` — `prepareCalls[0].requestReference === '7d99ddea-18d5-bea4-c874-7b0de44f56a5'`.
  - `send handler returns quietly when attempt context is missing` — context `null` ⇒ không gọi `prepare`, không gọi provider.
  - `send handler rejects invalid payload before loading context` — payload `retry_count: 3` ⇒ `assertRejects(…, 'Invalid or missing delivery identity: retry_count')`, `calls.length === 0`.
  Chạy, thấy đỏ.
- [x] **3.3** Viết `gateways.ts`, `fake_gateways.ts`, 3 tệp handler / hàm; chạy, thấy xanh.
- [x] **3.4** Viết `supabase_gateways.ts` (G4). Ghi Kết quả bảng: hàm TS → tên RPC → tham số `p_*` → cột đọc về → nguồn mapper Dart (tệp:dòng).

### Task 4: Dead-letter + đăng ký + `index.ts` (G5, G6)

**Files:** Create: `handlers/delivery/dead_letters.ts`; Modify: `handlers/registry.ts`, `index.ts`, `handlers/issuance/dead_letters_test.ts:97-120`, `handlers/issued_invoice/dead_letters_test.ts:140-160`; Test: `handlers/delivery/dead_letters_test.ts` (6 + 2), `handlers/delivery/processor_integration_test.ts` (1)

**Interfaces — Consumes:** Task 1–3; `runInvocation`, `FakeQueueRpc`, `cmd()`. **Produces:** `createDeliveryDeadLetters`, `HandlerDeps.delivery`.

- [x] **4.1** Chép 6 ca vào `dead_letters_test.ts`. Ca `max-three exhaustion invokes delivery dead-letter once …` ⇒ `runInvocation` + `FakeQueueRpc` (`batches = [[{ ...cmd('einvoice.send_invoice_email', 2), payload: { tenant_id: 'tenant-1', delivery_id: 'del-1', retry_count: 0 } }]]`), handler thật dựng từ bản giả, `loadAttemptContext` ném ⇒ `rpc.count('fail') === 1`, `rpc.count('retryOrDeadLetter') === 0`, `deadLetters.length === 1` với `WORKER_EXHAUSTED_BEFORE_DISPATCH`. Ca mới:
  - `reconcile dead letter reads camelCase payload written by SQL` — payload `{ tenantId: 'tenant-1', reconciliationCaseId: 'case-1', checkSequence: 2 }`, context `PENDING` (`caseVersion: 4`) ⇒ `loadReconciliationContext('tenant-1', 'case-1', 2)`, `checks` có 1 dòng `UNSUPPORTED / DELIVERY_RECONCILIATION_WORKER_EXHAUSTED`, `expectedCaseVersion: 4` (KI-25).
  - `delivery dead letter rejects tenant mismatch` — payload `tenant_id: 'tenant-2'`, tenant đang chạy `tenant-1` ⇒ `assertRejects(…, 'Delivery tenant does not match claimed tenant')`, `deadLetters.length === 0`.
- [x] **4.2** `processor_integration_test.ts` — 1 ca mới `reconcile exhaustion on third attempt fails and records UNSUPPORTED for camelCase payload`: `retryCount: 2`, payload camelCase như 4.1, `loadReconciliationContext` lần đầu (handler) ném `Error('load failed')`, lần sau (dead-letter) trả context ⇒ `rpc.count('fail') === 1`, `checks` 1 dòng `DELIVERY_RECONCILIATION_WORKER_EXHAUSTED`. (`FakeDeliveryGateway` cần hàng đợi kết quả cho `loadReconciliationContext` hoặc cờ `throwOnLoadReconciliationOnce` — chọn một, ghi Kết quả.)
- [x] **4.3** Chạy, thấy đỏ; viết `dead_letters.ts`, sửa `registry.ts`, `index.ts`, 2 ca đăng ký theo G6; chạy, thấy xanh.
- [x] **4.4** `deno check supabase/functions/einvoice-processor/index.ts`, `deno lint supabase/functions/einvoice-processor`, `deno test supabase/functions/einvoice-processor` — ghi số ca đạt / lỗi (tách: trước 7-E2c 301, 7-E2c 80; tổng kỳ vọng 381).
- [x] **4.5** `grep -rn -E "recipient|Email|email|password|access_token|accessToken|username" supabase/functions/einvoice-processor/handlers/delivery --include="*.ts" | grep -v "_test.ts" | grep -i -E "log\(|console"` ⇒ không dòng nào log email / tên người nhận / bí mật; ghi Kết quả.

### Task 5: Tài liệu + `detect_changes` + Kết quả

**Files:** Modify: `docs/refactor/PLAN.md` (dòng 7-E2c), `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md` (sau `:1516`)

- [x] **5.1** PLAN.md: dòng **7-E2c** cột nội dung chèn "chép 72 test Dart; " trước "dead-letter đối soát gửi…", cột Làm ✅ + ngày + "(chưa commit)". Cột Review để nguyên.
- [x] **5.2** TH-08: thêm **KI-25** sau KI-24 — "Việc `reconcile_invoice_delivery` do SQL xếp với payload camelCase (`…014`, `…015`) nhưng dead-letter Dart chỉ đọc `reconciliation_case_id` ⇒ hết 3 lượt thì hồ sơ đối soát gửi kẹt `PENDING`, không `UNRESOLVED`, không cảnh báo | Dead-letter Edge Function đọc cả hai kiểu khoá | Đã sửa 7-E2c".
- [x] **5.3** `node .gitnexus/run.cjs analyze` (lại) rồi `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory --scope all`: chỉ tệp trong plan; ghi số tệp / symbol / luồng / rủi ro, và số tệp mới chưa `git add` (người dùng chạy lại sau `git add`, như 7-E2b). Hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu `analyze` sửa.

## 6. Review Focus (chưa ca nào chạy — phiên review soi)

1. **Gửi thư hai lần:** mọi lỗi sau khi `prepare` trả `CALL_PROVIDER` (kể cả `getForTenant` ném, client ném, bộ phân loại ném) phải thành `UNDETERMINED`, **không** để ném lên hàng đợi (ném ⇒ thử lại ⇒ `RECORD_UNKNOWN`, vẫn an toàn — nhưng sai mã `PROVIDER_TRANSPORT_FAILURE`). Review đặt `send_invoice_email.ts` cạnh Dart `:67-85`.
2. **Bộ phân loại lệch Dart:** thứ tự `rateLimited` → thành công → transport → xác thực → `isDefiniteFailure`; dùng nhầm `isTransportAmbiguous` của 7-E2b (có `429`) hoặc so chuỗi con `auth` ⇒ lỗi tạm thời thành `FAILED` vĩnh viễn (không thử lại) hoặc ngược lại. Review đặt `delivery_classifier.ts` cạnh `me_invoice_delivery_classifier.dart`.
3. **Thứ tự tham số `MeInvoiceSendEmailData`:** đảo `receiverName` / `receiverEmail` ⇒ MISA gửi tới "Buyer" — ca Task 2.1 phải so cả hai trường.
4. **`p_request_reference` ổn định:** cùng lệnh + cùng lượt phải ra cùng chuỗi (SQL lưu `provider_request_reference` để truy vết); dùng `crypto.randomUUID()` là sai.
5. **Lộ dữ liệu:** log `einvoice_email_provider_result` không chứa email / tên người nhận; `String(e)` vào `internal_commands.error` có thể chứa thân lỗi MISA — như 7-E2b, ghi nhận.
6. **bigint:** `delivery_version` / `case_version` về dạng số hoặc chuỗi tuỳ PostgREST; `Number(...)` rồi gửi lại `p_expected_version` phải khớp, lệch ⇒ `STATE_CHANGED` ⇒ thử lại mãi.

## 7. Kiểm tra

### 7.1 Tự động
Task 4.4 (`deno check`, `deno lint`, `deno test`), Task 5.3 (`detect-changes`). Không có test Dart, không có ca SQL (plan không đổi app / DB).

### 7.2 Việc của người dùng
- (Tuỳ chọn, sau 7-E3) gửi / gửi lại hoá đơn trên MISA sandbox theo checklist 7-E3.

## 8. Rủi ro / lưu ý

- **Gửi tự động chưa có việc:** `start_auto_delivery` chưa ai gọi (KI-19 / KI-20 — 7-E3) ⇒ chỉ lần gửi thủ công từ app (`send_electronic_invoice`) sinh việc `send_invoice_email`.
- **Hồ sơ kẹt cũ:** hồ sơ đã kẹt `PENDING` vì lỗi KI-25 trước đây không được sửa (việc đã `failed_at`); Dev được reset nên không có.
- **Outbox chưa ai đọc:** `einvoice.delivery.result_recorded` / `attention_required` (TH-08 "Cảnh báo Theme 11"). Không chặn 7-E2c.
- **Plan dựa trên code 7-E1 / 7-E2a / 7-E2b tại `151a2edc6`:** nếu tên / chữ ký lệch, phiên code theo code thật và ghi lệch vào Kết quả.

## 9. Kết quả (phiên làm code ghi)

Mẫu cho mỗi task:

**Task 1 — ✅**
- Tệp:
  - `handlers/delivery/outcomes.ts:1-37` (tạo mới, 37 dòng)
  - `handlers/delivery/delivery_payload.ts:1-92` (tạo mới, 92 dòng vs Dart `delivery_command_payload.dart`: 36 dòng)
  - `handlers/delivery/provider_call_reference.ts:1-11` (tạo mới, 11 dòng vs Dart `provider_call_correlation_id.dart`: 19 dòng)
  - `handlers/delivery/delivery_classifier.ts:1-132` (tạo mới, 132 dòng vs Dart `me_invoice_delivery_classifier.dart`: 139 dòng)
  - `handlers/delivery/delivery_payload_test.ts:1-133` (tạo mới, 133 dòng, 16 ca)
  - `handlers/delivery/provider_call_reference_test.ts:1-17` (tạo mới, 17 dòng, 2 ca)
  - `handlers/delivery/delivery_classifier_test.ts:1-231` (tạo mới, 231 dòng, 25 ca)
- Lệch plan + lý do: Không có. Ném `Error` với đúng message định dạng Dart. `MeInvoiceSendEmailResponse` dùng static factory `envelopeAcknowledgement()` và `itemized()` theo thiết kế của `misa/models/responses/send_email_result.ts`.
- Ca test: `deno test supabase/functions/einvoice-processor/handlers/delivery` đạt 43/43 ca (toàn bộ 344/344 ca của `einvoice-processor` xanh). Tên ca vòng for:
  - `invalid identity ${bad} rejects with safe field error` (null, '', ' ', 12)
  - `invalid retry count ${bad} rejects` (null, '0', -1, 3, 1.5)
  - `status ${status} is classified without assuming acceptance is sent` (0, 1, 2, 3, 4, 99, null)
  - `ambiguous per-invoice results are undetermined ${set.name}` (empty, wrong transaction, status 3 with error, multiple items)
- Impact / detect_changes (task có): Không đụng code hiện tại, chỉ thêm tệp mới trong `handlers/delivery/`.

**Task 2 — ✅**
- Tệp:
  - `handlers/delivery/delivery_provider.ts:1-74` (tạo mới, 74 dòng vs Dart `me_invoice_delivery_provider_adapter.dart`: 131 dòng)
  - `handlers/delivery/delivery_observation_provider.ts:1-16` (tạo mới, 16 dòng vs Dart `me_invoice_delivery_observation_provider_adapter.dart`: 18 dòng)
  - `handlers/delivery/delivery_provider_test.ts:1-170` (tạo mới, 170 dòng, 7 ca)
  - `handlers/delivery/delivery_observation_provider_test.ts:1-30` (tạo mới, 30 dòng, 2 ca)
- Lệch plan + lý do: Không có. Ca `adapter source never references getStatus or sendEmail` kiểm `assertEquals(createMisaDeliveryObservationProvider.length, 0)` theo Q4 thay vì quét chuỗi mã nguồn bằng file I/O để giữ test hermetic.
- Ca test: `deno test supabase/functions/einvoice-processor/handlers/delivery` đạt 52/52 ca (9 ca Task 2 xanh; toàn bộ 353/353 ca của `einvoice-processor` xanh).
- Impact / detect_changes (task có): Không đụng code hiện tại, chỉ thêm tệp mới trong `handlers/delivery/`.

**Task 3 — ✅**
- Tệp:
  - `handlers/delivery/gateways.ts:1-86` (tạo mới, 86 dòng)
  - `handlers/delivery/fake_gateways.ts:1-144` (tạo mới, 144 dòng)
  - `handlers/delivery/record_delivery_result.ts:1-29` (tạo mới, 29 dòng)
  - `handlers/delivery/send_invoice_email.ts:1-94` (tạo mới, 94 dòng vs Dart `send_invoice_email_command_handler.dart`: 129 dòng)
  - `handlers/delivery/reconcile_invoice_delivery.ts:1-85` (tạo mới, 85 dòng vs Dart `reconcile_invoice_delivery_command_handler.dart`: 93 dòng)
  - `handlers/delivery/supabase_gateways.ts:1-254` (tạo mới, 254 dòng vs Dart `supabase_delivery_*_gateway.dart`: 224 dòng)
  - `handlers/delivery/send_invoice_email_test.ts:1-325` (tạo mới, 325 dòng, 11 ca)
  - `handlers/delivery/reconcile_invoice_delivery_test.ts:1-164` (tạo mới, 164 dòng, 5 ca)
  - `handlers/delivery/record_delivery_result_test.ts:1-68` (tạo mới, 68 dòng, 3 ca)
- Lệch plan + lý do: Không có.
- Bảng đối chiếu RPC Supabase Gateway (Task 3.4):

| Hàm TS | Tên RPC | Tham số `p_*` | Cột đọc về | Nguồn mapper Dart |
|---|---|---|---|---|
| `loadAttemptContext` | `load_delivery_attempt_context` | `p_tenant_id`, `p_delivery_id`, `p_retry_count` | `tenant_id`, `delivery_id`, `retry_count`, `delivery_version`, `provider_connection_id`, `provider_transaction_id`, `invoice_series`, `recipient_email`, `recipient_name` | `delivery_rpc_mapper.dart:32-42, 199-213` |
| `prepareProviderCall` | `prepare_delivery_provider_call` | `p_tenant_id`, `p_delivery_id`, `p_retry_count`, `p_request_reference` | `action`, `delivery_version`, `provider_connection_id`, `provider_transaction_id`, `invoice_series`, `recipient_email`, `recipient_name` | `delivery_rpc_mapper.dart:44-56, 215-262` |
| `recordResult` | `record_delivery_result` | `p_tenant_id`, `p_delivery_id`, `p_retry_count`, `p_expected_version`, `p_outcome_kind`, `p_provider_reference`, `p_safe_code`, `p_failure_source` | rows > 0 | `delivery_rpc_mapper.dart:58-71, 399-408` |
| `recordCommandDeadLetter` | `record_delivery_command_dead_letter` | `p_tenant_id`, `p_delivery_id`, `p_retry_count`, `p_safe_failure_code` | void | `delivery_rpc_mapper.dart:73-85` |
| `loadReconciliationContext` | `load_delivery_reconciliation_context` | `p_tenant_id`, `p_reconciliation_case_id`, `p_check_sequence` | `tenant_id`, `reconciliation_case_id`, `delivery_id`, `provider_connection_id`, `supports_delivery_result_observation`, `check_sequence`, `case_version`, `provider_delivery_reference` | `delivery_rpc_mapper.dart:87-97, 113-128` |
| `recordReconciliationCheck` | `record_delivery_reconciliation_check` | `p_tenant_id`, `p_reconciliation_case_id`, `p_expected_case_version`, `p_check_sequence`, `p_observation_kind`, `p_provider_reference`, `p_safe_code` | rows > 0 | `delivery_rpc_mapper.dart:99-111, 410-415` |

- Ca test: `deno test supabase/functions/einvoice-processor/handlers/delivery` đạt 71/71 ca (19 ca Task 3 xanh; toàn bộ 372/372 ca của `einvoice-processor` xanh).
- Impact / detect_changes:
  - `buildHandlers` upstream: direct 1 (`index.ts`), risk LOW.
  - `buildDeadLetters` upstream: direct 3 (`index.ts`, `issuance/dead_letters_test.ts`, `issued_invoice/dead_letters_test.ts`), risk LOW. Cả hai rủi ro đều LOW, đúng dự kiến.

**Task 4 — ✅**
- Tệp:
  - `handlers/delivery/dead_letters.ts:1-46` (tạo mới, 46 dòng vs Dart `delivery_*dead_letter_handler.dart`: 106 dòng)
  - `handlers/delivery/dead_letters_test.ts:1-275` (tạo mới, 275 dòng, 8 ca)
  - `handlers/delivery/processor_integration_test.ts:1-68` (tạo mới, 68 dòng, 1 ca)
  - `handlers/registry.ts:1-66` (sửa, 66 dòng)
  - `index.ts:1-121` (sửa, 121 dòng)
  - `handlers/issuance/dead_letters_test.ts:1-127` (sửa, 127 dòng)
  - `handlers/issued_invoice/dead_letters_test.ts:1-172` (sửa, 172 dòng)
- Lệch plan + lý do: Không có. `FakeDeliveryGateway` dùng cờ `throwOnLoadReconciliationOnce = true` cho ca integration test của `runInvocation`.
- Ca test:
  - `deno check supabase/functions/einvoice-processor/index.ts`: 0 lỗi.
  - `deno lint supabase/functions/einvoice-processor`: 141 files checked, 0 problems.
  - `deno test supabase/functions/einvoice-processor`: đạt 381/381 ca xanh (301 ca trước 7-E2c + 80 ca mới của 7-E2c).
- Kiểm tra bí mật/PII (Task 4.5): `grep -rn -E "recipient|Email|email|password|access_token|accessToken|username" supabase/functions/einvoice-processor/handlers/delivery --include="*.ts" | grep -v "_test.ts" | grep -i -E "log\(|console"` trả về rỗng (exit code 1), không log bất kỳ bí mật hay thông tin người nhận nào.

**Task 5 — ✅**
- Tệp:
  - `docs/refactor/PLAN.md:539` (sửa dòng 7-E2c: thêm "chép 72 test Dart; ", cột Làm ✅ 2026-11-08 (chưa commit))
  - `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md:1517` (sửa: thêm KI-25 sau KI-24)
- Lệch plan + lý do: Không có.
- Ca test: Toàn bộ 381/381 ca xanh, `deno check` và `deno lint` sạch.
- Impact / detect_changes:
  - GitNexus analyze hoàn tất sạch sẽ (48,194 nodes, 105,875 edges, 300 flows). Đã hoàn nguyên `AGENTS.md` và `CLAUDE.md`.
  - `detect-changes --repo erp-sales-inventory --scope all`: 6 tracked files changed (`TH-08-hoa-don-dien-tu.md`, `PLAN.md`, `issuance/dead_letters_test.ts`, `issued_invoice/dead_letters_test.ts`, `registry.ts`, `index.ts`), 7 symbols, 0 affected execution flows, risk level LOW. 24 tệp mới chưa `git add` (`handlers/delivery/*` gồm 23 tệp và tệp plan 7-E2c).

**R1 — sửa**
- **R1-1 — Tên ca test có tiền tố group:**
  - Bổ sung tiền tố group cho toàn bộ các ca chép từ Dart theo đúng yêu cầu:
    - `delivery_classifier_test.ts` (25 ca): tiền tố `MeInvoiceDeliveryClassifier `
    - `delivery_provider_test.ts` (7 ca): tiền tố `MeInvoiceDeliveryProviderAdapter `
    - `delivery_observation_provider_test.ts` (2 ca): tiền tố `MeInvoiceDeliveryObservationProviderAdapter `
    - `send_invoice_email_test.ts` (8 ca): 3 ca đầu có tiền tố `SendInvoiceEmailCommandHandler prepare branches `, 5 ca sau có tiền tố `SendInvoiceEmailCommandHandler provider outcomes `
    - `reconcile_invoice_delivery_test.ts` (5 ca): tiền tố `ReconcileInvoiceDeliveryCommandHandler `
    - `record_delivery_result_test.ts` (3 ca): 2 ca đầu có tiền tố `RecordDeliveryResultCommandValidator `, 1 ca sau có tiền tố `RecordDeliveryResultCommandHandler `
    - `dead_letters_test.ts` (6 ca): 4 ca của delivery dead-letter có tiền tố `Einvoice S5 delivery dead-letter `, 2 ca đối soát có tiền tố `Einvoice S5 reconciliation registration `
    - `provider_call_reference_test.ts` (1 ca): đổi thành `S4 worker command serialization provider-call correlation differs per worker attempt`
  - Các ca mới viết thêm giữ nguyên tên.
- **R1-2 — Gateway kiểm tra kiểu chặt chẽ:**
  - Thêm `requiredBool(row, key)` và `requiredInt(row, key)` vào `supabase_gateways.ts`.
  - Áp dụng kiểm tra chặt chẽ cho 5 cột: `supports_delivery_result_observation`, `delivery_version`, `case_version`, `retry_count`, `check_sequence`. Nếu thiếu hoặc sai kiểu (kể cả string `'false'`/`null`), ném `Error` rõ ràng thay vì nuốt lỗi hoặc ép kiểu ngầm làm sai `p_expected_version`. Nhận `number` nguyên hoặc chuỗi số nguyên (hỗ trợ bigint của PostgREST). Tệp `supabase_gateways.ts` đạt 254 dòng.
- **R1-3 — Số liệu Kết quả & định dạng tệp:**
  - Bỏ dòng trống thừa cuối (`\n\n`) ở các tệp trong `handlers/delivery/*.ts`.
  - Đo lại bằng `wc -l` tất cả 23 tệp trong `handlers/delivery/*.ts` (tổng 2,581 dòng). Cập nhật số dòng chính xác trong mục 9.
  - Sửa số tệp mới: 23 tệp `handlers/delivery/*` + 1 tệp plan = 24 tệp mới chưa `git add`.
- **Kiểm tra sau R1:**
  - `deno check supabase/functions/einvoice-processor/index.ts`: 0 lỗi.
  - `deno lint supabase/functions/einvoice-processor`: 141 files checked, 0 problems.
  - `deno test supabase/functions/einvoice-processor`: đạt 381/381 ca xanh.

## 10. Review (phiên review ghi)

### R1 — 2026-11-08 — **CHƯA ĐẠT** (3 việc sửa nhỏ; luồng nghiệp vụ đúng)

| Hạng mục | Kết quả | Ghi chú |
|---|---|---|
| `deno check index.ts` / `deno lint` | ✅ | chạy lại: 141 tệp, 0 lỗi |
| `deno test supabase/functions/einvoice-processor` | ✅ 381/381 | chạy lại; `handlers/delivery` 64 ca + 2 tệp đăng ký sửa — khớp 301 + 80 |
| Luồng gửi email (G5) | ✅ | đối chiếu `send_invoice_email_command_handler.dart:31-135`: `try` chỉ bọc `sendEmail` + đổi kết quả; lỗi ghi ⇒ ném; `RECORD_UNKNOWN` không gọi MISA |
| `providerCallReference` (Q3) | ✅ | ca vector `7d99ddea-18d5-bea4-c874-7b0de44f56a5` |
| Bộ phân loại (G2) | ✅ | thứ tự `rateLimited` → thành công → transport riêng (không `429`) → 12 mã xác thực + từ sau `:` → `isDefiniteFailure`; `safeErrorCode` dùng chung khớp Dart `me_invoice_provider_call_support.dart:34-42` |
| Thứ tự `MeInvoiceSendEmailData` | ✅ | `delivery_provider.ts:39-43`; ca đầu `delivery_provider_test.ts` so cả `receiverEmail` lẫn `receiverName` |
| Đối soát + dead-letter KI-25 (Q2) | ✅ | `parseReconciliationPayload` đọc cả hai kiểu khoá; ca đơn vị + ca `runInvocation` dùng payload camelCase |
| Log (Task 4.5) | ✅ | `einvoice_email_provider_result` chỉ có tenant, transaction, kind, mã |
| Wiring `registry.ts` / `index.ts` | ✅ | 2 handler + 2 dead-letter; 2 ca đăng ký đổi thành 6 khoá |
| Gateway Supabase (G4) | ⚠️ | tham số `p_*` khớp `delivery_rpc_mapper.dart`; nhưng cột bool / int không kiểm — R1-2 |
| Tên ca chép từ Dart | ❌ | thiếu tiền tố group — R1-1 |
| Số liệu Kết quả | ⚠️ | R1-3 |
| TH-08 KI-25, PLAN.md | ✅ | |

#### R1 — việc cần sửa

- [x] **R1-1 — Tên ca thiếu tiền tố group.** Ràng buộc chung mục 5 yêu cầu `Deno.test('<group> <ca>', …)` (như 7-E2b, vd. `'MeInvoiceObservationClassifier uses UNKNOWN labels…'`); 7-E2c chỉ `delivery_payload_test.ts` có tiền tố. Thêm tiền tố cho **các ca chép** (ca mới giữ nguyên tên):
  - `delivery_classifier_test.ts` (25) — `MeInvoiceDeliveryClassifier `
  - `delivery_provider_test.ts` (7) — `MeInvoiceDeliveryProviderAdapter `
  - `delivery_observation_provider_test.ts` (2) — `MeInvoiceDeliveryObservationProviderAdapter `
  - `send_invoice_email_test.ts` (8) — `SendInvoiceEmailCommandHandler prepare branches ` (3 ca đầu) / `SendInvoiceEmailCommandHandler provider outcomes ` (5 ca sau)
  - `reconcile_invoice_delivery_test.ts` (5) — `ReconcileInvoiceDeliveryCommandHandler `
  - `record_delivery_result_test.ts` (3) — `RecordDeliveryResultCommandValidator ` (2) / `RecordDeliveryResultCommandHandler ` (1)
  - `dead_letters_test.ts` — `Einvoice S5 delivery dead-letter ` (4 ca của `einvoice_s5_dead_letter_test`) / `Einvoice S5 reconciliation registration ` (2 ca)
  - `provider_call_reference_test.ts` — `S4 worker command serialization provider-call correlation differs per worker attempt`
  Kiểm: `deno test supabase/functions/einvoice-processor` vẫn 381/381.
- [x] **R1-2 — Gateway nuốt cột sai kiểu.** `supabase_gateways.ts`: `supportsDeliveryResultObservation: Boolean(row.supports_delivery_result_observation)` (`:192`) biến `'false'` / `null` thành giá trị hợp lệ — mục 3 của plan ghi "phải là boolean" (Dart `_requiredBool` ném). `Number(row.delivery_version)` / `case_version` / `retry_count` / `check_sequence` thiếu cột ⇒ `NaN` / `0`, gửi lại `p_expected_version` sai ⇒ `STATE_CHANGED` mỗi lượt thay vì báo lỗi rõ (Dart `_requiredInt` ném). Thêm `requiredBool(row, key)` (không phải `boolean` ⇒ `throw new Error(\`RPC row missing required bool field: ${key}\`)`) và `requiredInt(row, key)` (nhận `number` nguyên hoặc chuỗi số nguyên — bigint có thể về dạng chuỗi; còn lại ⇒ `RPC row missing required int field: ${key}`), dùng cho 5 cột trên. Không cần test đơn vị (như G4); ghi Kết quả.
- [x] **R1-3 — Số liệu Kết quả.** (a) Task 5: "22 tệp mới (21 tệp `handlers/delivery/*` + plan)" — thực tế `handlers/delivery/` có **23** tệp ⇒ 24 tệp mới. (b) Mọi số dòng ghi ít hơn `wc -l` 1 (vd. `outcomes.ts` ghi 37, `wc -l` = 38) vì các tệp kết thúc bằng một dòng trống thừa (`}\n\n`). Bỏ dòng trống cuối ở các tệp `handlers/delivery/*.ts` (hoặc giữ và sửa số), đo lại bằng `wc -l` sau R1-1 / R1-2, cập nhật Kết quả.

**Không chặn (ghi nhận):** `parseReconciliationPayload` nhận chuỗi số / `Infinity` mềm hơn `fromJson` Dart — đúng G2 (gộp handler + dead-letter); tên ca vòng `ambiguous per-invoice results are undetermined ${set.name}` dùng nhãn tự đặt thay vì `toString()` của danh sách Dart (`[Instance of …]`) — chấp nhận.

R2 = lượt review sau khi phiên code xong R1-1 … R1-3 và ghi vào mục 9 (thêm "**R1 — sửa**").

### R2 — 2026-11-08 — **ĐẠT**

| Hạng mục | Kết quả | Ghi chú |
|---|---|---|
| `deno check index.ts` / `deno lint` | ✅ | chạy lại: 141 tệp, 0 lỗi |
| `deno test supabase/functions/einvoice-processor` | ✅ 381/381 | chạy lại |
| R1-1 tên ca | ✅ | 72 ca chép đều có tiền tố group Dart (kể cả 6 ca dead-letter, `S4 worker command serialization …`); 8 ca mới giữ tên |
| R1-2 gateway | ✅ | `requiredBool` / `requiredInt` (`supabase_gateways.ts:25-45`) dùng cho `retry_count`, `delivery_version` (×3), `supports_delivery_result_observation`, `check_sequence`, `case_version`; `requiredInt` nhận chuỗi số nguyên (bigint) |
| R1-3 số liệu | ✅ | 23 tệp `handlers/delivery/` kết thúc `\n` đơn; mọi `tệp:1-N` ở mục 9 khớp `wc -l` (tổng 2 581); 24 tệp mới |

Nhắc quy ước: phiên code đã tự tích `[x]` các việc R1 trong mục 10 — mục 10 chỉ phiên review ghi; lần sau chỉ ghi "**R1 — sửa**" ở mục 9.

Còn lại (người dùng): `git add` + `node .gitnexus/run.cjs detect-changes` trước commit. Không có bước DB.
