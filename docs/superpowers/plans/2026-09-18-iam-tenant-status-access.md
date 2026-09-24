# IAM — Chặn tổ chức tạm ngừng / đã đóng Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Khi tổ chức `suspended`/`closed`, server từ chối mọi thao tác nghiệp vụ (kể cả người đang ở trong app); ERP tự đưa người dùng về màn chặn với thông báo đúng; vá 2 RPC tồn kho thiếu kiểm tra quyền.

**Architecture:**
- SQL (sửa migration gốc, file owner): `iam.has_permission` ném `TENANT_SUSPENDED`/`TENANT_CLOSED`; `iam.can_access_store` lọc tổ chức; `iam.get_session_context` ném cùng mã; `catalog.adjust_basic_stock` + `catalog.set_basic_stock_quantity_base` thêm kiểm tra quyền.
- Client: `TenantAccessRevokedSignal` (shared application) được `SupabaseSchemaRpcClient` phát khi lỗi chứa 2 mã; `TenantContextCubit` (ERP) nghe → bootstrap lại → về màn chặn.
- IAM application: bootstrap trả `invalidated` cho tổ chức tạm ngừng/đã đóng thay vì `none`.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`; Flutter `flutter_test`, `flutter_bloc`, `go_router`.

**Spec:** [16-tenant-status-access.md](../specs/iam-schema-refactor/16-tenant-status-access.md) · Quy ước: [README §Quy ước implement](../specs/iam-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Global Constraints

- Tuân thủ **Quy ước implement** (sửa file owner; hàm cũ chỉ sửa khi `declare`/chữ ký dùng đối tượng bị bỏ — plan này không bỏ đối tượng nào).
- Chỉ chặn `suspended`, `closed`. **Không** chặn `provisioning`.
- Không đổi chữ ký RPC. Không chặn: RPC platform admin, `get_tenant_context`, `switch_tenant_context` (đã có), `list_accessible_tenants`, `list_user_tenants`, tuỳ chọn người dùng, luồng mật khẩu.
- Mã lỗi SQL: `raise exception 'TENANT_SUSPENDED'` / `'TENANT_CLOSED'` (plain) trong `has_permission`; JSON `{"code":"TENANT_SUSPENDED",…}` trong `get_session_context` (cùng định dạng các lỗi khác của hàm).
- Không `dart format` cả package; chỉ format file đã sửa. **Không `git commit`** — cuối task tóm tắt rồi dừng.
- Trước khi sửa symbol Dart: GitNexus `impact` (upstream). Hàm SQL → quét text.
- Sau khi sửa migration: **chỉ** chạy `supabase db reset` (không chạy lại file migration đơn lẻ trên DB đang chạy).

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260811024_iam_patch_owner_role_canonicalization.sql` | `has_permission` |
| Modify `supabase/migrations/20260830001_iam_active_store_context_group_a.sql` | `can_access_store` |
| Modify `supabase/migrations/20260914001_iam_get_session_context_multi_tenant.sql` | `get_session_context` |
| Modify `supabase/migrations/20260712003_catalog_rename_basic_stock_quantity_base.sql` | 2 hàm tồn kho |
| Create `modules/iam/infrastructure/test/iam_tenant_status_access_sql_contract_test.dart` | SQL contract test |
| Create `packages/vet45_shared/application/lib/src/access/tenant_access_revoked_signal.dart` + export + test | Tín hiệu |
| Modify `packages/vet45_adapters/lib/src/supabase/supabase_schema_rpc_client.dart` + test | Phát tín hiệu |
| Modify `modules/iam/application/lib/src/shared/iam_blocked_codes.dart` | `tenantClosed` |
| Modify `modules/iam/infrastructure/lib/src/errors/iam_blocked_error_mapper.dart` | Map `TENANT_CLOSED` |
| Modify `modules/iam/application/lib/src/tenant/queries/get_tenant_context/get_tenant_context_query_handler.dart` + test | Bootstrap trả `invalidated` |
| Modify `modules/iam/application/lib/src/testing/fake_iam_module.dart` | Đồng bộ fake |
| Modify `apps/{erp,admin}/lib/features/iam/presentation/shared/iam_ui_failure_mapper.dart` | Thông báo `TENANT_CLOSED` |
| Modify `apps/erp/lib/features/tenant_context/presentation/bloc/tenant_context_cubit.dart` + test | Nghe tín hiệu |
| Modify `apps/erp/lib/features/iam/presentation/organizations/widgets/organization_empty_view.dart` | Thông báo "đã đóng" |
| Modify `apps/erp/lib/features/dashboard/presentation/dashboard_page.dart` | Truyền `isClosed`, về dashboard khi bị chặn |
| Modify `docs/themes/TH-01-organization-users/harness/07-api-contracts.md` | Ghi chú OQ-07 |
| Modify `docs/superpowers/specs/iam-schema-refactor/README.md` | Tiến độ |

---

### Task 1: SQL — chặn ở server + vá RPC tồn kho

- [ ] **Step 1: Viết test (fail)** — `modules/iam/infrastructure/test/iam_tenant_status_access_sql_contract_test.dart`

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — block suspended/closed tenants server-side
/// (docs/superpowers/specs/iam-schema-refactor/16-tenant-status-access.md).
void main() {
  test('has_permission raises for suspended/closed tenant, not provisioning', () {
    final b = _lastFunctionBlock(
      _readMigration('20260811024_iam_patch_owner_role_canonicalization.sql'),
      'iam.has_permission',
    );
    expect(b, contains('join iam.tenants t on t.id = m.tenant_id'));
    expect(b, contains("if v_tenant_status = 'suspended' then\n    raise exception 'TENANT_SUSPENDED';"));
    expect(b, contains("if v_tenant_status = 'closed' then\n    raise exception 'TENANT_CLOSED';"));
    expect(b, isNot(contains("'provisioning'")));
    // Tenant check happens after membership check, before owner shortcut.
    expect(b.indexOf("'TENANT_SUSPENDED'"), greaterThan(b.indexOf("coalesce(v_status, 'active') <> 'active'")));
    expect(b.indexOf("'TENANT_SUSPENDED'"), lessThan(b.indexOf('if coalesce(v_is_owner, false) then')));
  });

  test('can_access_store excludes suspended/closed tenants', () {
    final b = _lastFunctionBlock(
      _readMigration('20260830001_iam_active_store_context_group_a.sql'),
      'iam.can_access_store',
    );
    expect(b, contains('join iam.tenants t'));
    expect(b, contains("t.status not in ('suspended', 'closed')"));
  });

  test('get_session_context raises tenant status codes', () {
    final b = _lastFunctionBlock(
      _readMigration('20260914001_iam_get_session_context_multi_tenant.sql'),
      'iam.get_session_context',
    );
    expect(b, contains('"code":"TENANT_SUSPENDED"'));
    expect(b, contains('"code":"TENANT_CLOSED"'));
    expect(b.indexOf('"code":"TENANT_SUSPENDED"'), lessThan(b.indexOf('from iam.stores store')));
  });

  test('basic stock RPCs assert manage_stock permission', () {
    final sql = _readMigration('20260712003_catalog_rename_basic_stock_quantity_base.sql');
    for (final fn in ['catalog.adjust_basic_stock', 'catalog.set_basic_stock_quantity_base']) {
      expect(
        _lastFunctionBlock(sql, fn),
        contains("perform catalog._assert_product_permission(p_tenant_id, 'catalog.product.manage_stock');"),
        reason: fn,
      );
    }
  });
}

