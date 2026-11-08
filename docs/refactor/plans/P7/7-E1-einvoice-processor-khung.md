# 7-E1 — HĐĐT: Edge Function `einvoice-processor` — client MISA TypeScript + khung hàng đợi + handler `einvoice.sync_capabilities`

> Theme 8 (mã cũ P7) · Phần server, làm sau 7-B1 (PLAN.md: 7-B1 → 7-E1 → 7-E2 → 7-E3, chốt 2026-11-08).
> Gồm: việc 7.4 phần khung (client MISA, hàng đợi, 1/9 handler); hàm SQL tìm cửa hàng có việc (Q1); sửa lỗi `reschedule_internal_command` ghi cột không có (Q4, KI-22).
> Trạng thái: Plan ✅ (viết 2026-11-08, duyệt 2026-11-08) | Làm ✅ 2026-11-08 | Review ✅ R2 2026-11-08 (ĐẠT; R1 CHƯA ĐẠT → đã sửa R1-1, R1-2)
> Trước: 7-B1. Sau: 7-E2a / 7-E2b / 7-E2c (8 handler còn lại + 6 dead-letter, dùng `FakeMeInvoiceClient`, `QueueRpc`, `HANDLERS`, `DEAD_LETTER_HANDLERS` của plan này), 7-E3 (`pg_cron` gọi function), 7-A1 (app gọi `functions.invoke`).
> Tài liệu: [TH-08](../../../02-yeu-cau/TH-08-hoa-don-dien-tu.md) 1 (dòng 44), 6.2 "Lệnh nội bộ", 9.1 "Sau refactor" (KI-20), 9.2 (PR 7.4), 9.4. Nguồn chép: `packages/vet45_misa/lib` + `test`; `modules/einvoice/infrastructure/lib/src/configuration/processing/internal_commands/process_internal_commands_command_handler.dart`, `einvoice_internal_command_attempt_policy.dart`; `modules/einvoice/application/lib/src/configuration/commands/sync_provider_capabilities/`; `modules/einvoice/infrastructure/lib/src/adapters/misa/{me_invoice_provider_adapter,tenant_me_invoice_client_factory,me_invoice_endpoint_capabilities}.dart`; `modules/einvoice/infrastructure/lib/src/data_access/einvoice_rpc_mapper.dart:53-100`; `modules/einvoice/domain/lib/src/issuance_profile/{provider_template_ref,invoice_series_classification}.dart`. Mẫu Edge Function: `supabase/functions/send-email/`, `supabase/functions/invitation-signup/`.
>
> **Cho phiên code:** dùng `superpowers:executing-plans` (tuần tự). Mỗi task xong ghi ngay mục 9 theo mẫu (tệp:dòng, lệch plan, ca test, impact). **Không commit** (người dùng commit sau `detect_changes()`). **Không làm gì với DB** (không chạy SQL, không reset, không push, không deploy function). **Không đụng `modules/`, `packages/`, `apps/`** (chỉ đọc để chép). **Không ghi mục 10.**

**Goal:** Có Edge Function `supabase/functions/einvoice-processor` chạy được: nhận lời gọi từ `service_role` (quét mọi cửa hàng có việc) hoặc người đăng nhập (một cửa hàng), lấy việc trong `einvoice.internal_commands`, chạy handler `einvoice.sync_capabilities` bằng client MISA TypeScript, ghi kết quả, xử lý thử lại / hỏng / dời giờ đúng như worker Dart cũ; 62 ca test của `vet45_misa` chạy xanh bằng Deno.

**Architecture:** Ba thư mục độc lập: `misa/` (client MISA chép 1:1 từ `vet45_misa`, nhận `fetch` qua constructor), `queue/` (vòng lấy việc, chỉ phụ thuộc interface `QueueRpc` + bảng handler), `handlers/` (handler + tạo client theo cửa hàng). `index.ts` chỉ kiểm quyền, dựng phụ thuộc thật rồi gọi `queue/`. DB: thêm `einvoice.list_tenants_with_due_commands` (migration gốc `…009`), bỏ dòng `updated_at` của `reschedule_internal_command` (migration gốc `…019`).

**Tech Stack:** Deno 2 (máy có 2.9.7, `supabase/config.toml:396` `deno_version = 2`), TypeScript, `npm:@supabase/supabase-js@2`, `jsr:@std/assert@1`; PostgreSQL / plpgsql.

## 1. Mục tiêu

- `deno test supabase/functions/einvoice-processor` xanh: 62 ca chép từ `vet45_misa` + 17 ca chép từ test handler / năng lực / mẫu của `modules/einvoice` + ca mới của `queue/` và `index.ts`.
- `deno check` và `deno lint` trên thư mục không lỗi.
- Gọi function với role `service_role`, body `{}` → quét cửa hàng do `list_tenants_with_due_commands` trả; với role `authenticated`, body `{"tenant_id": "<uuid>"}` → chỉ cửa hàng đó; `authenticated` không có `tenant_id` → 403.
- Việc `einvoice.sync_capabilities` → `record_connection_verified` với `CONNECTED` + năng lực (cùng JSON app đang đọc) hoặc `RECONNECT_REQUIRED`; MISA không phản hồi → thử lại theo `retry_or_dead_letter_internal_command`.
- 8 loại lệnh chưa có handler → dời 300 giây, **không** tính lượt thử.
- `reschedule_internal_command` chạy được (không còn ghi `updated_at`).

**Không làm:** 8 handler còn lại + 6 dead-letter (7-E2); `pg_cron`, `pg_net`, trigger, `record_issuance_success` xếp gửi (7-E3); app gọi `functions.invoke` (7-A1); xoá `packages/vet45_misa`, `platform.list_tenants_with_pending_messaging` (7-C); thêm `[functions.einvoice-processor]` vào `config.toml` (giữ `verify_jwt` mặc định bật); lưu token MISA vào DB.

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | Tìm cửa hàng có việc: hàm cũ `platform.list_tenants_with_pending_messaging` UNION cả outbox / inbox (7-C xoá ⇒ hàm vỡ) và không lọc `enqueued_at <= now()` | **Người dùng chốt 2026-11-08 (A):** hàm mới `einvoice.list_tenants_with_due_commands(p_limit int default 20)` chỉ đọc `internal_commands` đến hạn, `service_role`, viết trong `20261031009` cạnh `claim_internal_commands_batch` |
| Q2 | Ai được gọi function | **Người dùng chốt 2026-11-08 (A):** `verify_jwt` mặc định (gateway đòi JWT hợp lệ). Không có `tenant_id` → chỉ role `service_role`, còn lại 403. Có `tenant_id` → mọi role, không kiểm người gọi thuộc cửa hàng (function chỉ chạy việc đã xếp, không trả dữ liệu cửa hàng) |
| Q3 | Việc có loại chưa có handler (8 loại tới 7-E2) | **Người dùng chốt 2026-11-08 (A):** `reschedule_internal_command(…, 300)` + log `unknown_command_type`; không gọi `retry_or_dead_letter` (sẽ giết việc phát hành thật sau 3 lần) |
| Q4 | Lỗi thấy khi viết plan: `reschedule_internal_command` (`20261031019_einvoice_misa_publish_series_lease.sql:231`) ghi `updated_at = now()` nhưng `einvoice.internal_commands` không có cột `updated_at` (`20260623000001:235-248`, `20261031002:77-90`, không migration nào thêm) ⇒ gọi là lỗi `column "updated_at" does not exist` | **Người dùng chốt 2026-11-08 (A):** sửa ở 7-E1: xoá dòng đó trong migration gốc; ca SQL E33; TH-08 7.3 thêm KI-22 |
| Q5 | Chép client MISA tới đâu | Chép **1:1** toàn bộ `vet45_misa/lib` (10 hàm của `IMeInvoiceClient`, mọi model, `FakeMeInvoiceClient`): tên lớp / hàm / trường giữ như Dart (camelCase), chuỗi lỗi giữ nguyên từng ký tự (bộ phân loại lỗi của 7-E2 so theo chuỗi). Chỉ đổi: `http.Client` → tham số `fetchFn: FetchLike` (mặc định `fetch`); `Duration` → số mili-giây (`…Ms`); `DateTime` → `Date` |
| Q6 | Token MISA | Theo TH-08 9.1: giữ trong `Map` cấp module theo `tenant_id` (chép `TenantMeInvoiceClientFactory`), không lưu DB. Rủi ro ở mục 8 |
| Q7 | Số lượt thử truyền cho handler | Truyền qua `CommandContext.attemptNumber = retryCount + 1` (thay khoá payload `_worker_attempt_number` của Dart); không sửa payload |
| Q8 | Giới hạn mỗi lần gọi | `MAX_TENANTS = 20`, `CLAIM_BATCH = 5`, `SEED_LIMIT = 5`, `MAX_COMMANDS = 20`, `TIME_BUDGET_MS = 90_000` (Edge Function bản miễn phí bị cắt ở 150 giây; một lệnh MISA chờ tối đa 60 giây). Hằng số đầu `queue/processor.ts` |
| Q9 | Chạy test SQL | Phiên code **viết**, không chạy; người dùng chạy (mục 7.2) |
| Q10 | Đếm test `vet45_misa` | 62 lời gọi `test(` trong 6 tệp (8 + 8 + 20 + 7 + 8 + 11). `send_email_response_test.dart` có 2 ca chạy vòng nhiều bộ dữ liệu ⇒ số ca lúc chạy lớn hơn 62 (TH-08 9.2 ghi "80"). Chép đủ vòng; TH-08 9.2 sửa thành "62 test (một số chạy nhiều bộ dữ liệu)" |

## 3. Hiện trạng (đo 2026-11-08)

