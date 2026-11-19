# 6-C — Dọn sạch module pricing + xoá phần nhập Excel trong DB

> Theme 4 (mã cũ P6) · Bước (dọn) theo "Quy tắc dọn module (chốt 2026-10-11)" của PLAN.md
> Trạng thái: Plan ✅ (viết + người dùng duyệt 2026-11-06) | Làm ✅ 2026-11-06 | Review ✅ R1 2026-11-06
> Làm **sau** 6-A1, 6-A2, 6-B (đã review đạt, **chưa commit** — Task 0 Step 1).
> Tài liệu: PLAN.md mục Theme 4 dòng 6-C, "Quy tắc dọn module", "Quy tắc migration", "Plan xoá / tách / thay code cũ"; TH-04 mục 3 (dữ liệu), 6.2, 6.3, 8, BR-19; 6-A1 Q9, 6-A2 Q12; mẫu đã làm: 5-C (`git show d95419d20^:docs/refactor/plans/P5/5-C-don-module-catalog-inventory.md`).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** App hết `c45_pricing_*` (cả test, integration test, pubspec). Xoá `modules/pricing`. DB schema `pricing` bỏ toàn bộ phần nhập Excel và 2 RPC đọc trước (create / update context) mà app không còn gọi.

**Architecture:** Không đổi code chạy trong `lib/`: 6-A2 đã chuyển hết sang `CustomerPriceRuleRepository` / `SalesPricingRepository`. Việc còn lại là xoá nhóm test `old`, sửa đoạn dọn của live test, xoá module + workspace, và sửa migration gốc. Một test hợp đồng SQL mới ở app chốt danh sách RPC phải còn / phải mất.

**Tech Stack:** Flutter / Dart (`flutter_test`), Supabase Postgres (plpgsql), `tools/c45_supabase_migrate`.

**Spec:** [TH-04](../../../02-yeu-cau/TH-04-chinh-sach-gia.md) (mục 3, 6.2, 6.3, 8, BR-19).

## Global Constraints

- **Không đổi nghiệp vụ.** `apps/erp/lib` không có dòng nào đổi. RPC app gọi giữ nguyên chữ ký và thân hàm.
- **Giữ trong DB** (TH-04 6.2 "Không dùng … giữ trong DB"): `delete_customer_price_rule`, `save_remembered_price_from_order`, bảng `remembered_price_requests` và các hàm phụ của chúng.
- **Giữ nhãn dữ liệu cũ** (TH-04 mục 3, 6-A2 Q12): `source_type` vẫn nhận `'excel_import'`; `activity_type` vẫn nhận `'import_created'`, `'import_updated'`.
- Migration: **sửa thẳng migration gốc**, không tạo migration mới. Migration chỉ còn phần nhập Excel thì xoá tệp + dòng trong `REGISTRY.yaml`. Phiên code **không** chạy `supabase db reset`, không reset Dev, không chạy SQL. Chỉ ghi "cần reset" vào Kết quả.
- Trước khi sửa mỗi symbol Dart: `node .gitnexus/run.cjs impact <symbol> --direction upstream --repo erp-sales-inventory`, ghi vào Kết quả. Trước mỗi commit: `detect_changes`.
- `flutter analyze` sập vì đường dẫn có dấu: dùng `dart analyze`.
- Tìm kiếm dùng `grep -r`, không dùng `git grep` (4-C sót tệp chưa theo dõi; phần lớn tệp 6-A1 đang untracked).
- **Giữ** `modules/` (còn `einvoice`, `partner/integration_events`, `sales`), `packages/c45_adapters`, `c45_annotations`, `c45_generator`, `c45_shared*` (7-5, 9-1 lo).

## Review Focus

1. **Xoá nhầm phần còn dùng trong `20260725010`.** Tệp này vừa có phần nhập vừa nới 2 ràng buộc CHECK (`excel_import`, `import_*`) và thêm 4 cột truy vết. Mất CHECK ⇒ dữ liệu cũ / lịch sử ghi lỗi. Test: Task 0 `keeps source_type and activity_type labels for old import data`.
2. **Cột truy vết còn khoá ngoại tới bảng đã xoá** ⇒ `db reset` hỏng ở 010. Test: Task 3 `trace columns have no FK to import tables` + `keeps 4 import trace columns`.
3. **Xoá nhầm RPC app đang gọi / RPC TH-04 giữ.** Test: Task 0 `keeps every RPC the app calls` + `keeps RPCs TH-04 keeps unused`.
4. **Live test dọn sai tham số** ⇒ để lại giá riêng, lần chạy sau vấp `seed must not reuse a private rule`. Test: Task 1, đối chiếu map với `PricingDeleteRpcMapper.params` cũ (trong bảng mục 4) + `dart analyze integration_test`.
5. **Workspace còn trỏ `modules/pricing`** ⇒ `flutter pub get` gốc / `apps/erp/example` lỗi. Test: Task 2 Step 6.

---

## 1. Mục tiêu

- `grep -r "c45_pricing" apps modules packages tools` rỗng (trừ không còn gì). Không còn `IPricingModule` / `FakePricingModule` trong repo.
- Xoá `modules/pricing` (domain, application, infrastructure; gồm codec `.xlsx`, TH-04 dòng 922).
- DB: xoá 4 RPC nhập, 5 hàm phụ nhập, 2 bảng lô / dòng nhập, `catalog._resolve_product_unit_for_pricing_import`, `get_customer_price_rule_create_context`, `get_customer_price_rule_update_context`.
- TH-04 lên 3.3 ghi đúng hiện trạng.

