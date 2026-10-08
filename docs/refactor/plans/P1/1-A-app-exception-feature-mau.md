# 1-A — `AppException`, bộ gọi RPC dùng chung, feature mẫu `partner_change_history`, kiểm tra import

> Phase: P1 · Bước (a) chuyển kiến trúc · Trạng thái: Plan 📝 | Làm ⬜ | Review ⬜
> Gồm việc: 1.2 (`AppException` + bộ map lỗi), 1.5 (feature mẫu), 1.6 (lint)
> Tài liệu liên quan: [PLAN.md](../../PLAN.md) P1 và "Cách chuyển MỘT feature"; [SCOPE.md](../../SCOPE.md) mục 3.1 (cấu trúc `data/ logic/ presentation/`, 3 luật phụ thuộc); [TH-03](../../../02-yeu-cau/TH-03-doi-tac-giao-dich.md) PT-12

## 1. Mục tiêu

Sau plan này có **khuôn mẫu đầy đủ** cho mọi feature từ P2 trở đi:

1. `core/errors/app_exception.dart`: **một kiểu lỗi duy nhất** cho cả app, đọc được cả 3 định dạng lỗi RPC đang có trong DB, lỗi Auth và lỗi mạng; kèm bảng câu tiếng Việt cho các mã chung.
2. `core/supabase/supabase_rpc.dart`: **một chỗ gọi RPC** cho mọi repository: gọi `schema(x).rpc(fn)`, đổi lỗi sang `AppException`, phát tín hiệu "tổ chức bị tạm ngừng" như client cũ.
3. Feature `partner_change_history` (màn PT-12 "Lịch sử thao tác") chạy theo luồng mới `Page → Cubit (logic/) → PartnerRepository (data/) → partner.get_partner_action_logs`, **không còn** `IPartnerModule`.
4. Script `tool/check_feature_imports.dart` chặn import sai tầng / sai feature cho phần code mới.

**Không đổi hành vi** màn hình, với một ngoại lệ đã chấp nhận: khi tải lỗi, màn hiện câu tiếng Việt từ `AppException` thay cho chuỗi exception thô (code cũ dùng `e.toString()`).

## 2. Hiện trạng

### 2.1 Lỗi

| Nơi | Cách làm hiện tại |
|---|---|
| DB | **3 định dạng** `raise exception`: (1) chỉ mã — `'PERMISSION_DENIED'`, `'STATE_CHANGED'` (IAM, catalog, pricing); (2) `'MÃ: chi tiết'` — `'NO_PERMISSION: einvoice.view required'`, `'ISSUANCE_NOT_READY: {"details":…}'` (einvoice, partner); (3) JSON — `using message = jsonb_build_object('code','PERMISSION_DENIED','message','…')` (sales, 10 migration). Ngoài ra có chuỗi tự do (`'permission denied: partner.contact.manage'`, `'not authenticated'`) và lỗi Postgres gốc (`42501 permission denied for table`) |
| `packages/vet45_adapters` `SupabaseSchemaRpcClient` | Gọi RPC, `TenantAccessRevokedSignal.notifyFromError(error)`, ném `RpcException(message)` |
| Mỗi module | Tự map: `mapPartnerRpcError` (tìm mã trong chuỗi), `IamUiFailureMapper` (mã + `AuthException` + lỗi mạng, có bảng câu tiếng Việt), `OrderEInvoiceErrorMessage`, sales `jsonDecode(error.message)`… |
| Mã trùng nghĩa | `PERMISSION_DENIED` (IAM, sales) ≈ `NO_PERMISSION` (partner, pricing, einvoice); `RESOURCE_NOT_FOUND` (IAM) ≈ `NOT_FOUND` |
| `apps/erp/lib/core/errors/` | `Failure` + `Either` + `guard()` — chỉ 3 chỗ dùng `guard()` (router đăng xuất, `more_page`, `dashboard_page`) |

### 2.2 Feature mẫu