| Thứ | Ở đâu | Ghi chú |
|---|---|---|
| Bảng `einvoice.internal_commands` | `20261031002_einvoice_install_module_messaging.sql:77-104` | cột: `id` (không default), `tenant_id`, `command_type`, `payload`, `source_event_id`, `enqueued_at`, `processed_at`, `failed_at`, `error`, `retry_count`, `claimed_at`, `claim_token`; chỉ mục `internal_commands_pending_tenant_idx (tenant_id, enqueued_at) where processed_at is null and failed_at is null` |
| `claim_internal_commands_batch(uuid, int)` | `20261031009_einvoice_issuance_reconciliation_rpcs.sql:780-841`; grant `:850` | đến hạn = `enqueued_at <= now()`, khoá quá 10 phút thì lấy lại; trả `command_id, command_type, payload, source_event_id, enqueued_at, claim_token, retry_count` |
| `seed_due_issuance_reconciliation_commands(uuid, int)` | `…009:714-778`; grant `:849` | trả `int` |
| `complete_internal_command(uuid, uuid, uuid)`, `fail_internal_command(uuid, uuid, uuid, text)` | `…002:485-538` (tạo qua `install_module_messaging`) | `fail` đặt `failed_at` + `retry_count + 1` |
| `retry_or_dead_letter_internal_command(uuid, uuid, uuid, text)` | `20261031007…:753-811` | trả `(disposition, retry_count)`; lần thứ 3 → `DEAD_LETTER`; còn lại dời 5 giây (lần 1) / 30 giây |
| `reschedule_internal_command(uuid, uuid, uuid, integer)` | `20261031019…:200-237` | **lỗi Q4** ở `:231` |
| `read_provider_credentials(uuid)` | `20261031003…:366-402` | trả `username, password, tax_code, base_url` (`base_url` luôn `null`); đòi claim `role = service_role` |
| `record_connection_verified(uuid, uuid, int, text, jsonb, timestamptz, text)` | `20261031003…:86-143` | `p_status` ∈ `CONNECTED`, `RECONNECT_REQUIRED`; phiên bản lệch → no-op trả trạng thái hiện tại |
| Ai xếp `einvoice.sync_capabilities` | `connect_provider` `…003:67`, `verify_provider_connection` `:226`, `reconnect_provider` `:302` | payload `{tenant_id, connection_id, expected_connection_version, correlation_id?}` (khoá như `sync_provider_capabilities_command.dart:30-37`) |
| Edge Function đang có | `supabase/functions/send-email/`, `invitation-signup/` | import `npm:` / `jsr:` ngay trong mã, không `deno.json`; test `*_test.ts` cạnh tệp |
| Env worker cũ | `git show c1d3a5445^:apps/messaging_worker/lib/config/worker_env.dart:128-131` | `MISA_MEINVOICE_APP_ID`, `MISA_MEINVOICE_BASE_URL` (bắt buộc), `MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED` |
| Không ai gọi function này | — | tới 7-E3 / 7-A1; trong 7-E1 chỉ kiểm bằng test |

Không có bảng "Đang làm gì": plan không xoá / tách code cũ (xoá `vet45_misa` ở 7-C); test parity chính là các ca chép từ Dart.

## 4. Thiết kế

### G1. SQL (Q1, Q4)

**`einvoice.list_tenants_with_due_commands`** — chèn sau `claim_internal_commands_batch` (`…009:841`), trước `-- Grants`:

```sql
-- 11. Tenants with due internal commands (Edge Function einvoice-processor)
create or replace function einvoice.list_tenants_with_due_commands(p_limit int default 20)
returns table (tenant_id uuid, oldest_due_at timestamptz)
language sql
stable
security definer
set search_path = einvoice, pg_temp
as $$
  select m.tenant_id, min(m.enqueued_at)
  from einvoice.internal_commands m
  where m.processed_at is null
    and m.failed_at is null
    and m.enqueued_at <= now()
    and (m.claimed_at is null or m.claimed_at < now() - interval '10 minutes')
  group by m.tenant_id
  order by min(m.enqueued_at)
  limit greatest(p_limit, 1)
$$;
```

Ở khối `-- Grants`: `revoke all on function einvoice.list_tenants_with_due_commands(int) from public, anon, authenticated;` + `grant execute … to service_role;`. Điều kiện lọc phải **trùng** điều kiện của `claim_internal_commands_batch` (`…009:803-809`).

**`reschedule_internal_command`** (`…019:227-232`): xoá dòng `updated_at = now()` và dấu phẩy thừa ở dòng trên (`claim_token = null`).

### G2. `misa/` (Q5)

Mỗi tệp Dart → một tệp TS cùng tên (snake_case), cùng thư mục con:

| Dart (`packages/vet45_misa/lib/src/e_invoice/`) | TS (`supabase/functions/einvoice-processor/misa/`) |
|---|---|
| `models/me_invoice_result.dart`, `me_invoice_session_token.dart`, `me_invoice_config.dart`, `me_invoice_sign_type.dart` | `models/…` cùng tên `.ts` |
| `models/misa/*.dart` (11 tệp), `models/requests/*.dart` (5), `models/responses/*.dart` (5) | `models/misa/*.ts`, `models/requests/*.ts`, `models/responses/*.ts` |
| `internal/json_helpers.dart`, `error_mapper.dart`, `api_response_parser.dart`, `me_invoice_auth.dart`, `me_invoice_http.dart` | `internal/…` cùng tên |
| `me_invoice_publish_error_codes.dart`, `me_invoice_view_url_policy.dart` | cùng tên |
| `i_me_invoice_client.dart`, `me_invoice_client.dart` | `i_me_invoice_client.ts`, `me_invoice_client.ts` |
| `fake_me_invoice_client.dart` | `fake_me_invoice_client.ts` |
| `lib/e_invoice.dart` (barrel) | `mod.ts` (export đúng danh sách như barrel) |

Kiểu chung (đặt ở `misa/internal/me_invoice_http.ts`, export qua `mod.ts`):

```ts
export type FetchLike = (input: string | URL | Request, init?: RequestInit) => Promise<Response>
```

Quy tắc chép:
- `MeInvoiceResult<T>`: lớp có `static ok<T>(data: T)`, `static failed<T>(error: string, opts?: { rateLimited?: boolean })`, trường `data`, `error`, `rateLimited`, getter `isSuccess` (như Dart).
- `MeInvoiceConfig`: interface `{ baseUrl: string; appId?: string; taxCode?: string; username?: string; password?: string; accessToken?: string; accessTokenExpiresAt?: Date; requestTimeoutMs?: number }` + hàm `missingCredentialError(c)`, `hasCredentials(c)`, `hasBearerToken(c)`, `hasLoginCredentials(c)`; hằng `TEST_BASE_URL`, `PROD_BASE_URL`, `DEFAULT_TOKEN_TTL_MS = 14 ngày`, `RECOMMENDED_TOKEN_TTL_MS = 7 ngày`, `DEFAULT_REQUEST_TIMEOUT_MS = 60_000`.
- `MeInvoiceClient`: `constructor(config: MeInvoiceConfig, fetchFn: FetchLike = fetch)`; hết giờ bằng `AbortSignal.timeout(requestTimeoutMs)`; lỗi hết giờ / mạng map đúng chuỗi như `error_mapper.dart`.
- `MeInvoiceAuth`: `constructor(opts: { baseUrl; appId?; taxCode?; username?; password?; fetchFn: FetchLike; initialToken?: MeInvoiceAuthToken; defaultTtlMs?; requestTimeoutMs?; now?: () => Date })` — thêm `now` để test "hết hạn sau 7 ngày" không phải chờ (Dart dùng `DateTime.now()`; ca Dart giả thời gian thế nào thì chép cách đó, chỉ dùng `now` nếu Dart không có cách khác).
- `fromJson` / `toJson` là `static fromJson(json: Record<string, unknown>)` / phương thức `toJson(): Record<string, unknown>`, khoá JSON giữ nguyên.
- Ngoại lệ Dart (`FormatException`, `ArgumentError`) → `throw new Error(<cùng thông điệp>)` hoặc lớp con cùng tên nếu test Dart bắt theo kiểu.

### G3. `queue/` (Q3, Q7, Q8)

`queue/types.ts`:

```ts
export interface ClaimedCommand {
  commandId: string; commandType: string; payload: Record<string, unknown>
  sourceEventId: string | null; enqueuedAt: string; claimToken: string; retryCount: number
}
export type Disposition = 'RETRY' | 'DEAD_LETTER'
export interface QueueRpc {
  listTenantsWithDueCommands(limit: number): Promise<string[]>
  seedDueReconciliationCommands(tenantId: string, limit: number): Promise<number>
  claimBatch(tenantId: string, limit: number): Promise<ClaimedCommand[]>
  complete(tenantId: string, commandId: string, claimToken: string): Promise<void>
  fail(tenantId: string, commandId: string, claimToken: string, error: string): Promise<void>
  retryOrDeadLetter(tenantId: string, commandId: string, claimToken: string, error: string): Promise<Disposition>
  reschedule(tenantId: string, commandId: string, claimToken: string, delaySeconds: number): Promise<void>
}
export interface CommandContext { tenantId: string; command: ClaimedCommand; attemptNumber: number }
export type CommandHandler = (ctx: CommandContext) => Promise<void>
export type DeadLetterHandler = (ctx: { tenantId: string; command: ClaimedCommand; error: unknown }) => Promise<void>
export interface RunSummary { tenants: number; processed: number; rescheduled: number; failed: number; errors: number }
```

`queue/errors.ts`: `class PublishSeriesLeaseBusyError extends Error { constructor(readonly retryAfterSeconds: number) }` (7-E2 ném); `class ProviderUnavailableError extends Error` (thông điệp `'provider_unavailable'`).

`queue/attempt_policy.ts`: `MAX_ATTEMPTS_BY_COMMAND_TYPE` = `{ 'einvoice.fetch_official_view': 2, 'einvoice.download_invoice_document': 3, 'einvoice.send_invoice_email': 3, 'einvoice.reconcile_invoice_delivery': 3 }`; `maxAttemptsFor(type): number | undefined`.

`queue/supabase_queue_rpc.ts`: `class SupabaseQueueRpc implements QueueRpc { constructor(client: SupabaseClient) }` — mọi hàm gọi `client.schema('einvoice').rpc(<tên SQL>, { p_tenant_id, … })`; `error` khác null → `throw new Error(\`${tên}: ${error.message}\`)`; `retryOrDeadLetter` đọc `data[0].disposition`, rỗng / giá trị lạ → ném. `listTenantsWithDueCommands` trả `data.map(r => r.tenant_id)`.