String _readMigration(String fileName) {
  final root = _findRepoRoot();
  return File('${root.path}/supabase/migrations/$fileName').readAsStringSync();
}

/// Last `create or replace function <qualifiedName>(` … `$$;` in [sql].
String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  final bodyStart = sql.indexOf(r'as $$', start);
  final end = sql.indexOf(r'$$;', bodyStart + 5);
  return sql.substring(start, end + 3);
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Vet45 workspace root');
    }
    current = parent;
  }
  return current;
}
```

- [ ] **Step 2: Chạy test, xác nhận fail** — `cd modules/iam/infrastructure && dart test test/iam_tenant_status_access_sql_contract_test.dart` → FAIL 4 test.

- [ ] **Step 3: `iam.has_permission`** (`20260811024_…`, định nghĩa cuối)

1. `declare`: thêm `  v_tenant_status text;`
2. Thay:
```sql
  select m.role, m.is_owner, iam._membership_status_code(m.is_active, m.removed_at)
  into v_role, v_is_owner, v_status
  from iam.memberships m
  where m.user_id = v_user_id
    and m.tenant_id = p_tenant_id;

  -- Not a member, or membership no longer active.
  if v_role is null or coalesce(v_status, 'active') <> 'active' then
    return false;
  end if;
```
bằng:
```sql
  select m.role, m.is_owner, iam._membership_status_code(m.is_active, m.removed_at),
         coalesce(t.status, 'active')
  into v_role, v_is_owner, v_status, v_tenant_status
  from iam.memberships m
  join iam.tenants t on t.id = m.tenant_id
  where m.user_id = v_user_id
    and m.tenant_id = p_tenant_id;

  -- Not a member, or membership no longer active.
  if v_role is null or coalesce(v_status, 'active') <> 'active' then
    return false;
  end if;

  -- Suspended/closed tenant: raise a stable code so clients can leave the tenant.
  -- provisioning stays allowed (owner completes profile before activation).
  if v_tenant_status = 'suspended' then
    raise exception 'TENANT_SUSPENDED';
  end if;
  if v_tenant_status = 'closed' then
    raise exception 'TENANT_CLOSED';
  end if;
```

- [ ] **Step 4: `iam.can_access_store`** (`20260830001_…`) — thay thân:
```sql
  select exists (
    select 1
    from iam.stores s
    join iam.memberships m
      on m.tenant_id = s.tenant_id
    where s.tenant_id = p_tenant_id
      and s.id = p_store_id
      and s.status = 'active'
      and m.user_id = p_user_id
      and m.is_active
  );
```
bằng:
```sql
  select exists (
    select 1
    from iam.stores s
    join iam.tenants t
      on t.id = s.tenant_id
    join iam.memberships m
      on m.tenant_id = s.tenant_id
    where s.tenant_id = p_tenant_id
      and s.id = p_store_id
      and s.status = 'active'
      and t.status not in ('suspended', 'closed')
      and m.user_id = p_user_id
      and m.is_active
  );
```
Sửa comment ngay trên hàm: `-- Single-store era: store access = active store of an operational tenant + active membership.`

- [ ] **Step 5: `iam.get_session_context`** (`20260914001_…`)

1. `declare`: thêm `  v_tenant_status text;`
2. Ngay **trước** dòng `  -- Single-store era: the tenant's active store (default first) is the active store.` thêm:
```sql
  select coalesce(t.status, 'active')
  into v_tenant_status
  from iam.tenants t
  where t.id = v_tenant_id;

  if v_tenant_status = 'suspended' then
    raise exception using errcode = 'P0001',
      message = '{"code":"TENANT_SUSPENDED","message":"Tenant is suspended.","details":{}}';
  end if;
  if v_tenant_status = 'closed' then
    raise exception using errcode = 'P0001',
      message = '{"code":"TENANT_CLOSED","message":"Tenant is closed.","details":{}}';
  end if;

```

- [ ] **Step 6: RPC tồn kho** (`20260712003_…`) — trong **cả** `catalog.set_basic_stock_quantity_base` và `catalog.adjust_basic_stock`, dòng đầu tiên ngay sau `begin` thêm:
```sql
  perform catalog._assert_product_permission(p_tenant_id, 'catalog.product.manage_stock');

```
(`_assert_product_permission` tạo ở `20260709014`, chạy trước. `set_basic_stock_quantity_base` còn được gọi nội bộ từ `create_guided_product`… với cùng `auth.uid()` đã có quyền `catalog.product.create` → owner/staff hoạt động vẫn có `manage_stock` theo `has_permission`.)

