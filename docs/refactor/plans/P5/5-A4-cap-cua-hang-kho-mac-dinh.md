# 5-A4 — Cặp cửa hàng–kho mặc định: promote migration nháp + `DefaultPairRepository`

> Theme 2 (mã cũ P5) · Bước (a) chuyển kiến trúc · Gồm việc 5.5 (PLAN.md mục Theme 2)
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-01, kèm các đề xuất "duyệt plan là chốt") | Làm ⬜ | Review ⬜
> Độc lập với 5-A1…5-A3 (khác feature, khác module). Làm sau 5-A3 cho gọn thứ tự; làm trước cũng được.
> Tài liệu: PLAN.md mục Theme 2 dòng 5.5, "Quy tắc migration"; [TH-07](../../../02-yeu-cau/TH-07-kho.md); `specs/themes/theme-07/01.knowledge/know-how/KB-KGV-003-kho-cua-hang-va-khoa-dinh-danh-so-du-ton-kho.md` (một cửa hàng – một kho mặc định); `supabase/migrations/_drafts/README.md`.

## 1. Mục tiêu

- Đưa `supabase/migrations/_drafts/inventory_default_pair.sql` thành migration thật. Hiện hai RPC `inventory.get_default_store_warehouse_pair` / `ensure_default_store_warehouse_pair` **chỉ có ở bản nháp**, không nằm trong chuỗi migration ⇒ DB dựng từ migration (vd. sau `db reset`) không có schema `inventory`, cổng ở `StoreShell` lỗi và **chặn cả app** ở `DefaultPairGateErrorView`.
- Chuyển `DefaultPairGateCubit` từ `IInventoryModule` sang `DefaultPairRepository` (`features/dashboard/data/`; **không** dùng tên `InventoryRepository`: tên đó là của Theme 7).
- Sau 5-A4: `apps/erp/lib` không còn import `vet45_inventory_*`; DI bỏ `InventoryStartup` / `IInventoryModule`. Thư mục `modules/inventory` để 5-C xoá.

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | Promote bản nháp ở đâu | **Người dùng chốt 2026-11-01: trong 5-A4.** Theme 7 backend xây tiếp trên schema này (cặp mặc định là khái niệm của Theme 7, KB-KGV-003) |
| Q2 | Kiểm quyền client `InventoryPermissions.defaultPairRead` của handler `get` | **Bỏ** (như Theme 3 Q3). Server `Permission denied: inventory.default_pair.read` → `NO_PERMISSION` |
| Q3 | Bản nháp có gắn vào lúc tạo tổ chức không | **Không** (đo 2026-11-01: không đụng `iam._create_tenant_for_owner`). Cặp được tạo **lười** khi `StoreShell` gọi `ensure` lần đầu. Giữ như vậy; TH-01 BR-06 ghi "tạo cặp cùng tổ chức" là lệch tài liệu, phiên review sửa TH-01 sau khi xong (mục 3 bảng Thay đổi) |

## 3. Thay đổi

| Tệp | Hành động |
|---|---|
| `supabase/migrations/<số>_inventory_default_pair.sql` | **tạo** (đối tượng mới ⇒ migration mới). `<số>` = số kế tiếp **lớn hơn mọi tệp** trong `supabase/migrations/` lúc làm (đo 2026-11-01: lớn nhất `20261031023`; 4-B dự kiến `20261101001`). Nội dung = toàn bộ bản nháp, **không sửa thân**, thêm header theo `_migration.template.sql`: `-- Title: inventory default store/warehouse pair`, `-- Kind: feature`, `-- Intent: inventory_default_pair`, `-- Context: TH-07 / KB-KGV-003; PLAN 5-A4`, `-- Touches: ensure_default_store_warehouse_pair, get_default_store_warehouse_pair`, `-- Safety: one-shot ; low`, `-- Depends on: <migration tạo iam.stores unique (tenant_id, id)> (20260830001_iam_active_store_context_group_a)`. Bỏ 2 dòng chú thích đầu của nháp ("Draft: …", "Not a timestamped migration…") |
| `supabase/migrations/REGISTRY.yaml` | thêm mục `inventory:` (theo thứ tự chữ cái: sau `iam:`, trước `partner:`) với 2 dòng `ensure_default_store_warehouse_pair: <tệp>`, `get_default_store_warehouse_pair: <tệp>`. REGISTRY chỉ ghi hàm (xem mục `partner:`), không ghi bảng |
| `supabase/migrations/_drafts/inventory_default_pair.sql` | **xoá** |
| `supabase/migrations/_drafts/README.md` | dòng "Còn lại trong `_drafts/`: `inventory_default_pair.sql` (chưa promote)." → "`inventory_default_pair.sql` đã promote ở 5-A4 (`<tệp>`). `_drafts/` trống." |
| `apps/erp/lib/features/dashboard/data/default_pair_repository.dart` | **tạo** (mục 4.1) |
| `apps/erp/lib/features/dashboard/presentation/bloc/default_pair_gate_cubit.dart` | sửa (mục 4.2) |
| `apps/erp/lib/features/dashboard/presentation/store_shell.dart` | tham số `IInventoryModule? inventoryModule` (≈ dòng 37, 106, 118) → `DefaultPairRepository? defaultPairRepository`; `inventoryModule ?? getIt<IInventoryModule>()` → `defaultPairRepository ?? getIt<DefaultPairRepository>()` |
| `apps/erp/lib/core/di/injection.dart` | thêm `DefaultPairRepository`; xoá `InventoryStartup.initialize(...)` + `registerSingleton<IInventoryModule>` (≈ dòng 202–209) và 2 import `vet45_inventory_*` (dòng 3–4) |
| `apps/erp/test/features/dashboard/presentation/ready_default_pair_inventory_module.dart` | thay bằng `fake_default_pair_repository.dart` (mục 4.3) |
| 8 tệp test đang dùng `IInventoryModule` / `ReadyDefaultPairInventoryModule` (mục 6.3) | đổi cách dựng |
| `docs/02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md` BR-06, FR-03 dòng 410, dòng 60, 102, 1280 | phiên review sửa sau khi xong: cặp cửa hàng–kho tạo lười khi vào app lần đầu (Q3) |

**Không** đổi: `apps/erp/pubspec.yaml` (dòng `vet45_inventory_*` để 5-C bỏ cùng `modules/inventory`); `DefaultPairGateErrorView`; `supabase/config.toml` (đã có `inventory` trong `schemas` và `extra_search_path`).

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

`apps/erp/test/features/dashboard/presentation/fake_default_pair_repository.dart`: `FakeDefaultPairRepository extends DefaultPairRepository` với `enum FakeDefaultPairMode { ready, missingThenEnsure, error }`, đếm `getCalls` / `ensureCalls`. `ready` = hành vi của `ReadyDefaultPairInventoryModule` hiện tại (chép dữ liệu trả về). Xoá `ready_default_pair_inventory_module.dart`.

## 5. Đang làm gì — test giữ hành vi

| # | Cũ đang làm gì | Sau khi sửa | Test |
|---|---|---|---|
| D1 | `load`: `get` thành công → `ready` | giữ | `default_pair_gate_test.dart` `scn_dashboard_gate_success` (có sẵn) |
| D2 | `get` lỗi `DEFAULT_PAIR_MISSING` → gọi `ensure`; `ensure` thành công → `ready` | giữ | bước 0 thêm cubit test: fake module ném `ApplicationException('DEFAULT_PAIR_MISSING')` ở query, command thành công → `[loading, ready]`, command gọi 1 lần |
| D3 | `get` lỗi khác → `error` (không gọi `ensure`); `ensure` lỗi → `error`; lỗi không phải `ApplicationException` → `error` | giữ (`failureMessage` = mã) | bước 0: 3 ca; sau sửa kiểm `status`, **không** kiểm chuỗi `failureMessage` |
| D4 | Handler `get` kiểm quyền client `InventoryPermissions.defaultPairRead` | **Đổi (Q2):** bỏ | repository test: `get` gọi đúng 1 RPC `get_default_store_warehouse_pair` với `{p_tenant_id}` |
| D5 | Handler `ensure` gửi `p_correlation_id` = `correlationId` của context (cố định trong phiên) | repository giữ một `correlationId` suốt vòng đời | repository test: gọi `ensure` 2 lần → cùng `p_correlation_id`, là UUID |
| D6 | `StoreShell`: phiên không hợp lệ → không dựng cổng; đổi tổ chức (`ValueKey(tenantId)`) → cubit mới, tải lại; `status != ready` → màn chờ / lỗi; "Thử lại" gọi `load()` | giữ, chỉ đổi kiểu tham số | `store_shell_test.dart` (có sẵn) + bước 0 thêm: lỗi → bấm "Thử lại" → `get` gọi lần 2 |
| D7 | DB dựng từ migration **không** có RPC ⇒ cổng lỗi | **Đổi (Q1):** có RPC | SQL `supabase/tests/inventory_default_pair.sql` (mục 6, bước 1) |

**Bước 0:** D2, D3, D6 trên code cũ với `ReadyDefaultPairInventoryModule` / fake module ném lỗi. Chạy xanh, ghi tên test.

## 6. Các bước

Trước mỗi symbol Dart sửa: `gitnexus impact` (upstream) cho `DefaultPairGateCubit`, `StoreShell`, `initDependencies` (`injection.dart`). `StoreShell` nằm trên mọi màn sau đăng nhập ⇒ có thể HIGH: ghi blast radius, làm tiếp vì có D1–D6.

