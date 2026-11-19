# 7-E3 — HĐĐT: kích hoạt phía server — trigger xếp việc tự động, `pg_cron` gọi `einvoice-processor`, checklist MISA

> Theme 8 (mã cũ P7) · Phần server, plan cuối của chuỗi 7-B1 → 7-E1 → 7-E2a → 7-E2b → 7-E2c → **7-E3**.
> Gồm: việc 7.5 phần server — 3 trigger thêm việc vào hàng đợi HĐĐT (đơn Hoàn tất, hồ sơ khách đổi, hoá đơn được ghi), 3 handler mới trong Edge Function, lịch `pg_cron` 30 giây; viết lại 2 checklist MISA + runbook (KI-19, KI-20, KI-26 mới).
> Trạng thái: Plan ✅ (viết 2026-11-08, duyệt 2026-11-08) | Làm ✅ (2026-11-08) | Review ✅ R2 ĐẠT (2026-11-08)
> **Trước: 7-E2c Làm ✅ + Review R2 ✅** (2026-11-08; `deno test supabase/functions/einvoice-processor` đo lúc viết plan: **381 ca xanh**). Plan này sửa migration gốc `20261031008`, `20261031013`, thêm migration `20261108001`, sửa `supabase/tests/einvoice_th08.sql`, `supabase/migrations/REGISTRY.yaml`, `handlers/registry.ts`, `index.ts`; dùng `CommandHandler`, `CommandContext` (`queue/types.ts`), `FakeQueueRpc`, `cmd()` (`queue/test_support.ts`), `runInvocation` (`queue/processor.ts`), `einvoice.enqueue_internal_command(p_tenant_id, p_command_type, p_payload, p_source_event_id, p_command_id)` (`20261031002:387-410`, `on conflict do nothing`). Sau: 7-A1.
> Tài liệu: [TH-08](../../../02-yeu-cau/TH-08-hoa-don-dien-tu.md) BR-32, BR-34, BR-46, US-02.3 (FR-01, FR-03), US-02.4 FR-05, US-04.x "Gửi tự động" FR-01, 6.1, 9.2 PR 7.5, KI-19, KI-20. Nguồn chép (`modules/einvoice/application/lib/src/`):
> - khoá: `issuance/shared/auto_issuance_idempotency_key.dart`, `delivery/shared/auto_delivery_idempotency_key.dart`
> - lệnh + validator: `issuance/commands/{start_auto_issuance,reevaluate_auto_issuance}/`, `delivery/commands/start_auto_delivery/`
> - bộ xử lý sự kiện (thay bằng trigger + handler): `issuance/integration_events/{sales_order_finalized,partner_profile_updated}_integration_event_handler.dart`, `delivery/integration_events/electronic_invoice_registered_integration_event_handler.dart`
> - gateway: `infrastructure/lib/src/domain/issuance/supabase_auto_issuance_gateway.dart`, `infrastructure/lib/src/domain/delivery/supabase_delivery_command_gateway.dart:20-37`, `delivery_rpc_mapper.dart:170-188`
>
> **Cho phiên code:** dùng `superpowers:executing-plans` (tuần tự). Mỗi task xong ghi ngay mục 9 theo mẫu (tệp:dòng, lệch plan, ca test, impact). **Không commit** (người dùng commit sau `detect_changes()`). **Không làm gì với DB** (không chạy SQL, không reset, không push, không deploy function, không ghi Vault). **Không đụng `modules/`, `packages/`, `apps/`** (chỉ đọc để chép). **Không ghi mục 10.**

**Goal:** Phát hành và gửi hoá đơn tự động chạy lại khi không ai mở app: đơn Hoàn tất, hồ sơ khách đổi, hoá đơn được ghi đều thêm việc vào hàng đợi HĐĐT; `pg_cron` gọi `einvoice-processor` mỗi 30 giây khi có việc đến hạn; Edge Function làm 3 loại việc mới bằng đúng RPC và khoá chống trùng như worker Dart cũ.

**Architecture:** DB: hàm `einvoice._stable_command_id` + 3 trigger `security definer` gọi `enqueue_internal_command` với mã việc cố định (lặp ⇒ `on conflict do nothing`); hàm `einvoice._invoke_processor()` + lịch `einvoice-processor-tick`. Edge Function: thư mục mới `handlers/automation/` (khoá UUIDv5, đọc payload, gateway hẹp + bản Supabase, 3 handler) theo khuôn `handlers/delivery/` của 7-E2c; handler chỉ phụ thuộc interface, test bằng bản giả.

**Tech Stack:** PostgreSQL 17 (`pg_cron` 1.6 — lịch `'30 seconds'`, `pg_net`, Vault), Deno 2, TypeScript, `npm:@supabase/supabase-js@2`, `jsr:@std/assert@1`, Web Crypto (`crypto.subtle.digest('SHA-1')`).

## 1. Mục tiêu

- `deno test supabase/functions/einvoice-processor` xanh: 381 ca hiện có + 33 ca chép từ Dart + 8 ca mới (Task 2: 4, Task 3: 4) ⇒ tổng **422**. `deno check supabase/functions/einvoice-processor/index.ts`, `deno lint supabase/functions/einvoice-processor` không lỗi.
- `supabase/tests/einvoice_th08.sql` có ca E47–E52 (người dùng chạy sau `db reset`).
- Đơn chèn vào `sales.sales_orders` với `lifecycle_status = 'completed'` ⇒ đúng 1 việc `einvoice.start_auto_issuance` (kể cả tổ chức tắt tự động — `start_auto_issuance` ghi `SKIPPED`, AC-03). Handler gọi `start_auto_issuance(p_tenant_id, p_sales_order_id, p_trigger_key, p_idempotency_key)`.
- `partner.partners.version` đổi ⇒ mỗi dòng `auto_issuance_processes` `PENDING_REEVALUATION` của đúng khách đó có 1 việc `einvoice.reevaluate_auto_issuance`; khách không có dòng chờ ⇒ không thêm việc. Handler gọi `reevaluate_auto_issuance(p_tenant_id, p_process_id, p_source_event_id)`.
- Chèn `einvoice.electronic_invoices` (cả `record_issuance_success` lẫn `recover_internal_finalization`) ⇒ 1 việc `einvoice.start_auto_delivery`. Handler gọi `start_auto_delivery(p_tenant_id, p_electronic_invoice_id, p_trigger_id, p_idempotency_key)`.
- Kết quả bỏ qua (`SKIPPED`, `PENDING_REEVALUATION`, `disposition = 'skipped'`) là **thành công** — việc `complete`, không thử lại.
- Có việc đến hạn + Vault đủ `project_url`, `service_role_key` ⇒ mỗi 30 giây một `net.http_post` tới `/functions/v1/einvoice-processor`, body `{}`, `Authorization: Bearer <service_role_key>`. Thiếu Vault hoặc không có việc ⇒ không gọi, không lỗi.
- 2 checklist + `docs/refactor/RUNBOOK-einvoice.md` viết lại cho Edge Function; PLAN, TH-08 sửa theo các quyết định dưới.