- [ ] **Step 7: Chạy test + policy**
- `cd modules/iam/infrastructure && dart test test/iam_tenant_status_access_sql_contract_test.dart test/iam_refactor_06_store_scopes_sql_contract_test.dart test/iam_refactor_08_access_checks_sql_contract_test.dart test/iam_owner_role_canonicalization_sql_contract_test.dart` → PASS (sửa assertion cũ nếu kiểm tra nguyên văn thân `has_permission`/`can_access_store`).
- `cd modules/catalog/infrastructure && dart test` → không thêm lỗi so với trước khi sửa.
- `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK.

- [ ] **Step 8: Dừng — tóm tắt.**

---

### Task 2: Tín hiệu `TenantAccessRevokedSignal` + phát từ RPC client

- [ ] **Step 1: Test (fail)** — `packages/vet45_shared/application/test/tenant_access_revoked_signal_test.dart`

```dart
import 'package:test/test.dart';
import 'package:vet45_shared_application/application.dart';

void main() {
  test('emits code when error mentions TENANT_SUSPENDED or TENANT_CLOSED', () async {
    final events = <String>[];
    final sub = TenantAccessRevokedSignal.stream.listen(events.add);

    TenantAccessRevokedSignal.notifyFromError(Exception('PostgrestException(message: TENANT_SUSPENDED)'));
    TenantAccessRevokedSignal.notifyFromError(Exception('{"code":"TENANT_CLOSED"}'));
    TenantAccessRevokedSignal.notifyFromError(Exception('PERMISSION_DENIED'));
    await Future<void>.delayed(Duration.zero);

    expect(events, [
      TenantAccessRevokedSignal.tenantSuspended,
      TenantAccessRevokedSignal.tenantClosed,
    ]);
    await sub.cancel();
  });
}
```
Run: `cd packages/vet45_shared/application && dart test test/tenant_access_revoked_signal_test.dart` → FAIL.

- [ ] **Step 2: Tạo** `packages/vet45_shared/application/lib/src/access/tenant_access_revoked_signal.dart`

```dart
import 'dart:async';

/// Process-wide signal raised when the server rejects a call because the
/// current tenant is no longer operational (suspended / closed).
///
/// Emitted by the Supabase RPC client; UI shells listen and leave the tenant.
abstract final class TenantAccessRevokedSignal {
  static const tenantSuspended = 'TENANT_SUSPENDED';
  static const tenantClosed = 'TENANT_CLOSED';

  static final StreamController<String> _controller = StreamController<String>.broadcast();

  static Stream<String> get stream => _controller.stream;

  /// Emits [tenantSuspended] / [tenantClosed] when [error] carries that code.
  static void notifyFromError(Object error) {
    final text = error.toString().toUpperCase();
    if (text.contains(tenantClosed)) {
      _controller.add(tenantClosed);
    } else if (text.contains(tenantSuspended)) {
      _controller.add(tenantSuspended);
    }
  }
}
```
`packages/vet45_shared/application/lib/application.dart`: thêm `export 'src/access/tenant_access_revoked_signal.dart';` ngay sau `export 'src/access/access_metadata.dart';`.

- [ ] **Step 3: Chạy test, xác nhận pass.**

- [ ] **Step 4: `SupabaseSchemaRpcClient`** — trong **cả 3** khối `catch (error, stackTrace)` (`callMap`, `callList`, `callScalar`), ngay trước `throw _mapError(error, stackTrace);` thêm:
```dart
      TenantAccessRevokedSignal.notifyFromError(error);
```
(`vet45_adapters` đã phụ thuộc `vet45_shared_application`; thêm `import 'package:vet45_shared_application/application.dart';` nếu file chưa import.)

- [ ] **Step 5: Test client** — trong `packages/vet45_adapters/test/` thêm test (theo mẫu fake Supabase sẵn có trong `supabase_rpc_client_test.dart`): RPC ném lỗi có message `TENANT_SUSPENDED` → `TenantAccessRevokedSignal.stream` nhận `TENANT_SUSPENDED` và lời gọi vẫn ném lỗi như cũ. Nếu không dựng được fake cho `SupabaseSchemaRpcClient`, ghi lại lý do trong tóm tắt và dựa vào test Step 1.
Run: `cd packages/vet45_adapters && dart test` → PASS.

- [ ] **Step 6: Dừng — tóm tắt.**

---

### Task 3: IAM application — bootstrap trả `invalidated` + mã `TENANT_CLOSED`

- [ ] **Step 1: Test (fail)** — trong `modules/iam/application/test/scn_e05_u03_fr01_01_get_tenant_context_test.dart`, thêm cạnh test `'bootstrap_invalid — OQ-07 returns none without auto-pick'`:

```dart
    test('bootstrap on suspended/closed tenant returns invalidated (no auto-pick)', () async {
      for (final reason in [
        TenantContextInvalidationReason.tenantSuspended,
        TenantContextInvalidationReason.tenantClosed,
      ]) {
        final session = _FakeSessionPort();
        final handler = GetTenantContextQueryHandler(
          accessGateway: _ScenarioAccessGateway((id) async {
            return TenantContextDto(
              status: TenantContextStatus.invalidated,
              tenantId: 'tenant-x',
              tenantName: 'Tiền',
              invalidationReason: reason,
              blockedErrorCode: reason == TenantContextInvalidationReason.tenantClosed
                  ? 'TENANT_CLOSED'
                  : 'TENANT_SUSPENDED',
            );
          }),
          preferencePort: _FakePreferencePort('tenant-x'),
          sessionPort: session,
          currentTenant: _FakeCurrentTenant(null),
        );

        final result = await handler.handle(
          GetTenantContextQuery(bootstrapFromLastSelected: true),
        );

        expect(result.status, TenantContextStatus.invalidated, reason: '$reason');
        expect(result.invalidationReason, reason);
        expect(result.tenantName, 'Tiền');
        expect(session.establishedTenantId, isNull);
      }
    });
```
Run: `cd modules/iam/application && dart test test/scn_e05_u03_fr01_01_get_tenant_context_test.dart` → FAIL.

- [ ] **Step 2: Handler** — `get_tenant_context_query_handler.dart`, thay:
```dart
      // OQ-07: invalid preference → none (do not auto-pick another tenant).
      if (context.status != TenantContextStatus.valid ||
          context.tenantId == null) {
        return const TenantContextDto(status: TenantContextStatus.none);
      }
```
bằng:
```dart
      // Suspended/closed tenant: surface it so the shell can explain the block.
      // Still no auto-pick (OQ-07) — the shell opens the selector.
      if (context.status == TenantContextStatus.invalidated &&
          (context.invalidationReason == TenantContextInvalidationReason.tenantSuspended ||
              context.invalidationReason == TenantContextInvalidationReason.tenantClosed)) {
        return context;
      }

      // OQ-07: invalid preference → none (do not auto-pick another tenant).
      if (context.status != TenantContextStatus.valid ||
          context.tenantId == null) {
        return const TenantContextDto(status: TenantContextStatus.none);
      }
```
(thêm import `package:vet45_iam_domain/domain.dart` nếu thiếu `TenantContextInvalidationReason`.)

- [ ] **Step 3: Mã lỗi**
- `iam_blocked_codes.dart`: sau `static const tenantSuspended = 'TENANT_SUSPENDED';` thêm `  static const tenantClosed = 'TENANT_CLOSED';`
- `iam_blocked_error_mapper.dart`: thêm `IamBlockedCodes.tenantClosed,` ngay sau `IamBlockedCodes.tenantSuspended,`.
- `apps/erp/.../iam_ui_failure_mapper.dart` và `apps/admin/.../iam_ui_failure_mapper.dart`: `_knownCodes` thêm `IamBlockedCodes.tenantClosed,` sau `IamBlockedCodes.tenantSuspended,`; `_localizedMessages` thêm `IamBlockedCodes.tenantClosed: 'Tổ chức đã đóng.',` sau dòng `tenantSuspended`.

- [ ] **Step 4: Fake module** — `fake_iam_module.dart`, trong `_handleGetTenantContext` nhánh `bootstrapFromLastSelected`, thay khối:
```dart
      if (match == null ||
          match.status == TenantLifecycleStatus.suspended ||
          match.status == TenantLifecycleStatus.closed) {
        // OQ-07: invalid preference → none (do not auto-pick).
        return Future.value(
          const TenantContextDto(status: TenantContextStatus.none) as TResult,
        );
```
bằng (giữ nguyên phần sau khối):
```dart
      if (match != null &&
          (match.status == TenantLifecycleStatus.suspended ||
              match.status == TenantLifecycleStatus.closed)) {
        final closed = match.status == TenantLifecycleStatus.closed;
        return Future.value(
          TenantContextDto(
            status: TenantContextStatus.invalidated,
            tenantId: match.tenantId,
            tenantName: match.name,
            tenantStatus: match.status,
            invalidationReason: closed
                ? TenantContextInvalidationReason.tenantClosed
                : TenantContextInvalidationReason.tenantSuspended,
            blockedErrorCode: closed ? IamBlockedCodes.tenantClosed : IamBlockedCodes.tenantSuspended,
          ) as TResult,
        );
      }
      if (match == null) {
        // OQ-07: invalid preference → none (do not auto-pick).
        return Future.value(
          const TenantContextDto(status: TenantContextStatus.none) as TResult,
        );
```
(`_accessibleTenants` là `List<AccessibleTenantDto>` với field `tenantId`, `name`, `status`.)

- [ ] **Step 5: Chạy test**
- `cd modules/iam/application && dart test` → PASS (sửa test fake nào đang kỳ vọng `none` cho tổ chức tạm ngừng/đã đóng sang `invalidated`).
- `cd modules/iam/infrastructure && dart test` → không thêm lỗi so với baseline 20.

- [ ] **Step 6: Tài liệu contract** — `docs/themes/TH-01-organization-users/harness/07-api-contracts.md`:
- Dòng `- **OQ-07 (closed):** …` thêm cuối câu: ` Ngoại lệ (2026-09-18): preference trỏ tổ chức \`suspended\`/\`closed\` → \`invalidated\` (\`tenantSuspended\`/\`tenantClosed\`) để FE hiện lý do; vẫn không auto-select.`
- Dòng `- Identity/membership/tenant denial → …`: đổi `hoặc \`none\` (bootstrap OQ-07)` thành `hoặc \`none\` (bootstrap OQ-07, trừ tổ chức tạm ngừng/đã đóng)`.

- [ ] **Step 7: Dừng — tóm tắt.**

---

### Task 4: ERP — tự rời tổ chức khi bị chặn + thông báo "đã đóng"

- [ ] **Step 1: Test cubit (fail)** — tạo `apps/erp/test/features/tenant_context/presentation/tenant_context_cubit_revoked_signal_test.dart`

```dart
import 'dart:async';

import 'package:erp/features/tenant_context/presentation/bloc/tenant_context_cubit.dart';
import 'package:erp/features/tenant_context/presentation/bloc/tenant_context_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/testing.dart';

void main() {
  test('ready cubit re-bootstraps when tenant access is revoked', () async {
    final revoked = StreamController<String>.broadcast();
    final cubit = TenantContextCubit(
      iamModule: FakeIamModule(),
      initialState: const TenantContextState(status: TenantContextLoadStatus.ready),
      tenantAccessRevoked: revoked.stream,
    );
    expect(cubit.state.status, TenantContextLoadStatus.ready);

    final statuses = <TenantContextLoadStatus>[];
    final sub = cubit.stream.listen((s) => statuses.add(s.status));

    revoked.add('TENANT_SUSPENDED');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(statuses, contains(TenantContextLoadStatus.loading));
    await sub.cancel();
    await cubit.close();
    await revoked.close();
  });

  test('blocked cubit ignores further revoked signals', () async {
    final revoked = StreamController<String>.broadcast();
    final cubit = TenantContextCubit(
      iamModule: FakeIamModule(scenario: FakeIamScenario.contextNone),
      tenantAccessRevoked: revoked.stream,
    );
    await cubit.bootstrap();
    expect(cubit.state.isBlocked, isTrue);

    final statuses = <TenantContextLoadStatus>[];
    final sub = cubit.stream.listen((s) => statuses.add(s.status));
    revoked.add('TENANT_CLOSED');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(statuses, isEmpty);
    await sub.cancel();
    await cubit.close();
    await revoked.close();
  });
}
```
(`TenantContextState` có thể cần `userDisplayName` bắt buộc — bổ sung `userDisplayName: ''` nếu constructor yêu cầu.)
Run: `cd apps/erp && flutter test test/features/tenant_context/presentation/tenant_context_cubit_revoked_signal_test.dart` → FAIL.

- [ ] **Step 2: `TenantContextCubit`**
1. Import `dart:async`.
2. Constructor thêm tham số `Stream<String>? tenantAccessRevoked,`; trong body constructor:
```dart
  {
    _revokedSubscription = (tenantAccessRevoked ?? TenantAccessRevokedSignal.stream).listen(
      (_) => _onTenantAccessRevoked(),
    );
  }
```
(đổi initializer list hiện tại thành constructor có body, giữ nguyên `super(...)`.)
3. Field: `late final StreamSubscription<String> _revokedSubscription;`
4. Thêm:
```dart
  void _onTenantAccessRevoked() {
    if (isClosed || state.status != TenantContextLoadStatus.ready) return;
    bootstrap();
  }

  @override
  Future<void> close() async {
    await _revokedSubscription.cancel();
    return super.close();
  }
```
5. Thay 2 chuỗi `'TENANT_CLOSED'` trong file bằng `IamBlockedCodes.tenantClosed`.

- [ ] **Step 3: Màn chặn** — `organization_empty_view.dart`
1. Thêm field + tham số constructor `final bool isClosed;` / `this.isClosed = false,`.
2. Trong `case OrganizationEmptyStateType.inaccessible:` thay dòng `description = '${suspendedOrgName ?? "ASC Commerce"} đang tạm ngừng. …';` bằng:
```dart
        final orgName = suspendedOrgName ?? 'Tổ chức';
        description = isClosed
            ? '$orgName đã đóng. Bạn không thể truy cập dữ liệu của tổ chức này.'
            : '$orgName đang tạm ngừng. Bạn không thể truy cập dữ liệu của tổ chức này.';
```

- [ ] **Step 4: Dashboard** — `dashboard_page.dart`
1. Trong `_buildHomeBody`, `OrganizationEmptyView(` thêm `isClosed: state.blockedErrorCode == IamBlockedCodes.tenantClosed,`.
2. Bọc phần body của `_DashboardPageState.build` bằng (hoặc thêm vào `BlocListener` sẵn có):
```dart
BlocListener<TenantContextCubit, TenantContextState>(
  listenWhen: (previous, current) =>
      previous.status == TenantContextLoadStatus.ready && current.isBlocked,
  listener: (context, state) {
    // Leave any pushed feature page and show the block screen.
    context.goNamed('dashboard', extra: DashboardTab.home);
  },
  child: …,
)
```

- [ ] **Step 5: Chạy test + analyze**
- `cd apps/erp && flutter test test/features/tenant_context test/features/iam/presentation_module/shared` → PASS.
- `cd apps/erp && flutter analyze lib/features/tenant_context lib/features/dashboard lib/features/iam/presentation/organizations` → không lỗi mới.
- `cd apps/admin && flutter test test/features/iam/presentation_module/shared` → PASS.

- [ ] **Step 6: Tiến độ** — README spec, bảng "Việc phát sinh", dòng "Chặn tổ chức tạm ngừng / đã đóng" → `🧪 Đã sửa, chờ reset`.

- [ ] **Step 7: Dừng — user `supabase db reset` + smoke test**

1. Staff đang ở màn **chi tiết đơn hàng** trong ERP; Admin tạm ngừng tổ chức → Staff kéo làm mới / bấm thao tác → app tự về dashboard, hiện "{tên} đang tạm ngừng…", mở selector (tổ chức hiện mờ).
2. Kill app → mở lại → cùng màn chặn (không còn "Chưa có tổ chức được cấp quyền").
3. Admin khôi phục → Staff chọn lại tổ chức → dùng bình thường.
4. Lặp 1–2 với **đóng tổ chức** → thông báo "đã đóng".
5. User thuộc 2 tổ chức (1 tạm ngừng) → chọn tổ chức còn hoạt động → dùng bình thường.
6. Tổ chức `provisioning`: owner vẫn sửa hồ sơ / kích hoạt được.
7. SQL (giả lập staff, tổ chức tạm ngừng):
```sql
begin;
select set_config('request.jwt.claims', json_build_object('sub','<STAFF_UUID>','role','authenticated')::text, true);
set local role authenticated;
select iam.has_permission('<TENANT_ID>', 'sales.order.create');   -- ERROR: TENANT_SUSPENDED
rollback;
```

---

### Task 5: ERP — chặn mọi tab, sửa header và mã lỗi bị xoá

> Bổ sung 2026-09-18 sau smoke test: server đã chặn đúng, nhưng ERP chỉ hiện màn chặn ở tab **Trang chủ**; các tab khác vẫn mở và hiện lỗi riêng của module (kể cả lỗi thô `PostgrestException(message: TENANT_SUSPENDED…)`), header vẫn hiện tên tổ chức.

**Ba lỗi phải sửa:**

| # | Lỗi | Nguyên nhân |
|---|---|---|
| 5a | Tab Đơn hàng / Sản phẩm / KH & NCC / Khác vẫn dùng được | Nhánh `state.isBlocked` chỉ nằm trong `_buildHomeBody`; `_buildBody` trả thẳng trang module cho các tab khác |
| 5b | Header vẫn hiện tên tổ chức ("Vua") | `TenantContextState.copyWith` giữ `branchDisplayName` cũ khi truyền `null` (`branchDisplayName ?? this.branchDisplayName`) |
| 5c | Màn chặn không bao giờ hiện thông báo "đã đóng" | Trong `copyWith`, `blockedErrorCode` bị buộc vào `clearContextFailure`; `_emitResolvedContext` nhánh `invalidated` truyền `clearContextFailure: true` nên `blockedErrorCode` bị xoá ngay |
| 5d | Ở 3 tab Đơn hàng / Sản phẩm / KH & NCC, thẻ chặn tràn lên status bar | Header của 3 tab này do `VPageScaffold` trong trang module dựng (kèm vùng an toàn); thay trang module bằng màn chặn thì mất phần đó, mà dashboard không bù lại |
| 5e | Chặn cả tab **Khác** thì người dùng **không đăng xuất được** → mắc kẹt trong app | Tab Khác chứa "Đăng xuất" và "Tài khoản của tôi" — hai mục thuộc **tài khoản cá nhân**, không thuộc tổ chức |
| 5f | Màn "Tài khoản của tôi" không cho biết người dùng là chủ sở hữu | Thẻ đầu trang chỉ hiện tên + "Tài khoản cá nhân"; `MyAccountUiModel` chưa có `isOwner` (yêu cầu user 2026-09-18) |
| 5h | Mở tab Khác khi tổ chức bị chặn → log 1 dòng `SEVERE` `get_tenant_readiness → TENANT_SUSPENDED` | `IamFeatureAccessCubit.load()` vẫn gọi `GetCurrentSessionQuery` + `GetTenantReadinessQuery` (đều theo tổ chức). Chỉ là nhiễu log, người dùng không thấy |
| 5g | Đang ở **bất kỳ** trang con (Đơn hàng, Sản phẩm, Thêm khách hàng, các mục trong Khác) thì bị tạm ngừng → app **không** chuyển về màn chặn; RPC lỗi liên tục, UI im lặng hoặc hiện lỗi thô | `BlocListener` dùng `previous.status == ready && current.isBlocked`, nhưng `bootstrap()` phát `loading` **trước** `blocked`, nên khi `blocked` tới thì `previous` là `loading` → điều kiện không bao giờ đúng. Tín hiệu và việc điều hướng là **dùng chung cho mọi module**, nên chỉ cần sửa 1 chỗ |

- [ ] **Step 1: Test (fail)** — `apps/erp/test/features/tenant_context/presentation/tenant_context_blocked_ui_test.dart`

```dart
import 'package:erp/features/tenant_context/presentation/bloc/tenant_context_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_iam_application/application.dart';

void main() {
  test('copyWith keeps blockedErrorCode when clearing context failure', () {
    const state = TenantContextState(userDisplayName: '');
    final blocked = state.copyWith(
      status: TenantContextLoadStatus.blocked,
      blockedErrorCode: IamBlockedCodes.tenantClosed,
      clearContextFailure: true,
    );
    expect(blocked.blockedErrorCode, IamBlockedCodes.tenantClosed);
  });

  test('copyWith can clear branch display name', () {
    const state = TenantContextState(userDisplayName: '', branchDisplayName: 'Vua');
    expect(state.copyWith(clearBranchDisplayName: true).branchDisplayName, isNull);
  });
}
```
Thêm vào `apps/erp/test/features/tenant_context/presentation/wgt_e05_tenant_context_test.dart` (theo mẫu test sẵn có dựng `DashboardPage` với `initialState`) một test: state `blocked` + `emptyStateType: inaccessible` + `initialTab: DashboardTab.orders` → thấy `OrganizationEmptyView` ("Tổ chức không thể truy cập"), **không** thấy `SalesOrderListPage`.

Run: `cd apps/erp && flutter test test/features/tenant_context` → FAIL.

- [ ] **Step 2: `tenant_context_state.dart`**
1. `copyWith` thêm tham số `bool clearBranchDisplayName = false,` (cạnh các cờ `clear*`).
2. `branchDisplayName: branchDisplayName ?? this.branchDisplayName,` → `branchDisplayName: clearBranchDisplayName ? null : (branchDisplayName ?? this.branchDisplayName),`
3. Tách `blockedErrorCode` khỏi `clearContextFailure`: thêm cờ `bool clearBlockedErrorCode = false,` và đổi thành `blockedErrorCode: clearBlockedErrorCode ? null : (blockedErrorCode ?? this.blockedErrorCode),`

- [ ] **Step 3: `tenant_context_cubit.dart`** — trong `_emitResolvedContext`:
- Nhánh `valid`: thêm `clearBlockedErrorCode: true,` (trước đây dựa vào `clearContextFailure`).
- Nhánh `none` và `invalidated`: thay `branchDisplayName: null,` bằng `clearBranchDisplayName: true,`; nhánh `none` thêm `clearBlockedErrorCode: true,`.
- Rà các chỗ khác đang dựa vào `clearContextFailure` để xoá `blockedErrorCode` (vd `bootstrap`, `switchTenant`) → thêm `clearBlockedErrorCode: true` khi cần.

- [ ] **Step 4: `dashboard_page.dart` — chặn mọi tab**
1. Chuyển 3 nhánh đầu của `_buildHomeBody` (`loading/initial`, `isBlocked`, `failure`) lên đầu `_buildBody`, trước `switch (_currentTab)`; `_buildHomeBody` chỉ còn phần nội dung trang chủ.
2. **5d — vùng an toàn (chốt cách A).** Tab Trang chủ có `DashboardHeader`, tab Khác có `VAppBar`, còn 3 tab Đơn hàng / Sản phẩm / KH & NCC lấy header từ `VPageScaffold` **bên trong trang module**. Thay trang module bằng màn chặn là mất luôn phần chừa status bar → thẻ chặn tràn lên vùng tai thỏ. Vì vậy 3 nhánh vừa chuyển lên phải tự bọc vùng an toàn và canh giữa:
```dart
    if (state.isBlocked) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(VSpacing.screenMobile),
            child: OrganizationEmptyView(
              type: state.emptyStateType ?? OrganizationEmptyStateType.noAuthorizedOrganizations,
              suspendedOrgName: state.suspendedOrgName,
              isClosed: state.blockedErrorCode == IamBlockedCodes.tenantClosed,
              onAction: () => _openSelector(context),
            ),
          ),
        ),
      );
    }
```
Áp cùng cách cho nhánh `loading/initial` (`SafeArea(child: Center(child: VLoading()))`) và nhánh `failure`. Không thêm `VAppBar` cho trạng thái bị chặn — khi tổ chức bị chặn thì tiêu đề tab không còn ý nghĩa.
3. **5e — chừa tab Khác.** Nhánh `isBlocked` **không** áp cho `DashboardTab.more`; tab này vẫn trả `const MorePage()`. Nếu chặn cả tab Khác thì người dùng không đăng xuất được và mắc kẹt trong app (nhất là khi họ chỉ thuộc đúng tổ chức đang bị chặn). Cấu trúc:
```dart
  Widget _buildBody(BuildContext context, TenantContextState state) {
    // Tab "Khác" luôn mở: chứa Đăng xuất + Tài khoản của tôi.
    if (_currentTab != DashboardTab.more) {
      if (state.status == TenantContextLoadStatus.loading ||
          state.status == TenantContextLoadStatus.initial) { … }
      if (state.isBlocked) { … }
      if (state.status == TenantContextLoadStatus.failure) { … }
    }

    switch (_currentTab) { … }
  }
```
4. Kết quả: 4 tab Trang chủ / Đơn hàng / Sản phẩm / KH & NCC hiện `OrganizationEmptyView`; tab Khác vẫn mở với các mục thuộc tổ chức bị làm mờ (Step 4b).
5. **5g — sửa điều kiện `BlocListener`.** Thay:
```dart
      listenWhen: (previous, current) =>
          previous.status == TenantContextLoadStatus.ready && current.isBlocked,
```
bằng:
```dart
      // bootstrap() phát loading trước blocked → không so với `ready`.
      listenWhen: (previous, current) => !previous.isBlocked && current.isBlocked,
```
Trong `listener`, ngoài `context.goNamed('dashboard', extra: DashboardTab.home)`, hiện thêm toast để người dùng hiểu vì sao màn hình đổi:
```dart
        VToast.show(
          context,
          title: 'Tổ chức không thể truy cập',
          message: state.blockedErrorCode == IamBlockedCodes.tenantClosed
              ? 'Tổ chức đã đóng.'
              : 'Tổ chức đang bị tạm ngừng.',
          type: VToastType.danger,
        );
```
Test: cubit đang `ready` → nhận tín hiệu → chuỗi state `loading` rồi `blocked`; widget test kiểm tra `listenWhen` đúng (vd dùng `TenantContextState` giả lập 2 lần emit) và listener chạy **một lần**.

- [ ] **Step 4b: `more_page.dart` — làm mờ mục thuộc tổ chức (5e)**
1. `_MoreView` đọc trạng thái chặn: `final blocked = context.watch<TenantContextCubit>().state.isBlocked;` (tab Khác nằm trong `BlocProvider` của dashboard nên đọc được; nếu `MorePage` được dùng ở nơi không có cubit thì nhận qua tham số `bool tenantBlocked = false` và dashboard truyền vào).
2. Trong danh sách `menuItems` ([more_page.dart:82](../../../apps/erp/lib/features/more/presentation/pages/more_page.dart)), **làm mờ** (không ẩn) các mục thuộc tổ chức khi `blocked`:
   - "Giá riêng / Nhớ giá": `onTap: blocked ? null : () => context.push('/pricing')`.
   - "Người dùng & vai trò": tương tự (giữ điều kiện `access.canOpenIamHub`).
   - "Thiết lập": tương tự.
   - 4 mục đang `enabled: false` (Khách hàng & NCC, Đơn nhập, Kho, Báo cáo): để nguyên.
   - `_MoreMenuItem`/`_Item` đã có `enabled` và tự vô hiệu `onTap` khi `onTap == null` ([more_page.dart:177](../../../apps/erp/lib/features/more/presentation/pages/more_page.dart)) — dùng lại, **không** tự vẽ kiểu mờ mới.
3. **Giữ hoạt động bình thường**: "Tài khoản của tôi" và "Đăng xuất".
4. Khi `blocked`, thêm một dòng giải thích phía trên danh sách: `Tổ chức đang tạm ngừng. Chỉ còn các mục thuộc tài khoản cá nhân.` (nếu `blockedErrorCode == IamBlockedCodes.tenantClosed` thì đổi thành `Tổ chức đã đóng. …`).
5. Test: thêm widget test dựng `MorePage` với cubit ở state `blocked` → "Đăng xuất" và "Tài khoản của tôi" còn bấm được; "Thiết lập", "Giá riêng / Nhớ giá", "Người dùng & vai trò" bị vô hiệu.

- [ ] **Step 4b2: bỏ gọi RPC theo tổ chức ở tab Khác khi bị chặn (5h)**

`MorePage` đã có `tenantBlocked` (Step 4b) → dùng luôn cờ này:
1. Trong `MorePage.build`, **không** gọi `load()` khi bị chặn:
```dart
    return BlocProvider(
      create: (_) {
        final cubit = IamFeatureAccessCubit(iamModule: iamModule ?? getIt<IIamModule>());
        // Tổ chức bị chặn: mọi RPC theo tổ chức đều bị từ chối → không gọi.
        if (!tenantBlocked) cubit.load();
        return cubit;
      },
      child: _MoreView(onLogout: _logout, tenantBlocked: tenantBlocked),
    );
```
2. Hệ quả: `access.canOpenIamHub` là `false` → mục "Người dùng & vai trò" **bị ẩn**, khác quyết định "làm mờ". Để nhất quán, khi `blocked` thì **luôn dựng** mục này ở dạng vô hiệu:
```dart
          if (access.canOpenIamHub || blocked)
            _MoreMenuItem(
              icon: VIcons.people,
              title: 'Người dùng & vai trò',
              subtitle: 'Quản lý thành viên và quyền truy cập',
              onTap: blocked ? null : () => context.push('/more/users-and-roles'),
            ),
```
3. Không sửa `IamFeatureAccessCubit` (giữ nguyên để các nơi khác dùng lại).
4. Test: widget test `MorePage(tenantBlocked: true)` với fake module đếm số lần gọi query → **không** có `GetCurrentSessionQuery` / `GetTenantReadinessQuery`; mục "Người dùng & vai trò" vẫn hiện nhưng vô hiệu.

- [ ] **Step 4c: `my_account_page.dart` — nhãn "Chủ sở hữu" (5f)**

Nguồn dữ liệu: **`ListAccessibleTenantsQuery`** → `AccessibleTenantDto.isOwner`. `MyIdentityProfileDto` không có `isOwner`; **không dùng** `SessionDto.isOwner` vì nó theo tổ chức đang chọn, sẽ thành `false` khi tổ chức bị chặn hoặc chưa chọn tổ chức.

**Chốt (user 2026-09-18):** trang "Tài khoản của tôi" **không phụ thuộc tổ chức**, nên badge **luôn hiện** khi người dùng là chủ sở hữu của **ít nhất một** tổ chức — kể cả khi tổ chức đó đang bị tạm ngừng hoặc đã đóng.

1. `MyAccountState` ([bloc/my_account_state.dart](../../../apps/erp/lib/features/iam/presentation/users/bloc/my_account_state.dart)): thêm `final bool isOwner;` (mặc định `false`) + tham số trong `copyWith`.
2. `MyAccountCubit.load()`: sau khi lấy `MyIdentityProfileDto`, gọi thêm
```dart
      var isOwner = false;
      try {
        final tenants = await _iamModule.executeQueryAsync<List<AccessibleTenantDto>>(
          ListAccessibleTenantsQuery(),
        );
        isOwner = tenants.any((t) => t.isOwner);
      } catch (_) {
        // Không chặn trang cá nhân nếu danh sách tổ chức lỗi.
      }
```
rồi `emit(state.copyWith(status: success, profile: profile, isOwner: isOwner, clearFailure: true))`. Kiểm tra kiểu trả về thực tế của query (có thể là `CursorPageDto` hoặc `List`) và dùng đúng kiểu.
3. `MyAccountUiModel` ([my_account_page.dart:15](../../../apps/erp/lib/features/iam/presentation/users/views/my_account_page.dart)): thêm `final bool isOwner;` (mặc định `false`), tham số constructor, và `MyAccountUiModel.fromDto(dto, {bool isOwner = false})`; chỗ dựng model từ state truyền `isOwner: state.isOwner`. `sample` giữ `isOwner: false`.
4. Trong `VCard` đầu trang, ngay sau `VText` tên (dòng `data.hasName ? data.fullName : '(chưa có tên)'`), thêm badge theo **đúng mẫu đã có** ở [member_card.dart:52](../../../apps/erp/lib/features/iam/presentation/users/widgets/member_card.dart):
```dart
                      if (data.isOwner) ...[
                        const VGap.xs(),
                        const VBadge(
                          label: 'Chủ sở hữu',
                          tone: VComponentTone.success,
                          variant: VBadgeVariant.soft,
                          isSmall: true,
                        ),
                      ],
```
(Đặt trong `Column` của thẻ, trước dòng "Tài khoản cá nhân"; nếu muốn badge nằm cùng hàng với tên thì bọc tên trong `Row` + `Flexible` như `member_card.dart` — chọn một cách, không sửa layout khác.)
5. Test: widget test dựng `_MyAccountScaffold` (hoặc `MyAccountPage` với cubit fake) 2 trường hợp — `isOwner: true` → tìm thấy `VBadge` "Chủ sở hữu"; `isOwner: false` → `findsNothing`.

6. Test thêm: state `blocked` (tổ chức đang tạm ngừng) mà `isOwner: true` → badge **vẫn hiện**.

- [ ] **Step 5: Chạy test + analyze**
- `cd apps/erp && flutter test test/features/tenant_context` → PASS.
- `cd apps/erp && flutter analyze lib/features/tenant_context lib/features/dashboard` → không lỗi mới.

- [ ] **Step 6: Dừng — user build lại app + smoke test**

Với tổ chức đang bị tạm ngừng (không cần reset DB):
1. Bấm 4 tab Trang chủ / Đơn hàng / Sản phẩm / KH & NCC → tab nào cũng hiện "Tổ chức không thể truy cập" + tên tổ chức; **không** còn lỗi "Không tải được danh sách" hay `PostgrestException`. Thẻ chặn **không** dính lên vùng tai thỏ / status bar (kiểm tra 5d).
1b. Tab **Khác** vẫn mở: "Đăng xuất" và "Tài khoản của tôi" bấm được; "Thiết lập", "Giá riêng / Nhớ giá", "Người dùng & vai trò" bị làm mờ, bấm không vào. Đăng xuất thành công → về màn đăng nhập (kiểm tra 5e). Trong log **không** còn dòng `SEVERE` `get_tenant_readiness → TENANT_SUSPENDED` khi mở tab này (kiểm tra 5h).
1c. Đăng nhập bằng **chủ sở hữu** → Khác → Tài khoản của tôi → thẻ đầu trang có badge "Chủ sở hữu". Badge **vẫn hiện** khi tổ chức đang bị tạm ngừng / đã đóng. Đăng nhập bằng staff → **không** có badge (kiểm tra 5f).
2. Header hiện "Chọn tổ chức", không còn tên tổ chức cũ.
3. **Đang ở trang con khi bị tạm ngừng (kiểm tra 5g) — thử đủ các nhóm sau**, mỗi lần: tạm ngừng tổ chức trong app admin rồi thao tác một việc có gọi server:

| Nơi đang đứng | Thao tác gây gọi server |
|---|---|
| Đơn hàng → chi tiết đơn | Kéo làm mới, mở tab thanh toán |
| Đơn hàng → tạo đơn (đang nhập) | Tìm sản phẩm, tính giá, lưu nháp |
| Sản phẩm → chi tiết / tạo sản phẩm | Kéo làm mới, lưu sản phẩm, sửa tồn kho |
| KH & NCC → thêm khách hàng (đang nhập) | Gõ tên hoặc SĐT (chạy `check_duplicate`) |
| Khác → Giá riêng / Nhớ giá | Mở danh sách, thử lại |
| Khác → Người dùng & vai trò | Mở danh sách thành viên |
| Khác → Thiết lập → Sản phẩm / HĐĐT | Mở trang con |

Kết quả đúng cho **tất cả**: hiện toast rồi quay về dashboard với màn chặn; **không** còn đứng im ở form, không lặp lỗi `TENANT_SUSPENDED` trong log, không hiện lỗi thô.

Vì tín hiệu được phát ở `SupabaseSchemaRpcClient` (mọi module dùng chung), không cần sửa gì trong Sales/Catalog/Partner/Pricing.

3b. Trang **cá nhân** thì không bị đá ra: đang ở Khác → Tài khoản của tôi khi bị tạm ngừng → vẫn xem và sửa được hồ sơ cá nhân, vì trang này chỉ gọi RPC theo tài khoản, không theo tổ chức.
4. Đóng tổ chức → màn chặn hiện "… đã đóng. …" (kiểm tra 5c).
5. Khôi phục → chọn lại tổ chức → 5 tab dùng bình thường.

**Ngoài phạm vi (đề xuất tách việc riêng):** module Catalog in nguyên `PostgrestException` ra UI (ảnh tab Sản phẩm). Sau Task 5 người dùng không thấy nữa, nhưng vẫn nên map lỗi ở tầng Catalog để không lộ lỗi kỹ thuật ở các luồng khác.