```text
PartnerChangeHistoryPage(partnerModule, executionContext)          lib/features/partner/presentation/pages/
  └─ PartnerChangeHistoryCubit                                      lib/features/partner/presentation/bloc/
       └─ IPartnerModule.executeQueryAsync(GetPartnerActionLogsQuery(tenantId, partnerId, page=1, limit=20))
            └─ SupabasePartnerReadGateway.getPartnerActionLogs
                 └─ partner.get_partner_action_logs(p_tenant_id, p_partner_id, p_page, p_limit)   → trả 1 dòng (returns table)
                      { items: [{action_log_id, action_type, actor_user_id, reason, before_state, after_state, created_at}], total, page, limit }
```

- DTO `PartnerActionLogItemDto`, `PartnerActionLogResultDto` (module application), enum `PartnerActionType` (module domain, có `parse()` nhận cả `add_contact` lẫn `addContact`).
- Mapper `PartnerReadRpcMapper.mapActionLogsResult`: `before_state` / `after_state` rỗng `{}` → `null`.
- Route `/partner/:partnerId/history` (`app_router.dart` ~dòng 553) truyền `getIt<IPartnerModule>()`, `getIt<IExecutionContext>()`.
- Test: `test/features/partner/presentation_module/bloc/partner_change_history_cubit_test.dart` (3 test, dùng `FakePartnerModule`), `test/features/partner/presentation/widgets/partner_change_history_widgets_test.dart` (widget, không đụng module).

## 3. Thay đổi

| File | Hành động | Nội dung |
|---|---|---|
| `lib/core/errors/app_exception.dart` | Tạo | `AppException`, `AppErrorCode`, `AppException.from(error)` |
| `lib/core/errors/app_error_messages.dart` | Tạo | Câu tiếng Việt cho mã chung |
| `lib/core/supabase/supabase_rpc.dart` | Tạo | `SupabaseRpc`: `call`, `rows`, `firstRow` |
| `lib/core/di/injection.dart` | Sửa | Đăng ký `SupabaseRpc`, `PartnerRepository` |
| `lib/features/partner/data/models/partner_action_log.dart` | Tạo | `PartnerActionType`, `PartnerActionLog`, `PartnerActionLogPage` + `fromJson` |
| `lib/features/partner/data/partner_repository.dart` | Tạo | `PartnerRepository.getActionLogs(...)` (P4 sẽ bổ sung các hàm khác) |
| `lib/features/partner/logic/partner_change_history_cubit.dart`, `…_state.dart` | Chuyển từ `presentation/bloc/` + sửa | Dùng `PartnerRepository`, lỗi → `AppException.userMessage` |
| `lib/features/partner/presentation/pages/partner_change_history_page.dart` | Sửa | Nhận `PartnerRepository` thay cho module + execution context |
| `lib/features/partner/presentation.dart` (barrel) | Sửa | Export cubit/state từ đường mới |
| `lib/core/router/app_router.dart` | Sửa | Route history truyền `getIt<PartnerRepository>()` |
| `test/core/errors/app_exception_test.dart` | Tạo | Test bộ phân tích lỗi |
| `test/features/partner/data/partner_repository_test.dart` | Tạo | Test map JSON → model |
| `test/features/partner/logic/partner_change_history_cubit_test.dart` | Chuyển + viết lại | Fake repository thay `FakePartnerModule`; giữ 3 kịch bản cũ + 1 kịch bản lỗi |
| `tool/check_feature_imports.dart` | Tạo | Script kiểm import |

**Không đụng** trong plan này: `core/errors/failure.dart`, `result.dart`, `exception_mapper.dart` (`guard()`) — để 1-B, khi sửa router/đăng xuất; các mapper của module khác — mỗi phase tự chuyển sang `AppException`; `PartnerActionLogDiff` (support, giữ nguyên).

## 4. Các bước

### Bước 1 — `AppException`

`lib/core/errors/app_exception.dart`:

```dart
/// Mã lỗi chuẩn hoá dùng chung. Mã riêng của từng nghiệp vụ (vd `HAS_TRANSACTIONS`,
/// `BUYER_TAX_CODE_REQUIRED`) giữ nguyên chuỗi server trả về.
abstract final class AppErrorCode {
  static const noPermission = 'NO_PERMISSION';          // ← PERMISSION_DENIED, 'permission denied…', Postgres 42501
  static const notFound = 'NOT_FOUND';                  // ← RESOURCE_NOT_FOUND
  static const validation = 'VALIDATION_ERROR';
  static const stateChanged = 'STATE_CHANGED';
  static const authRequired = 'AUTHENTICATION_REQUIRED';// ← 'not authenticated', PGRST301, JWT hết hạn
  static const tenantSuspended = 'TENANT_SUSPENDED';
  static const tenantClosed = 'TENANT_CLOSED';
  static const network = 'NETWORK_ERROR';               // SocketException, ClientException, TimeoutException
  static const unknown = 'SYSTEM_ERROR';
}

final class AppException implements Exception {
  const AppException(this.code, {this.serverMessage, this.details, this.cause});

  final String code;                     // đã chuẩn hoá
  final String? serverMessage;           // phần chi tiết server gửi (KHÔNG hiện thẳng cho người dùng)
  final Map<String, dynamic>? details;   // vd {"blockers": [...]} của einvoice
  final Object? cause;

  /// Câu hiển thị. [overrides] cho phép feature thay câu của một số mã.
  String userMessage([Map<String, String> overrides = const {}]) =>
      overrides[code] ?? AppErrorMessages.of(code);

  bool get isNoPermission => code == AppErrorCode.noPermission;
  bool get isStateChanged => code == AppErrorCode.stateChanged;

  factory AppException.from(Object error, [StackTrace? stackTrace]) { /* bước 1b */ }

  @override
  String toString() => 'AppException($code${serverMessage == null ? '' : ': $serverMessage'})';
}
```

**1b. Thứ tự phân tích trong `AppException.from`:**

1. `AppException` → trả lại chính nó.
2. `PostgrestException e`:
   1. `e.message` bắt đầu bằng `{` → `jsonDecode`; lấy `code`, `message`, `details` (định dạng 3, sales).
   2. Khớp `^([A-Z][A-Z0-9_]{2,})(?::\s*(.*))?$` (cờ `dotAll`) → mã = nhóm 1, chi tiết = nhóm 2; nếu chi tiết bắt đầu bằng `{` thì thử `jsonDecode` vào `details` (định dạng 1, 2).
   3. Không khớp: `e.code == '42501'` hoặc message chứa `permission denied` → `NO_PERMISSION`; `e.code == 'PGRST301'`, message chứa `jwt` hoặc `not authenticated` → `AUTHENTICATION_REQUIRED`; còn lại → `SYSTEM_ERROR` (giữ `e.message` ở `serverMessage`).
3. `AuthException e` (đăng nhập): `invalid_credentials` → `INVALID_CREDENTIALS`; `email_not_confirmed` → `IDENTITY_EMAIL_NOT_VERIFIED`; `over_email_send_rate_limit` hoặc `statusCode == '429'` → `RATE_LIMITED`; còn lại → `AUTHENTICATION_REQUIRED` nếu `statusCode == '401'`, ngược lại `SYSTEM_ERROR`. (Lấy đúng logic `IamUiFailureMapper` hiện có.)
4. `SocketException`, `TimeoutException`, `http.ClientException`, hoặc `toString()` chứa `failed host lookup` / `connection refused` / `network is unreachable` → `NETWORK_ERROR`.
5. Còn lại → `SYSTEM_ERROR`, `cause = error`.
6. Sau khi có mã: chuẩn hoá bí danh `PERMISSION_DENIED → NO_PERMISSION`, `RESOURCE_NOT_FOUND → NOT_FOUND`. **Không** đổi mã khác.

> Lưu ý: dùng `dart:io` cho `SocketException` thì file chỉ chạy trên mobile/desktop. App có target web (`apps/erp/web`) — để an toàn, nhận diện lỗi mạng bằng `error.runtimeType.toString()` / `toString()` thay vì `is SocketException`, hoặc import có điều kiện. Chọn cách so chuỗi cho đơn giản.

### Bước 2 — Câu tiếng Việt

`lib/core/errors/app_error_messages.dart`: `abstract final class AppErrorMessages { static String of(String code) => _messages[code] ?? _messages[AppErrorCode.unknown]!; }` với bảng:

| Mã | Câu |
|---|---|
| `NO_PERMISSION` | Bạn không có quyền thực hiện thao tác này. |
| `NOT_FOUND` | Không tìm thấy dữ liệu. Có thể dữ liệu đã bị xoá. |
| `VALIDATION_ERROR` | Dữ liệu chưa hợp lệ. Vui lòng kiểm tra lại. |
| `STATE_CHANGED` | Dữ liệu vừa được thay đổi ở nơi khác. Vui lòng tải lại. |
| `AUTHENTICATION_REQUIRED` | Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại. |
| `TENANT_SUSPENDED` | Tổ chức đang tạm ngừng hoạt động. |
| `TENANT_CLOSED` | Tổ chức đã đóng. |
| `NETWORK_ERROR` | Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng. |
| `IDEMPOTENCY_CONFLICT` | Yêu cầu bị trùng. Vui lòng thử lại. |
| `SYSTEM_ERROR` | Đã có lỗi xảy ra. Vui lòng thử lại. |

Câu của mã riêng từng nghiệp vụ **không** đưa vào đây; feature truyền `overrides` (vd TH-03: `HAS_TRANSACTIONS`). Câu cho các mã IAM (`INVALID_CREDENTIALS`, `RATE_LIMITED`…) chuyển ở 2-A1 từ `IamUiFailureMapper`.

### Bước 3 — `SupabaseRpc`

`lib/core/supabase/supabase_rpc.dart`:

```dart
class SupabaseRpc {
  SupabaseRpc(this._client);
  final SupabaseClient _client;

  /// Gọi RPC; mọi lỗi thành [AppException].
  Future<dynamic> call(String schema, String fn, {Map<String, dynamic> params = const {}}) async {
    try {
      final builder = schema == 'public' ? _client : _client.schema(schema);
      return await builder.rpc(fn, params: params);
    } catch (error, stackTrace) {
      TenantAccessRevokedSignal.notifyFromError(error);   // giữ hành vi client cũ (đến 1-B thay bằng SessionController)
      throw AppException.from(error, stackTrace);
    }
  }

  /// RPC `returns table` / `setof` → danh sách dòng (null → rỗng, 1 object → [object]).
  Future<List<Map<String, dynamic>>> rows(String schema, String fn, {Map<String, dynamic> params = const {}}) async { … }

  /// Dòng đầu; không có dòng → AppException(NOT_FOUND).
  Future<Map<String, dynamic>> firstRow(String schema, String fn, {Map<String, dynamic> params = const {}}) async { … }
}
```

- `TenantAccessRevokedSignal` nằm ở `package:vet45_shared_application` — tạm import (gói bị xoá ở P9; 1-B chuyển tín hiệu vào `core/session`).
- Không log trong bước này (client cũ log `fine`/`severe`); nếu muốn giữ log, dùng `Logger('SupabaseRpc')` của `package:logging`.

### Bước 4 — Model

`lib/features/partner/data/models/partner_action_log.dart`:

- `enum PartnerActionType { create, update, addContact, removeContact, transform, deactivate, reactivate, delete; static PartnerActionType parse(String raw) }` — chép nguyên `parse()` từ `modules/partner/domain`.
- `class PartnerActionLog { actionLogId, actionType, actorUserId, reason, beforeState, afterState, createdAt; factory fromJson(Map) }` — `before_state` / `after_state` rỗng → `null` (giống `_asStateMap`).
- `class PartnerActionLogPage { items, total, page, limit; factory fromJson(Map) }` — `total` mặc định `items.length`, `page` 1, `limit` `items.length` (giống mapper cũ).

Giữ tên field giống DTO cũ để cubit đổi ít nhất.

### Bước 5 — Repository

`lib/features/partner/data/partner_repository.dart`:

```dart
class PartnerRepository {
  PartnerRepository({required SupabaseRpc rpc, required Future<String> Function() tenantId})
      : _rpc = rpc, _tenantId = tenantId;
  final SupabaseRpc _rpc;
  final Future<String> Function() _tenantId;   // 1-A: IExecutionContext.requireTenantId; 1-B: SessionController

  Future<PartnerActionLogPage> getActionLogs(String partnerId, {int page = 1, int limit = 20}) async {
    final row = await _rpc.firstRow('partner', 'get_partner_action_logs', params: {
      'p_tenant_id': await _tenantId(),
      'p_partner_id': partnerId,
      'p_page': page,
      'p_limit': limit,
    });
    return PartnerActionLogPage.fromJson(row);
  }
}
```