`queue/processor.ts`:

```ts
export interface ProcessorDeps {
  rpc: QueueRpc
  handlers: Readonly<Record<string, CommandHandler>>
  deadLetters: Readonly<Record<string, DeadLetterHandler>>
  now?: () => number          // mili-giây, mặc định Date.now
  log?: (event: string, data: Record<string, unknown>) => void   // mặc định console.log(JSON.stringify({event, ...data}))
}
export async function runInvocation(deps: ProcessorDeps, tenantId: string | null): Promise<RunSummary>
```

Thuật toán (chép `process_internal_commands_command_handler.dart:35-111`, thêm giới hạn):

1. `tenants = tenantId ? [tenantId] : await rpc.listTenantsWithDueCommands(MAX_TENANTS)`.
2. Với từng cửa hàng, trong `try`: `seedDueReconciliationCommands(t, SEED_LIMIT)`; lặp: nếu `processed + rescheduled + failed >= MAX_COMMANDS` hoặc `now() - start >= TIME_BUDGET_MS` thì dừng; `rows = claimBatch(t, CLAIM_BATCH)`; rỗng thì sang cửa hàng sau; với từng `row`:
   - nếu đã chạm giới hạn → `reschedule(…, 1)`, `rescheduled++`, `continue`;
   - `handler = handlers[row.commandType]`; không có → `reschedule(…, 300)`, log `unknown_command_type`, `rescheduled++`;
   - có → `await handler({tenantId: t, command: row, attemptNumber: row.retryCount + 1})` → `complete`, `processed++`;
   - `catch (e)`: `PublishSeriesLeaseBusyError` → `reschedule(…, e.retryAfterSeconds)`, `rescheduled++`; còn lại: `max = maxAttemptsFor(type)`; `max !== undefined && attemptNumber >= max` → `fail(…, String(e))` + dead-letter (nếu có), `failed++`; ngược lại `retryOrDeadLetter(…, String(e))`, `DEAD_LETTER` → dead-letter (nếu có) + `failed++`, `RETRY` → `rescheduled++`.
   - Lỗi của chính dead-letter handler: log `dead_letter_error`, không ném.
3. `catch` quanh cả cửa hàng (RPC lỗi): log `tenant_error` (chỉ `tenantId` + `String(e)`), `errors++`, sang cửa hàng sau.
4. Trả `RunSummary` (`tenants = tenants.length`).

Thứ tự kiểm giới hạn trước mỗi `claimBatch` và trước mỗi `row` giữ cho việc đã claim mà chưa chạy luôn được trả lại (không đợi khoá 10 phút).

### G4. `handlers/` (Q6)

`handlers/template_ref.ts` — chép `invoice_series_classification.dart` + `provider_template_ref.dart`:

```ts
export interface ProviderTemplateRef {
  templateId: string; name: string; invoiceSeries: string; invoiceWithCode: boolean
  isMtt: boolean; isSendSummary: boolean; serial: string | null; isAvailable: boolean
}
export function classifyInvoiceSeries(invSeries: string): { invoiceWithCode: boolean; isMtt: boolean } | null
export function tryCreateTemplateRef(input: { templateId: string; name: string; invoiceSeries: string; isSendSummary: boolean; serial?: string | null; isAvailable?: boolean }): ProviderTemplateRef | null
export function mergeAndDedupe(refs: Iterable<ProviderTemplateRef>): ProviderTemplateRef[]
```

`handlers/endpoint_capabilities.ts` — chép `me_invoice_endpoint_capabilities.dart`: `resolveEndpointCapabilities(baseUrl: string, emailDeliveryEnabled: boolean): { supportsEmailDelivery: boolean; supportedDocumentTypes: ('PDF' | 'XML')[]; supportsPreview: boolean }`; scheme khác `https` → `throw new Error('MISA endpoint baseUrl must use HTTPS')`; email chỉ khi cờ bật **và** host (chữ thường) là `api.meinvoice.vn`; tài liệu `['PDF', 'XML']`; xem trước `true`.

`handlers/misa_env.ts`: `interface MisaEnv { appId: string; baseUrl: string; emailDeliveryEnabled: boolean }`; `readMisaEnv(get: (k: string) => string | undefined): MisaEnv` — thiếu `MISA_MEINVOICE_APP_ID` / `MISA_MEINVOICE_BASE_URL` → ném `missing_MISA_MEINVOICE_APP_ID` / `missing_MISA_MEINVOICE_BASE_URL`; cờ email `true` khi giá trị (trim, chữ thường) là `true` hoặc `1`.

`handlers/misa_client_factory.ts` — chép `tenant_me_invoice_client_factory.dart` + `_readCredentials` (`me_invoice_provider_adapter.dart:413-424`):

```ts
export interface CredentialsRow { username: string | null; password: string | null; tax_code: string | null; base_url: string | null }
export interface CredentialsReader { read(tenantId: string): Promise<CredentialsRow | null> }  // bản thật: client.schema('einvoice').rpc('read_provider_credentials', {p_tenant_id})
export class TenantMisaClientFactory {
  constructor(env: MisaEnv, credentials: CredentialsReader, create?: (c: MeInvoiceConfig) => IMeInvoiceClient)
  getForTenant(tenantId: string): Promise<{ client: IMeInvoiceClient; baseUrl: string } | null>   // null khi không có dòng mật khẩu
  invalidate(tenantId: string): void
}
```

Cache cấp module do `index.ts` giữ (một `TenantMisaClientFactory` dựng một lần ở đầu module). Cấu hình = `{ baseUrl: row.base_url ?? env.baseUrl, appId: env.appId, taxCode, username, password }`; cấu hình khác lần trước (so 5 trường như `_sameConfig`) → client mới.

`handlers/sync_capabilities.ts`:

```ts
export interface ConnectionRecorder {   // bản thật: rpc('record_connection_verified', {...})
  record(input: { tenantId: string; connectionId: string; expectedConnectionVersion: number
    status: 'CONNECTED' | 'RECONNECT_REQUIRED'; capabilities?: Record<string, unknown>
    verifiedAt?: string; correlationId?: string }): Promise<void>
}
export function createSyncCapabilitiesHandler(deps: {
  clients: TenantMisaClientFactory; recorder: ConnectionRecorder; env: MisaEnv; now?: () => Date
  log?: (event: string, data: Record<string, unknown>) => void
}): CommandHandler
export function safeFailureReason(error: string): string   // chép _safeFailureReason + _safeCode
```

Luồng (chép `sync_provider_capabilities_command_handler.dart:24-69` + `me_invoice_provider_adapter.dart:43-148`):
1. Payload: `tenant_id` (bỏ qua, dùng `ctx.tenantId`), `connection_id` (bắt buộc, thiếu → ném), `expected_connection_version` (số, thiếu → `-1`), `correlation_id?`.
2. `getForTenant` trả `null` → `record(RECONNECT_REQUIRED)`.
3. `obtainAccessToken({forceLogin: true})` → `listInvoiceTemplates({invoiceWithCode: true})` → `listInvoiceTemplates({invoiceWithCode: false})`. Bước nào `!isSuccess`: `invalidate`, log `misa_verification_failed` với `stage` (`token` / `templates`) + `safeFailureReason`; lỗi (chữ thường) chứa `unavailable` hoặc `timeout` → `throw new ProviderUnavailableError()`; còn lại → `record(RECONNECT_REQUIRED)` rồi return. (Bước token: chứa `missing credential` → `RECONNECT_REQUIRED` trước khi xét `unavailable` / `timeout`, như Dart `:76-82`.)
4. Mẫu: nối hai danh sách (có mã trước), bỏ `inactive`, `tryCreateTemplateRef({templateId: ipTemplateId, name: templateName, invoiceSeries: invSeries, isSendSummary, serial: invTemplateNo, isAvailable: !inactive})`, bỏ `null`, `mergeAndDedupe`.
5. `caps = resolveEndpointCapabilities(baseUrl, env.emailDeliveryEnabled)`.
6. `record(CONNECTED, verifiedAt = now().toISOString(), capabilities = …)` với JSON đúng khoá `einvoice_rpc_mapper.dart:62-93`:
   `supports_email_delivery`, `supports_preview`, `supports_delivery_result_observation: false`, `template_count` (= số mẫu sau gộp), `supported_document_types`, `templates: [{template_id, name, serial, symbol, invoice_series, invoice_with_code, is_mtt, is_send_summary, is_available}]` (`symbol` = `invoice_series`), `synced_at` (= `verifiedAt`).
7. Log không bao giờ chứa mật khẩu, token, tên đăng nhập.

`handlers/registry.ts`:

```ts
export function buildHandlers(deps: Parameters<typeof createSyncCapabilitiesHandler>[0]): Record<string, CommandHandler>
  // { 'einvoice.sync_capabilities': createSyncCapabilitiesHandler(deps) } — 7-E2 thêm 8 dòng
export const DEAD_LETTER_HANDLERS: Readonly<Record<string, DeadLetterHandler>> = {}   // 7-E2 thêm 5
```

### G5. `index.ts` (Q2)

`auth.ts` (hàm thuần, test được):

```ts
export type AuthDecision = { ok: true; tenantId: string | null } | { ok: false; status: 400 | 403 | 405; error: string }
export function readJwtRole(authorization: string | null): string | null   // giải mã phần payload base64url của Bearer JWT (gateway đã kiểm chữ ký); lỗi → null
export function authorizeRequest(method: string, role: string | null, body: unknown): AuthDecision
```

`authorizeRequest`: method khác `POST` → `405 method_not_allowed`; `body.tenant_id` có mà không phải chuỗi UUID (regex như `send-email/index.ts:4-5`) → `400 invalid_tenant_id`; không có `tenant_id` và `role !== 'service_role'` → `403 service_role_required`; còn lại `ok`. Body không phải object (hoặc rỗng) coi như `{}`.

`index.ts`: `Deno.serve` → đọc JSON (lỗi parse → coi như `{}`; body rỗng là bình thường với `pg_net`) → `authorizeRequest` → thiếu `SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY` → `500 missing_supabase_env` → `readMisaEnv(Deno.env.get)` lỗi → `500 missing_misa_env` → dựng `createClient(url, serviceRoleKey, { auth: { persistSession: false, autoRefreshToken: false } })` (một lần ở cấp module, lười), `SupabaseQueueRpc`, `TenantMisaClientFactory` (cấp module, giữ token giữa các lần gọi trong cùng isolate), `buildHandlers`, rồi `runInvocation` → `200` + `RunSummary`. Lỗi không bắt được → `500 internal_error` (log không có payload).

## 5. Các bước

**Ràng buộc chung** (mọi task):
- Lệnh test: `deno test supabase/functions/einvoice-processor` (chạy từ gốc repo); không cần quyền mạng (mọi `fetch` là giả). Lệnh kiểm: `deno check supabase/functions/einvoice-processor/index.ts` và `deno lint supabase/functions/einvoice-processor`.
- Test chép từ Dart: **giữ tên ca** (chuỗi trong `test('…')`), `Deno.test('<tên group> <tên ca>', …)`; giữ dữ liệu đầu vào và giá trị so sánh. Ca nào phải đổi (khác kiểu thời gian, khác cách bắt lỗi) ghi Kết quả.
- Mỗi task: viết test trước, chạy thấy đỏ (thiếu module), viết mã, chạy thấy xanh.

### Task 1: SQL — `list_tenants_with_due_commands` + sửa `reschedule_internal_command` (G1)

**Files:** Modify: `supabase/migrations/20261031009_einvoice_issuance_reconciliation_rpcs.sql:841-850`, `supabase/migrations/20261031019_einvoice_misa_publish_series_lease.sql:227-232`, `supabase/tests/einvoice_th08.sql` (trước `reset role; raise notice 'einvoice_th08: OK'` ở `:777`)

- [ ] **1.1** Chạy `impact({target: "reschedule_internal_command", direction: "upstream"})` và `impact({target: "claim_internal_commands_batch", direction: "upstream"})` (GitNexus); ghi Kết quả (index có thể không có symbol SQL — ghi "không có trong index" nếu vậy).
- [ ] **1.2** Thêm ca vào `einvoice_th08.sql` (khai báo biến mới ở `declare`; dùng tenant **B** `v_tb` — không có việc nào từ các ca trước; chạy dưới `reset role`):
  - **E32** ✱ Q1: chèn 4 dòng `internal_commands` cho `v_tb` (`id = gen_random_uuid()`, `command_type = 'einvoice.sync_capabilities'`, `payload = '{}'`): (a) `enqueued_at = now() + interval '1 hour'`; (b) `claimed_at = now() - interval '1 minute'`, `claim_token = gen_random_uuid()`; (c) `processed_at = now()`; ⇒ `v_tb` **không** có trong `list_tenants_with_due_commands(1000)`. Thêm (d) `claimed_at = now() - interval '11 minutes'` ⇒ `v_tb` **có**, `oldest_due_at` ≤ `now()`.
  - **E33** ✱ Q4: `claim_internal_commands_batch(v_tb, 10)` lấy dòng (d) (lưu `command_id`, `claim_token`, `retry_count`); `reschedule_internal_command(v_tb, id, token, 120)` không lỗi; sau đó dòng có `enqueued_at` trong `[now() + 119s, now() + 121s]`, `claimed_at is null`, `claim_token is null`, `retry_count` không đổi; `v_tb` không còn trong `list_tenants_with_due_commands(1000)`.
  - **E34** ✱ quyền: `set local role authenticated` (claim của owner A) → `_th08_expect_err('select * from einvoice.list_tenants_with_due_commands(10)', 'permission denied')`; `reset role`.
- [ ] **1.3** Viết hàm + `revoke` / `grant` theo G1; xoá dòng `updated_at` ở `…019`.
- [ ] **1.4** `grep -n "updated_at" supabase/migrations/2026103100*.sql supabase/migrations/2026103101*.sql supabase/migrations/2026103102*.sql | grep -i "internal_commands"` và đọc mọi `update einvoice.internal_commands` (`grep -n "update einvoice.internal_commands" supabase/migrations/*.sql`): ghi Kết quả còn chỗ nào ghi cột không có hay không.

### Task 2: `misa/` — model + phân tích JSON (G2)

**Files:** Create: `supabase/functions/einvoice-processor/misa/models/**/*.ts`, `misa/internal/json_helpers.ts`, `misa/internal/error_mapper.ts`, `misa/internal/api_response_parser.ts`, `misa/me_invoice_publish_error_codes.ts`, `misa/me_invoice_view_url_policy.ts`; Test: `misa/model_roundtrip_test.ts` (7 ca, từ `model_roundtrip_test.dart`)

**Interfaces — Produces:** các lớp model cùng tên Dart (`MeInvoiceTemplate`, `MeInvoiceInvoiceData`, `MeInvoicePublishRequest`, `MeInvoiceInvoiceQuery` với `static fromInvSeries` / `tryFromInvSeries`, `MeInvoiceApiResponse`, `MeInvoiceSendEmailRequest`, `MeInvoiceSendEmailResponse`, `MeInvoiceInvoiceStatus`, `MeInvoiceInvoiceDataPublished`, `MeInvoicePublishInvoiceResultItem`, `MeInvoiceTicket`, …), `MeInvoiceResult`, `MeInvoiceConfig` + hàm của G2, `MeInvoiceSignType`, các enum (`MeInvoiceDownloadDataType`, `MeInvoiceStatusInputType`).

- [ ] **2.1** Chép `model_roundtrip_test.dart` → `model_roundtrip_test.ts`; chạy, thấy đỏ.
- [ ] **2.2** Chép model + `json_helpers`, `error_mapper`, `api_response_parser`, `publish_error_codes`, `view_url_policy` theo G2; chạy, thấy 7 ca xanh.
- [ ] **2.3** Ghi Kết quả: số dòng TS / Dart; chỗ đổi kiểu (enum Dart → union / `const` object).

### Task 3: `misa/` — đăng nhập, HTTP, `MeInvoiceClient` (G2)

**Files:** Create: `misa/internal/me_invoice_auth.ts`, `misa/internal/me_invoice_http.ts`, `misa/i_me_invoice_client.ts`, `misa/me_invoice_client.ts`; Test: `misa/auth_token_store_test.ts` (8), `misa/me_invoice_client_test.ts` (20), `misa/send_email_response_test.ts` (8, có vòng), `misa/th08_hardening_parse_view_url_test.ts` (11)

**Interfaces — Consumes:** Task 2. **Produces:** `FetchLike`; `interface IMeInvoiceClient` (10 hàm như `i_me_invoice_client.dart`: `obtainAccessToken({forceLogin?})`, `listInvoiceTemplates({invoiceWithCode, year?})`, `listTicketTemplates({invoiceWithCode, year?})`, `previewUnpublished(invoice)`, `publish(request)`, `previewPublished({transactionIds, companyTaxCode, query?})`, `download({transactionIds, query, downloadDataType})`, `getStatus({ids, inputType, query})`, `sendEmail(request)`, `convertToPaper({transactionIds, query, converter, convertDate})`, mọi hàm trả `Promise<MeInvoiceResult<…>>`); `class MeInvoiceClient implements IMeInvoiceClient { constructor(config: MeInvoiceConfig, fetchFn?: FetchLike) }`; `MeInvoiceAuth`, `MeInvoiceAuthToken`.

- [ ] **3.1** Chép 4 tệp test (HTTP giả: hàm `FetchLike` trả `new Response(JSON.stringify(…), {status})` theo URL / method, ghi lại request để so body / query như `MockClient` của Dart); chạy, thấy đỏ.
- [ ] **3.2** Chép `me_invoice_auth`, `me_invoice_http`, `i_me_invoice_client`, `me_invoice_client`; chạy, thấy 47 ca (theo mã nguồn) xanh.
- [ ] **3.3** Ghi Kết quả: cách giả thời gian ở 2 ca "7 ngày"; cách giả hết giờ (ca "API timeout maps to stable network timeout code", "authentication timeout …").

### Task 4: `FakeMeInvoiceClient` + barrel (G2)

**Files:** Create: `misa/fake_me_invoice_client.ts`, `misa/mod.ts`; Test: `misa/fake_me_invoice_client_test.ts` (8)

**Interfaces — Produces:** `class FakeMeInvoiceClient implements IMeInvoiceClient` cùng kịch bản / hàng đợi như Dart (`ok`, `failed`, `rateLimited`, `missingCredentials`, `tokenExpiredThenOk`, hàng đợi FIFO `previewPublished` / `download` / `getStatus`, `enqueueSendEmailEnvelopeAcknowledgement`); `mod.ts` export đúng danh sách của `lib/e_invoice.dart`.

- [ ] **4.1** Chép test; chạy, thấy đỏ.
- [ ] **4.2** Chép `fake_me_invoice_client.dart`, viết `mod.ts`; chạy, thấy 8 ca xanh. Tổng `misa/`: 62 ca theo mã nguồn.

### Task 5: `queue/` (G3)

**Files:** Create: `queue/types.ts`, `queue/errors.ts`, `queue/attempt_policy.ts`, `queue/processor.ts`, `queue/supabase_queue_rpc.ts`; Test: `queue/processor_test.ts`

**Interfaces — Produces:** toàn bộ kiểu ở G3; `runInvocation(deps, tenantId)`; `PublishSeriesLeaseBusyError`, `ProviderUnavailableError`; `maxAttemptsFor`; `SupabaseQueueRpc`.

