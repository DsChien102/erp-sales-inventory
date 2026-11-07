# 8-C — Dọn sạch module sales

> Theme 5 (mã cũ P8) · Bước (dọn) theo "Quy tắc dọn module (chốt 2026-10-11)" của PLAN.md
> Trạng thái: Plan ✅ (viết + người dùng duyệt 2026-11-08) | Làm ⬜ | Review ⬜
> Làm **sau** 8-A1…8-A4, 8-B1…8-B3 (đã commit, review đạt).
> Tài liệu: PLAN.md mục Theme 5 dòng 8-C, "Quy tắc dọn module", "Quy tắc migration", "Plan xoá / tách / thay code cũ", "Plan chuyển kiến trúc: giữ nghiệp vụ"; TH-05 mục 3, 6.1, 6.2, 9.1, BR-36, KI-12…14; 8-A1 (chép kiểu ở 8-C); mẫu đã làm: 6-C (`docs/refactor/plans/P6/6-C-don-module-pricing.md`), 4-C (outbox).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** App hết `vet45_sales_{domain,application,infrastructure}` (lib, test, integration test, `apps/erp/example`, pubspec); xoá 3 package đó; DB schema `sales` bỏ phần messaging, giữ `sales.outbox_messages` làm nhật ký sự kiện của đơn.

**Architecture:** Không đổi nghiệp vụ. Test đang chạy qua `ISalesModule` chuyển sang fake repository có sẵn (Task 1), nhóm test `old` bỏ (Task 2), rồi chép 61 tệp DTO / enum của module vào `lib/features/sales/data/models/contracts/` và đổi import một lượt (Task 3), xoá module (Task 4), sửa migration gốc (Task 5). Thứ tự này bắt buộc: chép kiểu trước khi bỏ cầu module ⇒ test cầu lỗi biên dịch (module trả DTO của module, repository trả DTO của app).

**Tech Stack:** Flutter / Dart (`flutter_test`, `bloc_test`), Supabase Postgres (plpgsql), `tools/vet45_supabase_migrate`.

**Spec:** [TH-05](../../../02-yeu-cau/TH-05-ban-hang-va-don-hang.md) (mục 3, 6.1, 6.2, 9.1, BR-36); quyết định ở mục 2 dưới đây (người dùng chốt 2026-11-08).

## Global Constraints

- **Không đổi nghiệp vụ.** `apps/erp/lib` chỉ đổi: dòng `import` (Task 3), 61 tệp chép mới + barrel (Task 3), `core/di/injection.dart` bỏ `SalesStartup` / `ISalesModule` (Task 4). Không RPC nào đổi chữ ký / thân hàm.
- **Giữ** `modules/sales/integration_events` (einvoice dùng, 7-5 xoá), `CoreExecutionContext` / `CorePermissionChecker` / `CoreTenantAccessChecker` (einvoice dùng, 7-5 xoá — Q5), `vet45_shared_*` (9-1), `modules/einvoice`, `modules/partner/integration_events`.
- Test giữ hành vi (PLAN "Plan xoá / tách / thay code cũ"): được đổi **cách dựng** (module → fake repository), **không** đổi điều kiện kiểm, trừ đúng các ngoại lệ ở Q3.
- Migration: **sửa migration gốc**, không tạo migration mới. Phiên code **không** chạy / không đề nghị `supabase db reset`, reset Dev, chạy SQL; việc DB là của người dùng, plan không ghi bước DB nào.
- Trước khi sửa mỗi symbol Dart trong `lib`: `node .gitnexus/run.cjs impact <symbol> --direction upstream --repo erp-sales-inventory`, ghi vào Kết quả. Trước mỗi commit: `detect_changes`.
- `flutter analyze` sập vì đường dẫn có dấu: dùng `dart analyze`.
- Tìm kiếm dùng `grep -r` (không `git grep`); trong zsh luôn đặt `--include='*.dart'` trong nháy.
- Đếm test của một tệp: `flutter test <tệp> 2>&1 | tail -1` ⇒ ghi số `+N` (và `-M` nếu có).
- Ghi Kết quả (mục 8) ngay sau mỗi task theo mẫu: tệp:dòng, lệch plan, test (số trước / sau), impact. Phiên code không tự chấm ĐẠT.

## Review Focus

1. **Tệp chép lệch bản gốc** (thiếu trường, sai enum `sales_contract_enums.dart`, đổi `fromJson` / `==`) ⇒ mapper JSON trả sai âm thầm. Test: Task 3 Step 2 `diff` từng tệp với bản gốc = chỉ khác dòng `import`; nhóm `new` của parity xanh, số test không đổi.
2. **Chuyển test mà nới điều kiện kiểm** (bỏ `expect`, đổi giá trị mong đợi, bỏ test). Test: Task 1 mỗi tệp ghi số test trước / sau (bằng nhau) + số dòng `expect(` trước / sau; chỉ được giảm đúng số assert `tenantId` / `actorId` (Q3c), ghi từng chỗ.
3. **Fake ném lỗi khác cầu cũ** (cầu đổi `SalesContractException` → `AppException`, `PERMISSION_DENIED` → `NO_PERMISSION`, blocker DTO → map) ⇒ test lỗi đổi nghĩa. Test: Task 1 Step 1 `sales_contract_error_test.dart` chốt hàm đổi lỗi dùng chung, so với `_bridge` cũ.
4. **Bỏ nhầm cột / quyền của `sales.outbox_messages`** ⇒ RPC ghi sự kiện lỗi lúc chạy (plpgsql không kiểm lúc `create`), Lịch sử đơn trống. Test: Task 0 `outbox writers use only id, tenant_id, event_type, payload` + `timeline and settlement guard read sales.outbox_messages`; Task 5 `creates sales.outbox_messages directly`.
5. **Workspace còn trỏ package đã xoá** ⇒ `pub get` gốc / `apps/erp/example` / einvoice example lỗi. Test: Task 4 Step 5.

---

## 1. Mục tiêu

- `grep -rnE "vet45_sales_(domain|application|infrastructure)|ISalesModule|SalesStartup|FakeSalesModule|SalesFeShellModule" apps packages tools pubspec.yaml --include='*.dart' --include='*.yaml'` rỗng.
- `ls modules/sales` = `integration_events`.
- Schema `sales` không còn `inbox_messages`, `internal_commands`, 12 hàm hàng đợi; `sales.outbox_messages` còn, 5 cột, đọc / ghi như cũ.
- TH-05 lên 3.1 ghi đúng hiện trạng; PLAN.md: dòng 8-C, 7-5 (nhận Q5).

## 2. Quyết định

| Q | Nội dung |
|---|---|
| Q1 | **Người dùng chốt 2026-11-08: giữ `sales.outbox_messages` làm nhật ký sự kiện của đơn.** Lý do: `get_sales_order_timeline` (`20260830010:1496`, BR-36) đọc nó để dựng Lịch sử đơn; `_record_settlement_changed…` (`20260830006:363`) dùng nó chống ghi trùng. Bỏ `install_module_messaging('sales')` ở `20260623000002:4` và `20260830005:11`; `20260830005` tự `create schema if not exists sales` + `create table if not exists sales.outbox_messages` với đúng 5 cột `id uuid primary key`, `tenant_id uuid not null`, `event_type text not null`, `payload jsonb not null`, `occurred_at timestamptz not null default now()`; index `sales_outbox_messages_order_idx on sales.outbox_messages (tenant_id, (payload ->> 'salesOrderId'), occurred_at)`; `alter table … enable row level security` + `revoke all on sales.outbox_messages from public, anon, authenticated` (giữ quyền như bản cài cũ: `20260623000001:691`). Không đổi tên bảng, không đổi câu insert / đọc nào. Danh sách `v_allowed` của `platform.install_module_messaging` **không** sửa (P9, như 4-C) |
| Q2 | **Người dùng chốt 2026-11-08: chép 1:1 + barrel.** 61 tệp ở bảng mục 3 chép nguyên vào `apps/erp/lib/features/sales/data/models/contracts/<cùng tên tệp>`; chỉ sửa dòng `import` nếu có (các tệp chỉ import lẫn nhau bằng đường tương đối ⇒ giữ nguyên). Barrel `apps/erp/lib/features/sales/data/models.dart` `export` đủ 61 tệp theo thứ tự chữ cái. Không đổi tên lớp / trường / thân hàm. Không chép 12 tệp còn lại của `src/shared` (app không dùng; test chỉ dùng trong fixture / nhóm `old` sẽ bỏ) |
| Q3 | **Chuyển 14 test dùng module sang fake repository** (`test/features/sales/support/fake_*_repository.dart`, có sẵn đủ method — đo 2026-11-08). (a) Ánh xạ query / command → method fake theo bảng Task 1. (b) Lỗi: nơi module cũ ném `SalesContractException(code, message, details)` thì fake ném `salesContractError(code, message: …, details: …)` (Task 1 Step 1) — cùng kết quả như `_bridge` cũ. (c) **Ngoại lệ đổi điều kiện kiểm (đổi có chủ đích, người dùng chốt 2026-11-08):** assert trên `tenantId` / `actorId` của query / command bị bỏ, vì từ 8-A cầu đã gán cứng `'tenant-1'` / `'actor-1'` và repository thật lấy từ phiên — assert đó chỉ kiểm cầu. Ghi từng chỗ bỏ (tệp:dòng) vào Kết quả. (d) `CheckoutBlockerCodes.receivableDueDateRequired` thay bằng chuỗi `'RECEIVABLE_DUE_DATE_REQUIRED'` (giá trị ở `checkout_blocker_codes.dart:12`). (f) **Người dùng chốt 2026-11-08:** assert "không gọi `get_return_exchange_form_policy`" bỏ: `ReturnExchangeRepository` không có method đó và test `app RPC list matches repositories` (Task 0) đã chốt app không gọi RPC này (KI-10). (e) Fixture mặc định `SalesFakeContractFixtureFactory.create(...)` thay bằng `test/features/sales/support/sales_contract_fixtures.dart` (Task 1 Step 2). Xoá `module_backed_sales_repositories.dart` |
| Q4 | **Người dùng chốt 2026-11-08: 2 live test chuyển sang repository.** `sales_group_b_s06_s07_live_test.dart` dùng `di<SalesDraftRepository>()`, `sales_group_c_s08_s11_live_test.dart` dùng `di<SalesCheckoutRepository>()`; `on SalesContractException` → `on AppException` cùng mã (`STALE_DATA`, `REFERENCE_UNAVAILABLE` — repository giữ nguyên mã, `sales_draft_errors.dart:8-9`). Kiểm bằng `dart analyze integration_test` (live test mặc định skip) |
| Q5 | **Người dùng chốt 2026-11-08: `CoreExecutionContext` / `CorePermissionChecker` / `CoreTenantAccessChecker` dời sang 7-5.** `EinvoiceStartup.initialize` (`injection.dart:280-286`) còn nhận `permissionChecker`, `tenantAccessChecker`; 42 chỗ trong `lib` còn dùng `IExecutionContext` / `ICurrentUser` / … (einvoice). 8-C chỉ bỏ khối `SalesStartup` (`injection.dart:269-278`) + 2 import (`:5-6`) |
| Q6 | **Người dùng chốt 2026-11-08: không xoá RPC nào.** 6 RPC app không gọi giữ trong DB: `complete_return_exchange`, `get_return_exchange_form_policy`, `list_sales_order_cancellation_reasons`, `audit_sales_review_invariants`, `record_sales_refund` (KI-13), `get_order_integration_status` (KI-14). TH-05 6.2 / FR-03 sửa cho đúng (Task 6) |
| Q7 | **Người dùng chốt 2026-11-08: bỏ test của module, không chuyển test SQL nào sang app** (như 6-C Q4, 5-C Q8). `modules/sales/infrastructure` có 11 lỗi mốc (`TEST-BASELINE.md:162-174`, đọc `_drafts/`); hành vi SQL do `supabase/tests/sales_th05.sql` (8-B1) lo; test hợp đồng mới chỉ kiểm có / không có |

## 3. Hiện trạng (đo 2026-11-08, HEAD `735ed8704`)

| Thứ | Ai còn dùng |
|---|---|
| `apps/erp/lib` | 87 tệp import `vet45_sales_application` (chỉ dùng kiểu trong `src/shared`); `core/di/injection.dart:5-6, 269-278` (`SalesStartup`, `ISalesModule`) |
| `apps/erp/test`, `integration_test` | 75 tệp. Phân loại ở bảng dưới |
| `apps/erp/example/lib/sales/preview` | 5 tệp, chỉ DTO: `fixtures.dart` (`as app`), `sales_return_exchange_{session,settlement,detail}_preview_section.dart`, `sg13_return_result_tab.dart` |
| Workspace | `pubspec.yaml:20-22` (giữ `:23` integration_events); `apps/erp/pubspec.yaml:22-24`; `apps/erp/example/pubspec.yaml:17-18` (dependency), `:56-61` (override; giữ `:62-63`) |
| einvoice | chỉ `vet45_sales_integration_events` (`modules/einvoice/{application,infrastructure}/pubspec.yaml`, `presentation/example/pubspec.yaml:55-56`) |
| DB messaging sales | `20260623000002:4`, `20260830005:11` gọi `install_module_messaging('sales')`. 20 câu `insert into sales.outbox_messages(id, tenant_id, event_type, payload)` (8 tệp); 2 chỗ đọc (`20260830006:363`, `20260830010:1496`). 0 chỗ dùng `sales.inbox_messages` / `internal_commands` / `enqueue_*` / `claim_*` / cột `processed_at`… `REGISTRY.yaml` mục `sales:` (`:364`) không có hàm hàng đợi |
| `verify_migration_policy` | 0 error, 3 `[WARN] registry_consistency` có sẵn (`20261101001` ×1, `20261104001` ×2); `verify_schema_lock_sync`: OK |
| `TEST-BASELINE.md` | `:34, :45-47` (4 hàng module sales), `:162-174` (11 lỗi `modules/sales/infrastructure`) |

**61 tệp chép (Q2)** — thư mục `modules/sales/application/lib/src/shared/`:
`actor_snapshot_dto`, `available_post_sale_actions_dto`, `cancellation_precheck_dto`, `cancellation_reason_dto`, `checkout_line_input`, `checkout_monetary_summary_dto`, `checkout_precheck_dto`, `checkout_result_dto`, `checkout_result_view_dto`, `customer_snapshot_dto`, `money_dto`, `opaque_cursor_page_dto`, `paged_sales_order_list_dto`, `payment_intent_input`, `payment_intent_summary_dto`, `product_snapshot_dto`, `product_unit_snapshot_dto`, `quantity_dto`, `receivable_requirement_dto`, `return_exchange_detail_dto`, `return_exchange_detail_line_dto`, `return_exchange_draft_dto`, `return_exchange_line_input`, `return_exchange_precheck_dto`, `return_exchange_pricing_preview_dto`, `return_exchange_result_dto`, `return_exchange_settlement_plan_dto`, `return_exchange_summary_dto`, `return_exchange_valuation_dto`, `returnable_order_line_dto`, `returnable_order_lines_dto`, `sales_blocker_dto`, `sales_commercial_snapshot_input`, `sales_contract_enums`, `sales_order_cancellation_detail_dto`, `sales_order_cancellation_result_dto`, `sales_order_current_line_dto`, `sales_order_detail_dto`, `sales_order_draft_dto`, `sales_order_draft_for_restore_dto`, `sales_order_draft_line_dto`, `sales_order_draft_line_input`, `sales_order_dto`, `sales_order_line_dto`, `sales_order_list_facets_dto`, `sales_order_list_filter_input`, `sales_order_list_item_dto`, `sales_order_payment_original_breakdown_dto`, `sales_order_payment_return_slip_breakdown_dto`, `sales_order_payment_summary_dto`, `sales_order_result_dto`, `sales_order_return_summary_dto`, `sales_order_settlement_dto`, `sales_order_timeline_dto`, `sales_payment_transaction_dto`, `sales_payment_transactions_dto`, `sales_receipt_document_dto`, `sales_receipt_dto`, `sales_receipt_line_dto`, `sales_receipt_settlement_snapshot_dto`, `store_snapshot_dto` (đuôi `.dart`).

**Test — phân loại** (đường dẫn dưới `apps/erp/`):

| Nhóm | Tệp | Việc |
|---|---|---|
| A. Dùng module làm nguồn dữ liệu (Task 1) | `test/features/sales/presentation/sales_checkout_page_test.dart` (934 dòng); `test/features/sales/presentation_module/bloc/` `sales_order_detail_cubit_test.dart` (1849), `sales_order_list_cubit_test.dart` (436), `sales_return_exchange_detail_cubit_test.dart` (283), `sales_return_exchange_session_cubit_test.dart` (800), `sales_return_exchange_settlement_cubit_test.dart` (656), `sales_transaction_result_cubit_test.dart` (746); `test/features/sales/presentation_module/widgets/sales_transaction_result_body_test.dart` (553); `test/features/sales/` `sales_flow_pages_test.dart` (1652), `sales_order_detail_page_test.dart` (989), `sales_return_exchange_detail_page_test.dart` (249), `sales_return_exchange_result_page_test.dart` (217), `sales_return_exchange_slip_preview_page_test.dart` (187), `sales_transaction_result_page_test.dart` (210) — 14 tệp; cầu `test/features/sales/support/module_backed_sales_repositories.dart` (580) | fake repository (Q3) |
| B. Nhóm `old` (Task 2) | `test/features/sales/data/`: `return_exchange_rpc_parity_test.dart` (nhóm `return exchange rpc parity (old)` 48-469), `sales_cancellation_rpc_parity_test.dart` (48-165), `sales_checkout_errors_test.dart` (`old` 60-73), `sales_checkout_rpc_parity_test.dart` (28-114), `sales_draft_rpc_parity_test.dart` (167-hết), `sales_order_inquiry_rpc_parity_test.dart` (42-223), `sales_order_read_errors_test.dart` (45-62), `sales_payment_rpc_parity_test.dart` (28-95), `sales_receipt_errors_test.dart` (54-74), `sales_receipt_rpc_parity_test.dart` (38-159); `test/features/sales/logic/sales_checkout_rules_test.dart` (80-107), `sales_draft_rules_test.dart` (211-hết) — 12 tệp | xoá nhóm `old` |
| C. Live / DI (Task 2, 4) | `integration_test/sales_group_b_s06_s07_live_test.dart`, `sales_group_c_s08_s11_live_test.dart` (Q4); `test/core/di/sales_runtime_registration_test.dart` (Task 4) | chuyển / viết lại |
| D. Chỉ dùng DTO (Task 3) | các tệp còn lại trong danh sách 75 (gồm `integration_test/sales_group_a_s03_s05_live_test.dart` `as sales`, 7 `support/fake_*`) | đổi import |

`test/features/sales/group_f_no_demo_contract_test.dart` chỉ chứa chuỗi `'SalesFeShellModule'` trong danh sách cấm — không đổi.

## 4. Đang làm gì (thứ bị xoá / thay)

| # | Thứ cũ đang làm | Sau khi sửa nằm ở đâu | Test giữ hành vi |
|---|---|---|---|
| 1 | `_bridge` (`module_backed_sales_repositories.dart:19-50`): bắt `SalesContractException` ⇒ `AppException(code == 'PERMISSION_DENIED' ? 'NO_PERMISSION' : code, serverMessage: message, details: …)`; `details['blockers']` là `SalesBlockerDto` ⇒ map `{code, message, field}`, là `Map` ⇒ `cast`; không có `blockers` ⇒ `Map.from(details)`; `details` rỗng ⇒ `null` | `salesContractError(...)` ở `test/features/sales/support/sales_contract_error.dart` (Task 1 Step 1) | `sales_contract_error_test.dart` (Task 1 Step 1) |
| 2 | 6 lớp `ModuleBacked*Repository`: mỗi method dựng query / command với `tenantId: 'tenant-1', actorId: 'actor-1'` + tham số method, gọi module | Fake repository ghi `*Calls` cùng tham số (bảng Task 1) | 14 tệp nhóm A, số test không đổi |
| 3 | `_RecordingSalesModule implements ISalesModule` (12 tệp) + `FakeSalesModule` (2 tệp): trả DTO theo kiểu query, ghi `queries` / `commands` | Đặt `*Result` / `*Error` của fake; assert trên `*Calls` | như dòng 2 |
| 4 | `SalesFakeContractFixtureFactory.create(typeName)` (`sales_flow_pages_test.dart:1395-1507`, `sales_return_exchange_result_page_test.dart:150-151`): DTO mặc định cho query không cấu hình | `sales_contract_fixtures.dart` (Task 1 Step 2), cùng giá trị | 2 tệp đó, số test không đổi |
| 5 | Nhóm `old` 12 tệp: mapper / gateway / validator module cho ra cùng tham số / DTO / câu lỗi như nhóm `new` | Nhóm `new` cùng tệp (không sửa giá trị mong đợi, không sửa `*_parity_expectations.dart`) | nhóm `new` có sẵn |
| 6 | Live B: `ISalesModule` + `UpdateSalesOrderDraftCommand` / `CancelSalesOrderDraftCommand` / `ListSalesOrderDraftsQuery`; dọn dẹp bỏ qua `STALE_DATA`, `REFERENCE_UNAVAILABLE`; mong đợi `STALE_DATA` khi sửa trùng version. Live C: `PrecheckSalesOrderCheckoutQuery` | `SalesDraftRepository.update/cancel/list`, `SalesCheckoutRepository.precheck`; `AppException` cùng mã (Q4) | `dart analyze integration_test` |
| 7 | `SalesStartup.initialize(...)` + `registerSingleton<ISalesModule>` (`injection.dart:269-278`) | **Bỏ** (không ai `di<ISalesModule>` sau Task 1-2) | Task 4 `sales_runtime_registration_test` (viết lại) |
| 8 | `install_module_messaging('sales')`: tạo `outbox_messages` (11 cột) + `inbox_messages` + `internal_commands` + 12 hàm + đăng ký `platform.messaging_module_registry` + `revoke all` bảng | `create table sales.outbox_messages` 5 cột + RLS + `revoke all` trong `20260830005` (Q1); inbox / commands / hàm / đăng ký **bỏ** (không ai dùng) | Task 0 `kept`, Task 5 `removed` |

## 5. Thay đổi

| Tệp | Hành động |
|---|---|
| `apps/erp/test/features/sales/data/sales_sql_contract_test.dart` | tạo (Task 0), thêm nhóm `removed` (Task 5) |
| `apps/erp/test/features/sales/support/sales_contract_error.dart`, `…/sales_contract_error_test.dart` (đặt ở `test/features/sales/support/`), `…/support/sales_contract_fixtures.dart` | tạo (Task 1) |
| 14 tệp nhóm A; `support/fake_*_repository.dart` (thêm trường nếu thiếu) | sửa (Task 1) |
| `support/module_backed_sales_repositories.dart` | xoá (Task 1) |
| 12 tệp nhóm B; 2 live test | sửa (Task 2) |
| `apps/erp/lib/features/sales/data/models/contracts/*.dart` (61), `apps/erp/lib/features/sales/data/models.dart` | tạo (Task 3) |
| 86 tệp `lib` + tệp test / integration test / 5 tệp example có import module | đổi import (Task 3) |
| `apps/erp/lib/core/di/injection.dart`; `apps/erp/test/core/di/sales_runtime_registration_test.dart` | sửa / viết lại (Task 4) |
| `modules/sales/{domain,application,infrastructure}` | xoá (Task 4) |
| `pubspec.yaml`, `apps/erp/pubspec.yaml`, `apps/erp/example/pubspec.yaml` | sửa (Task 4) |
| `supabase/migrations/20260623000002_install_module_messaging_modules.sql`, `20260830005_sales_rebuild_schema.sql` | sửa (Task 5) |
| `docs/02-yeu-cau/TH-05-ban-hang-va-don-hang.md`, `docs/refactor/PLAN.md` | Task 6 |
| `docs/refactor/TEST-BASELINE.md` | phiên review cập nhật (như 6-C) |

---

## 6. Các task

### Task 0: Bước 0 — test hợp đồng SQL + đếm test trên code cũ

**Files:**
- Create: `apps/erp/test/features/sales/data/sales_sql_contract_test.dart`

**Interfaces:**
- Produces (Task 5 dùng lại, cùng tệp): `Directory _findRepoRoot()`, `String _allMigrationsSql()` (nối mọi `supabase/migrations/*.sql`, không vào `_drafts/`), `bool _definesFn(String sql, String schema, String name)` — chép nguyên từ `apps/erp/test/features/pricing/data/pricing_sql_contract_test.dart`.

- [x] **Step 1: Viết nhóm `kept`**

| Tên test | Kiểm |
|---|---|
| `keeps every RPC the app calls` | `_definesFn(sql, 'sales', n)` đúng với 35 tên: `cancel_return_exchange`, `cancel_sales_order_draft`, `confirm_return_exchange`, `confirm_sales_order_cancellation`, `evaluate_return_exchange_valuation`, `finalize_sales_order`, `generate_sales_receipt`, `get_available_post_sale_actions`, `get_checkout_result`, `get_return_exchange_detail`, `get_returnable_order_lines`, `get_sales_order`, `get_sales_order_cancellation`, `get_sales_order_detail`, `get_sales_order_draft_for_restore`, `get_sales_order_original_receipt`, `get_sales_order_payment_summary`, `get_sales_order_payment_transactions`, `get_sales_order_return_summary`, `get_sales_order_settlement`, `get_sales_order_timeline`, `get_sales_receipt`, `list_sales_order_drafts`, `list_sales_orders`, `precheck_return_exchange`, `precheck_sales_order_cancellation`, `precheck_sales_order_checkout`, `preview_return_exchange_pricing`, `record_sales_payment`, `record_sales_receipt_activity`, `save_sales_order_draft`, `search_sales_orders`, `start_return_exchange`, `update_return_exchange`, `update_sales_order_draft` |
| `app RPC list matches repositories` | Nối nội dung `apps/erp/lib/features/sales/data/*.dart`; `RegExp(r"'sales',\s*'([a-z_]+)'")` (khớp qua xuống dòng); tập tên == 35 tên trên |
| `keeps RPCs TH-05 keeps unused or einvoice calls` | được định nghĩa: 6 RPC của Q6 + `can_access_sales_order`, `get_einvoice_source_snapshot`, `settle_return_exchange_difference` |
| `timeline and settlement guard read sales.outbox_messages` | tệp `20260830010_sales_inquiry_receipt_rpcs.sql` chứa `from sales.outbox_messages o`; `20260830006_sales_shared_rpc_helpers.sql` chứa `from sales.outbox_messages` |
| `outbox writers use only id, tenant_id, event_type, payload` | mọi khớp `RegExp(r'insert into sales\.outbox_messages\s*\(([^)]*)\)')` trong `sql`: tập cột (tách `,`, `trim`) ⊆ `{id, tenant_id, event_type, payload, occurred_at}`; có ≥ 20 khớp; `sql` không chứa `sales.outbox_messages` đi cùng `processed_at` / `claim_token` / `retry_count` (kiểm: không có dòng nào chứa cả `outbox_messages` và một trong 3 tên đó) |

- [x] **Step 2: Chạy** `cd apps/erp && flutter test test/features/sales/data/sales_sql_contract_test.dart` ⇒ PASS 5/5. Đỏ ⇒ dừng, ghi lại (bảng mục 3 sai).
- [x] **Step 3: Đếm test trên code cũ** — với mỗi tệp nhóm A, B, ghi vào Kết quả: số `+N` (lệnh ở Global Constraints) và `grep -c "expect(" <tệp>`. Ghi thêm `cd apps/erp && flutter test test/features/sales 2>&1 | tail -1`.
- [x] **Step 4: Commit** `test(sales): 8-C bước 0 — test hợp đồng RPC sales trên migration hiện tại`

### Task 1: Test nhóm A sang fake repository (Q3)

**Files:**
- Create: `apps/erp/test/features/sales/support/sales_contract_error.dart`, `apps/erp/test/features/sales/support/sales_contract_error_test.dart`, `apps/erp/test/features/sales/support/sales_contract_fixtures.dart`
- Modify: 14 tệp nhóm A; `apps/erp/test/features/sales/support/fake_*_repository.dart` (chỉ thêm trường `*Result` / `*Error` còn thiếu, vd `FakeSalesPaymentRepository.recordError`)
- Delete: `apps/erp/test/features/sales/support/module_backed_sales_repositories.dart`

**Interfaces:**
- Produces:
  - `AppException salesContractError(String code, {String message = '', Map<String, Object?> details = const {}})` — cùng kết quả `_bridge` (bảng mục 4 dòng 1); `details['blockers']` là `List<Map<String, Object?>>` hoặc `List<SalesBlockerDto>`.
  - `T salesFixture<T>()` trong `sales_contract_fixtures.dart` — trả DTO mặc định, giá trị chép từ `SalesFakeContractFixtureFactory` (`modules/sales/application/lib/src/testing/sales_fake_contract_fixture_factory.dart`, nhánh `create` / `_createByResultContract` + hằng `_now`, `_actor`, …); hỗ trợ đúng các kiểu mà 2 tệp ở bảng mục 4 dòng 4 cần; kiểu khác ⇒ `throw UnsupportedError`.
- Consumes: `FakeSalesOrderRepository`, `FakeSalesPaymentRepository`, `FakeSalesReceiptRepository`, `FakeSalesCheckoutRepository`, `FakeSalesCancellationRepository`, `FakeReturnExchangeRepository` (`test/features/sales/support/`).

**Bảng ánh xạ** (query / command cũ → method fake → trường ghi lời gọi):

| Cũ | Fake | Ghi lời gọi |
|---|---|---|
| `GetSalesOrderPaymentSummaryQuery` / `GetSalesOrderSettlementQuery` / `GetSalesOrderPaymentTransactionsQuery` | `FakeSalesPaymentRepository.getSummary` / `getSettlement` / `getTransactions` | `summaryCalls` / `settlementCalls` / `transactionsCalls` |
| `GetSalesOrderQuery` / `ListSalesOrdersQuery` / `SearchSalesOrdersQuery` / `GetSalesOrderDetailQuery` / `GetSalesOrderTimelineQuery` / `GetSalesOrderReturnSummaryQuery` / `GetAvailablePostSaleActionsQuery` / `GetSalesOrderCancellationQuery` | `FakeSalesOrderRepository.get` / `list` / `search` / `getDetail` / `getTimeline` / `getReturnSummary` / `getAvailableActions` / `getCancellation` | `getCalls` / `listCalls` / `searchCalls` / `detailCalls` / `timelineCalls` / `returnSummaryCalls` / `actionsCalls` / `cancellationCalls` |
| `GenerateSalesReceiptCommand` / `GetSalesReceiptQuery` / `GetSalesOrderOriginalReceiptQuery` / `RecordSalesReceiptPrintedCommand` / `RecordSalesReceiptSharedCommand` | `FakeSalesReceiptRepository.generate` / `get` / `getOriginal` / `recordPrinted` / `recordShared` | `generateCalls` / `getCalls` / `originalCalls` / `printedCalls` / `sharedCalls` |
| `PrecheckSalesOrderCheckoutQuery` / `FinalizeSalesOrderCommand` / `GetCheckoutResultQuery` | `FakeSalesCheckoutRepository.precheck` / `finalize` / `getResult` | `precheckCalls` / `finalizeCalls` / `getResultCalls` |
| `PrecheckSalesOrderCancellationQuery` / `ConfirmSalesOrderCancellationCommand` | `FakeSalesCancellationRepository.precheck` / `confirm` | `precheckCalls` / `confirmCalls` |
| `PrecheckReturnExchangeQuery` / `GetReturnableOrderLinesQuery` / `PreviewReturnExchangePricingQuery` / `GetReturnExchangeDetailQuery` / `StartReturnExchangeCommand` / `UpdateReturnExchangeCommand` / `CancelReturnExchangeCommand` / `ConfirmReturnExchangeCommand` / `EvaluateReturnPricingImpactQuery` | `FakeReturnExchangeRepository.precheck` / `getReturnableLines` / `previewPricing` / `getDetail` / `start` / `update` / `cancel` / `confirm` / `evaluate` | `precheckCalls` / `returnableCalls` / `previewCalls` / `detailCalls` / `startCalls` / `updateCalls` / `cancelCalls` / `confirmCalls` / `evaluateCalls` |

Trường của query cũ ⇒ trường của bản ghi lời gọi: theo cách `ModuleBacked*Repository` truyền (đọc tệp cầu trước khi xoá). Query cũ được module trả lời nhưng app không còn gọi (`ListSalesOrderCancellationReasonsQuery`, `GetReturnExchangeFormPolicyQuery` cùng `CancellationReasonPolicyDto`, `ReturnExchangeFormPolicyDto`, `ReturnExchangePolicyOptionDto` trong `sales_flow_pages_test`, `sales_return_exchange_session_cubit_test`): bỏ cấu hình đó (vd `returnFormPolicy = …` ở `sales_flow_pages_test.dart:789`, `policy:` ở `sales_return_exchange_session_cubit_test.dart:148, 183, 202`, `_policy()` `:672`, `cancelReasons` `sales_flow_pages_test.dart:1307`), **giữ** test và các `expect` khác của nó. Assert duy nhất trên chúng — `module.queries.whereType<GetReturnExchangeFormPolicyQuery>()` `isEmpty` (`sales_return_exchange_session_cubit_test.dart:45-48`) — bỏ (Q3(f)). Assert khác trên chúng ⇒ dừng, ghi lại, hỏi người dùng.

- [ ] **Step 1: `salesContractError` + test.** Test `sales_contract_error_test.dart`: (1) `'PERMISSION_DENIED'` ⇒ `code == 'NO_PERMISSION'`; (2) mã khác giữ nguyên, `serverMessage == message`; (3) `details: {'blockers': [SalesBlockerDto(code: 'X', message: 'm', field: 'f')]}` ⇒ `details == {'blockers': [{'code': 'X', 'message': 'm', 'field': 'f'}]}`; (4) `details: {'k': 1}` ⇒ `{'k': 1}`; (5) `details` rỗng ⇒ `details == null`. Chạy đỏ → viết hàm → xanh.
- [ ] **Step 2: `sales_contract_fixtures.dart`.** Chép giá trị (không đổi số / chuỗi / ngày). Test nhỏ trong cùng tệp test của Step 1: `salesFixture<T>()` với từng kiểu hỗ trợ trả bằng (`==` hoặc so `toJson`/trường chính) kết quả `SalesFakeContractFixtureFactory.create(<typeName tương ứng>)` — so được vì module còn tới Task 3; **xoá test so sánh này ở Task 3 Step 0** (sau khi đổi import, DTO của app khác kiểu DTO module ⇒ không biên dịch được).
- [ ] **Step 3: Chuyển từng tệp** (thứ tự ngắn trước: 4 tệp `sales_return_exchange_*_page_test`, `sales_transaction_result_page_test`, `sales_return_exchange_detail_cubit_test`, `sales_order_list_cubit_test`, `sales_transaction_result_body_test`, `sales_return_exchange_settlement_cubit_test`, `sales_transaction_result_cubit_test`, `sales_return_exchange_session_cubit_test`, `sales_checkout_page_test`, `sales_order_detail_page_test`, `sales_order_detail_cubit_test`, `sales_flow_pages_test`). Mỗi tệp: thay lớp module riêng + `ModuleBacked*` bằng fake theo bảng; `SalesContractException(...)` ⇒ `salesContractError(...)`; Q3(c), Q3(d). Sau mỗi tệp chạy nó: số `+N` == số ở Task 0 Step 3, không `-M`; ghi `expect(` trước / sau và từng dòng assert `tenantId` / `actorId` đã bỏ. Commit mỗi 2-4 tệp: `test(sales): 8-C chuyển <tên tệp> sang fake repository`.
- [ ] **Step 4: Xoá cầu.** `grep -rln "module_backed_sales_repositories\|ModuleBacked\|ISalesModule\|FakeSalesModule\|SalesFakeContractFixtureFactory" apps/erp/test --include='*.dart'` ⇒ chỉ còn `sales_contract_error_test.dart` (test so sánh Step 2, xoá ở Task 3) và `test/core/di/sales_runtime_registration_test.dart`. Xoá `module_backed_sales_repositories.dart`.
- [ ] **Step 5: Kiểm.** `cd apps/erp && dart analyze test` ⇒ 0 error; `flutter test test/features/sales` ⇒ số pass = Task 0 Step 3 + số test mới Step 1-2, 0 lỗi mới.
- [ ] **Step 6: Commit** `test(sales): 8-C bỏ cầu module_backed_sales_repositories`

### Task 2: Bỏ nhóm `old` + live test sang repository (Q4)

**Files:** 12 tệp nhóm B; `apps/erp/integration_test/sales_group_b_s06_s07_live_test.dart`, `sales_group_c_s08_s11_live_test.dart`.

**Interfaces:**
- Consumes: `SalesDraftRepository.update({required String draftId, required int expectedVersion, required String storeId, …, required String idempotencyKey})`, `.cancel({required String draftId, required String storeId, required int expectedVersion, required String idempotencyKey})`, `.list({required String storeId, String? cursor, int pageSize = 25, String? search, String? createdByUserId})` (`lib/features/sales/data/sales_draft_repository.dart:61-135`); `SalesCheckoutRepository.precheck({required String storeId, String? customerId, required String currencyCode, DateTime? paymentDueDate, required List<CheckoutLineInput> lines, required List<PaymentIntentInput> paymentIntents, int? expectedSourceVersion})` (`sales_checkout_repository.dart:26`). Đọc chữ ký đầy đủ ở tệp trước khi sửa.

- [ ] **Step 1: Bỏ nhóm `old`** ở 12 tệp (dòng ở bảng mục 3 — kiểm lại bằng `grep -n "group('"` trước khi xoá): xoá cả `group`, import module chỉ nhóm đó dùng, helper / lớp fake chỉ nhóm đó dùng (kiểm 0 tham chiếu còn lại). **Không** sửa ca / giá trị nhóm `new` và `*_parity_expectations.dart`.
- [ ] **Step 2: Chạy** 12 tệp ⇒ PASS; số test **nhóm `new`** mỗi tệp bằng số trước (Task 0 Step 3 trừ số test nhóm `old`, đếm bằng `flutter test <tệp> --plain-name "<tên nhóm new>"`). Ghi vào Kết quả.
- [ ] **Step 3: Live B.** `di<ISalesModule>()` ⇒ `di<SalesDraftRepository>()`; 3 command / query ⇒ method theo bảng mục 4 dòng 6, giữ dữ liệu, `expectedVersion`, khoá idempotency; `on SalesContractException catch (error)` ⇒ `on AppException catch (error)` (cùng 2 mã); `isA<SalesContractException>()` ⇒ `isA<AppException>()` cùng `code == 'STALE_DATA'`. Bỏ `tenantId` / `actorId` (repository lấy từ phiên) — biến `executionContext` bỏ nếu không còn dùng.
- [ ] **Step 4: Live C.** `di<ISalesModule>().executeQueryAsync(PrecheckSalesOrderCheckoutQuery(...))` ⇒ `di<SalesCheckoutRepository>().precheck(...)` cùng tham số; `expect` sau đó giữ nguyên. Tên test `'… precheck through ISalesModule …'` ⇒ `'… precheck through SalesCheckoutRepository …'`.
- [ ] **Step 5: Kiểm.** `cd apps/erp && dart analyze integration_test` ⇒ `No issues found!`; `grep -rnE "ISalesModule|SalesContractException|Command\(|Query\(" integration_test --include='*.dart'` ⇒ không còn kiểu module.
- [ ] **Step 6: Commit** `test(sales): 8-C bỏ nhóm test old, live test nháp / precheck qua repository`

### Task 3: Chép kiểu + đổi import (Q2)

**Files:**
- Create: `apps/erp/lib/features/sales/data/models/contracts/` (61 tệp ở mục 3), `apps/erp/lib/features/sales/data/models.dart`
- Modify: mọi tệp trong `apps/erp/{lib,test,integration_test}`, `apps/erp/example/lib` còn `import 'package:vet45_sales_application/application.dart'`

**Interfaces:**
- Produces: `package:erp/features/sales/data/models.dart` export đủ 61 tệp. Mọi tên lớp / enum giữ nguyên ⇒ chỗ dùng không đổi.

- [ ] **Step 0: Bỏ test so sánh fixture** (Task 1 Step 2) khỏi `sales_contract_error_test.dart` + import `vet45_sales_application/testing.dart`; ghi tên test đã bỏ vào Kết quả.
- [ ] **Step 1: Chép** 61 tệp (`cp`) từ `modules/sales/application/lib/src/shared/` sang `contracts/`. Viết barrel.
- [ ] **Step 2: Kiểm bản chép** — `for f in contracts/*.dart; do diff <(grep -v '^import' modules/…/shared/$f) <(grep -v '^import' contracts/$f); done` ⇒ không khác. `grep -h "^import 'package" contracts/*.dart` ⇒ rỗng (61 tệp chỉ import lẫn nhau — đo 2026-11-08; có import package ⇒ dừng, ghi lại).
- [ ] **Step 3: Đổi import** — trong 4 cây trên, thay `package:vet45_sales_application/application.dart` bằng `package:erp/features/sales/data/models.dart`, **giữ** prefix (`as app`, `as sales`) nếu có. Bỏ `// ignore_for_file: depend_on_referenced_packages` chỉ khi tệp không còn import package ngoài nào cần nó. Tệp đã import barrel rồi ⇒ bỏ dòng trùng. Tệp nào còn import `vet45_sales_infrastructure` / `testing.dart` / `domain` ngoài `injection.dart`, `sales_runtime_registration_test.dart` ⇒ dừng, ghi lại (Task 1-2 sót).
- [ ] **Step 4: Kiểm.**
  - `grep -rln "vet45_sales_" apps/erp --include='*.dart'` ⇒ đúng 2 tệp: `lib/core/di/injection.dart`, `test/core/di/sales_runtime_registration_test.dart`
  - `cd apps/erp && dart analyze lib test integration_test` ⇒ 0 error, 0 warning mới; `cd apps/erp/example && dart analyze lib` ⇒ 0 error
  - `cd apps/erp && flutter test test/features/sales` ⇒ số pass như Task 2 Step 2 + Task 1 Step 5
- [ ] **Step 5: Commit** `refactor(sales): 8-C chép kiểu DTO sales vào app (data/models.dart), đổi import`

### Task 4: Bỏ DI module + xoá module + workspace

**Files:**
- Modify: `apps/erp/lib/core/di/injection.dart:5-6, 269-278`; `apps/erp/test/core/di/sales_runtime_registration_test.dart` (viết lại); `pubspec.yaml:20-22`; `apps/erp/pubspec.yaml:22-24`; `apps/erp/example/pubspec.yaml:17-18, 56-61`
- Delete: `modules/sales/domain`, `modules/sales/application`, `modules/sales/infrastructure`

- [ ] **Step 1: Impact.** `node .gitnexus/run.cjs impact initDependencies --direction upstream --repo erp-sales-inventory` ⇒ ghi vào Kết quả; HIGH / CRITICAL ⇒ báo người dùng trước khi sửa.
- [ ] **Step 2: Viết lại `sales_runtime_registration_test.dart` (đỏ).** Giữ `_findRepoRoot`, 2 fake Supabase. Test: (1) `ERP DI source has no sales module`: nguồn `injection.dart` không chứa `SalesStartup`, `ISalesModule`, `vet45_sales_`; (2) `initDependencies registers sales repositories`: sau `initDependencies(...)`, `getIt.isRegistered<T>()` đúng với `SalesDraftRepository`, `SalesCheckoutRepository`, `SalesPaymentRepository`, `SalesOrderRepository`, `SalesReceiptRepository`, `SalesCancellationRepository`, `ReturnExchangeRepository`. Chạy ⇒ (1) FAIL, (2) PASS.
- [ ] **Step 3: Sửa `injection.dart`**: xoá 2 import `vet45_sales_*` và khối `final salesModule = SalesStartup.initialize(...)` + `getIt.registerSingleton<ISalesModule>(salesModule);`. **Giữ** `executionContext`, `permissionChecker`, `tenantAccessChecker`, khối einvoice (Q5). Sửa chú thích dòng 91 thành `// Ngữ cảnh / quyền cho module einvoice cũ (bỏ ở 7-5), đọc cùng SessionStore.`. Chạy test Step 2 ⇒ 2/2 PASS.
- [ ] **Step 4: Xoá module.** `git status --short modules/sales` sạch; `git rm -r modules/sales/domain modules/sales/application modules/sales/infrastructure`; `rm -rf` phần không theo dõi còn lại của 3 thư mục đó. Sửa 3 pubspec (giữ mọi dòng `integration_events`).
- [ ] **Step 5: `pub get`** ở gốc, `apps/erp`, `apps/erp/example`, `modules/einvoice/presentation/example` ⇒ không lỗi phân giải.
- [ ] **Step 6: Kiểm.**
  - `grep -rnE "vet45_sales_(domain|application|infrastructure)|ISalesModule|SalesStartup|FakeSalesModule|SalesFeShellModule" apps packages tools pubspec.yaml --include='*.dart' --include='*.yaml'` ⇒ chỉ chuỗi cấm trong `group_f_no_demo_contract_test.dart` và chuỗi trong test Step 2 (1)
  - `ls modules/sales` ⇒ `integration_events`
  - `cd apps/erp && dart analyze lib test integration_test` ⇒ 0 error, 0 warning mới; `cd apps/erp/example && dart analyze lib` ⇒ 0 error
  - `cd apps/erp && flutter test` ⇒ không lỗi mới so với `TEST-BASELINE.md` (mốc "Sau 6-C": 53 + 2 ⚠️); ghi số đạt / lỗi
  - `dart test` ở `modules/einvoice/application`, `modules/einvoice/infrastructure` ⇒ không lỗi biên dịch mới (mốc: 217 / 1; 378 / 60)
- [ ] **Step 7: Commit** `chore(sales): 8-C xoá modules/sales (trừ integration_events), bỏ SalesStartup khỏi DI`

### Task 5: DB — bỏ messaging sales, giữ `sales.outbox_messages` (Q1)

**Files:** `supabase/migrations/20260623000002_install_module_messaging_modules.sql`, `supabase/migrations/20260830005_sales_rebuild_schema.sql`, `apps/erp/test/features/sales/data/sales_sql_contract_test.dart`.

- [ ] **Step 1: Nhóm `removed` (đỏ)** thêm vào `sales_sql_contract_test.dart`:

| Tên test | Kiểm |
|---|---|
| `sales no longer installs messaging` | không tệp migration nào chứa `install_module_messaging('sales')` |
| `sales has no inbox, internal commands or queue functions` | `sql` không chứa `sales.inbox_messages`, `sales.internal_commands`, `sales.enqueue_outbox_message`, `sales.claim_`, `sales.receive_integration_event` |
| `creates sales.outbox_messages directly` | tệp `20260830005` chứa `create schema if not exists sales;`, `create table if not exists sales.outbox_messages (`; khối từ đó tới `);` đầu tiên chứa đủ `id uuid primary key`, `tenant_id uuid not null`, `event_type text not null`, `payload jsonb not null`, `occurred_at timestamptz not null default now()` và không chứa `processed_at`, `claim_token`; tệp chứa `sales_outbox_messages_order_idx`, `alter table sales.outbox_messages enable row level security`, `revoke all on sales.outbox_messages from public, anon, authenticated` |
| `creates outbox before any sales function uses it` | trong `20260830005`, vị trí `create table if not exists sales.outbox_messages` < vị trí `create table if not exists sales.idempotency_records` |

Run: `flutter test test/features/sales/data/sales_sql_contract_test.dart` ⇒ 4 test mới FAIL, 5 `kept` PASS.

- [ ] **Step 2: `20260623000002`**: xoá dòng 4 `select platform.install_module_messaging('sales');`. Không đổi gì khác.
- [ ] **Step 3: `20260830005`**: dòng 11 thay bằng `create schema if not exists sales;` + `create table` / index / RLS / revoke ở Q1, đặt ngay sau (trước dòng `grant usage on schema sales …`). Header: `-- Touches:` thêm `sales.outbox_messages`; `-- Depends on:` bỏ `platform.install_module_messaging(text);`; thêm dòng `-- 8-C (2026-11-08): bỏ messaging (inbox, internal_commands, hàm hàng đợi); outbox_messages = nhật ký sự kiện của đơn (timeline, chống ghi trùng quyết toán).` Chú thích dòng 32-35 sửa thành 1 dòng: `-- Sales ghi sự kiện vòng đời đơn vào sales.outbox_messages (đọc bởi get_sales_order_timeline); không còn hàng đợi messaging.`
- [ ] **Step 4: Kiểm**
  - `flutter test test/features/sales/data/sales_sql_contract_test.dart` ⇒ 9/9 PASS
  - `grep -rnE "install_module_messaging\('sales'\)|sales\.(inbox_messages|internal_commands|enqueue_outbox_message|claim_)" supabase` ⇒ rỗng
  - `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart` ⇒ 0 error, đúng 3 warning có sẵn
  - `dart run tools/vet45_supabase_migrate/bin/verify_schema_lock_sync.dart` ⇒ `OK`
- [ ] **Step 5: Commit** `chore(db): 8-C bỏ messaging schema sales, giữ outbox_messages làm nhật ký sự kiện (sửa migration gốc)`

### Task 6: Tài liệu + kiểm tổng

- [ ] **Step 1: TH-05 → 3.1** (ngày 2026-11-08; header dòng 4 ghi `3.1 · 2026-11-08`, giữ `3.0` trong một dòng lịch sử nếu tệp có):
  - dòng 8 "Nguồn đối chiếu — App": bỏ "module `modules/sales/`", thêm `apps/erp/lib/features/sales/{data,logic,presentation}`
  - mục 3 `outbox_messages` (dòng 502): "Nhật ký sự kiện của đơn (5 cột `id`, `tenant_id`, `event_type`, `payload`, `occurred_at`), đọc bởi `get_sales_order_timeline` (BR-36) và chống ghi trùng quyết toán. Không còn hàng đợi messaging / người tiêu thụ (8-C); HĐĐT tự động: trigger, TH-08 KI-20."
  - BR-29 cột cuối (dòng 294): "chưa nối (messaging bỏ ở 8-C); sau 7-4: trigger → `einvoice.internal_commands`"
  - 6.1 (dòng 2087-2090): `Page ─▶ Cubit ─▶ Sales*Repository / ReturnExchangeRepository ─▶ SupabaseRpc ─▶ schema('sales').rpc(...)`; lookups: `SalesPricingRepository`, `ProductRepository`, `PartnerRepository`
  - 6.2: `get_return_exchange_form_policy`, `list_sales_order_cancellation_reasons` ghi "(app không dùng, giữ trong DB)"; dòng `complete_return_exchange` ghi "app không gọi, giữ trong DB"; thêm dòng `audit_sales_review_invariants` — "chỉ đọc, kiểm bất biến; không ai gọi, giữ trong DB"
  - FR-03 (dòng 1239): "Hợp lệ → mở SG-10; lý do nhập dạng chữ, không bắt buộc (KI-12)."
  - 9.1: dòng 1 cột "Sau refactor" thêm "(xong 8-C)"; dòng sự kiện `sales_order_finalized.v1`: "outbox giữ làm nhật ký (8-C); trigger ở 7-4"
- [ ] **Step 2: PLAN.md**:
  - dòng 8-C (503): nội dung ghi đúng Q1, Q5 ("`Core*` dời 7-5", "giữ `sales.outbox_messages` làm nhật ký"); cột Plan `✅ [plan](plans/P8/8-C-don-module-sales.md) duyệt <ngày>`; cột Làm `✅ <ngày>`
  - dòng 7-5 (539): thêm "bỏ `CoreExecutionContext` / `CorePermissionChecker` / `CoreTenantAccessChecker` trong `core/session` (chuyển từ 8-C, 2026-11-08)"; giữ nguyên phần còn lại của dòng
  - dòng trạng thái Theme 5 (491), bảng "Theo dõi tiến độ", dòng 9.1 (722) nếu nhắc `modules/sales`
- [ ] **Step 3: Kiểm tổng**
  - `grep -rnE "vet45_sales_(domain|application|infrastructure)|ISalesModule|SalesStartup" apps packages tools --include='*.dart' --include='*.yaml'` ⇒ như Task 4 Step 6
  - `ls modules` ⇒ `einvoice partner sales`; `ls modules/sales` ⇒ `integration_events`
  - `cd apps/erp && dart analyze lib test integration_test` ⇒ 0 error, 0 warning mới
  - `cd apps/erp && flutter test` ⇒ không lỗi mới so với `TEST-BASELINE.md`; ghi số
  - `git diff 735ed8704 HEAD --stat -- apps/erp/lib` ⇒ chỉ: 61 tệp mới + `models.dart`, `injection.dart`, các tệp đổi import (`git diff 735ed8704 HEAD -- apps/erp/lib | grep '^[-+]' | grep -v '^[-+]import\|^+++\|^---'` ⇒ chỉ nội dung 62 tệp mới + khối `injection.dart`)
  - `node .gitnexus/run.cjs analyze` + `detect_changes({scope: "compare", base_ref: "735ed8704"})` ⇒ ghi số tệp / symbol; lỗi FTS như 6-C ⇒ ghi lại, xoá cache `.gitnexus` rồi chạy lại
- [ ] **Step 4: Commit** `docs(refactor): 8-C cập nhật TH-05 3.1, PLAN.md và kết quả plan 8-C`

## 7. Rủi ro / lưu ý

- **Task 1 nặng nhất** (14 tệp, khoảng 9.700 dòng). Chia commit theo Step 3. Gặp test assert trên thứ fake không ghi được (vd thứ tự gọi giữa 2 repository khác nhau) ⇒ thêm danh sách ghi chung vào test đó (không vào fake dùng chung), ghi vào Kết quả.
- **`FakeSalesModule` / `SalesFakeData`** (`vet45_sales_application/testing.dart`) còn dùng ở `sales_runtime_registration_test` (Task 4 viết lại) và các tệp nhóm A — sau Task 1 không còn ở nhóm A.
- **DB dựng lại.** Hàm plpgsql không kiểm bảng lúc `create`; Task 0 test `outbox writers…` chốt mọi câu insert chỉ dùng cột còn giữ.
- **HĐĐT tự động** (BR-29) hiện chưa chạy (worker đã bỏ ở 3-D); 8-C không làm xấu thêm. 7-4 dựng trigger.
- **`v_allowed`** của `platform.install_module_messaging` còn `'sales'`: vô hại, P9 dọn.
- **Live test** mặc định skip; chỉ kiểm bằng `dart analyze`.

## 8. Kết quả

<!-- Phiên code ghi ngay sau mỗi task: commit, tệp:dòng, lệch plan, test (trước / sau), impact. Không tự chấm ĐẠT. -->

### Task 0

- Commit: xem `git log -1` (test(sales): 8-C bước 0 — test hợp đồng RPC sales trên migration hiện tại).
- Tệp: tạo `apps/erp/test/features/sales/data/sales_sql_contract_test.dart` (helper `_findRepoRoot` / `_allMigrationsSql` / `_definesFn` chép từ `pricing_sql_contract_test.dart`). Không đổi code production, không chạm DB.
- Lệch plan: không. Tệp dở từ lần trước đã kiểm lại đủ 5 test theo bảng Step 1 (35 tên RPC, 6 RPC Q6 + 3 RPC giữ).
- Test: `sales_sql_contract_test.dart` +5 PASS (5/5); `dart analyze` tệp này sạch. Toàn `test/features/sales`: +1284 xanh (đã gồm 5 test mới; trước Task 0 là 1279). Mọi tệp nhóm A, B xanh trên code cũ.
- Impact: không sửa symbol Dart trong `lib`, không cần `impact`.

Nhóm A (Task 1), đếm trên code cũ:

| Tệp (trong `test/features/sales/`) | Test | `expect(` |
|---|---|---|
| `presentation/sales_checkout_page_test.dart` | +22 | 89 |
| `presentation_module/bloc/sales_order_detail_cubit_test.dart` | +57 | 269 |
| `…/sales_order_list_cubit_test.dart` | +16 | 39 |
| `…/sales_return_exchange_detail_cubit_test.dart` | +6 | 20 |
| `…/sales_return_exchange_session_cubit_test.dart` | +24 | 116 |
| `…/sales_return_exchange_settlement_cubit_test.dart` | +20 | 87 |
| `…/sales_transaction_result_cubit_test.dart` | +28 | 100 |
| `presentation_module/widgets/sales_transaction_result_body_test.dart` | +7 | 28 |
| `sales_flow_pages_test.dart` | +28 | 117 |
| `sales_order_detail_page_test.dart` | +28 | 113 |
| `sales_return_exchange_detail_page_test.dart` | +2 | 23 |
| `sales_return_exchange_result_page_test.dart` | +3 | 15 |
| `sales_return_exchange_slip_preview_page_test.dart` | +2 | 8 |
| `sales_transaction_result_page_test.dart` | +4 | 11 |

Nhóm B (Task 2), đếm trên code cũ (cả `old` và `new`):

| Tệp (trong `test/features/sales/`) | Test | `expect(` |
|---|---|---|
| `data/return_exchange_rpc_parity_test.dart` | +64 | 121 |
| `data/sales_cancellation_rpc_parity_test.dart` | +19 | 32 |
| `data/sales_checkout_errors_test.dart` | +33 | 15 |
| `data/sales_checkout_rpc_parity_test.dart` | +22 | 10 |
| `data/sales_draft_rpc_parity_test.dart` | +40 | 13 |
| `data/sales_order_inquiry_rpc_parity_test.dart` | +32 | 35 |
| `data/sales_order_read_errors_test.dart` | +18 | 10 |
| `data/sales_payment_rpc_parity_test.dart` | +16 | 15 |
| `data/sales_receipt_errors_test.dart` | +25 | 12 |
| `data/sales_receipt_rpc_parity_test.dart` | +17 | 25 |
| `logic/sales_checkout_rules_test.dart` | +25 | 1 |
| `logic/sales_draft_rules_test.dart` | +71 | 11 |


## 9. Review

<!-- Chỉ phiên review ghi. -->