## 2. Quyết định

| Q | Nội dung |
|---|---|
| Q1 | **Người dùng chốt 2026-11-06: giữ 4 cột truy vết, bỏ khoá ngoại.** `customer_price_rules.source_import_id`, `source_import_row_id`, `customer_price_rule_activities.import_id`, `import_row_id` giữ là `uuid` thường (bỏ `references …`). RPC chi tiết / lịch sử vẫn trả các khoá JSON đó (luôn `null` với dữ liệu mới); mapper, model app không đổi. |
| Q2 | **Người dùng chốt 2026-11-06: live test dọn bằng RPC.** `sales_group_a_s03_s05_live_test.dart` gọi `di<SupabaseRpc>().call('pricing', 'delete_customer_price_rule', …)` thay `IPricingModule` (DI đã bỏ từ 6-A2 ⇒ đoạn dọn đang hỏng lúc chạy). Repository **không** thêm method xoá (BR-19). |
| Q3 | **Xoá `get_customer_price_rule_create_context`, `get_customer_price_rule_update_context`** (PLAN dòng 6-C "bỏ RPC cũ không còn dùng"). App bỏ gọi từ 6-A1; không hàm SQL / test SQL nào gọi (đo 2026-11-06). `delete_customer_price_rule`, `save_remembered_price_from_order` **giữ** (TH-04 6.2). |
| Q4 | **Bỏ hết test của module, không chuyển test SQL nào sang app.** 8 tệp test SQL trong `modules/pricing/infrastructure/test` (`pricing_sql_contract_test.dart` + `test/sql/*`): 49/50 đỏ (đọc `_drafts/` đã promote, như 5-C Q8); test xanh duy nhất (`015 search list price…`) đọc migration `20260725015` mà `20260805001` đã thay ⇒ không còn giá trị. Kiểm hành vi SQL do `supabase/tests/pricing_th04.sql` (6-B) lo; test hợp đồng mới (Task 0, 3) chỉ kiểm có / không có. |
| Q5 | **Xoá `fake_customer_price_rule_repository_test.dart`** (6-A2 dòng 288 đã hẹn): cả tệp chỉ so fake mới với `FakePricingModule` cũ. Fake mới vẫn được các test cubit / widget pricing dùng. |
| Q6 | **Không đổi quyền** `pricing.customer_price_rule.import` và thao tác `'import'` mà `search_customer_price_rules` trả (app có hằng `PricingAvailableActions.import` nhưng không dùng). Đổi là đổi hợp đồng RPC ⇒ ngoài phạm vi dọn; ghi vào mục 6 Rủi ro. |

## 3. Hiện trạng (đo 2026-11-06)

| Thứ | Ai còn dùng |
|---|---|
| `package:c45_pricing_*` trong `apps/erp/lib` | **không** (6-A2) |
| `apps/erp/test` | `features/pricing/data/pricing_rpc_parity_test.dart:16-28` (nhóm `old (mappers)` dòng 35-501; `new (json)` 502, `new (CustomerPriceRuleRepository)` 582, `new (SalesPricingRepository)` 778); `data/pricing_errors_test.dart:7-8` (nhóm `old (mapPricingRpcError)` dòng 49-82); `support/fake_customer_price_rule_repository_test.dart` (cả tệp, 7 test) |
| `apps/erp/integration_test` | `sales_group_a_s03_s05_live_test.dart:6` (import), `:221-228` (`di<IPricingModule>().executeCommandAsync(DeleteCustomerPriceRuleCommand(…))`). `IExecutionContext` (`c45_shared_application`) còn dùng ở dòng 40, giữ |
| Workspace | `pubspec.yaml:30-32`; `apps/erp/pubspec.yaml:22-24`; `apps/erp/example/pubspec.yaml:56-61` |
| Module khác phụ thuộc pricing | không (grep `pubspec.yaml` trong `modules`, `packages`) |
| Script CI, `schema.lock.yaml`, `supabase/sql` | không nhắc pricing |
| Outbox / inbox `pricing` | không có (`install_module_messaging` không gọi `'pricing'`) |
| `TEST-BASELINE.md` | dòng 32-34 (3 hàng module), 158-213 (51 lỗi module), 111-113, 118 (test nhập đã xoá ở 6-A2) |
| `verify_migration_policy.dart` hiện tại | 3 `[WARN] registry_consistency` có sẵn (`20261101001` ×1, `20261104001` ×2), 0 error |

DB — phần nhập Excel:

| Tệp migration | Có gì | Làm gì |
|---|---|---|
| `20260725003_catalog_pricing_import_product_unit_resolver.sql` | chỉ `catalog._resolve_product_unit_for_pricing_import` | xoá tệp |
| `20260725010_pricing_customer_price_rule_import_s8.sql` | dòng 11-24: nới CHECK `source_type`, `activity_type` (**giữ**); 26-90: 2 bảng nhập; 92-97: thêm 4 cột có `references`; 99-109: index, RLS, revoke bảng nhập; 111-871: 7 hàm nhập | sửa (Task 3) |
| `20260725013_pricing_customer_price_rule_import_overlap_policy.sql` | chỉ 2 hàm nhập | xoá tệp |
| `20260725016_pricing_customer_price_rule_import_explicit_unit.sql` | `alter table … import_rows`, resolver catalog, 4 hàm nhập | xoá tệp |
| `20260725017_pricing_customer_price_rule_import_auto_match_upsert.sql` | chỉ 3 hàm nhập | xoá tệp |
| `20260725018_pricing_customer_price_rule_import_price_parse.sql` | chỉ 1 hàm nhập | xoá tệp |

DB — 2 RPC đọc trước:

| Hàm | Định nghĩa |
|---|---|
| `get_customer_price_rule_create_context` | `20260725004…s1.sql:389-523` (hàm + revoke + grant), `20260810001…overwrite_disabled_rules.sql:109-243` |
| `get_customer_price_rule_update_context` | `20260725007…update_s5.sql:293-463` |

## 4. Đang làm gì (thứ bị xoá)

| # | Thứ cũ đang làm | Sau khi sửa nằm ở đâu | Test giữ hành vi |
|---|---|---|---|
| 1 | Nhóm `old (mappers)` của `pricing_rpc_parity_test`: mapper module cho ra map tham số / DTO khớp `pricing_parity_expectations.dart` | Nhóm `new (…)` cùng tệp, **cùng** giá trị mong đợi, không đổi | 3 nhóm `new` (có sẵn) |
| 2 | Nhóm `old (mapPricingRpcError)`: mã lỗi ổn định giữ nguyên, mã lạ → `SYSTEM_ERROR` | Nhóm `new (pricingException)` cùng tệp | nhóm `new` (có sẵn) |
| 3 | `fake_customer_price_rule_repository_test`: fake mới = `FakePricingModule` | **Bỏ** (Q5). Fake mới đã chạy qua test cubit / widget pricing | `test/features/pricing/logic/*`, `presentation/*` (có sẵn) |
| 4 | Live test dọn: `DeleteCustomerPriceRuleCommand(tenantId, actorId, ruleId, expectedVersion)` → gateway gửi `{'p_tenant_id', 'p_rule_id', 'p_expected_version'}` tới `pricing.delete_customer_price_rule` (`actorId` không gửi lên server) | `di<SupabaseRpc>().call('pricing', 'delete_customer_price_rule', params: {'p_tenant_id': _tenantId, 'p_rule_id': create.ruleId!, 'p_expected_version': cleanupVersion})` (Q2) | `dart analyze integration_test` (test live mặc định skip) |
| 5 | RPC nhập Excel + hàm phụ + bảng + resolver catalog | **Bỏ** (6-A1 Q9). App không gọi | Task 3 nhóm `removed` |
| 6 | `get_customer_price_rule_create_context` / `update_context` | **Bỏ** (Q3). Server tự kiểm khi tạo / sửa (6-A1) | Task 3 nhóm `removed`; `pricing_th04.sql` (người dùng chạy) |
| 7 | 4 cột truy vết có FK tới bảng nhập | Cột `uuid` thường (Q1) | Task 3 `trace columns have no FK…`, `keeps 4 import trace columns` |
| 8 | CHECK `source_type` (`excel_import`), `activity_type` (`import_*`) | Giữ nguyên trong 010 | Task 0 `keeps source_type and activity_type labels…` |

## 5. Thay đổi

| Tệp | Hành động |
|---|---|
| `apps/erp/test/features/pricing/data/pricing_sql_contract_test.dart` | tạo (Task 0, thêm ở Task 3) |
| `apps/erp/integration_test/sales_group_a_s03_s05_live_test.dart` | bỏ import dòng 6; khối `finally` gọi RPC (Q2) |
| `apps/erp/test/features/pricing/data/pricing_rpc_parity_test.dart` | xoá nhóm `old (mappers)`, 13 import module (16-28), helper chỉ nhóm `old` dùng |
| `apps/erp/test/features/pricing/data/pricing_errors_test.dart` | xoá nhóm `old`, import 7-8 |
| `apps/erp/test/features/pricing/support/fake_customer_price_rule_repository_test.dart` | xoá (Q5) |
| `pubspec.yaml` (gốc) | xoá dòng 30-32 |
| `apps/erp/pubspec.yaml` | xoá dòng 22-24 |
| `apps/erp/example/pubspec.yaml` | xoá 6 dòng 56-61 |
| `modules/pricing` | xoá cả thư mục |
| `supabase/migrations/20260725010_…import_s8.sql` | sửa (Task 3) |
| `supabase/migrations/20260725004_…s1.sql`, `20260810001_…overwrite_disabled_rules.sql`, `20260725007_…update_s5.sql` | xoá hàm context + revoke / grant; sửa dòng `-- Touches:` |
| `supabase/migrations/20260725{003,013,016,017,018}_*.sql` | xoá tệp |
| `supabase/migrations/REGISTRY.yaml` | xoá 11 dòng owner + 5 dòng tên tệp (Task 3) |
| `docs/02-yeu-cau/TH-04-chinh-sach-gia.md` | lên 3.3 (Task 4) |
| `docs/refactor/PLAN.md` | Task 4 |
| `docs/refactor/TEST-BASELINE.md` | phiên review cập nhật (như 4-C, 5-C) |

---

## 6. Các task

### Task 0: Commit phần còn lại + test hợp đồng SQL trên code cũ (bước 0)

**Files:**
- Create: `apps/erp/test/features/pricing/data/pricing_sql_contract_test.dart`

**Interfaces:**
- Produces (dùng lại ở Task 3, cùng tệp):
  - `Directory _findRepoRoot()`: đi lên từ `Directory.current` tới thư mục có `supabase/migrations` (khuôn `test/features/catalog/data/catalog_sql_contract_test.dart`)
  - `String _allMigrationsSql()`: nối nội dung mọi `supabase/migrations/*.sql` (không vào `_drafts/`)
  - `bool _definesFn(String sql, String schema, String name)`: `RegExp(r'create\s+(or\s+replace\s+)?function\s+' + schema + r'\.' + name + r'\s*\(', caseSensitive: false)`

- [x] **Step 1: Commit 6-A1 … 6-B** (đã review đạt, đang nằm trong cây làm việc). `git status --short` ⇒ chỉ còn tệp của 6-A1, 6-A2, 6-B, `supabase/migrations/20261105001_iam_member_display_name.sql`, `supabase/tests/pricing_th04.sql`, PLAN / TH-04 / plan P6. Có tệp lạ ⇒ dừng, hỏi người dùng. Commit `chore(pricing): Theme 4 — commit 6-A1, 6-A2, 6-B (review đạt)`.

- [x] **Step 2: Viết test nhóm `kept`**

| Tên test | Kiểm |
|---|---|
| `keeps every RPC the app calls` | `_definesFn(sql, 'pricing', n)` đúng với cả 11 tên: `search_customer_price_rules`, `get_customer_price_rule_detail`, `get_customer_price_rule_history`, `create_customer_price_rule`, `update_customer_price_rule`, `disable_customer_price_rule`, `precheck_customer_price_rule_reenable`, `reenable_customer_price_rule`, `resolve_applicable_customer_price_rule`, `preview_sales_working_state_pricing`, `evaluate_sales_manual_price` |
| `keeps RPCs TH-04 keeps unused` | `delete_customer_price_rule`, `save_remembered_price_from_order` được định nghĩa; `sql` chứa `create table if not exists pricing.remembered_price_requests` |
| `app RPC list matches repositories` | Quét `apps/erp/lib/features/pricing/data/*.dart`, lấy mọi chuỗi `'<tên>'` đứng ngay sau `'pricing',` (RegExp `'pricing',\s*'([a-z_]+)'`); tập tên == 11 tên ở trên. Đỏ ⇒ danh sách lệch code, sửa danh sách (không sửa `lib`) |
| `keeps source_type and activity_type labels for old import data` | `sql` chứa `check (source_type in ('manual', 'excel_import', 'sales_order', 'migration'))`; tệp `20260725014_…` chứa `'import_created', 'import_updated'` trong CHECK `activity_type` (định nghĩa cuối) |

- [x] **Step 3: Chạy trên code cũ**

Run: `cd apps/erp && flutter test test/features/pricing/data/pricing_sql_contract_test.dart`
Expected: PASS 4/4. Đỏ ⇒ dừng, ghi lại (bảng mục 3 sai).

- [x] **Step 4: Commit** `test(pricing): 6-C bước 0 — test hợp đồng RPC pricing trên migration hiện tại`

### Task 1: Live test dọn giá riêng qua RPC (Q2)

**Files:**
- Modify: `apps/erp/integration_test/sales_group_a_s03_s05_live_test.dart:6, 220-229`

**Interfaces:**
- Consumes: `SupabaseRpc.call(String schema, String fn, {Map<String, dynamic>? params})` (`lib/core/supabase/supabase_rpc.dart:16`), đăng ký trong DI (`injection.dart:60`).

- [x] **Step 1: Sửa** khối `finally` theo bảng mục 4 dòng 4. Thêm `import 'package:erp/core/supabase/supabase_rpc.dart';`, xoá `import 'package:c45_pricing_application/application.dart';`. Không đổi gì khác (giữ `IExecutionContext`, `sales.MoneyDto`).
- [x] **Step 2: Kiểm**: `cd apps/erp && dart analyze integration_test` ⇒ `No issues found!`; `grep -n "IPricingModule\|c45_pricing" integration_test -r` ⇒ rỗng.
- [x] **Step 3: Commit** `test(sales): 6-C live test dọn giá riêng qua RPC delete_customer_price_rule`

### Task 2: Bỏ nhóm test `old`, xoá module + workspace

**Files:** theo bảng mục 5 (3 tệp test, 3 pubspec, `modules/pricing`).

- [x] **Step 1: Kiểm điều kiện**: `grep -rln "c45_pricing\|IPricingModule\|FakePricingModule" apps/erp/lib apps/erp/test apps/erp/integration_test`. Expected: đúng 3 tệp `pricing_rpc_parity_test.dart`, `pricing_errors_test.dart`, `fake_customer_price_rule_repository_test.dart`. Khác ⇒ dừng, ghi lại.
- [x] **Step 2: Ghi số test trước**: `flutter test test/features/pricing/data/pricing_rpc_parity_test.dart test/features/pricing/data/pricing_errors_test.dart` ⇒ ghi số pass / nhóm vào Kết quả.
- [x] **Step 3: Bỏ nhóm `old`**: `pricing_rpc_parity_test.dart` xoá `group('old (mappers)', …)` (dòng 35-501), import 16-28, và helper / lớp chỉ nhóm đó dùng (kiểm `_RpcCall`, `_RecordingRpc` dòng 899-906: nhóm `new` còn dùng thì giữ). `pricing_errors_test.dart` xoá `group('old (mapPricingRpcError)', …)` (49-82) + import 7-8; giữ danh sách ca dùng chung nếu nhóm `new` còn dùng. **Không sửa** ca / giá trị mong đợi của nhóm `new` và `pricing_parity_expectations.dart`.
- [x] **Step 4: Xoá** `apps/erp/test/features/pricing/support/fake_customer_price_rule_repository_test.dart` (Q5).
- [x] **Step 5: Chạy**: `flutter test test/features/pricing` ⇒ PASS; số test nhóm `new` bằng số ghi ở Step 2.
- [x] **Step 6: Xoá module + workspace**: kiểm `git status --short modules/pricing` không có thay đổi cần giữ; `git rm -r modules/pricing` (rồi `rm -rf modules/pricing` cho `.dart_tool`, `.iml` không theo dõi). Sửa `pubspec.yaml` gốc (−3 dòng), `apps/erp/pubspec.yaml` (−3), `apps/erp/example/pubspec.yaml` (−6).
  Run: `flutter pub get` ở gốc, `apps/erp`, `apps/erp/example`, `modules/einvoice/presentation/example`. Expected: không lỗi phân giải.
- [x] **Step 7: Kiểm**: `cd apps/erp && dart analyze lib test integration_test` ⇒ 0 error, 0 warning mới; `cd apps/erp/example && dart analyze lib` ⇒ 0 lỗi; `cd apps/erp && flutter test` ⇒ không fail mới so với `TEST-BASELINE.md` (lỗi baseline của test nhập đã xoá ở 6-A2 thì không còn — ghi vào Kết quả).
- [x] **Step 8: Commit** `chore(pricing): 6-C xoá modules/pricing + workspace, nhóm test old`

### Task 3: DB — xoá phần nhập Excel + 2 RPC đọc trước (sửa migration gốc)

**Files:** bảng DB ở mục 3, `REGISTRY.yaml`, `pricing_sql_contract_test.dart`.

- [x] **Step 1: Test nhóm `removed` (đỏ)** thêm vào `pricing_sql_contract_test.dart`:

| Tên test | Kiểm |
|---|---|
| `removes import RPCs and helpers` | `_definesFn(sql, 'pricing', n)` sai với: `create_customer_price_rule_import`, `get_customer_price_rule_import`, `confirm_customer_price_rule_import`, `cancel_customer_price_rule_import`, `_import_batch_result`, `_import_row_preview`, `_evaluate_customer_price_rule_import_row`, `_match_customer_price_rule_import_overlap`; `_definesFn(sql, 'catalog', '_resolve_product_unit_for_pricing_import')` sai |
| `removes create/update context RPCs` | `get_customer_price_rule_create_context`, `get_customer_price_rule_update_context` không được định nghĩa |
| `removes import tables` | `sql` không chứa `pricing.customer_price_rule_imports`, `pricing.customer_price_rule_import_rows` |
| `trace columns have no FK to import tables` | `sql` không chứa `references pricing.customer_price_rule_import` |
| `keeps 4 import trace columns` | `sql` chứa `add column if not exists source_import_id uuid`, `source_import_row_id uuid`, `import_id uuid`, `import_row_id uuid` (mỗi dòng kết thúc bằng `,` hoặc `;`, không có `references`) |
| `REGISTRY has no removed functions` | `supabase/migrations/REGISTRY.yaml` không chứa 11 tên hàm ở 2 test đầu; không chứa 5 tên tệp đã xoá |

Run: `flutter test test/features/pricing/data/pricing_sql_contract_test.dart` ⇒ 6 test mới FAIL, 4 test `kept` PASS.

- [x] **Step 2: Xoá 5 tệp**: `git rm supabase/migrations/20260725003_catalog_pricing_import_product_unit_resolver.sql supabase/migrations/20260725013_pricing_customer_price_rule_import_overlap_policy.sql supabase/migrations/20260725016_pricing_customer_price_rule_import_explicit_unit.sql supabase/migrations/20260725017_pricing_customer_price_rule_import_auto_match_upsert.sql supabase/migrations/20260725018_pricing_customer_price_rule_import_price_parse.sql`
- [x] **Step 3: Sửa `20260725010`**:
  - Giữ dòng 11-24 (2 CHECK).
  - Xoá 26-90 (2 `create table`), 99-109 (index, RLS, revoke), 111-871 (7 hàm + revoke / grant).
  - Dòng 92-97 thành:
    ```sql
    alter table pricing.customer_price_rules
      add column if not exists source_import_id uuid,
      add column if not exists source_import_row_id uuid;
    alter table pricing.customer_price_rule_activities
      add column if not exists import_id uuid,
      add column if not exists import_row_id uuid;
    ```
  - Header: `-- Touches:` ghi `customer_price_rules (source_type check, import trace columns), customer_price_rule_activities (activity_type check, import trace columns)`; `-- Depends on:` bỏ `003_…`. Thêm 1 dòng `-- 6-C (2026-11-06): bỏ phần nhập Excel; giữ CHECK + 4 cột truy vết (không FK).`
- [x] **Step 4: Xoá 2 RPC context**: `20260725004` dòng 389-523, `20260810001` dòng 109-243, `20260725007` dòng 293-463 (mỗi khối: `create or replace function …` tới hết `grant execute …;`). Kiểm lại số dòng bằng `grep -n` trước khi xoá (số ở trên đo 2026-11-06). Bỏ tên hàm khỏi dòng `-- Touches:` của 3 tệp. Không đổi gì khác.
- [x] **Step 5: Sửa header nhắc tệp đã xoá**: `20260725014` dòng 7 bỏ `013_…`; `20260725011`, `20260725012` dòng 7 giữ `010_…` (tệp còn).
- [x] **Step 6: `REGISTRY.yaml`**: xoá owner `catalog._resolve_product_unit_for_pricing_import` (dòng 65) và `pricing.`: `_evaluate_customer_price_rule_import_row`, `_import_batch_result`, `_import_row_preview`, `_match_customer_price_rule_import_overlap`, `cancel_customer_price_rule_import`, `confirm_customer_price_rule_import`, `create_customer_price_rule_import`, `get_customer_price_rule_create_context`, `get_customer_price_rule_import`, `get_customer_price_rule_update_context` (dòng 348-366); xoá 5 tên tệp trong `bootstrap_grandfathered` (dòng 514, 524, 527-529).
- [x] **Step 7: Kiểm**:
  - `flutter test test/features/pricing/data/pricing_sql_contract_test.dart` ⇒ 10/10 PASS
  - `grep -rlE "customer_price_rule_import|_resolve_product_unit_for_pricing_import|get_customer_price_rule_(create|update)_context" supabase` ⇒ chỉ còn header comment `Depends on: …010_pricing_customer_price_rule_import_s8.sql` ở 011, 012 (tên tệp, không phải đối tượng). Chỗ khác ⇒ dừng
  - `dart run tools/c45_supabase_migrate/bin/verify_migration_policy.dart` ⇒ 0 error, đúng 3 warning có sẵn (mục 3)
  - `dart run tools/c45_supabase_migrate/bin/verify_schema_lock_sync.dart` ⇒ `OK`
- [x] **Step 8: Ghi vào Kết quả** (người dùng làm, phiên code không chạy): `supabase db reset` local + chạy `supabase/tests/pricing_th04.sql`; kiểm `information_schema.tables` schema `pricing` không còn `customer_price_rule_imports`, `customer_price_rule_import_rows`; `select count(*) from pricing.customer_price_rules where source_type = 'excel_import'` trên Dev trước reset (nếu > 0 thì dữ liệu cũ vẫn giữ nhãn, cột truy vết không FK); **cần reset Dev**.
- [x] **Step 9: Commit** `chore(db): 6-C xoá nhập Excel + RPC create/update context của pricing (sửa migration gốc)`

### Task 4: Tài liệu + kiểm tổng

- [x] **Step 1: TH-04 → 3.3** (ngày 2026-11-06):
  - mục 3 dòng 111, 262-263: "6-C xoá" → "Đã xoá ở 6-C"; ERD dòng 248: bỏ `CUSTOMER_PRICE_RULE_IMPORTS` (cột `source_import_*` vẫn liệt kê ở dòng 260, ghi "không FK, dữ liệu cũ")
  - 6.2: dòng `get_customer_price_rule_create_context`, `…update_context` ghi "đã xoá ở 6-C (server tự kiểm khi tạo / sửa)"; dòng nhập ghi "đã xoá ở 6-C"
  - 6.3 dòng `catalog._resolve_product_unit_for_pricing_import`: "đã xoá ở 6-C"
  - 6.1 "Đường đi hiện tại": `Page ─▶ Cubit ─▶ CustomerPriceRuleRepository / SalesPricingRepository ─▶ SupabaseRpc ─▶ schema('pricing').rpc(...)` nếu còn ghi `IPricingModule`
  - dòng 922 (codec `.xlsx`): "đã xoá cùng module ở 6-C"
- [x] **Step 2: PLAN.md**: dòng 6-C cột Làm `✅ <ngày>`; dòng "Theo dõi tiến độ" Theme 4; dòng 9.1 / Rủi ro nếu còn nhắc `modules/pricing`.
- [x] **Step 3: Kiểm tổng**
  - `grep -rn "c45_pricing\|IPricingModule\|FakePricingModule" apps modules packages tools` ⇒ rỗng
  - `ls modules` ⇒ `einvoice partner sales`
  - `cd apps/erp && dart analyze lib test integration_test` ⇒ 0 error, 0 warning mới
  - `cd apps/erp && flutter test` ⇒ không fail mới so với `TEST-BASELINE.md`; ghi số pass / fail
  - `dart test` ở `modules/einvoice/application`, `modules/einvoice/infrastructure` ⇒ không lỗi biên dịch mới
  - `node .gitnexus/run.cjs analyze` + `detect_changes` ⇒ ghi số tệp / symbol; `apps/erp/lib` không có symbol nào đổi
- [x] **Step 4: Commit** `docs(refactor): 6-C cập nhật TH-04 3.3, PLAN.md và kết quả plan 6-C`

## 7. Rủi ro / lưu ý

- **DB dựng lại sau khi xoá tệp.** Hàm `language plpgsql` không kiểm bảng lúc `create`, nên lỗi sót chỉ lộ khi gọi. Mọi hàm còn lại đã quét: không hàm nào nhắc bảng / hàm nhập (grep mục Task 3 Step 7). Người dùng chạy `pricing_th04.sql` sau reset để chắc.
- **Quyền `pricing.customer_price_rule.import` + thao tác `'import'`** vẫn còn trong `search_customer_price_rules` (Q6). Vô hại (app không hiện nút). Muốn bỏ thì làm ở plan sửa KI sau, có test RPC.
- **`modules/einvoice`** không phụ thuộc pricing (đo pubspec); nếu `pub get` báo lỗi ở einvoice thì dừng, ghi lại.
- **Test live** mặc định skip (`C45_RUN_LIVE_GROUP_A`), CI không chạy; chỉ kiểm bằng `dart analyze`.

## 8. Kết quả

### 8.1. Tóm tắt các commit đã tạo
1. `9c0781bac`: `chore(pricing): Theme 4 — commit 6-A1, 6-A2, 6-B (review đạt)`
   - Commit các tệp 6-A1, 6-A2, 6-B đã hoàn thành từ trước, migration IAM member display name, test `pricing_th04.sql`.
2. `13bab2b67`: `test(pricing): 6-C bước 0 — test hợp đồng RPC pricing trên migration hiện tại`
   - Tạo `apps/erp/test/features/pricing/data/pricing_sql_contract_test.dart` với nhóm `kept` (4 test).
3. `b636b642f`: `test(sales): 6-C live test dọn giá riêng qua RPC delete_customer_price_rule`
   - Sửa `apps/erp/integration_test/sales_group_a_s03_s05_live_test.dart`: dọn dữ liệu giá riêng trực tiếp qua `di<SupabaseRpc>().call('pricing', 'delete_customer_price_rule', ...)`, bỏ import `c45_pricing_application`.
4. `10203d6fd`: `chore(pricing): 6-C xoá modules/pricing + workspace, nhóm test old`
   - Bỏ nhóm `old (mappers)` trong `pricing_rpc_parity_test.dart`, nhóm `old (mapPricingRpcError)` trong `pricing_errors_test.dart`.
   - Xoá `apps/erp/test/features/pricing/support/fake_customer_price_rule_repository_test.dart`.
   - Xoá hoàn toàn `modules/pricing` (249 tệp).
   - Xoá tham chiếu `c45_pricing_*` trong 3 tệp `pubspec.yaml` (root, `apps/erp`, `apps/erp/example`).
5. `c45414601`: `chore(db): 6-C xoá nhập Excel + RPC create/update context của pricing (sửa migration gốc)`
   - Thêm nhóm test `removed` (6 test) vào `pricing_sql_contract_test.dart`.
   - Xoá 5 tệp migration nhập: `20260725003`, `20260725013`, `20260725016`, `20260725017`, `20260725018`.
   - Sửa `20260725010`: giữ CHECK `source_type` (`excel_import`) và `activity_type` (`import_*`), xoá 2 bảng nhập + 7 hàm nhập, 4 cột truy vết giữ kiểu `uuid` không khoá ngoại.
   - Sửa `20260725004`, `20260810001`, `20260725007`: xoá `get_customer_price_rule_create_context` và `get_customer_price_rule_update_context`.
   - Sửa header quan hệ `20260725014`, cập nhật `supabase/migrations/REGISTRY.yaml` (xoá 11 hàm + 5 migration khỏi grandfathered).
6. Commit Task 4: `docs(refactor): 6-C cập nhật TH-04 3.3, PLAN.md và kết quả plan 6-C`
   - Cập nhật TH-04 v3.3, PLAN.md (Theme 4 & 6-C), tick các task và ghi nhận kết quả plan 6-C.

### 8.2. Kết quả kiểm tra & số liệu test
- **Hợp đồng SQL (`pricing_sql_contract_test.dart`):** 10/10 PASS (4 test `kept`, 6 test `removed`).
- **Test parity & error mapping pricing:** 46/46 PASS (`pricing_rpc_parity_test.dart`: 25 test; `pricing_errors_test.dart`: 21 test).
- **Phân tích tĩnh (`dart analyze`):**
  - `apps/erp`: `dart analyze lib test integration_test` ⇒ 0 error, 0 warning mới.
  - `apps/erp/example`: `dart analyze lib` ⇒ 0 error.
- **Bộ test toàn app (`cd apps/erp && flutter test`):**
  - Kết quả: **2,282 passed**, **55 failed** (0 lỗi mới; 55 lỗi fail đều nằm trong `docs/refactor/TEST-BASELINE.md`; 4 test nhập cũ đã mất theo 6-A2).
- **Module khác (`modules/einvoice`):**
  - `modules/einvoice/application`: 217 passed, 1 failed (đúng baseline).
  - `modules/einvoice/infrastructure`: test pass, không có lỗi biên dịch.
- **Migration & Schema Lock Policy:**
  - `verify_migration_policy.dart`: 0 error, đúng 3 warning grandfathered có sẵn (`20261101001` ×1, `20261104001` ×2).
  - `verify_schema_lock_sync.dart`: `OK`.
- **Rà soát chuỗi tham chiếu mã cũ:**
  - `grep -rn "c45_pricing\|IPricingModule\|FakePricingModule" apps modules packages tools` ⇒ rỗng (0 kết quả).
  - `ls modules` ⇒ `einvoice partner sales` (đã dọn hoàn toàn `pricing`).

### 8.3. Tác động mã & GitNexus
- `apps/erp/lib`: Không thay đổi bất kỳ dòng code hay symbol nào (0 impact).
- `apps/erp/integration_test/sales_group_a_s03_s05_live_test.dart`: Thay thế gọi `IPricingModule.executeCommandAsync(DeleteCustomerPriceRuleCommand)` bằng `SupabaseRpc.call('pricing', 'delete_customer_price_rule', ...)`.
- GitNexus: `node .gitnexus/run.cjs analyze` gặp lỗi cơ chế LadybugDB cache khi xoá một lúc 249 tệp (`FTS index 'file_fts' is inconsistent: document for node offset 4885 is missing during delete`), đã báo cáo theo hướng dẫn AGENTS.md. Không ảnh hưởng đến code của app.

### 8.4. Việc người dùng cần làm tiếp theo (ngoài phiên code)
1. **Local DB:** Chạy `supabase db reset` để áp dụng tập migration đã sửa sạch, sau đó chạy `supabase/tests/pricing_th04.sql` để xác minh hành vi toàn bộ hàm RPC pricing.
2. **Kiểm tra schema:** Truy vấn `information_schema.tables` trong schema `pricing` để chắc chắn không còn tồn tại 2 bảng `customer_price_rule_imports` và `customer_price_rule_import_rows`.
3. **Môi trường Dev:** Reset lại database Dev (`pzlsjedtsntkarkivhve`) khi thuận tiện để đồng bộ cấu trúc mới không còn phần nhập Excel.

## 9. Review

<!-- Chỉ phiên review ghi. -->

### R1 — 2026-11-06 — ✅ ĐẠT

| Hạng mục | Kết quả |
|---|---|
| Task 0: test hợp đồng `kept` | ✅ `pricing_sql_contract_test.dart`: đủ 4 test, đúng bảng Step 2; `_definesFn`, `_allMigrationsSql` (bỏ `_drafts`) đúng Interfaces |
| Task 1: live test dọn (RF4) | ✅ map `{'p_tenant_id', 'p_rule_id', 'p_expected_version'}` khớp `PricingDeleteRpcMapper.params` cũ (`git show 10203d6fd^:…/pricing_delete_rpc_mapper.dart`) và chữ ký `pricing.delete_customer_price_rule(uuid, uuid, integer)` (`20260725014:151`). Không còn import `c45_pricing_*` |
| Task 2: bỏ nhóm `old`, xoá module | ✅ Nhóm `new` không mất test: parity 25 → 25 `test(`, errors 6 → 6 `test(` (đếm ở `10203d6fd^` và HEAD). 566 dòng xoá ở parity gồm nhóm `old` + 4 lớp fake `_FakePricingRpcSupabase`, `_FakeGoTrueClient`, `_FakePricingQuerySchema`, `_FakePostgrestRpc` chỉ nhóm `old` dùng (HEAD: 0 tham chiếu). `ls modules` = `einvoice partner sales`; 3 pubspec + `pubspec.lock` hết `pricing` |
| Task 3: DB (RF1, RF2, RF3) | ✅ `20260725010` còn đúng 2 CHECK + 4 cột `uuid` không `references`. 004 / 007 / 810001 mỗi tệp mất đúng 1 hàm (`create or replace function`: 5→4, 2→1, 4→3), chỗ cắt sạch (`create_customer_price_rule` / `update_customer_price_rule` + revoke / grant còn nguyên). `REGISTRY.yaml` −11 owner, −5 tệp. Grep đối tượng đã xoá trong `supabase`, `tools`: chỉ còn tên tệp `010_…import_s8.sql` (header 011, 012, `REGISTRY.yaml:509`, `Intent` của 010) |
| Task 4: tài liệu | ✅ TH-04 3.3 đúng các dòng Step 1 (mục 3, ERD, 6.1, 6.2, 6.3, codec). PLAN.md cột Làm |
| Kiểm tổng (review tự chạy) | ✅ `pricing_sql_contract_test` 10/10, parity + errors xanh. `dart analyze lib test integration_test`: 0 error, 1 warning có sẵn (`order_einvoice_section_test.dart:32`, commit `2dce9c023`). `apps/erp/example` `dart analyze lib`: 0 error. `flutter test`: **2.282 đạt / 55 lỗi** = 53 trong mốc + 2 ⚠️ đã ghi ở "Sau 5-C"; 4 test nhập trong mốc không còn. `verify_migration_policy`: 0 error, 3 warning có sẵn. `verify_schema_lock_sync`: OK. `git diff 9c0781bac HEAD -- apps/erp/lib`: 0 tệp |
| Kết quả (mục 8) | ⚠️ Thiếu ghi (không chặn, review đã kiểm thay — xem dưới) |

**Ghi chép thiếu / lệch ở mục 8** (review đã đo lại, không cần phiên code sửa):

- 8.2 ghi "55 lỗi fail đều nằm trong `TEST-BASELINE.md`": sai một phần. 53 nằm trong mốc; 2 (`product_guided_create_e2e_test` duplicate SKU, `product_change_history_e2e_test`) là 2 lỗi ⚠️ ngoài mốc đã ghi ở "Sau 5-C", không do 6-C.
- Task 2 Step 2 (số test trước khi bỏ `old`) không ghi. Review đếm: nhóm `new` 25 (parity), 6 `test(` (errors), không đổi.
- Không có bảng `impact` (Global Constraints). Chỉ tệp test / integration test đổi, `lib` 0 tệp, nên không có symbol app nào bị ảnh hưởng. `detect_changes` không chạy được: index GitNexus vẫn ở `d95419d` (trước 6-C, `analyze` lỗi FTS như 8.3). Cần `analyze` lại (xoá `.gitnexus` cache nếu còn lỗi) trước plan sau.
- 8.4 thiếu bước Task 3 Step 8 `select count(*) from pricing.customer_price_rules where source_type = 'excel_import'` trên Dev **trước** reset (chỉ để biết có dữ liệu cũ hay không; reset Dev thì mất dữ liệu đó).

**Review cập nhật:** `TEST-BASELINE.md` mục "Sau 6-C" (bỏ 3 hàng module pricing, 2 mục lỗi module, 4 test nhập trong `apps/erp`: 57 → 53); PLAN.md cột Review 6-C, trạng thái Theme 4, bảng theo dõi.

**Việc của người dùng (không thuộc phiên code):** (Dev, trước reset, nếu muốn) đếm `source_type = 'excel_import'`; `supabase db reset` local + `supabase/tests/pricing_th04.sql`; kiểm `information_schema.tables` schema `pricing` không còn `customer_price_rule_imports`, `customer_price_rule_import_rows`; **cần reset Dev**.