### Bước 6 — Cubit sang `logic/`

1. `git mv` `presentation/bloc/partner_change_history_cubit.dart` và `…_state.dart` → `lib/features/partner/logic/`.
2. Constructor: `PartnerChangeHistoryCubit({required PartnerRepository repository})`; bỏ `IPartnerModule`, `IExecutionContext`.
3. `loadHistory`: `final page = await _repository.getActionLogs(partnerId);` rồi map như cũ (`_toEntry` nhận `PartnerActionLog` thay `PartnerActionLogItemDto`; `PartnerActionType` import từ model mới).
4. `catch (e)`: `errorMessage: AppException.from(e).userMessage()`.
5. Giữ nguyên `_summaryFor`, `_titleLabel`, cách hiển thị người thao tác 8 ký tự (sửa ở 4-B theo TH-03).
6. Sửa import trong `partner_change_history_page.dart` và barrel `lib/features/partner/presentation.dart` (đã grep: state/cubit chỉ được import trực tiếp ở barrel và chính cubit; widget dùng qua barrel).

### Bước 7 — DI và router

`core/di/injection.dart`, sau khi có `iamRuntime`:

```dart
getIt
  ..registerLazySingleton<SupabaseRpc>(() => SupabaseRpc(supabaseModule.client))
  ..registerLazySingleton<PartnerRepository>(() => PartnerRepository(
        rpc: getIt<SupabaseRpc>(),
        tenantId: () => getIt<IExecutionContext>().requireTenantId(),
      ));
```

`app_router.dart` route `/partner/:partnerId/history`: `PartnerChangeHistoryPage(partnerId: …, partnerName: …, repository: getIt<PartnerRepository>())`. Page tạo cubit với `repository`.

### Bước 8 — Script kiểm import

`apps/erp/tool/check_feature_imports.dart` (Dart thuần, chạy `dart run tool/check_feature_imports.dart`, thoát mã 1 nếu vi phạm). Duyệt `lib/features/**.dart`, đọc dòng `import`/`export`, quy đường dẫn tương đối và `package:erp/...` về `lib/features/<feature>/<layer>/…`. Luật (theo SCOPE 3.1):

| # | File nguồn | Không được import | Lý do |
|---|---|---|---|
| R1 | `features/A/data/**` | `features/*/logic/**`, `features/*/presentation/**`, `package:flutter/` (trừ `package:flutter/foundation.dart`) | data không phụ thuộc tầng trên / UI |
| R2 | `features/A/logic/**` | `features/*/presentation/**` | logic không phụ thuộc UI |
| R3 | `features/A/**` | `features/B/logic/**` (B ≠ A) | feature khác chỉ dùng repository (`data/`) của nhau |

Chỉ áp cho tầng mới (`data/`, `logic/`): code cũ chỉ có `presentation/` nên không báo lỗi giả. Luật "presentation A không import presentation B" (SCOPE luật 2) bật ở P9 khi code cũ đã chuyển hết. In ra `file:line  R#  import`.

Thêm vào `AGENTS.md` mục "Lệnh hay dùng": `cd apps/erp && dart run tool/check_feature_imports.dart`.

### Bước 9 — Test

1. `test/core/errors/app_exception_test.dart` — mỗi dòng ở bước 1b một test, tối thiểu:
   - `PostgrestException(message: 'PERMISSION_DENIED')` → `NO_PERMISSION`
   - `'NO_PERMISSION: einvoice.view required'` → `NO_PERMISSION`, `serverMessage == 'einvoice.view required'`
   - `'ISSUANCE_NOT_READY: {"details":{"blockers":["X"]}}'` → mã đúng, `details['details']['blockers']` có `X`
   - JSON `{"code":"STATE_CHANGED","message":"…"}` → `STATE_CHANGED`
   - `'permission denied: partner.detail.view'` → `NO_PERMISSION`; `code: '42501'` → `NO_PERMISSION`; `'not authenticated'` → `AUTHENTICATION_REQUIRED`
   - `'RESOURCE_NOT_FOUND'` → `NOT_FOUND`; `'HAS_TRANSACTIONS'` → giữ `HAS_TRANSACTIONS`
   - `AuthException('Invalid login credentials', code: 'invalid_credentials')` → `INVALID_CREDENTIALS`
   - `Exception('SocketException: Failed host lookup')` → `NETWORK_ERROR`
   - `userMessage({'HAS_TRANSACTIONS': 'x'})` dùng override; mã lạ → câu `SYSTEM_ERROR`
