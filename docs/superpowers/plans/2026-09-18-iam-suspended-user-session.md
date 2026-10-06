# IAM — Người dùng bị tạm ngừng: đá khỏi phiên + thông báo đúng Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Khi admin tạm ngừng một người dùng lúc họ **đang dùng app**, ERP tự đăng xuất và báo đúng lý do; khi mở lại app với phiên cũ còn hạn cũng báo đúng thay vì "Chưa có tổ chức được cấp quyền".

**Architecture:** Chỉ sửa Dart phía client. Tận dụng `TenantAccessRevokedSignal` đã có: thêm mã `PLATFORM_USER_SUSPENDED`; ERP nhận mã này thì **đăng xuất** (khác tổ chức bị chặn — chỉ rời tổ chức). Thêm nhánh `identityInactive` khi dựng màn chặn.

**Tech Stack:** Dart `package:test`; Flutter `flutter_test`, `flutter_bloc`, `go_router`.

**Spec:** [16-tenant-status-access.md](../specs/iam-schema-refactor/16-tenant-status-access.md) (cùng cơ chế tín hiệu) · Bối cảnh: plan 8 [2026-09-17-iam-refactor-08-owner-flag-checks](2026-09-17-iam-refactor-08-owner-flag-checks.md) đã chặn ở server.

## Hiện trạng (đã có, không sửa)

| Lớp | Hành vi khi user `suspended` |
|---|---|
| `suspend_platform_user` | Đặt `status = 'suspended'`, ghi audit kèm lý do, cấm tự tạm ngừng mình |
| `has_permission`, `has_platform_permission` | trả `false` |
| `get_session_context`, `switch_tenant_context` | ném `PLATFORM_USER_SUSPENDED` |
| `get_tenant_context` | trả `invalidated` + `identityInactive` + `blocked_error_code = PLATFORM_USER_SUSPENDED` |
| Đăng nhập | `LoginAuditAuthenticator` gọi `assert_my_platform_access` → đăng xuất + báo lỗi |
| `IamUiFailureMapper` (ERP + admin) | đã có câu "Tài khoản của bạn đã bị tạm ngừng…" |

## Hai lỗi cần sửa

| # | Lỗi | Nguyên nhân |
|---|---|---|
| A | Đang ở trong app mà bị tạm ngừng → app **không** phản ứng; người dùng gặp lỗi lặt vặt ở từng màn cho tới khi tự thoát | `TenantAccessRevokedSignal.notifyFromError` chỉ nhận `TENANT_SUSPENDED` / `TENANT_CLOSED` |
| B | Mở lại app khi phiên cũ còn hạn → hiện "Chưa có tổ chức được cấp quyền" | `_emitResolvedContext` nhánh `invalidated` chỉ coi `tenantSuspended` / `tenantClosed` là `inaccessible`; `identityInactive` rơi vào nhánh mặc định |

## Quyết định

| # | Điểm | Chốt |
|---|---|---|
| Q1 | Bị tạm ngừng giữa phiên | **Đăng xuất** (không phải chỉ rời tổ chức), vì tài khoản bị chặn ở mọi tổ chức |
| Q2 | Thông báo | Toast "Tài khoản của bạn đã bị tạm ngừng. Vui lòng liên hệ quản trị viên." rồi về màn đăng nhập |
| Q3 | Mở lại app với phiên cũ còn hạn | **Tự đăng xuất ngay khi khởi động** (chốt 2026-09-18): `bootstrap()` thấy tài khoản bị tạm ngừng → toast + đăng xuất + về `/login`, không để người dùng vào app. Màn chặn "Tài khoản bị tạm ngừng" vẫn làm (Task 3) như lớp dự phòng nếu việc đăng xuất thất bại |
| Q4 | App admin | Ngoài phạm vi plan này (admin bị tạm ngừng sẽ bị `has_platform_permission` từ chối; xử lý sau nếu cần) |
| Q5 | Thu hồi phiên Supabase Auth | Vẫn để sau ([16 §4](../specs/iam-schema-refactor/16-tenant-status-access.md)) |

## Global Constraints

- Chỉ sửa Dart; **không** đổi SQL, không cần `supabase db reset`.
- Giữ nguyên hành vi hiện có cho `TENANT_SUSPENDED` / `TENANT_CLOSED` (Task 5 của plan tenant status).
- Không `dart format` cả package; **không `git commit`**.
- Trước khi sửa symbol: GitNexus `impact` (upstream).

## File Structure

| File | Thay đổi |
|---|---|
| Modify `packages/vet45_shared/application/lib/src/access/tenant_access_revoked_signal.dart` + test | Thêm mã `PLATFORM_USER_SUSPENDED` |
| Modify `apps/erp/lib/features/tenant_context/presentation/bloc/tenant_context_cubit.dart` + test | Phân biệt mã; phát ra yêu cầu đăng xuất; nhận `identityInactive` |
| Modify `apps/erp/lib/features/tenant_context/presentation/bloc/tenant_context_state.dart` | (nếu cần) cờ `identityBlocked` |
| Modify `apps/erp/lib/features/iam/presentation/organizations/widgets/organization_empty_view.dart` | Nội dung khi tài khoản bị tạm ngừng + nhãn nút |
| Modify `apps/erp/lib/features/dashboard/presentation/dashboard_page.dart` | Toast + điều hướng `/login` khi là tài khoản bị tạm ngừng |
| Modify `docs/superpowers/specs/iam-schema-refactor/README.md` | Tiến độ |

---

### Task 1: Tín hiệu nhận thêm `PLATFORM_USER_SUSPENDED`

- [x] **Step 1: Test (fail)** — `packages/vet45_shared/application/test/tenant_access_revoked_signal_test.dart`, thêm:
```dart
  test('emits platform user suspended code', () async {
    final events = <String>[];
    final sub = TenantAccessRevokedSignal.stream.listen(events.add);

    TenantAccessRevokedSignal.notifyFromError(
      Exception('PostgrestException(message: PLATFORM_USER_SUSPENDED)'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(events, [TenantAccessRevokedSignal.platformUserSuspended]);
    await sub.cancel();
  });
```
Run: `cd packages/vet45_shared/application && dart test test/tenant_access_revoked_signal_test.dart` → FAIL.

- [ ] **Step 2: Sửa `TenantAccessRevokedSignal`**
```dart
  static const tenantSuspended = 'TENANT_SUSPENDED';
  static const tenantClosed = 'TENANT_CLOSED';
  static const platformUserSuspended = 'PLATFORM_USER_SUSPENDED';

  static void notifyFromError(Object error) {
    final text = error.toString().toUpperCase();
    // Tài khoản bị tạm ngừng ưu tiên cao nhất: chặn ở mọi tổ chức.
    if (text.contains(platformUserSuspended)) {
      _controller.add(platformUserSuspended);
    } else if (text.contains(tenantClosed)) {
      _controller.add(tenantClosed);
    } else if (text.contains(tenantSuspended)) {
      _controller.add(tenantSuspended);
    }
  }
```

- [ ] **Step 3: Chạy test → PASS.** Đề xuất commit: `feat(shared): signal platform user suspension`.

---

### Task 2: ERP đăng xuất khi tài khoản bị tạm ngừng (lỗi A)

- [ ] **Step 1: Test (fail)** — `apps/erp/test/features/tenant_context/presentation/tenant_context_cubit_revoked_signal_test.dart`, thêm:
```dart
  test('suspended account signals sign-out instead of re-bootstrap', () async {
    final revoked = StreamController<String>.broadcast();
    final codes = <String>[];
    final cubit = TenantContextCubit(
      iamModule: FakeIamModule(),
      initialState: const TenantContextState(
        status: TenantContextLoadStatus.ready,
        userDisplayName: '',
      ),
      tenantAccessRevoked: revoked.stream,
      onIdentityRevoked: codes.add,
    );

    revoked.add(TenantAccessRevokedSignal.platformUserSuspended);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(codes, [TenantAccessRevokedSignal.platformUserSuspended]);
    // Không bootstrap lại: state giữ nguyên ready.
    expect(cubit.state.status, TenantContextLoadStatus.ready);

    await cubit.close();
    await revoked.close();
  });
```
Run: `cd apps/erp && flutter test test/features/tenant_context/presentation/tenant_context_cubit_revoked_signal_test.dart` → FAIL.

- [ ] **Step 2: `TenantContextCubit`**
1. Constructor thêm tham số `void Function(String code)? onIdentityRevoked,` và lưu vào field.
2. Đổi handler nhận cả mã:
```dart
    _revokedSubscription = (tenantAccessRevoked ?? TenantAccessRevokedSignal.stream)
        .listen(_onTenantAccessRevoked);

  void _onTenantAccessRevoked(String code) {
    if (isClosed) return;
    if (code == TenantAccessRevokedSignal.platformUserSuspended) {
      // Tài khoản bị chặn ở mọi tổ chức → shell đăng xuất.
      _onIdentityRevoked?.call(code);
      return;
    }
    if (state.status != TenantContextLoadStatus.ready) return;
    bootstrap();
  }
```
3. **Giữ nguyên** `close()` không `await` việc huỷ đăng ký (xem ghi chú cuối plan).

- [ ] **Step 3: `dashboard_page.dart`** — khi dựng `TenantContextCubit`, truyền:
```dart
          onIdentityRevoked: (_) => _handleIdentityRevoked(context),
```
và thêm hàm (tái dùng đúng đoạn đăng xuất ở [app_router.dart:283](../../../apps/erp/lib/core/router/app_router.dart), có thể tách thành helper dùng chung `signOutAndGoToLogin(BuildContext)`):
```dart
  Future<void> _handleIdentityRevoked(BuildContext context) async {
    VToast.show(
      context,
      title: 'Tài khoản bị tạm ngừng',
      message: 'Tài khoản của bạn đã bị tạm ngừng. Vui lòng liên hệ quản trị viên.',
      type: VToastType.danger,
    );
    await getIt<IIamModule>().executeCommandAsync<SignOutResultDto>(SignOutCommand());
    if (!context.mounted) return;
    context.go('/login');
  }
```
Lưu ý: bọc `guard(...)` như các chỗ đăng xuất khác để lỗi mạng không làm kẹt; dù đăng xuất từ xa thất bại vẫn phải `context.go('/login')`.

- [ ] **Step 4: Chạy test** — `cd apps/erp && flutter test test/features/tenant_context` → PASS.

- [ ] **Step 5: Dừng — tóm tắt.** Đề xuất commit: `fix(erp): sign out when the platform account is suspended`.

---

### Task 3: Màn chặn báo đúng lý do tài khoản (lỗi B)

- [ ] **Step 1: Test (fail)** — trong `apps/erp/test/features/tenant_context/presentation/tenant_context_blocked_ui_test.dart` thêm test cubit: `_emitResolvedContext` với `TenantContextDto(status: invalidated, invalidationReason: identityInactive, blockedErrorCode: 'PLATFORM_USER_SUSPENDED')` → `state.emptyStateType == OrganizationEmptyStateType.inaccessible` và `state.blockedErrorCode == IamBlockedCodes.platformUserSuspended`.
(Gọi qua `cubit.bootstrap()` với `FakeIamModule` dựng sẵn trạng thái, hoặc mở `_emitResolvedContext` cho test bằng `@visibleForTesting`.)

- [ ] **Step 1b: Tự đăng xuất ngay khi khởi động (Q3)** — trong `_emitResolvedContext`, nhánh `invalidated`, **trước** khi `emit`:
```dart
        if (context.blockedErrorCode == IamBlockedCodes.platformUserSuspended ||
            context.invalidationReason ==
                TenantContextInvalidationReason.identityInactive) {
          // Tài khoản bị tạm ngừng: không cho vào app, đăng xuất luôn.
          _onIdentityRevoked?.call(IamBlockedCodes.platformUserSuspended);
        }
```
Vẫn `emit` trạng thái `blocked` như bước dưới: nếu đăng xuất thất bại (mất mạng) thì người dùng còn thấy màn chặn đúng lý do, kèm nút Đăng xuất để thử lại.

Test: `bootstrap()` với ngữ cảnh `identityInactive` → callback `onIdentityRevoked` được gọi **một lần** với mã `PLATFORM_USER_SUSPENDED`.

- [ ] **Step 2: `TenantContextCubit._emitResolvedContext`** — nhánh `invalidated`, thêm `identityInactive` vào điều kiện `inaccessible`:
```dart
        final inaccessible =
            context.invalidationReason == TenantContextInvalidationReason.tenantSuspended ||
            context.invalidationReason == TenantContextInvalidationReason.tenantClosed ||
            context.invalidationReason == TenantContextInvalidationReason.identityInactive ||
            context.blockedErrorCode == IamBlockedCodes.tenantSuspended ||
            context.blockedErrorCode == IamBlockedCodes.tenantClosed ||
            context.blockedErrorCode == IamBlockedCodes.platformUserSuspended;
```

- [ ] **Step 3: `organization_empty_view.dart`** — thêm cờ `final bool isAccountSuspended;` (mặc định `false`). Trong `case OrganizationEmptyStateType.inaccessible`, ưu tiên trường hợp tài khoản:
```dart
        title = isAccountSuspended ? 'Tài khoản bị tạm ngừng' : 'Tổ chức không thể truy cập';
        description = isAccountSuspended
            ? 'Tài khoản của bạn đã bị tạm ngừng. Vui lòng liên hệ quản trị viên.'
            : (isClosed
                ? '$orgName đã đóng. Bạn không thể truy cập dữ liệu của tổ chức này.'
                : '$orgName đang tạm ngừng. Bạn không thể truy cập dữ liệu của tổ chức này.');
        actionLabel = isAccountSuspended ? 'Đăng xuất' : 'Chọn tổ chức khác';
```

- [ ] **Step 4: `dashboard_page.dart`** — truyền cờ và đổi hành động nút:
```dart
              final accountSuspended =
                  state.blockedErrorCode == IamBlockedCodes.platformUserSuspended;
              …
              OrganizationEmptyView(
                …
                isAccountSuspended: accountSuspended,
                onAction: accountSuspended
                    ? () => _handleIdentityRevoked(context)
                    : () => _openSelector(context),
              )
```
(Ở nhánh tài khoản bị tạm ngừng thì `_handleIdentityRevoked` chỉ cần đăng xuất; có thể tách toast ra khỏi hàm nếu không muốn hiện lại.)

- [ ] **Step 5: Chạy test + analyze**
- `cd apps/erp && flutter test test/features/tenant_context test/features/more` → PASS.
- `cd apps/erp && flutter analyze lib/features/tenant_context lib/features/dashboard lib/features/iam/presentation/organizations` → không lỗi mới.

- [ ] **Step 6: Tiến độ** — README spec, bảng "Việc phát sinh": thêm dòng *"Người dùng bị tạm ngừng: đá khỏi phiên + thông báo đúng"* trỏ plan này.

- [ ] **Step 7: Dừng — user build lại app + smoke test**

Dùng 2 tài khoản: **Admin** và **A** (staff hoặc owner của một tổ chức đang hoạt động).
1. A đăng nhập ERP, đang ở tab Đơn hàng. Admin tạm ngừng A (có lý do).
2. A kéo làm mới hoặc bấm thao tác bất kỳ → toast "Tài khoản của bạn đã bị tạm ngừng…" → app **đăng xuất** và về màn đăng nhập.
3. A thử đăng nhập lại → bị chặn với cùng thông báo.
4. **Phiên cũ còn hạn:** để A đăng nhập trước, thoát app (không đăng xuất), Admin mới tạm ngừng A, rồi A mở lại app → app **tự đăng xuất** và về màn đăng nhập kèm toast; không vào được dashboard, không còn "Chưa có tổ chức được cấp quyền".
4b. Nếu tắt mạng ngay khi mở lại app (đăng xuất từ xa thất bại) → thấy màn chặn ghi **"Tài khoản bị tạm ngừng"** với nút **Đăng xuất**.
5. Admin khôi phục A → A đăng nhập và dùng bình thường.
6. Kiểm tra **không đổi hành vi tổ chức**: tạm ngừng *tổ chức* (không phải người dùng) → vẫn chỉ rời tổ chức, **không** đăng xuất.

---

## Ghi chú kỹ thuật (từ lần review trước)

Không viết `close()` dạng:
```dart
Future<void> close() async {
  await _revokedSubscription.cancel();   // ❌ treo trong flutter_test
  return super.close();
}
```
`await` trên `cancel()` của stream broadcast không hoàn tất dưới zone thời gian giả của `flutter_test`, làm mọi widget test kết thúc bằng `await cubit.close()` treo tới 10 phút. Dùng:
```dart
Future<void> close() {
  _revokedSubscription.cancel();
  return super.close();
}
```
