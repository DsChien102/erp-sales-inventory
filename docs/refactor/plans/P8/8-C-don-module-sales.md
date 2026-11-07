# 8-C — Dọn sạch module sales

> Theme 5 (mã cũ P8) · Bước (dọn) theo "Quy tắc dọn module (chốt 2026-10-11)" của PLAN.md
> Trạng thái: Plan ✅ (viết + người dùng duyệt 2026-11-08) | Làm ✅ 2026-11-08 | Review ⬜
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

**61 tệp chép (Q2)** (thực tế 63: 61 tệp `src/shared` + `sales_order_draft/shared/sales_order_draft_contract_mapper.dart` + `paged_sales_order_draft_list_dto.dart`; 8-C Task 3) — thư mục `modules/sales/application/lib/src/shared/`:
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
| `apps/erp/lib/features/sales/data/models/contracts/*.dart` (61) (thực tế 63: 61 tệp `src/shared` + `sales_order_draft/shared/sales_order_draft_contract_mapper.dart` + `paged_sales_order_draft_list_dto.dart`; 8-C Task 3), `apps/erp/lib/features/sales/data/models.dart` | tạo (Task 3) |
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

- [x] **Step 1: `salesContractError` + test.** Test `sales_contract_error_test.dart`: (1) `'PERMISSION_DENIED'` ⇒ `code == 'NO_PERMISSION'`; (2) mã khác giữ nguyên, `serverMessage == message`; (3) `details: {'blockers': [SalesBlockerDto(code: 'X', message: 'm', field: 'f')]}` ⇒ `details == {'blockers': [{'code': 'X', 'message': 'm', 'field': 'f'}]}`; (4) `details: {'k': 1}` ⇒ `{'k': 1}`; (5) `details` rỗng ⇒ `details == null`. Chạy đỏ → viết hàm → xanh.
- [x] **Step 2: `sales_contract_fixtures.dart`.** Chép giá trị (không đổi số / chuỗi / ngày). Test nhỏ trong cùng tệp test của Step 1: `salesFixture<T>()` với từng kiểu hỗ trợ trả bằng (`==` hoặc so `toJson`/trường chính) kết quả `SalesFakeContractFixtureFactory.create(<typeName tương ứng>)` — so được vì module còn tới Task 3; **xoá test so sánh này ở Task 3 Step 0** (sau khi đổi import, DTO của app khác kiểu DTO module ⇒ không biên dịch được).
- [x] **Step 3: Chuyển từng tệp** (thứ tự ngắn trước: 4 tệp `sales_return_exchange_*_page_test`, `sales_transaction_result_page_test`, `sales_return_exchange_detail_cubit_test`, `sales_order_list_cubit_test`, `sales_transaction_result_body_test`, `sales_return_exchange_settlement_cubit_test`, `sales_transaction_result_cubit_test`, `sales_return_exchange_session_cubit_test`, `sales_checkout_page_test`, `sales_order_detail_page_test`, `sales_order_detail_cubit_test`, `sales_flow_pages_test`). Mỗi tệp: thay lớp module riêng + `ModuleBacked*` bằng fake theo bảng; `SalesContractException(...)` ⇒ `salesContractError(...)`; Q3(c), Q3(d). Sau mỗi tệp chạy nó: số `+N` == số ở Task 0 Step 3, không `-M`; ghi `expect(` trước / sau và từng dòng assert `tenantId` / `actorId` đã bỏ. Commit mỗi 2-4 tệp: `test(sales): 8-C chuyển <tên tệp> sang fake repository`.
- [x] **Step 4: Xoá cầu.** `grep -rln "module_backed_sales_repositories\|ModuleBacked\|ISalesModule\|FakeSalesModule\|SalesFakeContractFixtureFactory" apps/erp/test --include='*.dart'` ⇒ chỉ còn `sales_contract_error_test.dart` (test so sánh Step 2, xoá ở Task 3) và `test/core/di/sales_runtime_registration_test.dart`. Xoá `module_backed_sales_repositories.dart`.
- [x] **Step 5: Kiểm.** `cd apps/erp && dart analyze test` ⇒ 0 error; `flutter test test/features/sales` ⇒ số pass = Task 0 Step 3 + số test mới Step 1-2, 0 lỗi mới.
- [x] **Step 6: Commit** `test(sales): 8-C bỏ cầu module_backed_sales_repositories`

### Task 2: Bỏ nhóm `old` + live test sang repository (Q4)

**Files:** 12 tệp nhóm B; `apps/erp/integration_test/sales_group_b_s06_s07_live_test.dart`, `sales_group_c_s08_s11_live_test.dart`.

**Interfaces:**
- Consumes: `SalesDraftRepository.update({required String draftId, required int expectedVersion, required String storeId, …, required String idempotencyKey})`, `.cancel({required String draftId, required String storeId, required int expectedVersion, required String idempotencyKey})`, `.list({required String storeId, String? cursor, int pageSize = 25, String? search, String? createdByUserId})` (`lib/features/sales/data/sales_draft_repository.dart:61-135`); `SalesCheckoutRepository.precheck({required String storeId, String? customerId, required String currencyCode, DateTime? paymentDueDate, required List<CheckoutLineInput> lines, required List<PaymentIntentInput> paymentIntents, int? expectedSourceVersion})` (`sales_checkout_repository.dart:26`). Đọc chữ ký đầy đủ ở tệp trước khi sửa.

- [x] **Step 1: Bỏ nhóm `old`** ở 12 tệp (dòng ở bảng mục 3 — kiểm lại bằng `grep -n "group('"` trước khi xoá): xoá cả `group`, import module chỉ nhóm đó dùng, helper / lớp fake chỉ nhóm đó dùng (kiểm 0 tham chiếu còn lại). **Không** sửa ca / giá trị nhóm `new` và `*_parity_expectations.dart`.
- [x] **Step 2: Chạy** 12 tệp ⇒ PASS; số test **nhóm `new`** mỗi tệp bằng số trước (Task 0 Step 3 trừ số test nhóm `old`, đếm bằng `flutter test <tệp> --plain-name "<tên nhóm new>"`). Ghi vào Kết quả.
- [x] **Step 3: Live B.** `di<ISalesModule>()` ⇒ `di<SalesDraftRepository>()`; 3 command / query ⇒ method theo bảng mục 4 dòng 6, giữ dữ liệu, `expectedVersion`, khoá idempotency; `on SalesContractException catch (error)` ⇒ `on AppException catch (error)` (cùng 2 mã); `isA<SalesContractException>()` ⇒ `isA<AppException>()` cùng `code == 'STALE_DATA'`. Bỏ `tenantId` / `actorId` (repository lấy từ phiên) — biến `executionContext` bỏ nếu không còn dùng.
- [x] **Step 4: Live C.** `di<ISalesModule>().executeQueryAsync(PrecheckSalesOrderCheckoutQuery(...))` ⇒ `di<SalesCheckoutRepository>().precheck(...)` cùng tham số; `expect` sau đó giữ nguyên. Tên test `'… precheck through ISalesModule …'` ⇒ `'… precheck through SalesCheckoutRepository …'`.
- [x] **Step 5: Kiểm.** `cd apps/erp && dart analyze integration_test` ⇒ `No issues found!`; `grep -rnE "ISalesModule|SalesContractException|Command\(|Query\(" integration_test --include='*.dart'` ⇒ không còn kiểu module.
- [x] **Step 6: Commit** `test(sales): 8-C bỏ nhóm test old, live test nháp / precheck qua repository`

### Task 3: Chép kiểu + đổi import (Q2)

**Files:**
- Create: `apps/erp/lib/features/sales/data/models/contracts/` (61 tệp ở mục 3; thực tế 63: 61 tệp `src/shared` + `sales_order_draft/shared/sales_order_draft_contract_mapper.dart` + `paged_sales_order_draft_list_dto.dart`; 8-C Task 3), `apps/erp/lib/features/sales/data/models.dart`
- Modify: mọi tệp trong `apps/erp/{lib,test,integration_test}`, `apps/erp/example/lib` còn `import 'package:vet45_sales_application/application.dart'`

**Interfaces:**
- Produces: `package:erp/features/sales/data/models.dart` export đủ 63 tệp (61 + 2, xem Kết quả Task 3). Mọi tên lớp / enum giữ nguyên ⇒ chỗ dùng không đổi.

- [x] **Step 0: Bỏ test so sánh fixture** (Task 1 Step 2) khỏi `sales_contract_error_test.dart` + import `vet45_sales_application/testing.dart`; ghi tên test đã bỏ vào Kết quả.
- [x] **Step 1: Chép** 61 tệp (`cp`) từ `modules/sales/application/lib/src/shared/` sang `contracts/`. Viết barrel.
- [x] **Step 2: Kiểm bản chép** — `for f in contracts/*.dart; do diff <(grep -v '^import' modules/…/shared/$f) <(grep -v '^import' contracts/$f); done` ⇒ không khác. `grep -h "^import 'package" contracts/*.dart` ⇒ rỗng (61 tệp chỉ import lẫn nhau — đo 2026-11-08; có import package ⇒ dừng, ghi lại).
- [x] **Step 3: Đổi import** — trong 4 cây trên, thay `package:vet45_sales_application/application.dart` bằng `package:erp/features/sales/data/models.dart`, **giữ** prefix (`as app`, `as sales`) nếu có. Bỏ `// ignore_for_file: depend_on_referenced_packages` chỉ khi tệp không còn import package ngoài nào cần nó. Tệp đã import barrel rồi ⇒ bỏ dòng trùng. Tệp nào còn import `vet45_sales_infrastructure` / `testing.dart` / `domain` ngoài `injection.dart`, `sales_runtime_registration_test.dart` ⇒ dừng, ghi lại (Task 1-2 sót).
- [x] **Step 4: Kiểm.**
  - `grep -rln "vet45_sales_" apps/erp --include='*.dart'` ⇒ đúng 2 tệp: `lib/core/di/injection.dart`, `test/core/di/sales_runtime_registration_test.dart`
  - `cd apps/erp && dart analyze lib test integration_test` ⇒ 0 error, 0 warning mới; `cd apps/erp/example && dart analyze lib` ⇒ 0 error
  - `cd apps/erp && flutter test test/features/sales` ⇒ số pass như Task 2 Step 2 + Task 1 Step 5
- [x] **Step 5: Commit** `refactor(sales): 8-C chép kiểu DTO sales vào app (data/models.dart), đổi import`

### Task 4: Bỏ DI module + xoá module + workspace

**Files:**
- Modify: `apps/erp/lib/core/di/injection.dart:5-6, 269-278`; `apps/erp/test/core/di/sales_runtime_registration_test.dart` (viết lại); `pubspec.yaml:20-22`; `apps/erp/pubspec.yaml:22-24`; `apps/erp/example/pubspec.yaml:17-18, 56-61`
- Delete: `modules/sales/domain`, `modules/sales/application`, `modules/sales/infrastructure`

- [x] **Step 1: Impact.** `node .gitnexus/run.cjs impact initDependencies --direction upstream --repo erp-sales-inventory` ⇒ ghi vào Kết quả; HIGH / CRITICAL ⇒ báo người dùng trước khi sửa.
- [x] **Step 2: Viết lại `sales_runtime_registration_test.dart` (đỏ).** Giữ `_findRepoRoot`, 2 fake Supabase. Test: (1) `ERP DI source has no sales module`: nguồn `injection.dart` không chứa `SalesStartup`, `ISalesModule`, `vet45_sales_`; (2) `initDependencies registers sales repositories`: sau `initDependencies(...)`, `getIt.isRegistered<T>()` đúng với `SalesDraftRepository`, `SalesCheckoutRepository`, `SalesPaymentRepository`, `SalesOrderRepository`, `SalesReceiptRepository`, `SalesCancellationRepository`, `ReturnExchangeRepository`. Chạy ⇒ (1) FAIL, (2) PASS.
- [x] **Step 3: Sửa `injection.dart`**: xoá 2 import `vet45_sales_*` và khối `final salesModule = SalesStartup.initialize(...)` + `getIt.registerSingleton<ISalesModule>(salesModule);`. **Giữ** `executionContext`, `permissionChecker`, `tenantAccessChecker`, khối einvoice (Q5). Sửa chú thích dòng 91 thành `// Ngữ cảnh / quyền cho module einvoice cũ (bỏ ở 7-5), đọc cùng SessionStore.`. Chạy test Step 2 ⇒ 2/2 PASS.
- [x] **Step 4: Xoá module.** `git status --short modules/sales` sạch; `git rm -r modules/sales/domain modules/sales/application modules/sales/infrastructure`; `rm -rf` phần không theo dõi còn lại của 3 thư mục đó. Sửa 3 pubspec (giữ mọi dòng `integration_events`).
- [x] **Step 5: `pub get`** ở gốc, `apps/erp`, `apps/erp/example`, `modules/einvoice/presentation/example` ⇒ không lỗi phân giải.
- [x] **Step 6: Kiểm.**
  - `grep -rnE "vet45_sales_(domain|application|infrastructure)|ISalesModule|SalesStartup|FakeSalesModule|SalesFeShellModule" apps packages tools pubspec.yaml --include='*.dart' --include='*.yaml'` ⇒ chỉ chuỗi cấm trong `group_f_no_demo_contract_test.dart` và chuỗi trong test Step 2 (1)
  - `ls modules/sales` ⇒ `integration_events`
  - `cd apps/erp && dart analyze lib test integration_test` ⇒ 0 error, 0 warning mới; `cd apps/erp/example && dart analyze lib` ⇒ 0 error
  - `cd apps/erp && flutter test` ⇒ không lỗi mới so với `TEST-BASELINE.md` (mốc "Sau 6-C": 53 + 2 ⚠️); ghi số đạt / lỗi
  - `dart test` ở `modules/einvoice/application`, `modules/einvoice/infrastructure` ⇒ không lỗi biên dịch mới (mốc: 217 / 1; 378 / 60)
- [x] **Step 7: Commit** `chore(sales): 8-C xoá modules/sales (trừ integration_events), bỏ SalesStartup khỏi DI`

### Task 5: DB — bỏ messaging sales, giữ `sales.outbox_messages` (Q1)

**Files:** `supabase/migrations/20260623000002_install_module_messaging_modules.sql`, `supabase/migrations/20260830005_sales_rebuild_schema.sql`, `apps/erp/test/features/sales/data/sales_sql_contract_test.dart`.

- [x] **Step 1: Nhóm `removed` (đỏ)** thêm vào `sales_sql_contract_test.dart`:

| Tên test | Kiểm |
|---|---|
| `sales no longer installs messaging` | không tệp migration nào chứa `install_module_messaging('sales')` |
| `sales has no inbox, internal commands or queue functions` | `sql` không chứa `sales.inbox_messages`, `sales.internal_commands`, `sales.enqueue_outbox_message`, `sales.claim_`, `sales.receive_integration_event` |
| `creates sales.outbox_messages directly` | tệp `20260830005` chứa `create schema if not exists sales;`, `create table if not exists sales.outbox_messages (`; khối từ đó tới `);` đầu tiên chứa đủ `id uuid primary key`, `tenant_id uuid not null`, `event_type text not null`, `payload jsonb not null`, `occurred_at timestamptz not null default now()` và không chứa `processed_at`, `claim_token`; tệp chứa `sales_outbox_messages_order_idx`, `alter table sales.outbox_messages enable row level security`, `revoke all on sales.outbox_messages from public, anon, authenticated` |
| `creates outbox before any sales function uses it` | trong `20260830005`, vị trí `create table if not exists sales.outbox_messages` < vị trí `create table if not exists sales.idempotency_records` |

Run: `flutter test test/features/sales/data/sales_sql_contract_test.dart` ⇒ 4 test mới FAIL, 5 `kept` PASS.

- [x] **Step 2: `20260623000002`**: xoá dòng 4 `select platform.install_module_messaging('sales');`. Không đổi gì khác.
- [x] **Step 3: `20260830005`**: dòng 11 thay bằng `create schema if not exists sales;` + `create table` / index / RLS / revoke ở Q1, đặt ngay sau (trước dòng `grant usage on schema sales …`). Header: `-- Touches:` thêm `sales.outbox_messages`; `-- Depends on:` bỏ `platform.install_module_messaging(text);`; thêm dòng `-- 8-C (2026-11-08): bỏ messaging (inbox, internal_commands, hàm hàng đợi); outbox_messages = nhật ký sự kiện của đơn (timeline, chống ghi trùng quyết toán).` Chú thích dòng 32-35 sửa thành 1 dòng: `-- Sales ghi sự kiện vòng đời đơn vào sales.outbox_messages (đọc bởi get_sales_order_timeline); không còn hàng đợi messaging.`
- [x] **Step 4: Kiểm**
  - `flutter test test/features/sales/data/sales_sql_contract_test.dart` ⇒ 9/9 PASS
  - `grep -rnE "install_module_messaging\('sales'\)|sales\.(inbox_messages|internal_commands|enqueue_outbox_message|claim_)" supabase` ⇒ rỗng
  - `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart` ⇒ 0 error, đúng 3 warning có sẵn
  - `dart run tools/vet45_supabase_migrate/bin/verify_schema_lock_sync.dart` ⇒ `OK`
- [x] **Step 5: Commit** `chore(db): 8-C bỏ messaging schema sales, giữ outbox_messages làm nhật ký sự kiện (sửa migration gốc)`

### Task 6: Tài liệu + kiểm tổng

- [x] **Step 1: TH-05 → 3.1** (ngày 2026-11-08; header dòng 4 ghi `3.1 · 2026-11-08`, giữ `3.0` trong một dòng lịch sử nếu tệp có):
  - dòng 8 "Nguồn đối chiếu — App": bỏ "module `modules/sales/`", thêm `apps/erp/lib/features/sales/{data,logic,presentation}`
  - mục 3 `outbox_messages` (dòng 502): "Nhật ký sự kiện của đơn (5 cột `id`, `tenant_id`, `event_type`, `payload`, `occurred_at`), đọc bởi `get_sales_order_timeline` (BR-36) và chống ghi trùng quyết toán. Không còn hàng đợi messaging / người tiêu thụ (8-C); HĐĐT tự động: trigger, TH-08 KI-20."
  - BR-29 cột cuối (dòng 294): "chưa nối (messaging bỏ ở 8-C); sau 7-4: trigger → `einvoice.internal_commands`"
  - 6.1 (dòng 2087-2090): `Page ─▶ Cubit ─▶ Sales*Repository / ReturnExchangeRepository ─▶ SupabaseRpc ─▶ schema('sales').rpc(...)`; lookups: `SalesPricingRepository`, `ProductRepository`, `PartnerRepository`
  - 6.2: `get_return_exchange_form_policy`, `list_sales_order_cancellation_reasons` ghi "(app không dùng, giữ trong DB)"; dòng `complete_return_exchange` ghi "app không gọi, giữ trong DB"; thêm dòng `audit_sales_review_invariants` — "chỉ đọc, kiểm bất biến; không ai gọi, giữ trong DB"
  - FR-03 (dòng 1239): "Hợp lệ → mở SG-10; lý do nhập dạng chữ, không bắt buộc (KI-12)."
  - 9.1: dòng 1 cột "Sau refactor" thêm "(xong 8-C)"; dòng sự kiện `sales_order_finalized.v1`: "outbox giữ làm nhật ký (8-C); trigger ở 7-4"
- [x] **Step 2: PLAN.md**:
  - dòng 8-C (503): nội dung ghi đúng Q1, Q5 ("`Core*` dời 7-5", "giữ `sales.outbox_messages` làm nhật ký"); cột Plan `✅ [plan](plans/P8/8-C-don-module-sales.md) duyệt <ngày>`; cột Làm `✅ <ngày>`
  - dòng 7-5 (539): thêm "bỏ `CoreExecutionContext` / `CorePermissionChecker` / `CoreTenantAccessChecker` trong `core/session` (chuyển từ 8-C, 2026-11-08)"; giữ nguyên phần còn lại của dòng
  - dòng trạng thái Theme 5 (491), bảng "Theo dõi tiến độ", dòng 9.1 (722) nếu nhắc `modules/sales`
- [x] **Step 3: Kiểm tổng**
  - `grep -rnE "vet45_sales_(domain|application|infrastructure)|ISalesModule|SalesStartup" apps packages tools --include='*.dart' --include='*.yaml'` ⇒ như Task 4 Step 6
  - `ls modules` ⇒ `einvoice partner sales`; `ls modules/sales` ⇒ `integration_events`
  - `cd apps/erp && dart analyze lib test integration_test` ⇒ 0 error, 0 warning mới
  - `cd apps/erp && flutter test` ⇒ không lỗi mới so với `TEST-BASELINE.md`; ghi số
  - `git diff 735ed8704 HEAD --stat -- apps/erp/lib` ⇒ chỉ: 61 tệp mới + `models.dart`, `injection.dart`, các tệp đổi import (`git diff 735ed8704 HEAD -- apps/erp/lib | grep '^[-+]' | grep -v '^[-+]import\|^+++\|^---'` ⇒ chỉ nội dung 62 tệp mới + khối `injection.dart`)
  - `node .gitnexus/run.cjs analyze` + `detect_changes({scope: "compare", base_ref: "735ed8704"})` ⇒ ghi số tệp / symbol; lỗi FTS như 6-C ⇒ ghi lại, xoá cache `.gitnexus` rồi chạy lại
- [x] **Step 4: Commit** `docs(refactor): 8-C cập nhật TH-05 3.1, PLAN.md và kết quả plan 8-C`

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

- Commit: `5afc32c04` (test(sales): 8-C bước 0 — test hợp đồng RPC sales trên migration hiện tại).
- `node .gitnexus/run.cjs detect_changes` lỗi Node (stack trace trong `LocalBackend.callTool`), không có kết quả.
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

### Task 1

- Commit: `6e8d857ab` (4 page test + `salesContractError`), `4a1e4e21d` (detail cubit, list cubit, result body), `b299c2141` (settlement, session cubit), `839ed3548` (checkout page, order detail page), `416308b7f` (flow pages + `sales_contract_fixtures.dart`), `17b424992` (order detail cubit, transaction result cubit, xoá cầu).
- Tệp tạo: `support/sales_contract_error.dart`, `support/sales_contract_error_test.dart` (5 test Step 1 + 11 test so `salesFixture` với `SalesFakeContractFixtureFactory`, xoá nhóm so ở Task 3 Step 0), `support/sales_contract_fixtures.dart` (10 kiểu: `AvailablePostSaleActionsDto`, `CheckoutResultDto`, `SalesOrderResultDto`, `SalesOrderPaymentSummaryDto`, `SalesOrderSettlementDto`, `SalesPaymentTransactionsDto`, `SalesOrderTimelineDto`, `SalesOrderReturnSummaryDto`, `ReturnExchangeDetailDto`, `ReturnExchangeValuationDto` — đúng các kiểu `sales_flow_pages_test` cần; `sales_return_exchange_result_page_test` không cần kiểu nào). Tệp xoá: `support/module_backed_sales_repositories.dart`. `apps/erp/lib` không đổi.
- Fake dùng chung đổi: chỉ `fake_return_exchange_repository.dart`, `final class` thành `class` (để test kế thừa; không đổi hành vi). Không thêm trường nào.
- Test (trước / sau, `+N` giữ nguyên, 0 lỗi; `expect(` trước / sau):

| Tệp | `+N` | `expect(` |
|---|---|---|
| `sales_return_exchange_detail_page_test` | 2 / 2 | 23 / 23 |
| `sales_return_exchange_result_page_test` | 3 / 3 | 15 / 15 |
| `sales_return_exchange_slip_preview_page_test` | 2 / 2 | 8 / 8 |
| `sales_transaction_result_page_test` | 4 / 4 | 11 / 11 |
| `…/sales_return_exchange_detail_cubit_test` | 6 / 6 | 20 / 20 |
| `…/sales_order_list_cubit_test` | 16 / 16 | 39 / 40 |
| `…/sales_transaction_result_body_test` | 7 / 7 | 28 / 28 |
| `…/sales_return_exchange_settlement_cubit_test` | 20 / 20 | 87 / 87 |
| `…/sales_return_exchange_session_cubit_test` | 24 / 24 | 116 / 114 |
| `presentation/sales_checkout_page_test` | 22 / 22 | 89 / 92 |
| `sales_order_detail_page_test` | 28 / 28 | 113 / 115 |
| `sales_flow_pages_test` | 28 / 28 | 117 / 117 |
| `…/sales_order_detail_cubit_test` | 57 / 57 | 269 / 252 |
| `…/sales_transaction_result_cubit_test` | 28 / 28 | 100 / 100 |

  Toàn `flutter test test/features/sales`: +1300 xanh (1284 của Task 0 + 5 test `salesContractError` + 11 test so fixture). `dart analyze test`: 0 error, 0 warning, 18 info có sẵn (không tệp sales).
- Assert bỏ (Q3c, `tenantId` / `actorId`; số dòng của tệp cũ): `sales_order_list_cubit_test.dart:20-21`; `sales_return_exchange_session_cubit_test.dart:250-251`; `sales_order_detail_cubit_test.dart:25-26, 193-194, 197-198, 201-202, 205-206, 209-210, 213-214, 527-528`. Assert bỏ (Q3f): `sales_return_exchange_session_cubit_test.dart:45-48` (`GetReturnExchangeFormPolicyQuery` `isEmpty`). Bỏ 20 `expect(` tenantId / actorId (Q3c) + 3 `expect(` khoá idempotency (lệch plan 5) + 1 `expect(` (Q3f) = 24. Thêm 11 `expect(` để giữ độ chặt (lệch plan 1; vòng sửa 1: giao dịch 2, list 3, checkout page 3, order detail page 2). Khớp bảng: list −2+3, session −2, order detail cubit −17, transaction result cubit −2+2 (về 100), checkout page +3, order detail page +2.
- Lệch plan:
  1. `sales_return_exchange_session_cubit_test`: `.single` ngầm của `PreviewReturnExchangePricingQuery` (dòng 248) thành `expect(previewCalls, hasLength(1))` (thêm 1 `expect(`; thay 2 assert tenant / actor).
  2. Test cần Future treo, hàng đợi lỗi theo lời gọi, thứ tự lời gọi giữa 2 repository (`list`/`search` đếm riêng, settlement, session, order detail) dùng lớp con cục bộ của fake dùng chung (`extends Fake…Repository`) trong tệp test, không sửa fake chung (trừ bỏ `final` ở fake đổi/trả).
  3. `sales_flow_pages_test`: `SalesFakeData.findOrderDetail` (module) thay bằng `_OrderRepo.getDetail` cục bộ dựng cùng đơn cho mã không có trong dữ liệu mẫu (`DH-000129`, `ord_123`, `fake-sales-order`).
  4. `sales_transaction_result_page_test`: tên test bỏ chữ `ISalesModule` / `module`.
  5. Người dùng chốt bỏ như Q3c: 3 assert khoá idempotency tạo phiếu `'sales-receipt:tenant-1:order-1:v7'` / `…:v4` (`sales_order_detail_cubit_test.dart:494`, `sales_transaction_result_cubit_test.dart:241, 276` của tệp cũ) bị bỏ, vì khoá do cầu cũ dựng từ `'tenant-1'`, repository thật dựng từ phiên (`sales_receipt_repository.dart:37`, có test ở `sales_receipt_repository_test.dart:56`). Assert so 2 khoá bằng nhau giữ, viết thành `expect(commands[1], commands[0])`. Tổng assert bỏ: 23 + 1 (Q3f); `expect(` order detail cubit 269 → 252; transaction result cubit sau vòng sửa 1 về 100 (thêm `salesOrderId` và `commands.first == (salesOrderId: 'order-1', expectedVersion: 4)`).
  6. Vòng sửa 1 (review): thêm lại độ chặt "không lời gọi khác": list cubit (`searchCalls` / `listCalls` isEmpty), checkout page (`getResultCalls` isEmpty), order detail page (`confirmCalls` hasLength 1 + lệnh phiếu / đổi trả isEmpty; `queryCount` thêm `cancellationCalls`, `originalCalls`).
- Impact: chỉ sửa tệp test, không sửa symbol Dart trong `lib`; `detect_changes` lỗi Node như Task 0.


### Task 2

- Commit: `72617487e` (12 tệp nhóm B + 2 live test). `apps/erp/lib` không đổi.
- Nhóm `old` bỏ ở 12 tệp (kèm `_FakeRpcClient`, `_OldRpc`, `_ThrowingRpc`, `_oldCode`, `_msgOf`, `_snapshot` và import module chỉ nhóm đó dùng; `dart analyze test/features/sales/data test/features/sales/logic` ⇒ No issues found). Không sửa ca / giá trị nhóm `new`, không sửa `*_parity_expectations.dart`. Số test (tổng trước / sau, đếm `flutter test <tệp> | tail -1`; nhóm `new` đếm bằng `--plain-name "new"` hoặc tên nhóm, bằng tổng sau):

| Tệp (trong `test/features/sales/`) | Trước | Test nhóm `old` | Sau (= nhóm `new`) |
|---|---|---|---|
| `data/return_exchange_rpc_parity_test` | +64 | 44 | +20 |
| `data/sales_cancellation_rpc_parity_test` | +19 | 14 | +5 |
| `data/sales_checkout_errors_test` | +33 | 14 | +19 |
| `data/sales_checkout_rpc_parity_test` | +22 | 11 | +11 |
| `data/sales_draft_rpc_parity_test` | +40 | 20 | +20 |
| `data/sales_order_inquiry_rpc_parity_test` | +32 | 17 | +15 |
| `data/sales_order_read_errors_test` | +18 | 8 | +10 |
| `data/sales_payment_rpc_parity_test` | +16 | 8 | +8 |
| `data/sales_receipt_errors_test` | +25 | 12 | +13 |
| `data/sales_receipt_rpc_parity_test` | +17 | 9 | +8 |
| `logic/sales_checkout_rules_test` | +25 | 12 | +13 |
| `logic/sales_draft_rules_test` | +71 | 32 | +39 |

- Live B (`sales_group_b_s06_s07_live_test.dart`): `di<SalesDraftRepository>()`; `update` / `cancel` / `list` cùng dữ liệu, `expectedVersion`, khoá idempotency, `payloadHash` của update giữ; `cancel` repository không nhận `payloadHash` nên bỏ (`cleanup-hash`, `cancel-hash`); `on AppException` (cùng 2 mã), `isA<AppException>()` + `STALE_DATA`; `listed.page.items` ⇒ `listed.items` và `item.draftId` ⇒ `item.draft.draftId` (kiểu `SalesDraftListEntry`). Live C: `di<SalesCheckoutRepository>().precheck(...)`, tên test đổi.
- Lệch plan: giữ biến `executionContext` + `tenantId` ở cả 2 live test để giữ `expect(tenantId, _tenantId)` (chỉ bỏ `actorId`).
- Test nhóm `old` mà nhóm `new` cùng tệp không có ca tương ứng (chỉ kiểm hành vi riêng của module, app không có đường tương đương): `params_complete` (RPC `complete_return_exchange`, app không gọi — Q6), `hash_start_fixed`, `hash_confirm_fixed` (`return_exchange_rpc_parity_test`), `hash_cancel_fixed` (`sales_cancellation_rpc_parity_test`). `hash_start_fixed` / `hash_confirm_fixed` / `hash_cancel_fixed` trùng `return_exchange_hash_unchanged_start` / `_confirm` (`sales_return_exchange_attempt_factory_test.dart:24,40`) và `cancel_hash_unchanged` (`sales_order_cancellation_attempt_factory_test.dart:8`), cùng đầu vào và giá trị; chỉ `params_complete` không có đường app (Q6).
- Kiểm: `dart analyze integration_test` ⇒ No issues found; `grep -rnE "ISalesModule|SalesContractException|Command\(|Query\(" integration_test --include='*.dart'` ⇒ rỗng.
- Impact: chỉ sửa tệp test, không sửa symbol Dart trong `lib`; `node .gitnexus/run.cjs detect_changes --repo erp-sales-inventory` ⇒ "No changes detected" (chạy trước commit, chỉ số chưa phản ánh tệp test mới sửa).

### Task 3

- Commit `9a3941d81`; commit sửa sau review `9e4fbada0`.
- Step 0: `sales_contract_error_test.dart` bỏ nhóm `salesFixture khớp SalesFakeContractFixtureFactory` (11 test: `AvailablePostSaleActionsDto`, `CheckoutResultDto`, `SalesOrderResultDto`, `SalesOrderPaymentSummaryDto`, `SalesOrderSettlementDto`, `SalesPaymentTransactionsDto`, `SalesOrderTimelineDto`, `SalesOrderReturnSummaryDto`, `ReturnExchangeValuationDto`, `ReturnExchangeDetailDto`, `kiểu chưa hỗ trợ ném UnsupportedError`), hàm `_planSig` / `_valuationSig` và import `testing.dart` + `sales_contract_fixtures.dart`; còn 5 test `salesContractError` (`flutter test` ⇒ +5).
- **Lệch plan: 64 tệp chép ban đầu, không phải 61 (sau chốt còn 63).** Danh sách mục 3 thiếu 3 tệp app dùng nhưng nằm ngoài `src/shared`: `checkout_blocker_codes.dart` (`sales_order/shared`), `sales_order_draft_contract_mapper.dart` (`sales_order_draft/shared`; `SalesDraftJson` dùng `SalesOrderDraftContractMapper`, `SalesOrderDraftReadRow`, `SalesOrderDraftLineReadRow`), và `paged_sales_order_draft_list_dto.dart` (`shared`, mapper kéo theo). Phát hiện vì `dart analyze` báo `Undefined name` sau khi đổi import; chép thêm, import `../../shared/` của mapper đổi sang cùng thư mục. Barrel `data/models.dart` 64 dòng `export` (sau chốt: 63).
- Step 2: `diff` bỏ dòng `import` cho 64 tệp ⇒ không khác; `grep -h "^import 'package" contracts/*.dart` ⇒ rỗng.
- Step 3: đổi import (không tính `injection.dart`, `sales_runtime_registration_test.dart` — giữ nguyên cho Task 4, vì còn dùng `ISalesModule`): `lib` 84 tệp, `test` 65, `integration_test` 3, `example/lib` 5. Giữ prefix `as app` / `as sales` và `hide` ở `sg13_return_result_tab.dart`. Không phải `hide` / `show` nào (không trùng tên với `data/models/*.dart`). Không có tệp import trùng barrel.
- Step 4: `grep -rln "vet45_sales_" apps/erp --include='*.dart'` ⇒ 7 tệp: 2 tệp mong đợi + 5 tệp `lib` chỉ còn tên trong doc comment (`sales_draft_repository`, `sales_checkout_repository`, `mappers/sales_draft_json`, `mappers/sales_checkout_json`, `presentation/lookups/sales_pricing_ports`); không sửa vì ràng buộc `lib` chỉ đổi import. `dart analyze lib test integration_test` ⇒ 228 issues (đều `info`), bằng trước khi sửa, 0 error, 0 warning; `example`: `dart analyze lib` ⇒ 2 issues (`info`, deprecated), 0 error. `flutter test test/features/sales` ⇒ +1088 All passed (trước Step 0 là 1099).
- **Chốt sau review (commit sửa):** giữ `sales_order_draft_contract_mapper.dart` + `paged_sales_order_draft_list_dto.dart` (tổng 63, `SalesDraftJson` cần). Bỏ `checkout_blocker_codes.dart` khỏi `contracts/` + barrel (chỉ test dùng, Q3(d)): `sales_flow_pages_test.dart:592`, `sales_checkout_page_test.dart:332,476` dùng chuỗi `'RECEIVABLE_DUE_DATE_REQUIRED'`. Sửa chú thích nguồn kiểu ở `sales_checkout_repository.dart:9`, `sales_draft_repository.dart:8`, `mappers/sales_draft_json.dart:5`, `mappers/sales_checkout_json.dart:5` ⇒ `data/models.dart`. `grep -rln "vet45_sales_" apps/erp --include='*.dart'` ⇒ `injection.dart`, `sales_runtime_registration_test.dart`, `sales_pricing_ports.dart` (chỉ chú thích). `dart analyze lib test` 0 error, 0 warning; 2 tệp test +28 / +22 không đổi; `flutter test test/features/sales` ⇒ +1088.
- Impact: `impact MoneyDto` ⇒ chọn nhầm `MoneyDto` của `pricing_common.dart` (CRITICAL, 1076) không phải kiểu sales; thay đổi chỉ là dòng `import` + tệp chép mới, không sửa thân symbol nào. `detect_changes` ⇒ 157 tệp, 3 symbol (tệp test), 0 process, risk low.

### Task 4

- Commit `fd7c6088f` (xoá module + DI + pubspec + test); `chore(sales): 8-C dọn góp ý nhỏ review Task 1, 3` (3 góp ý nhỏ + 3 sửa chữ ở Task 1, 3 của kế hoạch).
- Step 1 impact: `impact initDependencies --direction upstream` ⇒ CRITICAL (1081 symbol, 864 trực tiếp; đếm gộp mọi nơi gọi hàm cùng tên `build`). Vẫn làm: chỉ bỏ một đăng ký DI không còn ai lấy (`ISalesModule`).
- Step 2 đỏ: `sales_runtime_registration_test.dart` viết lại, (1) `ERP DI source has no sales module` FAIL, (2) `initDependencies registers sales repositories` PASS. Step 3 xanh: 2/2 PASS. `injection.dart` bỏ 2 import `vet45_sales_*`, khối `SalesStartup`, `registerSingleton<ISalesModule>`; chú thích dòng 91 sửa; giữ `executionContext`, `permissionChecker`, `tenantAccessChecker`, khối einvoice (Q5).
- Step 4: `git status --short modules/sales` sạch trước khi xoá; `git rm -r` + `rm -rf` phần còn lại của `modules/sales/{domain,application,infrastructure}`; `ls modules/sales` ⇒ `integration_events`. Dòng bỏ: `pubspec.yaml:20-22`; `apps/erp/pubspec.yaml:22-24`; `apps/erp/example/pubspec.yaml:17-18, 56-61` (giữ mọi dòng `integration_events`).
- Step 5 `pub get` ở gốc, `apps/erp`, `apps/erp/example`, `modules/einvoice/presentation/example` ⇒ không lỗi phân giải.
- Step 6: grep ⇒ chỉ chuỗi cấm trong `group_f_no_demo_contract_test.dart:65`, chuỗi trong test Step 2 (1) và 3 tệp `packages/vet45_generator/test` (chuỗi tên gói trong test sinh mã, không phải phụ thuộc). `dart analyze lib test integration_test` ⇒ 228 issues (đều `info`), 0 error, 0 warning; `example`: 2 issues (`info`), 0 error. `flutter test` (apps/erp) ⇒ +2737 / -55 = 53 + 2 ⚠️ như mốc "Sau 6-C" (số lỗi khớp); `flutter test test/features/sales test/core` ⇒ +1185 xanh. einvoice: `application` 217 / 1, `infrastructure` 378 / 60 (như mốc, không lỗi biên dịch mới).
- Đối chiếu lỗi theo tên: `flutter test -r json` ⇒ 55 test lỗi; 53 có trong danh sách `apps/erp` của `TEST-BASELINE.md`, 2 là ⚠️ `product_guided_create_e2e_test` (duplicate SKU) và `product_change_history_e2e_test` (mục "Sau 5-C"). Không có tên nào ngoài mốc.
- `detect_changes` ⇒ 8 tệp, 2 symbol (fake trong test DI), 0 process, risk low.
- Dọn góp ý nhỏ (commit `3aca0dad0`): `sales_order_detail_page_test.dart` thêm `salesModule.payments.recordCalls` vào danh sách "không lệnh khác" của test huỷ; `sales_checkout_page_test.dart:427` thụt lề; bỏ `depend_on_referenced_packages` ở 39 tệp test sales (25 dòng riêng + 14 dòng gộp) (`dart analyze` vẫn 0 warning, `flutter test test/features/sales` ⇒ +1088).

### Task 5

- Commit: xem `git log` (`chore(db): 8-C bỏ messaging schema sales, giữ outbox_messages làm nhật ký sự kiện (sửa migration gốc)`).
- Dòng đổi: `20260623000002_install_module_messaging_modules.sql:4` xoá. `20260830005_sales_rebuild_schema.sql`: `:5` thêm `sales.outbox_messages` vào `Touches`; `:7` bỏ `platform.install_module_messaging(text);`; `:8` thêm dòng 8-C; `:12-24` (thay dòng 11 cũ) `create schema` + `create table` + index + RLS + revoke (trước `grant usage on schema sales`); `:45` chú thích 4 dòng cũ (32-35) thành 1 dòng.
- Đỏ: `flutter test .../sales_sql_contract_test.dart` ⇒ +6 -3: 5 `kept` PASS; `removed`: `sales no longer installs messaging`, `creates sales.outbox_messages directly`, `creates outbox before any sales function uses it` FAIL. **Lệch plan:** `sales has no inbox, internal commands or queue functions` PASS ngay từ đầu (không đỏ) vì `install_module_messaging` dựng tên hàm bằng SQL động nên chuỗi `sales.inbox_messages` không có sẵn trong tệp; vẫn giữ làm chốt chặn.
- Xanh: sau sửa ⇒ 9/9 PASS.
- Grep `install_module_messaging\('sales'\)|sales\.(inbox_messages|internal_commands|enqueue_outbox_message|claim_|complete_[a-z_]*message|receive_integration_event)` trong `supabase` ⇒ rỗng. `REGISTRY.yaml` / `schema.lock.yaml`: không có mục messaging của sales (chỉ khớp tên tệp `20260904001_sales_normalize_outbox_and_commands.sql`, không phải mục messaging).
- `detect_changes` (compare với `7c9f91540~1`, sau `analyze`): 21 tệp, 25 symbol, 0 process, risk low; số này gồm cả commit dọn góp ý Task 4, 5 và tài liệu Task 6 chưa commit lúc đo. Thay đổi của Task 5 chỉ là SQL (2 migration): 0 symbol Dart.
- `verify_migration_policy` ⇒ 0 error, 3 warning có sẵn (`registry_consistency`: 2 tệp `20261101001`, `20261104001`). `verify_schema_lock_sync` ⇒ `OK (sources match schema.lock.yaml)`.

### Task 6

- Commit dọn góp ý Task 4, 5: `26aa5263a`; commit tài liệu: xem `git log` (`docs(refactor): 8-C cập nhật TH-05 3.1, PLAN.md và kết quả plan 8-C`).
- Dọn góp ý Task 4, 5 (`26aa5263a`): `sales_sql_contract_test.dart` thêm assert `on sales.outbox_messages (tenant_id, (payload ->> 'salesOrderId'), occurred_at)` trong `creates sales.outbox_messages directly`, thêm dòng trống trước `group('removed'` ⇒ `flutter test` 9/9; bỏ `// ignore_for_file: implementation_imports` ở 12 tệp `test/features/sales/{data,logic}` (không tệp nào còn import `package:*/src/`; `dart analyze` các thư mục `data`, `logic`, `support` ⇒ No issues); `support/sales_contract_fixtures.dart:5-6` chú thích đổi thành "chép từ SalesFakeContractFixtureFactory (module sales cũ, đã xoá ở 8-C)"; sửa Kết quả Task 4, 5 (39 tệp, hash `3aca0dad0`, bỏ mệnh đề không đối chiếu tên, mẫu grep `complete_[a-z_]*message`, dòng `detect_changes` Task 5).
- Step 1 TH-05 (`docs/02-yeu-cau/TH-05-ban-hang-va-don-hang.md`, đổi theo nội dung; tệp không có dòng lịch sử `3.0`): `:4` `3.1 · 2026-11-08`; `:8` bỏ module `modules/sales/`, thêm `apps/erp/lib/features/sales/{data,logic,presentation}`; `:294` BR-29 cột cuối; `:502` `outbox_messages` (bỏ câu "Người tiêu thụ hiện có: messaging worker…"); `:1239` FR-03; `:2087-2088` 6.1; `:2116-2117` `list_sales_order_cancellation_reasons` tách dòng riêng "(app không dùng, giữ trong DB)"; `:2120-2121` `get_return_exchange_form_policy` tách dòng riêng, cùng ghi chú; `:2128-2130` `complete_return_exchange` tách dòng "app không gọi, giữ trong DB" + dòng mới `audit_sales_review_invariants`; `:2256` 9.1 dòng 1 thêm "(xong 8-C)"; `:2259` dòng `sales_order_finalized.v1`. **Ngoài brief:** `:2143` (6.3, dòng HĐĐT) "hiện: `sales.outbox_messages` → messaging worker" ⇒ "hiện chưa nối: messaging bỏ ở 8-C", vì câu cũ sai sau 8-C. Giữ nguyên các bảng, không thêm mục.
- Step 2 PLAN.md (`docs/refactor/PLAN.md`): `:503` hàng 8-C ghi lại Q1, Q5 (bỏ câu "bỏ `Core*`… chỉ phục vụ module cũ" và "bỏ outbox / inbox" đã sai), cột Làm `✅ 2026-11-08`, cột Review giữ `⬜`; `:539` hàng 7-5 thêm "bỏ `CoreExecutionContext` / `CorePermissionChecker` / `CoreTenantAccessChecker` trong `core/session` (chuyển từ 8-C, 2026-11-08)" và "trừ `integration_events`" ở phần 6-C, 8-C; `:491` dòng Trạng thái Theme 5 thêm "2026-11-08: 8-C xong (Làm ✅, chờ review)"; `:520` "Integration event: bỏ outbox" ⇒ "bỏ messaging; `sales.outbox_messages` giữ làm nhật ký (8-C)" (ngoài brief, sai sau 8-C); `:793` "Theo dõi tiến độ" Theme 5 từ ⬜ sang 🔄 với ghi chú. Hàng 9.1 (`:722`) đã ghi "8-C sales", không sửa.
- Step 3:
  - `grep -rnE "vet45_sales_(domain|application|infrastructure)|ISalesModule|SalesStartup" apps packages tools --include='*.dart' --include='*.yaml'` ⇒ chỉ 2 chuỗi cấm trong `sales_runtime_registration_test.dart:40-41` và chuỗi tên gói trong 2 tệp `packages/vet45_generator/test` (6 dòng); như Task 4 Step 6.
  - `ls modules` ⇒ `einvoice partner sales`; `ls modules/sales` ⇒ `integration_events`.
  - `dart analyze lib test integration_test` ⇒ 228 issues (đều `info`), 0 error, 0 warning (bằng Task 4).
  - `flutter test` (apps/erp, `-r json`) ⇒ +2741 / -55, 0 skip. Đối chiếu theo tên với `TEST-BASELINE.md`: 53 lỗi nằm trong danh sách `apps/erp` (đủ 53, không thiếu), 2 là ⚠️ `product_guided_create_e2e_test` (duplicate SKU) và `product_change_history_e2e_test` (mục "Sau 5-C"). Không lỗi mới. Danh sách: `.superpowers/sdd/8-C-don-module-sales/failed-names.txt`.
  - `git diff 735ed8704 HEAD --stat -- apps/erp/lib` ⇒ 149 tệp: 64 mới (63 trong `data/models/contracts/` + `data/models.dart`), 85 sửa. Lọc `^[-+]` bỏ `import`: chỉ còn nội dung tệp mới, khối `SalesStartup` / `ISalesModule` và chú thích `injection.dart` (chú thích dòng 89), 4 chú thích đổi chữ (`sales_checkout_repository.dart`, `sales_draft_repository.dart`, `mappers/sales_draft_json.dart`, `mappers/sales_checkout_json.dart`). Không gì khác.
  - GitNexus: lần `analyze` đầu lỗi (`copyNodeCSVs`/`copyCsvWithRetry`, `lbug-adapter`), chạy lại lần 2 không xoá cache ⇒ thành công (index 3952 tệp, 46631 node, 100608 cạnh, `lastCommit` `26aa5263a`). `detect_changes --scope compare --base-ref 735ed8704` ⇒ 191 tệp, 229 symbol, 0 process, risk low (CLI hỗ trợ compare). Symbol `lib`: `SalesCheckoutJson`, `SalesDraftJson`, `SalesCheckoutRepository`, `SalesDraftRepository` (chỉ chú thích); còn lại là test và tiêu đề tài liệu. Không có bảng `impact`: Task này chỉ sửa chú thích tài liệu và test, không sửa thân symbol Dart nào.
- Commit dọn góp ý `26aa5263a` cũng chạy `dart format` trên `sales_sql_contract_test.dart` (rộng 100 cột).
- Fix round 1 (sau review Task 6, commit xem `git log`: `docs(refactor): 8-C sửa chữ outbox sales ở PLAN 9.x / TH-05 8 và góp ý nhỏ review Task 6`): PLAN 9-2 và 9.4 thêm ngoại lệ `sales.outbox_messages`; TH-05 bảng mục 8 (`:2226`) ghi giữ `sales.outbox_messages` làm nhật ký; TH-05 9.1 dùng đúng tên lớp repository và `SalesPricingRepository`; TH-05 `:8` một đường dẫn; PLAN `:491` thêm dấu `; `; PLAN `:539` dời mệnh đề `Core*` sau `vet45_adapters`, `vet45_generator`.
- Không động `TEST-BASELINE.md`.

## 9. Review

<!-- Chỉ phiên review ghi. -->