0. Bước 0 (mục 5).
1. **Migration:**
   - Tạo tệp (mục 3), REGISTRY, xoá nháp, sửa README nháp.
   - `supabase db reset` **local** (không phải Dev): chạy qua toàn bộ migration + `seed.sql`.
   - Tạo `supabase/tests/inventory_default_pair.sql` (mẫu `supabase/tests/iam_legacy_cleanup.sql`, một khối `begin … rollback`, `set local role authenticated` + `request.jwt.claims` của owner một tổ chức có cửa hàng mặc định):
     1. `get` khi chưa có cặp → lỗi `DEFAULT_PAIR_MISSING`;
     2. `ensure` → trả `storeId` = cửa hàng `code = 'default'`, `replayed = false`;
     3. `ensure` lần hai → cùng `warehouseId`, `replayed = true` (đọc thân hàm để chắc tên khoá);
     4. `get` → cùng cặp;
     5. user không là thành viên → `get` lỗi `Permission denied: inventory.default_pair.read`.
     Kết thúc `raise notice 'inventory_default_pair: OK'`. Chạy: `psql "$LOCAL_DB" -v ON_ERROR_STOP=1 -f supabase/tests/inventory_default_pair.sql`.
   - `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart`: không lỗi mới (migration có đủ header ⇒ **không** thêm vào `bootstrap_grandfathered`).
2. `DefaultPairRepository` + test (D4, D5, đọc JSON `get` / `ensure`).
3. Cubit (4.2), `StoreShell`, DI.
4. Fake (4.3), đổi 8 tệp test (mục 6.3).
5. Kiểm mục 7, ghi Kết quả, `detect_changes()`.

### 6.3 Test đang dùng `IInventoryModule`

`test/core/di/injection_test.dart` (đổi kỳ vọng: `DefaultPairRepository` đăng ký, `IInventoryModule` **không** đăng ký), `features/auth/e2e_th01_s0_session_test.dart`, `features/dashboard/presentation/default_pair_gate_test.dart`, `store_shell_test.dart`, `features/iam/presentation_module/w2_behavior_preservation_test.dart`, `w2_wide_layout_test.dart`, `features/tenant_context/presentation/e2e_e05_u01_fr01_01_tenant_context_test.dart`, `wgt_e05_tenant_context_test.dart`.

## 7. Kiểm tra

- [ ] `git grep -n "package:vet45_inventory" -- apps/erp/lib apps/erp/test` → rỗng.
- [ ] `git grep -n "IInventoryModule\|InventoryStartup\|ReadyDefaultPairInventoryModule" -- apps/erp` → rỗng.
- [ ] `ls supabase/migrations/_drafts/*.sql` → không còn tệp nào.
- [ ] `supabase db reset` local chạy qua; `inventory_default_pair.sql` ra `inventory_default_pair: OK`; các `supabase/tests/iam_*.sql` vẫn chạy qua.
- [ ] `verify_migration_policy.dart`: không lỗi mới.
- [ ] `cd apps/erp && dart analyze lib test`: không lỗi / cảnh báo mới. `flutter test`: không fail mới.
- [ ] Dev: migration **mới** (không sửa tệp đã áp) ⇒ Dev nhận khi người dùng chạy `supabase db push` hoặc reset. Phiên code **không** chạy; ghi "cần push / reset Dev" vào Kết quả.
- [ ] Kiểm tay (người dùng, sau khi Dev có migration): đăng nhập → vào thẳng trang chủ, không thấy màn lỗi cổng; đổi tổ chức → vẫn vào được.

## 8. Rủi ro / lưu ý

- Bản nháp viết trước nhiều thay đổi IAM. Nếu `db reset` local lỗi (cột / ràng buộc `iam.stores`, `iam.tenants` đã đổi tên) thì sửa **trong tệp migration mới** cho khớp schema hiện tại, ghi từng chỗ sửa + lý do vào Kết quả. Không sửa migration IAM.
- `idempotency_records` có trong bản nháp nhưng hai RPC có dùng không: không đổi, giữ nguyên (Theme 7 cần).
- Theme 7 backend sẽ thêm bảng / RPC vào schema `inventory`: theo quy tắc migration, sửa **tại chỗ** tệp này nếu đổi bảng của nó (trước khi Prod chạy thật).

## 9. Kết quả (phiên làm code ghi)

> Xong **mỗi bước** ghi ngay. Mẫu: trạng thái ✅ / 🔄 dở / ⏭ (lý do) · tệp:dòng · lệch plan + lý do · test thêm / sửa · impact · ghi chú cho review. Bước cuối: lệnh, số pass / fail, fail đối chiếu `TEST-BASELINE.md`, `detect_changes()`, "cần push / reset Dev".

## 10. Review

<!-- Phiên review ghi -->
