# T7-G5-2a — CAP-01 Chính sách tồn & cận hạn

> Theme 7 · plan **G5-2a** của [PLAN.md](../../PLAN.md) mục "Theme 7" (bảng Plan)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-10) | Làm ✅ (2026-11-10) | Review ✅ R3 đạt (2026-11-10; R1, R2 ❌) — còn nợ chạy `supabase/tests/inventory_stock_policy.sql`
> Thiết kế: duyệt trong chat 2026-11-10 (mục 1). Màn: SCR-062, SCR-063 (FROZEN v5.27.0) — bản rút gọn ở mục 1. Làm **trước** G5-2 (BJ-01 đọc chính sách + luật chỉ báo của plan này).

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Chủ cửa hàng đặt ngưỡng cảnh báo + mức tồn mục tiêu theo sản phẩm và số ngày cận hạn (mặc định + riêng theo sản phẩm); nhân viên xem; dữ liệu ghi qua RPC thật; luật chỉ báo tồn (Hết hàng / Có lô hết hạn / Tồn thấp / Có lô cận hạn / Chưa có ngưỡng) dùng chung cho G5-2 và Hub.

**Architecture:** Một migration `20261111001_inventory_stock_policy.sql`: 2 bảng chính sách, helper tính tồn + cờ hết hạn / cận hạn theo sản phẩm (`_product_stock_rows`, dùng lại ở G5-2 và Hub), 3 RPC (đọc, lưu ngưỡng, lưu cận hạn — ghi theo mẫu RPC ghi: `_assert_actor` owner → idempotency → kiểm `revision` → ghi). Flutter `features/inventory/{data,logic,presentation}/stock_policy/` + luật chỉ báo thuần `logic/stock/stock_indicator_rules.dart`; một Cubit giữ nháp cả hai tab.

**Tech Stack:** PostgreSQL / Supabase (plpgsql), Flutter, `flutter_bloc`, `go_router`, `get_it`, `c45_design_system`.

**Spec:** mục 1 của plan này + `specs/themes/theme-07/03.design/screens/SCR-062.md`, `SCR-063.md` + prototype `03.design/prototype/html/app/cap01.js` (mở bằng `?scope=full`) + PLAN.md Theme 7 → "Quy ước chung cho mọi plan G5".

## Global Constraints

- Quy ước chung: PLAN.md Theme 7 → "Quy ước chung cho mọi plan G5" (cấu trúc code, điều hướng, thứ tự task, UI Flutter chép code prototype, đối chiếu ảnh).
- **Không** chạy bước DB nào (reset, push, `psql`). `supabase/tests/inventory_stock_policy.sql` chỉ **viết**, người dùng chạy.
- Header migration theo khuôn `20261110001_inventory_core.sql` (`-- Title / Kind / Intent / Context / Touches / Safety / Depends on`), Kind `schema`; thêm hàm / bảng vào `supabase/migrations/REGISTRY.yaml`.
- Bảng: RLS bật + `revoke all … from public, anon, authenticated`. Helper `_…`: `revoke all on function … from public, anon, authenticated`. RPC: `security definer`, `set search_path = inventory, iam, catalog, pg_temp`, `grant execute … to authenticated`.
- Lỗi chỉ qua `inventory._raise`; **không thêm mã lỗi mới** — dùng `PERMISSION_DENIED`, `CONTEXT_INVALID`, `VERSION_CONFLICT`, `IDEMPOTENCY_CONFLICT`, `COMMAND_IN_PROGRESS` (đã có ở `inventory_error_codes.dart`).
- "Hôm nay" của server = `inventory._today()` = `(now() at time zone 'Asia/Ho_Chi_Minh')::date`.
- Chữ trên màn chép **nguyên văn** SCR-062 / SCR-063 mục 8, trừ chỗ mục 1 ghi "bỏ" hoặc "đề xuất".
- Số lượng ngưỡng / mục tiêu là **số nguyên ≥ 0** theo ĐVT tồn (`catalog._product_base_unit_name`), như `k7EditCell` (`step="1"`).
- `dart analyze` (không `flutter analyze`). Test: `flutter test --no-pub -r compact`.
- Trước khi sửa symbol đã có (`WarehouseArea`, `warehouseAreaEntries`, `WarehouseHubPage`, `appRouter` / `app_router.dart`, `configureDependencies`): chạy `impact` (GitNexus), ghi blast radius vào Kết quả; HIGH / CRITICAL → dừng, báo người dùng. Cuối plan (Task kiểm cuối): `detect_changes()`.
- `AGENTS.md`, `CLAUDE.md`: không `git add`. Ghi mục 5 Kết quả sau mỗi task; không ghi mục Review.

## Review Focus

1. **Hai người cùng sửa chính sách** (máy A mở màn, máy B lưu, máy A lưu) ⇒ A thấy "Chính sách vừa được cập nhật" + "Tải lại", **không** ghi đè B. Test: Task 1 ca SQL `stale_revision_conflict`; Task 3 `save_version_conflict_enters_conflict`.
2. **Mất mạng sau khi bấm "Lưu chính sách" rồi bấm "Thử lại"** ⇒ không tăng "Lần N" hai lần, không báo xung đột. Test: Task 1 ca SQL `replay_same_key_returns_same_revision`; Task 3 `retry_reuses_idempotency_key`.
3. **Xoá trắng ô của sản phẩm đã có ngưỡng / gõ mục tiêu < ngưỡng / gõ số âm, số lẻ** ⇒ lỗi dưới ô, "Lưu" tắt; server cũng chặn nếu bị vượt qua. Test: Task 2 `row_error_cases`; Task 1 ca SQL `invalid_threshold_rejected`.
4. **Nhân viên mở màn** (kể cả gõ thẳng URL một sản phẩm) ⇒ chỉ xem, không có nút lưu; gọi RPC lưu bị `PERMISSION_DENIED`. Test: Task 1 ca SQL `staff_cannot_save`; Task 4 `staff_read_only_390`, Task 5 `single_staff_read_only`.
5. **Rời màn khi còn nháp** (nút quay lại, đổi tab trong app) ⇒ hỏi bỏ thay đổi; đổi tab Ngưỡng tồn ↔ Cận hạn **giữ** nháp. Test: Task 4 `leave_with_draft_asks_confirm`, `switch_tab_keeps_draft`.
6. **Sản phẩm không theo lô trong chính sách cận hạn riêng** (gọi RPC thẳng) ⇒ `CONTEXT_INVALID`. Test: Task 1 ca SQL `override_requires_lot_product`.

---

## 1. Quyết định (người dùng, 2026-11-10)

| Q | Nội dung |
|---|---|
| Q-2a1 | **Lấy lại CAP-01** (bảng "Rút gọn 2026-11-09" từng bỏ). Ngưỡng cảnh báo + mức tồn mục tiêu sống ở bảng chính sách của Kho; **bỏ** cột `min_stock` ở Theme 2 (không sửa RPC Catalog). AI-3 đọc ngưỡng từ đây |
| Q-2a2 | **Cận hạn chỉ "Cảnh báo"**: bỏ "Hành động" (Cảnh báo / Chặn bán) ở mặc định và ở dòng riêng; bỏ `dsChoiceRow`, `cap-select`. Lô cận hạn **vẫn tính vào khả dụng** |
| Q-2a3 | **Không có số ngày cận hạn mặc định**: tenant chưa lưu thì `near_expiry_days = null` ⇒ không lô nào "cận hạn". Ô mặc định được để trống (= chưa đặt); có chữ thì phải > 0 |
| Q-2a4 | **Bỏ `LOCKED` và SCR-065** (K3 / duyệt đã bỏ). Lưu lỗi ⇒ banner lỗi + "Thử lại" (cùng khoá idempotency). Giữ `CONFLICT` bằng `revision` ("Lần N") |
| Q-2a5 | **Tách khỏi G5-2**, làm trước: luật chỉ báo + helper tồn theo sản phẩm thuộc plan này |

**Chữ đề xuất (không có trong Screen Contract — người dùng duyệt khi duyệt plan):**

| Chỗ | Chữ |
|---|---|
| Hộp thoại rời màn khi còn nháp | "Bỏ thay đổi chưa lưu?" · "Các giá trị vừa sửa sẽ không được lưu." · "Ở lại" · "Bỏ thay đổi" |
| Lưu lỗi (banner `error` trên thân màn / trong sheet) | "Chưa lưu được chính sách" · `inventoryErrorMessage(code)` · nút "Thử lại" |
| Ô mặc định trống (chú thích dưới ô, thay câu gợi ý khi trống) | "Chưa đặt: không đánh dấu lô cận hạn." |

## 2. Thiết kế

### 2.1 Dữ liệu (`supabase/migrations/20261111001_inventory_stock_policy.sql`)

| Bảng | Cột | Ràng buộc |
|---|---|---|
| `inventory.stock_policy_settings` | `tenant_id uuid` PK → `iam.tenants`; `near_expiry_days int null`; `revision int not null default 0`; `updated_at timestamptz not null default now()`; `updated_by uuid not null` | `near_expiry_days is null or near_expiry_days > 0` |
| `inventory.product_stock_policies` | PK `(tenant_id, product_id)`; `product_id` → `catalog.products` (cascade); `reorder_threshold numeric null`; `target_level numeric null`; `near_expiry_days int null`; `updated_at`, `updated_by` | `(reorder_threshold is null) = (target_level is null)`; `reorder_threshold is null or (reorder_threshold >= 0 and target_level >= reorder_threshold and reorder_threshold = trunc(reorder_threshold) and target_level = trunc(target_level))`; `near_expiry_days is null or near_expiry_days > 0` |

`revision` là một bộ đếm chung cho cả hai tab (toast "Lần {N}" = `revision` sau khi lưu).

### 2.2 Helper (nội bộ)

| Hàm | Làm gì |
|---|---|
| `inventory._today() returns date` | `(now() at time zone 'Asia/Ho_Chi_Minh')::date` |
| `inventory._lot_expiry_end(p_expiry date, p_precision text) returns date` | `DAY` → chính ngày; `MONTH` → ngày cuối tháng; `YEAR` → 31/12; `p_expiry null` → `null` (cùng luật `bj01ExpirySortKey`) |
| `inventory._near_expiry_days(p_tenant_id uuid, p_product_id uuid) returns int` | `product_stock_policies.near_expiry_days` → nếu null thì `stock_policy_settings.near_expiry_days` → nếu null thì `null` |
| `inventory._product_stock_rows(p_tenant_id uuid) returns table (product_id uuid, physical numeric, available numeric, has_expired boolean, has_near_expiry boolean, nearest_expiry date)` | Mọi `catalog.products` của tenant `deleted_at is null and business_status = 'active'` (kể cả chưa có tồn ⇒ 0). Gộp `stock_balances` theo `(product_id, lot_key)` nối `lots`. Lô **hết hạn** = `physical > 0` và `_lot_expiry_end(...) < _today()`. Lô **cận hạn** = `physical > 0`, chưa hết hạn, `_near_expiry_days` không null và `_lot_expiry_end(...) - _today() <= _near_expiry_days`. `available = physical − Σ physical lô hết hạn`. `nearest_expiry` = `_lot_expiry_end` nhỏ nhất của lô còn tồn (G5-2 dùng) |

### 2.3 RPC

| RPC | Quyền | Trả về / làm gì |
|---|---|---|
| `inventory.get_stock_policy(p_tenant_id uuid) returns jsonb` | `_assert_actor(p_tenant_id, 'inventory.read')` | `{revision, is_owner, near_expiry_days, products: [{product_id, name, code, base_uom, is_lot_tracked, available, has_expired, has_near_expiry, reorder_threshold, target_level, near_expiry_days}]}` — `code` = `coalesce(sku, '')`, `is_lot_tracked` = `tracking_mode = 'lot'`, `near_expiry_days` của dòng = giá trị **riêng** (null nếu dùng mặc định); `revision` = 0 khi chưa có dòng settings; sắp theo `name` |
| `inventory.save_stock_thresholds(p_tenant_id uuid, p_idempotency_key text, p_expected_revision int, p_lines jsonb) returns jsonb` | `_assert_actor(…, 'inventory.stock_policy.manage', true)` | Mẫu RPC ghi (scope `stock_policy.thresholds`, hash = `md5(p_expected_revision::text || p_lines::text)`). Khoá dòng settings `for update` (chưa có → `insert … revision 0`). `revision <> p_expected_revision` → `VERSION_CONFLICT`. Mỗi dòng `{product_id, reorder_threshold, target_level}`: sản phẩm không thuộc tenant / thiếu số / vi phạm ràng buộc 2.1 → `CONTEXT_INVALID`. Upsert, `revision += 1`. Trả `{revision}` |
| `inventory.save_near_expiry_policy(p_tenant_id uuid, p_idempotency_key text, p_expected_revision int, p_default_days int, p_overrides jsonb) returns jsonb` | như trên | Scope `stock_policy.near_expiry`. Kiểm `revision` như trên. `p_default_days` null hoặc > 0. `p_overrides` = **toàn bộ** danh sách riêng `[{product_id, days}]`: sản phẩm không `tracking_mode = 'lot'` hoặc `days <= 0` → `CONTEXT_INVALID`. Ghi `settings.near_expiry_days = p_default_days`; `near_expiry_days = null` cho mọi sản phẩm không có trong danh sách; upsert sản phẩm trong danh sách (giữ ngưỡng đang có). `revision += 1`. Trả `{revision}` |

### 2.4 Flutter

| Tệp | Nội dung |
|---|---|
| `lib/features/inventory/logic/stock/stock_indicator_rules.dart` | `enum StockIndicator { out, expired, low, nearExpiry, notConfigured }` + `label` ("Hết hàng", "Có lô hết hạn", "Tồn thấp", "Có lô cận hạn", "Chưa có ngưỡng tồn"); `stockIndicators(...)`, `primaryIndicator(...)` (Task 2) |
| `lib/features/inventory/data/stock_policy/stock_policy_models.dart` | `StockPolicySnapshot`, `StockPolicyProduct`, `ThresholdChange`, `NearExpiryOverride` |
| `lib/features/inventory/data/stock_policy/stock_policy_repository.dart` | 3 phương thức, mỗi cái một RPC |
| `lib/features/inventory/logic/stock_policy/stock_policy_rules.dart` | Kiểm tra nháp (chép luật `capRowError`, `capSingleBlocked`) |
| `lib/features/inventory/logic/stock_policy/stock_policy_cubit.dart` + `_state.dart` | Một Cubit cho cả 2 tab + chế độ một sản phẩm |
| `lib/features/inventory/presentation/patterns/k7_edit_cell.dart` | `K7EditCell` (ô số sửa tại dòng) — dời từ G5-5 về đây |
| `lib/features/inventory/presentation/stock_policy/` | `stock_policy_page.dart` (khung + thanh chọn), `stock_threshold_tab.dart`, `near_expiry_tab.dart`, `stock_threshold_single_page.dart`, `threshold_impact_sheet.dart`, `threshold_edit_sheet.dart`, `near_expiry_add_sheet.dart`, `stock_policy_routes.dart` |

### 2.5 Ngoài phạm vi

Danh sách / chi tiết tồn (G5-2), "Cần chú ý" Hub (G5-2), chặn bán lô cận hạn (Q-2a2), lô hết hạn trong FEFO (G5-4 — dùng `_product_stock_rows` / `_lot_expiry_end`), nhập tệp chính sách.

## 3. Tệp

| Tệp | Tạo / sửa | Task |
|---|---|---|
| `supabase/migrations/20261111001_inventory_stock_policy.sql` | tạo | 1 |
| `supabase/migrations/REGISTRY.yaml` | sửa | 1 |
| `supabase/tests/inventory_stock_policy.sql` | tạo | 1 |
| `apps/erp/test/features/inventory/data/stock_policy_sql_contract_test.dart` | tạo | 1 |
| `apps/erp/lib/features/inventory/logic/stock/stock_indicator_rules.dart` + test | tạo | 2 |
| `apps/erp/lib/features/inventory/data/stock_policy/*` + test | tạo | 2 |
| `apps/erp/lib/features/inventory/logic/stock_policy/stock_policy_rules.dart` + test | tạo | 2 |
| `apps/erp/lib/features/inventory/logic/stock_policy/stock_policy_cubit.dart`, `_state.dart` + test | tạo | 3 |
| `apps/erp/lib/features/inventory/presentation/patterns/k7_edit_cell.dart` + test | tạo | 4 |
| `apps/erp/lib/features/inventory/presentation/stock_policy/*` + test | tạo | 4, 5, 6 |
| `apps/erp/lib/core/router/app_router.dart`, `lib/core/di/injection.dart` | sửa | 6 |
| `apps/erp/lib/features/inventory/presentation/hub/warehouse_entries.dart`, `warehouse_area_page.dart` / `warehouse_hub_page.dart` | sửa | 6 |
| `docs/refactor/plans/T7/img/G5-2a/` | ảnh prototype (đã chép) + ảnh Flutter | 7 |

## 4. Task

### Task 1: SQL — bảng, helper, 3 RPC

**Files:**
- Create: `supabase/migrations/20261111001_inventory_stock_policy.sql`, `supabase/tests/inventory_stock_policy.sql`, `apps/erp/test/features/inventory/data/stock_policy_sql_contract_test.dart`
- Modify: `supabase/migrations/REGISTRY.yaml`

**Interfaces:**
- Consumes: `inventory._assert_actor`, `_begin_idempotency`, `_complete_idempotency`, `_raise` (G5-0b); `catalog._product_base_unit_name(tenant, product)` (`20260709006_catalog_basic_stock.sql` — G5-5 bỏ tồn cơ bản **phải giữ hàm này**, ghi vào Kết quả).
- Produces: bảng + hàm mục 2.1–2.3. G5-2 gọi `inventory._product_stock_rows`, `_lot_expiry_end`, `_near_expiry_days`, `_today`.

- [ ] **Step 1: Viết test hợp đồng (đỏ)** — cùng kiểu `inventory_core_sql_contract_test.dart` (đọc tệp migration thành chuỗi):

```dart
test('stock_policy_tables_have_rls_and_revoke', () {
  for (final t in ['stock_policy_settings', 'product_stock_policies']) {
    expect(sql, contains('alter table inventory.$t enable row level security'));
    expect(sql, contains('revoke all on inventory.$t from public, anon, authenticated'));
  }
});
test('helpers_are_revoked', () {
  for (final f in ['_today()', '_lot_expiry_end(date, text)', '_near_expiry_days(uuid, uuid)', '_product_stock_rows(uuid)']) {
    expect(sql, contains('revoke all on function inventory.$f from public, anon, authenticated'));
  }
});
test('rpcs_security_definer_and_granted', () {
  for (final f in ['get_stock_policy(uuid)', 'save_stock_thresholds(uuid, text, int, jsonb)', 'save_near_expiry_policy(uuid, text, int, int, jsonb)']) {
    expect(sql, contains('grant execute on function inventory.$f to authenticated'));
  }
  expect(RegExp('security definer').allMatches(sql).length, greaterThanOrEqualTo(7));
});
test('save_rpcs_require_owner_and_check_revision', () {
  expect(RegExp(r"_assert_actor\(p_tenant_id, 'inventory\.stock_policy\.manage', true\)").allMatches(sql).length, 2);
  expect(RegExp(r"_raise\('VERSION_CONFLICT'").allMatches(sql).length, 2);
  expect(sql, contains("'stock_policy.thresholds'"));
  expect(sql, contains("'stock_policy.near_expiry'"));
});
test('no_new_error_codes', () {
  final codes = RegExp(r"_raise\('([A-Z_]+)'").allMatches(sql).map((m) => m[1]).toSet();
  expect(codes.difference({'PERMISSION_DENIED','CONTEXT_INVALID','VERSION_CONFLICT','IDEMPOTENCY_CONFLICT','COMMAND_IN_PROGRESS'}), isEmpty);
});
```

- [x] **Step 2: Chạy, thấy đỏ** — `cd apps/erp && flutter test --no-pub -r compact test/features/inventory/data/stock_policy_sql_contract_test.dart` → FAIL (không có tệp).
- [x] **Step 3: Viết migration** theo mục 2.1–2.3. `in_progress` của idempotency → `_raise('COMMAND_IN_PROGRESS', …)`; `replay` → trả `result_snapshot`.
- [x] **Step 4: Viết `supabase/tests/inventory_stock_policy.sql`** (khuôn `supabase/tests/inventory_core.sql`; `begin … rollback`; mỗi ca một khối `do $$ … $$` có `raise exception` khi sai): `expired_lot_excluded_from_available` (lô HSD hôm qua 11 + lô còn hạn 3 ⇒ `available = 3`, `has_expired`), `month_precision_expires_end_of_month` (HSD `MONTH` tháng này ⇒ chưa hết hạn), `near_expiry_null_when_unset` (chưa có settings ⇒ `has_near_expiry = false`), `override_beats_default` (mặc định 30, riêng 90, lô còn 60 ngày ⇒ cận hạn), `stale_revision_conflict`, `replay_same_key_returns_same_revision`, `invalid_threshold_rejected` (mục tiêu < ngưỡng; số lẻ 1.5), `staff_cannot_save`, `override_requires_lot_product`, `overrides_replace_whole_list` (lưu lần 2 bỏ sản phẩm A ⇒ A về `null`, ngưỡng của A giữ nguyên).
- [x] **Step 5: Chạy test hợp đồng, thấy xanh** — lệnh Step 2 → PASS.

### Task 2: Luật chỉ báo, model, repository, luật nháp

**Files:**
- Create: `lib/features/inventory/logic/stock/stock_indicator_rules.dart`, `lib/features/inventory/data/stock_policy/{stock_policy_models,stock_policy_repository}.dart`, `lib/features/inventory/logic/stock_policy/stock_policy_rules.dart`
- Test: `test/features/inventory/logic/stock/stock_indicator_rules_test.dart`, `test/features/inventory/data/stock_policy/stock_policy_repository_test.dart`, `test/features/inventory/logic/stock_policy/stock_policy_rules_test.dart`

**Interfaces:**
- Produces (G5-2 dùng lại `stock_indicator_rules.dart`):
  - `List<StockIndicator> stockIndicators({required num available, required num? threshold, required bool hasExpired, required bool hasNearExpiry})` — thứ tự đúng `bj01Indicators` (`bj01.js:48-57`): `out` khi `available == 0`; `expired`; `low` khi `threshold != null && available > 0 && available <= threshold`; `nearExpiry`; `notConfigured` khi `threshold == null`.
  - `StockIndicator? primaryIndicator(List<StockIndicator> all, {StockIndicator? filter})` — `bj01PrimaryAttention` (`bj01.js:62-67`): có `filter` thì trả `filter` nếu có trong `all`, không thì `notConfigured` nếu có; không `filter` thì theo thứ tự `out, expired, low, nearExpiry, notConfigured`.
  - `int urgencyRank(List<StockIndicator> all)` — `bj01UrgencyRank` (`bj01.js:95-101`): `out`=0, `expired`=1, `low`=2, `nearExpiry`=3, bình thường=4, `notConfigured`=5.
  - `extension StockIndicatorX on StockIndicator { String get label; VComponentTone? get tone; }` — tone: `out`, `expired` → `danger`; `low`, `nearExpiry` → `warning`; `notConfigured` → `null` (badge trung tính).
  - `class StockPolicyProduct { String productId, name, code, uom; bool isLotTracked; num available; bool hasExpired, hasNearExpiry; num? threshold, target; int? nearExpiryDaysOverride; bool get configured => threshold != null; }`
  - `class StockPolicySnapshot { int revision; bool isOwner; int? nearExpiryDays; List<StockPolicyProduct> products; }`
  - `class ThresholdChange { String productId; int threshold, target; }`, `class NearExpiryOverride { String productId; int days; }`
  - `StockPolicyRepository({required InventoryRpc rpc})`: `Future<StockPolicySnapshot> load()` → `rpc.query('get_stock_policy')`; `Future<int> saveThresholds({required String idempotencyKey, required int expectedRevision, required List<ThresholdChange> changes})` → `rpc.mutate(scope: 'stock_policy.thresholds', fn: 'save_stock_thresholds', params: {'p_expected_revision', 'p_lines': [{product_id, reorder_threshold, target_level}]})` trả `revision`; `Future<int> saveNearExpiry({required String idempotencyKey, required int expectedRevision, required int? defaultDays, required List<NearExpiryOverride> overrides})` → `save_near_expiry_policy` (`p_default_days`, `p_overrides: [{product_id, days}]`).
  - `stock_policy_rules.dart`: `const capRowError = 'Mục tiêu phải lớn hơn hoặc bằng ngưỡng.'`, `const capDaysError = 'Số ngày cận hạn phải lớn hơn 0.'`; `String? thresholdRowError(String threshold, String target, {required bool configured})` (luật `capRowError`, `cap01.js:44-48`; thêm: số không nguyên hoặc âm ⇒ lỗi); `bool singleBlocked(String threshold, String target, {required bool configured})` (`cap01.js:50-51`); `String? defaultDaysError(String text)` (trống ⇒ `null`, Q-2a3); `String? overrideDaysError(String text)` (trống ⇒ lỗi); `int lowCount(Iterable<({num available, num? threshold, bool hasExpired, bool hasNearExpiry})>)`.

- [ ] **Step 1: Viết test (đỏ):**

```dart
test('indicators_follow_bj01_order', () {
  expect(stockIndicators(available: 0, threshold: 10, hasExpired: true, hasNearExpiry: false),
      [StockIndicator.out, StockIndicator.expired]);
  expect(stockIndicators(available: 2, threshold: 8, hasExpired: true, hasNearExpiry: false),
      [StockIndicator.expired, StockIndicator.low]);
  expect(stockIndicators(available: 7, threshold: null, hasExpired: false, hasNearExpiry: false),
      [StockIndicator.notConfigured]);
  expect(stockIndicators(available: 30, threshold: 30, hasExpired: false, hasNearExpiry: true),
      [StockIndicator.low, StockIndicator.nearExpiry]);
});
test('primary_with_filter_falls_back_to_not_configured', () {
  final all = [StockIndicator.nearExpiry, StockIndicator.notConfigured];
  expect(primaryIndicator(all, filter: StockIndicator.low), StockIndicator.notConfigured);
  expect(primaryIndicator(all), StockIndicator.nearExpiry);
});
test('urgency_rank', () {
  expect(urgencyRank([]), 4);
  expect(urgencyRank([StockIndicator.notConfigured]), 5);
  expect(urgencyRank([StockIndicator.expired, StockIndicator.low]), 1);
});
test('row_error_cases', () {
  expect(thresholdRowError('', '', configured: false), isNull);
  expect(thresholdRowError('', '', configured: true), capRowError);
  expect(thresholdRowError('10', '', configured: false), capRowError);
  expect(thresholdRowError('10', '5', configured: false), capRowError);
  expect(thresholdRowError('-1', '5', configured: false), capRowError);
  expect(thresholdRowError('1.5', '5', configured: false), capRowError);
  expect(thresholdRowError('10', '10', configured: false), isNull);
});
test('days_errors', () {
  expect(defaultDaysError(''), isNull);
  expect(defaultDaysError('0'), capDaysError);
  expect(overrideDaysError(''), capDaysError);
  expect(overrideDaysError('60'), isNull);
});
```

Repository (fake `InventoryRpc`, ghi lại `fn` + `params`): `load_parses_snapshot` (JSON mẫu mục 2.3 → `revision`, `products.first.threshold == null` khi JSON `null`), `save_thresholds_sends_lines` (`fn == 'save_stock_thresholds'`, `params['p_lines'] == [{'product_id': 'p1', 'reorder_threshold': 10, 'target_level': 30}]`, trả `6` khi RPC trả `{'revision': 6}`), `save_near_expiry_sends_null_default`.

- [x] **Step 2: Chạy, thấy đỏ** — `flutter test --no-pub -r compact test/features/inventory/logic/stock test/features/inventory/logic/stock_policy test/features/inventory/data/stock_policy` → FAIL.
- [x] **Step 3: Viết code** theo Interfaces.
- [x] **Step 4: Chạy lại, thấy xanh** — cùng lệnh → PASS.

### Task 3: `StockPolicyCubit`

**Files:**
- Create: `lib/features/inventory/logic/stock_policy/stock_policy_cubit.dart`, `stock_policy_state.dart`
- Test: `test/features/inventory/logic/stock_policy/stock_policy_cubit_test.dart`

**Interfaces:**
- Consumes: Task 2.
- Produces:
  - `enum StockPolicyStatus { loading, ready, denied, loadError, conflict }`; `enum ThresholdFilter { all, unset }`.
  - `class ThresholdDraft { String threshold, target; }`; `class ExpiryDraft { String defaultDays; List<({String productId, String days})> overrides; }`.
  - `StockPolicyState { status; StockPolicySnapshot? snapshot; Map<String, ThresholdDraft> thresholdDrafts; ExpiryDraft expiryDraft; ThresholdFilter filter; bool saving; AppException? saveError; int? savedRevision /* để trang hiện toast một lần */; }` + getters `dirtyProductIds`, `hasThresholdError`, `expiryDirty`, `expiryHasError`, `hasUnsavedChanges`, `bool get readOnly => !(snapshot?.isOwner ?? false) || status == StockPolicyStatus.conflict`.
  - `StockPolicyCubit({required StockPolicyRepository repository, String Function() newKey = newIdempotencyKey})`: `load()`, `reload()` (bỏ mọi nháp — "Tải lại"), `setFilter(ThresholdFilter)`, `editThreshold(String productId, {String? threshold, String? target})` (bằng giá trị đã lưu ⇒ xoá khỏi nháp, như `cap01.js:307-308`), `discardThresholds()`, `saveThresholds()` (mọi dòng nháp), `saveSingle(String productId, String threshold, String target)`, `editDefaultDays(String)`, `addOverride(String productId)` (lấy số ngày đang gõ ở mặc định, `cap01.js:380`), `editOverrideDays(String productId, String days)`, `removeOverride(String productId)`, `saveNearExpiry()`, `consumeSavedRevision()`.
  - Lưu: khoá idempotency tạo **một lần** cho mỗi nội dung gửi; lỗi ⇒ giữ khoá, `saveError` = lỗi; gửi lại cùng nội dung dùng lại khoá; nội dung đổi ⇒ khoá mới. `VERSION_CONFLICT` ⇒ `status = conflict`, giữ nháp. `NO_PERMISSION` khi load ⇒ `denied`. Lưu xong ⇒ `load()` lại, xoá nháp của tab vừa lưu, `savedRevision = revision`.

- [x] **Step 1: Viết test (đỏ)** với fake repository: `load_ready`, `load_denied_on_no_permission`, `edit_back_to_saved_value_clears_draft`, `save_thresholds_sends_only_dirty_rows`, `save_version_conflict_enters_conflict`, `retry_reuses_idempotency_key` (lần 1 ném `AppException(network)`, lần 2 cùng nháp ⇒ fake nhận cùng khoá), `changed_draft_gets_new_key`, `save_success_sets_saved_revision_and_reloads`, `switch_tab_keeps_draft` (sửa ngưỡng rồi sửa số ngày ⇒ cả hai nháp còn), `add_override_copies_default_days`.
- [x] **Step 2: Chạy, thấy đỏ** — `flutter test --no-pub -r compact test/features/inventory/logic/stock_policy/stock_policy_cubit_test.dart`.
- [x] **Step 3: Viết Cubit.**
- [x] **Step 4: Chạy, thấy xanh.**

### Task 4: `K7EditCell` + SCR-062 bảng (web) / danh sách (iPhone) + khung trang + SCR-063

Màn chính: SCR-062 `READY` bảng, SCR-063 `READY`. Ảnh đích: `img/G5-2a/proto-SCR-062-READY-{390,1280}.png`, `proto-SCR-063-READY-{390,1280}.png` — **ảnh v5.27.0**: SCR-063 còn khối "Hành động" và cột "Hành động" (bỏ, Q-2a2), ô mặc định có "90" (Flutter trống khi chưa đặt, Q-2a3); còn lại so như ảnh.

**Code prototype (chép nguyên, `specs/themes/theme-07/03.design/prototype/html/`):**

`app/cap01.js:125-139` (khung, thanh chọn, banner):

```js
function capShell({ title = CAP_TITLE, subtitle = null, body, actions = "", centered = false, back = true }) {
  return appShell({ title, subtitle, body, actions, centered, back, backAction: back ? "cap-back" : "", extraClass: "k7-wide" });
}
function capTabs() {
  return dsSegmented({ items: [["SCR-062", "Ngưỡng tồn"], ["SCR-063", "Cận hạn"]], value: activeScreenId, attr: "data-cap-tab", label: "Loại chính sách" });
}
// Banner theo trạng thái / vai; trả { notice, readOnly }.
function capNotice(state, hasInlineError = false) {
  const staff = !capCanEdit();
  if (staff) return { notice: k1Locked({ title: "Chỉ chủ cửa hàng thay đổi được chính sách.", description: "Bạn có thể xem các mức hiện tại." }), readOnly: true };
  if (state === "LOCKED") return { notice: k1Locked({ title: "Đang ở chế độ chỉ xem", description: "Chính sách đang được cập nhật ở nơi khác. Bạn có thể xem nhưng chưa thể lưu." }), readOnly: true };
  if (state === "CONFLICT") return { notice: k1Stale({ title: "Chính sách vừa được cập nhật", description: "Tải lại giá trị hiện hành trước khi lưu thay đổi.", actionLabel: "Tải lại", actionAttr: "data-cap-reload" }), readOnly: true };
  if (state === "VALIDATION_ERROR" && !hasInlineError) return { notice: vBanner("error", "Chưa thể tiếp tục", "Kiểm tra lại các giá trị được nhập trước khi lưu."), readOnly: false };
  return { notice: "", readOnly: false };
}
```

`app/cap01.js:154-171` (dòng bảng, dòng iPhone):

```js
function capTableRow(p) {
  const v = capShown(p), err = capRowError(v, capIsConfigured(p)), dirty = capIsDirty(p), ro = !capCanEdit() || ["LOCKED", "CONFLICT"].includes(stateByScreen["SCR-062"]);
  const after = capApplied(p, v);
  return {
    id: p.id, uom: p.stockUom, available: String(p.available),
    product: `<strong>${dirty ? '<span class="cap-dirty-dot" role="img" aria-label="Đã sửa"></span>' : ""}${esc(p.name)}</strong><small>${esc(p.code)}</small>`,
    threshold: k7EditCell({ value: v.threshold, attr: `data-cap-input data-cap-threshold="${escapeAttribute(p.id)}"`, unit: p.stockUom, label: `Ngưỡng cảnh báo — ${p.name}`, disabled: ro }),
    target: k7EditCell({ value: v.target, attr: `data-cap-input data-cap-target="${escapeAttribute(p.id)}"`, unit: p.stockUom, error: err, label: `Mức tồn mục tiêu — ${p.name}`, disabled: ro }),
    badge: capIndicatorBadge(after),
  };
}
function capMobileRow(r) {
  const p = capProduct(r.id);
  const sub = capIsConfigured(p) ? `Ngưỡng ${p.threshold} · Mục tiêu ${p.target} ${p.stockUom}` : "Chưa có ngưỡng";
  // Chỉ xem (nhân viên / khoá / dữ liệu cũ): dòng trạng thái, không mũi tên, không mở sheet.
  const ro = !capCanEdit() || ["LOCKED", "CONFLICT"].includes(stateByScreen["SCR-062"]);
  return ds24ListRow({ title: p.name, subtitle: sub, trailing: capIndicatorBadge(p), leading: null, attrs: ro ? "" : `data-cap-edit-row="${escapeAttribute(p.id)}"`, type: ro ? "Status" : "Navigation" });
}
```

`app/cap01.js:60-67` (badge chỉ báo):

```js
const CAP_BADGE_ORDER = ["OUT", "EXPIRED", "LOW", "NEAR", "NOT_CONFIGURED"];
function capIndicatorBadge(p) {
  const inds = bj01Indicators(p);
  const key = CAP_BADGE_ORDER.find((k) => inds.some((i) => i.key === k));
  if (!key) return ds24Badge("Bình thường", "Success");
  const label = inds.find((i) => i.key === key).label;
  return BJ01_STOCK_TONE[key] ? ds24DotBadge(label, BJ01_STOCK_TONE[key]) : ds24Badge(label, "Neutral");
}
```

`app/cap01.js:205-226` (thân SCR-062 bảng):

```js
  const dirty = capDirtyProducts(), hasErr = capHasError();
  const { notice, readOnly } = capNotice(state, hasErr);
  const unset = capUnsetCount();
  const products = bj01Products.filter((p) => capFilter === "ALL" || !capIsConfigured(p));
  const rows = products.map(capTableRow);
  const columns = [
    { key: "product", label: "Sản phẩm", html: true },
    { key: "uom", label: "ĐVT" },
    { key: "available", label: "Khả dụng", align: "end", mono: true },
    { key: "threshold", label: "Ngưỡng cảnh báo", align: "end", html: true },
    { key: "target", label: "Mức tồn mục tiêu", align: "end", html: true },
    { key: "badge", label: "Chỉ báo", html: true },
  ];
  const table = k7Table({ columns, rows, mobileRow: capMobileRow, caption: "Ngưỡng tồn theo sản phẩm", empty: { title: "Không còn sản phẩm nào chưa có ngưỡng", description: "Mọi sản phẩm đã có ngưỡng cảnh báo.", actionLabel: "Xem tất cả", actionAttr: 'data-cap-filter="ALL"' } });
  const chips = k7FilterChips({ items: [["ALL", "Tất cả", bj01Products.length], ["UNSET", "Chưa có ngưỡng", unset]], selected: capFilter, attrName: "data-cap-filter" });
  const body = `${notice}${capTabs()}${chips}${table}<p class="cap-note">${CAP_NOTE}</p>${capImpactSheet()}${capSheetEdit()}`;
  const actions = readOnly ? "" : k4Footer([
    { label: "Huỷ thay đổi", attr: "data-cap-discard", disabled: dirty.length === 0 },
    { label: `Lưu thay đổi (${dirty.length})`, attr: "data-cap-open-save", primary: true, disabled: dirty.length === 0 || hasErr },
  ]).replace('class="app-actions', 'class="app-actions k7-web-only');
  return capShell({ body, actions });
```

`app/cap01.js:229-268` (SCR-063 — phần **in đậm bỏ** theo Q-2a2: `select`, `choice`, `capField("Hành động", …)`, cột `select`):

```js
function capOverrideRow(o, ro) {
  const p = capProduct(o.productId), err = Number(o.days) > 0 ? "" : CAP_DAYS_ERROR;
  const days = k7EditCell({ value: o.days, attr: `data-cap-input data-cap-ovr-days="${escapeAttribute(o.productId)}"`, unit: "ngày", error: err, label: `Số ngày cận hạn — ${p.name}`, disabled: ro });
  const select = /* bỏ — Q-2a2 */ …;
  const remove = ro ? "" : `<button type="button" class="cap-link-button" data-cap-override-remove="${escapeAttribute(o.productId)}">Dùng mặc định</button>`;
  return { id: o.productId, product: `<strong>${esc(p.name)}</strong><small>${esc(p.code)}</small>`, days, select, remove, p };
}
function capOverrideMobile(r) {
  return `<div class="cap-row-card"><div class="cap-row-card__head"><span><strong>${esc(r.p.name)}</strong><small>${esc(r.p.code)}</small></span>${r.remove}</div>${r.days}${r.select}</div>`;
}
function render063CAP01(state) {
  if (state === "PERMISSION_DENIED") return capDenied("SCR-063");
  const d = capExpiryDraft, daysErr = Number(d.days) > 0 ? "" : CAP_DAYS_ERROR;
  const hasErr = Boolean(daysErr) || d.overrides.some((o) => !(Number(o.days) > 0));
  const { notice, readOnly: ro } = capNotice(state, hasErr);
  const rowsView = d.overrides.map((o) => capOverrideRow(o, ro));
  const choice = /* bỏ — Q-2a2 */ …;
  const defaults = `<div class="cap-narrow cap-narrow--start">${ac310SectionTitle("Mặc định cho mọi sản phẩm")}${capField("Số ngày cận hạn", k7EditCell({ value: d.days, attr: "data-cap-input data-cap-expiry-days", unit: "ngày", error: daysErr, label: "Số ngày cận hạn", disabled: ro }), "Tính từ ngày hiện tại đến hạn dùng.")}${capField("Hành động", choice) /* bỏ */}</div>`;
  const columns = [
    { key: "product", label: "Sản phẩm", html: true },
    { key: "days", label: "Số ngày", align: "end", html: true },
    { key: "select", label: "Hành động", html: true }, // bỏ
    { key: "remove", label: "", align: "end", html: true },
  ];
  const list = rowsView.length
    ? k7Table({ columns, rows: rowsView, mobileRow: capOverrideMobile, caption: "Sản phẩm có chính sách riêng" })
    : `<p class="cap-note">Chưa có sản phẩm nào có chính sách riêng.</p>`;
  const add = ro ? "" : cfSecondary("Thêm sản phẩm", "data-cap-override-add");
  const body = `${notice}${capTabs()}${defaults}${ac310SectionTitle("Sản phẩm có chính sách riêng")}${list}${add}<p class="cap-note">${CAP_NOTE}</p>${capAddSheet()}`;
  const actions = ro ? "" : primaryFooter("Lưu thay đổi", "data-cap-save-expiry", hasErr);
  return capShell({ body, actions });
}
```

`app/shared-patterns.js:193-204` (`k7EditCell`, `dsSegmented`):

```js
function k7EditCell({ value, attr, unit = "", error = "", label, disabled = false }) {
  const invalid = error ? ' aria-invalid="true"' : "";
  return `<span class="k7-edit${error ? " k7-edit--error" : ""}" data-ds-component="VNumberField"><span class="k7-edit__box"><input type="number" inputmode="numeric" min="0" step="1" value="${escapeAttribute(value ?? "")}" ${attr} aria-label="${escapeAttribute(label)}"${invalid}${disabled ? " disabled" : ""}>${unit ? `<em class="k7-edit__unit" aria-hidden="true">${esc(unit)}</em>` : ""}</span>${error ? `<small class="field-error" role="alert">${esc(error)}</small>` : ""}</span>`;
}
function dsSegmented({ items, value, attr, label = "Chọn mục" }) {
  return `<div class="ds-segmented" role="group" aria-label="${escapeAttribute(label)}" data-ds-component="VSegmentedControl">${items.map(([key, text]) => `<button type="button" class="ds-segment${key === value ? " is-selected" : ""}" ${attr}="${escapeAttribute(key)}" aria-pressed="${key === value}">${esc(text)}</button>`).join("")}</div>`;
}
```

CSS `styles/components.css:2673-2676, 2684-2717, 2720, 2725, 3088-3090` (bỏ `.ds-choice-*`, `.ds-radio`, `.cap-select`):

```css
.ds-segmented { display: grid; grid-auto-flow: column; grid-auto-columns: minmax(0, 1fr); gap: 4px; padding: 4px; border-radius: 12px; background: var(--c45-v2-surface-subtle); }
.ds-segment { min-height: 44px; border: 0; border-radius: 9px; background: transparent; color: var(--c45-v2-text-secondary); font: inherit; font-size: 13px; font-weight: 600; cursor: pointer; }
.ds-segment.is-selected { background: var(--c45-v2-surface-default); color: var(--c45-v2-action-primary-default); box-shadow: 0 1px 3px rgba(18, 32, 26, .10); }
.k7-edit { display: flex; flex-direction: column; gap: 2px; min-width: 0; }
.k7-edit__box { display: flex; align-items: center; gap: 6px; height: 44px; padding: 0 var(--c45-v2-space-3); box-sizing: border-box; border: 1px solid var(--c45-v2-border-default); border-radius: var(--c45-v2-radius-input); background: var(--c45-v2-surface-default); }
.k7-edit__box:focus-within { border-color: var(--c45-v2-border-brand); box-shadow: 0 0 0 2px var(--c45-v2-surface-brand); }
.k7-edit--error .k7-edit__box { border-color: var(--c45-v2-text-danger); }
.k7-edit__box input { flex: 1 1 auto; min-width: 0; width: 100%; border: 0; outline: 0; background: transparent; color: var(--c45-v2-text-primary); font: 500 14px/20px var(--c45-v2-font-mono); font-variant-numeric: tabular-nums; text-align: right; }
.k7-edit__box input:disabled { color: var(--c45-v2-text-secondary); }
.k7-edit__unit { flex: 0 0 auto; color: var(--c45-v2-text-secondary); font: 400 12px/16px Inter, system-ui, sans-serif; font-style: normal; }
.k7-edit .field-error { color: var(--c45-v2-text-danger); font-size: 12px; line-height: 16px; text-align: left; }
.k7-table td .k7-edit { min-width: 120px; max-width: 168px; margin-left: auto; }
.cap-note { margin: 0; color: var(--c45-v2-text-secondary); font: 400 12px/18px Inter, system-ui, sans-serif; }
.cap-dirty-dot { display: inline-block; width: 8px; height: 8px; margin-right: 6px; border-radius: 50%; background: var(--c45-v2-action-primary-default); vertical-align: middle; }
.cap-field { display: flex; flex-direction: column; gap: var(--c45-v2-space-2); }
.cap-field > label { color: var(--c45-v2-text-primary); font: 600 13px/18px Inter, system-ui, sans-serif; }
.cap-preview { margin: 0; color: var(--c45-v2-text-primary); font: 500 14px/20px Inter, system-ui, sans-serif; }
.cap-row-card { display: flex; flex-direction: column; gap: var(--c45-v2-space-2); padding: var(--c45-v2-space-3); border: 1px solid var(--c45-v2-border-default); border-radius: var(--c45-v2-radius-3); background: var(--c45-v2-surface-default); }
.cap-row-card__head { display: flex; align-items: flex-start; justify-content: space-between; gap: var(--c45-v2-space-2); }
.cap-link-button { border: 0; background: transparent; color: var(--c45-v2-action-primary-default); font: 600 13px/18px Inter, system-ui, sans-serif; cursor: pointer; padding: 8px 0; min-height: 44px; }
.device-preview.is-web .cap-link-button { position: relative; min-height: 0; padding: 0; }
.cap-narrow { display: flex; flex-direction: column; gap: var(--c45-v2-space-3); }
.device-preview.is-web .k7-wide .cap-narrow { width: 100%; max-width: 560px; margin: 0 auto; }
.device-preview.is-web .k7-wide .cap-narrow--start { margin: 0; }
.device-preview.is-web .k7-edit__box { height: 40px; }
.device-preview.is-web .ds-segment { min-height: 40px; }
.k7-edit__box:has(input:disabled) { background: var(--c45-v2-surface-subtle); }
.k7-table:has(.k7-edit) td { vertical-align: middle; }
.device-preview.is-web .k7-wide .cap-narrow .k7-edit:has([data-cap-expiry-days]) { max-width: 200px; }
.device-preview.is-web .k7-wide [data-cap-override-add] { width: auto; min-width: 160px; justify-self: start; align-self: flex-start; }
```

Token: `surface-subtle` #E5E8EB, `surface-default` #FFFFFF, `surface-brand` #EBF4EC, `action-primary-default` #2F7A3A, `text-secondary` #4A535E, `text-primary` #0E1116, `text-danger` #B53232, `border-default` #E5E8EB, `border-brand` #B8DFBD, `radius-input` 8, `radius-3` 8, `space-2` 8, `space-3` 12.

**Bảng ánh xạ → Flutter:**

| Phần tử prototype | Flutter | Tham số / giá trị |
|---|---|---|
| `capShell` / `appShell(extraClass:"k7-wide")` | `Scaffold` + `VAppBar(title: 'Chính sách tồn & cận hạn')`; bề rộng web theo `inventoryIsWide(context)` (patterns, G5-0a) | nút quay lại → `_confirmLeave` rồi `context.pop()` (về nơi đã đến; vào thẳng URL thì `/warehouse`) |
| `capNotice` staff | `InventoryLocked(title: 'Chỉ chủ cửa hàng thay đổi được chính sách.', description: 'Bạn có thể xem các mức hiện tại.')` | khi `!snapshot.isOwner` |
| `capNotice` `LOCKED` | **bỏ** — Q-2a4 | — |
| `capNotice` `CONFLICT` | `InventoryStale(title: 'Chính sách vừa được cập nhật', description: 'Tải lại giá trị hiện hành trước khi lưu thay đổi.', actionLabel: 'Tải lại', onAction: cubit.reload)` | `status == conflict` |
| `capNotice` `VALIDATION_ERROR` không có lỗi dòng | **bỏ** (Flutter không mở bằng trạng thái; lỗi luôn ở dưới ô) | — |
| lỗi lưu | `VBanner(tone: error, title: 'Chưa lưu được chính sách', message: inventoryErrorMessage(code), action: 'Thử lại')` | đặt ngay dưới thanh chọn — đề xuất mục 1 |
| `dsSegmented` | `VSegmentedControl(segments: ['Ngưỡng tồn','Cận hạn'], semanticLabel: 'Loại chính sách')` | cao 44 (iPhone) / 40 (web ≥ 1024); đổi tab = `context.replace('/warehouse/stock-policy?tab=expiry')` / bỏ query, **không** hỏi bỏ nháp |
| `k7FilterChips` | `K7FilterChips(items: [K7Filter(key: 'all', label: 'Tất cả', count: products.length), K7Filter(key: 'unset', label: 'Chưa có ngưỡng', count: …)])` (G5-0a) | số theo giá trị **đã lưu**; chip 0 mờ sẵn có |
| `k7Table` | `K7Table<StockPolicyProduct>(columns: [K7Column('Sản phẩm'), K7Column('ĐVT'), K7Column('Khả dụng', numeric: true), K7Column('Ngưỡng cảnh báo'), K7Column('Mức tồn mục tiêu'), K7Column('Chỉ báo')], mobileRow: …)` (G5-0a; web bảng, iPhone `mobileRow`) | `Khả dụng` mono |
| ô "Sản phẩm" + `cap-dirty-dot` | `Column(name 14/600, code 12 text-secondary)`; chấm 8×8 `#2F7A3A` cách tên 6, `Semantics(label: 'Đã sửa')` | |
| `k7EditCell` | `K7EditCell` (mới, Step 3) | |
| `capIndicatorBadge(after)` | `StockIndicatorBadge(indicators)` (mới trong `stock_policy/`): không chỉ báo ⇒ `VBadge('Bình thường', tone: success)`; tone có ⇒ `VBadge(showDot: true)` (chấm rỗng cho `danger` thêm ở G5-2 — ở plan này dùng chấm sẵn có); `notConfigured` ⇒ `VBadge` trung tính | tính theo nháp **hợp lệ** (`capApplied`, `cap01.js:56-59`) |
| `capMobileRow` (iPhone, `mobileRow`) | `VListRow(title, subtitle, trailing: StockIndicatorBadge, type: readOnly ? VListRowType.plain : VListRowType.navigation, onTap: readOnly ? null : mở sheet sửa)` | phụ đề "Ngưỡng {M} · Mục tiêu {m} {ĐVT}" / "Chưa có ngưỡng" |
| `empty` của `k7Table` (lọc "Chưa có ngưỡng" rỗng) | `InventoryEmpty(title: 'Không còn sản phẩm nào chưa có ngưỡng', description: 'Mọi sản phẩm đã có ngưỡng cảnh báo.', actionLabel: 'Xem tất cả')` | |
| `.cap-note` | `Text('Thay đổi chính sách không làm đổi số tồn.', 12/18, #4A535E)` | |
| `k4Footer` web (`k7-web-only`) | `InventoryFooter` hai nút: phụ "Huỷ thay đổi" (tắt khi không nháp), chính "Lưu thay đổi ({n})" (tắt khi `n == 0` hoặc có lỗi) | **chỉ web**; iPhone không chân |
| 063 `ac310SectionTitle` | `VSection(title: …, child: …)` sẵn có | "Mặc định cho mọi sản phẩm", "Sản phẩm có chính sách riêng" |
| 063 `capField("Số ngày cận hạn", k7EditCell…, hint)` | nhãn 13/600 + `K7EditCell(unit: 'ngày', maxWidth web 200)` + chú thích 12/18 | gợi ý "Tính từ ngày hiện tại đến hạn dùng."; trống ⇒ "Chưa đặt: không đánh dấu lô cận hạn." (đề xuất) |
| 063 `choice` / `capField("Hành động")` / cột "Hành động" / `cap-select` | **bỏ** — Q-2a2 | — |
| 063 bảng riêng | `K7Table(columns: [K7Column('Sản phẩm'), K7Column('Số ngày', numeric: true), K7Column('')], mobileRow: thẻ dưới)` | cột cuối nút "Dùng mặc định" (`VButton(variant: VButtonVariant.tertiary)`, vùng chạm 44) |
| `capOverrideMobile` | thẻ `VCard` viền `#E5E8EB` r8 pad 12: đầu (tên + mã | "Dùng mặc định"), dưới `K7EditCell` | |
| chưa có dòng riêng | `Text('Chưa có sản phẩm nào có chính sách riêng.')` kiểu `.cap-note` | |
| `cfSecondary("Thêm sản phẩm")` | `VButton(variant: VButtonVariant.secondary)` rộng theo chữ, min 160 (web) / full (iPhone) | ẩn khi `readOnly` |
| `primaryFooter("Lưu thay đổi")` 063 | `InventoryFooter` một nút chính, tắt khi `expiryHasError` hoặc `!expiryDirty` | cả iPhone và web; ẩn khi `readOnly` |

- [ ] **Step 1: Test `K7EditCell` (đỏ)** — `test/features/inventory/presentation/patterns/k7_edit_cell_test.dart`: `shows_unit_suffix`, `shows_error_below_and_red_border` (viền `#B53232`), `disabled_uses_subtle_background` (`#E5E8EB`), `height_44_mobile_40_web`, `semantics_label`.
- [ ] **Step 2: Viết `K7EditCell({required String value, required ValueChanged<String> onChanged, String unit = '', String? errorText, required String semanticLabel, bool enabled = true, TextInputAction? textInputAction, double? maxWidth})`** — bọc `VNumberField(suffixText: unit)`; chỉ nhận chữ số (`FilteringTextInputFormatter.digitsOnly`); căn phải, mono 14/20 w500. Thiếu tham số lỗi / cao ở `VNumberField` thì mở rộng `VNumberField` trong `packages/c45_design_system` (kèm test ở `packages/c45_design_system/test/`).
- [ ] **Step 3: Widget test SCR-062 / SCR-063 (đỏ)** — `test/features/inventory/presentation/stock_policy/stock_policy_page_test.dart`, fake repository 5 sản phẩm như fixture `bj01.js:12-24` (Nobivac ngưỡng 30/80, Amox 50/80, Enro 10/30 tồn 0, Tylo 8/24 có lô hết hạn, Oxy chưa có ngưỡng); hai bề rộng 390 × 844 và 1280 × 800:
  - `table_ready_1280`: 6 tiêu đề cột đúng chữ; chip "Tất cả 5", "Chưa có ngưỡng 1"; chân "Lưu thay đổi (0)" tắt.
  - `edit_row_marks_dirty_and_recomputes_badge_1280`: gõ ngưỡng Oxy 20, mục tiêu 40 ⇒ có `Semantics('Đã sửa')`, badge Oxy "Tồn thấp", chân "Lưu thay đổi (1)" bật.
  - `row_error_disables_save_1280`: mục tiêu 5 < ngưỡng 10 ⇒ chữ "Mục tiêu phải lớn hơn hoặc bằng ngưỡng.", nút lưu tắt.
  - `list_ready_390`: không có `VTable`, không chân; dòng Oxy phụ đề "Chưa có ngưỡng"; dòng Nobivac "Ngưỡng 30 · Mục tiêu 80 hộp".
  - `staff_read_only_390`: `isOwner false` ⇒ "Chỉ chủ cửa hàng thay đổi được chính sách.", dòng không chevron, chạm không mở sheet.
  - `conflict_shows_reload_1280`; `save_error_shows_retry_1280`.
  - `expiry_tab_ready_1280`: không có chữ "Hành động" / "Chặn bán"; ô mặc định trống + chú thích "Chưa đặt: không đánh dấu lô cận hạn."; "Chưa có sản phẩm nào có chính sách riêng.".
  - `expiry_zero_days_error_390`: gõ 0 ⇒ "Số ngày cận hạn phải lớn hơn 0.", nút "Lưu thay đổi" tắt.
  - `switch_tab_keeps_draft`: sửa ngưỡng ⇒ sang "Cận hạn" ⇒ về lại ⇒ ô vẫn giá trị đã gõ.
  - `leave_with_draft_asks_confirm`: có nháp, bấm quay lại ⇒ "Bỏ thay đổi chưa lưu?"; "Ở lại" giữ màn.
- [ ] **Step 4: Chạy, thấy đỏ** — `flutter test --no-pub -r compact test/features/inventory/presentation/patterns/k7_edit_cell_test.dart test/features/inventory/presentation/stock_policy/stock_policy_page_test.dart`.
- [ ] **Step 5: Dựng** `stock_policy_page.dart` (khung, `BlocProvider`, thanh chọn, `PopScope` hỏi bỏ nháp, toast `VToast` "Đã lưu chính sách · Lần {N}" khi `savedRevision != null` rồi `consumeSavedRevision()`), `stock_threshold_tab.dart`, `near_expiry_tab.dart` theo bảng ánh xạ; trạng thái `loading` / `denied` / `loadError` dùng `InventoryLoading(blocks: [card, row, row, row])` / `InventoryDenied(what: 'xem hoặc thay đổi chính sách tồn', next: 'Liên hệ chủ cửa hàng nếu cần.', onExit: () => context.go('/warehouse'))` / `InventoryEmpty` + "Thử lại". Câu `PERMISSION_DENIED` nguyên văn SCR-062 mục 8: "Bạn chưa có quyền xem hoặc thay đổi chính sách tồn".
- [ ] **Step 6: Chạy, thấy xanh.**

### Task 5: Sheet tác động, sheet sửa iPhone, chế độ một sản phẩm, sheet thêm sản phẩm

**Code prototype** `app/cap01.js:172-203` (sheet tác động, hai ô một sản phẩm, sheet sửa, chế độ "single"):

```js
function capImpactSheet() {
  if (!capSaveOpen) return "";
  const list = capDirtyProducts();
  const items = list.map((p) => {
    const v = capShown(p), old = capIsConfigured(p) ? `${p.threshold} / ${p.target}` : "chưa có";
    return `<li><strong>${esc(p.name)}</strong>: ${esc(old)} → ${esc(v.threshold)} / ${esc(v.target)} ${esc(p.stockUom)}</li>`;
  }).join("");
  const before = capLowCount(bj01Products), after = capLowCount(bj01Products.map((p) => (capIsDirty(p) ? capApplied(p, capShown(p)) : p)));
  const body = `<ul class="cap-sheet-list">${items}</ul><p class="cap-preview">Tồn thấp: ${before} → ${after} sản phẩm</p><p class="cap-note">${CAP_NOTE}</p>`;
  return capSheet({ title: `Lưu ${list.length} thay đổi?`, body, actions: `${capCloseBtn()}${capPrimaryBtn("Lưu chính sách", "data-cap-save")}` });
}
function capSingleFields(p, readOnly) {
  const v = capSingle, err = capRowError(v, capIsConfigured(p));
  const cell = (label, attr, value, error = "") => capField(label, k7EditCell({ value, attr: `data-cap-input ${attr}`, unit: p.stockUom, error, label: `${label} — ${p.name}`, disabled: readOnly }));
  const preview = err || capSingleEmpty(v) ? "" : `<p class="cap-preview" data-cap-preview>Sau khi lưu: ${esc(capPreviewLabel(p, v))}</p>`;
  return `<p class="cap-preview">Khả dụng ${esc(p.available)} ${esc(p.stockUom)}</p>${cell("Ngưỡng cảnh báo", 'data-cap-s-threshold=""', v.threshold)}${cell("Mức tồn mục tiêu", 'data-cap-s-target=""', v.target, err)}${preview}`;
}
function capSheetEdit() {
  if (!capSheetProductId) return "";
  const p = capProduct(capSheetProductId);
  return capSheet({ title: p.name, body: capSingleFields(p, false), actions: `${capCloseBtn()}${capPrimaryBtn("Lưu", "data-cap-save-single", capSingleBlocked(p, capSingle))}` });
}
function render062CAP01(state) {
  if (state === "PERMISSION_DENIED") return capDenied("SCR-062");
  if (capMode === "single") {
    const p = capProduct(capProductId), err = capRowError(capSingle, capIsConfigured(p));
    const { notice, readOnly } = capNotice(state, Boolean(err));
    const body = `<div class="cap-narrow">${notice}${capSingleFields(p, readOnly)}<p class="cap-note">${CAP_NOTE}</p></div>`;
    const actions = readOnly ? "" : primaryFooter("Lưu", "data-cap-save-single", capSingleBlocked(p, capSingle));
    return capShell({ title: esc(p.name), subtitle: "Ngưỡng tồn", body, actions });
  }
```

`app/cap01.js:68-72` (`capPreviewLabel`) và `239-247` (`capAddSheet`):

```js
function capPreviewLabel(p, v) {
  const inds = bj01Indicators(capApplied(p, v));
  const key = ["OUT", "EXPIRED", "LOW", "NEAR"].find((k) => inds.some((i) => i.key === k));
  return key ? inds.find((i) => i.key === key).label : "Không có cảnh báo";
}
function capAddSheet() {
  if (!capAddOpen) return "";
  const taken = new Set(capExpiryDraft.overrides.map((o) => o.productId));
  const options = bj01Products.filter((p) => p.tracking === "LOT" && !taken.has(p.id));
  const body = options.length
    ? `<div class="ds24-list-stack">${options.map((p) => ds24ListRow({ title: p.name, subtitle: p.code, leading: null, attrs: `data-cap-override-pick="${escapeAttribute(p.id)}"`, type: "Navigation" })).join("")}</div>`
    : `<p class="cap-note">Mọi sản phẩm theo lô đều đã có chính sách riêng.</p>`;
  return capSheet({ title: "Thêm sản phẩm", body, actions: capCloseBtn("Đóng") });
}
```

CSS `styles/components.css:2710-2716` + `3080-3082` (hộp thoại web 480, bo 16, pad 20, không thanh kéo):

```css
.cap-sheet-list { display: flex; flex-direction: column; gap: var(--c45-v2-space-2); margin: 0; padding: 0; list-style: none; }
.cap-sheet-list li { font: 400 14px/20px Inter, system-ui, sans-serif; }
.cap-sheet-list li strong { font-weight: 600; }
.cap-sheet .sheet-content { display: flex; flex-direction: column; gap: var(--c45-v2-space-3); }
.cap-sheet .sheet-actions { margin-top: var(--c45-v2-space-2); }
.device-preview.is-web .k7-wide .bottom-sheet[data-ds-component="VBottomSheet"] { width: 480px; padding: var(--c45-v2-space-5) var(--c45-v2-space-5) var(--c45-v2-space-5); border-radius: var(--c45-v2-radius-sheet); }
```

**Bảng ánh xạ → Flutter:**

| Phần tử | Flutter | Ghi chú |
|---|---|---|
| `capSheet` | `showVAdaptiveSheet` (bottom sheet iPhone, hộp thoại 480 web — sẵn có) | |
| `capImpactSheet` | `ThresholdImpactSheet`: tiêu đề "Lưu {n} thay đổi?"; mỗi dòng `Text.rich` (tên 600) + ": {cũ} → {ngưỡng} / {mục tiêu} {ĐVT}" ("chưa có" khi chưa cấu hình); "Tồn thấp: {a} → {b} sản phẩm" 14/500; `.cap-note`; nút phụ "Huỷ", chính "Lưu chính sách" | chỉ web (mở từ chân) |
| `capSheetEdit` (iPhone) | `ThresholdEditSheet`: tiêu đề tên sản phẩm; `capSingleFields`; "Huỷ" / "Lưu" (tắt khi `singleBlocked`) | lưu thẳng, ở lại danh sách, toast |
| `capSingleFields` | "Khả dụng {n} {ĐVT}" 14/500; hai `K7EditCell` có nhãn 13/600 ("Ngưỡng cảnh báo", "Mức tồn mục tiêu"; lỗi dưới ô mục tiêu); "Sau khi lưu: {chỉ báo}" / "Sau khi lưu: Không có cảnh báo" — ẩn khi lỗi hoặc hai ô trống | dùng chung sheet + trang một sản phẩm |
| `render062` `single` | `StockThresholdSinglePage(productId)`: `VAppBar(title: tên, subtitle: 'Ngưỡng tồn')`, không thanh chọn; thân rộng tối đa 560 căn giữa (web); `InventoryFooter` một nút "Lưu" | lưu xong ⇒ `context.pop(true)` + toast; G5-2 nhận `true` thì tải lại SCR-003 |
| `capAddSheet` | `NearExpiryAddSheet`: `VListRow` (tên, mã, chevron) của sản phẩm `isLotTracked` chưa có dòng riêng; rỗng ⇒ "Mọi sản phẩm theo lô đều đã có chính sách riêng."; nút "Đóng" | chọn ⇒ `addOverride` |

- [x] **Step 1: Widget test (đỏ)** thêm vào `stock_policy_page_test.dart` + `stock_threshold_single_page_test.dart`: `impact_sheet_lists_changes_and_low_delta_1280` (sửa Oxy 20/40 ⇒ "Lưu 1 thay đổi?", "Oxytetracycline LA: chưa có → 20 / 40 chai", "Tồn thấp: 2 → 3 sản phẩm"; "Lưu chính sách" gọi `saveThresholds` 1 dòng); `edit_sheet_saves_directly_390`; `single_preview_hidden_when_empty`, `single_preview_shows_low` ("Sau khi lưu: Tồn thấp"); `single_save_pops_true`; `single_staff_read_only` (không nút "Lưu"); `add_sheet_lists_only_lot_products` (Nobivac, Tylosin; không Amox).
- [x] **Step 2: Chạy, thấy đỏ.**
- [x] **Step 3: Dựng** 4 widget theo bảng.
- [x] **Step 4: Chạy, thấy xanh.**

### Task 6: Route, DI, lối vào Hub "Thiết lập kho"

**Files:** Modify `lib/core/router/app_router.dart`, `lib/core/di/injection.dart`, `lib/features/inventory/presentation/hub/warehouse_entries.dart` (+ nơi dựng danh sách khu ở `warehouse_hub_page.dart`); Create `lib/features/inventory/presentation/stock_policy/stock_policy_routes.dart`; Test `test/features/inventory/presentation/stock_policy/stock_policy_routes_test.dart`, sửa test Hub hiện có.

**Interfaces:**
- Produces: `List<RouteBase> stockPolicyRoutes()` — `GoRoute('/warehouse/stock-policy')` (query `tab=expiry` ⇒ tab Cận hạn) và `GoRoute('/warehouse/stock-policy/product/:productId')`; đặt cạnh các route `/warehouse/receipts/...` (con của `ShellRoute(StoreShell)`, ngoài `StatefulShellRoute` — PLAN "Điều hướng"). G5-2 mở `context.push<bool>('/warehouse/stock-policy/product/$id')`.
- `WarehouseArea.setup` (`id 'setup'`, "Thiết lập kho", "Các việc thiết lập ít dùng", `VIcons.inbox`, không `ownerOnly`) với một lối vào `WarehouseEntry(id: 'stock_policy', title: 'Chính sách tồn & cận hạn', subtitle: 'Thiết lập ngưỡng tồn và chính sách cảnh báo', icon: VIcons.shield, route: '/warehouse/stock-policy')` — chữ theo `hub.js:56-58`.
- DI: `registerLazySingleton<StockPolicyRepository>(() => StockPolicyRepository(rpc: getIt<InventoryRpc>()))`.

- [x] **Step 1: `impact`** cho `WarehouseArea`, `warehouseAreaEntries`, `WarehouseHubPage`; ghi vào Kết quả.
- [x] **Step 2: Test (đỏ):** `route_opens_threshold_tab`, `route_tab_expiry_opens_expiry`, `route_product_opens_single`, `hub_shows_setup_area_with_stock_policy` (Hub có dòng "Thiết lập kho"; khu `/warehouse/area/setup` có "Chính sách tồn & cận hạn" mở được).
- [x] **Step 3: Chạy, thấy đỏ.**
- [x] **Step 4: Viết** route, DI, entry. Hub iPhone / web: khu "Thiết lập kho" đứng cuối nhóm "Quản lý kho" như `hub.js` (web cột phải).
- [x] **Step 5: Chạy test Hub + route, thấy xanh** — `flutter test --no-pub -r compact test/features/inventory`.

### Task 7: Luồng đầu–cuối, đối chiếu ảnh, kiểm cuối

- [x] **Step 1: Test luồng** `test/features/inventory/presentation/stock_policy/stock_policy_flow_test.dart` (fake repository giữ trạng thái): Hub → "Thiết lập kho" → "Chính sách tồn & cận hạn" → sửa ngưỡng Oxy 20/40 → "Lưu thay đổi (1)" → "Lưu chính sách" → toast "Đã lưu chính sách · Lần 6" → chip "Chưa có ngưỡng 0" → tab "Cận hạn" → gõ 30 → "Thêm sản phẩm" → Tylosin → sửa 60 → "Lưu thay đổi" → toast "Lần 7".
- [x] **Step 2: Ảnh Flutter** (`matchesGoldenFile`, cùng bề rộng): `docs/refactor/plans/T7/img/G5-2a/flutter-SCR-062-READY-{390,1280}.png`, `flutter-SCR-063-READY-{390,1280}.png` (fixture Task 4; SCR-063: mặc định 90, Tylosin riêng 60 để giống ảnh prototype trừ phần "Hành động"). So với `proto-*`; lệch ghi Kết quả.
- [x] **Step 3: Kiểm** — `cd apps/erp && dart analyze lib/features/inventory test/features/inventory` = 0 lỗi; `flutter test --no-pub -r compact` không thêm lỗi so với `TEST-BASELINE.md`; `detect_changes()`.
- [x] **Step 4: Ghi Kết quả** (mục 5) + cập nhật PLAN.md bảng Plan (cột Làm).

## 5. Kết quả

### 5.1 Tiến độ & Kết quả kiểm thử từng Task
1. **Task 1 (SQL & Contract test):**
   - Tạo migration `20261111001_inventory_stock_policy.sql` gồm 2 bảng `inventory.product_stock_policies`, `inventory.stock_policy_settings`, 4 helper nội bộ (`_today`, `_lot_expiry_end`, `_near_expiry_days`, `_product_stock_rows`), và 3 RPC bảo mật (`get_stock_policy`, `save_stock_thresholds`, `save_near_expiry_policy`).
   - Đăng ký 7 hàm vào `supabase/migrations/REGISTRY.yaml`.
   - Viết 10 test case SQL trong `supabase/tests/inventory_stock_policy.sql` (bọc transaction rollback).
   - Test hợp đồng SQL `apps/erp/test/features/inventory/data/stock_policy_sql_contract_test.dart`: 5/5 ca test PASS.
2. **Task 2 (Luật chỉ báo, Model, Repository, Luật nháp):**
   - Viết `stock_indicator_rules.dart`, `stock_policy_models.dart`, `stock_policy_repository.dart`, `stock_policy_rules.dart`.
   - Test unit: `stock_indicator_rules_test.dart` (4/4 PASS), `stock_policy_rules_test.dart` (4/4 PASS), `stock_policy_repository_test.dart` (3/3 PASS).
3. **Task 3 (`StockPolicyCubit`):**
   - Viết `stock_policy_cubit.dart` và `stock_policy_state.dart` quản lý state đầy đủ cho cả hai tab, lọc nháp dirty, xử lý version conflict và tái sử dụng khóa idempotency khi retry (bao gồm cả `saveThresholds`, `saveSingle`, `saveNearExpiry` và `retryLastSave`).
   - Test cubit: `stock_policy_cubit_test.dart`: 11/11 ca test PASS.
4. **Task 4 & Task 5 (Màn hình & Các sheet tương tác):**
   - Tạo `K7EditCell`, `StockIndicatorBadge`, `ThresholdImpactSheet`, `ThresholdEditSheet`, `NearExpiryAddSheet`, `StockThresholdTab`, `NearExpiryTab`, `StockPolicyPage`, `StockThresholdSinglePage`.
   - Test widget: `k7_edit_cell_test.dart` (6/6 PASS), `stock_policy_page_test.dart` (16/16 PASS), `stock_threshold_single_page_test.dart` (4/4 PASS).
   - Cải tiến DS: Trong `packages/c45_design_system/lib/src/components/v_modal.dart`, thay thế `Row` bằng `Align(child: Wrap(...))` cho action buttons của `VConfirmDialog` để chống lỗi RenderFlex overflow khi nút có nhãn dài trên màn hẹp 390px; kèm unit test `packages/c45_design_system/test/components/v_modal_test.dart` (1/1 PASS).
5. **Task 6 (Route, DI, Hub entry):**
   - Tạo `stock_policy_routes.dart` với 2 route `/warehouse/stock-policy` (nhận query `tab=expiry`) và `/warehouse/stock-policy/product/:productId`.
   - Đăng ký vào `app_router.dart` bên ngoài `StatefulShellRoute` (cạnh `/warehouse/receipts/new`) dưới `ShellRoute(StoreShell)`.
   - Đăng ký `StockPolicyRepository` vào `apps/erp/lib/core/di/injection.dart` thông qua `InventoryRpc`.
   - Thêm `WarehouseArea.setup` ("Thiết lập kho") vào `warehouse_entries.dart` và gắn vào `WarehouseHubPage`.
   - Test route & Hub: `stock_policy_routes_test.dart` (5/5 PASS), `warehouse_hub_test.dart` (5/5 PASS), `warehouse_hub_pages_test.dart` (15/15 PASS), `warehouse_hub_routes_test.dart` (4/4 PASS), `warehouse_entry_parity_test.dart` (5/5 PASS).
6. **Task 7 (Luồng đầu–cuối, Đối chiếu ảnh & Kiểm cuối):**
   - Viết `stock_policy_flow_test.dart` kiểm chứng 3 flow chính:
     - Flow 1 (Web 1280): Hub → Thiết lập kho → Mở chính sách tồn → Sửa 2 sản phẩm (1 chuyển tồn thấp) → Impact sheet hiển thị thay đổi & delta tồn thấp → Lưu thành công → Toast lần 6 → Khóa nút Lưu.
     - Flow 2 (Mobile 390): Danh sách thẻ → Chạm thẻ chưa có ngưỡng → Mở sheet sửa → Nhập 10 / 20 → Lưu thành công → Cập nhật thẻ và badge An toàn.
     - Flow 3 (Cận hạn 1280 & 390, fixture ban đầu: mặc định 90 ngày, `Tylosin 200` riêng 60 ngày): Đổi số ngày mặc định thành 45 → Thêm ngoại lệ cho Amox 50% (30 ngày) → Lưu thay đổi → Toast lần 6.
   - 4/4 ca flow test PASS, chụp lại toàn bộ 4 ảnh `flutter-SCR-062-READY-{390,1280}.png` và `flutter-SCR-063-READY-{390,1280}.png`.
   - Toàn bộ `flutter test --no-pub test/features/inventory`: **230/230 PASS (0 lỗi)**.

### 5.2 Blast Radius & Impact Analysis (GitNexus)
- **`WarehouseArea`:** LOW risk (0 direct dependants affected; enum được mở rộng an toàn với nhánh `setup`).
- **`warehouseAreaEntries` & `WarehouseHubPage`:** Call graph upstream mở rộng sang các router / navigation process, các test Hub đều được đối chiếu và chạy xanh.
- **`detect_changes`:** 10 files modified, 18 symbols changed. Duy nhất 1 execution flow bị tác động (`Build → VConfirmDialog`) do fix overflow Wrap trong `v_modal.dart`. Risk level: Medium, an toàn.

### 5.3 Đối chiếu ảnh (Visual Snapshot Verification)
Các ảnh màn hình thực tế được chụp tự động trong `stock_policy_flow_test.dart` và lưu tại `docs/refactor/plans/T7/img/G5-2a/`:
- `flutter-SCR-062-READY-1280.png` vs `proto-SCR-062-READY-1280.png`: Khớp cấu trúc bảng VTable, các cột Sản phẩm, ĐVT, Khả dụng, Ngưỡng cảnh báo, Mức tồn mục tiêu, Chỉ báo (không còn viền đôi trong ô nhập `K7EditCell`), thanh chọn tab, filter chips và footer dính đáy (`Scaffold.bottomNavigationBar`).
- `flutter-SCR-062-READY-390.png` vs `proto-SCR-062-READY-390.png`: Khớp danh sách `VListRow(asCard: true)`, subtitle hiển thị ngưỡng / mục tiêu, trailing badge trạng thái giới hạn bề rộng `maxWidth: 150` để tên sản phẩm không bị ép gãy từng chữ; không hiện thanh 5 tab đáy.
- `flutter-SCR-063-READY-1280.png` vs `proto-SCR-063-READY-1280.png`: Khớp cấu trúc thiết lập số ngày mặc định (90 ngày), tiêu đề khu 15px/w600, bảng danh sách ngoại lệ có sẵn dòng `Tylosin 200` (60 ngày) + nút "Dùng mặc định", và footer dính đáy.
- `flutter-SCR-063-READY-390.png` vs `proto-SCR-063-READY-390.png`: Khớp layout mobile với card mặc định (90 ngày), thẻ ngoại lệ `Tylosin 200` (60 ngày), và nút "Lưu chính sách" dính đáy màn hình.

### 5.4 Tuân thủ kiến trúc & Kiểm tra tĩnh
- `dart analyze lib/features/inventory test/features/inventory`: **0 issues**.
- `dart run tool/check_feature_imports.dart`: **0 vi phạm** trong `features/inventory`.

### 5.5 Kết quả sửa R2 → R3 (Chi tiết 12 mục)

| # | Mức | Nội dung sửa | File đã sửa | Test kiểm chứng |
|---|---|---|---|---|
| 1 | P1 | Bỏ `Navigator.of(context).pop()` thừa trong `onAction` của `showVConfirmDialog` (do `VConfirmDialog` đã tự đóng dialog trước khi gọi `onAction`); dùng helper `_leave(context)` kiểm tra `Navigator.of(context).canPop()` để chỉ pop đúng 1 màn | `apps/erp/lib/features/inventory/presentation/stock_policy/stock_policy_page.dart` | `discard_pops_once` trong `stock_policy_page_test.dart` |
| 2 | P1 | Cập nhật test Hub từ 5 khu sang 6 khu (thêm kiểm chứng `WarehouseArea.setup` và entry `stock_policy`) | `apps/erp/test/features/inventory/logic/hub/warehouse_hub_test.dart` | `entries_copy_matches_contract` trong `warehouse_hub_test.dart` (5/5 PASS) |
| 3 | P2 | Đặt `...stockPolicyRoutes()` ngoài `StatefulShellRoute` (cạnh `/warehouse/receipts/new`) và bổ sung test kiểm chứng không hiển thị `ErpBottomNavigation` ở màn 390px | `apps/erp/lib/core/router/app_router.dart`, `apps/erp/test/features/inventory/presentation/stock_policy/stock_policy_routes_test.dart` | `route_has_no_bottom_tabs_390` trong `stock_policy_routes_test.dart` (5/5 PASS) |
| 4 | P2 | Tắt toàn bộ `border`, `enabledBorder`, `focusedBorder`, `disabledBorder`, `errorBorder`, `focusedErrorBorder` (`InputBorder.none`) trên `InputDecoration` của `K7EditCell` để xoá viền lồng bên trong | `apps/erp/lib/features/inventory/presentation/patterns/k7_edit_cell.dart`, `apps/erp/test/features/inventory/presentation/patterns/k7_edit_cell_test.dart` | `no_inner_border` trong `k7_edit_cell_test.dart` (6/6 PASS) + ảnh `flutter-SCR-062/063` |
| 5 | P2 | Đưa `InventoryFooter` ra khỏi `SingleChildScrollView` của 2 tab và gắn vào `Scaffold.bottomNavigationBar` của `StockPolicyPage` (Tab 0: chỉ hiện trên web `>= 768px`; Tab 1: hiện cả web & mobile) và `StockThresholdSinglePage` | `apps/erp/lib/features/inventory/presentation/stock_policy/stock_policy_page.dart`, `stock_threshold_tab.dart`, `near_expiry_tab.dart`, `stock_threshold_single_page.dart` | `stock_policy_page_test.dart` (16/16 PASS), `stock_threshold_single_page_test.dart` (4/4 PASS) + ảnh `flutter-SCR-062/063` |
| 6 | P2 | Giữ khoá idempotency theo payload (`_lastSinglePayload`, `_lastSingleKey`) trong `saveSingle`; lưu `lastFailedSave` (`FailedThresholdsSave` / `FailedSingleSave` / `FailedNearExpirySave`) vào `StockPolicyState` và thêm `retryLastSave()` gắn vào nút "Thử lại" trên banner lỗi | `apps/erp/lib/features/inventory/logic/stock_policy/stock_policy_state.dart`, `stock_policy_cubit.dart`, `stock_policy_page.dart` | `single_retry_reuses_key` trong `stock_policy_cubit_test.dart` (11/11 PASS), `retry_after_sheet_error_resends_single` trong `stock_policy_page_test.dart` (16/16 PASS) |
| 7 | P2 | Cập nhật fixture ban đầu của Flow 3 (`SCR-063`) có `nearExpiryDays: 90` và `Tylosin 200` (`nearExpiryDaysOverride: 60`); chụp lại 4 ảnh `flutter-SCR-*.png` | `apps/erp/test/features/inventory/presentation/stock_policy/stock_policy_flow_test.dart`, `docs/refactor/plans/T7/img/G5-2a/flutter-SCR-*.png` | `stock_policy_flow_test.dart` (4/4 PASS) + ảnh `flutter-SCR-063-READY-{390,1280}.png` |
| 8 | P3 | Dùng `VListRow(asCard: true)` kèm `ConstrainedBox(constraints: BoxConstraints(maxWidth: 150))` bọc `StockIndicatorBadge` ở `trailing` trên mobile để tên sản phẩm không bị ép gãy từng chữ | `apps/erp/lib/features/inventory/presentation/stock_policy/stock_threshold_tab.dart` | Ảnh `flutter-SCR-062-READY-390.png` |
| 9 | P3 | Đổi tiêu đề khu trong `NearExpiryTab` từ `VSection` (H3 18px) sang `Text` cỡ `15px` / `FontWeight.w600` khớp `ac310SectionTitle` | `apps/erp/lib/features/inventory/presentation/stock_policy/near_expiry_tab.dart` | Ảnh `flutter-SCR-063-READY-{390,1280}.png` |
| 10 | P3 | Đồng bộ chữ và icon của `WarehouseArea.setup` (`'Các việc thiết lập ít dùng'`, `VIcons.inbox`) và entry `stock_policy` (`'Thiết lập ngưỡng tồn và chính sách cảnh báo'`, `VIcons.shield`) khớp đúng plan Task 6 | `apps/erp/lib/features/inventory/presentation/hub/warehouse_entries.dart` | `warehouse_hub_test.dart` (5/5 PASS), `warehouse_hub_pages_test.dart` (15/15 PASS) |
| 11 | P3 | Thêm `insert into inventory.stock_policy_settings (tenant_id) values (v_tenant) on conflict (tenant_id) do nothing;` trước `select revision ... for update` trong cả `save_stock_thresholds` và `save_near_expiry_policy` để tránh lỗi trùng khoá `23505` khi 2 request lưu lần đầu đồng thời | `supabase/migrations/20261111001_inventory_stock_policy.sql` | `stock_policy_sql_contract_test.dart` (5/5 PASS) |
| 12 | P3 | Sửa tên bảng trong mục 5.1 thành `stock_policy_settings`; truyền `message: ''` khi gọi `VToast.show` để không lặp chữ; thêm widget test cho `VConfirmDialog` trong package DS | `stock_policy_page.dart`, `stock_threshold_single_page.dart`, `packages/c45_design_system/test/components/v_modal_test.dart` | `confirm_dialog_wraps_long_labels_390` trong `v_modal_test.dart` (1/1 PASS) |

## 6. Review

### R1 (2026-11-10) — ❌ chưa đạt (2 P1, 5 P2)

Đã chạy: `dart analyze lib/features/inventory test/features/inventory` = 0 lỗi; `flutter test --no-pub test/features/inventory` = **225 đạt, 1 lỗi**. So 4 ảnh `flutter-*` với `proto-*` trước khi đọc code. SQL: 10/10 ca của plan có trong `supabase/tests/inventory_stock_policy.sql` (chưa chạy — người dùng chạy).

| # | Mức | Chỗ | Lỗi | Sửa |
|---|---|---|---|---|
| 1 | P1 | `stock_policy_page.dart:59-62` | Bấm "Bỏ thay đổi" **đóng hai màn**: `VConfirmDialog` đã tự `pop()` hộp thoại, `onAction` lại `Navigator.of(context).pop()` (đóng trang chính sách) rồi `onLeave()` gọi `context.pop()` lần nữa (đóng luôn màn trước, vd. khu "Thiết lập kho"). Test `leave_with_draft_asks_confirm` chỉ bấm "Ở lại" nên không bắt được | Bỏ dòng `Navigator.of(context).pop()` trong `onAction`. Thêm test `discard_pops_once` (Hub → khu → trang chính sách, sửa, quay lại, "Bỏ thay đổi" ⇒ đang ở khu "Thiết lập kho") |
| 2 | P1 | `test/features/inventory/logic/hub/warehouse_hub_test.dart:60` | `entries_copy_matches_contract` lỗi (`Expected: <5>, Actual: <6>`) sau khi thêm `WarehouseArea.setup`; Kết quả 5.1 ghi "81/81 PASS" chỉ tính test của plan | Sửa test theo 6 khu (kèm chữ khu "Thiết lập kho"); chạy lại **cả** `test/features/inventory` |
| 3 | P2 | `app_router.dart:640` | `...stockPolicyRoutes()` đặt trong nhánh `StatefulShellRoute` (cạnh `warehouseHubRoutes`) ⇒ iPhone hiện thanh 5 tab (thấy ở cả hai ảnh `flutter-*-390`). Plan Task 6 + PLAN "Điều hướng": route luồng BJ là con `ShellRoute(StoreShell)`, **ngoài** `StatefulShellRoute`, cạnh `/warehouse/receipts/...` | Dời sang cạnh `GoRoute('/warehouse/receipts/new')`; test `route_has_no_bottom_tabs_390` |
| 4 | P2 | `k7_edit_cell.dart:130-133` | Ô số có **ô trong ô** (viền bo tròn bên trong hộp — mọi ảnh Flutter): `InputDecoration(border: InputBorder.none)` không tắt `enabledBorder` / `focusedBorder` / `disabledBorder` của `inputDecorationTheme` | Dùng `InputDecoration.collapsed(hintText: null)` (hoặc đặt cả 3 border `InputBorder.none`); test `no_inner_border` (đếm `InputBorder` khác `none` = 0 hoặc golden ô đơn) |
| 5 | P2 | `stock_threshold_tab.dart:229-248`, `near_expiry_tab.dart:242-` | Chân nút nằm trong vùng cuộn ngay dưới bảng; prototype là chân **dính đáy** (`k4Footer` / `primaryFooter`, viền trên) — ảnh 062 web và 063 cả hai bề rộng lệch | Đưa `InventoryFooter` ra `Scaffold.bottomNavigationBar` của `StockPolicyPage` (chân theo tab đang chọn); 062 chỉ web, 063 cả hai |
| 6 | P2 | `stock_policy_cubit.dart:212`; `stock_policy_page.dart:200-206` | `saveSingle` tạo **khoá mới mỗi lần** ⇒ sheet iPhone / trang một sản phẩm: mất mạng sau khi server đã lưu rồi gửi lại ⇒ `VERSION_CONFLICT` thay vì replay (Review Focus 2). "Thử lại" trên banner trang gọi `saveThresholds()` — lỗi đến từ sheet thì nháp rỗng ⇒ bấm không làm gì | Giữ khoá theo nội dung như `saveThresholds` (`_lastSinglePayload` / `_lastSingleKey`); state ghi `lastFailedSave` (thresholds / single(productId, t, g) / nearExpiry) để "Thử lại" gửi lại đúng lệnh; test `single_retry_reuses_key`, `retry_after_sheet_error_resends_single` |
| 7 | P2 | `flutter-SCR-063-READY-*.png` | Ảnh 063 không có dòng chính sách riêng (plan Task 7 Step 2: mặc định 90, Tylosin 60) ⇒ không so được bảng / thẻ dòng riêng | Chụp lại theo fixture của plan; so và ghi lệch |
| 8 | P3 | `stock_threshold_tab.dart:207` | Dòng iPhone không phải thẻ (prototype `ds24ListRow` có viền, bo, khe 8 giữa dòng); badge trung tính "Chưa có ngưỡng tồn" không có nền xám | `VListRow(asCard: true)` + khe 8; kiểm `VBadge` tone `neutral` có nền `surface-subtle` |
| 9 | P3 | `near_expiry_tab.dart` | Tiêu đề khu "Mặc định cho mọi sản phẩm" / "Sản phẩm có chính sách riêng" to hơn prototype (`ac310SectionTitle` 13–15 / 600) | Dùng cỡ chữ tiêu đề khu như `VSection` ở Hub |
| 10 | P3 | `warehouse_entries.dart` | Chữ lệch plan Task 6 / `hub.js:56-58`: khu "Chính sách tồn, hạn dùng và quy tắc kho" (plan: "Các việc thiết lập ít dùng"), lối vào "Đặt ngưỡng cảnh báo, tồn mục tiêu và số ngày cận hạn" (plan: "Thiết lập ngưỡng tồn và chính sách cảnh báo"); icon `settings` / `tune` (plan: `inbox` / `shield`) | Theo plan, hoặc ghi "Lệch plan + lý do" |
| 11 | P3 | `save_*` (SQL) | Hai lần lưu **đầu tiên** đồng thời: cả hai không thấy dòng settings, lần sau `insert` lỗi khoá chính (23505) thay vì `VERSION_CONFLICT` | `insert … on conflict (tenant_id) do nothing;` rồi `select revision … for update` |
| 12 | P3 | Kết quả 5.1, `stock_policy_page.dart:110-115` | Kết quả ghi bảng `product_near_expiry_policies` (thực tế `stock_policy_settings`); toast lặp chữ ở `title` và `message`; sửa `v_modal.dart` (DS) không có test trong `packages/c45_design_system/test/` | Sửa Kết quả; toast chỉ `title`; thêm test `confirm_dialog_wraps_long_labels_390` |

**Đạt:** SQL đúng thiết kế 2.1–2.3 (khoá dòng settings, kiểm `revision` sau replay, xoá số ngày riêng ngoài danh sách, chặn sản phẩm không theo lô, không mã lỗi mới); luật `stockIndicators` / `thresholdRowError` khớp `bj01.js` / `cap01.js`; Cubit giữ nháp khi đổi tab, khoá idempotency theo nội dung cho bảng và cận hạn; nhân viên chỉ xem; chữ Screen Contract và chữ đề xuất đúng; bỏ "Hành động" / `LOCKED` / SCR-065 đúng Q-2a2, Q-2a4.

Làm lại: sửa #1–#7 (P1, P2), #8–#12 khi tiện; ghi Kết quả R1 → R2.

### R2 (2026-11-10) — ❌ chưa đạt (vẫn 2 P1, 4 P2)

Mục 5 Kết quả **chưa ghi** việc sửa sau R1 ⇒ review kiểm thẳng từng điểm trên code + ảnh (ảnh `flutter-*` chụp lại 12:15). `dart analyze` = 0 lỗi; `flutter test --no-pub test/features/inventory` = **225 đạt, 1 lỗi** (như R1).

| # R1 | Trạng thái | Bằng chứng |
|---|---|---|
| 1 P1 — "Bỏ thay đổi" đóng hai màn | ❌ chưa sửa | `stock_policy_page.dart:59-62` vẫn `Navigator.of(context).pop(); onLeave();`; chưa có test `discard_pops_once` |
| 2 P1 — test Hub lỗi | ❌ chưa sửa | `warehouse_hub_test.dart:59-60` vẫn `// 5 khu vực (đã bỏ setup)`, `expect(… .length, 5)` → `Actual: <6>` |
| 3 P2 — route trong `StatefulShellRoute` | ✅ | `app_router.dart:645` đặt `...stockPolicyRoutes()` cạnh `/warehouse/receipts/new`; ảnh 390 không còn thanh 5 tab. Còn thiếu test `route_has_no_bottom_tabs_390` |
| 4 P2 — ô trong ô | ❌ chưa sửa | `k7_edit_cell.dart:130-133` vẫn `InputDecoration(border: InputBorder.none, isCollapsed: true)`; ảnh 062 / 063 vẫn có viền bo tròn bên trong |
| 5 P2 — chân không dính đáy | ❌ chưa sửa | `InventoryFooter` vẫn trong vùng cuộn (`stock_threshold_tab.dart:232`, `near_expiry_tab.dart:244`); không có `bottomNavigationBar` |
| 6 P2 — `saveSingle` khoá mới mỗi lần, "Thử lại" sau lỗi sheet không làm gì | ❌ chưa sửa | `stock_policy_cubit.dart:212` `final key = _newKey();` |
| 7 P2 — ảnh 063 thiếu dòng riêng | ❌ chưa sửa | `flutter-SCR-063-READY-390.png` vẫn "Chưa có sản phẩm nào có chính sách riêng", không có Tylosin 60 |
| 8 P3 — dòng iPhone không phải thẻ | 🟡 một phần | dòng đã là thẻ; badge "Chưa có ngưỡng tồn" vẫn chiếm gần hết bề ngang làm tên sản phẩm gãy từng chữ (ảnh 390 dòng đầu — Ahem phóng đại nhưng bố cục `trailing` không giới hạn rộng). Thêm: tên `Expanded`, badge `Flexible` / tối đa ~45% bề ngang |
| 9–12 P3 | ❌ chưa sửa | tiêu đề khu 063 vẫn to; chữ / icon khu "Thiết lập kho" vẫn lệch plan; SQL chưa `on conflict (tenant_id) do nothing`; Kết quả vẫn ghi `product_near_expiry_policies`, toast vẫn lặp chữ, `v_modal.dart` chưa có test |

Làm lại: #1, #2, #4, #5, #6, #7 (bắt buộc), #8–#12 khi tiện. **Ghi Kết quả R2 → R3** (mỗi điểm: sửa ở đâu, test nào) trước khi gọi review.

### R3 (2026-11-10) — ✅ đạt (còn 2 P3 + nợ chạy test SQL)

Đã chạy: `flutter test --no-pub test/features/inventory` = **231/231 đạt**; `dart analyze lib/features/inventory test/features/inventory` = 0 lỗi; `packages/c45_design_system` `test/components/v_modal_test.dart` đạt. So 4 ảnh `flutter-*` (13:59) với `proto-*` trước khi đọc code.

| # R1 | Kết quả | Bằng chứng |
|---|---|---|
| 1 P1 | ✅ | `onAction: onLeave`, `_leave` pop một lần; test `discard_pops_once` |
| 2 P1 | ✅ | `warehouse_hub_test.dart` 6 khu; cả bộ inventory xanh |
| 3 P2 | ✅ | route ngoài `StatefulShellRoute`; `route_has_no_bottom_tabs_390`; ảnh 390 không thanh tab |
| 4 P2 | ✅ | `k7_edit_cell.dart:131-136` tắt đủ 6 border; ảnh không còn ô trong ô; `no_inner_border` |
| 5 P2 | ✅ | chân ở `Scaffold.bottomNavigationBar`, dính đáy (062 chỉ web, 063 cả hai) — khớp ảnh prototype |
| 6 P2 | ✅ | `_lastSinglePayload` / `_lastSingleKey`, `lastFailedSave` + `retryLastSave()` gắn nút "Thử lại"; `single_retry_reuses_key`, `retry_after_sheet_error_resends_single` |
| 7 P2 | ✅ | ảnh 063 có mặc định 90 + Tylosin 60 (bảng web, thẻ iPhone) |
| 8–12 P3 | ✅ | thẻ iPhone + badge giới hạn 150; tiêu đề khu 15/600; chữ / icon khu "Thiết lập kho" theo plan; SQL `insert … on conflict (tenant_id) do nothing` rồi `select … for update` (đủ `updated_by`); Kết quả sửa tên bảng; toast không lặp; test `VConfirmDialog` |

**Còn lại (không chặn, sửa khi tiện hoặc ở G5-2):**

| # | Mức | Chỗ | Nội dung |
|---|---|---|---|
| 13 | P3 | `stock_policy_cubit.dart` (`saveThresholds`, `saveSingle`, `saveNearExpiry`) | Khoá idempotency **không xoá sau khi lưu thành công** và payload không gồm `revision`. Nếu máy khác vừa đổi chính sách và người dùng lưu lại **đúng** nội dung lần trước (chưa "Tải lại"), app gửi khoá cũ với hash mới ⇒ server `IDEMPOTENCY_CONFLICT` ⇒ banner lỗi chung, "Thử lại" lặp mãi, thay vì "Chính sách vừa được cập nhật". Sửa: đặt `_last…Key = null` khi lưu xong (3 chỗ); test `key_resets_after_success` |
| 14 | P3 | `StockIndicatorBadge` / `VBadge` tone `neutral` (ảnh 062 web, dòng đầu) | Badge "Chưa có ngưỡng tồn" trên bảng web không có nền xám như prototype (iPhone có). Chấm `danger` vẫn đặc — G5-2 Task 4 thêm `hollowDot` và dời `StockIndicatorBadge` sang `presentation/stock/`, sửa luôn nền trung tính ở đó |

Nợ: người dùng chạy `supabase/tests/inventory_stock_policy.sql` (10 ca) trên DB Dev.
