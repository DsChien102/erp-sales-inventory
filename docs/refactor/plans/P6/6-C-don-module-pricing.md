# 6-C — Dọn sạch module pricing + xoá phần nhập Excel trong DB

> Theme 4 (mã cũ P6) · Bước (dọn) theo "Quy tắc dọn module (chốt 2026-10-11)" của PLAN.md
> Trạng thái: Plan ✅ (viết + người dùng duyệt 2026-11-06) | Làm ⬜ | Review ⬜
> Làm **sau** 6-A1, 6-A2, 6-B (đã review đạt, **chưa commit** — Task 0 Step 1).
> Tài liệu: PLAN.md mục Theme 4 dòng 6-C, "Quy tắc dọn module", "Quy tắc migration", "Plan xoá / tách / thay code cũ"; TH-04 mục 3 (dữ liệu), 6.2, 6.3, 8, BR-19; 6-A1 Q9, 6-A2 Q12; mẫu đã làm: 5-C (`git show d95419d20^:docs/refactor/plans/P5/5-C-don-module-catalog-inventory.md`).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** App hết `vet45_pricing_*` (cả test, integration test, pubspec). Xoá `modules/pricing`. DB schema `pricing` bỏ toàn bộ phần nhập Excel và 2 RPC đọc trước (create / update context) mà app không còn gọi.

**Architecture:** Không đổi code chạy trong `lib/`: 6-A2 đã chuyển hết sang `CustomerPriceRuleRepository` / `SalesPricingRepository`. Việc còn lại là xoá nhóm test `old`, sửa đoạn dọn của live test, xoá module + workspace, và sửa migration gốc. Một test hợp đồng SQL mới ở app chốt danh sách RPC phải còn / phải mất.

**Tech Stack:** Flutter / Dart (`flutter_test`), Supabase Postgres (plpgsql), `tools/vet45_supabase_migrate`.

**Spec:** [TH-04](../../../02-yeu-cau/TH-04-chinh-sach-gia.md) (mục 3, 6.2, 6.3, 8, BR-19).

## Global Constraints

- **Không đổi nghiệp vụ.** `apps/erp/lib` không có dòng nào đổi. RPC app gọi giữ nguyên chữ ký và thân hàm.
- **Giữ trong DB** (TH-04 6.2 "Không dùng … giữ trong DB"): `delete_customer_price_rule`, `save_remembered_price_from_order`, bảng `remembered_price_requests` và các hàm phụ của chúng.
- **Giữ nhãn dữ liệu cũ** (TH-04 mục 3, 6-A2 Q12): `source_type` vẫn nhận `'excel_import'`; `activity_type` vẫn nhận `'import_created'`, `'import_updated'`.
- Migration: **sửa thẳng migration gốc**, không tạo migration mới. Migration chỉ còn phần nhập Excel thì xoá tệp + dòng trong `REGISTRY.yaml`. Phiên code **không** chạy `supabase db reset`, không reset Dev, không chạy SQL. Chỉ ghi "cần reset" vào Kết quả.
- Trước khi sửa mỗi symbol Dart: `node .gitnexus/run.cjs impact <symbol> --direction upstream --repo erp-sales-inventory`, ghi vào Kết quả. Trước mỗi commit: `detect_changes`.
- `flutter analyze` sập vì đường dẫn có dấu: dùng `dart analyze`.
- Tìm kiếm dùng `grep -r`, không dùng `git grep` (4-C sót tệp chưa theo dõi; phần lớn tệp 6-A1 đang untracked).
- **Giữ** `modules/` (còn `einvoice`, `partner/integration_events`, `sales`), `packages/vet45_adapters`, `vet45_annotations`, `vet45_generator`, `vet45_shared*` (7-5, 9-1 lo).

## Review Focus

1. **Xoá nhầm phần còn dùng trong `20260725010`.** Tệp này vừa có phần nhập vừa nới 2 ràng buộc CHECK (`excel_import`, `import_*`) và thêm 4 cột truy vết. Mất CHECK ⇒ dữ liệu cũ / lịch sử ghi lỗi. Test: Task 0 `keeps source_type and activity_type labels for old import data`.
2. **Cột truy vết còn khoá ngoại tới bảng đã xoá** ⇒ `db reset` hỏng ở 010. Test: Task 3 `trace columns have no FK to import tables` + `keeps 4 import trace columns`.
3. **Xoá nhầm RPC app đang gọi / RPC TH-04 giữ.** Test: Task 0 `keeps every RPC the app calls` + `keeps RPCs TH-04 keeps unused`.
4. **Live test dọn sai tham số** ⇒ để lại giá riêng, lần chạy sau vấp `seed must not reuse a private rule`. Test: Task 1, đối chiếu map với `PricingDeleteRpcMapper.params` cũ (trong bảng mục 4) + `dart analyze integration_test`.
5. **Workspace còn trỏ `modules/pricing`** ⇒ `flutter pub get` gốc / `apps/erp/example` lỗi. Test: Task 2 Step 6.

---

## 1. Mục tiêu

- `grep -r "vet45_pricing" apps modules packages tools` rỗng (trừ không còn gì). Không còn `IPricingModule` / `FakePricingModule` trong repo.
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
| `package:vet45_pricing_*` trong `apps/erp/lib` | **không** (6-A2) |
| `apps/erp/test` | `features/pricing/data/pricing_rpc_parity_test.dart:16-28` (nhóm `old (mappers)` dòng 35-501; `new (json)` 502, `new (CustomerPriceRuleRepository)` 582, `new (SalesPricingRepository)` 778); `data/pricing_errors_test.dart:7-8` (nhóm `old (mapPricingRpcError)` dòng 49-82); `support/fake_customer_price_rule_repository_test.dart` (cả tệp, 7 test) |
| `apps/erp/integration_test` | `sales_group_a_s03_s05_live_test.dart:6` (import), `:221-228` (`di<IPricingModule>().executeCommandAsync(DeleteCustomerPriceRuleCommand(…))`). `IExecutionContext` (`vet45_shared_application`) còn dùng ở dòng 40, giữ |
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

- [ ] **Step 1: Commit 6-A1 … 6-B** (đã review đạt, đang nằm trong cây làm việc). `git status --short` ⇒ chỉ còn tệp của 6-A1, 6-A2, 6-B, `supabase/migrations/20261105001_iam_member_display_name.sql`, `supabase/tests/pricing_th04.sql`, PLAN / TH-04 / plan P6. Có tệp lạ ⇒ dừng, hỏi người dùng. Commit `chore(pricing): Theme 4 — commit 6-A1, 6-A2, 6-B (review đạt)`.

- [ ] **Step 2: Viết test nhóm `kept`**

| Tên test | Kiểm |
|---|---|
| `keeps every RPC the app calls` | `_definesFn(sql, 'pricing', n)` đúng với cả 11 tên: `search_customer_price_rules`, `get_customer_price_rule_detail`, `get_customer_price_rule_history`, `create_customer_price_rule`, `update_customer_price_rule`, `disable_customer_price_rule`, `precheck_customer_price_rule_reenable`, `reenable_customer_price_rule`, `resolve_applicable_customer_price_rule`, `preview_sales_working_state_pricing`, `evaluate_sales_manual_price` |
| `keeps RPCs TH-04 keeps unused` | `delete_customer_price_rule`, `save_remembered_price_from_order` được định nghĩa; `sql` chứa `create table if not exists pricing.remembered_price_requests` |
| `app RPC list matches repositories` | Quét `apps/erp/lib/features/pricing/data/*.dart`, lấy mọi chuỗi `'<tên>'` đứng ngay sau `'pricing',` (RegExp `'pricing',\s*'([a-z_]+)'`); tập tên == 11 tên ở trên. Đỏ ⇒ danh sách lệch code, sửa danh sách (không sửa `lib`) |
| `keeps source_type and activity_type labels for old import data` | `sql` chứa `check (source_type in ('manual', 'excel_import', 'sales_order', 'migration'))`; tệp `20260725014_…` chứa `'import_created', 'import_updated'` trong CHECK `activity_type` (định nghĩa cuối) |

- [ ] **Step 3: Chạy trên code cũ**

Run: `cd apps/erp && flutter test test/features/pricing/data/pricing_sql_contract_test.dart`
Expected: PASS 4/4. Đỏ ⇒ dừng, ghi lại (bảng mục 3 sai).

- [ ] **Step 4: Commit** `test(pricing): 6-C bước 0 — test hợp đồng RPC pricing trên migration hiện tại`

### Task 1: Live test dọn giá riêng qua RPC (Q2)

**Files:**
- Modify: `apps/erp/integration_test/sales_group_a_s03_s05_live_test.dart:6, 220-229`

**Interfaces:**
- Consumes: `SupabaseRpc.call(String schema, String fn, {Map<String, dynamic>? params})` (`lib/core/supabase/supabase_rpc.dart:16`), đăng ký trong DI (`injection.dart:60`).

- [ ] **Step 1: Sửa** khối `finally` theo bảng mục 4 dòng 4. Thêm `import 'package:erp/core/supabase/supabase_rpc.dart';`, xoá `import 'package:vet45_pricing_application/application.dart';`. Không đổi gì khác (giữ `IExecutionContext`, `sales.MoneyDto`).
- [ ] **Step 2: Kiểm**: `cd apps/erp && dart analyze integration_test` ⇒ `No issues found!`; `grep -n "IPricingModule\|vet45_pricing" integration_test -r` ⇒ rỗng.
- [ ] **Step 3: Commit** `test(sales): 6-C live test dọn giá riêng qua RPC delete_customer_price_rule`

### Task 2: Bỏ nhóm test `old`, xoá module + workspace

**Files:** theo bảng mục 5 (3 tệp test, 3 pubspec, `modules/pricing`).

- [ ] **Step 1: Kiểm điều kiện**: `grep -rln "vet45_pricing\|IPricingModule\|FakePricingModule" apps/erp/lib apps/erp/test apps/erp/integration_test`. Expected: đúng 3 tệp `pricing_rpc_parity_test.dart`, `pricing_errors_test.dart`, `fake_customer_price_rule_repository_test.dart`. Khác ⇒ dừng, ghi lại.
- [ ] **Step 2: Ghi số test trước**: `flutter test test/features/pricing/data/pricing_rpc_parity_test.dart test/features/pricing/data/pricing_errors_test.dart` ⇒ ghi số pass / nhóm vào Kết quả.
- [ ] **Step 3: Bỏ nhóm `old`**: `pricing_rpc_parity_test.dart` xoá `group('old (mappers)', …)` (dòng 35-501), import 16-28, và helper / lớp chỉ nhóm đó dùng (kiểm `_RpcCall`, `_RecordingRpc` dòng 899-906: nhóm `new` còn dùng thì giữ). `pricing_errors_test.dart` xoá `group('old (mapPricingRpcError)', …)` (49-82) + import 7-8; giữ danh sách ca dùng chung nếu nhóm `new` còn dùng. **Không sửa** ca / giá trị mong đợi của nhóm `new` và `pricing_parity_expectations.dart`.
- [ ] **Step 4: Xoá** `apps/erp/test/features/pricing/support/fake_customer_price_rule_repository_test.dart` (Q5).
- [ ] **Step 5: Chạy**: `flutter test test/features/pricing` ⇒ PASS; số test nhóm `new` bằng số ghi ở Step 2.
- [ ] **Step 6: Xoá module + workspace**: kiểm `git status --short modules/pricing` không có thay đổi cần giữ; `git rm -r modules/pricing` (rồi `rm -rf modules/pricing` cho `.dart_tool`, `.iml` không theo dõi). Sửa `pubspec.yaml` gốc (−3 dòng), `apps/erp/pubspec.yaml` (−3), `apps/erp/example/pubspec.yaml` (−6).
  Run: `flutter pub get` ở gốc, `apps/erp`, `apps/erp/example`, `modules/einvoice/presentation/example`. Expected: không lỗi phân giải.
- [ ] **Step 7: Kiểm**: `cd apps/erp && dart analyze lib test integration_test` ⇒ 0 error, 0 warning mới; `cd apps/erp/example && dart analyze lib` ⇒ 0 lỗi; `cd apps/erp && flutter test` ⇒ không fail mới so với `TEST-BASELINE.md` (lỗi baseline của test nhập đã xoá ở 6-A2 thì không còn — ghi vào Kết quả).
- [ ] **Step 8: Commit** `chore(pricing): 6-C xoá modules/pricing + workspace, nhóm test old`

### Task 3: DB — xoá phần nhập Excel + 2 RPC đọc trước (sửa migration gốc)

**Files:** bảng DB ở mục 3, `REGISTRY.yaml`, `pricing_sql_contract_test.dart`.

- [ ] **Step 1: Test nhóm `removed` (đỏ)** thêm vào `pricing_sql_contract_test.dart`:

| Tên test | Kiểm |
|---|---|
| `removes import RPCs and helpers` | `_definesFn(sql, 'pricing', n)` sai với: `create_customer_price_rule_import`, `get_customer_price_rule_import`, `confirm_customer_price_rule_import`, `cancel_customer_price_rule_import`, `_import_batch_result`, `_import_row_preview`, `_evaluate_customer_price_rule_import_row`, `_match_customer_price_rule_import_overlap`; `_definesFn(sql, 'catalog', '_resolve_product_unit_for_pricing_import')` sai |
| `removes create/update context RPCs` | `get_customer_price_rule_create_context`, `get_customer_price_rule_update_context` không được định nghĩa |
| `removes import tables` | `sql` không chứa `pricing.customer_price_rule_imports`, `pricing.customer_price_rule_import_rows` |
| `trace columns have no FK to import tables` | `sql` không chứa `references pricing.customer_price_rule_import` |
| `keeps 4 import trace columns` | `sql` chứa `add column if not exists source_import_id uuid`, `source_import_row_id uuid`, `import_id uuid`, `import_row_id uuid` (mỗi dòng kết thúc bằng `,` hoặc `;`, không có `references`) |
| `REGISTRY has no removed functions` | `supabase/migrations/REGISTRY.yaml` không chứa 11 tên hàm ở 2 test đầu; không chứa 5 tên tệp đã xoá |

Run: `flutter test test/features/pricing/data/pricing_sql_contract_test.dart` ⇒ 6 test mới FAIL, 4 test `kept` PASS.

- [ ] **Step 2: Xoá 5 tệp**: `git rm supabase/migrations/20260725003_catalog_pricing_import_product_unit_resolver.sql supabase/migrations/20260725013_pricing_customer_price_rule_import_overlap_policy.sql supabase/migrations/20260725016_pricing_customer_price_rule_import_explicit_unit.sql supabase/migrations/20260725017_pricing_customer_price_rule_import_auto_match_upsert.sql supabase/migrations/20260725018_pricing_customer_price_rule_import_price_parse.sql`
- [ ] **Step 3: Sửa `20260725010`**:
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
- [ ] **Step 4: Xoá 2 RPC context**: `20260725004` dòng 389-523, `20260810001` dòng 109-243, `20260725007` dòng 293-463 (mỗi khối: `create or replace function …` tới hết `grant execute …;`). Kiểm lại số dòng bằng `grep -n` trước khi xoá (số ở trên đo 2026-11-06). Bỏ tên hàm khỏi dòng `-- Touches:` của 3 tệp. Không đổi gì khác.
- [ ] **Step 5: Sửa header nhắc tệp đã xoá**: `20260725014` dòng 7 bỏ `013_…`; `20260725011`, `20260725012` dòng 7 giữ `010_…` (tệp còn).
- [ ] **Step 6: `REGISTRY.yaml`**: xoá owner `catalog._resolve_product_unit_for_pricing_import` (dòng 65) và `pricing.`: `_evaluate_customer_price_rule_import_row`, `_import_batch_result`, `_import_row_preview`, `_match_customer_price_rule_import_overlap`, `cancel_customer_price_rule_import`, `confirm_customer_price_rule_import`, `create_customer_price_rule_import`, `get_customer_price_rule_create_context`, `get_customer_price_rule_import`, `get_customer_price_rule_update_context` (dòng 348-366); xoá 5 tên tệp trong `bootstrap_grandfathered` (dòng 514, 524, 527-529).
- [ ] **Step 7: Kiểm**:
  - `flutter test test/features/pricing/data/pricing_sql_contract_test.dart` ⇒ 10/10 PASS
  - `grep -rlE "customer_price_rule_import|_resolve_product_unit_for_pricing_import|get_customer_price_rule_(create|update)_context" supabase` ⇒ chỉ còn header comment `Depends on: …010_pricing_customer_price_rule_import_s8.sql` ở 011, 012 (tên tệp, không phải đối tượng). Chỗ khác ⇒ dừng
  - `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart` ⇒ 0 error, đúng 3 warning có sẵn (mục 3)
  - `dart run tools/vet45_supabase_migrate/bin/verify_schema_lock_sync.dart` ⇒ `OK`
- [ ] **Step 8: Ghi vào Kết quả** (người dùng làm, phiên code không chạy): `supabase db reset` local + chạy `supabase/tests/pricing_th04.sql`; kiểm `information_schema.tables` schema `pricing` không còn `customer_price_rule_imports`, `customer_price_rule_import_rows`; `select count(*) from pricing.customer_price_rules where source_type = 'excel_import'` trên Dev trước reset (nếu > 0 thì dữ liệu cũ vẫn giữ nhãn, cột truy vết không FK); **cần reset Dev**.
- [ ] **Step 9: Commit** `chore(db): 6-C xoá nhập Excel + RPC create/update context của pricing (sửa migration gốc)`

### Task 4: Tài liệu + kiểm tổng

- [ ] **Step 1: TH-04 → 3.3** (ngày 2026-11-06):
  - mục 3 dòng 111, 262-263: "6-C xoá" → "Đã xoá ở 6-C"; ERD dòng 248: bỏ `CUSTOMER_PRICE_RULE_IMPORTS` (cột `source_import_*` vẫn liệt kê ở dòng 260, ghi "không FK, dữ liệu cũ")
  - 6.2: dòng `get_customer_price_rule_create_context`, `…update_context` ghi "đã xoá ở 6-C (server tự kiểm khi tạo / sửa)"; dòng nhập ghi "đã xoá ở 6-C"
  - 6.3 dòng `catalog._resolve_product_unit_for_pricing_import`: "đã xoá ở 6-C"
  - 6.1 "Đường đi hiện tại": `Page ─▶ Cubit ─▶ CustomerPriceRuleRepository / SalesPricingRepository ─▶ SupabaseRpc ─▶ schema('pricing').rpc(...)` nếu còn ghi `IPricingModule`
  - dòng 922 (codec `.xlsx`): "đã xoá cùng module ở 6-C"
- [ ] **Step 2: PLAN.md**: dòng 6-C cột Làm `✅ <ngày>`; dòng "Theo dõi tiến độ" Theme 4; dòng 9.1 / Rủi ro nếu còn nhắc `modules/pricing`.
- [ ] **Step 3: Kiểm tổng**
  - `grep -rn "vet45_pricing\|IPricingModule\|FakePricingModule" apps modules packages tools` ⇒ rỗng
  - `ls modules` ⇒ `einvoice partner sales`
  - `cd apps/erp && dart analyze lib test integration_test` ⇒ 0 error, 0 warning mới
  - `cd apps/erp && flutter test` ⇒ không fail mới so với `TEST-BASELINE.md`; ghi số pass / fail
  - `dart test` ở `modules/einvoice/application`, `modules/einvoice/infrastructure` ⇒ không lỗi biên dịch mới
  - `node .gitnexus/run.cjs analyze` + `detect_changes` ⇒ ghi số tệp / symbol; `apps/erp/lib` không có symbol nào đổi
- [ ] **Step 4: Commit** `docs(refactor): 6-C cập nhật TH-04 3.3, PLAN.md và kết quả plan 6-C`

## 7. Rủi ro / lưu ý

- **DB dựng lại sau khi xoá tệp.** Hàm `language plpgsql` không kiểm bảng lúc `create`, nên lỗi sót chỉ lộ khi gọi. Mọi hàm còn lại đã quét: không hàm nào nhắc bảng / hàm nhập (grep mục Task 3 Step 7). Người dùng chạy `pricing_th04.sql` sau reset để chắc.
- **Quyền `pricing.customer_price_rule.import` + thao tác `'import'`** vẫn còn trong `search_customer_price_rules` (Q6). Vô hại (app không hiện nút). Muốn bỏ thì làm ở plan sửa KI sau, có test RPC.
- **`modules/einvoice`** không phụ thuộc pricing (đo pubspec); nếu `pub get` báo lỗi ở einvoice thì dừng, ghi lại.
- **Test live** mặc định skip (`VET45_RUN_LIVE_GROUP_A`), CI không chạy; chỉ kiểm bằng `dart analyze`.

## 8. Kết quả

<!-- Phiên code ghi ngay sau mỗi task: tệp:dòng, lệch plan, lệnh test + số pass/fail, impact (symbol, số caller, mức rủi ro). Không tự chấm ĐẠT. -->

## 9. Review

<!-- Chỉ phiên review ghi. -->