- [ ] **5.1** Viết `processor_test.ts` với `FakeQueueRpc` (ghi lại mọi lời gọi theo thứ tự; `claimBatch` trả lần lượt từ danh sách dựng sẵn rồi `[]`; `retryOrDeadLetter` trả giá trị dựng sẵn) và đồng hồ giả. Ca:
  - `complete after handler succeeds` — 1 việc, handler xong ⇒ lời gọi `seed(t,5)`, `claim(t,5)`, `complete`, `claim`; summary `{tenants:1, processed:1, rescheduled:0, failed:0, errors:0}`.
  - `handler receives attemptNumber = retryCount + 1` — `retryCount: 2` ⇒ `ctx.attemptNumber === 3`.
  - `unknown command type is rescheduled 300s without consuming an attempt` — loại `einvoice.publish_invoice`, không handler ⇒ `reschedule(…, 300)`, không `retryOrDeadLetter` / `fail`; log có `unknown_command_type`.
  - `lease busy reschedules by retryAfter` — handler ném `new PublishSeriesLeaseBusyError(42)` ⇒ `reschedule(…, 42)`.
  - `typed attempt limit fails and dead-letters on last attempt` — `einvoice.fetch_official_view`, `retryCount: 1` (lượt 2/2), handler ném ⇒ `fail(…, 'Error: boom')`, dead-letter gọi 1 lần với `error` là lỗi gốc; không `retryOrDeadLetter`.
  - `typed attempt limit below max uses retryOrDeadLetter` — `einvoice.download_invoice_document`, `retryCount: 0` ⇒ `retryOrDeadLetter`.
  - `generic failure retries` — `retryOrDeadLetter` trả `RETRY` ⇒ không dead-letter, `rescheduled: 1`.
  - `generic failure dead-letters` — trả `DEAD_LETTER` ⇒ dead-letter gọi 1 lần, `failed: 1`.
  - `dead-letter handler error does not escape` — dead-letter ném ⇒ `runInvocation` vẫn resolve; log `dead_letter_error`.
  - `stops at MAX_COMMANDS and hands back claimed rows` — `claimBatch` trả 5 việc mỗi lần, 5 lần; ⇒ đúng 20 `complete`, không có lần `claim` thứ 5.
  - `time budget hands back remaining claimed rows` — đồng hồ nhảy 91.000 ms sau việc đầu của lô 3 việc ⇒ 1 `complete`, 2 `reschedule(…, 1)`, không `claim` thêm.
  - `tenant error does not block next tenant` — `tenantId = null`, `listTenantsWithDueCommands` trả `[t1, t2]`, `seed(t1)` ném ⇒ `t2` vẫn được `claim`; `errors: 1`, `tenants: 2`.
  - `explicit tenant skips discovery` — `tenantId = 't1'` ⇒ không gọi `listTenantsWithDueCommands`.
  - `discovery uses MAX_TENANTS` — ⇒ `listTenantsWithDueCommands(20)`.
- [ ] **5.2** Chạy, thấy đỏ; viết `types`, `errors`, `attempt_policy`, `processor` theo G3; chạy, thấy xanh.
- [ ] **5.3** Viết `SupabaseQueueRpc` (không test đơn vị — chỉ ánh xạ tên RPC / tham số; review đối chiếu bảng mục 3). Tên tham số: `p_tenant_id`, `p_limit`, `p_command_id`, `p_claim_token`, `p_error`, `p_delay_seconds`.

### Task 6: `handlers/` (G4)

**Files:** Create: `handlers/template_ref.ts`, `handlers/endpoint_capabilities.ts`, `handlers/misa_env.ts`, `handlers/misa_client_factory.ts`, `handlers/sync_capabilities.ts`, `handlers/registry.ts`; Test: `handlers/template_ref_test.ts` (5, từ `th08_hardening_provider_template_ref_test.dart`), `handlers/endpoint_capabilities_test.ts` (5, từ `me_invoice_endpoint_capabilities_test.dart`), `handlers/sync_capabilities_test.ts` (5 từ `sync_provider_capabilities_handler_test.dart` + 2 từ `th08_hardening_capability_templates_test.dart` + ca mới dưới đây), `handlers/misa_client_factory_test.ts`

**Interfaces — Consumes:** `FakeMeInvoiceClient`, `IMeInvoiceClient`, `MeInvoiceConfig` (Task 2–4); `CommandHandler`, `CommandContext`, `ProviderUnavailableError` (Task 5). **Produces:** mọi chữ ký ở G4; `buildHandlers`, `DEAD_LETTER_HANDLERS`.

- [ ] **6.1** Chép 17 ca Dart (thay `IMeInvoiceProviderPort` giả bằng `FakeMeInvoiceClient` + `CredentialsReader` / `ConnectionRecorder` giả; giữ giá trị so sánh). Ca mới:
  - `capabilities JSON uses the keys the app reads` — `record` nhận `capabilities` có đúng tập khoá cấp 1 `['supports_email_delivery','supports_preview','supports_delivery_result_observation','template_count','supported_document_types','templates','synced_at']` và mỗi mẫu đúng 9 khoá của G4 bước 6; `symbol === invoice_series`.
  - `missing credentials row records RECONNECT_REQUIRED` — `CredentialsReader` trả `null`.
  - `missing expected_connection_version defaults to -1`.
  - `safeFailureReason never echoes secrets` — `safeFailureReason('meinvoice_auth_rejected:InvalidPassword secret=abc')` = `'InvalidPassword'`; `'request timeout'` = `'TIMEOUT'`.
  - `email delivery requires flag and production host` — `MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED=true` + `https://testapi.meinvoice.vn/…` ⇒ `supports_email_delivery: false`.
  - `misa_client_factory`: `reuses client for same config`, `new client after password change`, `invalidate drops cached client`, `base_url null falls back to env`.
  - `readMisaEnv`: thiếu app id ⇒ ném `missing_MISA_MEINVOICE_APP_ID`; `'1'` ⇒ cờ email `true`.
- [ ] **6.2** Chạy, thấy đỏ; viết 6 tệp theo G4; chạy, thấy xanh.

### Task 7: `index.ts` + kiểm toàn thư mục (G5)

**Files:** Create: `supabase/functions/einvoice-processor/auth.ts`, `index.ts`; Test: `auth_test.ts`

**Interfaces — Consumes:** `runInvocation`, `SupabaseQueueRpc` (Task 5); `buildHandlers`, `DEAD_LETTER_HANDLERS`, `TenantMisaClientFactory`, `readMisaEnv` (Task 6).

- [ ] **7.1** `auth_test.ts`: `GET` ⇒ 405; `service_role` + `{}` ⇒ ok, `tenantId: null`; `authenticated` + `{}` ⇒ 403 `service_role_required`; `authenticated` + `{tenant_id: <uuid>}` ⇒ ok; `{tenant_id: 'abc'}` ⇒ 400 `invalid_tenant_id`; body `null` ⇒ như `{}`; `readJwtRole` với JWT dựng tay (`header.base64url({role:'service_role'}).sig`) ⇒ `'service_role'`; chuỗi rác / thiếu `Bearer ` ⇒ `null`.
- [ ] **7.2** Chạy, thấy đỏ; viết `auth.ts`, `index.ts` theo G5; chạy, thấy xanh.
- [ ] **7.3** `deno check supabase/functions/einvoice-processor/index.ts`, `deno lint supabase/functions/einvoice-processor`, `deno test supabase/functions/einvoice-processor` — ghi số ca đạt / lỗi vào Kết quả.
- [ ] **7.4** `grep -rn "password\|access_token\|accessToken" supabase/functions/einvoice-processor --include=*.ts | grep -i "log\|console"` ⇒ không có dòng nào log bí mật; ghi Kết quả.

### Task 8: Tài liệu + `detect_changes` + Kết quả

**Files:** Modify: `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md`, `docs/refactor/PLAN.md`

- [ ] **8.1** TH-08: 7.3 thêm **KI-22**: "`reschedule_internal_command` ghi `updated_at` nhưng `internal_commands` không có cột này — Đã sửa 7-E1"; 6.2 dòng bộ xử lý thêm `list_tenants_with_due_commands`; 9.1 "Sau refactor": thêm "`pg_cron` quét cửa hàng qua `einvoice.list_tenants_with_due_commands`; không `tenant_id` chỉ `service_role`, có `tenant_id` mọi người đăng nhập (7-E1 Q2); loại lệnh chưa có handler dời 300 giây"; 9.2 dòng 7.4 "80 test" → "62 test (một số chạy nhiều bộ dữ liệu)"; 6.1 / 9.1 ghi secret Edge Function `MISA_MEINVOICE_APP_ID`, `MISA_MEINVOICE_BASE_URL`, `MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED`.
- [ ] **8.2** PLAN.md: dòng 7-E1 Làm ✅ + ngày; dòng 7-C thêm "xoá `platform.list_tenants_with_pending_messaging` / `messaging_module_registry` nếu hết người dùng (Edge Function dùng `einvoice.list_tenants_with_due_commands`, 7-E1)".
- [ ] **8.3** `node .gitnexus/run.cjs analyze` rồi `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory --scope all`: chỉ tệp trong plan; ghi số tệp / symbol / luồng / rủi ro. Hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu `analyze` sửa.

## 6. Review Focus (chưa ca nào chạy — phiên review soi)

1. **Chuỗi lỗi MISA lệch bản Dart:** một ký tự khác trong `meinvoice_network`, `meinvoice_5xx`, `TokenExpiredCode`, `missing credential`, `meinvoice_auth_rejected:` làm bộ phân loại của 7-E2 hiểu sai (lỗi chưa rõ thành lỗi chắc chắn ⇒ phát hành trùng). Review `diff` chuỗi: `grep -ohE "'[a-z_A-Z]+(:|')" packages/vet45_misa/lib -r | sort -u` so với cùng lệnh trên `misa/` (dấu `"`/`'`).
2. **Điều kiện lọc của `list_tenants_with_due_commands` lệch `claim_internal_commands_batch`:** lệch ⇒ cửa hàng được liệt kê mà claim rỗng (phí) hoặc có việc mà không bao giờ được quét (kẹt). Review đặt hai `where` cạnh nhau.
3. **Việc đã claim bị bỏ rơi:** mọi nhánh thoát vòng (giới hạn, lỗi RPC giữa lô) phải `reschedule` hoặc để khoá tự hết; lỗi RPC ở `complete` sau khi handler đã chạy xong ⇒ việc sẽ chạy lại sau 10 phút — chấp nhận được vì `record_*` idempotent; review xác nhận `sync_capabilities` chạy lại không gây hại (`record_connection_verified` phiên bản lệch → no-op).
4. **Lộ bí mật trong log / phản hồi:** `String(e)` của lỗi đăng nhập có thể chứa thân phản hồi MISA; `tenant_error` / `dead_letter_error` / `fail(…, error)` ghi vào DB. Review xem chuỗi lỗi của client có bao giờ chứa mật khẩu / token không (bản Dart: `error_mapper.dart` chỉ giữ mã an toàn).
5. **Hết giờ thật của Edge Function:** ngân sách 90 giây chỉ kiểm **giữa** các việc; một việc 60 giây bắt đầu ở giây 89 kết thúc ở 149 — sát 150. Review chấp nhận hoặc đề xuất hạ `TIME_BUDGET_MS` (ghi Review).

## 7. Kiểm tra

### 7.1 Tự động
Task 7.3 (`deno check`, `deno lint`, `deno test`), Task 8.3 (`detect-changes`). Không có test Dart (plan không đổi app).

### 7.2 Việc của người dùng
- DB local: reset rồi `psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/einvoice_th08.sql` → `einvoice_th08: OK`. Ca nào FAIL ⇒ báo phiên sửa.
- (Tuỳ chọn) `supabase functions serve einvoice-processor --env-file <tệp có 3 biến MISA>` rồi `curl -X POST -H "Authorization: Bearer $SERVICE_ROLE_JWT" -d '{}' http://127.0.0.1:54321/functions/v1/einvoice-processor` → `200` + `RunSummary`; bấm "Kết nối" trên màn HĐĐT rồi gọi lại → kết nối thành `CONNECTED` (MISA sandbox) — kiểm đầy đủ ở 7-E3.

## 8. Rủi ro / lưu ý

- **Đăng nhập MISA lặp:** isolate sống ngắn ⇒ gần như mỗi lần gọi có việc phải `/auth/token`; MISA cảnh báo chặn IP nếu gọi nhiều. Chỉ đăng nhập khi cửa hàng có việc (lượt quét rỗng không đăng nhập). Bị chặn ở checklist 7-E3 thì mới tính lưu token (cần người dùng chốt, trái TH-08 9.1).
- **Khoá API mới của Supabase** (`sb_secret_…`) không phải JWT ⇒ `readJwtRole` trả `null` ⇒ 403 khi không `tenant_id`. 7-E3 phải gọi bằng JWT `service_role` (ghi chú cho 7-E3).
- **Migration đã áp:** sửa tại chỗ `…009`, `…019` ⇒ local / Dev chưa có tới khi reset (việc người dùng).
- **Trùng việc khi app + `pg_cron` gọi cùng lúc:** do `claim … for update skip locked` bảo đảm (TH-08 9.3 E2E, kiểm ở 7-E3).
- **`sync_capabilities` trước 7-E3:** chưa có gì gọi function ⇒ bấm "Kết nối" trên app vẫn đứng ở "Đang kiểm tra" như hiện nay.

## 9. Kết quả (phiên làm code ghi)

<!-- Mẫu mỗi task:
**Task N — ✅/🔄**
- Tệp: `đường/dẫn:dòng` (tạo / sửa), số dòng.
- Lệch plan + lý do:
- Ca test: tên + số ca đạt / lỗi (lệnh đã chạy).
- Impact: symbol / luồng / rủi ro (Task 1.1, 8.3).
-->

**Task 1 — ✅ (SQL; không chạy được ở phiên này — việc của người dùng, Q9)**
- Tệp: `supabase/migrations/20261031009_einvoice_issuance_reconciliation_rpcs.sql` (thêm `list_tenants_with_due_commands` mục 11 trước `-- Grants`, `revoke`/`grant` cạnh `claim_internal_commands_batch`); `…019_einvoice_misa_publish_series_lease.sql:227-231` (bỏ `updated_at = now()` và dấu phẩy thừa); `supabase/tests/einvoice_th08.sql` (E32a/E32b, E33, E34 trước `raise notice 'einvoice_th08: OK'`; khai báo thêm `v_cmd, v_tok, v_rc, v_due, v_n`).
- Lệch plan: E33 không chèn dòng (d) riêng ở bước E33 mà dùng lại dòng (d) của E32 (lấy qua `claim_internal_commands_batch(v_tb, 10)`); `reset role` đầu E32 vì file đang ở role owner A từ E31 — E31 đã `reset role` ở cuối nên thêm `reset role` nữa là vô hại. E34 đặt `request.jwt.claims = v_claims` (owner A) rồi `set local role authenticated`.
- Ca test: chưa chạy (chỉ người dùng chạy `psql … -f supabase/tests/einvoice_th08.sql`).
- 1.4: mọi `update einvoice.internal_commands` còn lại (`…007:726/789/799`, `…009:816`) chỉ ghi `claimed_at, claim_token, failed_at, error, retry_count, enqueued_at` — đều có cột. Không còn chỗ nào ghi cột không có.
- Impact: GitNexus chỉ lập chỉ mục tệp tài liệu cho lần này (index chưa phân tích lại, không có symbol SQL) ⇒ "không có trong index". Người gọi `reschedule_internal_command` hiện tại: chưa có (chỉ 7-E2 gọi) ⇒ rủi ro thấp.

**Task 2 — ✅**
- Tệp: `misa/models/{me_invoice_result,me_invoice_session_token,me_invoice_config,me_invoice_sign_type}.ts`, `misa/models/misa/*.ts` (11), `models/requests/*.ts` (5), `models/responses/*.ts` (5), `misa/internal/{json_helpers,error_mapper,api_response_parser,format_exception}.ts`, `me_invoice_publish_error_codes.ts`, `me_invoice_view_url_policy.ts`; test `misa/model_roundtrip_test.ts`.
- Lệch plan: 9 model "phẳng" (`clock_info`, `fee_info`, `option_user_defined`, `original_invoice_detail`, `other_info`, `tax_rate_info`, `publish_invoice_data`, `invoice_status`, `invoice_data`) sinh bằng script từ mã Dart (cùng thứ tự trường / khoá JSON) rồi `deno check`; `template`, `ticket`, request, response viết tay. Enum Dart (`MeInvoiceSignType`, `…StatusInputType`, `…DownloadDataType`, `…SendEmailResponseKind`, `FakeMeInvoiceScenario`) → `const` object + union (có `wireValue`). Thêm `internal/format_exception.ts` (lớp `FormatException` để ca "throws FormatException" bắt theo kiểu) và `internal/timeout.ts` (`FetchLike`, `TimeoutException`, `withTimeout`). Khác biệt biết trước: số nguyên-dạng-double của Dart (`5.0`) in ra `5` trong JSON TS; `readString` của số/đối tượng dùng `String()` của JS.
- Ca test: 7/7 (`deno test misa/model_roundtrip_test.ts`).

**Task 3 — ✅**
- Tệp: `misa/internal/{me_invoice_auth,me_invoice_http,timeout}.ts`, `misa/i_me_invoice_client.ts`, `misa/me_invoice_client.ts`; test `auth_token_store_test.ts` (8), `me_invoice_client_test.ts` (20), `send_email_response_test.ts` (26 ca chạy: 4 + 10 vòng + 10 dữ liệu hỏng + 2), `th08_hardening_parse_view_url_test.ts` (11); trợ giúp test `misa/test_support.ts` (`mockFetch`, giống `MockClient`).
- Lệch plan: `MeInvoiceAuth` nhận `now` (không bắt buộc; hai ca "7 ngày" giữ cách của Dart: `isExpired({now})` + `seed` token cũ, không cần giả đồng hồ). Hết giờ: `withTimeout` = `Promise.race` + `AbortController` (mock chậm không đọc signal vẫn bị cắt); hai ca timeout đặt `sanitizeOps/Resources: false` vì mock còn timer 20 ms.
- Ca test: cộng dồn `deno test misa/` = 72 xanh sau Task 3.

**Task 4 — ✅**
- Tệp: `misa/fake_me_invoice_client.ts`, `misa/mod.ts` (barrel đúng danh sách `e_invoice.dart` + `FetchLike`, `MeInvoiceAuth*`), test `fake_me_invoice_client_test.ts` (8).
- Lệch plan: `FakeMeInvoiceClient` thêm `obtainAccessTokenCount`, `lastListInvoiceWithCode` (không ảnh hưởng hành vi Dart).
- Ca test: `deno test misa/` = 80 xanh (62 ca nguồn Dart; 80 lúc chạy do vòng nhiều bộ dữ liệu — Q10).

**Task 5 — ✅**
- Tệp: `queue/{types,errors,attempt_policy,processor,supabase_queue_rpc}.ts`, test `queue/processor_test.ts`.
- Lệch plan: thêm hằng `UNKNOWN_TYPE_DELAY_SECONDS = 300`. `SupabaseQueueRpc` không test đơn vị (như plan); tên tham số đối chiếu migration: `complete`/`fail` (`…002:485-538`), `retry_or_dead_letter` (`…007:753`), `reschedule` (`…019:200`), `claim`/`seed` (`…009`).
- Ca test: 14/14 (đủ 14 ca liệt kê ở 5.1).

**Task 6 — ✅**
- Tệp: `handlers/{template_ref,endpoint_capabilities,misa_env,misa_client_factory,sync_capabilities,registry}.ts`, test `template_ref_test.ts` (5), `endpoint_capabilities_test.ts` (5), `misa_client_factory_test.ts` (7), `sync_capabilities_test.ts` (15).
- Lệch plan: `resolveEndpointCapabilities` gọi **trước** đăng nhập (đúng thứ tự Dart `…adapter.dart:48-56`) thay vì bước 5, để cấu hình `http://` không tốn lượt `/auth/token`; kết quả không đổi. `sync_capabilities_test` thêm ca `missing connection_id throws`, `failure logs reason code only…`, `fake client scenario failed…`. Ca `th08_hardening_capability_01` chạy bằng `MeInvoiceClient` thật + `mockFetch`; các ca còn lại dùng `ScriptedClient extends FakeMeInvoiceClient`.
- Ca test: 32/32.

**Task 7 — ✅**
- Tệp: `auth.ts`, `index.ts`, `auth_test.ts` (8).
- Lệnh: `deno test supabase/functions/einvoice-processor` → **134 passed / 0 failed**; `deno check …/index.ts` sạch; `deno lint …` sạch (64 tệp). 7.4: `grep` log chỉ trúng 1 dòng chú thích (`me_invoice_config.ts:4`), không có log bí mật. Thêm: so chuỗi lỗi `meinvoice_*` / `missing_*` / `TokenExpiredCode` giữa `packages/vet45_misa/lib` và `misa/` bằng `grep -rohE … | sort -u` ⇒ **giống hệt** (Review Focus 1).
- Lệch plan: không có.

**Task 8 — ✅ (một phần)**
- TH-08: 6.1 (thêm 3 secret), 6.2 (thêm `list_tenants_with_due_commands`), 7.3 KI-22, 9.1 (hàng "Tìm tổ chức có việc"), 9.2 ("62 test"). PLAN.md: 7-E1 Làm ✅; 7-C thêm xoá `platform.list_tenants_with_pending_messaging`.
- `detect-changes --scope all`: 7 tệp, 13 symbol, 0 luồng, rủi ro thấp (chỉ trúng tiêu đề tài liệu + `AGENTS.md`/`CLAUDE.md` đã sửa từ trước). **`analyze` chưa chạy** (máy không có `timeout`; chỉ mục cũ) ⇒ tệp `.ts`/`.sql` mới chưa vào chỉ mục — người dùng chạy `node .gitnexus/run.cjs analyze` nếu cần. `AGENTS.md`/`CLAUDE.md` không bị phiên này đổi.

**R1 — sửa (2026-11-08)**

*R1-1 — ✅*
- Xác nhận: đúng 7 câu như review nêu. Bảng `internal_commands` (`…002:77-90`, `20260623000001:235-248`) không có `created_at`, không migration nào `alter table` thêm.
- Tệp: `supabase/migrations/20261031009_einvoice_issuance_reconciliation_rpcs.sql` (5 câu: khối ở `:119`, `:265`, `:338`, `:741`, `:885`), `…014_einvoice_delivery_results_and_projection_rpcs.sql:96`, `…015_einvoice_delivery_reconciliation_rpcs.sql:385`. Mỗi câu bỏ cột `created_at` và giá trị `now()` tương ứng (dòng cuối của `values`). Sửa bằng script, và script kiểm đúng mẫu `enqueued_at,` / `created_at` / `now()` / `)` trước khi xoá.
- Kiểm thêm: quét mọi khối `insert into` / `update einvoice.internal_commands` của `2026103*.sql` (30 dòng sau mỗi câu) tìm `created_at|updated_at` ⇒ **rỗng**. Hai câu `insert into internal_commands` không ghi tên schema (`20260623000001:558`, `…002:400`) chỉ ghi `id, tenant_id, command_type, payload, source_event_id` — đúng cột.
- Ca SQL **E40** (`supabase/tests/einvoice_th08.sql`, sau E34): chèn một ca `invoice_reconciliation_cases` `PENDING` đến hạn cho cửa hàng A (dùng `v_conn`), gọi `seed_due_issuance_reconciliation_commands(v_ta, 1000)` ⇒ trả ≥ 1 và có dòng `internal_commands` với `id = _reconciliation_poll_command_id(case, 1)`, `einvoice.poll_issuance_status`, đến hạn. Trước khi sửa, ca này nổ lỗi `column "created_at" … does not exist`. Chưa chạy (người dùng chạy, Q9).
- TH-08 7.3: thêm **KI-23**.
- Impact: các hàm sửa (`open_reconciliation_case`, `record_issuance_undetermined`, `record_reconciliation_pending`, `seed_due_issuance_reconciliation_commands`, khối backfill, 2 hàm xếp đối soát gửi) chỉ đổi danh sách cột; chữ ký không đổi. GitNexus không có symbol SQL (N3).

*R1-2 — ✅*
- Tệp: `supabase/functions/einvoice-processor/auth.ts` (thêm `CORS_HEADERS` giống `invitation-signup`, `preflightResponse(method)` → `204` cho `OPTIONS`, `jsonResponse(body, status)` luôn kèm CORS); `index.ts` (gọi `preflightResponse` trước mọi xử lý; `json()` dùng `jsonResponse`, nên mọi phản hồi 200 / 4xx / 500 đều có CORS). `authorizeRequest` giữ nguyên (405 cho method khác `POST`).
- Ca test (`auth_test.ts`, thêm 3): `OPTIONS preflight returns 204 with CORS headers`, `non-OPTIONS requests are not preflight`, `json responses carry CORS headers`. Đỏ trước khi viết code (thiếu export), xanh sau.
- TH-08 9.1: ghi "Edge Function trả CORS (`OPTIONS` → 204)".
- Lệnh: `deno test supabase/functions/einvoice-processor` → **137 passed / 0 failed**; `deno check …/index.ts` sạch; `deno lint` 64 tệp sạch.

## 10. Review (phiên review ghi)

### R2 — 2026-11-08 — ✅ ĐẠT

**Kết luận: ĐẠT.** R1-1 và R1-2 đã sửa đúng phương án (A). Không có lỗi mới. Plan đóng phần code; còn việc của người dùng: `db reset` local + `einvoice_th08.sql` (E32–E34, E40), reset Dev, commit sau `detect_changes()`.

| Loại | Mục |
|---|---|
| Bắt buộc sửa | — |
| Tuỳ chọn sửa | — |
| Chỉ ghi nhận | N5 ca E40 không lọc theo loại ca · N6 preflight phụ thuộc gateway khi `verify_jwt` bật · N1–N4 của R1 giữ nguyên |
| Còn lại để đóng plan | Người dùng: `db reset` + `psql … -f supabase/tests/einvoice_th08.sql` → `einvoice_th08: OK`; reset Dev; commit |

**Góp ý chi tiết:**

- [Không sửa — chỉ ghi nhận] **N5**: E40 gọi `seed_due_issuance_reconciliation_commands(v_ta, 1000)` rồi kiểm `v_n >= 1`. Nếu các ca trước đã để lại ca `PENDING` khác của cửa hàng A thì `v_n` lớn hơn 1, nhưng phép kiểm thứ hai theo `id = _reconciliation_poll_command_id(v_case, 1)` vẫn chính xác. Riêng hàm `seed` không lọc `target_type`, nên ca `INVOICE_DELIVERY` cũng sẽ sinh việc `poll_issuance_status`. Đây là hành vi có sẵn từ trước, không thuộc 7-E1. Ghi cho 7-E2a / 7-E2c xem lại.
- [Không sửa — chỉ ghi nhận] **N6**: `OPTIONS` được trả trước `try` / `authorizeRequest`, đúng mẫu `invitation-signup`. Khi `verify_jwt` bật (mặc định), preflight không mang JWT. Gateway của Supabase cho `OPTIONS` đi qua (theo hướng dẫn CORS của Supabase), nhưng chưa kiểm thật. Ghi cho 7-A1: thử `functions.invoke` trên Chrome.

**Đã chạy / đối chiếu (2026-11-08):**

- `deno test supabase/functions/einvoice-processor`: **137 đạt / 0 lỗi** (thêm 3 ca CORS). `deno check …/index.ts`: sạch. `deno lint`: 64 tệp, sạch.
- `git diff` 3 migration: đủ 7 chỗ (`…009` ×5, `…014`, `…015`). Mỗi chỗ bỏ cột `created_at` cùng giá trị `now()` cuối `values`, cột và giá trị vẫn khớp nhau.
- Quét danh sách cột của **mọi** `insert into … internal_commands` trong `supabase/migrations/*.sql` (11 câu): tất cả chỉ dùng `id, tenant_id, command_type, payload, source_event_id[, enqueued_at]`, đều có trong bảng. Quét `created_at|updated_at` trong các khối `insert` / `update internal_commands` của `2026103*.sql`: rỗng.
- E40: `invoice_reconciliation_cases` đủ cột `not null` (`target_type` hợp lệ `ISSUANCE_ATTEMPT`, `status` `PENDING`, `correlation_id`). Khoá ngoại `(tenant_id, provider_connection_id)` thoả vì `v_conn` thuộc `v_ta` (`einvoice_th08.sql:406`). `v_case` đã khai báo; ca chạy dưới `reset role`.
- `auth.ts` `CORS_HEADERS` trùng `invitation-signup/index.ts:17-21`. `index.ts:51-52` trả preflight; mọi `json()` đi qua `jsonResponse` nên kèm CORS (cả 4xx / 500).
- TH-08: 7.3 có KI-23; 9.1 có dòng CORS.

### R1 — 2026-11-08 — ❌ CHƯA ĐẠT

**Kết luận: CHƯA ĐẠT.** Code TypeScript làm đúng plan: client MISA chép sát Dart (chuỗi lỗi giống hệt), vòng hàng đợi giống `ProcessInternalCommandsCommandHandler` và có thêm giới hạn đúng G3, handler `sync_capabilities` giống adapter + handler Dart, tên RPC / tham số khớp migration, test xanh. Chưa đạt vì 2 lý do:

1. Kết quả Task 1.4 ghi "Không còn chỗ nào ghi cột không có". Điều này sai: **7 câu `insert into einvoice.internal_commands` ghi cột `created_at`**, mà bảng không có cột này. Cùng loại lỗi với KI-22, và nằm ngay trên đường của bộ xử lý (R1-1).
2. Function không trả lời CORS / `OPTIONS`, nên app web (thiết bị chính) không gọi được ở 7-A1 (R1-2). Đây là chỗ plan bỏ sót, không phải phiên code làm lệch.

| Loại | Mục |
|---|---|
| Bắt buộc sửa | R1-1 (P1) 7 câu `insert` ghi `created_at` không có · R1-2 (P2) thiếu CORS / `OPTIONS` — **cả hai cần người dùng chốt làm ở 7-E1 hay dời** |
| Tuỳ chọn sửa | T1 tiêu đề plan còn "Làm ⬜" |
| Chỉ ghi nhận | N1 ngân sách thời gian (Review Focus 5) · N2 `fromVendorPayload` in danh sách khác Dart · N3 `analyze` của GitNexus hỏng, không phải "thiếu `timeout`" · N4 Review Focus 3, 4 đạt |
| Còn lại để đóng plan | Người dùng chốt R1-1 / R1-2 → làm → review R2; `db reset` + `einvoice_th08.sql` (người dùng) |

**Góp ý chi tiết:**

- [Bắt buộc sửa] **R1-1**, **R1-2**: xem mục "R1 — việc cần sửa".
- [Tuỳ chọn sửa] **T1**: dòng 5 vẫn ghi `Làm ⬜` (PLAN.md đã ghi ✅). Review này đã sửa thành `Làm ✅ | Review ❌ R1`.
- [Không sửa — chỉ ghi nhận] **N1** (Review Focus 5): ngân sách 90 giây chỉ được kiểm giữa các việc. Riêng `sync_capabilities` đã gọi MISA 3 lần liên tiếp (token, mẫu có mã, mẫu không mã), mỗi lần chờ tối đa 60 giây. Trường hợp xấu nhất (mỗi lần chậm gần 60 giây nhưng không quá giờ) là ~180 giây, vượt 150 giây dù ngân sách đặt bao nhiêu. Khi function bị cắt, việc vẫn đang bị khoá và được lấy lại sau 10 phút mà không tăng `retry_count`. Với `sync_capabilities` thì vô hại: không có tác dụng phụ, và `record_connection_verified` idempotent. **Chấp nhận cho 7-E1.** Ghi cho 7-E2a / 7-E3: nếu checklist sandbox thấy bị cắt, hạ `requestTimeoutMs` trong `TenantMisaClientFactory` (ví dụ 25 giây) — người dùng chốt lúc đó.
- [Không sửa — chỉ ghi nhận] **N2**: `misa/internal/error_mapper.ts` `fromVendorPayload`. Khi `Errors` là danh sách, Dart in `[a, b]`, còn `String([...])` của JS in `a,b`. Bộ phân loại của 7-E2 so bằng `contains` / tiền tố mã nên không ảnh hưởng. Nếu 7-E2a có ca so nguyên chuỗi thì cần biết điểm khác này.
- [Không sửa — chỉ ghi nhận] **N3**: Task 8.3 ghi "`analyze` chưa chạy (máy không có `timeout`)". Review chạy thử `node .gitnexus/run.cjs analyze`: lệnh **lỗi** ở `lbug-adapter.js` `copyCsvWithRetry`, nghĩa là công cụ hỏng chứ không phải thiếu `timeout`. `AGENTS.md` / `CLAUDE.md` không bị đổi (đã so với bản sao trước khi chạy). `detect-changes --scope all` khớp số liệu Kết quả: chỉ trúng tiêu đề tài liệu; `.ts` mới chưa được track nên không vào.
- [Không sửa — chỉ ghi nhận] **N4**:
  - Review Focus 3: mọi nhánh thoát vòng đều `reschedule(…, 1)` cho việc đã claim. Lỗi RPC giữa lô để khoá tự hết sau 10 phút. Chạy lại `sync_capabilities` không gây hại.
  - Review Focus 4: lỗi ghi vào DB / log của `sync_capabilities` chỉ là `provider_unavailable`, `missing_connection_id`, câu HTTPS, hoặc `<rpc>: <message>`. Log thất bại chỉ có `stage` + `safeFailureReason`. `meinvoice_network: ${e}` không chứa token, vì token nằm ở header.

**Đã chạy / đối chiếu (2026-11-08):**

- `deno test supabase/functions/einvoice-processor`: **134 đạt / 0 lỗi** (misa 80 lúc chạy = 62 ca nguồn; queue 14; handlers 32; auth 8). `deno check …/index.ts`: sạch. `deno lint`: 64 tệp, sạch.
- Chuỗi chữ thường trong `packages/vet45_misa/lib` so với `misa/` (bỏ test): chỉ khác ở khoá object không có nháy (`appid`, `taxcode`, `username`, `password`, `invoiceWithCode`, `ticket`, `'https:'`) và tên enum / kịch bản TS. Không có chuỗi lỗi nào lệch.
- So từng dòng: `me_invoice_http`, `error_mapper`, `TenantMisaClientFactory` (TS không so `accessToken*` vì factory không bao giờ truyền 2 trường này — tương đương), `authenticateAndListTemplates` + handler Dart, `ProcessInternalCommandsCommandHandler`, `SyncProviderCapabilitiesCommand.fromJson` (`expected_connection_version ?? -1`).
- `SupabaseQueueRpc` / `index.ts` so với migration: `complete` / `fail` (`…002:485-538`), `retry_or_dead_letter` (`…007:753`), `reschedule` (`…019:200`), `seed` / `claim` (`…009:715/780`), `record_connection_verified` (`…003:86-94`, 7 tham số), `read_provider_credentials` (`…003:366`). Schema `einvoice` có trong `config.toml:13` `schemas`.
- SQL: `where` của `list_tenants_with_due_commands` trùng `claim_internal_commands_batch` (`…009:803-809`) (Review Focus 2). E32–E34: `now()` cố định trong khối `DO`, nên mốc `119…121 s` và `11 minutes` đúng; tenant B không có việc từ ca trước.

### R1 — việc cần sửa

**Người dùng chốt 2026-11-08: cả R1-1 và R1-2 làm ở 7-E1, theo phương án (A).** Thứ tự: R1-1 → R1-2 → review R2. Không còn việc chờ người dùng. Phiên code ghi vào khối "R1 — sửa" ở cuối mục 9 (không làm gì với DB, không commit — như ràng buộc đầu plan).

#### R1-1 — 7 câu `insert into einvoice.internal_commands` ghi cột `created_at` không có

- **Mức:** P1. Cùng loại với KI-22, ngay trên đường của bộ xử lý.
- **Hiện tại:** bảng (`20261031002:77-90`, `20260623000001:235-248`) không có `created_at`, và không migration nào thêm cột này. Các câu ghi `created_at`:
  - `20261031009_einvoice_issuance_reconciliation_rpcs.sql:126`, `:272`, `:345` (mở / xếp việc đối soát phát hành), `:748` (`seed_due_issuance_reconciliation_commands`), `:892` (khối backfill lúc chạy migration — chỉ nổ khi đã có ca `PENDING`);
  - `20261031014_einvoice_delivery_results_and_projection_rpcs.sql:103`;
  - `20261031015_einvoice_delivery_reconciliation_rpcs.sql:392`.
- **Hệ quả:** plpgsql chỉ kiểm cột lúc chạy, nên `db reset` vẫn qua. Nhưng hễ phát hành rơi vào "chưa xác định" (mở ca đối soát) hoặc có ca gửi cần đối soát là gặp lỗi `column "created_at" of relation "internal_commands" does not exist`. Thêm nữa, `runInvocation` gọi `seed` **trước** mọi việc của cửa hàng. Một ca `PENDING` đến hạn sẽ làm `seed` ném lỗi, cửa hàng đó rơi vào `tenant_error` mãi mãi, kể cả `sync_capabilities` cũng không chạy. Task 1.4 của plan chỉ grep `updated_at` / `update`, nên sót các câu `insert`.
- **Đề xuất (cần người dùng chốt):** (A) sửa ở 7-E1 — xoá `created_at` (cột + giá trị `now()` tương ứng) ở 7 chỗ, sửa thẳng migration gốc; TH-08 7.3 thêm **KI-23**; thêm ca SQL **E40** (7-E2a đã giữ E35–E39): gọi `seed_due_issuance_reconciliation_commands` có một ca `PENDING` đến hạn, hoặc gọi hàm mở ca đối soát mà ca SQL hiện có dựng được; nếu ràng buộc khoá ngoại quá nặng thì ghi Kết quả và kiểm bằng `grep`. (B) Dời sang 7-E2a (luồng đối soát phát hành) + 7-E2c (đối soát gửi).
- **Kiểm thêm:** `grep -n "created_at\|updated_at" ` trên mọi khối `insert into einvoice.internal_commands` / `update einvoice.internal_commands` của `supabase/migrations/2026103*.sql`, ghi Kết quả là rỗng.
- **Xong khi:** không còn câu nào ghi cột không có; KI-23 ghi trong TH-08; có ca SQL hoặc giải thích.

#### R1-2 — Function không trả lời CORS / `OPTIONS`

- **Mức:** P2. Plan bỏ sót (G5 ghi "method khác `POST` → 405").
- **Hiện tại:** `auth.ts` trả `405` cho `OPTIONS`; `index.ts` không gửi header `Access-Control-*`. Q2 cho phép người đăng nhập gọi kèm `tenant_id` chính là để app gọi `functions.invoke` (7-A1). Trên web, trình duyệt gửi preflight `OPTIONS` trước nên bị chặn, trong khi web là thiết bị chính. Mẫu sẵn có: `supabase/functions/invitation-signup/index.ts:17-26, 126`.
- **Đề xuất (cần người dùng chốt):** (A) sửa ở 7-E1 — `OPTIONS` → `204` + `CORS_HEADERS` (như `invitation-signup`, `Allow-Methods: POST, OPTIONS`), mọi phản hồi `json()` kèm `CORS_HEADERS`; `authorizeRequest` giữ 405 cho method khác; thêm ca `auth_test` / test thuần cho nhánh `OPTIONS`; TH-08 9.1 ghi "Edge Function trả CORS cho app web". (B) Dời sang 7-A1 (ghi vào dòng 7-A1 của PLAN.md).
- **Xong khi:** `OPTIONS` trả `204` có header CORS; `deno test` / `check` / `lint` xanh.