2. `test/features/partner/data/partner_repository_test.dart` — test `PartnerActionLogPage.fromJson` (state `{}` → null, `add_contact` → `addContact`, thiếu total/page/limit → mặc định). Không gọi Supabase thật.
3. `test/features/partner/logic/partner_change_history_cubit_test.dart` — `git mv` file test cũ, thay `FakePartnerModule` bằng fake `PartnerRepository` (mocktail: `class _MockRepo extends Mock implements PartnerRepository`), giữ 3 kịch bản cũ (dữ liệu hỗn hợp, không snapshot, rỗng) + thêm 1: repository ném `AppException('NO_PERMISSION')` → state `failure`, `errorMessage == 'Bạn không có quyền thực hiện thao tác này.'`.

### Bước 10 — Commit

Gợi ý tách 2 commit cho dễ review: (1) `core`: `AppException`, `SupabaseRpc`, script + test; (2) `partner`: model, repository, cubit, page, router, DI, test.

## 5. Kiểm tra

- [ ] `dart analyze lib/core lib/features/partner tool test/core test/features/partner`: không issue mới.
- [ ] `flutter test test/core test/features/partner`: đạt.
- [ ] `flutter test` toàn bộ `apps/erp`: không test lỗi mới so với [TEST-BASELINE.md](../../TEST-BASELINE.md) (hiện 61 lỗi có sẵn). Test cubit cũ dời đi nên tổng số test thay đổi nhẹ — ghi lại số mới.
- [ ] `dart run tool/check_feature_imports.dart`: không vi phạm.
- [ ] `grep -rn "IPartnerModule\|IExecutionContext" lib/features/partner/logic lib/features/partner/data`: rỗng.
- [ ] Chạy app với Dev: mở một đối tác → "Lịch sử thao tác" hiện danh sách như trước; tắt mạng rồi mở lại → hiện "Không thể kết nối đến máy chủ…".
- [ ] CHECKLIST: tick cột "Mới" dòng **PT-12**.

## 6. Rủi ro / lưu ý

- **Thứ tự quét mã trong chuỗi**: mapper cũ của partner tìm mã ở *bất kỳ đâu* trong message (`contains`). Bộ mới yêu cầu mã ở **đầu** message. Đã kiểm `partner.get_partner_action_logs`: chỉ ném `'not authenticated'` và `'permission denied: partner.detail.view'` → rơi vào nhánh 1b.2.3, ra `AUTHENTICATION_REQUIRED` / `NO_PERMISSION`. RPC của các feature khác sẽ được kiểm khi chuyển ở phase của chúng (ghi trong plan từng phase).
- `TenantAccessRevokedSignal` và `IExecutionContext` vẫn là phụ thuộc vào gói cũ — chấp nhận tạm, 1-B thay.
- Module partner cũ vẫn dùng `get_partner_action_logs` qua `IPartnerModule` ở chỗ khác? Grep cho thấy chỉ màn lịch sử dùng; `FakePartnerModule` scenario `actionLogs*` sẽ không còn ai gọi — để nguyên, xoá cùng module ở P9.
- Web: tránh `dart:io` trong `core/errors` (xem lưu ý bước 1b).
- Không có GitNexus để chạy `impact`; phạm vi xác định bằng grep: `PartnerChangeHistoryCubit` chỉ được dùng ở page, barrel và test; `PartnerChangeHistoryState` ở page, body widget, test.

## 7. Review

<!-- Claude ghi sau khi bạn code xong -->
- Ngày, commit được review:
- Kết quả:
- Góp ý:
