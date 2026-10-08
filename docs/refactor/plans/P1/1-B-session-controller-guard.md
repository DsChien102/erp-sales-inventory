# 1-B — `SessionController` + router guard

> Phase: P1 · Bước (a) chuyển kiến trúc · Trạng thái: Plan 📝 | Làm ⬜ | Review ⬜
> Gồm việc: 1.3 (`SessionController`), 1.4 (router guard), cộng 2 góp ý từ review 1-A và dọn `Failure`/`Either`
> Tài liệu liên quan: [PLAN.md](../../PLAN.md) P1; [SCOPE.md](../../SCOPE.md) 3.5; [TH-01](../../../02-yeu-cau/TH-01-to-chuc-va-nguoi-dung.md) mục 2.3 (bảng định tuyến), ID-08, ID-09

## 1. Mục tiêu

1. **Một nguồn sự thật về phiên** ở `core/session/SessionController`: người dùng đã đăng nhập chưa, tổ chức / cửa hàng đang chọn, quyền, danh sách tổ chức, chọn / đổi tổ chức, tín hiệu tổ chức bị tạm ngừng, đăng xuất. Feature mới (repository) lấy `tenantId` / `storeId` từ đây thay cho `IExecutionContext`.
2. **Guard tách thành hàm thuần** `routeGuard(...)` có test, router tự chạy lại guard khi trạng thái đăng nhập đổi.
3. Bỏ `Failure` / `Either` / `guard()` cũ (3 chỗ đăng xuất) — đăng xuất đi qua `SessionController.signOut()` và `AppException`.

**Không đổi hành vi** (bước a). Cụ thể giữ nguyên: cách chọn tổ chức lúc mở app (lấy tổ chức chọn gần nhất; không hợp lệ thì **mở sheet chọn**, không tự chọn tổ chức khác), màn "Tổ chức không thể truy cập" hiện trong Dashboard, đăng xuất khi tài khoản bị tạm ngừng.

### Phạm vi so với PLAN

PLAN ghi "guard đúng 6 trường hợp" (TH-01 mục 2.3). 3 trong 6 trường hợp cần màn **chưa có** và là hành vi mới (🆕), nên **không** làm ở 1-B:

| Trường hợp TH-01 2.3 | Làm ở |
|---|---|
| Chưa đăng nhập → `/login`; đã đăng nhập mà vào `/login` → `/` | **1-B** (đang có, chuyển sang hàm guard) |
| Tổ chức đang chọn `suspended` / `closed` → màn chặn | **1-B giữ nguyên** cách hiện tại (Dashboard hiện `OrganizationEmptyView`); guard chỉ đọc trạng thái, không đổi route |
| Tổ chức `active` → `/` | **1-B** (như hiện tại) |
| Email chưa xác minh → `/verify-email` | **2-B1** (màn mới) |
| Không có membership → `/no-organization` | **2-B1** (màn mới; hiện là sheet chọn tổ chức rỗng) |
| Platform admin → `/admin`, "Chuyển không gian" | **P8** |
| Không hợp lệ thì lấy "tổ chức hoạt động đầu tiên" | **2-B1** (hiện code mở sheet chọn — OQ-07) |

Hàm guard được thiết kế sẵn chỗ cho 3 nhánh này (xem bước 4) để 2-B1 và P8 chỉ thêm nhánh.

Thân bên trong `SessionController` **vẫn gọi IAM module cũ** (`GetTenantContextQuery`, `ListAccessibleTenantsQuery`, `SwitchTenantContextCommand`, `SignOutCommand`) và đọc `IamSession`. Đổi sang gọi RPC trực tiếp (`iam.get_tenant_context`, `list_accessible_tenants`, `switch_tenant_context`, `user_preferences`) làm ở **2-A2** khi chuyển IAM. Lý do: các handler đó còn ghi `IamSession` mà ~119 file cũ (`IExecutionContext`) đang dựa vào; tách ra bây giờ sẽ phải viết lại cả phần đồng bộ phiên.

## 2. Hiện trạng

| Thành phần | Vị trí | Vai trò |
|---|---|---|
| `TenantContextCubit` + `TenantContextState` (400 dòng) | `lib/features/tenant_context/presentation/bloc/` | Bootstrap tổ chức, danh sách tổ chức, đổi tổ chức, nghe `TenantAccessRevokedSignal`, gọi `onIdentityRevoked` khi tài khoản bị tạm ngừng. **Tạo mới mỗi lần mở Dashboard** (`dashboard_page.dart` ~dòng 81, `BlocProvider(create:)`) |
| `IamSession` | `modules/iam/infrastructure/.../iam_session.dart` | `userId`, `tenantId`, `activeStoreId`, `role`, `permissions`, `hasPermission()`; đăng ký trong getIt dưới 5 interface (`IamSession`, `ICurrentUser`, `ICurrentTenant`, `IPrincipalSnapshot`, + `IExecutionContext` qua `iamRuntime`) |
| `restorePersistedAuthSession` | `lib/core/session/` | Lúc khởi động: có phiên Supabase thì `sessionPort.applyAuthenticatedUser(userId)` |
| Router `redirect` | `app_router.dart` dòng 84–99 | Chỉ kiểm `getIt<ICurrentUser>().userId != null`; public: `/login*`, `/invitation`. **Không có `refreshListenable`** — sau đăng nhập/đăng xuất code tự `context.go` |
| Đăng xuất | `guard(() => iamModule.executeCommandAsync(SignOutCommand()))` + `fold` ở 3 chỗ: `app_router.dart` (route `/more/my-account`), `more_page.dart`, `dashboard_page.dart` (`signOutSuspendedAccountAndGoToLogin`) | Hiện toast khi `localCleared == false` / `remoteSucceeded == false`, rồi `go('/login')` |
| `core/errors/failure.dart`, `result.dart`, `exception_mapper.dart` | — | Chỉ phục vụ `guard()` ở 3 chỗ trên |
| Nơi dùng `TenantContextCubit`/`State` | `dashboard_page.dart`, `dashboard_header.dart`, `select_organization_bottom_sheet.dart`, `tenant_context_selector.dart`, `core/di/injection.dart`; test: `default_pair_gate_test.dart`, `wgt_e05_tenant_context_test.dart`, `tenant_context_blocked_ui_test.dart`, `tenant_context_cubit_revoked_signal_test.dart` | |

## 3. Thay đổi

| File | Hành động | Nội dung |
|---|---|---|
| `lib/core/session/session_controller.dart` | Tạo (chuyển từ `tenant_context_cubit.dart`) | `SessionController extends Cubit<SessionState>` |
| `lib/core/session/session_state.dart` | Tạo (chuyển từ `tenant_context_state.dart`) | Thêm `authStatus` |
| `lib/core/session/restore_persisted_auth_session.dart` | Xoá | Gộp vào `SessionController.start()` |
| `lib/features/tenant_context/presentation/bloc/*` | Xoá sau khi chuyển | — |
| `lib/core/router/route_guard.dart` | Tạo | Hàm thuần `routeGuard` |
| `lib/core/router/session_refresh.dart` | Tạo | `Listenable` cho `GoRouter.refreshListenable` |
| `lib/core/router/app_router.dart` | Sửa | `redirect` gọi `routeGuard`; logout dùng `SessionController.signOut()` |
| `lib/core/di/injection.dart` | Sửa | Đăng ký `SessionController` singleton; `PartnerRepository` lấy tenant từ nó |
| `dashboard_page.dart`, `dashboard_header.dart`, `select_organization_bottom_sheet.dart`, `tenant_context_selector.dart`, `more_page.dart` | Sửa | Dùng `SessionController` / `SessionState` |
| `lib/core/errors/failure.dart`, `result.dart`, `exception_mapper.dart` | Xoá | Không còn ai dùng |
| 4 file test tenant context | Sửa / chuyển sang `test/core/session/` | Đổi tên lớp |
| `test/core/router/route_guard_test.dart` | Tạo | Test bảng guard |
| `test/core/session/session_controller_test.dart` | Tạo | Test auth status + accessor + signOut |
| `apps/erp/tool/check_feature_imports.dart` | Sửa | Góp ý 1 của review 1-A |
| `AGENTS.md` | Sửa | Góp ý 2 của review 1-A |

## 4. Các bước

### Bước 1 — Chuyển cubit thành `SessionController`

1. `git mv lib/features/tenant_context/presentation/bloc/tenant_context_cubit.dart lib/core/session/session_controller.dart`, tương tự `tenant_context_state.dart` → `session_state.dart`.
2. Đổi tên: `TenantContextCubit` → `SessionController`, `TenantContextState` → `SessionState`, `TenantContextLoadStatus` → `TenantLoadStatus` (giữ giá trị `initial/loading/ready/blocked/failure`). **Giữ nguyên** thân `bootstrap`, `loadAccessibleTenants`, `switchTo`, `_emitResolvedContext`, `requestOpenSelector`, `consumeOpenSelectorRequest`, `retryLoadAccessibleTenants`, `selectorEmptyStateType`.
3. Thêm vào `SessionState`:
   ```dart
   enum AuthStatus { unknown, signedOut, signedIn }
   final AuthStatus authStatus;   // mặc định unknown
   final String? userId;
   ```
4. Thêm vào `SessionController` (constructor nhận thêm `GoTrueClient auth`, `IamSession iamSession`, `IIamSessionPort sessionPort`):
   ```dart
   /// Gọi 1 lần trong initDependencies (thay restorePersistedAuthSession).
   void start() {
     _apply(_auth.currentUser?.id);
     _authSub = _auth.onAuthStateChange.listen((e) {
       if (e.event == AuthChangeEvent.signedOut) _apply(null);
       if (e.event == AuthChangeEvent.signedIn || e.event == AuthChangeEvent.tokenRefreshed) _apply(e.session?.user.id);
     });
   }

   void _apply(String? userId) {
     if (userId == null || userId.isEmpty) { _sessionPort.clear(); emit(const SessionState(authStatus: AuthStatus.signedOut)); return; }
     if (state.userId != userId) _sessionPort.applyAuthenticatedUser(userId);   // giống restorePersistedAuthSession
     emit(state.copyWith(authStatus: AuthStatus.signedIn, userId: userId));
   }

   // Accessor cho repository / UI (đọc IamSession, sẽ thay ở 2-A2)
   String? get tenantId => _iamSession.tenantId;
   String? get activeStoreId => _iamSession.activeStoreId;
   bool hasPermission(String code) => _iamSession.hasPermission(code);
   Future<String> requireTenantId() async => tenantId ?? (throw const AppException(AppErrorCode.authRequired));
   Future<String> requireActiveStoreId() => _iamSession.requireActiveStoreId();

   /// Thay 3 chỗ guard(SignOutCommand). Trả kết quả để UI hiện cảnh báo như cũ.
   Future<SignOutResultDto> signOut() async {
     try {
       final result = await _iamModule.executeCommandAsync<SignOutResultDto>(SignOutCommand());
       if (result.localCleared) emit(const SessionState(authStatus: AuthStatus.signedOut));
       return result;
     } catch (e) {
       throw AppException.from(e);
     }
   }
   ```
   `close()` huỷ `_authSub` (không `await`, như đã ghi chú với `_revokedSubscription`).
   - **Lưu ý `signedIn` lặp**: Supabase phát `signedIn` cả khi app quay lại foreground; chỉ gọi `applyAuthenticatedUser` khi `userId` đổi (đã có điều kiện trên).
   - Đăng nhập hiện chạy `SignInTenantUserCommand` trong `LoginCubit`, module tự `applyAuthenticatedUser`. Sự kiện `signedIn` của Supabase đến sau → `_apply` thấy cùng `userId`, chỉ cập nhật `authStatus`. Không sửa `LoginCubit`.
5. Trạng thái sau đăng xuất: `emit(const SessionState(...))` xoá luôn tổ chức / danh sách, để lần đăng nhập sau `bootstrap()` chạy lại từ đầu.

### Bước 2 — Một instance cho cả app

1. `core/di/injection.dart`: thay `restorePersistedAuthSession(...)` bằng
   ```dart
   final session = SessionController(
     iamModule: iamRuntime.module,
     auth: supabaseModule.client.auth,
     iamSession: iamRuntime.session,
     sessionPort: iamRuntime.sessionPort,
   )..start();
   getIt.registerSingleton<SessionController>(session);
   ```
   `applyTenantContextPermissions` hiện nằm ở `lib/features/tenant_context/presentation/tenant_context_selector.dart` và chỉ làm một việc: `IamSession.apply(PrincipalAccessDto(...))` từ `TenantContextDto`. Chuyển nó thành **hàm private trong `SessionController`** (dùng `_iamSession` đã được tiêm, bỏ `getIt` bên trong) và gọi ở đúng hai chỗ cũ (`switchTo` thành công, `_emitResolvedContext` khi `valid`). Bỏ tham số `applyPermissions` khỏi constructor. Lý do: `core/` không được import `features/`. `onIdentityRevoked` xem bước 3.
2. `PartnerRepository`: `tenantId: () => getIt<SessionController>().requireTenantId()`.
3. Không đổi đăng ký `IExecutionContext`, `ICurrentUser`… (code cũ còn dùng đến khi từng feature chuyển).

### Bước 3 — Dashboard và các widget

1. `dashboard_page.dart`: `BlocProvider(create: …TenantContextCubit(...)..bootstrap())` → `BlocProvider.value(value: getIt<SessionController>())` và gọi `bootstrap()` **một lần khi Dashboard mở** (trong `initState` của StatefulWidget hoặc `create` cũ chuyển thành `addPostFrameCallback`) — giữ đúng thời điểm như hiện tại: mỗi lần vào Dashboard sau đăng nhập.
   - Không dùng `BlocProvider(create:)` nữa vì nó sẽ `close()` singleton khi rời Dashboard.
2. `onIdentityRevoked` (tài khoản bị tạm ngừng): hiện là callback `signOutSuspendedAccountAndGoToLogin(context)` ở `dashboard_page.dart` dòng 30–49 (toast "Tài khoản bị tạm ngừng — Tài khoản của bạn đã bị tạm ngừng. Vui lòng liên hệ quản trị viên.", rồi `guard(SignOutCommand)`, rồi `go('/login')`); hàm này còn được gọi ở nút trong màn chặn (~dòng 227, `showToast: false`). Đổi thành:
   - `SessionController` thêm field state `identityRevoked` (bool). Khi nhận `platformUserSuspended` (tín hiệu hoặc `_emitResolvedContext`), emit `identityRevoked: true` thay vì gọi callback; bỏ tham số `onIdentityRevoked`.
   - Dashboard thêm `BlocListener<SessionController, SessionState>` (`listenWhen: identityRevoked` đổi từ false → true) gọi `signOutSuspendedAccountAndGoToLogin(context)` như cũ.
   - Thân `signOutSuspendedAccountAndGoToLogin` thay `guard(...)` bằng `try { await getIt<SessionController>().signOut(); } catch (_) {}` (code cũ cũng bỏ qua kết quả). Giữ toast và `go('/login')`.
3. Đổi tên import/kiểu trong `dashboard_header.dart`, `select_organization_bottom_sheet.dart`, `tenant_context_selector.dart` (`context.read<SessionController>()`, `BlocBuilder<SessionController, SessionState>`).
4. `more_page.dart` và route `/more/my-account` (`onLogout`): thay `guard(...).fold` bằng
   ```dart
   try {
     final r = await getIt<SessionController>().signOut();
     if (!r.localCleared) { toast 'Không thể đóng phiên trên máy.'; return; }
     if (!r.remoteSucceeded) { toast cảnh báo như cũ; }
     context.go('/login');
   } on AppException catch (e) { toast 'Đăng xuất thất bại', e.userMessage(); }
   ```
   Giữ nguyên tiêu đề / câu toast hiện có.
5. Xoá `lib/core/errors/failure.dart`, `result.dart`, `exception_mapper.dart`. Hai file sau import `fpdart` (`Either`); grep `fpdart` trong `apps/erp/lib` — nếu không còn ai dùng thì bỏ `fpdart` khỏi `apps/erp/pubspec.yaml`.
6. `openTenantContextSelector` và phần còn lại của `tenant_context_selector.dart` giữ ở feature (chỉ đổi kiểu sang `SessionController`/`SessionState`).