**Không làm:** bỏ `enqueue_outbox_message('einvoice.electronic_invoice.registered', …)` và outbox `sales_order_finalized.v1` (7-C dọn); app gọi `functions.invoke` (7-A1); chạy checklist (người dùng; phần UI sau 7-A2); đánh giá lại khi kết nối / mẫu sẵn sàng (BR-34 chỉ nói hồ sơ khách); dead-letter riêng cho 3 loại việc mới; seed việc cho đơn / hoá đơn có từ trước (Dev được reset).

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | Tín hiệu tự động đi đường nào | **Người dùng chốt 2026-11-08 (A):** trigger chỉ thêm việc vào hàng đợi HĐĐT (`einvoice.internal_commands`); Edge Function có 3 handler mới gọi RPC. Không gọi thẳng `start_auto_issuance` trong giao dịch bán hàng |
| Q2 | `pg_cron` xác thực với Edge Function | **Người dùng chốt (A):** Vault `service_role_key` (+ `project_url` đã có từ `20261009004`), header `Authorization: Bearer`. Không sửa `auth.ts` / `config.toml` (`verify_jwt` giữ mặc định) |
| Q3 | 2 checklist MISA | **Người dùng chốt (A):** 7-E3 viết lại cả hai cho kiến trúc mới; S1 thêm mục "Kiểm phía server bằng SQL Editor" — người dùng chạy sau khi đưa lên Dev; phần bấm UI của `DEV-LIVE-ACCEPTANCE-CHECKLIST` chạy sau 7-A2 (ghi vào dòng 7-B2) |
| Q4 | Gửi tự động xếp ở đâu (hoá đơn được ghi ở 2 hàm: `record_issuance_success` `…007:341`, `recover_internal_finalization` `…009:642`) | **Người dùng chốt (A):** trigger `after insert on einvoice.electronic_invoices`. Lệch chữ PLAN / TH-08 ("`record_issuance_success` tự xếp") ⇒ sửa PLAN, TH-08, ghi **KI-26** |
| Q5 | Trigger hồ sơ khách | **Người dùng chốt (A):** `after update of version on partner.partners` (mọi RPC sửa đối tác tăng `version`, `20260714004`); trigger tìm dòng `PENDING_REEVALUATION` theo `buyer_partner_id` và thêm 1 việc / dòng. Không thêm việc khi không có dòng chờ |
| Q6 | Chỗ đặt trigger (lúc trao đổi nói `…018` / `…023`) | Gom 2 trigger tự động phát hành + hàm `_stable_command_id` vào **`20261031008`** (nơi tạo `auto_issuance_processes`, `start_auto_issuance`, `reevaluate_auto_issuance`); trigger gửi tự động vào **`20261031013`** (nơi tạo `start_auto_delivery`; chạy sau `008` nên dùng được `_stable_command_id`). Lịch cron ở migration **mới** `20261108001_einvoice_processor_cron.sql` (không thuộc migration nào) |
| Q7 | Khoá chống trùng | Như Dart, tính trong TypeScript: `triggerKey = 'sales_order_finalized.v1:' + <mã việc> + ':' + <đơn> + ':' + <version>` (mã việc thay mã sự kiện cũ); `idempotencyKey = UUIDv5('6ba7b811-9dad-11d1-80b4-00c04fd430c8', 'einvoice:auto_issue:<tổ chức>:<đơn>:<version>')`; gửi: `UUIDv5('9d4c1d80-8d2c-5f2a-8b86-ff34c8a8e275', '<tổ chức>\|<hoá đơn>\|auto_initial')`, `trigger_id = <mã việc>`. Giá trị mẫu (đo bằng Python `uuid.uuid5`, cùng RFC 4122 với gói `uuid` Dart): `('tenant-1','order-456','sales-v17')` ⇒ `c1ccac1b-df81-519e-a2f5-e4333a17c8d2`; `('tenant-1','ei-1')` ⇒ `214c3038-4c3f-51e0-a7c2-b675ea0fe14b` |
| Q8 | Mã việc cố định | `einvoice._stable_command_id(p_raw text) returns uuid` — hex SHA-256 của `p_raw`, ghép `8-4-4-4-12` từ 32 ký tự đầu (như `_delivery_send_command_id`, `…013:66-87`). Chuỗi: phát hành `<đơn>\|start_auto_issuance\|<version>`; đánh giá lại `<process>\|reevaluate_auto_issuance\|<partner version>`; gửi `<hoá đơn>\|start_auto_delivery`. Mẫu: `'o1\|start_auto_issuance\|1'` ⇒ `cea12d30-5532-ca74-2bb8-b1863e8457ca` (`shasum -a 256`) |
| Q9 | Trigger lỗi | **Không** bọc `exception`: thêm việc lỗi ⇒ giao dịch bán / sửa khách / ghi hoá đơn lỗi theo (không âm thầm mất tín hiệu). Ghi hoá đơn trong `record_issuance_success` nằm trong khối `begin … exception` (`…007:340-378`) ⇒ trigger lỗi ⇒ lượt thành `UNRESOLVED` + `recover_internal_finalization` sau — chấp nhận |
| Q10 | Số lượt thử / dead-letter 3 loại việc mới | Không thêm vào `attempt_policy.ts` ⇒ `retry_or_dead_letter_internal_command` (3 lượt, `…007:787`). Không dead-letter (worker cũ: inbox chỉ đánh dấu hỏng). Lỗi nghiệp vụ RPC (`NOT_FOUND`, `DELIVERY_NOT_SUPPORTED`, `OPERATION_IN_PROGRESS`, `IDEMPOTENCY_CONFLICT`) ⇒ ném ⇒ thử lại như Dart |
| Q11 | Validator Dart | Chép vào cùng tệp core, ném trước khi gọi gateway, giữ chuỗi: `tenantId is required`, `salesOrderId is required`, `triggerKey is required`, `processId is required`, `sourceEventId is required`, `electronicInvoiceId is required`, `triggerId is required`, `idempotencyKey must be a canonical UUID` (regex RFC 4122 `^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$`, không phân biệt hoa thường) |
| Q12 | Payload / tenant | Trigger ghi snake_case. Thiếu / không phải chuỗi / `trim` rỗng ⇒ `Invalid or missing automation payload: <key>`. `tenant_id` vắng ⇒ dùng tenant đang chạy; khác ⇒ `Automation tenant does not match claimed tenant` (như 7-E2c Q7) |
| Q13 | Gọi cron khi không có việc | `_invoke_processor` chỉ gọi khi có dòng đến hạn (cùng điều kiện `list_tenants_with_due_commands`, `…009:836-852`); `timeout_milliseconds := 150000` (≥ giới hạn 150 giây của Edge Function, để `pg_net` không ngắt giữa chừng) |

## 3. Hiện trạng (đo 2026-11-08)

| Thứ | Ở đâu | Ghi chú |
|---|---|---|
| Tạo đơn | `sales.finalize_sales_order` (bản cuối `20261031017:499`) — chỗ **duy nhất** `insert into sales.sales_orders` | `lifecycle_status` chỉ `completed` / `cancelled` (`20260830005:132`); đơn chèn thẳng `completed`, `version` bigint mặc định 1; `source_version` của nguồn = `version::text` (`…018:91`) |
| Sửa đối tác | `20260714004` — `update_partner:697-700`, liên hệ `:848`, `:984-995`, `:1049`, chuyển tổ chức `:1209`, ngừng / mở / xoá `:1297`, `:1371`, `:1472` | đều `version = p.version + 1`; `partner.partners(partner_id, tenant_id, version integer)` |
| Dòng chờ đánh giá lại | `einvoice.auto_issuance_processes(id, tenant_id, sales_order_id, buyer_partner_id, status …)` `…008:10-30` | index `(tenant_id, buyer_partner_id) where status = 'PENDING_REEVALUATION'` |
| Ghi hoá đơn | `insert into einvoice.electronic_invoices` `…007:341` (`record_issuance_success`), `…009:642` (`recover_internal_finalization`) | cả hai phát outbox `einvoice.electronic_invoice.registered` (`…007:369`, `…009:686`) — không ai đọc |
| 3 RPC (chỉ `service_role`) | `start_auto_issuance` `…008:428` và `reevaluate_auto_issuance` `…008:922` ⇒ `(started bool, skipped bool, process_id uuid, attempt_id uuid, status text, reason text)`; `start_auto_delivery` `…013:285` ⇒ `(disposition text 'started' \| 'skipped', delivery_id uuid, skip_reason text 'POLICY_OFF' \| 'INVALID_OR_MISSING_EMAIL' \| 'INITIAL_DELIVERY_ALREADY_CLAIMED')`, kiểm `request.jwt.claims.role = 'service_role'` | `p_trigger_id`, `p_idempotency_key` của gửi là `uuid` |
| Mẫu `pg_net` + `pg_cron` | `20261009004_iam_email_dispatch.sql` | Vault `project_url`; gỡ lịch cũ theo `jobname` rồi `cron.schedule`; `revoke all … from public, anon, authenticated` |
| Postgres local | `supabase/config.toml:36` `major_version = 17`; `.temp/postgres-version` `17.11.0.002` | `pg_cron` 1.6 ⇒ cú pháp `'30 seconds'` |
| `HandlerDeps` / đăng ký | `handlers/registry.ts:24-31`, `:33-57`; `index.ts:82-109` | 2 ca đăng ký dead-letter ép `as unknown as HandlerDeps` ⇒ thêm khoá `automation` không làm hỏng |
| Ca SQL | `supabase/tests/einvoice_th08.sql` — ca cuối E46 (`:1079-1100`); đơn chỉ tạo ở tenant A (`v_ta`); E32 / E33 kiểm tenant B (`v_tb`) không có việc | trigger đơn không chạm tenant B ⇒ E32 / E33 không đổi |
| `REGISTRY.yaml` | `supabase/migrations/REGISTRY.yaml:133-…` (mục `einvoice`, xếp chữ cái) | thêm hàm mới |
| KI mới nhất ở TH-08 | `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md:1517` (KI-25) | KI mới = **KI-26** |

Không có bảng "Đang làm gì": plan không xoá / tách code cũ (worker đã xoá, module xoá ở 7-C); test parity là các ca chép từ Dart.

## 4. Thiết kế

### G1. SQL — `20261031008` (sửa tại chỗ, cuối tệp)

- `einvoice._stable_command_id(p_raw text) returns uuid` — `language sql immutable`, Q8.
- `einvoice._enqueue_auto_issuance() returns trigger` — `security definer`, `set search_path = einvoice, pg_temp`: `perform einvoice.enqueue_internal_command(new.tenant_id, 'einvoice.start_auto_issuance', jsonb_build_object('tenant_id', new.tenant_id, 'sales_order_id', new.id, 'source_version', new.version::text), null, einvoice._stable_command_id(new.id::text || '|start_auto_issuance|' || new.version::text)); return new;`
  - `drop trigger if exists sales_orders_einvoice_auto_issuance on sales.sales_orders; create trigger sales_orders_einvoice_auto_issuance after insert on sales.sales_orders for each row when (new.lifecycle_status = 'completed') execute function einvoice._enqueue_auto_issuance();`
- `einvoice._enqueue_auto_issuance_reevaluation() returns trigger` — như trên; lặp `select id from einvoice.auto_issuance_processes where tenant_id = new.tenant_id and buyer_partner_id = new.partner_id and status = 'PENDING_REEVALUATION'`, mỗi dòng `enqueue_internal_command(new.tenant_id, 'einvoice.reevaluate_auto_issuance', jsonb_build_object('tenant_id', new.tenant_id, 'process_id', <id>, 'source_event_id', 'partner:' || new.partner_id || ':' || new.version), null, _stable_command_id(<id> || '|reevaluate_auto_issuance|' || new.version))`.
  - trigger `partners_einvoice_auto_issuance_reevaluation after update of version on partner.partners for each row when (new.version is distinct from old.version)`.
- `revoke all on function` 3 hàm `from public, anon, authenticated`. Header `-- Touches:` thêm 3 tên + 2 trigger.

### G2. SQL — `20261031013` (sửa tại chỗ, cuối tệp)

- `einvoice._enqueue_auto_delivery() returns trigger` — payload `{tenant_id, electronic_invoice_id: new.id}`, mã `_stable_command_id(new.id::text || '|start_auto_delivery')`, loại `einvoice.start_auto_delivery`.
- trigger `electronic_invoices_einvoice_auto_delivery after insert on einvoice.electronic_invoices for each row`. `revoke`; header `Touches` + `Depends on: 008`.

### G3. SQL — migration mới `20261108001_einvoice_processor_cron.sql`

Header theo `_migration.template.sql` (`Kind: patch`, `Context: TH-08 KI-20, 7-E3`, `Depends on: 20261009004_iam_email_dispatch.sql, 20261031009_einvoice_issuance_reconciliation_rpcs.sql`). Nội dung theo khuôn `20261009004`:
- `create extension if not exists pg_net with schema extensions; create extension if not exists pg_cron;`
- `einvoice._invoke_processor() returns void` — `security definer`, `set search_path = einvoice, extensions, pg_temp`: đọc `vault.decrypted_secrets` tên `project_url`, `service_role_key` (thiếu / rỗng sau `trim` ⇒ `return`); `if not exists (select 1 from einvoice.internal_commands m where m.processed_at is null and m.failed_at is null and m.enqueued_at <= now() and (m.claimed_at is null or m.claimed_at < now() - interval '10 minutes')) then return; end if;` rồi `perform net.http_post(url := rtrim(v_url, '/') || '/functions/v1/einvoice-processor', body := '{}'::jsonb, headers := jsonb_build_object('Content-Type', 'application/json', 'Authorization', 'Bearer ' || v_key), timeout_milliseconds := 150000);`. Chú thích đầu hàm: tên 2 secret, thiếu thì bỏ qua.
- `revoke all on function einvoice._invoke_processor() from public, anon, authenticated;`
- khối `do` gỡ mọi `cron.job` có `jobname = 'einvoice-processor-tick'` (`pg_cron` chưa có ⇒ `raise exception 'pg_cron is not available'`), rồi `select cron.schedule('einvoice-processor-tick', '30 seconds', $$select einvoice._invoke_processor()$$);`

### G4. Edge Function — `handlers/automation/`

```ts
// idempotency_keys.ts
export const SALES_ORDER_FINALIZED_EVENT_TYPE = 'sales_order_finalized.v1'
export const AUTO_ISSUANCE_NAMESPACE = '6ba7b811-9dad-11d1-80b4-00c04fd430c8'
export const AUTO_DELIVERY_NAMESPACE = '9d4c1d80-8d2c-5f2a-8b86-ff34c8a8e275'
export function uuidV5(namespace: string, name: string): Promise<string>   // RFC 4122 §4.3, SHA-1
export function autoIssuanceTriggerKey(i: { eventType: string; eventId: string; salesOrderId: string; sourceVersion: string }): string
export function autoIssuanceIdempotencyKey(i: { tenantId: string; salesOrderId: string; sourceVersion: string }): Promise<string>
export function autoDeliveryIdempotencyKey(i: { tenantId: string; electronicInvoiceId: string }): Promise<string>

// payloads.ts (Q12)
export function parseStartAutoIssuancePayload(p: Record<string, unknown>, claimedTenantId: string): { tenantId: string; salesOrderId: string; sourceVersion: string }
export function parseReevaluateAutoIssuancePayload(p: Record<string, unknown>, claimedTenantId: string): { tenantId: string; processId: string; sourceEventId: string }
export function parseStartAutoDeliveryPayload(p: Record<string, unknown>, claimedTenantId: string): { tenantId: string; electronicInvoiceId: string }

// gateways.ts
export interface AutoIssuanceStartRequest { tenantId: string; salesOrderId: string; triggerKey: string; idempotencyKey: string }
export interface AutoIssuanceReevaluationRequest { tenantId: string; processId: string; sourceEventId: string }
export interface AutoIssuanceResult { started: boolean; skipped: boolean; processId: string; attemptId: string | null; status: string; reason: string | null }
export interface AutoDeliveryStartRequest { tenantId: string; electronicInvoiceId: string; triggerId: string; idempotencyKey: string }
export interface AutoDeliveryResult { disposition: 'started' | 'skipped'; deliveryId: string | null; skipReason: string | null }
export interface AutomationGateway {
  startAutoIssuance(r: AutoIssuanceStartRequest): Promise<AutoIssuanceResult>
  reevaluateAutoIssuance(r: AutoIssuanceReevaluationRequest): Promise<AutoIssuanceResult>
  startAutoDelivery(r: AutoDeliveryStartRequest): Promise<AutoDeliveryResult>
}
export interface AutomationDeps { gateway: AutomationGateway }

// auto_issuance.ts — validator (Q11) + core (chép command handler Dart) + handler
export function startAutoIssuance(g: AutomationGateway, r: AutoIssuanceStartRequest): Promise<AutoIssuanceResult>
export function reevaluateAutoIssuance(g: AutomationGateway, r: AutoIssuanceReevaluationRequest): Promise<AutoIssuanceResult>
export function createStartAutoIssuanceHandler(deps: AutomationDeps): CommandHandler
export function createReevaluateAutoIssuanceHandler(deps: AutomationDeps): CommandHandler
// auto_delivery.ts
export function startAutoDelivery(g: AutomationGateway, r: AutoDeliveryStartRequest): Promise<AutoDeliveryResult>
export function createStartAutoDeliveryHandler(deps: AutomationDeps): CommandHandler
```

- Handler phát hành: `parseStartAutoIssuancePayload(ctx.command.payload, ctx.tenantId)` → `triggerKey = autoIssuanceTriggerKey({ eventType: SALES_ORDER_FINALIZED_EVENT_TYPE, eventId: ctx.command.commandId, … })`, `idempotencyKey = await autoIssuanceIdempotencyKey(…)` → `startAutoIssuance`. Handler đánh giá lại: payload → `reevaluateAutoIssuance`. Handler gửi: payload → `startAutoDelivery({ …, triggerId: ctx.command.commandId, idempotencyKey: await autoDeliveryIdempotencyKey(…) })`. Kết quả nào cũng `return` (Q10 — chỉ ném khi RPC / validator ném).
- `supabase_gateways.ts` — `createSupabaseAutomationGateway(client: SupabaseClient): AutomationGateway`; `client.schema('einvoice').rpc(<tên>, …)` với tham số `p_*` ở mục 3; `error` ⇒ `throw new Error(\`${tên}: ${error.message}\`)`; 0 dòng ⇒ `throw new Error(\`${tên} returned no rows\`)`; `disposition` lạ ⇒ `throw new Error(\`Unknown auto delivery disposition: ${x}\`)`; `skipReason` chỉ đọc khi `skipped`. Không test đơn vị (như 7-E2a…c); review đối chiếu mục 3.
- `fake_gateways.ts` — `FakeAutomationGateway`: kết quả dựng sẵn cho từng hàm (mặc định `started`), `throwOnStartIssuance?: Error`, mảng `startIssuanceCalls`, `reevaluateCalls`, `startDeliveryCalls`.
- `registry.ts`: `HandlerDeps` thêm `automation: AutomationDeps`; `buildHandlers` thêm `'einvoice.start_auto_issuance'`, `'einvoice.reevaluate_auto_issuance'`, `'einvoice.start_auto_delivery'`. `index.ts`: `automation: { gateway: createSupabaseAutomationGateway(client) }`.

## 5. Các bước

**Ràng buộc chung** (mọi task):
- Lệnh test: `deno test supabase/functions/einvoice-processor` (từ gốc repo). Lệnh kiểm: `deno check supabase/functions/einvoice-processor/index.ts`, `deno lint supabase/functions/einvoice-processor`.
- Test chép từ Dart: **giữ tên ca** (`Deno.test('<group> <ca>', …)`), giữ dữ liệu và giá trị so sánh; ca phải đổi ghi Kết quả. Test ở `supabase/functions/einvoice-processor/handlers/automation/*_test.ts`.
- Mỗi task: viết test trước, chạy thấy đỏ, viết mã, chạy thấy xanh.
- SQL: không chạy được (không đụng DB) ⇒ phiên code đọc lại bằng mắt + `grep`; người dùng chạy `einvoice_th08.sql`.

| Dart (`modules/einvoice/application/test/`) | TS test | Ca | Task |
|---|---|---|---|
| `issuance/auto_issuance_idempotency_key_test.dart` | `idempotency_keys_test.ts` | 6 | 2 |
| group `AutoDeliveryIdempotencyKey` của `delivery/start_auto_delivery_command_handler_test.dart:150-175` | `idempotency_keys_test.ts` | 1 | 2 |
| group validator của `issuance/start_auto_issuance_command_handler_test.dart:64-158` ⇒ gọi `startAutoIssuance` với gateway giả, lỗi ⇒ gateway không được gọi | `auto_issuance_test.ts` | 5 | 3 |
| group validator của `issuance/reevaluate_auto_issuance_command_handler_test.dart:43-112` | `auto_issuance_test.ts` | 4 | 3 |
| group handler của `start_auto_issuance_command_handler_test.dart:160-219` (`validKey = 'a6547397-1158-5873-a825-9ee320d9fcc5'`, trigger `sales_order_finalized.v1:event-1:order-1:sales-v17`) | `auto_issuance_test.ts` | 4 | 3 |
| group handler của `reevaluate_auto_issuance_command_handler_test.dart:114-150` | `auto_issuance_test.ts` | 2 | 3 |
| group `SalesOrderFinalizedIntegrationEventHandler` của `issuance/auto_issuance_integration_event_handlers_test.dart:71-106` ⇒ handler với `commandId: 'event-001'`, payload `{ tenant_id: 'tenant-1', sales_order_id: 'order-123', source_version: '1' }` | `auto_issuance_test.ts` | 1 | 3 |
| group validator + handler của `delivery/start_auto_delivery_command_handler_test.dart:7-147` | `auto_delivery_test.ts` | 5 + 3 | 3 |
| `delivery/electronic_invoice_registered_integration_event_handler_test.dart` ⇒ handler với `commandId: 'event-001'` / `'event-a'`, `'event-b'`, payload `{ tenant_id: 'tenant-1', electronic_invoice_id: 'ei-99' }` | `auto_delivery_test.ts` | 2 | 3 |
| | **Tổng chép** | **33** | |

2 ca `PartnerProfileUpdatedIntegrationEventHandler` (`:108-170`) chuyển thành ca SQL E49 (việc tìm dòng chờ nằm trong trigger — Q5).

### Task 1: SQL — hàm mã việc, 3 trigger, lịch cron, ca E47–E52 (G1, G2, G3)

**Files:** Modify: `supabase/migrations/20261031008_einvoice_auto_issuance_and_retry_rpcs.sql` (cuối tệp + header), `supabase/migrations/20261031013_einvoice_delivery_schema_and_start_rpcs.sql` (cuối tệp + header), `supabase/migrations/REGISTRY.yaml` (mục `einvoice`), `supabase/tests/einvoice_th08.sql` (sau E46, trước `raise notice 'einvoice_th08: OK'`; thêm biến vào khối `declare`); Create: `supabase/migrations/20261108001_einvoice_processor_cron.sql`

**Interfaces — Produces:** loại việc `einvoice.start_auto_issuance` (payload `{tenant_id, sales_order_id, source_version}`), `einvoice.reevaluate_auto_issuance` (`{tenant_id, process_id, source_event_id}`), `einvoice.start_auto_delivery` (`{tenant_id, electronic_invoice_id}`) — Task 3 đọc đúng các khoá này.

- [x] **1.1** Viết ca SQL (dùng `public._th08_*` sẵn có; đọc bảng dưới quyền chủ — `reset role`):
  - **E47** `einvoice._stable_command_id('o1|start_auto_issuance|1') = 'cea12d30-5532-ca74-2bb8-b1863e8457ca'::uuid`.
  - **E48** đơn `v_oa` (E10) có đúng 1 dòng `command_type = 'einvoice.start_auto_issuance'` với `id = _stable_command_id(v_oa::text || '|start_auto_issuance|1')`, `payload = jsonb_build_object('tenant_id', v_ta, 'sales_order_id', v_oa, 'source_version', '1')`; gọi lại `einvoice.enqueue_internal_command(v_ta, 'einvoice.start_auto_issuance', '{}'::jsonb, null, <cùng id>)` ⇒ vẫn 1 dòng, payload không đổi.
  - **E49** khách mới `v_ke := _th08_customer(v_ta, v_ua, 'organization', 'Công ty E', null, '5 Lê Lợi')`; đơn `_th08_sale(v_ta, v_ua, v_store, v_p1, v_u1, v_ke, 'organization', 'th08-sale-e')` dưới `authenticated` như E27 (auto đang bật từ `:712`); `reset role` rồi; `start_auto_issuance(v_ta, <đơn>, 't-ke', 'auto-ke')` ⇒ `PENDING_REEVALUATION`, giữ `process_id`. (a) `update partner.partners set version = version + 1 where partner_id = v_ke` ⇒ đúng 1 dòng `einvoice.reevaluate_auto_issuance` có `payload->>'process_id' = <process>` và `payload->>'source_event_id' = 'partner:' || v_ke || ':' || <version mới>`. (b) `update partner.partners set version = version + 1 where partner_id = v_ka` (không có dòng chờ) ⇒ tổng số dòng `einvoice.reevaluate_auto_issuance` không đổi. (c) `update partner.partners set display_name = display_name where partner_id = v_ke` ⇒ không đổi.
  - **E50** hoá đơn `v_inv` (= `_th08_invoice_id(v_ob)`, gán ở E26; tạo qua `_th08_succeed` ở `:642`) có đúng 1 dòng `einvoice.start_auto_delivery`, `id = _stable_command_id(v_inv::text || '|start_auto_delivery')`, `payload->>'electronic_invoice_id' = v_inv::text`.
  - **E51** `cron.job` có 1 dòng `jobname = 'einvoice-processor-tick'`, `schedule = '30 seconds'`, `command` chứa `einvoice._invoke_processor()`. Nếu `not exists (select 1 from vault.secrets where name = 'service_role_key')`: đếm `net.http_request_queue` trước / sau `perform einvoice._invoke_processor()` ⇒ bằng nhau, không lỗi.
  - **E52** dưới `authenticated`: `_th08_expect_err('select einvoice._invoke_processor()', 'permission denied')`, `_th08_expect_err('select einvoice._stable_command_id(''x'')', 'permission denied')`.
- [x] **1.2** Viết G1, G2, G3. `REGISTRY.yaml` mục `einvoice` thêm (đúng thứ tự chữ cái): `_enqueue_auto_delivery: 20261031013_…`, `_enqueue_auto_issuance: 20261031008_…`, `_enqueue_auto_issuance_reevaluation: 20261031008_…`, `_invoke_processor: 20261108001_einvoice_processor_cron.sql`, `_stable_command_id: 20261031008_…`.
- [x] **1.3** Tự kiểm bằng `grep`: (a) không còn `created_at` trong các câu `insert` mới (KI-23); (b) `search_path` mỗi hàm mới có `pg_temp`; (c) tên trigger không trùng: `grep -rn "sales_orders_einvoice_auto_issuance\|partners_einvoice_auto_issuance_reevaluation\|electronic_invoices_einvoice_auto_delivery" supabase/migrations` ⇒ mỗi tên đúng 1 tệp. Ghi Kết quả: tệp:dòng từng hàm / trigger / ca.

### Task 2: Khoá UUIDv5 + đọc payload (G4 — `idempotency_keys.ts`, `payloads.ts`)

**Files:** Create: `handlers/automation/idempotency_keys.ts`, `payloads.ts`; Test: `idempotency_keys_test.ts` (7 + 2), `payloads_test.ts` (2)

**Interfaces — Produces:** các hàm `idempotency_keys.ts`, `payloads.ts` ở G4.

- [x] **2.1** Chép 7 ca. Ca `generates valid canonical UUIDv5 …` ⇒ khớp regex Q11 và ký tự 15 là `5`. Thêm 2 ca:
  - `auto issuance idempotency key matches uuid package vector` — `await autoIssuanceIdempotencyKey({ tenantId: 'tenant-1', salesOrderId: 'order-456', sourceVersion: 'sales-v17' })` ⇒ `'c1ccac1b-df81-519e-a2f5-e4333a17c8d2'`.
  - `auto delivery idempotency key matches uuid package vector` — `await autoDeliveryIdempotencyKey({ tenantId: 'tenant-1', electronicInvoiceId: 'ei-1' })` ⇒ `'214c3038-4c3f-51e0-a7c2-b675ea0fe14b'`.
  `payloads_test.ts` 2 ca mới:
  - `automation payload rejects missing required key` — `parseStartAutoIssuancePayload({ tenant_id: 't', sales_order_id: ' ', source_version: '1' }, 't')` ⇒ ném `Invalid or missing automation payload: sales_order_id`.
  - `automation payload rejects tenant mismatch` — `parseStartAutoDeliveryPayload({ tenant_id: 'tenant-2', electronic_invoice_id: 'ei-1' }, 'tenant-1')` ⇒ ném `Automation tenant does not match claimed tenant`.
  Chạy, thấy đỏ.
- [x] **2.2** Viết 2 tệp. `uuidV5`: byte namespace (bỏ `-`, hex) + UTF-8 `name` → SHA-1 → 16 byte đầu, byte 6 = `(b & 0x0f) | 0x50`, byte 8 = `(b & 0x3f) | 0x80` → hex chữ thường `8-4-4-4-12`. Chạy, thấy 11 ca xanh.
- [x] **2.3** Ghi Kết quả: số dòng TS / Dart.

### Task 3: Gateway + 3 handler + đăng ký (G4)

**Files:** Create: `handlers/automation/gateways.ts`, `supabase_gateways.ts`, `fake_gateways.ts`, `auto_issuance.ts`, `auto_delivery.ts`; Modify: `handlers/registry.ts`, `index.ts`; Test: `auto_issuance_test.ts` (16 + 2), `auto_delivery_test.ts` (10), `registry_test.ts` (1), `processor_integration_test.ts` (1)

**Interfaces — Consumes:** Task 2; `CommandHandler`, `CommandContext`, `ClaimedCommand` (7-E1); `cmd()`, `FakeQueueRpc`, `runInvocation`. **Produces:** `AutomationGateway`, `AutomationDeps`, `createSupabaseAutomationGateway`, `FakeAutomationGateway`, 3 hàm core, 3 `create…Handler`, `HandlerDeps.automation`.

- [x] **3.1** `node .gitnexus/run.cjs analyze` (hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu bị sửa), rồi `impact({target: "buildHandlers", direction: "upstream"})`. Kỳ vọng: ← `index.ts` (+ 2 ca đăng ký dead-letter chỉ dùng `buildDeadLetters`). Ghi Kết quả (không chạy được ⇒ ghi lý do, dùng `grep -rn`). HIGH / CRITICAL ⇒ dừng, báo người dùng.
- [x] **3.2** Chép 26 ca (bảng trên; các ca validator, core handler, bộ xử lý sự kiện). Ca bộ xử lý sự kiện:
  - phát hành: `startIssuanceCalls.length === 1`, `triggerKey === 'sales_order_finalized.v1:event-001:order-123:1'`, `idempotencyKey === await autoIssuanceIdempotencyKey({ tenantId: 'tenant-1', salesOrderId: 'order-123', sourceVersion: '1' })`, `reevaluateCalls.length === 0`.
  - gửi: `triggerId === 'event-001'`; 2 việc `event-a` / `event-b` cùng hoá đơn ⇒ 2 lời gọi cùng `idempotencyKey`.
  Ca mới:
  - `reevaluate handler forwards payload fields` — payload `{ tenant_id: 'tenant-1', process_id: 'proc-1', source_event_id: 'partner:p1:3' }` ⇒ `reevaluateCalls[0]` đúng 3 trường.
  - `start auto issuance handler rejects payload without sales_order_id before calling gateway` — `assertRejects(…, 'Invalid or missing automation payload: sales_order_id')`, `startIssuanceCalls.length === 0`.
  - `registry registers automation command types` (`registry_test.ts`) — `buildHandlers({ …, automation: { gateway: new FakeAutomationGateway() } } as unknown as HandlerDeps)` có 3 khoá `einvoice.start_auto_issuance`, `einvoice.reevaluate_auto_issuance`, `einvoice.start_auto_delivery`.
  - `skipped auto issuance completes the command` (`processor_integration_test.ts`) — `runInvocation` + `FakeQueueRpc` (`batches = [[{ ...cmd('einvoice.start_auto_issuance', 0), payload: { tenant_id: 'tenant-1', sales_order_id: 'order-1', source_version: '1' } }]]`), gateway trả `{ started: false, skipped: true, status: 'SKIPPED', reason: 'AUTOMATION_POLICY_DISABLED', … }` ⇒ `rpc.count('complete') === 1`, `rpc.count('retryOrDeadLetter') === 0`.
  Chạy, thấy đỏ.
- [x] **3.3** Viết `gateways.ts`, `fake_gateways.ts`, `auto_issuance.ts`, `auto_delivery.ts`, sửa `registry.ts`, `index.ts` theo G4; chạy, thấy xanh.
- [x] **3.4** Viết `supabase_gateways.ts`. Ghi Kết quả bảng: hàm TS → RPC → tham số `p_*` → cột đọc về → nguồn mapper Dart (tệp:dòng).
- [x] **3.5** `deno check supabase/functions/einvoice-processor/index.ts`, `deno lint supabase/functions/einvoice-processor`, `deno test supabase/functions/einvoice-processor` — ghi số ca (trước 381, 7-E3 thêm 41, kỳ vọng 422).

### Task 4: Tài liệu — checklist, runbook, TH-08, PLAN

**Files:** Modify: `docs/themes/TH-08-e-invoice/harness/S1-MISA-SANDBOX-CHECKLIST.md`, `docs/themes/TH-08-e-invoice/harness/DEV-LIVE-ACCEPTANCE-CHECKLIST.md`, `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md`, `docs/refactor/PLAN.md`; Create: `docs/refactor/RUNBOOK-einvoice.md`

- [x] **4.1** `RUNBOOK-einvoice.md` (khuôn `RUNBOOK-email.md`, không ghi giá trị bí mật): (1) secret Edge Function `supabase secrets set MISA_MEINVOICE_APP_ID=… MISA_MEINVOICE_BASE_URL=https://testapi.meinvoice.vn/api/integration MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED=…` (ý nghĩa theo TH-08 6.1); (2) Vault: `project_url` (có thể đã có từ email), `service_role_key` = khoá **legacy JWT** `service_role` (Dashboard ▸ Settings ▸ API Keys ▸ Legacy; khoá `sb_secret_…` không phải JWT ⇒ hàm trả 403 `service_role_required`), `einvoice_credential_key` (câu `create_secret` chép từ S1 mục 2); (3) đưa lên — hỏi trước: `db reset --linked` (đã sửa migration gốc), `supabase functions deploy einvoice-processor`; (4) kiểm: `select jobname, schedule from cron.job where jobname = 'einvoice-processor-tick'`, `select status, return_message from cron.job_run_details … order by start_time desc limit 5`, `select status_code, content from net._http_response order by created desc limit 5`; (5) tắt tạm: `select cron.unschedule('einvoice-processor-tick')`, bật lại bằng câu `cron.schedule` của `20261108001`; (6) Local: thiếu Vault thì cron chạy nhưng không gọi.
- [x] **4.2** `S1-MISA-SANDBOX-CHECKLIST.md` viết lại: chuỗi `Vault → RPC → hàng đợi HĐĐT → einvoice-processor (pg_cron / app) → MISA`; mục 1 bỏ `theme8.sql` (thay "migration đã lên Dev"), giữ Exposed schemas / quyền; mục 2 Vault giữ; mục 3 "Worker environment" thay bằng trỏ `RUNBOOK-einvoice.md` mục 1–3; bỏ mọi `melos` / `apps/messaging_worker`. Thêm mục **"Kiểm phía server bằng SQL Editor"** (từng bước có câu SQL + kết quả mong đợi): kết nối (sau UI hoặc RPC) ⇒ `internal_commands` có `einvoice.sync_capabilities` rồi `processed_at` có giá trị trong ≤ 60 giây; bật tự động phát hành + gửi; tạo một đơn khách có email ⇒ `einvoice.start_auto_issuance` xong ⇒ `auto_issuance_processes.status = 'ATTEMPT_STARTED'` ⇒ `einvoice.preview_invoice` / `publish_invoice` xong ⇒ có `electronic_invoices` ⇒ `einvoice.start_auto_delivery` xong ⇒ `invoice_deliveries` 1 dòng `INITIAL_SEND`; khách tổ chức thiếu MST ⇒ `PENDING_REEVALUATION`, bổ sung MST trên app ⇒ `einvoice.reevaluate_auto_issuance` ⇒ `ATTEMPT_STARTED`; việc hỏng: `select command_type, retry_count, error from einvoice.internal_commands where failed_at is not null`.
- [x] **4.3** `DEV-LIVE-ACCEPTANCE-CHECKLIST.md`: dòng mục đích + mục 2 thay "messaging worker" bằng "Edge Function `einvoice-processor` + `pg_cron` (RUNBOOK-einvoice)"; thêm dòng đầu "**Chạy sau 7-A2** (app gọi `functions.invoke`)"; mục 4.0 / 4.3 thay `theme8.sql` / `melos run worker:*` bằng trỏ RUNBOOK; giữ nguyên mục 3, 3b, 5 (bằng chứng cũ — thêm ghi chú "đợt worker cũ, 2026-09").
- [x] **4.4** TH-08: BR-32 (`:264`), BR-34 (`:266`), US-02.3 FR-01 / FR-03 (`:689`, `:691`), US-02.4 FR-05 (`:733` — "trigger trên `einvoice.electronic_invoices` ghi việc `einvoice.start_auto_delivery`"), FR-01 gửi tự động (`:895`), sơ đồ 6.1 (`:1365-1380` thêm dòng trigger), bảng thay thế (`:1553`), 9.2 PR 7.5 (`:1565` — checklist: phần server ở 7-E3, phần UI sau 7-A2), KI-20 cột cuối thêm "7-E3". Thêm **KI-26** sau KI-25: "Hoá đơn được ghi ở 2 hàm (`record_issuance_success`, `recover_internal_finalization`); PLAN / TH-08 từng ghi chỉ `record_issuance_success` tự xếp gửi tự động ⇒ hoá đơn ra từ đối soát sẽ không bao giờ gửi tự động | Trigger `after insert on einvoice.electronic_invoices` xếp `einvoice.start_auto_delivery` | Đã sửa 7-E3".
- [x] **4.5** PLAN.md: dòng **7-E3** cột nội dung thay bằng tóm tắt chốt (Q1–Q6: 3 trigger `…008` / `…013`, cron `20261108001` + Vault `service_role_key`, 3 handler, chép 33 test Dart, viết lại 2 checklist + RUNBOOK; checklist UI sau 7-A2; KI-26), cột Plan ✅ + link + "duyệt 2026-11-08" **chỉ khi người dùng đã duyệt plan**, cột Làm ✅ + ngày + "(chưa commit; còn `db reset` + `einvoice_th08.sql` E47–E52, Vault, deploy, mục kiểm server của S1 — người dùng)"; mục **7.5** thay "`record_issuance_success` tự xếp việc gửi tự động" bằng "trigger trên `electronic_invoices` xếp việc gửi tự động (KI-26)"; dòng **7-B2** cột nội dung thêm "; chạy phần UI của `DEV-LIVE-ACCEPTANCE-CHECKLIST` (7-E3 Q3)".
- [x] **4.6** `node .gitnexus/run.cjs analyze` rồi `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory --scope all`: chỉ tệp trong plan; ghi số tệp / symbol / luồng / rủi ro và số tệp mới chưa `git add`. Hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu `analyze` sửa.

## 6. Review Focus (chưa ca nào chạy — phiên review soi)

1. **`pg_net` ngắt ⇒ Edge Function có bị huỷ?** `timeout_milliseconds := 150000` để `pg_net` chờ hết lần chạy; nếu Supabase huỷ hàm khi client ngắt thì việc đang `claim` bị bỏ dở tới khi `claimed_at` quá 10 phút. Review đối chiếu tài liệu `pg_net` / Edge Runtime; người dùng xem `net._http_response` (RUNBOOK 4.1 (4)) lần đầu chạy trên Dev.
2. **Trigger hồ sơ khách không bắt được sửa trực tiếp `organization_profiles`:** RPC đối tác đều tăng `partners.version` cùng giao dịch, nhưng câu `update partner.organization_profiles` lẻ (như ca E28 / E29 cũ) không kích hoạt. Review `grep -rn "update partner.organization_profiles\|update partner.person_profiles" supabase/migrations` — mọi chỗ phải nằm trong hàm có tăng `version`.
3. **Trigger lỗi làm hỏng bán hàng (Q9):** `enqueue_internal_command` chỉ `insert … on conflict do nothing`; nhưng `_stable_command_id` hay `jsonb_build_object` sai kiểu ⇒ mọi lần bán lỗi. Ca E48 bắt; review đọc kỹ thân trigger đơn.
4. **Đơn trả hết / đổi version trước khi việc chạy:** payload giữ `source_version` lúc chèn; `start_auto_issuance` tự đọc nguồn hiện hành (`ORDER_FULLY_RETURNED` ⇒ `SKIPPED`, version lệch ⇒ gắn version hiện tại — `…008:968-996`). Review xác nhận không cần đọc lại version trong handler.
5. **`start_auto_delivery` ném `DELIVERY_NOT_SUPPORTED` khi MISA không bật gửi email** (`…013:381`): bật "Tự động gửi" trên testapi ⇒ mỗi hoá đơn 3 lượt thử rồi `failed_at` (như worker cũ). S1 mục kiểm server phải nhắc: testapi ⇒ để `auto_send_enabled = false` hoặc chấp nhận dòng hỏng.

## 7. Kiểm tra

### 7.1 Tự động
Task 3.5 (`deno check`, `deno lint`, `deno test` — 422 ca), Task 4.6 (`detect-changes`). Không có test Dart.

### 7.2 Việc của người dùng
- `supabase db reset` local → `psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/einvoice_th08.sql` (E47–E52 mới + E01–E46 cũ không đổi).
- Dev: theo `RUNBOOK-einvoice.md` (secret, Vault, `db reset --linked`, deploy), rồi mục "Kiểm phía server bằng SQL Editor" của S1.
- Sau 7-A2: phần UI của `DEV-LIVE-ACCEPTANCE-CHECKLIST` (ghi ở 7-B2).

## 8. Rủi ro / lưu ý

- **Mọi đơn đều thêm việc** (Q1 / AC-03): tổ chức không dùng HĐĐT vẫn có 1 việc + 1 dòng `SKIPPED` mỗi đơn, như worker cũ. Edge Function được gọi khi có việc này (tối đa mỗi 30 giây).
- **Khoá `service_role` trong Vault:** chỉ đọc được bằng `vault.decrypted_secrets` trong DB; xoay khoá ⇒ cập nhật Vault.
- **Không seed cho dữ liệu cũ:** đơn / hoá đơn có trước migration không có việc tự động (Dev được reset).
- **Sales test `sales_th05.sql`** tạo đơn ⇒ có thêm dòng `einvoice.start_auto_issuance`; tệp đó không đếm `internal_commands` (đã `grep`) ⇒ không ảnh hưởng.
- **Plan dựa trên code tại `68c826826`:** tên / chữ ký lệch ⇒ theo code thật, ghi Kết quả.

## 9. Kết quả (phiên làm code ghi)

**Task 1 — ✅**
- Tệp:
  - `supabase/migrations/20261031008_einvoice_auto_issuance_and_retry_rpcs.sql:4,1335-1424` (sửa, +90 dòng: `_stable_command_id`, `_enqueue_auto_issuance`, `sales_orders_einvoice_auto_issuance`, `_enqueue_auto_issuance_reevaluation`, `partners_einvoice_auto_issuance_reevaluation`)
  - `supabase/migrations/20261031013_einvoice_delivery_schema_and_start_rpcs.sql:5-7,1055-1085` (sửa, +31 dòng: `_enqueue_auto_delivery`, `electronic_invoices_einvoice_auto_delivery`)
  - `supabase/migrations/20261108001_einvoice_processor_cron.sql:1-90` (tạo mới, 90 dòng: `_invoke_processor`, cron job `einvoice-processor-tick`)
  - `supabase/migrations/REGISTRY.yaml:143-154` (sửa, +5 dòng mục `einvoice`)
  - `supabase/tests/einvoice_th08.sql:352-359,1111-1240` (sửa, +138 dòng: biến declare + ca E47–E52)
- Lệch plan + lý do: Không có.
- Ca test: E47–E52 trong `supabase/tests/einvoice_th08.sql` (người dùng chạy `psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/einvoice_th08.sql` sau `db reset`). Tự kiểm: không có `created_at` trong insert mới; mọi `search_path` đều có `pg_temp`; tên 3 trigger duy nhất.
- Impact / detect-changes: N/A (SQL test và migrations, kiểm tra bằng grep tĩnh).

**Task 2 — ✅**
- Tệp:
  - `supabase/functions/einvoice-processor/handlers/automation/idempotency_keys.ts:1-71` (tạo mới, 71 dòng; so với Dart 41 dòng: thêm WebCrypto SHA-1 UUIDv5 thuần không cần thư viện ngoài)
  - `supabase/functions/einvoice-processor/handlers/automation/payloads.ts:1-57` (tạo mới, 57 dòng)
  - `supabase/functions/einvoice-processor/handlers/automation/idempotency_keys_test.ts:1-135` (tạo mới, 135 dòng, 9 ca: 7 ca chép từ Dart + 2 ca vector UUIDv5)
  - `supabase/functions/einvoice-processor/handlers/automation/payloads_test.ts:1-31` (tạo mới, 31 dòng, 2 ca mới)
- Lệch plan + lý do: Không có.
- Ca test: `deno test supabase/functions/einvoice-processor/handlers/automation/` (11 passed, 0 failed).
- Impact / detect-changes: N/A (module handlers/automation độc lập mới tạo).

**Task 3 — ✅**
- Tệp:
  - `supabase/functions/einvoice-processor/handlers/automation/gateways.ts:1-45` (tạo mới, 45 dòng)
  - `supabase/functions/einvoice-processor/handlers/automation/fake_gateways.ts:1-61` (tạo mới, 61 dòng)
  - `supabase/functions/einvoice-processor/handlers/automation/auto_issuance.ts:1-99` (tạo mới, 99 dòng)
  - `supabase/functions/einvoice-processor/handlers/automation/auto_delivery.ts:1-52` (tạo mới, 52 dòng)
  - `supabase/functions/einvoice-processor/handlers/automation/supabase_gateways.ts:1-114` (tạo mới, 114 dòng)
  - `supabase/functions/einvoice-processor/handlers/registry.ts:17-38,62-75` (sửa, +20 dòng: HandlerDeps.automation + 3 handler mới)
  - `supabase/functions/einvoice-processor/index.ts:17,108-111` (sửa, +4 dòng: gắn createSupabaseAutomationGateway)
  - `supabase/functions/einvoice-processor/handlers/automation/auto_issuance_test.ts:1-368` (tạo mới, 368 dòng, 18 ca: 16 ca chép từ Dart + 2 ca mới)
  - `supabase/functions/einvoice-processor/handlers/automation/auto_delivery_test.ts:1-216` (tạo mới, 216 dòng, 10 ca chép từ Dart)
  - `supabase/functions/einvoice-processor/handlers/registry_test.ts:1-14` (tạo mới, 14 dòng, 1 ca mới)
  - `supabase/functions/einvoice-processor/handlers/automation/processor_integration_test.ts:1-46` (tạo mới, 46 dòng, 1 ca mới)
- Bảng đối chiếu Supabase RPC Gateway (Task 3.4):
  | Hàm TS | RPC Supabase | Tham số `p_*` | Cột đọc về | Nguồn mapper Dart (tệp:dòng) |
  |---|---|---|---|---|
  | `startAutoIssuance` | `einvoice.start_auto_issuance` | `p_tenant_id`, `p_sales_order_id`, `p_trigger_key`, `p_idempotency_key` | `started`, `skipped`, `process_id`, `attempt_id`, `status`, `reason` | `modules/einvoice/infrastructure/lib/src/domain/issuance/issuance_rpc_mapper.dart:296-305, 324-340` |
  | `reevaluateAutoIssuance` | `einvoice.reevaluate_auto_issuance` | `p_tenant_id`, `p_process_id`, `p_source_event_id` | `started`, `skipped`, `process_id`, `attempt_id`, `status`, `reason` | `modules/einvoice/infrastructure/lib/src/domain/issuance/issuance_rpc_mapper.dart:307-315, 324-340` |
  | `startAutoDelivery` | `einvoice.start_auto_delivery` | `p_tenant_id`, `p_electronic_invoice_id`, `p_trigger_id`, `p_idempotency_key` | `disposition`, `delivery_id`, `skip_reason` | `modules/einvoice/infrastructure/lib/src/domain/delivery/delivery_rpc_mapper.dart:9-18, 170-188` |
- Lệch plan + lý do: Không có.
- Ca test:
  - `deno check supabase/functions/einvoice-processor/index.ts`: 0 lỗi type-check.
  - `deno lint supabase/functions/einvoice-processor`: 0 cảnh báo lint across 154 files.
  - `deno test supabase/functions/einvoice-processor`: 422 ca passed (381 trước + 41 mới của 7-E3).
- Impact / detect-changes:
  - `node .gitnexus/run.cjs impact -r erp-sales-inventory -d upstream buildHandlers`: 1 direct caller (`index.ts`), risk LOW. Khớp kỳ vọng plan.

**Task 4 — ✅**
- Tệp:
  - `docs/refactor/RUNBOOK-einvoice.md:1-142` (tạo mới, 142 dòng: secret, Vault service_role_key JWT, deploy, kiểm tra cron & net, bật/tắt, local testing)
  - `docs/themes/TH-08-e-invoice/harness/S1-MISA-SANDBOX-CHECKLIST.md:1-201` (viết lại hoàn toàn, 201 dòng: mô hình Edge Function + pg_cron, thêm mục 5 Kiểm tra phía server bằng SQL Editor)
  - `docs/themes/TH-08-e-invoice/harness/DEV-LIVE-ACCEPTANCE-CHECKLIST.md:1-45` (sửa, cập nhật tiền đề Edge Function, trỏ RUNBOOK, ghi chú chạy sau 7-A2)
  - `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md:264-266,689-733,895,1365-1380,1413,1513,1553-1575` (sửa: BR-32, BR-34, US-02.3, US-02.4 FR-05, auto-delivery FR-01, sơ đồ 6.1, 6.2 lệnh nội bộ, 7.3 KI-20 cập nhật KI-26, bảng 9.1, 9.2 PR 7.5, KI-20 và thêm KI-26)
  - `docs/refactor/PLAN.md:7-E3, 7-B2, 7.5` (sửa: tóm tắt 7-E3, cập nhật 7-B2 và 7.5 với KI-26)
  - `docs/refactor/plans/P7/7-E3-einvoice-kich-hoat-server.md` (cập nhật tiến độ task 1-4)
- Lệch plan + lý do: S1 mục 4 giữ `melos run env:sync` / `c45 run erp debug` (lệnh chạy app để kiểm tra UI, không phải messaging worker; plan 4.2 ghi "bỏ mọi melos"). Review R1 chấp nhận giữ.
- Ca test: N/A (tài liệu nghiệp vụ, checklist và runbook).
- Impact / detect-changes:
  - `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory --scope all`: 10 files, 34 symbols, 0 affected processes, risk level LOW. Khớp đúng các tệp trong plan, không có thay đổi ngoài ý muốn.
  - Tệp mới chưa git add: `docs/refactor/RUNBOOK-einvoice.md`, `docs/refactor/plans/P7/7-E3-einvoice-kich-hoat-server.md`, `supabase/functions/einvoice-processor/handlers/automation/` (9 tệp), `supabase/functions/einvoice-processor/handlers/registry_test.ts`, `supabase/migrations/20261108001_einvoice_processor_cron.sql`.

**R1 — đã sửa (2026-11-08)**
- Tệp:
  - `docs/themes/TH-08-e-invoice/harness/S1-MISA-SANDBOX-CHECKLIST.md:101-103,131-155` (bỏ "có thể", khẳng định testapi luôn `supports_email_delivery = false`; bước 4 tách 3 trường hợp kỳ vọng (a), (b), (c) và thêm cột SQL `retry_count`, `left(error, 150)`)
  - `docs/refactor/RUNBOOK-einvoice.md:26` (sửa giải thích `MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED` theo TH-08 :1380, bỏ câu "đặt false để bỏ qua gửi email hoặc chấp nhận dòng hỏng")
  - `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md:1413,1513` (mục 6.2 thêm 3 lệnh tự động kèm "(trigger xếp, 7-E3)"; mục 7.3 KI-20 cập nhật "trigger trên electronic_invoices xếp việc gửi tự động (KI-26)")
  - `docs/refactor/plans/P7/7-E3-einvoice-kich-hoat-server.md` (chính xác hóa số dòng trong Kết quả Tasks 1–4, ghi nhận lệch plan của Task 4, tick R1-1, R1-2, R1-3)
- Lệch plan + lý do: Không có.
- Ca test: `deno check` và `deno test` (422/422 ca passed); `gitnexus detect-changes` (10 files, 34 symbols, LOW).
- Impact / detect-changes: Khớp đúng các tệp trong plan.

## 10. Review (phiên review ghi)

### R1 — 2026-11-08 — **CHƯA ĐẠT** (3 việc sửa tài liệu; mã, trigger, cron, test đúng)

| Hạng mục | Kết quả | Ghi chú |
|---|---|---|
| `deno check index.ts` / `deno lint` | ✅ | chạy lại: 154 tệp, 0 lỗi |
| `deno test supabase/functions/einvoice-processor` | ✅ 422/422 | chạy lại; mới: `idempotency_keys_test` 9, `payloads_test` 2, `auto_issuance_test` 18, `auto_delivery_test` 10, `registry_test` 1, `processor_integration_test` 1 = 41 (33 chép + 8 mới), khớp bảng mục 5 |
| G1 trigger `…008:1335-1424` | ✅ | đúng tên cột (`sales_orders.id` / `version bigint` / `lifecycle_status`, `partners.partner_id` / `version integer`, `auto_issuance_processes.buyer_partner_id`); `security definer` + `search_path` có `pg_temp`; không bọc `exception` (Q9); `enqueue_internal_command` không kiểm role ⇒ gọi được từ trigger trong giao dịch bán hàng của `authenticated` |
| `_stable_command_id` | ✅ | cùng thuật toán với `_delivery_send_command_id` (`…013:66-87`); `p_raw::bytea` an toàn vì chuỗi chỉ gồm uuid / số |
| G2 trigger gửi `…013:1055-1085` | ✅ | bắt cả `record_issuance_success` lẫn `recover_internal_finalization` (KI-26); `Depends on` thêm `008` |
| G3 cron `20261108001` | ✅ | điều kiện đến hạn y hệt `list_tenants_with_due_commands` (`…009:836-852`); thiếu Vault ⇒ `return`; `revoke`; gỡ lịch cũ rồi `cron.schedule` |
| Ca SQL E47–E52 | ✅ (đọc) | biến khai báo đủ; claims lúc E49 là chủ tenant A (đặt lại ở `:839`); `v_ka` không có dòng chờ (chỉ E27 gọi `start_auto_issuance`, cho `v_oc2`); các ca cũ đếm `internal_commands` đều lọc theo `command_type` / `id` ⇒ trigger không làm lệch. Người dùng chạy sau `db reset` |
| Khoá UUIDv5 / triggerKey (Q7) | ✅ | ca vector `c1ccac1b-…`, `214c3038-…`; ký tự 15 là `5` |
| Validator + payload (Q11, Q12) | ✅ | đúng chuỗi lỗi, regex RFC 4122 `i` |
| Gateway Supabase | ✅ | tham số `p_*` khớp mục 3; `disposition` lạ ⇒ ném; `skipReason` chỉ đọc khi `skipped` |
| Wiring `registry.ts:62-70`, `index.ts:17,109-111` | ✅ | |
| `impact(buildHandlers)` / `detect-changes` | ✅ | chạy lại `detect-changes --scope all`: 10 tệp, 34 symbol, 0 luồng, LOW — khớp Kết quả |
| RUNBOOK, DEV-LIVE, PLAN.md | ⚠️ | RUNBOOK mục 1 sai nghĩa `MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED` — R1-1 |
| S1 mục 5 (Review Focus 5) | ❌ | R1-1 |
| TH-08 | ⚠️ | 6.2 thiếu 3 loại việc mới, KI-20 còn câu cũ — R1-2 |
| Số liệu Kết quả | ⚠️ | R1-3 |

**Review Focus (mục 6):**
1. `pg_net` ngắt / Edge Function bị huỷ — ⚠️ không kiểm được khi không có Dev. Rủi ro có giới hạn: việc đang claim hết hạn sau 10 phút rồi chạy lại, RPC có khoá chống trùng. Lần đầu chạy trên Dev, người dùng xem `net._http_response` (RUNBOOK mục 4.3). Không phải việc sửa.
2. Sửa hồ sơ không tăng `version` — ✅ `grep`: chỉ ghi `person_profiles` / `organization_profiles` ở `20260714004:260`, `:331`, `:1181`, đều trong RPC tăng `version` (hoặc tạo đối tác mới — chưa có dòng chờ). Câu `update partner.organization_profiles` lẻ chỉ có trong ca test E28 / E29.
3. Trigger lỗi làm hỏng bán hàng — ✅ đọc thân trigger: kiểu đúng (`uuid` vào `jsonb_build_object`, `version::text`), tham số `null` cho `p_source_event_id uuid` chọn đúng hàm; E48 bắt.
4. Đơn đổi version trước khi việc chạy — ✅ `reevaluate_auto_issuance` gắn version hiện hành (`…008:968-996`); handler không cần đọc lại.
5. `DELIVERY_NOT_SUPPORTED` trên testapi — ❌ thực tế là **luôn luôn**, không phải "có thể": `endpoint_capabilities.ts:17` chỉ bật `supports_email_delivery` khi host là `api.meinvoice.vn`; `start_auto_delivery` ném ở `…013:376-381` (sau bước kiểm `POLICY_OFF`). S1 mục 5.3 bước 4 lại kỳ vọng có `invoice_deliveries` `INITIAL_SEND` ⇒ trên testapi bước này chắc chắn sai — R1-1.

#### R1 — việc cần sửa

- [x] **R1-1 — Gửi tự động trên testapi (S1 mục 5, RUNBOOK mục 1).**
  - `S1-MISA-SANDBOX-CHECKLIST.md` 5.2: bỏ "có thể". Ghi: trên testapi `supports_email_delivery` luôn `false` (chỉ host `api.meinvoice.vn` mới gửi được email).
  - 5.3 bước 4: tách kỳ vọng theo trường hợp:
    - (a) testapi + `auto_send_enabled = true` ⇒ việc `einvoice.start_auto_delivery` có `failed_at`, `retry_count = 3` (hoặc giá trị thật của `retry_or_dead_letter_internal_command`, `…007:787`), `error` chứa `DELIVERY_NOT_SUPPORTED`; `invoice_deliveries` 0 dòng.
    - (b) `auto_send_enabled = false` ⇒ việc có `processed_at` (bỏ qua `POLICY_OFF`); 0 dòng.
    - (c) host `api.meinvoice.vn` + `MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED=true` + khách có email ⇒ 1 dòng `INITIAL_SEND`.
    - Câu SQL bước 4 thêm cột `retry_count`, `left(error, 150)`.
  - `RUNBOOK-einvoice.md` mục 1: sửa dòng `MISA_MEINVOICE_EMAIL_DELIVERY_ENABLED` theo TH-08 `:1380`: "`true` / `1` để bật gửi email; chỉ có hiệu lực với host `api.meinvoice.vn` — trên testapi luôn coi là không hỗ trợ, dù đặt gì". Bỏ câu "đặt `false` để bỏ qua gửi email hoặc chấp nhận dòng hỏng" (đặt `false` không bỏ qua — bỏ qua là do `auto_send_enabled = false`).
- [x] **R1-2 — TH-08 còn chỗ chưa theo 7-E3.**
  - `:1413` (danh sách "Lệnh nội bộ cho bộ xử lý"): thêm `einvoice.start_auto_issuance`, `einvoice.reevaluate_auto_issuance`, `einvoice.start_auto_delivery`, kèm "(trigger xếp, 7-E3)".
  - `:1513` KI-20: thay "`record_issuance_success` tự xếp việc gửi tự động" bằng "trigger trên `electronic_invoices` xếp việc gửi tự động (KI-26)". Câu cũ mâu thuẫn với KI-26 ngay dưới.
  - `:1566` mục 7.4 "9 loại lệnh" giữ nguyên (đó là phạm vi 7-E1 / 7-E2).
- [x] **R1-3 — Số liệu Kết quả.**
  - Số dòng lệch thực tế (`wc -l`):
    - `gateways.ts`: ghi 38, thực tế 45; `auto_issuance.ts`: 93 / 99; `auto_delivery.ts`: 53 / 52; `fake_gateways.ts`: 59 / 61; `supabase_gateways.ts`: 110 / 114; `idempotency_keys.ts`: 72 / 71; `payloads.ts`: 52 / 57.
    - Tệp test: `idempotency_keys_test.ts` 125 / 135, `payloads_test.ts` 30 / 31, `auto_issuance_test.ts` 364 / 368, `auto_delivery_test.ts` 213 / 216, `processor_integration_test.ts` 45 / 46.
    - `20261108001`: 83 / 90; `RUNBOOK-einvoice.md`: 125 / 142; `S1-MISA-SANDBOX-CHECKLIST.md`: 122 / 197.
    - `…008:1335-1426` ⇒ `:1335-1424`; `…013:1054-1086` ⇒ `:1055-1085`.
    - Sửa lại sau khi làm xong R1-1, R1-2.
  - Task 4 "Lệch plan: Không có" ⇒ ghi lệch: S1 mục 4 giữ `melos run env:sync` / `c45 run erp debug` (lệnh chạy app, không phải worker; plan 4.2 ghi "bỏ mọi `melos`"). Review **chấp nhận** giữ.
  - Ghi thêm một mục "R1 — đã sửa" theo mẫu (tệp:dòng). Phiên code không đánh dấu ĐẠT.

### R2 — 2026-11-08 — **ĐẠT**

| Hạng mục | Kết quả | Ghi chú |
|---|---|---|
| `deno check` / `deno lint` / `deno test` | ✅ 422/422 | chạy lại |
| R1-1 S1 5.2 / 5.3 bước 4, RUNBOOK mục 1 | ✅ | 3 trường hợp (a) / (b) / (c) đúng: `retry_count = 3` khớp `…007:787` (`>= 3` ⇒ `failed_at`); `SUCCEEDED` có trong check `invoice_deliveries.status` (`…013`); RUNBOOK `:26` theo TH-08 `:1380` |
| R1-2 TH-08 `:1413`, `:1513` | ✅ | 3 loại việc mới; KI-20 hết mâu thuẫn với KI-26 |
| R1-3 Kết quả | ✅ | số dòng khớp `wc -l` (S1 201 dòng sau sửa); Task 4 ghi lệch `melos`; có mục "R1 — đã sửa" |
| `detect-changes --scope all` | ✅ | 10 tệp, 35 symbol (thêm 1 mục TH-08 do R1-2), 0 luồng, LOW |

Còn việc của người dùng: `db reset` + `einvoice_th08.sql` (E47–E52), Vault `service_role_key`, deploy, mục 5 của S1; theo dõi `net._http_response` lần đầu (Review Focus 1).
