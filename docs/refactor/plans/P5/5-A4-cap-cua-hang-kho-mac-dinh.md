# 5-A4 — Cặp cửa hàng–kho mặc định: promote migration nháp + `DefaultPairRepository`

> Theme 2 (mã cũ P5) · Bước (a) chuyển kiến trúc · Gồm việc 5.5 (PLAN.md mục Theme 2)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-01, kèm các đề xuất "duyệt plan là chốt"; rà lại theo code 2026-11-04: `Kind: patch`, cubit → `logic/`, 9 tệp test, viết lại `default_pair_gate_test`, số migration, reset local giao người dùng; mục 6 viết lại theo `superpowers:writing-plans`: Task 0–4 + Review Focus; người dùng duyệt lại 2026-11-04) | Làm ✅ (2026-11-04, chưa commit) | Review 🔄 R1 (2026-11-04) chưa đạt, code đạt; đã sửa R1-1…R1-3, R1-4 lúc commit
> Độc lập với 5-A1…5-A3 (khác feature, khác module). Làm sau 5-A3 cho gọn thứ tự; làm trước cũng được.
> Tài liệu: PLAN.md mục Theme 2 dòng 5.5, "Quy tắc migration"; [TH-07](../../../02-yeu-cau/TH-07-kho.md); `specs/themes/theme-07/01.knowledge/know-how/KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md` (một cửa hàng – một kho mặc định); `supabase/migrations/_drafts/README.md`.

## 1. Mục tiêu

- Đưa `supabase/migrations/_drafts/inventory_default_pair.sql` thành migration thật. Hiện hai RPC `inventory.get_default_store_warehouse_pair` / `ensure_default_store_warehouse_pair` **chỉ có ở bản nháp**, không nằm trong chuỗi migration ⇒ DB dựng từ migration (vd. sau `db reset`) không có schema `inventory`, cổng ở `StoreShell` lỗi và **chặn cả app** ở `DefaultPairGateErrorView`.
- Chuyển `DefaultPairGateCubit` từ `IInventoryModule` sang `DefaultPairRepository` (`features/dashboard/data/`; **không** dùng tên `InventoryRepository`: tên đó là của Theme 7).
- Sau 5-A4: `apps/erp/lib` không còn import `c45_inventory_*`; DI bỏ `InventoryStartup` / `IInventoryModule`. Thư mục `modules/inventory` để 5-C xoá.

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | Promote bản nháp ở đâu | **Người dùng chốt 2026-11-01: trong 5-A4.** Theme 7 backend xây tiếp trên schema này (cặp mặc định là khái niệm của Theme 7, KB-KGV-003) |
| Q2 | Kiểm quyền client `InventoryPermissions.defaultPairRead` của handler `get` | **Bỏ** (như Theme 3 Q3). Server `Permission denied: inventory.default_pair.read` → `NO_PERMISSION` |
| Q3 | Bản nháp có gắn vào lúc tạo tổ chức không | **Không** (đo 2026-11-01: không đụng `iam._create_tenant_for_owner`). Cặp được tạo **lười** khi `StoreShell` gọi `ensure` lần đầu. Giữ như vậy; TH-01 BR-06 ghi "tạo cặp cùng tổ chức" là lệch tài liệu, phiên review sửa TH-01 sau khi xong (mục 3 bảng Thay đổi) |

## 3. Thay đổi

| Tệp | Hành động |
|---|---|
| `supabase/migrations/<số>_inventory_default_pair.sql` | **tạo** (đối tượng mới ⇒ migration mới). `<số>` = số kế tiếp **lớn hơn mọi tệp** trong `supabase/migrations/` lúc làm (đo lại 2026-11-04: lớn nhất `20261101001_partner_sales_order_history_trigger.sql` ⇒ dự kiến `20261104001`). Nội dung = toàn bộ bản nháp, **không sửa thân**, thêm header theo `_migration.template.sql` (mẫu đã promote: `20261031001_einvoice_configuration_schema.sql`): `-- Title: inventory default store/warehouse pair`, `-- Kind: patch` (**không** `feature`: `tools/c45_supabase_migrate/lib/migration_header.dart:3` chỉ nhận `bootstrap, patch, surgical, generated`; `patch` ⇒ policy kiểm Touches khớp thân, ≤ 8 hàm, REGISTRY trỏ đúng tệp), `-- Intent: inventory_default_pair`, `-- Context: TH-07 / KB-KGV-003; PLAN 5-A4`, `-- Touches: ensure_default_store_warehouse_pair, get_default_store_warehouse_pair`, `-- Safety: one-shot ; low`, `-- Depends on: 20260830001_iam_active_store_context_group_a (iam.stores unique (tenant_id, id)), 20260916001_iam_ensure_default_store_scope_helpers (iam._ensure_tenant_default_store), 20260811024_iam_patch_owner_role_canonicalization (iam.has_permission)`, `-- Promoted from _drafts/inventory_default_pair.sql`. Bỏ 2 dòng chú thích đầu của nháp ("Draft: …", "Not a timestamped migration…") |
| `supabase/migrations/REGISTRY.yaml` | thêm mục `inventory:` (theo thứ tự chữ cái: sau `iam:`, trước `partner:`) với 2 dòng `ensure_default_store_warehouse_pair: <tệp>`, `get_default_store_warehouse_pair: <tệp>`. REGISTRY chỉ ghi hàm (xem mục `partner:`), không ghi bảng |
| `supabase/migrations/_drafts/inventory_default_pair.sql` | **xoá** |
| `supabase/migrations/_drafts/README.md` | dòng "Còn lại trong `_drafts/`: `inventory_default_pair.sql` (chưa promote)." → "`inventory_default_pair.sql` đã promote ở 5-A4 (`<tệp>`). `_drafts/` trống." |
| `apps/erp/lib/features/dashboard/data/default_pair_repository.dart` | **tạo** (mục 4.1). Thư mục `features/dashboard/data/` chưa có |
| `apps/erp/lib/features/dashboard/data/models/default_store_warehouse_pair.dart` | **tạo**: model (mục 4.1), theo cách đặt của `features/partner/data/models/` |
| `apps/erp/lib/features/dashboard/presentation/bloc/default_pair_gate_cubit.dart` → `apps/erp/lib/features/dashboard/logic/default_pair_gate_cubit.dart` | `git mv` rồi sửa (mục 4.2). Chuyển sang `logic/` theo PLAN.md "Đổi Cubit" bước 6 (như 4-A, 5-A3). State ở cùng tệp, giữ nguyên. Thư mục `presentation/bloc/` trống ⇒ xoá |
| `apps/erp/lib/features/dashboard/presentation/store_shell.dart` | import cubit theo đường mới; tham số `IInventoryModule? inventoryModule` (dòng 37, 44 truyền xuống, 106, 118–119) → `DefaultPairRepository? defaultPairRepository`; `inventoryModule ?? getIt<IInventoryModule>()` → `defaultPairRepository ?? getIt<DefaultPairRepository>()`; bỏ import `c45_inventory_application` (dòng 4) |
| `apps/erp/lib/core/di/injection.dart` | thêm `registerLazySingleton<DefaultPairRepository>` (cạnh các repository khác, cùng kiểu `rpc: getIt<SupabaseRpc>(), tenantId: () => getIt<SessionController>().requireTenantId()`); xoá `InventoryStartup.initialize(...)` + `registerSingleton<IInventoryModule>` (đo 2026-11-04: dòng 231–238) và 2 import `c45_inventory_*` (dòng 3–4) |
| `apps/erp/test/features/dashboard/presentation/ready_default_pair_inventory_module.dart` | thay bằng `fake_default_pair_repository.dart` (mục 4.3) |
| 9 tệp test đang dùng `IInventoryModule` / `ReadyDefaultPairInventoryModule` (mục 6.3) | đổi cách dựng |
| `docs/02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md` BR-06, FR-03 dòng 410, dòng 60, 102, 1280 | phiên review sửa sau khi xong: cặp cửa hàng–kho tạo lười khi vào app lần đầu (Q3) |

**Không** đổi: `apps/erp/pubspec.yaml` (dòng `c45_inventory_*` để 5-C bỏ cùng `modules/inventory`); `DefaultPairGateErrorView`; `supabase/config.toml` (đã có `inventory` trong `schemas` và `extra_search_path`).

## 4. Thiết kế

### 4.1 `DefaultPairRepository`

```dart
class DefaultPairRepository {
  DefaultPairRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
    String? correlationId,
  }) : _correlationId = correlationId ?? const Uuid().v4();

  /// `inventory.get_default_store_warehouse_pair(p_tenant_id)` → jsonb.
  Future<DefaultStoreWarehousePair> get();

  /// `inventory.ensure_default_store_warehouse_pair(p_tenant_id, p_correlation_id)` → jsonb.
  Future<DefaultStoreWarehousePair> ensure();
}

final class DefaultStoreWarehousePair {
  const DefaultStoreWarehousePair({required this.storeId, required this.storeName,
      required this.warehouseId, required this.warehouseName, this.replayed = false});
  // fromJson: khoá camelCase 'storeId', 'storeName', 'warehouseId', 'warehouseName', 'replayed' (chỉ ensure có)
}
```

- Gọi bằng `_rpc.call('inventory', …)`, ép `Map<String, dynamic>`. Khoá và cách đọc chép từ `modules/inventory/infrastructure/lib/src/default_pair/default_store_warehouse_pair_gateway.dart` (`row['storeId'] as String` …; `replayed as bool` ở `ensure`).
- `correlationId`: bản cũ dùng `CoreExecutionContext.correlationId`, sinh **một lần** cho cả phiên DI. Repository là lazy singleton nên `Uuid().v4()` lúc tạo cho cùng vòng đời.
- Lỗi: `SupabaseRpc` đã đổi sang `AppException`. Thân SQL báo `DEFAULT_PAIR_MISSING`, `CONTEXT_INVALID`, `DEFAULT_PAIR_LIMIT`, `DEFAULT_STORE_MISSING` (mã viết hoa ⇒ `code` đúng chuỗi), `RESOURCE_NOT_FOUND` (⇒ `NOT_FOUND`), `Permission denied: …` (⇒ `NO_PERMISSION`). Không cần bộ phân loại riêng.
- Không có `matches(...)` (app không dùng).

### 4.2 `DefaultPairGateCubit`

```dart
DefaultPairGateCubit({required DefaultPairRepository repository})

Future<void> load() async {
  emit(const DefaultPairGateState.loading());
  try {
    await _repository.get();
    if (isClosed) return;
    emit(const DefaultPairGateState.ready());
  } on AppException catch (e) {
    if (e.code != 'DEFAULT_PAIR_MISSING') { _emitError(e.code); return; }
    await _ensure();
  } catch (error) {
    _emitError('$error');
  }
}
```

`_ensure` tương tự (`on AppException catch (e) → _emitError(e.code)`). State giữ nguyên. `failureMessage` **không** chỗ nào hiện (grep 2026-11-01: chỉ state dùng) ⇒ đổi từ message thô sang mã không ảnh hưởng giao diện.

### 4.3 Fake

`apps/erp/test/features/dashboard/presentation/fake_default_pair_repository.dart`:

```dart
enum FakeDefaultPairMode { ready, missingThenEnsure, getError, ensureError }

class FakeDefaultPairRepository extends DefaultPairRepository {
  FakeDefaultPairRepository({this.mode = FakeDefaultPairMode.ready, this.pause})
    : super(rpc: _unusedRpc, tenantId: () async => 'tenant-test');
  final FakeDefaultPairMode mode;
  final Future<void> Function()? pause; // gọi đầu get/ensure, thay _PausingInventoryModule
  int getCalls = 0;
  int ensureCalls = 0;
}
```

- `_unusedRpc` theo mẫu `test/features/partner/support/fake_partner_repository.dart:18` (`SupabaseRpc(_UnusedClient())`).
- `ready`: `get` trả cặp `store-ready` / `Default Store` / `wh-ready` / `Kho mặc định` (chép từ `ReadyDefaultPairInventoryModule`). `missingThenEnsure`: `get` ném `AppException('DEFAULT_PAIR_MISSING')`, `ensure` trả cặp (`replayed: false`). `getError`: `get` ném `AppException(AppErrorCode.noPermission)`. `ensureError`: `get` ném `DEFAULT_PAIR_MISSING`, `ensure` ném `AppException('DEFAULT_PAIR_LIMIT')`.
- Xoá `ready_default_pair_inventory_module.dart`.
- `default_pair_gate_test.dart` hiện dựng `EnsureDefaultStoreWarehousePairCommandHandler` / `GetDefaultStoreWarehousePairQueryHandler` + `FakeDefaultStoreWarehousePairPort` (đều từ `c45_inventory_application`, `modules/inventory/application/lib/src/default_pair/testing/`) ⇒ viết lại bằng fake trên: `scn_dashboard_gate_success` = `missingThenEnsure` + `pause` (Completer, giữ kiểm `VLoading` trước khi mở); `expect(port.warehouses/assignments, hasLength(1))` → `getCalls == 1`, `ensureCalls == 1`. `scn_dashboard_gate_error` = `ensureError` (cũ: 2 kho active ⇒ `DEFAULT_PAIR_LIMIT`); `inner.ensureCount` → `ensureCalls` (1 rồi 2 sau "Thử lại"). Giữ mọi `expect` giao diện.

## 5. Đang làm gì — test giữ hành vi

| # | Cũ đang làm gì | Sau khi sửa | Test |
|---|---|---|---|
| D1 | `load`: `get` thành công → `ready`, **không** gọi `ensure` | giữ | Task 0 thêm cubit test `default_pair_gate_cubit_test.dart`: module trả cặp ở query → `[loading, ready]`, command 0 lần. (Gián tiếp: mọi test dùng `ReadyDefaultPairInventoryModule`.) |
| D2 | `get` lỗi `DEFAULT_PAIR_MISSING` → gọi `ensure`; `ensure` thành công → `ready` | giữ | `scn_dashboard_gate_success` (có sẵn: port rỗng ⇒ đi đường missing → ensure, **không** phải đường D1) + Task 0 cubit test: fake module ném `ApplicationException('DEFAULT_PAIR_MISSING')` ở query, command thành công → `[loading, ready]`, command gọi 1 lần |
| D3 | `get` lỗi khác → `error` (không gọi `ensure`); `ensure` lỗi → `error`; lỗi không phải `ApplicationException` → `error` | giữ (`failureMessage` = mã) | Task 0: 3 ca; sau sửa kiểm `status`, **không** kiểm chuỗi `failureMessage` |
| D4 | Handler `get` kiểm quyền client `InventoryPermissions.defaultPairRead` | **Đổi (Q2):** bỏ | repository test: `get` gọi đúng 1 RPC `get_default_store_warehouse_pair` với `{p_tenant_id}` |
| D5 | Handler `ensure` gửi `p_correlation_id` = `correlationId` của context (cố định trong phiên) | repository giữ một `correlationId` suốt vòng đời | repository test: gọi `ensure` 2 lần → cùng `p_correlation_id`, là UUID |
| D6 | `StoreShell`: phiên không hợp lệ → không dựng cổng; đổi tổ chức (`ValueKey(tenantId)`) → cubit mới, tải lại; `status != ready` → màn chờ / lỗi; "Thử lại" gọi `load()` | giữ, chỉ đổi kiểu tham số | `store_shell_test.dart` (có sẵn: phiên chặn / đang tải) + `scn_dashboard_gate_error` (có sẵn: lỗi → "Thử lại" → `ensure` lần 2 → "Chọn tổ chức khác"). Task 0 thêm: đổi `tenantId` của phiên → cubit mới, `get` gọi lại (chưa test nào phủ `ValueKey`) |
| D7 | DB dựng từ migration **không** có RPC ⇒ cổng lỗi | **Đổi (Q1):** có RPC | SQL `supabase/tests/inventory_default_pair.sql` (mục 6, Task 1) |

**Task 0 (mục 6):** D1, D2, D3 (cubit test mới `apps/erp/test/features/dashboard/logic/default_pair_gate_cubit_test.dart`, fake `IInventoryModule` ném / trả theo ca) và D6 phần đổi tổ chức, trên code cũ. Chạy xanh, ghi tên test. Task 3 đổi các test này sang `FakeDefaultPairRepository` (`getCalls` / `ensureCalls` thay đếm command).

## 6. Các bước

> Viết theo `superpowers:writing-plans`. Thực hiện: `superpowers:executing-plans` (làm tuần tự trong phiên). Mỗi task xong ghi ngay mục 9. **Không commit** (người dùng commit sau `detect_changes()`).
> Trước mỗi symbol Dart sửa: `gitnexus impact` (upstream). `StoreShell` nằm trên mọi màn sau đăng nhập ⇒ có thể HIGH: ghi blast radius vào Kết quả, làm tiếp vì có D1–D6.

**Ràng buộc chung** (mọi task):
- Không đổi thân SQL của bản nháp (trừ khi `db reset` lỗi, mục 8). Không sửa migration IAM.
- Không đổi `apps/erp/pubspec.yaml`, `DefaultPairGateErrorView`, `DefaultPairGateState`.
- Không dùng tên `InventoryRepository` (của Theme 7, `features/inventory/data/inventory_repository.dart`).
- Kiểm `status`, **không** kiểm chuỗi `failureMessage`.

### Task 0: Test giữ hành vi trên code cũ (D1, D2, D3, D6)

**Files:**
- Create: `apps/erp/test/features/dashboard/logic/default_pair_gate_cubit_test.dart`
- Modify: `apps/erp/test/features/dashboard/presentation/default_pair_gate_test.dart` (thêm 1 testWidgets)

- [x] **0.1** Viết cubit test, dùng fake `IInventoryModule` cục bộ `_ScriptedModule({Object? queryError, Object? commandError})` đếm `queryCalls` / `commandCalls`, trả `DefaultStoreWarehousePairDto` / `EnsureDefaultStoreWarehousePairResultDto` như `ReadyDefaultPairInventoryModule`. Dùng `expectLater(cubit.stream.map((s) => s.status), emitsInOrder([...]))`:
  - `d1_get_ok_ready_without_ensure`: không lỗi → `[loading, ready]`, `commandCalls == 0`.
  - `d2_missing_then_ensure_ready`: `queryError: ApplicationException('DEFAULT_PAIR_MISSING')` → `[loading, ready]`, `commandCalls == 1`.
  - `d3_get_other_error_no_ensure`: `queryError: ApplicationException('Permission denied')` → `[loading, error]`, `commandCalls == 0`.
  - `d3_ensure_error`: query missing, `commandError: ApplicationException('DEFAULT_PAIR_LIMIT')` → `[loading, error]`.
  - `d3_non_app_error`: `queryError: StateError('x')` → `[loading, error]`, `commandCalls == 0`.
- [x] **0.2** Thêm `scn_dashboard_gate_reload_on_tenant_change` vào `default_pair_gate_test.dart`: `_app(module)` với `module = _CountingModule()` (bọc `ReadyDefaultPairInventoryModule`, đếm `queryCalls`), `FakeSessionRepository(scenario: FakeIamScenario.tenantsMulti)`, chờ trang chủ (`queryCalls == 1`); gọi `tester.element(find.byType(HomeTabPage)).read<SessionController>().switchTo('org-002')` (mẫu `wgt_e05_tenant_context_test.dart:173`), `pumpAndSettle` → `queryCalls` tăng thêm 1, `find.text('Tổng quan hôm nay')` hiện lại. Nếu `switchTo` trả `false` với fake này thì ghi ⏭ + lý do vào Kết quả, không tự nghĩ cách khác.
- [x] **0.3** Chạy: `cd apps/erp && flutter test test/features/dashboard/` → PASS hết (code chưa đổi). Ghi tên test vào Kết quả.

### Task 1: Migration cặp mặc định + test SQL

**Files:**
- Create: `supabase/migrations/20261104001_inventory_default_pair.sql` (số đo lại lúc làm, mục 3)
- Create: `supabase/tests/inventory_default_pair.sql`
- Modify: `supabase/migrations/REGISTRY.yaml` (thêm mục `inventory:` giữa `iam:` và `partner:`)
- Modify: `supabase/migrations/_drafts/README.md` (dòng "Còn lại trong `_drafts/` …")
- Delete: `supabase/migrations/_drafts/inventory_default_pair.sql`

**Produces:** RPC `inventory.get_default_store_warehouse_pair(p_tenant_id uuid) → jsonb {storeId, storeName, warehouseId, warehouseName}`, `inventory.ensure_default_store_warehouse_pair(p_tenant_id uuid, p_correlation_id uuid) → jsonb {…, replayed bool}`.

- [x] **1.1** `git mv` nháp sang tên migration; thay 2 dòng đầu bằng header mục 3 (`Kind: patch`).
- [x] **1.2** REGISTRY:
  ```yaml
  inventory:
    ensure_default_store_warehouse_pair: 20261104001_inventory_default_pair.sql
    get_default_store_warehouse_pair: 20261104001_inventory_default_pair.sql
  ```
  Sửa README nháp theo mục 3.
- [x] **1.3** Chạy `dart run tools/c45_supabase_migrate/bin/verify_migration_policy.dart` → không có vi phạm của tệp mới (`header_kind`, `header_intent`, Touches, registry). Vi phạm có sẵn ở tệp khác: so với lúc trước khi sửa, ghi vào Kết quả.
- [x] **1.4** Viết `supabase/tests/inventory_default_pair.sql` (5 ca ở mục 5 D7, mẫu `supabase/tests/iam_legacy_cleanup.sql`, `begin … rollback`):
  1. `get` khi chưa có cặp → bắt lỗi, `sqlerrm = 'DEFAULT_PAIR_MISSING'`;
  2. `ensure` → `storeId` = id cửa hàng `code = 'default'` của tổ chức, `replayed = false`;
  3. `ensure` lần hai → cùng `warehouseId`, `replayed = true`;
  4. `get` → cùng `storeId` / `warehouseId`;
  5. claims của user không là thành viên → `get` lỗi `sqlerrm = 'Permission denied: inventory.default_pair.read'` (`iam.has_permission` bản `20260811024`: không là thành viên → false; không cần seed quyền).
  Ca sai → `raise exception`; hết → `raise notice 'inventory_default_pair: OK'`.
- [x] **1.5** ⏭ phiên code: `supabase db reset --local` + `psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/inventory_default_pair.sql` (mong `inventory_default_pair: OK`) + `supabase/tests/iam_*.sql`. Reset DB là việc người dùng (4-C bị auto mode chặn). Ghi lệnh vào Kết quả.

### Task 2: `DefaultPairRepository` + model

**Files:**
- Create: `apps/erp/lib/features/dashboard/data/models/default_store_warehouse_pair.dart`
- Create: `apps/erp/lib/features/dashboard/data/default_pair_repository.dart`
- Test: `apps/erp/test/features/dashboard/data/default_pair_repository_test.dart`

**Consumes:** `SupabaseRpc.call(String schema, String fn, {Map<String, dynamic>? params})` (`core/supabase/supabase_rpc.dart`), `AppException` (`core/errors/app_exception.dart`).
**Produces:**
- `final class DefaultStoreWarehousePair({required String storeId, required String storeName, required String warehouseId, required String warehouseName, bool replayed = false})` + `factory DefaultStoreWarehousePair.fromJson(Map<String, dynamic> json)`.
- `class DefaultPairRepository({required SupabaseRpc rpc, required Future<String> Function() tenantId, String? correlationId})` với `Future<DefaultStoreWarehousePair> get()`, `Future<DefaultStoreWarehousePair> ensure()`.

- [x] **2.1** Viết test (RPC giả `_Rpc extends SupabaseRpc` ghi `calls` + trả `next`, mẫu `test/core/session/session_repository_test.dart:9`):
  - `get_calls_one_rpc_with_tenant` (D4): `next = {'storeId':'s1','storeName':'CH','warehouseId':'w1','warehouseName':'Kho mặc định'}` → 1 call, `schema == 'inventory'`, `fn == 'get_default_store_warehouse_pair'`, `params == {'p_tenant_id': 't1'}`; kết quả `storeId == 's1'`, `warehouseName == 'Kho mặc định'`, `replayed == false`.
  - `ensure_reads_replayed`: `next` có `'replayed': true` → `fn == 'ensure_default_store_warehouse_pair'`, `params['p_tenant_id'] == 't1'`, `replayed == true`.
  - `ensure_keeps_one_correlation_id` (D5): gọi `ensure` 2 lần → 2 `p_correlation_id` bằng nhau và khớp `RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4')`.
  - `get_propagates_app_exception`: `_Rpc` ném `AppException('DEFAULT_PAIR_MISSING')` → `throwsA(isA<AppException>().having((e) => e.code, 'code', 'DEFAULT_PAIR_MISSING'))`.
- [x] **2.2** Chạy `cd apps/erp && flutter test test/features/dashboard/data/default_pair_repository_test.dart` → FAIL (chưa có lớp).
- [x] **2.3** Viết model + repository (mục 4.1). `correlationId ?? const Uuid().v4()` gán một lần ở constructor.
- [x] **2.4** Chạy lại lệnh 2.2 → PASS.

### Task 3: Cubit → `logic/`, `StoreShell`, DI, fake, 9 tệp test

**Files:**
- Move + Modify: `apps/erp/lib/features/dashboard/presentation/bloc/default_pair_gate_cubit.dart` → `apps/erp/lib/features/dashboard/logic/default_pair_gate_cubit.dart`
- Modify: `apps/erp/lib/features/dashboard/presentation/store_shell.dart:4,37,44,106,118-119`
- Modify: `apps/erp/lib/core/di/injection.dart:3-4,231-238`
- Create: `apps/erp/test/features/dashboard/presentation/fake_default_pair_repository.dart` (mục 4.3)
- Delete: `apps/erp/test/features/dashboard/presentation/ready_default_pair_inventory_module.dart`
- Modify: 9 tệp mục 6.3; Move: `test/features/dashboard/logic/default_pair_gate_cubit_test.dart` đổi sang fake mới

**Consumes:** `DefaultPairRepository` (Task 2).
**Produces:** `DefaultPairGateCubit({required DefaultPairRepository repository})`; `StoreShell({…, DefaultPairRepository? defaultPairRepository})`; `FakeDefaultPairRepository({FakeDefaultPairMode mode = FakeDefaultPairMode.ready, Future<void> Function()? pause})` với `int getCalls`, `int ensureCalls`.

- [x] **3.1** `gitnexus impact` upstream `DefaultPairGateCubit`, `StoreShell`, `initDependencies` → ghi bảng vào Kết quả.
- [x] **3.2** Tạo fake (mục 4.3). Đổi cubit test Task 0 sang fake: `_ScriptedModule` → mode `ready` / `missingThenEnsure` / `getError` / `ensureError`; `commandCalls` → `ensureCalls`. Ca `d3_non_app_error`: mode `ready` + `pause: () async => throw StateError('x')` (lỗi không phải `AppException` ở `get`; không thêm mode). Cùng tên test, cùng kỳ vọng `status`.
- [x] **3.3** Chạy `cd apps/erp && flutter test test/features/dashboard/logic/` → FAIL (constructor cubit chưa đổi).
- [x] **3.4** `git mv` cubit sang `logic/`; sửa theo mục 4.2 (`on AppException catch (e)`, dùng `e.code`). Xoá thư mục `presentation/bloc/` nếu trống.
- [x] **3.5** `StoreShell`: đổi tham số + import (mục 3). `injection.dart`: thêm `registerLazySingleton<DefaultPairRepository>(() => DefaultPairRepository(rpc: getIt<SupabaseRpc>(), tenantId: () => getIt<SessionController>().requireTenantId()))`; xoá `InventoryStartup` + `IInventoryModule` + 2 import.
- [x] **3.6** Đổi 9 tệp mục 6.3:
  - `injection_test.dart:59`: `expect(getIt.isRegistered<IInventoryModule>(), isTrue)` → `expect(getIt.isRegistered<DefaultPairRepository>(), isTrue)`; bỏ import `c45_inventory_application`.
  - `default_pair_gate_test.dart`: theo mục 4.3 (bỏ `_HandlerInventoryModule`, `_PausingInventoryModule`, `FakeDefaultStoreWarehousePairPort`; `inventoryModule:` → `defaultPairRepository:`). Ca 0.2 cũng đổi sang fake.
  - 7 tệp còn lại: `registerSingleton<IInventoryModule>(const ReadyDefaultPairInventoryModule())` → `registerSingleton<DefaultPairRepository>(FakeDefaultPairRepository())` + import; bỏ import `c45_inventory_application`.
- [x] **3.7** Chạy `cd apps/erp && flutter test test/features/dashboard/ test/core/di/injection_test.dart` → PASS (gồm mọi test Task 0, `scn_dashboard_gate_success`, `scn_dashboard_gate_error`).

### Task 4: Kiểm toàn bộ + Kết quả

- [x] **4.1** Chạy từng dòng mục 7 (grep, `ls`, `verify_migration_policy`, `dart analyze lib test`, `flutter test`). Ghi lệnh + số pass / fail; fail đối chiếu `TEST-BASELINE.md`.
- [x] **4.2** `node .gitnexus/run.cjs analyze` rồi `detect_changes()` → ghi số tệp / symbol / luồng / rủi ro.
- [x] **4.3** Ghi vào Kết quả: "Người dùng: (1) `supabase db reset --local` + chạy `supabase/tests/inventory_default_pair.sql`, `iam_*.sql`; (2) `supabase db push` lên Dev (migration mới, không cần reset); (3) kiểm tay mục 7; (4) commit."

### 6.3 Test đang dùng `IInventoryModule`

`test/core/di/injection_test.dart` (đổi kỳ vọng: `DefaultPairRepository` đăng ký, `IInventoryModule` **không** đăng ký), `features/auth/e2e_th01_s0_session_test.dart`, `features/dashboard/presentation/default_pair_gate_test.dart`, `store_shell_test.dart`, `features/iam/presentation_module/w2_behavior_preservation_test.dart`, `w2_wide_layout_test.dart`, `features/tenant_context/presentation/e2e_e05_u01_fr01_01_tenant_context_test.dart`, `wgt_e05_tenant_context_test.dart`, `features/partner/support/partner_router_harness.dart` (dòng 51, thêm ở 4-A; đo 2026-11-04). Ngoài `injection_test` và `default_pair_gate_test`, các tệp chỉ đổi `registerSingleton<IInventoryModule>(const ReadyDefaultPairInventoryModule())` → `registerSingleton<DefaultPairRepository>(FakeDefaultPairRepository())` + import.

## 7. Kiểm tra

- [x] `git grep -n "package:c45_inventory" -- apps/erp/lib apps/erp/test` → rỗng.
- [x] `git grep -n "IInventoryModule\|InventoryStartup\|ReadyDefaultPairInventoryModule" -- apps/erp` → rỗng.
- [x] `ls supabase/migrations/_drafts/*.sql` → không còn tệp nào.
- [x] `ls apps/erp/lib/features/dashboard/presentation/bloc` → không còn (cubit ở `logic/`).
- [ ] (Người dùng) `supabase db reset --local` chạy qua; `inventory_default_pair.sql` ra `inventory_default_pair: OK`; các `supabase/tests/iam_*.sql` vẫn chạy qua.
- [x] `verify_migration_policy.dart`: không lỗi mới.
- [x] `cd apps/erp && dart analyze lib test`: không lỗi / cảnh báo mới. `flutter test`: không fail mới.
- [ ] Dev: migration **mới** (không sửa tệp đã áp) ⇒ Dev nhận khi người dùng chạy `supabase db push` hoặc reset. Phiên code **không** chạy; ghi "cần push / reset Dev" vào Kết quả.
- [ ] Kiểm tay (người dùng, sau khi Dev có migration): đăng nhập → vào thẳng trang chủ, không thấy màn lỗi cổng; đổi tổ chức → vẫn vào được.

## 8. Rủi ro / lưu ý

- Bản nháp viết trước nhiều thay đổi IAM. Nếu `db reset` local lỗi (cột / ràng buộc `iam.stores`, `iam.tenants` đã đổi tên) thì sửa **trong tệp migration mới** cho khớp schema hiện tại, ghi từng chỗ sửa + lý do vào Kết quả. Không sửa migration IAM.
- `idempotency_records` có trong bản nháp nhưng hai RPC có dùng không: không đổi, giữ nguyên (Theme 7 cần).
- Theme 7 backend sẽ thêm bảng / RPC vào schema `inventory`: theo quy tắc migration, sửa **tại chỗ** tệp này nếu đổi bảng của nó (trước khi Prod chạy thật).

### Review Focus (chưa task nào test, phiên review soi)

- Đổi tổ chức khi `load()` của tổ chức cũ đang chờ: cubit cũ bị đóng, các `if (isClosed) return` phải giữ ở **cả** `load`, `_ensure`, `_emitError` (code cũ có sẵn), không emit sau `close`.
- RPC trả `null` / không phải object (DB lệch): cast `Map<String, dynamic>` ném `TypeError` → cubit nhánh `catch (error)` → `error`, không treo màn chờ.
- `correlationId` dùng chung khi đổi tổ chức trong cùng phiên: như cũ (`CoreExecutionContext` một lần cho DI), không đổi.
- `ensure` khi tổ chức có cửa hàng active nhưng không có `code = 'default'` → `DEFAULT_STORE_MISSING` → màn lỗi cổng (không có ca SQL; đọc thân hàm đối chiếu).

## 9. Kết quả (phiên làm code ghi)

- **Task 0**: ✅ Đã viết `apps/erp/test/features/dashboard/logic/default_pair_gate_cubit_test.dart` (5 tests `d1_get_ok_ready_without_ensure`, `d2_missing_then_ensure_ready`, `d3_get_other_error_no_ensure`, `d3_ensure_error`, `d3_non_app_error`) và thêm `scn_dashboard_gate_reload_on_tenant_change` vào `apps/erp/test/features/dashboard/presentation/default_pair_gate_test.dart` (`switchTo('org-002')` thành công, `queryCalls` tăng từ 1 lên 2). Chạy `cd apps/erp && flutter test test/features/dashboard/` pass 17/17.
- **Task 1**: ✅
  - `git mv supabase/migrations/_drafts/inventory_default_pair.sql supabase/migrations/20261104001_inventory_default_pair.sql` với header `Kind: patch`, `Intent: inventory_default_pair`, `Touches: ensure_default_store_warehouse_pair, get_default_store_warehouse_pair`.
  - Cập nhật `supabase/migrations/REGISTRY.yaml` thêm mục `inventory:` trước `partner:`.
  - Sửa `supabase/migrations/_drafts/README.md` (`_drafts/` nay trống).
  - Viết `supabase/tests/inventory_default_pair.sql` với 5 ca kiểm SQL (get missing, ensure lần 1, ensure replay lần 2, get sau ensure, stranger không có quyền).
  - Chạy `dart run tools/c45_supabase_migrate/bin/verify_migration_policy.dart`: 0 errors, 3 warnings: 1 cảnh báo có sẵn của `20261101001` (partner) + 2 cảnh báo `registry_consistency` **của tệp mới** `20261104001` (`catalog.ensure_default_store_warehouse_pair` / `catalog.get_default_store_warehouse_pair` not found) — do `_inferSchema` (`tools/c45_supabase_migrate/lib/migration_policy.dart:529-542`) không biết schema `inventory`, tra nhầm `catalog.*`; REGISTRY mục `inventory:` thật đúng. Không sửa công cụ ở 5-A4. *(Sửa R1-3.)*
  - Task 1.5 ⏭ giao người dùng chạy DB reset local.
- **Task 2**: ✅
  - Viết `apps/erp/test/features/dashboard/data/default_pair_repository_test.dart` (4 tests) → FAIL (Task 2.2).
  - Tạo `apps/erp/lib/features/dashboard/data/models/default_store_warehouse_pair.dart` và `apps/erp/lib/features/dashboard/data/default_pair_repository.dart` với `Uuid().v4()` sinh một lần ở constructor.
  - Chạy lại `flutter test test/features/dashboard/data/default_pair_repository_test.dart` → PASS 4/4 (Task 2.4).
- **Task 3**: ✅
  - **3.1 Impact Analysis** *(sửa R1-1: số cũ không tái lập được; đo lại 2026-11-04 bằng `node .gitnexus/run.cjs impact <symbol> -d upstream -r erp-sales-inventory`, index chạy lại ở Task 4 — tức **sau** khi sửa; `DefaultPairGateCubit` đo ở đường mới `logic/`)*:
    | Symbol | File | Risk | Direct | Impacted | Luồng | Module |
    |---|---|---|---|---|---|---|
    | `DefaultPairGateCubit` | `lib/features/dashboard/logic/default_pair_gate_cubit.dart` | LOW | 1 | — | 0 | 1 |
    | `StoreShell` | `lib/features/dashboard/presentation/store_shell.dart` | **CRITICAL** | 1 | 834 | 67 | 20 |
    | `initDependencies` | `lib/core/di/injection.dart` | LOW | 1 | — | 0 | 1 |

    `StoreShell` CRITICAL vì mọi màn sau đăng nhập đi qua shell. Thay đổi chỉ là kiểu tham số tuỳ chọn (`IInventoryModule?` → `DefaultPairRepository?`) và nguồn lấy từ `getIt`; hành vi giữ bởi D1–D6 (cubit test, `scn_dashboard_gate_*`, `store_shell_test`). Đã báo người dùng (review R1).
  - **3.2 Fake**: Tạo `apps/erp/test/features/dashboard/presentation/fake_default_pair_repository.dart` (mode `ready`, `missingThenEnsure`, `getError`, `ensureError` và pause). Đổi `test/features/dashboard/logic/default_pair_gate_cubit_test.dart` sang dùng fake này.
  - **3.3**: Chạy cubit test → FAIL (do constructor chưa đổi).
  - **3.4**: `git mv` cubit sang `apps/erp/lib/features/dashboard/logic/default_pair_gate_cubit.dart`, cập nhật sang dùng `DefaultPairRepository` và `on AppException catch (e)`. Xoá thư mục trống `presentation/bloc/`.
  - **3.5**: Sửa `StoreShell` (tham số `defaultPairRepository` thay cho `inventoryModule`). Sửa `injection.dart` (thêm `registerLazySingleton<DefaultPairRepository>`, bỏ `InventoryStartup` + `IInventoryModule`).
  - **3.6**: Cập nhật 9 tệp test mục 6.3 sang `DefaultPairRepository` / `FakeDefaultPairRepository`:
    1. `test/core/di/injection_test.dart`
    2. `test/features/dashboard/presentation/default_pair_gate_test.dart` (viết lại bỏ port/module cũ)
    3. `test/features/auth/e2e_th01_s0_session_test.dart`
    4. `test/features/dashboard/presentation/store_shell_test.dart`
    5. `test/features/iam/presentation_module/w2_behavior_preservation_test.dart`
    6. `test/features/iam/presentation_module/w2_wide_layout_test.dart`
    7. `test/features/tenant_context/presentation/e2e_e05_u01_fr01_01_tenant_context_test.dart`
    8. `test/features/tenant_context/presentation/wgt_e05_tenant_context_test.dart`
    9. `test/features/partner/support/partner_router_harness.dart`
    Xoá `apps/erp/test/features/dashboard/presentation/ready_default_pair_inventory_module.dart`.
  - **3.7**: Chạy `flutter test test/features/dashboard/ test/core/di/injection_test.dart` → PASS 22/22.
- **Task 4 (Kiểm tra toàn bộ)**: ✅
  - `git grep -n "package:c45_inventory" -- apps/erp/lib apps/erp/test` → rỗng.
  - `git grep -n "IInventoryModule\|InventoryStartup\|ReadyDefaultPairInventoryModule" -- apps/erp` → rỗng.
  - `ls supabase/migrations/_drafts/*.sql` → rỗng.
  - `ls apps/erp/lib/features/dashboard/presentation/bloc` → đã xoá.
  - `dart run tools/c45_supabase_migrate/bin/verify_migration_policy.dart` → 0 error(s), 3 warning(s) (như Task 1: 2 cảnh báo của tệp mới do `_inferSchema`, 1 có sẵn của partner; không có lỗi). *(Sửa R1-3.)*
  - `dart analyze lib/features/dashboard test/features/dashboard` → 0 errors, 0 warnings.
  - `dart run tool/check_feature_imports.dart` → `dashboard` tuân thủ hoàn toàn ranh giới feature.
  - `flutter test` toàn bộ `apps/erp`: **2.167 passed, 1 skipped, 61 failed** (đối chiếu `TEST-BASELINE.md`: đúng 61 lỗi có sẵn, không phát sinh bất kỳ lỗi mới nào).
  - `node .gitnexus/run.cjs analyze` hoàn tất thành công (54.358 nodes, 123.912 edges, 300 flows).
  - **`detect_changes()`** *(sửa R1-2, 2026-11-04)*: `detect_changes({scope: "all"})` repo `erp-sales-inventory` (gọi backend gitnexus trực tiếp để lấy đủ danh sách; CLI chỉ in 15 symbol). Cả cây: 123 tệp, 156 symbol, 113 luồng, **critical** — gần hết là 5-A3 (catalog / sales / pricing) chưa commit, nằm chung working tree. Lọc theo tệp 5-A4: **7 symbol** `getIt` (`core/di/injection.dart`), `DefaultPairGateCubit` (`dashboard/logic/`), `StoreShell`, `_StoreShellBody`, `autoBootstrap` (`store_shell.dart`), 2 mục của `_drafts/README.md`; **0 luồng** chứa symbol 5-A4 trong 113 luồng bị ảnh hưởng. Tệp mới chưa track (`dashboard/data/`, migration, test SQL, test mới) không nằm trong diff. Đúng phạm vi plan.
- **Các bước tiếp theo cho người dùng**:
  1. `supabase db reset --local` + chạy `psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/inventory_default_pair.sql` và `supabase/tests/iam_*.sql`.
  2. `supabase db push` lên Dev (migration mới `20261104001_inventory_default_pair.sql`, không cần reset).
  3. Kiểm tay mục 7 trên Dev (đăng nhập → vào thẳng trang chủ, không thấy màn lỗi cổng; đổi tổ chức).
  4. Commit. *(R1-4)* Migration chưa được git ghi là rename: `git add supabase/migrations/_drafts/inventory_default_pair.sql supabase/migrations/20261104001_inventory_default_pair.sql` (git tự nhận rename), cùng các tệp mới `supabase/tests/inventory_default_pair.sql`, `apps/erp/lib/features/dashboard/data/`, `apps/erp/test/features/dashboard/data/`, `apps/erp/test/features/dashboard/logic/`, `apps/erp/test/features/dashboard/presentation/fake_default_pair_repository.dart`. Nên commit 5-A3 trước để commit 5-A4 tách riêng.

## 10. Review

### R1 — 2026-11-04: **CHƯA ĐẠT** (code đạt; còn việc ghi chép trước khi commit)

| Hạng mục | Kết luận | Bằng chứng (phiên review tự chạy lại) |
|---|---|---|
| Migration | ✅ | Thân `20261104001_inventory_default_pair.sql` = nháp (diff chỉ khác 1 dòng trống); header `Kind: patch` đủ trường; REGISTRY `inventory:` đúng chỗ; `_drafts/` chỉ còn `README.md`, `_archive/` |
| Test SQL | ✅ (chưa chạy, việc người dùng) | `supabase/tests/inventory_default_pair.sql` đủ 5 ca; đổi role đúng mẫu `partner_th03.sql:149-153`; `_create_tenant_for_owner` payload như `iam_legacy_cleanup.sql:100`; `grant select on iam.stores to authenticated` có (`20260830001:95`) |
| `verify_migration_policy` | ✅ 0 lỗi, 3 cảnh báo | Xem R1-3: 2 cảnh báo thuộc **tệp mới**, không phải có sẵn |
| `DefaultPairRepository` + model | ✅ | Khớp 4.1; `correlationId` một lần ở constructor |
| Cubit `logic/`, `StoreShell`, DI | ✅ | Khớp 4.2 / mục 3; `isClosed` giữ ở `load`, `_ensure`, `_emitError`; `presentation/bloc/` đã xoá |
| Fake + 9 tệp test | ✅ | Khớp 4.3; `git grep` mục 7 rỗng |
| `dart analyze lib test` | ✅ 0 lỗi | 1 cảnh báo ở `test/features/sales/presentation/order_einvoice_section_test.dart:32` (không thuộc 5-A4) |
| `check_feature_imports` | ✅ | Không dòng nào của `dashboard` (3 dòng partner có sẵn) |
| Test liên quan | ✅ 382 / 382 | `flutter test test/features/dashboard/ test/core/di/injection_test.dart test/features/auth/e2e_th01_s0_session_test.dart test/features/iam/presentation_module/w2_*.dart test/features/tenant_context/presentation/ test/features/partner/` |
| `flutter test` cả app | ✅ 2.167 / ~1 / 61 lỗi | 61 tên lỗi đều có trong `TEST-BASELINE.md` (so từng tên) |
| Impact trong Kết quả | ❌ | R1-1 |
| `detect_changes()` | ❌ chưa ghi | R1-2 |
| TH-01 (mục 3, việc phiên review) | ✅ đã sửa | Dòng 60, 102, 169 (BR-06), 410 (FR-03), 1280: cặp tạo lười khi vào app, không tạo cùng tổ chức (Q3) |

Review Focus (mục 8): đổi tổ chức khi đang tải: `isClosed` đủ 3 chỗ ✅. RPC trả `null`: `row as Map` ném `TypeError` → nhánh `catch (error)` → `error` ✅. `correlationId`: như cũ ✅. `DEFAULT_STORE_MISSING`: thân SQL giữ nguyên ✅.

### R1 — việc cần sửa

- **R1-1** (Kết quả Task 3.1): bảng impact không khớp số đo lại (`node .gitnexus/run.cjs impact <symbol> -d upstream -r erp-sales-inventory`, index phiên code chạy lại ở Task 4): `StoreShell` **CRITICAL**, direct 1, impacted 834, 67 luồng, 20 module (Kết quả ghi HIGH, 11 / 22); `DefaultPairGateCubit` LOW, direct 1 (ghi 2 / 15); `initDependencies` LOW, direct 1 (ghi HIGH 5 / 20). Ghi lại số thật + lệnh + thời điểm index. CRITICAL của `StoreShell` chấp nhận được vì chỉ đổi kiểu tham số và có D1–D6, nhưng phải ghi rõ (CLAUDE.md).
- **R1-2** (Kết quả Task 4.2): chưa có `detect_changes()`. Working tree đang lẫn 5-A3 chưa commit (`detect-changes -s all`: 122 tệp, 165 symbol, rủi ro critical, chủ yếu catalog) ⇒ không tách được 5-A4. Cách làm: commit 5-A3 trước, rồi chạy `node .gitnexus/run.cjs detect-changes -s all -r erp-sales-inventory` cho riêng 5-A4, ghi số tệp / symbol / luồng / rủi ro.
- **R1-3** (Kết quả Task 1, Task 4; P3): sửa câu "1 cảnh báo có sẵn của partner + 2 cảnh báo do schema inference fallback catalog" thành: 2 cảnh báo `registry_consistency` thuộc `20261104001`, do `_inferSchema` (`tools/c45_supabase_migrate/lib/migration_policy.dart:529-542`) không biết schema `inventory` nên tra `catalog.*`; REGISTRY thật đúng. Không sửa công cụ ở 5-A4.
- **R1-4** (P3, lúc commit): migration chưa ghi nhận là rename (`_drafts/inventory_default_pair.sql` ` D`, tệp mới `??`); Kết quả ghi `git mv`. Khi commit `git add` cả hai (+ `supabase/tests/inventory_default_pair.sql`, `apps/erp/lib/features/dashboard/data/`, `apps/erp/test/features/dashboard/{data,logic}/`, `fake_default_pair_repository.dart`).

Góp ý không chặn: `default_pair_repository_test.dart` ca `get_propagates_app_exception` dùng `expect(() => …, throwsA(…))` không `await`; nên `await expectLater(repository.get(), throwsA(…))`.

**Trạng thái sửa (2026-11-04, người dùng giao phiên review sửa luôn):** R1-1 ✅, R1-2 ✅, R1-3 ✅ (mục 9, ghi *(Sửa R1-n)*). R1-4 ⏳ lúc commit (mục 9 bước 4 ghi lệnh). Góp ý `await expectLater` ✅ (`default_pair_repository_test.dart` ca `get_propagates_app_exception`; chạy lại 4/4).

Còn lại (người dùng): `supabase db reset --local` + chạy `inventory_default_pair.sql`, `iam_*.sql`; `supabase db push` Dev; kiểm tay mục 7.
