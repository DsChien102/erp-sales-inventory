# 7-C — Dọn sạch module einvoice (module cuối)

> Theme 8 (mã cũ P7, 7-5) · Bước (dọn) theo "Quy tắc dọn module (chốt 2026-10-11)" của PLAN.md
> Trạng thái: Plan ✅ (viết + người dùng duyệt 2026-11-09) | Làm ✅ 2026-11-09 | Review ✅ R1 2026-11-09 (góp ý R1-1, R1-2 đã sửa)
> Làm **sau** 7-B1, 7-E1…7-E3, 7-A1, 7-A2a, 7-A2b, 7-B2 (đã commit, review đạt).
> Tài liệu: PLAN.md mục Theme 8 dòng 7-C, "Quy tắc dọn module", "Quy tắc migration", "Plan xoá / tách / thay code cũ", "Plan chuyển kiến trúc: giữ nghiệp vụ"; TH-08 mục 3, 6.1, 9.1, KI-17, KI-20; mẫu đã làm: 8-C (`docs/refactor/plans/P8/8-C-don-module-sales.md`), 6-C, 4-C.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Xoá hẳn `modules/` (einvoice + 2 `integration_events` còn lại) và 4 package chỉ module dùng (`c45_misa`, `c45_async_query`, `c45_adapters`, `c45_generator`); app bỏ `EinvoiceStartup` / `IEInvoiceModule` / 2 checker cũ; schema `einvoice` chỉ còn phần hàng đợi Edge Function dùng.

**Architecture:** Không đổi nghiệp vụ. Bước 0 chốt hợp đồng SQL trên migration hiện tại (Task 0). Bỏ phần test so với module (Task 1), bỏ DI / checker cũ (Task 2). Khi app không còn import module thì xoá thư mục + workspace (Task 3). Sau đó viết lại `20261031002` cho tạo thẳng hàng đợi (Task 4), dọn script trỏ `modules/` (Task 5), và cập nhật tài liệu (Task 6). Thứ tự này bắt buộc: Task 3 cần Task 1–2 xong mới biên dịch được.

**Tech Stack:** Flutter / Dart (`flutter_test`), Supabase Postgres (plpgsql), `tools/c45_supabase_migrate`, bash.

**Spec:** [TH-08](../../../02-yeu-cau/TH-08-hoa-don-dien-tu.md) (mục 3, 6.1, 9.1, KI-17, KI-20); quyết định ở mục 2 (người dùng chốt 2026-11-09).

## Global Constraints

- **Không đổi nghiệp vụ.** `apps/erp/lib` chỉ đổi: `core/di/injection.dart`, `core/session/session_contracts.dart`, `core/session/session_repository.dart` (Task 2). Không RPC nào app hoặc Edge Function gọi bị đổi chữ ký hay thân hàm.
- **Giữ** `CoreExecutionContext` và 3 lượt đăng ký `IExecutionContext` / `ICurrentUser` / `ICurrentTenant` (sales logic còn dùng — Q1), `c45_shared_*`, `c45_annotations` (9-1), mọi thứ trong `platform` trừ dòng đăng ký einvoice (Q3).
- Test giữ hành vi: được bỏ **phần so với module cũ**, không đổi điều kiện kiểm của phần `new`. Ngoại lệ duy nhất nằm ở Task 1 Step 2: test readiness đổi từ "so với handler cũ" sang "so với giá trị cố định đo trên handler cũ".
- Migration: **sửa migration gốc**, không tạo migration mới. Phiên code **không** chạy / không đề nghị `supabase db reset`, reset Dev, chạy SQL; plan không ghi bước DB nào.
- Trước khi sửa mỗi symbol Dart: `node .gitnexus/run.cjs impact <symbol> --direction upstream --repo erp-sales-inventory`, ghi vào Kết quả. Gặp HIGH / CRITICAL thì báo người dùng trước khi sửa. Trước mỗi commit: `detect_changes`.
- `flutter analyze` sập vì đường dẫn có dấu: dùng `dart analyze`.
- Tìm kiếm dùng `grep -r` (không dùng `git grep`); trong zsh luôn đặt `--include='*.dart'` trong nháy.
- Đếm test của một tệp: `flutter test <tệp> 2>&1 | tail -1` ⇒ ghi số `+N` (và `~S`, `-M` nếu có).
- `AGENTS.md`, `CLAUDE.md` đang có thay đổi chưa commit của người dùng: Task 6 chỉ sửa đúng dòng ghi trong plan và `git add -p` đúng hunk đó.
- Ghi Kết quả (mục 8) ngay sau mỗi task theo mẫu: commit, tệp:dòng, lệch plan, test (trước / sau), impact. Phiên code không tự chấm ĐẠT.

## Review Focus

1. **Bản viết lại `20261031002` lệch bản cài cũ** (thiếu cột / index của `internal_commands`, sai chữ ký hay thiếu grant `service_role` của 5 hàm) ⇒ Edge Function lỗi lúc chạy, vì plpgsql không kiểm lúc `create`. Test: Task 4 `creates einvoice queue directly` (đủ 12 cột, 2 index, 5 chữ ký grant) + Task 0 `keeps every RPC the processor calls` (còn xanh sau Task 4).
2. **Xoá nhầm thứ sales còn dùng** (`CoreExecutionContext`, đăng ký `IExecutionContext`) ⇒ cubit sales ném lỗi `GetIt` lúc mở màn. Test: Task 2 `initDependencies keeps execution context for sales`; `flutter test test/features/sales` cùng số pass.
3. **Câu ghi outbox dùng cột đã bỏ** (bảng chỉ còn 5 cột) ⇒ RPC phát hành / gửi lỗi lúc chạy. Test: Task 0 `outbox writers use only the 5 log columns`.
4. **Pre-commit hoặc guard gãy** sau khi xoá `modules/` / 5 script ⇒ commit sau đó lỗi. Test: Task 5 Step 4 chạy `hooks/pre-commit` + 3 công cụ dùng chung.
5. **Workspace / example còn trỏ package đã xoá** ⇒ `pub get` lỗi. Test: Task 3 Step 4.

---

## 1. Mục tiêu

- `grep -rnE "c45_einvoice_|c45_misa|c45_async_query|async_query|c45_adapters|c45_generator|_integration_events|IEInvoiceModule|EinvoiceStartup|CorePermissionChecker|CoreTenantAccessChecker" apps packages tools scripts hooks pubspec.yaml c45.workspace.json --include='*.dart' --include='*.yaml' --include='*.sh' --include='*.json'` chỉ còn chuỗi trong test nguồn của Task 2 (`injection_test.dart`, danh sách cấm).
- `ls modules` ⇒ không tồn tại; `ls packages` ⇒ `c45_annotations c45_design_system c45_lints c45_shared`.
- Schema `einvoice`: còn `internal_commands` (12 cột, 2 index) + `enqueue_internal_command`, `claim_internal_commands_batch`, `complete_internal_command`, `fail_internal_command`; `outbox_messages` 5 cột + `enqueue_outbox_message`. Không còn: inbox, `receive_integration_event`, hàm claim / complete / fail của outbox và inbox, `renew_publish_series_lease`, dòng đăng ký `platform.messaging_module_registry`.
- TH-08, PLAN.md, README, AGENTS.md, `docs/agents/domain.md` ghi đúng hiện trạng.

## 2. Quyết định

| Q | Nội dung |
|---|---|
| Q1 | **Người dùng chốt 2026-11-09 (A): giữ `CoreExecutionContext`.** Logic sales còn dùng `IExecutionContext` (10 tệp trong `features/sales/logic`, vd `sales_checkout_cubit.dart:186-195`, `sales_checkout_orchestrator.dart:14-19`). 7-C bỏ `CorePermissionChecker`, `CoreTenantAccessChecker`, 2 lượt đăng ký `IPermissionChecker` / `ITenantAccessChecker` (`injection.dart:86-94, 99-100`). Việc thay `IExecutionContext` dời sang **9-1** (cùng lúc xoá `c45_shared`). Bỏ kèm thứ chỉ 2 checker / einvoice dùng: `ILoggerFactory`, `IEventsBus` (`injection.dart:54-58`, chỉ `EinvoiceStartup` đọc), `SessionRepository.hasPermission` (`session_repository.dart:55-66`, chỉ `CorePermissionChecker` gọi), tham số `permissionChecker` của `setUpErpCatalogE2E` (`catalog_e2e_harness.dart:82-91`, 0 nơi truyền) |
| Q2 | **Người dùng chốt 2026-11-09 (A): viết lại `20261031002` cho tạo thẳng.** (a) Bỏ bản đè `platform.install_module_messaging` (`:11-599`, kể cả `revoke` / `grant` của nó) và lệnh `select platform.install_module_messaging('einvoice')` (`:601`). (b) Tạo thẳng trong schema `einvoice`: bảng `internal_commands` + 2 index + 4 hàm `enqueue_internal_command`, `claim_internal_commands_batch` (kèm `drop function if exists … (uuid, integer)` trước), `complete_internal_command`, `fail_internal_command` — chép **nguyên** thân từ khối `execute format` cũ, thay `%I` bằng `einvoice`. (c) `outbox_messages` giữ làm **nhật ký sự kiện** như sales Q1 của 8-C: **5 cột** `id uuid primary key`, `tenant_id uuid not null`, `event_type text not null`, `payload jsonb not null`, `occurred_at timestamptz not null default now()`; bỏ index `outbox_messages_pending_tenant_idx` (không ai đọc). `enqueue_outbox_message` chép nguyên. (d) Giữ nguyên `grant usage on schema einvoice to service_role` / `to authenticated` và `revoke all on all tables in schema einvoice from public, anon, authenticated` (đặt cuối tệp, sau khi tạo bảng, như thứ tự cũ). `revoke all … from public, anon, authenticated` + `grant execute … to service_role` cho đúng 5 hàm, cùng chữ ký cũ. (e) Bỏ: `inbox_messages`, `receive_integration_event`, `claim_outbox_batch`, `complete_outbox_message`, `fail_outbox_message`, `claim_inbox_batch`, `complete_inbox_message`, `fail_inbox_message`, dòng `insert into platform.messaging_module_registry`, `rebuild_messaging_backlog_stats_view()`. 6 migration ghi outbox (`007/008/009/012/014/015/023`) **không sửa** |
| Q3 | **Người dùng chốt 2026-11-09 (A): không đụng nền messaging `platform`.** `20260623000001`, `20260623000002` (vẫn cài cho `iam`, `costing`, `accounting`, `dashboard`), `20260820008` giữ nguyên; việc dọn chuyển sang **9-1**. Kèm: **xoá `einvoice.renew_publish_series_lease`** (`20261031019:147-179`: chú thích + hàm; dòng `revoke` `:236`, `grant` `:241`): không ai gọi (7-E2a Q2 bỏ nhịp gia hạn) |
| Q4 | **Người dùng chốt 2026-11-09 (A): bỏ test của module, không chuyển tệp nào sang app** (như 8-C Q7, 6-C Q4). Mọi test SQL trong `modules/einvoice/infrastructure/test` (36 tệp, gồm 5 tệp `dev_acceptance`) đọc `supabase/migrations/_drafts/`, tức là bản nháp đã promote. Hành vi SQL do `supabase/tests/einvoice_th08.sql` (7-B1) lo, hành vi bộ xử lý do test Deno của `supabase/functions/einvoice-processor` lo. Test mới `apps/erp/test/features/einvoice/data/einvoice_sql_contract_test.dart` chỉ kiểm có / không có (Task 0, Task 4) |
| Q5 | **Người dùng chốt 2026-11-09 (A): dọn script.** Xoá 5 script chỉ phục vụ module: `scripts/scaffold_module.sh`, `scripts/ci/guard_application_dto_colocation.sh`, `guard_application_use_case_layout.sh`, `guard_infra_dart_only.sh`, `guard_layer_imports.sh`; bỏ `hooks/pre-commit:40-42`. Ba công cụ dùng chung chỉ bỏ phần quét `modules/`: `scripts/ci/guard_presentation_size.sh:27-30`, `scripts/sync_analysis_options.sh:75`, `tools/guard_design_system_usage.dart:7, 91, 176, 180`; `c45.workspace.json:9`. Tài liệu harness cũ `docs/themes/TH-0x-*/harness/06-harness-notes.md` không sửa (lịch sử) |
| Q6 | **Người dùng chốt 2026-11-09 (duyệt plan):** (a) 2 `[ERROR] touches_match_body` của `20261108001_einvoice_processor_cron.sql` (có sẵn từ 7-E3, chưa sửa) **không** sửa trong 7-C, coi là mốc; ghi vào mục Rủi ro. (b) `REGISTRY.yaml` cập nhật theo Task 4 Step 5 để `verify_migration_policy` không thêm cảnh báo |

## 3. Hiện trạng (đo 2026-11-09, HEAD `19c2495ba`)

| Thứ | Ai còn dùng |
|---|---|
| `apps/erp/lib` | Chỉ `core/di/injection.dart`: import `:2-3` (`c45_einvoice_application`, `_infrastructure`), `ILoggerFactory` / `IEventsBus` `:54-58`, 2 checker `:84-94`, đăng ký `:95-100`, `EinvoiceStartup` + `IEInvoiceModule` `:289-297`; `core/session/session_contracts.dart` (3 lớp: `:11-44`, `:50-77`, `:80-92`) |
| `apps/erp/test` | `core/di/injection_test.dart` (`:15-17` import module, `:48-52`, `:62-64`); `core/session/session_contracts_test.dart` (nhóm `CorePermissionChecker` `:67`, `CoreTenantAccessChecker` `:131`); `features/einvoice/data/einvoice_errors_test.dart` (nhóm `common cases with old …` `:21-52`: mỗi test vừa so cũ vừa so mới); `features/einvoice/data/einvoice_rpc_parity_test.dart` (nhóm `old` `:26-412`; test `readiness_dto parity …` trong `new (order)` `:942-973` so với handler cũ; `_FakeReadinessGateway` `:1072-1084`); `features/catalog/catalog_e2e_harness.dart:82-91` (`IPermissionChecker`) |
| `apps/erp/integration_test`, `apps/erp/example/lib` | không dùng |
| Workspace | `pubspec.yaml:13-15, 20-30` (gồm 2 `integration_events`, 5 einvoice, `c45_async_query` ×2); `apps/erp/pubspec.yaml:20-23`; `apps/erp/example/pubspec.yaml:19-20` (dependency), override `async_query`, `async_query_flutter`, `c45_adapters`, 5 `c45_einvoice_*`, `c45_misa`, 2 `integration_events` |
| Package | `c45_misa`, `c45_adapters`, `c45_generator`: chỉ `modules/einvoice/infrastructure` + example dùng; `c45_async_query`: chỉ einvoice example + `apps/erp/example` override |
| DB | `20261031002` (602 dòng) đè `platform.install_module_messaging` + cài 3 bảng / 12 hàm + đăng ký registry. Chỗ ghi outbox: 12 lần `einvoice.enqueue_outbox_message` (6 tệp) + 1 câu `insert into einvoice.outbox_messages (id, tenant_id, event_type, payload, occurred_at)` (`20261031012:279`); 0 chỗ đọc outbox / inbox. `claim_internal_commands_batch` được định nghĩa lại ở `007:689-691`, `009:773` |
| Edge Function | gọi 38 RPC `einvoice` (gồm `claim_internal_commands_batch`, `complete_internal_command`, `fail_internal_command`, `list_tenants_with_due_commands`, `reschedule_internal_command`, `retry_or_dead_letter_internal_command`); không gọi `renew_publish_series_lease` |
| `verify_migration_policy` | **2 ERROR** (`20261108001` `touches_match_body`, có sẵn) + 4 WARN `registry_consistency` (`20261101001` ×1, `20261104001` ×2, `20261108001` ×1); `verify_schema_lock_sync`: OK |
| `REGISTRY.yaml` | `einvoice.renew_publish_series_lease: …019…` (`:208`); `platform.install_module_messaging: 20261031002…` (`:343`); không có `enqueue_*` / `complete_internal_command` / `fail_internal_command` của einvoice |
| Test (đo) | `einvoice_rpc_parity_test.dart`: `old` +32 ~10, `new (json)` +19, `new (configuration)` +10, `new (order)` +15; `einvoice_errors_test.dart` +16; `injection_test` + `session_contracts_test` +11 |
| `TEST-BASELINE.md` | `:26-31, :36-41, :46-47` (hàng package / module sẽ xoá), `:152-…` (lỗi `modules/einvoice/application`), mục lỗi `modules/einvoice/infrastructure` |

## 4. Đang làm gì (thứ bị xoá / thay)

| # | Thứ cũ đang làm | Sau khi sửa nằm ở đâu | Test giữ hành vi |
|---|---|---|---|
| 1 | `EinvoiceStartup.initialize(...)` + `registerSingleton<IEInvoiceModule>` (`injection.dart:289-297`): dựng module cũ, không màn nào `di<IEInvoiceModule>()` (từ 7-A2a / 7-A2b) | **Bỏ** | Task 2 `ERP DI source has no einvoice module`; `flutter test test/features/einvoice` cùng số pass |
| 2 | `ILoggerFactory` (`LoggingLoggerFactory`), `IEventsBus` (`InMemoryEventBusClient`) đăng ký lazy (`:54-58`), chỉ dòng 1 đọc | **Bỏ**. Ghi log của app ở `core/config/app_logging.dart`, không đổi | Task 2 `initDependencies drops module-only services` |
| 3 | `CorePermissionChecker.require`: chủ / quyền trong phiên ⇒ qua, ngược lại gọi `iam.has_permission` qua `SessionRepository.hasPermission` ⇒ `ApplicationException('Permission denied: …')`. Chỉ module einvoice gọi | **Bỏ** (cả `SessionRepository.hasPermission` và chỗ fake tương ứng trong `test/core/session/fake_session_repository.dart:34-…`). Màn dùng `SessionController.hasPermission` (`session_controller.dart:143`), không đổi | Task 2 nhóm `CorePermissionChecker` bị xoá; `test/core` khác giữ số pass |
| 4 | `CoreTenantAccessChecker.ensureAccess`: `getSessionContext(tenantId) == null` ⇒ `ApplicationException('Tenant access denied: …')`. Chỉ module einvoice gọi | **Bỏ**. `SessionRepository.getSessionContext` **giữ** (`session_controller.dart:320` dùng) | như dòng 3 |
| 5 | `CoreExecutionContext` + đăng ký `IExecutionContext` / `ICurrentUser` / `ICurrentTenant`: sales logic lấy tenant / user / `correlationId` | **Giữ nguyên** (Q1) | Task 2 `initDependencies keeps execution context for sales`; nhóm `CoreExecutionContext` của `session_contracts_test` giữ |
| 6 | `setUpErpCatalogE2E(permissionChecker:)`: thay `IPermissionChecker` nếu có truyền (0 nơi truyền) | **Bỏ tham số** + khối `:87-90` | `flutter test test/features/catalog` cùng số pass |
| 7 | Nhóm `old` của `einvoice_rpc_parity_test` + nửa "old mapping" của `einvoice_errors_test`: so mapper / handler module với repository / `einvoiceException` của app | Nhóm `new …` cùng tệp (không đổi) | nhóm `new` giữ số test; `einvoice_errors_test` giữ +16 |
| 8 | Test `readiness_dto parity …` (`:942-973`): so `EInvoiceRepository.getReadiness` với `GetIssuanceReadinessQueryHandler` trên 3 mẫu | Cùng test, so với **giá trị cố định** đo từ handler cũ (Task 1 Step 2) | test đó |
| 9 | `install_module_messaging('einvoice')`: tạo 3 bảng + 12 hàm + grant + đăng ký registry + dựng lại view backlog | `20261031002` tạo thẳng phần còn dùng (Q2); phần còn lại **bỏ** | Task 0 `kept`, Task 4 `removed` |
| 10 | `renew_publish_series_lease`: gia hạn khoá ký hiệu (worker Dart cũ) | **Bỏ** (Q3) | Task 4 `removed` |
| 11 | `guard_infra_dart_only.sh`, `guard_layer_imports.sh` trong pre-commit: kiểm lớp của `modules/*` | **Bỏ** (Q5; không còn `modules/`) | Task 5 Step 4 |

## 5. Thay đổi

| Tệp | Hành động |
|---|---|
| `apps/erp/test/features/einvoice/data/einvoice_sql_contract_test.dart` | tạo (Task 0), thêm nhóm `removed` (Task 4) |
| `apps/erp/test/features/einvoice/data/einvoice_errors_test.dart`, `einvoice_rpc_parity_test.dart` | sửa (Task 1) |
| `apps/erp/lib/core/di/injection.dart`, `core/session/session_contracts.dart`, `core/session/session_repository.dart` | sửa (Task 2) |
| `apps/erp/test/core/di/injection_test.dart` (viết lại), `test/core/session/session_contracts_test.dart`, `test/core/session/fake_session_repository.dart`, `test/features/catalog/catalog_e2e_harness.dart` | sửa (Task 2) |
| `modules/` (cả thư mục), `packages/c45_misa`, `c45_async_query`, `c45_adapters`, `c45_generator` | xoá (Task 3) |
| `pubspec.yaml`, `apps/erp/pubspec.yaml`, `apps/erp/example/pubspec.yaml` | sửa (Task 3) |
| `supabase/migrations/20261031002_einvoice_install_module_messaging.sql`, `20261031019_einvoice_misa_publish_series_lease.sql`, `supabase/migrations/REGISTRY.yaml` | sửa (Task 4) |
| 5 script (Q5) | xoá (Task 5) |
| `hooks/pre-commit`, `scripts/ci/guard_presentation_size.sh`, `scripts/sync_analysis_options.sh`, `tools/guard_design_system_usage.dart`, `c45.workspace.json` | sửa (Task 5) |
| `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md`, `docs/refactor/PLAN.md`, `README.md`, `AGENTS.md`, `docs/agents/domain.md` | Task 6 |
| `docs/refactor/TEST-BASELINE.md` | phiên review cập nhật (như 8-C) |

---

## 6. Các task

### Task 0: Bước 0 — test hợp đồng SQL einvoice + đếm test trên code cũ

**Files:**
- Create: `apps/erp/test/features/einvoice/data/einvoice_sql_contract_test.dart`

**Interfaces:**
- Produces (Task 4 dùng lại, cùng tệp):
  - `Directory _findRepoRoot()`, `String _allMigrationsSql()`, `bool _definesFn(String sql, String schema, String name)`: chép nguyên từ `apps/erp/test/features/sales/data/sales_sql_contract_test.dart`.
  - `String _migration(String prefix)`: nội dung tệp `supabase/migrations/<prefix>*.sql` (đúng 1 tệp, không thì `fail`).
  - `const _installedQueueFns = {'enqueue_outbox_message', 'claim_outbox_batch', 'complete_outbox_message', 'fail_outbox_message', 'receive_integration_event', 'claim_inbox_batch', 'complete_inbox_message', 'fail_inbox_message', 'enqueue_internal_command', 'claim_internal_commands_batch', 'complete_internal_command', 'fail_internal_command'}`.
  - `bool _einvoiceDefines(String sql, String name)`: `_definesFn(sql, 'einvoice', name)` **hoặc** (`_migration('20261031002')` chứa `select platform.install_module_messaging('einvoice')` **và** `_installedQueueFns.contains(name)`). Lý do: trên code cũ các hàm này được tạo qua `%I.`, regex không thấy. Sau Task 4, vế sau luôn sai, nên test buộc phải thấy định nghĩa tĩnh.

- [x] **Step 1: Viết nhóm `kept`**

| Tên test | Kiểm |
|---|---|
| `keeps every RPC the app calls` | `_einvoiceDefines(sql, n)` đúng với 24 tên: `connect_provider`, `disconnect_provider`, `get_automation_policy`, `get_configuration_readiness`, `get_electronic_invoice_detail`, `get_invoice_delivery_history`, `get_invoice_documents`, `get_invoice_preview`, `get_issuance_attempt_status`, `get_issuance_profile`, `get_issuance_readiness`, `get_order_invoice_projection`, `get_provider_connection_screen`, `get_send_invoice_sheet_context`, `issue_invoice`, `list_provider_templates`, `reconnect_provider`, `request_invoice_document`, `request_invoice_preview`, `request_official_invoice_view`, `retry_issuance`, `send_electronic_invoice`, `set_default_issuance_configuration`, `update_automation_policy` |
| `app RPC list matches repositories` | nối nội dung `apps/erp/lib/features/einvoice/data/*.dart`; `RegExp(r"'einvoice',\s*'([a-z_]+)'")` (khớp qua xuống dòng); tập tên == 24 tên trên |
| `keeps every RPC the processor calls` | nối mọi `supabase/functions/einvoice-processor/**/*.ts` trừ `*_test.ts`; `RegExp(r"(?:\.rpc|#call)\(\s*'([a-z_]+)'")`; tập tên có đúng 38 phần tử và mỗi tên `_einvoiceDefines(sql, n)` |
| `keeps outbox log writers` | nối mọi migration **trừ** `20261031002`: chứa đúng 12 lần `einvoice.enqueue_outbox_message(`; `_einvoiceDefines(sql, 'enqueue_outbox_message')` |
| `outbox writers use only the 5 log columns` | mọi khớp `RegExp(r'insert into einvoice\.outbox_messages\s*\(([^)]*)\)')` trong `sql`: tập cột (tách `,`, `trim`) ⊆ `{id, tenant_id, event_type, payload, occurred_at}`; có ≥ 1 khớp. Thân `enqueue_outbox_message` trong `_migration('20261031002')` chèn đúng `(id, tenant_id, event_type, payload, occurred_at)` (kiểm chuỗi `id, tenant_id, event_type, payload, occurred_at` có trong tệp) |
| `nobody reads outbox or inbox` | `sql` không chứa `from einvoice.outbox_messages`, `join einvoice.outbox_messages`, `einvoice.inbox_messages`; các tệp `.ts` của Edge Function không chứa `outbox_messages`, `inbox_messages` |

- [x] **Step 2: Chạy** `cd apps/erp && flutter test test/features/einvoice/data/einvoice_sql_contract_test.dart` ⇒ PASS 6/6. Đỏ ⇒ dừng, ghi lại (bảng mục 3 sai).
- [x] **Step 3: Đếm test trên code cũ**, ghi vào Kết quả: 4 nhóm của `einvoice_rpc_parity_test.dart` (`--plain-name "old"`, `"new (json)"`, `"new (configuration)"`, `"new (order)"`), `einvoice_errors_test.dart`, `test/core/di/injection_test.dart`, `test/core/session/session_contracts_test.dart` (theo từng nhóm), `test/features/einvoice`, `test/features/sales`, `test/features/catalog`, cả `apps/erp` (`flutter test 2>&1 | tail -1`).
- [x] **Step 4: Commit** `test(einvoice): 7-C bước 0 — test hợp đồng RPC einvoice trên migration hiện tại`

### Task 1: Test einvoice của app bỏ phần so với module

**Files:**
- Modify: `apps/erp/test/features/einvoice/data/einvoice_errors_test.dart`, `apps/erp/test/features/einvoice/data/einvoice_rpc_parity_test.dart`

- [x] **Step 1: `einvoice_errors_test.dart`.** Trong nhóm `common cases with old mapEinvoiceRpcError parity` (`:21-52`): xoá 2 dòng "Old mapping" (`oldException = mapEinvoiceRpcError(...)` + `expect(oldException.code, …)`) ở cả 2 test, giữ nguyên phần "New mapping"; đổi tên nhóm thành `common cases`. Xoá import `c45_einvoice_infrastructure/src/errors/einvoice_error_mapper.dart` và `c45_shared_infrastructure` (nếu `RpcException` không còn dùng), bỏ `// ignore_for_file: implementation_imports` nếu hết import `src/`. Chạy ⇒ +16 (số không đổi); số dòng `expect(` giảm đúng 2 (2 dòng `expect(oldException.code, …)`).
- [x] **Step 2: Test readiness ở `new (order)` (`:942-973`).** (a) Trên code cũ, thêm tạm vào test một `print` cho mỗi mẫu: `oldDto.level.name`, `oldDto.buyerCompletionState.name`, danh sách `(code, message)` của `blockers` và `warnings`. Chạy, chép kết quả vào Kết quả, rồi bỏ `print`. (b) Thêm, **bên cạnh** các `expect` so cũ, các `expect` trên `newDto` bằng giá trị cố định vừa đo (`level`, `buyerCompletionState`, `blockers[i].code` / `.message`, `warnings[i].code` / `.message`, đúng độ dài). Mã phải khớp nhóm cũ `:354-412`: ready ⇒ `ready`, `[]`, `[]`; missing template ⇒ `notReady`, `['CONFIG_NOT_READY']`, `[]`; org missing tax ⇒ `notReady`, `['BUYER_TAX_CODE_REQUIRED']`, `[]`. Lệch ⇒ dừng, ghi lại. Chạy ⇒ xanh. (c) Xoá phần handler cũ (`oldInput`, `oldHandler`, `oldDto` và các `expect` so với `oldDto`); đổi tên test thành `readiness_dto: new repository maps all 3 sets`.
- [x] **Step 3: Bỏ nhóm `old`** (`:26-412`, kiểm lại bằng `grep -n "group('"`), lớp `_FakeReadinessGateway` (`:1072-1084`), các import module (`:16-21`) và `// ignore_for_file: implementation_imports` nếu hết import `src/`. Helper / hằng chỉ nhóm `old` dùng ⇒ xoá (kiểm 0 tham chiếu còn lại). **Không** sửa `einvoice_parity_expectations.dart` và các ca của nhóm `new`.
- [x] **Step 4: Kiểm.** `grep -n "c45_" test/features/einvoice/data/*.dart` ⇒ rỗng; `dart analyze test/features/einvoice` ⇒ 0 issue mới; `flutter test test/features/einvoice/data/einvoice_rpc_parity_test.dart` ⇒ +44 (`19 + 10 + 15`, đúng bằng 3 nhóm `new` ở Task 0 Step 3), không `~`; `flutter test test/features/einvoice` ⇒ số Task 0 trừ đúng số test của nhóm `old`.
- [x] **Step 5: Commit** `test(einvoice): 7-C bỏ nhóm test so với module einvoice cũ`

### Task 2: DI và phiên bỏ module einvoice + 2 checker (Q1)

**Files:**
- Modify: `apps/erp/lib/core/di/injection.dart:2-3, 54-58, 84-100, 289-297`; `apps/erp/lib/core/session/session_contracts.dart:46-92`; `apps/erp/lib/core/session/session_repository.dart:55-66`
- Modify: `apps/erp/test/core/di/injection_test.dart` (viết lại), `apps/erp/test/core/session/session_contracts_test.dart`, `apps/erp/test/core/session/fake_session_repository.dart`, `apps/erp/test/features/catalog/catalog_e2e_harness.dart:80-91`

**Interfaces:**
- Produces: `initDependencies` vẫn đăng ký `IExecutionContext`, `ICurrentUser`, `ICurrentTenant` ⇒ cùng một `CoreExecutionContext`; **không** đăng ký `IPermissionChecker`, `ITenantAccessChecker`, `ILoggerFactory`, `IEventsBus`, `IEInvoiceModule`. `setUpErpCatalogE2E({String scenario = FakeCatalogScenario.guidedCreateOk})`.

- [x] **Step 1: Impact** cho `initDependencies`, `CorePermissionChecker`, `CoreTenantAccessChecker`, `hasPermission` (của `SessionRepository`), `setUpErpCatalogE2E` ⇒ ghi vào Kết quả.
- [x] **Step 2: Viết lại `injection_test.dart` (đỏ).** Bỏ 3 import module (`:15-17`). Giữ 2 fake Supabase và test hiện có trừ `:51-52`, `:62-64`. Thêm:
  - `initDependencies keeps execution context for sales`: `getIt<IExecutionContext>()`, `getIt<ICurrentUser>()`, `getIt<ICurrentTenant>()` đều `isA<CoreExecutionContext>()` và `identical` nhau.
  - `initDependencies drops module-only services`: `getIt.isRegistered<IPermissionChecker>()`, `<ITenantAccessChecker>()`, `<ILoggerFactory>()`, `<IEventsBus>()` đều `isFalse`.
  - `ERP DI source has no einvoice module`: nội dung `apps/erp/lib/core/di/injection.dart` (tìm từ gốc repo như `_findRepoRoot` của Task 0) không chứa `c45_einvoice_`, `EinvoiceStartup`, `IEInvoiceModule`, `CorePermissionChecker`, `CoreTenantAccessChecker`.

  Chạy ⇒ 2 test mới sau FAIL, phần còn lại PASS.
- [x] **Step 3: Sửa `injection.dart`.** Xoá import `:2-3`; xoá `:54-58`; xoá `permissionChecker`, `tenantAccessChecker` (`:86-94`) và 2 dòng đăng ký `:99-100`; xoá `:289-297`. Sửa chú thích `:84` thành `// Ngữ cảnh phiên cho logic sales (IExecutionContext; thay ở 9-1), đọc cùng SessionStore.` Import `c45_shared_infrastructure` (`:5`) bỏ nếu `dart analyze` báo không dùng.
- [x] **Step 4: Sửa `session_contracts.dart`**: xoá `CorePermissionChecker` (`:46-77`, gồm chú thích đầu lớp) và `CoreTenantAccessChecker` (`:79-92`); bỏ import `session_repository.dart` nếu thừa. `session_repository.dart`: xoá `hasPermission` (`:55-66`). `session_store.dart:9, :43-45`: sửa chú thích còn nhắc `CorePermissionChecker` / `iam.has_permission` thành chỉ nói `CoreExecutionContext`.
- [x] **Step 5: Test phiên + harness.** `session_contracts_test.dart`: xoá nhóm `CorePermissionChecker` và `CoreTenantAccessChecker`; giữ nguyên nhóm `CoreExecutionContext`. `fake_session_repository.dart`: xoá override `hasPermission` + trường `permissionGranted` nếu không còn ai dùng (`grep -rn "permissionGranted" test` ⇒ 0). `catalog_e2e_harness.dart`: bỏ tham số `permissionChecker` + khối `:87-90` + import `c45_shared_application` nếu thừa.
- [x] **Step 6: Kiểm.**
  - `cd apps/erp && flutter test test/core/di/injection_test.dart` ⇒ PASS hết
  - `flutter test test/core` ⇒ số Task 0 trừ đúng số test của 2 nhóm checker, cộng 3 test mới
  - `flutter test test/features/sales test/features/catalog test/features/einvoice` ⇒ cùng số pass như Task 0 / Task 1
  - `grep -rln "c45_einvoice_\|IEInvoiceModule\|EinvoiceStartup" apps/erp --include='*.dart'` ⇒ chỉ `test/core/di/injection_test.dart` (chuỗi cấm)
  - `dart analyze lib test integration_test` ⇒ 0 error, 0 warning mới
- [x] **Step 7: Commit** `refactor(einvoice): 7-C bỏ EinvoiceStartup, CorePermissionChecker, CoreTenantAccessChecker khỏi DI`

### Task 3: Xoá `modules/` + 4 package + workspace

**Files:**
- Delete: `modules/`, `packages/c45_misa`, `packages/c45_async_query`, `packages/c45_adapters`, `packages/c45_generator`
- Modify: `pubspec.yaml:8-30`, `apps/erp/pubspec.yaml:20-23`, `apps/erp/example/pubspec.yaml`

- [x] **Step 1: Kiểm trước.** `ls modules` ⇒ `einvoice partner sales`; `ls modules/partner modules/sales` ⇒ chỉ `integration_events`; `git status --short modules packages` sạch; `grep -rln "c45_misa\|c45_adapters\|c45_generator\|async_query" packages/c45_shared packages/c45_annotations packages/c45_design_system packages/c45_lints tools apps --include='pubspec.yaml'` ⇒ chỉ `apps/erp/example/pubspec.yaml`.
- [x] **Step 2: Xoá.** `git rm -r -q modules packages/c45_misa packages/c45_async_query packages/c45_adapters packages/c45_generator`; `rm -rf` phần không theo dõi còn lại (`.dart_tool`, `build`) của các thư mục đó.
- [x] **Step 3: Sửa pubspec.**
  - `pubspec.yaml` `workspace:` còn đúng: `apps/erp`, `packages/c45_lints`, `packages/c45_design_system`, `packages/c45_annotations`, `packages/c45_shared/application`, `packages/c45_shared/domain`, `packages/c45_shared/infrastructure`, `packages/c45_shared/testing`, `tools/c45_env`, `tools/c45_supabase_migrate`
  - `apps/erp/pubspec.yaml`: xoá 4 dòng `c45_einvoice_*` (`:20-23`)
  - `apps/erp/example/pubspec.yaml`: xoá dependency `c45_einvoice_domain` (`:19-20`); trong `dependency_overrides` xoá `async_query`, `async_query_flutter`, `c45_adapters`, 5 `c45_einvoice_*`, `c45_misa`, `c45_partner_integration_events`, `c45_sales_integration_events`; giữ `c45_annotations`, `c45_design_system`, `c45_lints`, 4 `c45_shared_*`
- [x] **Step 4: `pub get`** ở gốc (`dart pub get`), `apps/erp/example` (`flutter pub get`) ⇒ không lỗi phân giải; `pubspec.lock` gốc đổi theo.
- [x] **Step 5: Kiểm.**
  - `cd apps/erp && dart analyze lib test integration_test` ⇒ 0 error, 0 warning mới; `cd apps/erp/example && dart analyze lib` ⇒ 0 error
  - `dart analyze packages/c45_shared packages/c45_annotations tools` ⇒ 0 error
  - `cd apps/erp && flutter test` ⇒ không lỗi mới so với `TEST-BASELINE.md` (mốc "Sau 8-C": 53 + 2 ⚠️); ghi số đạt / lỗi
- [x] **Step 6: Commit** `chore(einvoice): 7-C xoá modules/ và c45_misa, c45_async_query, c45_adapters, c45_generator`

### Task 4: DB — viết lại `20261031002`, bỏ `renew_publish_series_lease` (Q2, Q3)

**Files:** `supabase/migrations/20261031002_einvoice_install_module_messaging.sql`, `supabase/migrations/20261031019_einvoice_misa_publish_series_lease.sql`, `supabase/migrations/REGISTRY.yaml`, `apps/erp/test/features/einvoice/data/einvoice_sql_contract_test.dart`

- [x] **Step 1: Nhóm `removed` (đỏ)** thêm vào `einvoice_sql_contract_test.dart`:

| Tên test | Kiểm |
|---|---|
| `einvoice no longer installs messaging` | không tệp migration nào chứa `install_module_messaging('einvoice')`; `_migration('20261031002')` không chứa `platform.install_module_messaging`, `messaging_module_registry`, `rebuild_messaging_backlog_stats_view` |
| `einvoice has no inbox or outbox queue` | `_migration('20261031002')` không chứa `inbox_messages`, `receive_integration_event`, `claim_outbox_batch`, `complete_outbox_message`, `fail_outbox_message`, `claim_inbox_batch`, `complete_inbox_message`, `fail_inbox_message` |
| `creates einvoice queue directly` | `_migration('20261031002')`: (1) chứa `create table if not exists einvoice.internal_commands (`; khối tới `);` đầu tiên chứa đủ 12 cột `id uuid primary key`, `tenant_id uuid not null`, `command_type text not null`, `payload jsonb not null`, `source_event_id uuid null`, `enqueued_at timestamptz not null default now()`, `processed_at timestamptz null`, `failed_at timestamptz null`, `error text null`, `retry_count int not null default 0`, `claimed_at timestamptz null`, `claim_token uuid null`; (2) chứa `internal_commands_pending_tenant_idx`, `internal_commands_source_dedup_idx`; (3) chứa `create table if not exists einvoice.outbox_messages (`, khối tới `);` đầu tiên chứa đủ 5 cột của Q2(c), không chứa `processed_at`, `claim_token`; (4) `_definesFn(file, 'einvoice', n)` đúng với `enqueue_outbox_message`, `enqueue_internal_command`, `claim_internal_commands_batch`, `complete_internal_command`, `fail_internal_command`; (5) chứa đủ 5 chữ ký trong `grant execute on function …  to service_role`: `einvoice.enqueue_outbox_message(uuid, text, jsonb, uuid, timestamptz)`, `einvoice.enqueue_internal_command(uuid, text, jsonb, uuid, uuid)`, `einvoice.claim_internal_commands_batch(uuid, int)`, `einvoice.complete_internal_command(uuid, uuid, uuid)`, `einvoice.fail_internal_command(uuid, uuid, uuid, text)`; (6) chứa `revoke all on all tables in schema einvoice from public, anon, authenticated`, `grant usage on schema einvoice to service_role`, `grant usage on schema einvoice to authenticated` |
| `drops renew_publish_series_lease` | `sql` không chứa `renew_publish_series_lease`; `REGISTRY.yaml` không chứa nó |

Run: `flutter test test/features/einvoice/data/einvoice_sql_contract_test.dart` ⇒ 4 test mới FAIL, 6 `kept` PASS.

- [x] **Step 2: Viết lại `20261031002`** theo Q2. Header: `-- Title: einvoice — hàng đợi internal_commands + nhật ký outbox`; `-- Kind:` giữ; `-- Touches: einvoice.internal_commands, einvoice.outbox_messages, einvoice.enqueue_outbox_message, einvoice.enqueue_internal_command, einvoice.claim_internal_commands_batch, einvoice.complete_internal_command, einvoice.fail_internal_command`; `-- Depends on: 20261031001_einvoice_configuration_schema.sql`; thêm dòng `-- 7-C (2026-11-09): bỏ messaging (inbox, hàm outbox / inbox, đăng ký platform); outbox_messages = nhật ký sự kiện, không ai đọc.` Thứ tự thân: `create schema if not exists einvoice;` → bảng `outbox_messages` → bảng `internal_commands` + 2 index → `enqueue_outbox_message` → `enqueue_internal_command` → `drop function if exists einvoice.claim_internal_commands_batch(uuid, integer);` + `claim_internal_commands_batch` → `complete_internal_command` → `fail_internal_command` → `grant usage` ×2 → `revoke all on all tables …` → `revoke` / `grant execute` 5 hàm. Mỗi thân hàm: chép nguyên khối `$sql$ … $sql$` cũ, bỏ `execute format(`, thay `%I` bằng `einvoice` (cả trong `set search_path = %I, platform, pg_temp`), `$fn$` giữ hoặc đổi thành `$$` (không đổi nội dung giữa hai dấu).
- [x] **Step 3: Kiểm bản chép.** Với mỗi hàm trong 5 hàm: `diff` thân cũ (lấy từ `git show HEAD:supabase/migrations/20261031002_einvoice_install_module_messaging.sql`, thay `%I` → `einvoice`) với thân mới ⇒ chỉ khác dấu bao `$fn$` / `$$` và thụt lề. Ghi lệnh + kết quả vào Kết quả.
- [x] **Step 4: `20261031019`**: xoá chú thích `:147` + khối `create or replace function einvoice.renew_publish_series_lease(` … `$$;` đầu tiên sau đó (`:148-179`; **giữ** chú thích `:181` của hàm kế), dòng `revoke` (`:236`) và `grant` (`:241`) của nó; header `-- Touches:` bỏ `einvoice.renew_publish_series_lease`; thêm dòng `-- 7-C (2026-11-09): bỏ renew_publish_series_lease (Edge Function không gia hạn khoá, 7-E2a Q2).`
- [x] **Step 5: `REGISTRY.yaml`**: xoá `renew_publish_series_lease` (`:208`); `platform.install_module_messaging` (`:343`) ⇒ `20260623000001_platform_messaging_foundation.sql`; thêm dưới `einvoice:` theo thứ tự chữ cái: `complete_internal_command`, `enqueue_internal_command`, `enqueue_outbox_message`, `fail_internal_command` ⇒ `20261031002_einvoice_install_module_messaging.sql`. Không đổi danh sách tệp migration.
- [x] **Step 6: Kiểm**
  - `flutter test test/features/einvoice/data/einvoice_sql_contract_test.dart` ⇒ 10/10 PASS
  - `grep -rnE "install_module_messaging\('einvoice'\)|einvoice\.(inbox_messages|claim_outbox_batch|receive_integration_event|renew_publish_series_lease)" supabase` ⇒ rỗng
  - `dart run tools/c45_supabase_migrate/bin/verify_migration_policy.dart` ⇒ đúng mốc mục 3 (2 ERROR + 4 WARN có sẵn), không dòng mới nào nhắc `20261031002` / `20261031019`
  - `dart run tools/c45_supabase_migrate/bin/verify_schema_lock_sync.dart` ⇒ `OK`
- [x] **Step 7: Commit** `chore(db): 7-C einvoice tạo thẳng hàng đợi, bỏ inbox / hàm outbox / đăng ký platform, bỏ renew_publish_series_lease (sửa migration gốc)`

### Task 5: Script và công cụ trỏ `modules/` (Q5)

**Files:**
- Delete: `scripts/scaffold_module.sh`, `scripts/ci/guard_application_dto_colocation.sh`, `scripts/ci/guard_application_use_case_layout.sh`, `scripts/ci/guard_infra_dart_only.sh`, `scripts/ci/guard_layer_imports.sh`
- Modify: `hooks/pre-commit:40-42`, `scripts/ci/guard_presentation_size.sh:27-30`, `scripts/sync_analysis_options.sh:75`, `tools/guard_design_system_usage.dart:7, 91, 176, 180`, `c45.workspace.json:9`

- [x] **Step 1: Kiểm người gọi.** `grep -rn "guard_application_dto_colocation\|guard_application_use_case_layout\|guard_infra_dart_only\|guard_layer_imports\|scaffold_module" scripts hooks tools pubspec.yaml README.md .gitlab-ci.yml 2>/dev/null` ⇒ chỉ `hooks/pre-commit:41-42`, `README.md:112` và chính các tệp đó. Có chỗ khác ⇒ dừng, ghi lại.
- [x] **Step 2: Xoá** 5 script (`git rm`); `hooks/pre-commit` xoá dòng chú thích `# Harness guards (fast, architecture-only)` và 2 dòng gọi.
- [x] **Step 3: Sửa 3 công cụ + workspace.** `guard_presentation_size.sh`: xoá vòng `while … done < <(find "$root/modules" …)`. `sync_analysis_options.sh:75`: `find apps packages -name pubspec.yaml …` (bỏ `modules`). `guard_design_system_usage.dart`: xoá `modulesDir`, vế `|| (relPath.startsWith('modules/') && …)`, `scanDir(modulesDir);`; dòng in tóm tắt thành `'         monitored = apps/erp features presentation'`. `c45.workspace.json`: xoá `"modules/**/c45.target.json"` (sửa dấu phẩy dòng trước).
- [x] **Step 4: Kiểm.**
  - `./scripts/ci/guard_presentation_size.sh` ⇒ exit 0 (hoặc đúng các lỗi như trước khi sửa — chạy trên HEAD trước để so)
  - `dart run tools/guard_design_system_usage.dart` ⇒ cùng số vi phạm `enforced` như trước khi sửa
  - `./scripts/sync_analysis_options.sh && git status --short -- '*analysis_options.yaml' '*pubspec.yaml'` ⇒ không tệp nào đổi, không có dòng `find: modules` trên stderr
  - `dart run tools/c45_env/bin/run.dart list` ⇒ chạy được, không lỗi đọc `c45.workspace.json`
  - `sh -n hooks/pre-commit` ⇒ không lỗi cú pháp; commit Step 5 chạy qua hook
- [x] **Step 5: Commit** `chore(tools): 7-C bỏ script / guard của modules, công cụ dùng chung thôi quét modules/`

### Task 6: Tài liệu + kiểm tổng

- [x] **Step 1: TH-08 → 1.2** (ngày 2026-11-09, dòng 4 `**Phiên bản:** 1.2 · **Ngày:** 2026-11-09`):
  - dòng 8 "Nguồn đối chiếu — App": bỏ "module `modules/einvoice/` (domain, application, infrastructure, presentation)", thay khối trên đơn bằng `apps/erp/lib/features/einvoice/{data,logic,presentation}` (UI thiết lập + khu HĐĐT trên đơn, 7-A2a / 7-A2b)
  - dòng 9: thay "(`packages/c45_misa` còn là nguồn để port)" bằng "`packages/c45_misa` đã xoá ở 7-C (client MISA ở Edge Function, 7-E1)"
  - mục 3 (dòng 334): "Hàng đợi `internal_commands` (bộ xử lý) và `outbox_messages` (nhật ký sự kiện 5 cột, không ai đọc) do `20261031002` tạo thẳng; inbox và hàm outbox / inbox bỏ ở 7-C (KI-20)."
  - 6.1 (dòng 1384): "UI thiết lập và khu HĐĐT trên đơn nằm ở `apps/erp/lib/features/einvoice/presentation`; `features/sales` chỉ nhúng `OrderEInvoiceSection` (7-A2b)."
  - 9.1: dòng "Module `modules/einvoice` …", "`c45_async_query` …", "Bộ xử lý `apps/messaging_worker` …" cột "Sau refactor" thêm "(xong 7-C)"
- [x] **Step 2: PLAN.md**:
  - dòng 7-C (545): nội dung ghi đúng Q1–Q5 (giữ `CoreExecutionContext`, viết lại `20261031002`, không đụng `platform`, xoá `renew_publish_series_lease`, xoá 5 script); cột Plan `✅ [plan](plans/P7/7-C-don-module-einvoice.md) duyệt 2026-11-09`; cột Làm `✅ 2026-11-09`
  - dòng 9-1 (721): thêm "thay `IExecutionContext` / `CoreExecutionContext` trong `features/sales/logic` (10 tệp) bằng `SessionController` (7-C Q1); dọn nền messaging `platform` (`20260623000001/000002`, `20260820008`, 4 schema `iam` / `costing` / `accounting` / `dashboard`) (7-C Q3)"
  - dòng 9.1 (728), 9.2 (729): ghi 7-C đã xoá `modules/` + 4 package
  - dòng trạng thái Theme 8 (530), bảng "Theo dõi tiến độ" (800)
- [x] **Step 3: Tài liệu chung.** `README.md:21` xoá dòng `modules/` trong cây thư mục, `:112` xoá dòng scaffold; `AGENTS.md:35` thành "Code cũ trong `packages/c45_shared` còn đến 9-1 (`modules/` đã xoá hết ở 7-C); chỉ đọc để chuyển, không thêm code mới" (`git add -p` chỉ hunk này); `docs/agents/domain.md:8` bỏ câu "Also check `modules/<context>/docs/adr/` …", cây `:20-26` đổi `modules/` thành `apps/erp/lib/features/`.
- [x] **Step 4: Kiểm tổng**
  - lệnh `grep` ở mục 1 ⇒ như đã ghi
  - `ls modules` ⇒ không tồn tại; `ls packages` ⇒ 4 thư mục
  - `cd apps/erp && dart analyze lib test integration_test` ⇒ 0 error, 0 warning mới (258 info có sẵn)
  - `cd apps/erp && flutter test test/features/einvoice test/core` ⇒ 528/528 passed! `flutter test` toàn app ở Task 3: 2.984 đạt / 55 lỗi (khớp 53 lỗi `TEST-BASELINE.md` + 2 lỗi ⚠️ ngoài mốc)
  - `git diff 19c2495ba HEAD --stat -- apps/erp/lib` ⇒ chỉ 4 tệp của Task 2
  - `node .gitnexus/run.cjs analyze` + `detect_changes` ⇒ 42.335 nodes, 90.415 edges, 0 affected process, risk low
- [x] **Step 5: Commit** `docs(refactor): 7-C cập nhật TH-08 1.2, PLAN.md, README / AGENTS và kết quả plan 7-C`

## 7. Rủi ro / lưu ý

- **DB dựng lại.** Hàm plpgsql không kiểm bảng lúc `create`; Task 0 `outbox writers…` + Task 4 `creates einvoice queue directly` chốt cột còn giữ. Kiểm thật (người dùng): `db reset` + `supabase/tests/einvoice_th08.sql` + một lượt phát hành trên Dev.
- **`claim_internal_commands_batch`** bị `007` / `009` định nghĩa lại; bản trong `002` chỉ để giữ đúng thứ tự cũ (007 `drop` rồi tạo lại). Không sửa 007 / 009.
- **View `platform.messaging_backlog_stats`** không còn gồm einvoice (không đăng ký); không ai đọc view này (Edge Function dùng `list_tenants_with_due_commands`).
- **`v_allowed` của `platform.install_module_messaging`** về lại bản `20260623000001` (không có `einvoice`): vô hại, 9-1 dọn.
- **2 ERROR có sẵn** của `20261108001` (`touches_match_body`, Q6a): để nguyên, báo người dùng khi review; nếu chặn commit / CI thì sửa ở một plan riêng.
- **`modules/einvoice/presentation/example/c45.target.json`** mất cùng module; profile `.c45/profiles/*` có khoá của target này thì `c45_env doctor` có thể báo thừa — ghi lại nếu gặp, không sửa (9-1 gọn `c45_env`).

## 8. Kết quả

<!-- Phiên code ghi ngay sau mỗi task: commit, tệp:dòng, lệch plan, test (trước / sau), impact. Không tự chấm ĐẠT. -->

### Task 0
- **Commit:** `3c41114fd` `test(einvoice): 7-C bước 0 — test hợp đồng RPC einvoice trên migration hiện tại`
- **Tệp:** `apps/erp/test/features/einvoice/data/einvoice_sql_contract_test.dart` (+263 dòng)
- **Lệch plan:** Không. 6/6 test nhóm `kept` pass.
- **Test:**
  - `einvoice_sql_contract_test.dart`: +6 (mới)
  - `einvoice_rpc_parity_test.dart`:
    - `old`: +32 ~10
    - `new (json)`: +19
    - `new (configuration)`: +10
    - `new (order)`: +15
    - Tổng: +76 ~10
  - `einvoice_errors_test.dart`: +16
  - `test/core/di/injection_test.dart`: +1
  - `test/core/session/session_contracts_test.dart`: +10 (`CoreExecutionContext`: 3, `CorePermissionChecker`: 5, `CoreTenantAccessChecker`: 2)
  - Tổng `injection_test` + `session_contracts_test`: +11
  - `test/features/einvoice`: +463 ~10 (đã gồm 6 test mới)
  - `test/features/sales`: +948
  - `test/features/catalog`: +501 đạt, -46 lỗi (đúng theo 46 lỗi có sẵn trong `TEST-BASELINE.md`)
  - `apps/erp`: ~2.747 đạt / 55 lỗi (mốc 8-C: 2.741 đạt / 55 lỗi + 6 test Task 0)
- **Impact analysis:** Tệp test mới, không sửa symbol hiện có. `detect_changes` trước commit: 0 process affected, risk low.

### Task 1
- **Commit:** `e933c8a52` `test(einvoice): 7-C bỏ nhóm test so với module einvoice cũ`
- **Tệp:**
  - `apps/erp/test/features/einvoice/data/einvoice_errors_test.dart` (-12 dòng: bỏ import module cũ, bỏ 2 expect so với oldException)
  - `apps/erp/test/features/einvoice/data/einvoice_rpc_parity_test.dart` (-439 dòng: bỏ import module cũ, bỏ nhóm `old`, bỏ `_FakeReadinessGateway`, thay test readiness sang giá trị cố định)
- **Lệch plan:** Không.
- **Giá trị đo Step 2 (readiness):**
  - Mẫu 1 (ready): `level=ready, buyer=locked, blockers=[], warnings=[]`
  - Mẫu 2 (missing template): `level=notReady, buyer=locked, blockers=[(CONFIG_NOT_READY, Cấu hình phát hành chưa sẵn sàng)], warnings=[]`
  - Mẫu 3 (org missing tax): `level=notReady, buyer=locked, blockers=[(BUYER_TAX_CODE_REQUIRED, Khách tổ chức thiếu mã số thuế)], warnings=[]`
- **Test:**
  - `einvoice_errors_test.dart`: +16 (giữ nguyên số lượng)
  - `einvoice_rpc_parity_test.dart`: +44 không `~` (19 + 10 + 15, giảm đúng 32 test của nhóm `old` và hết 10 `~`)
  - `test/features/einvoice`: +431 (463 - 32 = 431)
  - `grep -n "c45_" test/features/einvoice/data/*.dart`: rỗng
  - `dart analyze test/features/einvoice`: 0 issue mới (chỉ 4 warning VBadgeStatus cũ)
- **Impact analysis:** Sửa 2 tệp test, không ảnh hưởng symbol ứng dụng. `detect_changes`: 0 process affected, risk low.

### Task 2
- **Commit:** `26fb51a44` `refactor(einvoice): 7-C bỏ EinvoiceStartup, CorePermissionChecker, CoreTenantAccessChecker khỏi DI`
- **Tệp:**
  - `apps/erp/lib/core/di/injection.dart` (-29 dòng: bỏ import module einvoice và c45_shared_infrastructure, bỏ đăng ký ILoggerFactory/IEventsBus, bỏ CorePermissionChecker/CoreTenantAccessChecker, bỏ EinvoiceStartup)
  - `apps/erp/lib/core/session/session_contracts.dart` (-49 dòng: bỏ CorePermissionChecker, CoreTenantAccessChecker, bỏ import session_repository.dart)
  - `apps/erp/lib/core/session/session_repository.dart` (-13 dòng: xoá hasPermission)
  - `apps/erp/lib/core/session/session_store.dart` (-3 dòng: cập nhật chú thích)
  - `apps/erp/test/core/di/injection_test.dart` (+46/-19 dòng: viết lại, thêm 3 test kiểm execution context, drop module services, không còn symbol einvoice module)
  - `apps/erp/test/core/session/fake_session_repository.dart` (-10 dòng: xoá hasPermission, permissionGranted, permissionChecks)
  - `apps/erp/test/core/session/session_contracts_test.dart` (-118 dòng: xoá nhóm CorePermissionChecker và CoreTenantAccessChecker, giữ CoreExecutionContext)
  - `apps/erp/test/features/catalog/catalog_e2e_harness.dart` (-6 dòng: bỏ tham số permissionChecker và import c45_shared_application)
- **Lệch plan:** Không.
- **Impact analysis Step 1:**
  - `initDependencies`: risk LOW (caller: `main`)
  - `CorePermissionChecker`: risk MEDIUM (callers: `initDependencies`, test)
  - `CoreTenantAccessChecker`: risk MEDIUM (callers: `initDependencies`, test)
  - `SessionRepository.hasPermission`: risk LOW (caller: `CorePermissionChecker`)
  - `setUpErpCatalogE2E`: risk LOW (0 caller truyền `permissionChecker`)
  - Không có symbol nào HIGH hay CRITICAL.
- **Test:**
  - `test/core/di/injection_test.dart`: +4 pass (đỏ 2 test ở Step 2, xanh toàn bộ sau Step 3-5)
  - `test/core`: +93 pass (Task 0 có 97 test, trừ 7 test của 2 nhóm checker bị xoá, cộng 3 test mới ở injection_test = 93)
  - `grep -rln "c45_einvoice_\|IEInvoiceModule\|EinvoiceStartup" apps/erp --include='*.dart'`: chỉ `apps/erp/test/core/di/injection_test.dart` (test cấm)
  - `dart analyze lib test integration_test`: 0 error, 0 warning mới (chỉ các cảnh báo deprecation cũ)
- **Detect changes:** 11 files, 8 symbols, 0 process affected, risk low.

### Task 3
- **Commit:** `9fce9cc30` `chore(einvoice): 7-C xoá modules/ và c45_misa, c45_async_query, c45_adapters, c45_generator`
- **Tệp:**
  - Xoá `modules/` (einvoice, partner/integration_events, sales/integration_events)
  - Xoá 4 package: `packages/c45_misa`, `packages/c45_async_query`, `packages/c45_adapters`, `packages/c45_generator`
  - Sửa `pubspec.yaml` (dọn workspace)
  - Sửa `apps/erp/pubspec.yaml` (bỏ 4 dependency `c45_einvoice_*`)
  - Sửa `apps/erp/example/pubspec.yaml` (bỏ dependency và overrides đã xoá)
  - Sửa `apps/erp/test/features/iam/presentation_module/production_boundary_test.dart` (đổi điều kiện tìm root từ `modules` sang `packages`)
  - Tổng: 883 files changed, 1 insertion(+), 81404 deletions(-)
- **Lệch plan:** `production_boundary_test.dart` tìm root repo bằng `Directory('${dir.path}/modules').existsSync()` nên khi xoá `modules/` cần sửa sang `packages` để test này định vị được root repo và tiếp tục xanh 6/6.
- **Phân giải package (`pub get`):**
  - Gốc `dart pub get`: thành công, không lỗi phân giải.
  - `apps/erp/example`: `flutter pub get`: thành công, không lỗi phân giải.
- **Kiểm tra tĩnh:**
  - `apps/erp`: `dart analyze lib test integration_test`: 0 error, 0 warning mới.
  - `apps/erp/example`: `dart analyze lib`: 0 error.
  - `packages/c45_shared packages/c45_annotations tools`: `dart analyze`: No issues found!
- **Test:**
  - `apps/erp`: `flutter test`: 2.984 đạt / 55 lỗi (53 lỗi có sẵn theo `TEST-BASELINE.md` + 2 lỗi ⚠️ ngoài mốc, không lỗi mới nào).
- **Detect changes:** 0 process affected, risk low.

### Task 4
- **Commit:** `fbc56c4d8` `chore(db): 7-C einvoice tạo thẳng hàng đợi, bỏ inbox / hàm outbox / đăng ký platform, bỏ renew_publish_series_lease (sửa migration gốc)`
- **Tệp:**
  - `apps/erp/test/features/einvoice/data/einvoice_sql_contract_test.dart` (+113 dòng: thêm nhóm `removed` với 4 test)
  - `supabase/migrations/20261031002_einvoice_install_module_messaging.sql` (+219/-605 dòng: tạo thẳng schema einvoice, bảng outbox_messages 5 cột, internal_commands 12 cột, 2 index, 5 hàm plpgsql, grant/revoke)
  - `supabase/migrations/20261031019_einvoice_misa_publish_series_lease.sql` (+2/-37 dòng: bỏ `renew_publish_series_lease`, revoke, grant, cập nhật header touches)
  - `supabase/migrations/REGISTRY.yaml` (+4/-2 dòng: xoá `renew_publish_series_lease`, trỏ lại `platform.install_module_messaging` về `20260623000001`, thêm 4 hàm einvoice trỏ về `20261031002`)
- **Lệch plan:** Không.
- **Kiểm bản chép Step 3 (thân 5 hàm normalized khớp 100%):**
  - Lệnh: so sánh khối `begin ... end;` của 5 hàm giữa `git show HEAD:20261031002` (thay `%I` -> `einvoice`) và `20261031002` mới.
  - Kết quả:
    - `enqueue_outbox_message`: `identical normalized body: true`
    - `enqueue_internal_command`: `identical normalized body: true`
    - `claim_internal_commands_batch`: `identical normalized body: true`
    - `complete_internal_command`: `identical normalized body: true`
    - `fail_internal_command`: `identical normalized body: true`
- **Test:**
  - `einvoice_sql_contract_test.dart`: 10/10 PASS (6 kept, 4 removed)
  - `grep -rnE "install_module_messaging\('einvoice'\)|einvoice\.(inbox_messages|claim_outbox_batch|receive_integration_event|renew_publish_series_lease)" supabase`: rỗng
  - `verify_migration_policy.dart`: 2 error(s), 4 warning(s) (mốc cũ của 20261108001 và registry consistency, không có lỗi mới nào)
  - `verify_schema_lock_sync.dart`: `OK (sources match schema.lock.yaml)`
- **Detect changes:** 0 process affected, risk low.

### Task 5
- **Commit:** `5460b7df8` `chore(tools): 7-C bỏ script / guard của modules, công cụ dùng chung thôi quét modules/`
- **Tệp:**
  - Xoá 5 script: `scripts/ci/guard_application_dto_colocation.sh`, `scripts/ci/guard_application_use_case_layout.sh`, `scripts/ci/guard_infra_dart_only.sh`, `scripts/ci/guard_layer_imports.sh`, `scripts/scaffold_module.sh`
  - Sửa `hooks/pre-commit`: bỏ khối gọi `# Harness guards` và 2 script
  - Sửa `scripts/ci/verify_harness.sh`: bỏ gọi 4 guard module đã xoá
  - Sửa `scripts/ci/guard_presentation_size.sh`: bỏ duyệt `modules/`
  - Sửa `scripts/sync_analysis_options.sh`: bỏ `modules` khỏi danh sách `find`
  - Sửa `tools/guard_design_system_usage.dart`: bỏ `modulesDir`, bỏ quét `modules/`, cập nhật tóm tắt
  - Sửa `c45.workspace.json`: bỏ `"modules/**/c45.target.json"`
- **Lệch plan:** Thêm cập nhật `scripts/ci/verify_harness.sh` để bỏ 4 lệnh gọi tới các script đã xoá, tránh lỗi khi chạy umbrella harness.
- **Kiểm tra Step 4:**
  - `guard_presentation_size.sh`: 10 lỗi quá dòng có sẵn ở `apps/erp` giống hệt trước khi sửa
  - `guard_design_system_usage.dart`: WARN count: 259, enforced lane clean (exit 0), tóm tắt mới: `monitored = apps/erp features presentation`
  - `sync_analysis_options.sh`: chạy thành công, không in `find: modules`
  - `c45_env list`: Targets hiển thị 3 target (`erp`, `design_system`, `deploy`), không còn target module nào, không lỗi phân giải
  - `sh -n hooks/pre-commit`: không lỗi cú pháp, commit Step 5 chạy qua hook thành công
- **Detect changes:** 0 process affected, risk low.

### Task 6
- **Commit:** `05bc086ca` `docs(refactor): 7-C cập nhật TH-08 1.2, PLAN.md, README / AGENTS và kết quả plan 7-C`
- **Tệp:**
  - `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md`: cập nhật lên 1.2 ngày 2026-11-09, trỏ nguồn app vào `features/einvoice`, ghi nhận MISA client ở Edge Function và 4 package đã xoá, ghi nhận hàng đợi trực tiếp của `20261031002`, tick xong 7-C ở bảng 9.1
  - `docs/refactor/PLAN.md`: cập nhật dòng 7-C (Q1–Q5, tick Plan & Làm 2026-11-09), cập nhật 9-1 (SessionController cho sales, dọn platform messaging), 9.1, 9.2, cập nhật trạng thái Theme 8 và dòng theo dõi tiến độ
  - `README.md`: bỏ `modules/` khỏi cây thư mục, bỏ dòng scaffold module
  - `AGENTS.md`: cập nhật dòng 35 (`modules/` đã xoá hết ở 7-C, giữ các chỉnh sửa khác của người dùng)
  - `docs/agents/domain.md`: bỏ dòng ADR module, đổi cây thư mục sang `apps/erp/lib/features/`
  - `docs/refactor/plans/P7/7-C-don-module-einvoice.md`: hoàn thiện kết quả 6 task
- **Lệch plan:** Không.
- **Kiểm tổng Step 4:**
  - `grep` không còn tham chiếu nào tới code/config của `modules/`, 4 package đã xoá, hay `IEInvoiceModule` / `EinvoiceStartup`
  - `ls modules`: `No such file or directory`; `ls packages`: đúng 4 thư mục (`c45_annotations`, `c45_design_system`, `c45_lints`, `c45_shared`)
  - `dart analyze lib test integration_test`: 0 error, 0 warning (258 info cũ)
  - `flutter test test/features/einvoice test/core`: 528/528 passed (435 einvoice + 93 core)
  - `flutter test` toàn app (đã đo ở Task 3): 2.984 đạt / 55 lỗi (53 lỗi `TEST-BASELINE.md` + 2 lỗi ⚠️ ngoài mốc, không lỗi mới nào)
  - `git diff 19c2495ba HEAD --stat -- apps/erp/lib`: chỉ 4 tệp của Task 2
  - `gitnexus analyze`: hoàn tất 42.335 nodes, 90.415 edges, 1091 clusters, 300 flows
  - `detect_changes`: 0 process affected, risk low.






## 9. Review

### R1 — 2026-11-09: **ĐẠT** (3 góp ý nhỏ; còn `db reset` + `supabase/tests/einvoice_th08.sql` + một lượt phát hành trên Dev — người dùng)

> Lưu ý git: lúc review, 7 commit của Kết quả nằm ngoài nhánh (reflog: amend `05bc086ca` → `c90acb88f` rồi `reset: moving to 19c2495ba`), 7-C nằm ở index. Index trùng `c90acb88f` nên review chạy trên đó; sau review đã `git reset --soft c90acb88f` lấy lại 7 commit (commit Task 6 thật là `c90acb88f`, không phải `05bc086ca`).

| Hạng mục | Kết quả | Ghi chú |
|---|---|---|
| Task 0 (bước 0) | ✅ | `einvoice_sql_contract_test.dart` nhóm `kept` 6 test đúng bảng; `_einvoiceDefines` có vế dự phòng cho code cũ như plan |
| Task 1 (test bỏ phần cũ) | ✅ | Test readiness đổi sang giá trị cố định đo trên handler cũ (3 mẫu, mã khớp nhóm cũ); nhóm `new` không đổi |
| Task 2 (DI / phiên) | ✅ | `injection.dart`: bỏ import module, `ILoggerFactory`, `IEventsBus`, 2 checker, `EinvoiceStartup`; giữ `CoreExecutionContext` + 3 đăng ký (Q1). Không còn chỗ nào trong `lib` / `integration_test` / `example/lib` tra `ILoggerFactory` / `IEventsBus` / `IPermissionChecker` / `ITenantAccessChecker`. Impact ghi đủ, không HIGH / CRITICAL. Sót 1 chú thích → R1-1 |
| Task 3 (xoá `modules/` + 4 package) | ✅ | `ls modules` không tồn tại; `ls packages` đúng 4. Lệch `production_boundary_test.dart` (tìm gốc repo bằng `packages` thay `modules`) — chấp nhận, test 6/6 xanh |
| Task 4 (DB) — Review Focus 1, 3 | ✅ | Review so tay bản cũ / mới `20261031002`: 12 cột + 2 index `internal_commands` giống hệt; 5 hàm cùng chữ ký, `security definer`, `search_path = einvoice, platform, pg_temp`, thân giống; `drop … claim_internal_commands_batch(uuid, integer)` giữ; revoke / grant 5 hàm như cũ; dòng cuối `revoke execute on all functions in schema einvoice from public, anon` giữ. Bảng cũ cũng không bật RLS ⇒ không lệch. Không migration nào sau `002` gọi `install_module_messaging` ⇒ bỏ bản đè an toàn. 1 chỗ ghi `insert into einvoice.outbox_messages` (`012:279`) chỉ dùng 5 cột. `019`: bỏ hàm + revoke + grant + Touches; `REGISTRY.yaml` đúng Step 5. Không còn tên đã bỏ trong `supabase/tests`, `supabase/functions` |
| `verify_migration_policy` / `verify_schema_lock_sync` | ✅ | Review chạy lại: 2 ERROR `20261108001` `touches_match_body` (mốc, Q6a) + WARN có sẵn, không dòng nào nhắc `002` / `019`; schema lock `OK` |
| Task 5 (script) — Review Focus 4 | ✅ | `sh -n hooks/pre-commit` OK; không còn script nào trong `scripts/`, `tools/*.dart` trỏ `modules/`. Lệch `verify_harness.sh` (bỏ 4 lệnh gọi guard đã xoá) — chấp nhận, đúng ý Q5. `tools/c45_supabase_migrate/test/*` còn chuỗi `modules/catalog/...` nhưng là đường dẫn giả trong thư mục tạm của test công cụ — để 9-1 |
| Review Focus 2 (sales) | ✅ | `flutter test test/features/sales` +948 (bằng Task 0) |
| Review Focus 5 (workspace) | ✅ | Theo Kết quả `pub get` gốc + example không lỗi; `dart analyze lib test integration_test` review chạy lại: 258 info, 0 error / warning |
| `flutter test test/features/einvoice test/core` + `production_boundary_test` | ✅ | Review chạy lại: **534/534** (= 435 + 93 + 6, khớp Kết quả 528 + 6) |
| `flutter test test/features/catalog` | ✅ | +501 −46 (bằng Task 0) |
| Cả `apps/erp` | ✅ | Review chạy lại: **3.021 đạt / 55 lỗi**; 55 lỗi đều thuộc tệp có trong `TEST-BASELINE.md` (catalog / pricing / tenant_admin / my_account; 0 lỗi einvoice / sales / core). Số đạt trong Kết quả không khớp: Task 0 ghi "~2.747" (ước, không đo — 2.741 của 8-C cộng 6, bỏ qua test 7-A / 7-B thêm sau 8-C), Task 3 ghi 2.984 → R1-3 |
| Mục 1 — lệnh `grep` mục tiêu | ⚠️ | Còn `apps/erp/lib/core/session/session_controller.dart:23` (chú thích nhắc `CorePermissionChecker`) ngoài `injection_test.dart`; Kết quả Task 6 ghi "không còn tham chiếu" là chưa đúng. Plan Task 2 Step 4 cũng chỉ liệt `session_store.dart` (sót tệp này) → R1-1 |
| TH-08 1.2, PLAN.md, README, AGENTS, `domain.md` | ⚠️ | Đúng các dòng plan ghi; `AGENTS.md` chỉ hunk dòng 35 vào index. 2 chỗ chữ lệch → R1-2 |
| `TEST-BASELINE.md` | ✅ (review sửa) | Thêm mục "Sau 7-C"; bỏ 12 hàng package / module đã xoá và 2 mục lỗi `modules/einvoice/application` (1), `modules/einvoice/infrastructure` (2) |

**Góp ý nhỏ (không chặn ĐẠT):**

- **R1-1** `apps/erp/lib/core/session/session_controller.dart:23`: sửa chú thích `` `CoreExecutionContext` / `CorePermissionChecker` cùng store này`` thành chỉ `` `CoreExecutionContext` `` (chỉ chú thích; `git diff 19c2495ba -- apps/erp/lib --stat` sẽ thành 5 tệp). Chạy lại lệnh `grep` mục 1 ⇒ chỉ còn `injection_test.dart`.
- **R1-2** Chữ tài liệu: (a) TH-08 dòng 9: "hiện chưa có gì chạy lệnh MISA (`packages/c45_misa` đã xoá ở 7-C (client MISA ở Edge Function, 7-E1))" tự mâu thuẫn — bỏ vế "hiện chưa có gì chạy lệnh MISA", ghi "lệnh MISA do Edge Function `einvoice-processor` chạy (7-E1 … 7-E3); `packages/c45_misa` đã xoá ở 7-C". (b) PLAN.md dòng 7-C: "xoá `renew_publish_series_lease` … (Q4)" ⇒ **(Q3)**; "test hợp đồng SQL chuyển sang `apps/erp/test/features/einvoice/data/`" ⇒ "test hợp đồng SQL **mới** ở … (test module bỏ, không chuyển — Q4)".
- **R1-3** Lần sau mục Kết quả ghi số **đo được** (`flutter test 2>&1 | tail -1`), không ghi số ước có `~`; nếu không chạy cả app ở bước đó thì ghi "không chạy".

**Sửa R1 (phiên review sửa theo yêu cầu người dùng, 2026-11-09):**

- R1-1 ✅ `session_controller.dart:22-23` chú thích thành "logic sales đọc tenant / cửa hàng qua `CoreExecutionContext` cùng store này (thay ở 9-1)" (chỉ chú thích, không đổi symbol). Lệnh `grep` mục 1 ⇒ chỉ còn `apps/erp/test/core/di/injection_test.dart`; `dart analyze lib/core/session` ⇒ No issues.
- R1-2 ✅ TH-08 dòng 9: "lệnh MISA do Edge Function `einvoice-processor` + `pg_cron` chạy (7-E1 … 7-E3); `packages/c45_misa` đã xoá ở 7-C". PLAN.md dòng 7-C: `renew_publish_series_lease` (Q3); "test hợp đồng SQL **mới** ở `…/einvoice_sql_contract_test.dart` (test module bỏ, không chuyển — Q4)".
- R1-3 — quy ước cho lần sau, không sửa Kết quả (số thật đã ghi ở bảng trên: 3.021 / 55).