### Bước 4 — Guard thuần + tự chạy lại

`lib/core/router/route_guard.dart`:

```dart
const _publicPrefixes = ['/login', '/invitation'];   // 2-B1 thêm '/signup', '/verify-email'

String? routeGuard({required SessionState session, required String location}) {
  final isPublic = _publicPrefixes.any((p) => location == p || location.startsWith('$p/'));
  switch (session.authStatus) {
    case AuthStatus.unknown:
      return null;                                  // chưa biết thì để yên (start() chạy đồng bộ trước runApp nên hiếm gặp)
    case AuthStatus.signedOut:
      return isPublic ? null : '/login';
    case AuthStatus.signedIn:
      // 2-B1: email chưa xác minh → '/verify-email'; không có membership → '/no-organization'
      // P8:   platform admin không có membership → '/admin'
      if (location == '/login' || location.startsWith('/login/')) return '/';
      return null;
  }
}
```

- Giữ đúng hành vi cũ: `/login/reset-password` (route con) đang là public; đã đăng nhập mà vào `/login…` thì về `/`. **Kiểm lại**: hiện code cũ chuyển cả `/login/reset-password` về `/` khi đã đăng nhập — giữ y nguyên.
- `/invitation` khi đã đăng nhập: code cũ **không** chặn — giữ.

`lib/core/router/session_refresh.dart`: `class SessionRefresh extends ChangeNotifier` nghe `controller.stream.map((s) => s.authStatus).distinct()` và `notifyListeners()`. **Chỉ nghe `authStatus`** để router không chạy lại guard mỗi lần danh sách tổ chức đổi.

`app_router.dart`: `redirect: (context, state) => routeGuard(session: getIt<SessionController>().state, location: state.matchedLocation)`, `refreshListenable: SessionRefresh(getIt<SessionController>())`.

- Lưu ý: `appRouter` là biến top-level khởi tạo khi file được import, **trước** `initDependencies`? Kiểm: `main.dart` gọi `initDependencies` trước `runApp`, còn `appRouter` chỉ được đọc khi `MaterialApp.router` build → `getIt<SessionController>()` đã có. Nếu analyzer/test khởi tạo sớm, đổi `appRouter` thành `late final` hoặc hàm `createAppRouter()`.

### Bước 5 — Góp ý từ review 1-A

1. `tool/check_feature_imports.dart`: áp **R3** cho mọi file trong `lib/features` (bỏ điều kiện "chỉ xét nguồn `data/`, `logic/`" cho R3; R1, R2 giữ theo tầng nguồn). Chạy lại phải vẫn 0 vi phạm.
2. `AGENTS.md` mục Kiến trúc đích, thêm: "Page được import kiểu repository (`data/`) **chỉ để tạo cubit** (`BlocProvider(create: (_) => XCubit(repository: …))`); mọi lời gọi dữ liệu đi qua cubit."

### Bước 6 — Test

1. Chuyển 4 test tenant context sang tên mới; test nào chỉ thuộc phiên (`tenant_context_cubit_revoked_signal_test.dart`) dời vào `test/core/session/`; test widget giữ chỗ cũ, chỉ đổi kiểu. Fake: `SessionController` cần thêm `auth` — dùng `MockGoTrueClient` (mocktail) với `onAuthStateChange` là `StreamController` của test.
2. `test/core/router/route_guard_test.dart`:
   | session | location | kỳ vọng |
   |---|---|---|
   | signedOut | `/` | `/login` |
   | signedOut | `/login`, `/login/reset-password`, `/invitation` | `null` |
   | signedIn | `/login` | `/` |
   | signedIn | `/login/reset-password` | `/` (giữ hành vi cũ) |
   | signedIn | `/`, `/partner`, `/invitation` | `null` |
   | unknown | bất kỳ | `null` |
3. `test/core/session/session_controller_test.dart`:
   - `start()` khi có `currentUser` → `signedIn`, gọi `applyAuthenticatedUser` 1 lần; không có → `signedOut`, gọi `clear()`.
   - sự kiện `signedOut` → state về mặc định `signedOut`.
   - `signedIn` lặp cùng user → không gọi lại `applyAuthenticatedUser`.
   - `requireTenantId()` khi chưa có tổ chức → `AppException(AUTHENTICATION_REQUIRED)`.
   - `signOut()` `localCleared=true` → `signedOut`; module ném lỗi → `AppException`.

### Bước 7 — Commit

Gợi ý 3 commit (đăng xuất đi qua `SessionController` ở **4 chỗ**: route `/more/my-account`, `more_page.dart`, và 2 lời gọi `signOutSuspendedAccountAndGoToLogin` trong Dashboard): (1) `SessionController` + DI + Dashboard/widget; (2) guard + refresh + đăng xuất + xoá `Failure`; (3) góp ý 1-A.

## 5. Kiểm tra

- [ ] `dart analyze lib test tool` (trong `apps/erp`): không issue mới.
- [ ] `dart run tool/check_feature_imports.dart`: 0 vi phạm (sau khi áp R3 cho mọi file).
- [ ] `grep -rn "TenantContextCubit\|TenantContextState\|restorePersistedAuthSession\|exception_mapper\|Either<Failure" lib test`: rỗng.
- [ ] `flutter test test/core test/features/dashboard test/features/tenant_context test/features/partner`: đạt.
- [ ] `flutter test` toàn bộ `apps/erp`: không test lỗi mới so với 61 lỗi trong [TEST-BASELINE.md](../../TEST-BASELINE.md).
- [ ] Chạy app với Dev, kiểm tay:
  - [ ] Mở app khi chưa đăng nhập → `/login`; đăng nhập → trang chủ, tên tổ chức đúng như trước.
  - [ ] Đổi tổ chức trong sheet (nếu tài khoản có ≥ 2 tổ chức) → dữ liệu đổi theo.
  - [ ] Đăng xuất từ "Thêm" và từ "Tài khoản của tôi" → về `/login`; nhấn Back không vào lại được app.
  - [ ] Đang trong app, hết phiên (xoá phiên trên Supabase Dashboard → Authentication → user → "Sign out user" hoặc đợi token hết hạn) → app tự về `/login` (hành vi **mới** nhờ `refreshListenable`; trước đây kẹt ở màn cũ đến khi gọi RPC lỗi).
  - [ ] Mở "Lịch sử thao tác" đối tác (feature mẫu 1-A) vẫn chạy với `tenantId` từ `SessionController`.
- [ ] CHECKLIST: tick cột "Mới" các dòng **APP-01, APP-04, ID-01, ID-08, ID-09, ID-x1, ID-x3, ID-x6** nếu kiểm tay đạt.

## 6. Rủi ro / lưu ý

- **Singleton thay cho cubit tạo mới mỗi lần**: trước đây rời Dashboard thì cubit bị đóng, vào lại thì tạo mới sạch. Giờ state sống suốt app → phải đảm bảo `signOut` / `signedOut` xoá state và lần vào Dashboard sau gọi lại `bootstrap()`. Test kịch bản: đăng xuất tài khoản A → đăng nhập tài khoản B → không thấy tổ chức của A.
- `refreshListenable` làm router chạy lại guard khi `authStatus` đổi — nơi nào đang tự `context.go('/login')` sau đăng xuất vẫn chạy được (guard trả `null` khi đã ở `/login`). Không gây lặp điều hướng vì chỉ nghe `authStatus`.
- Hành vi mới duy nhất: hết phiên giữa chừng thì tự về `/login`. Ghi vào CHANGELOG.
- `SessionController` vẫn phụ thuộc `IIamModule`, `IamSession`, `IIamSessionPort`, `TenantAccessRevokedSignal` (gói cũ) — chấp nhận tạm, 2-A2 thay bằng RPC; ghi chú `// TODO(2-A2)` ở các chỗ gọi module.
- Không có GitNexus để chạy `impact`; phạm vi theo grep ở mục 2 (5 file lib + 4 file test dùng `TenantContext*`; 3 chỗ dùng `guard()`, trong đó `signOutSuspendedAccountAndGoToLogin` được gọi ở 2 nơi).

## 7. Review

<!-- Claude ghi sau khi bạn code xong -->
- Ngày, commit được review:
- Kết quả:
- Góp ý:
