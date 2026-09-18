# IAM refactor — 01b Đóng tổ chức (close tenant) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Thêm thao tác **Đóng tổ chức** end-to-end: RPC `iam.close_platform_tenant`, command Dart, gateway, fake module, nút + sheet xác nhận trên app admin. `closed` là trạng thái terminal.

**Architecture:** Làm theo khuôn `suspend_platform_tenant` (cùng file owner `20260811011`, cùng mẫu command/handler/validator/gateway/cubit). Ghi bộ cột trạng thái chung của plan 1 (`status_changed_at/by`, `status_reason`). Không chạm membership, lời mời, store.

**Tech Stack:** PostgreSQL/Supabase plpgsql; Dart `package:test`; `build_runner` (IAM infrastructure); Flutter admin.

**Spec:** [01-tenants.md §4.1, §5](../specs/iam-schema-refactor/01-tenants.md#5-tính-năng-đóng-tenant-làm-trong-đợt-này) · Quy ước: [README §Quy ước implement](../specs/iam-schema-refactor/README.md#quy-ước-implement-sửa-trực-tiếp-migration-gốc)

## Quyết định nghiệp vụ (đã chốt)

| # | Điểm | Quyết định |
|---|---|---|
| 1 | Nguồn | Chỉ `active`, `suspended` → khác: `TENANT_STATE_INVALID` |
| 2 | Membership | Giữ nguyên |
| 3 | Lời mời pending | Giữ nguyên |
| 4 | Lý do | Bắt buộc → `status_reason` |
| 5 | Xác nhận | Sheet có ô lý do; nút **Đóng tổ chức** chỉ bật khi lý do không rỗng |
| 6 | Mở lại | Không |
| 7 | Idempotency | `expected_version` + `idempotency_key` (ghi `tracking_id`); gọi lại cùng key sau khi đã đóng → trả thành công, không ghi audit lần 2 |

## Global Constraints

- **Chạy sau plan 1** (cần cột `status_changed_at/by`, `status_reason`; `get_platform_tenant` đã trả `closed_*` tính từ cột chung). Độc lập với plan 2–14.
- Chữ ký RPC mới: `iam.close_platform_tenant(p_tenant_id uuid, p_reason text, p_expected_version integer, p_idempotency_key text) returns void`.
- Quyền: `platform.tenant.close` (hiện `has_platform_permission` cho mọi platform admin toàn quyền `platform.*` → không cần seed).
- Audit: `iam.tenant.closed`, category `organization`.
- GitNexus `impact` trước khi sửa symbol Dart (`IPlatformAdminGateway`, `FakeIamModule`, `OrganizationActionsBottomSheet`, `OrganizationDetailPage`, `PlatformTenantDetailCubit`). SQL: GitNexus không index → quét text.
- Không `dart format` cả package; chỉ format file đã sửa. Không `git commit` — cuối mỗi task tóm tắt + đề xuất commit rồi dừng.

## File Structure

| File | Thay đổi |
|---|---|
| Modify `supabase/migrations/20260811011_iam_platform_tenant_lifecycle.sql` | Thêm `close_platform_tenant` + grant; `-- Touches:` |
| Modify `supabase/migrations/20260826004_iam_audit_logs_v2_rebuild.sql` | `_audit_event_category`: thêm `iam.tenant.closed` |
| Create `modules/iam/infrastructure/test/iam_refactor_01b_close_tenant_sql_contract_test.dart` | SQL contract test |
| Modify `modules/iam/domain/lib/src/iam_platform_permissions.dart` | `tenantClose` |
| Modify `modules/iam/application/lib/src/shared/iam_audit_events.dart` | `tenantClosed` + `all` |
| Modify `modules/iam/application/test/iam_audit_event_mapping_test.dart` | 19 → 20, contains |
| Create `modules/iam/application/lib/src/platform/commands/close_platform_tenant/close_platform_tenant_command{,_handler,_validator}.dart` | Command mới |
| Modify `modules/iam/application/lib/application.dart` | export 3 file |
| Modify `modules/iam/application/lib/src/ports/i_platform_admin_gateway.dart` | `closePlatformTenant` |
| Modify `modules/iam/application/test/support/stub_platform_admin_gateway.dart` | stub |
| Modify `modules/iam/infrastructure/lib/src/domain/platform/supabase_platform_admin_gateway.dart` | gọi RPC |
| Modify `modules/iam/application/lib/src/testing/fake_iam_module.dart` | `_handleCloseTenant` |
| Modify `modules/iam/application/test/scn_e02_u06_u08_u09_platform_tenants_test.dart` | test handler + validator |
| Regenerate `modules/iam/infrastructure/lib/src/configuration/processing/generated/*.g.dart` | build_runner |
| Modify `apps/admin/lib/features/organizations/presentation/bloc/platform_tenant_detail_cubit.dart` | `close({reason})` |
| Modify `apps/admin/test/features/organizations/presentation/bloc/platform_tenant_detail_cubit_test.dart` | test `close` |
| Create `apps/admin/lib/features/iam/presentation/organizations/widgets/organization_close_confirmation_bottom_sheet.dart` | Sheet xác nhận |
| Modify `apps/admin/lib/features/iam/presentation/organizations/widgets/organization_actions_bottom_sheet.dart` | Mục "Đóng tổ chức" |
| Modify `apps/admin/lib/features/iam/presentation/organizations/views/organization_detail_page.dart` | `onCloseConfirmed` + `_showCloseConfirmation` |
| Modify `apps/admin/lib/features/organizations/presentation/pages/platform_tenant_detail_page.dart` | nối cubit |
| Modify `apps/admin/lib/features/iam/presentation/audit_logs/catalog/tenant_audit_event_catalog.dart` | entry `tenantClosed` |
| Modify `apps/admin/lib/features/audit/presentation/mappers/platform_audit_ui_mapper.dart` | nhãn "Đóng tổ chức" |
| Modify `docs/superpowers/specs/iam-schema-refactor/README.md` | Tiến độ |

---

### Task 1: SQL — RPC `close_platform_tenant` + audit category

**Files:** `20260811011_iam_platform_tenant_lifecycle.sql`, `20260826004_iam_audit_logs_v2_rebuild.sql`, test mới.

- [ ] **Step 1: Viết test (fail)** — `modules/iam/infrastructure/test/iam_refactor_01b_close_tenant_sql_contract_test.dart`

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract tests — IAM refactor 01b close tenant
/// (docs/superpowers/specs/iam-schema-refactor/01-tenants.md §5).
void main() {
  final root = _findRepoRoot().path;
  String readMigration(String name) =>
      File('$root/supabase/migrations/$name').readAsStringSync();

  String lastFunctionBlock(String sql, String qualifiedName) {
    final start = sql.lastIndexOf('create or replace function $qualifiedName(');
    expect(start, isNot(-1), reason: '$qualifiedName not found');
    final bodyStart = sql.indexOf(r'as $$', start);
    final end = sql.indexOf(r'$$;', bodyStart + 5);
    return sql.substring(start, end);
  }

  group('close_platform_tenant', () {
    final sql = readMigration('20260811011_iam_platform_tenant_lifecycle.sql');
    final body = lastFunctionBlock(sql, 'iam.close_platform_tenant');

    test('header touches the new function', () {
      expect(sql, contains('-- Touches: iam.suspend_platform_tenant, iam.restore_platform_tenant, iam.close_platform_tenant'));
    });

    test('signature, permission and grants', () {
      expect(body, contains('p_tenant_id uuid,'));
      expect(body, contains('p_reason text,'));
      expect(body, contains('p_expected_version integer,'));
      expect(body, contains('p_idempotency_key text'));
      expect(body, contains("iam.has_platform_permission('platform.tenant.close')"));
      expect(sql, contains('revoke all on function iam.close_platform_tenant(uuid, text, integer, text) from public, anon;'));
      expect(sql, contains('grant execute on function iam.close_platform_tenant(uuid, text, integer, text) to authenticated;'));
    });

    test('reason and idempotency key are required', () {
      expect(body, contains("if p_reason is null or trim(p_reason) = '' then"));
      expect(body, contains("if p_idempotency_key is null or trim(p_idempotency_key) = '' then"));
    });

    test('only active or suspended can be closed', () {
      expect(body, contains("if v_status not in ('active', 'suspended') then"));
      expect(body, contains("raise exception 'TENANT_STATE_INVALID'"));
    });

    test('replay with same key after close returns without side effects', () {
      expect(body, contains("event_code = 'iam.tenant.closed'"));
      expect(body, contains('tracking_id = trim(p_idempotency_key)'));
    });

    test('writes shared status columns, not legacy closed_* columns', () {
      expect(body, contains("set status = 'closed'"));
      expect(body, contains('status_changed_at = now()'));
      expect(body, contains('status_changed_by = v_actor'));
      expect(body, contains('status_reason = trim(p_reason)'));
      expect(body, contains('version = version + 1'));
      expect(body, isNot(matches(RegExp(r'\b(closed_at|close_reason|closed_by)\b'))));
    });

    test('does not touch memberships, invitations or stores', () {
      expect(body, isNot(contains('iam.memberships')));
      expect(body, isNot(contains('iam.tenant_invitations')));
      expect(body, isNot(contains('iam.stores')));
    });

    test('appends iam.tenant.closed audit with reason', () {
      expect(body, contains("p_event_code => 'iam.tenant.closed'"));
      expect(body, contains("'reason', trim(p_reason)"));
    });
  });

  test('audit category registers iam.tenant.closed as organization', () {
    final sql = readMigration('20260826004_iam_audit_logs_v2_rebuild.sql');
    final body = lastFunctionBlock(sql, 'iam._audit_event_category');
    expect(body, contains("'iam.tenant.restored',\n         'iam.tenant.closed',"));
  });
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

- [ ] **Step 2: Chạy test, xác nhận fail**

Run: `cd modules/iam/infrastructure && dart test test/iam_refactor_01b_close_tenant_sql_contract_test.dart`
Expected: FAIL (`iam.close_platform_tenant not found`).

- [ ] **Step 3: Sửa `20260811011_iam_platform_tenant_lifecycle.sql`**

1. Header: `-- Touches: iam.suspend_platform_tenant, iam.restore_platform_tenant, iam.close_platform_tenant`
2. Cuối file (sau grant của `restore_platform_tenant`) thêm:

```sql

create or replace function iam.close_platform_tenant(
  p_tenant_id uuid,
  p_reason text,
  p_expected_version integer,
  p_idempotency_key text
)
returns void
language plpgsql
security definer
set search_path = iam, pg_temp
as $$
declare
  v_actor uuid := auth.uid();
  v_status text;
  v_version int;
begin
  if not iam.has_platform_permission('platform.tenant.close') then
    raise exception 'PLATFORM_PERMISSION_DENIED';
  end if;

  if p_reason is null or trim(p_reason) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;
  if p_idempotency_key is null or trim(p_idempotency_key) = '' then
    raise exception 'VALIDATION_ERROR';
  end if;

  select status, version
    into v_status, v_version
  from iam.tenants
  where id = p_tenant_id
  for update;

  if v_status is null then
    raise exception 'RESOURCE_NOT_FOUND';
  end if;

  -- Replay: same key already closed this tenant → success, no second audit.
  if v_status = 'closed' and exists (
    select 1
    from iam.audit_logs a
    where a.tenant_id = p_tenant_id
      and a.event_code = 'iam.tenant.closed'
      and a.tracking_id = trim(p_idempotency_key)
  ) then
    return;
  end if;

  if v_status not in ('active', 'suspended') then
    raise exception 'TENANT_STATE_INVALID';
  end if;
  if v_version is distinct from p_expected_version then
    raise exception 'STATE_CHANGED';
  end if;

  update iam.tenants
  set status = 'closed',
      status_changed_at = now(),
      status_changed_by = v_actor,
      status_reason = trim(p_reason),
      updated_at = now(),
      version = version + 1
  where id = p_tenant_id
    and version = p_expected_version;
  if not found then
    raise exception 'STATE_CHANGED';
  end if;

  perform iam.append_audit_log(
    p_scope => 'platform',
    p_tenant_id => p_tenant_id,
    p_actor_user_id => v_actor,
    p_event_code => 'iam.tenant.closed',
    p_subject_type => 'tenant',
    p_subject_id => p_tenant_id::text,
    p_result => 'success',
    p_source => 'admin',
    p_tracking_id => trim(p_idempotency_key),
    p_before => jsonb_build_object('status', v_status, 'version', p_expected_version),
    p_after => jsonb_build_object(
      'status', 'closed',
      'reason', trim(p_reason),
      'version', p_expected_version + 1
    )
  );
end;
$$;

revoke all on function iam.close_platform_tenant(uuid, text, integer, text) from public, anon;
grant execute on function iam.close_platform_tenant(uuid, text, integer, text) to authenticated;
```

> Kiểm tra khi implement: tên cột `iam.audit_logs.tenant_id` / `event_code` / `tracking_id` khớp bảng sau plan 13 (`20260826004`: `tracking_id text` ở dòng ~36). Nếu `tenants.status`/`version` không còn nullable sau plan 1 thì bỏ `coalesce` là đúng; nếu còn nullable, dùng `coalesce(status, 'active')`, `coalesce(version, 1)` như suspend.

- [ ] **Step 4: Sửa `20260826004_iam_audit_logs_v2_rebuild.sql`** — trong `iam._audit_event_category`, nhóm `organization`, sau `'iam.tenant.restored',` thêm dòng `         'iam.tenant.closed',`.

- [ ] **Step 5: Registry + policy**
- `dart run tools/vet45_supabase_migrate/bin/seed_registry.dart --write` → `REGISTRY.yaml` có `close_platform_tenant: 20260811011_iam_platform_tenant_lifecycle.sql`
- `dart run tools/vet45_supabase_migrate/bin/verify_migration_policy.dart --strict` → OK

- [ ] **Step 6: Chạy test** — `cd modules/iam/infrastructure && dart test test/iam_refactor_01b_close_tenant_sql_contract_test.dart test/iam_audit_producer_sql_contract_test.dart test/iam_audit_logs_v2_schema_sql_contract_test.dart` → PASS (nếu test cũ đếm số event trong `_audit_event_category`, cập nhật số).

- [ ] **Step 7: Dừng** — tóm tắt. Đề xuất commit: `feat(iam): add close_platform_tenant rpc and iam.tenant.closed audit category`.

---

### Task 2: Dart application + infrastructure

- [ ] **Step 1: GitNexus impact** — `IPlatformAdminGateway`, `FakeIamModule`, `IamAuditEvents` (upstream). Báo caller/risk.

- [ ] **Step 2: Viết test (fail)**

a) `modules/iam/application/test/iam_audit_event_mapping_test.dart`: `hasLength(19)` → `hasLength(20)` (2 chỗ); thêm `expect(IamAuditEvents.all, contains('iam.tenant.closed'));`.

b) `modules/iam/application/test/scn_e02_u06_u08_u09_platform_tenants_test.dart`:
- `_RecordingGateway` thêm field `String? closeTenantId; String? closeReason; String? closeKey;` và override:
```dart
  @override
  Future<void> closePlatformTenant({
    required String tenantId,
    required String reason,
    required int expectedVersion,
    required String idempotencyKey,
  }) async {
    closeTenantId = tenantId;
    closeReason = reason;
    closeKey = idempotencyKey;
    lastExpectedVersion = expectedVersion;
  }
```
- Thêm trong group:
```dart
    test('close passes reason + version + idempotencyKey', () async {
      final gateway = _RecordingGateway();
      await ClosePlatformTenantCommandHandler(platformGateway: gateway).handle(
        ClosePlatformTenantCommand(
          tenantId: 't-1',
          reason: 'Kết thúc hợp đồng',
          expectedVersion: 5,
          idempotencyKey: 'k-close',
        ),
      );
      expect(gateway.closeTenantId, 't-1');
      expect(gateway.closeReason, 'Kết thúc hợp đồng');
      expect(gateway.closeKey, 'k-close');
      expect(gateway.lastExpectedVersion, 5);
    });

    test('close validator requires reason', () async {
      expect(
        () => ClosePlatformTenantCommandValidator().validate(
          ClosePlatformTenantCommand(
            tenantId: 't-1',
            reason: '  ',
            expectedVersion: 1,
            idempotencyKey: 'k',
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
```
(nếu file chưa import `vet45_shared_application` cho `ValidationException`, thêm import).

c) `modules/iam/application/test/fake_iam_module_test.dart`: thêm test theo mẫu test suspend sẵn có — đóng tenant `active` → `GetPlatformTenantQuery` trả `status == closed`, `closeReason` đúng, `version + 1`; đóng tenant `closed` → `IamBlockedException(tenantStateInvalid)`; tenant `provisioning` → `tenantStateInvalid`.

Run: `cd modules/iam/application && dart test test/iam_audit_event_mapping_test.dart test/scn_e02_u06_u08_u09_platform_tenants_test.dart test/fake_iam_module_test.dart` → FAIL (compile).

- [ ] **Step 3: Domain + event code**
- `iam_platform_permissions.dart`: sau `tenantRestore` thêm `static const tenantClose = 'platform.tenant.close';`
- `iam_audit_events.dart`: sau `tenantRestored` thêm `static const tenantClosed = 'iam.tenant.closed';` và thêm `tenantClosed,` vào `all` sau `tenantRestored,`.

- [ ] **Step 4: Command** — tạo thư mục `modules/iam/application/lib/src/platform/commands/close_platform_tenant/`:

`close_platform_tenant_command.dart`
```dart
import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

/// Close a Platform Tenant permanently (terminal). Requires a reason.
@RequiresPermission(IamPlatformPermissions.tenantClose)
@Idempotent(keyField: 'idempotencyKey')
final class ClosePlatformTenantCommand extends CommandBase<void>
    implements ICommand<void> {
  ClosePlatformTenantCommand({
    String? id,
    required this.tenantId,
    required this.reason,
    required this.expectedVersion,
    required this.idempotencyKey,
  }) : super(id);

  final String tenantId;
  final String reason;
  final int expectedVersion;
  final String idempotencyKey;
}
```

`close_platform_tenant_command_handler.dart`
```dart
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_platform_admin_gateway.dart';
import 'close_platform_tenant_command.dart';

@CommandHandlerFor(ClosePlatformTenantCommand)
final class ClosePlatformTenantCommandHandler
    implements ICommandHandler<ClosePlatformTenantCommand, void> {
  ClosePlatformTenantCommandHandler({
    required IPlatformAdminGateway platformGateway,
  }) : _platformGateway = platformGateway;

  final IPlatformAdminGateway _platformGateway;

  @override
  Future<void> handle(ClosePlatformTenantCommand command) {
    return _platformGateway.closePlatformTenant(
      tenantId: command.tenantId,
      reason: command.reason,
      expectedVersion: command.expectedVersion,
      idempotencyKey: command.idempotencyKey,
    );
  }
}
```

`close_platform_tenant_command_validator.dart`
```dart
import 'package:vet45_shared_application/application.dart';

import 'close_platform_tenant_command.dart';

final class ClosePlatformTenantCommandValidator
    implements ICommandValidator<ClosePlatformTenantCommand> {
  @override
  Future<void> validate(ClosePlatformTenantCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required');
    }
    if (command.reason.trim().isEmpty) {
      throw ValidationException('Close reason is required');
    }
    if (command.idempotencyKey.trim().isEmpty) {
      throw ValidationException('Idempotency key is required');
    }
  }
}
```

`application.dart`: thêm 3 export (theo thứ tự alphabet, trước khối `create_tenant_onboarding`).

- [ ] **Step 5: Port + stub + Supabase gateway**
- `i_platform_admin_gateway.dart` sau `restorePlatformTenant`:
```dart

  Future<void> closePlatformTenant({
    required String tenantId,
    required String reason,
    required int expectedVersion,
    required String idempotencyKey,
  });
```
- `stub_platform_admin_gateway.dart`: override tương tự trả `async => throw UnimplementedError();`
- `supabase_platform_admin_gateway.dart`: sao chép thân `suspendPlatformTenant` (giữ nguyên khối `try/catch` map lỗi), đổi tên RPC thành `'close_platform_tenant'`.

- [ ] **Step 6: Fake module** — `fake_iam_module.dart`:
- import `close_platform_tenant_command.dart`;
- trong switch command, sau dòng `RestorePlatformTenantCommand c => …`: `ClosePlatformTenantCommand c => _handleCloseTenant<TResult>(c),`
- thêm `_handleCloseTenant` sau `_handleRestoreTenant`: giống `_handleSuspendTenant` nhưng
  - lý do rỗng → `ValidationException('Close reason is required')`;
  - `tenant.status` không phải `active`/`suspended` (hoặc scenario `tenantClosedReject`) → `IamBlockedException(IamBlockedCodes.tenantStateInvalid)`;
  - DTO mới: `status: TenantLifecycleStatus.closed`, `version + 1`, `closedAt: now`, `closedBy: 'Nhân viên vận hành nền tảng'`, `closeReason: command.reason`, giữ `members`, `activatedAt`; `suspendedAt/suspendReason` = null.

- [ ] **Step 7: Codegen** — `cd modules/iam/infrastructure && dart run build_runner build --delete-conflicting-outputs`. Kiểm tra `iam_cqrs_registrar.g.dart` có `ClosePlatformTenantCommandValidator.new` + `registerBusinessHandler<ClosePlatformTenantCommand, …>`; `iam_module_manifest.g.dart` / `iam_access_metadata.g.dart` có `platform.tenant.close`.

- [ ] **Step 8: Chạy test**
- `cd modules/iam/application && dart test` → PASS (trừ baseline README)
- `cd modules/iam/infrastructure && dart test` → PASS (trừ baseline README)
- `dart analyze modules/iam` → không lỗi mới

- [ ] **Step 9: Dừng** — tóm tắt. Đề xuất commit: `feat(iam): add ClosePlatformTenantCommand, gateway and fake support`.

---

### Task 3: Admin app — nút Đóng tổ chức

- [ ] **Step 1: GitNexus impact** — `PlatformTenantDetailCubit`, `OrganizationDetailPage`, `OrganizationActionsBottomSheet`.

- [ ] **Step 2: Test cubit (fail)** — `apps/admin/test/features/organizations/presentation/bloc/platform_tenant_detail_cubit_test.dart`: theo mẫu test `suspend` sẵn có, thêm:
  - `close(reason: '  ')` → trả `false`, `errorMessage == 'Vui lòng nhập lý do đóng tổ chức.'`, không gọi command;
  - `close(reason: 'Hết hợp đồng')` với fake module tenant `active` → `true`, sau `load()` `state.organization!.status == OrganizationStatus.closed`.

Run: `cd apps/admin && flutter test test/features/organizations/presentation/bloc/platform_tenant_detail_cubit_test.dart` → FAIL.

- [ ] **Step 3: Cubit** — `platform_tenant_detail_cubit.dart`: thêm `close({required String reason})` sao chép `suspend`, khác:
  - message rỗng: `'Vui lòng nhập lý do đóng tổ chức.'`
  - command `ClosePlatformTenantCommand(...)`, key `'close-$tenantId-${DateTime.now().microsecondsSinceEpoch}'`.

- [ ] **Step 4: Sheet xác nhận** — tạo `apps/admin/lib/features/iam/presentation/organizations/widgets/organization_close_confirmation_bottom_sheet.dart`, dựa trên `OrganizationSuspendConfirmationBottomSheet`, khác:
  - Doc comment: `/// Sheet xác nhận Đóng tổ chức (terminal, không khôi phục).`
  - Tiêu đề `'Đóng tổ chức?'`; mô tả `'Tổ chức sẽ ngừng hoạt động vĩnh viễn và không thể khôi phục. Dữ liệu và lịch sử vẫn được giữ để tra cứu.'`
  - Ô lý do: label `'Lý do đóng'`, hint `'Nhập lý do đóng tổ chức'`.
  - **Nút bật/tắt theo lý do** (quyết định 5): state `bool _canSubmit = false`; `onChanged: (v) => setState(() => _canSubmit = v.trim().isNotEmpty)`; nút xác nhận label `'Đóng tổ chức'`, `tone: VComponentTone.danger`, `onPressed: _canSubmit ? _submit : null`.
  - Giữ nút `'Quay lại'`.

> Khi implement: kiểm tra `VButton.onPressed` chấp nhận `null` để hiển thị disabled; nếu không, dùng prop `disabled`/`enabled` của `VButton` trong design system.

- [ ] **Step 5: Bảng thao tác** — `organization_actions_bottom_sheet.dart`:
  - Thêm `final VoidCallback? onCloseTap;` + tham số constructor.
  - Cập nhật doc comment: thêm `- Đang hoạt động / Đã tạm ngừng: Đóng tổ chức (Tone đỏ).`
  - Sau khối `if (isSuspended) … else if (isActive) …`, thêm:
```dart
          if (isActive || isSuspended) ...[
            const VGap.md(),
            _ActionButtonCard(
              title: 'Đóng tổ chức',
              subtitle: 'Ngừng hoạt động vĩnh viễn, không thể khôi phục',
              icon: VIcons.close,
              isDanger: true,
              onTap: () {
                Navigator.of(context).pop();
                onCloseTap?.call();
              },
            ),
          ],
```
  (Kiểm tra `VIcons.close` tồn tại; nếu không, chọn icon có sẵn phù hợp, ví dụ `VIcons.block`.)

- [ ] **Step 6: Trang chi tiết** — `organization_detail_page.dart`:
  - Field + constructor: `/// When set, close uses this callback.` `final Future<bool> Function(String reason)? onCloseConfirmed;`
  - Trong `_handleActionTap`: `onCloseTap: () => _showCloseConfirmation(context),`
  - Thêm `_showCloseConfirmation` theo mẫu `_showSuspendConfirmation` dùng `OrganizationCloseConfirmationBottomSheet`; toast thành công `'Đã đóng tổ chức.'`, lỗi `'Không thể đóng tổ chức. Vui lòng thử lại.'`; nhánh fake (callback null) giữ cùng quy ước `'error'/'lỗi'` như suspend.
  - Import widget mới.

- [ ] **Step 7: Nối cubit** — `platform_tenant_detail_page.dart`: thêm `onCloseConfirmed: (reason) => cubit.close(reason: reason),`.

- [ ] **Step 8: Nhãn audit**
  - `tenant_audit_event_catalog.dart` sau entry `tenantRestored`:
```dart
    IamAuditEvents.tenantClosed: TenantAuditEventCatalogEntry(
      eventCode: IamAuditEvents.tenantClosed,
      title: 'Đóng tổ chức',
      category: TenantAuditEventCategory.organization,
      icon: VIcons.warning,
      searchAliases: ['đóng tổ chức', 'close tenant'],
    ),
```
  - `platform_audit_ui_mapper.dart`: thêm `IamAuditEvents.tenantClosed: 'Đóng tổ chức',` sau `tenantRestored`, và `'platform.tenant.close': 'Đóng tổ chức',` sau `'platform.tenant.restore'`.

- [ ] **Step 9: Chạy test + analyze**
- `cd apps/admin && flutter test` → PASS (so với trước khi sửa)
- `dart analyze apps/admin` → không lỗi mới
- `dart format` chỉ các file đã sửa/tạo.

- [ ] **Step 10: Tiến độ spec** — README dòng "Việc phát sinh" → `✅ Đã chốt · 📝 Plan 01b · 🧪 Đã sửa, chờ reset`.

- [ ] **Step 11: Dừng — user reset + smoke test**

Sau `supabase db reset` (plan 1 đã áp):
1. Admin → tổ chức **đang hoạt động** → Thao tác → **Đóng tổ chức** → nút bị mờ khi chưa nhập lý do → nhập lý do → Đóng → toast thành công, badge "Đã đóng", thẻ thông tin hiện ngày/người/lý do, thanh thao tác ẩn.
2. Lặp lại với tổ chức **đã tạm ngừng**.
3. Tổ chức **đang khởi tạo**: không có mục Đóng (hoặc RPC trả `TENANT_STATE_INVALID`).
4. ERP: thành viên tổ chức vừa đóng → bị đưa ra khỏi tổ chức (`tenantClosed`).
5. Nhật ký quản trị có sự kiện "Đóng tổ chức" kèm lý do.

Đề xuất commit: `feat(admin): close organization action with reason confirmation`.
