# 7-A2a — E-invoice: 4 trang thiết lập sang `EInvoiceConfigurationRepository`

> **For agentic workers:** REQUIRED SUB-SKILL: dùng superpowers:subagent-driven-development (khuyên dùng) hoặc superpowers:executing-plans để làm theo từng task. Các bước dùng checkbox (`- [ ]`).

> Theme 8 (mã cũ P7) · Bước (a) chuyển kiến trúc, phần UI **thiết lập** · Gồm việc 7.2 (UI; KI-15 phần thiết lập, KI-16) — PLAN.md mục Theme 8
> Trạng thái: Plan ✅ (người dùng duyệt 2026-11-08) | Làm ⬜ | Review ⬜
> Trước: 7-A1 (Làm ✅ + Review R2 ✅; 2 repository, model, `einvoiceException`, `EInvoiceProcessorTrigger`). Sau: **7-A2b** (khu HĐĐT trên đơn, màn kết quả bán, chi tiết đơn: `Timer` 5 giây, KI-17, bỏ `QueryClient`), rồi 7-B2, 7-C.
> Tài liệu: [TH-08](../../../02-yeu-cau/TH-08-hoa-don-dien-tu.md) US HD-04 FR-04, HD-05 FR-03, 6.4, KI-15, KI-16; PLAN.md "Cách chuyển MỘT feature", "Plan xoá / tách / thay code cũ", "Plan chuyển kiến trúc: giữ nghiệp vụ…". Mẫu: `plans/P5/5-A3-catalog-ui-sang-repository.md`, `plans/P7/7-A1-einvoice-data.md`.

**Goal:** 4 trang `/more/einvoice/*` chạy trên `EInvoiceConfigurationRepository` (7-A1), cubit nằm ở `features/einvoice/logic/`, không còn import `vet45_einvoice_*` hay `async_query` trong các tệp thiết lập và trong `app_router.dart`.

**Architecture:** Chép 29 tệp thiết lập của `modules/einvoice/presentation` vào `apps/erp/lib/features/einvoice/{logic,presentation}`. 4 cubit đổi constructor sang repository, các nhánh `on XException` đổi sang so `AppException.code`. Việc hỏi lại trạng thái kết nối chuyển từ `UseQuery` (khoá cố định `'current-tenant'`) sang `Timer.periodic` trong `ProviderConnectionCubit`. Router lấy repository từ `getIt`.

**Tech Stack:** Dart / Flutter, `flutter_bloc`, `equatable`, `get_it`, `go_router`, `flutter_test`.

## Global Constraints

- **Giữ nghiệp vụ:** cùng thứ tự gọi, cùng tham số, cùng chuỗi chữ, cùng `Key`. Chỉ đổi ở Q1 (HD-04), Q2 (`CONFIG_NOT_READY`, đã chốt ở 7-A1 Q7) và Q3 (hỏi lại).
- **Chép nguyên văn:** chỉ đổi import, constructor cubit, các nhánh bắt lỗi (mục 5) và phần hỏi lại (mục 6). Không đổi tên lớp, tên `enum`, chuỗi.
- **Không đụng:** `modules/einvoice/**` (xoá ở 7-C), `features/sales/**` (7-A2b), `injection.dart` chỉ được **thêm** đăng ký (giữ `IEInvoiceModule`, `QueryClient`, `main.dart`).
- **Luật import** (`dart run tool/check_feature_imports.dart`): không thêm dòng R1 / R2 / R3 mới.
- **Trước khi sửa symbol đang có** (`einvoiceException`, 4 trang, `app_router.dart`, `injection.dart`): chạy `impact({target, direction: "upstream"})` và ghi vào Kết quả; HIGH / CRITICAL thì dừng, báo người dùng.
- Câu lỗi lấy từ `*Copy` đang có. Không thêm câu mới, không hiện `serverMessage`.

## Review Focus

1. **Hỏi lại khi lỗi mạng:** mất mạng lúc đang `checkRequired` → màn vẫn "Chờ kết nối", không nhảy màn lỗi, có mạng lại thì tự cập nhật (test Task 0 `poll error keeps pending screen`).
2. **Rời trang khi đang hỏi lại:** `close()` huỷ timer, lượt đang chờ trả về sau khi đóng không `emit` (test Task 3 `close cancels polling`).
3. **Lượt chậm hơn 2 giây:** không chồng lượt (test Task 3 `slow poll does not overlap`).
4. **Kết nối xong ra `checkRequired`:** tự bắt đầu hỏi lại, không cần rời trang (test Task 0 `connect pending then polls to connected`).
5. **Mã server lạ ở Lưu cấu hình:** `TEMPLATE_NOT_AVAILABLE` đi qua `einvoiceException` thật ra "Mẫu không tương thích" (test Task 1 + Task 3 `server template error shows incompatible`).

---

## 1. Mục tiêu

Sau 7-A2a:

```text
/more/einvoice/* (router) ─▶ Page ─▶ Cubit (features/einvoice/logic) ─▶ EInvoiceConfigurationRepository ─▶ SupabaseRpc
```

- `git grep -n "vet45_einvoice\|async_query" -- apps/erp/lib/features/einvoice apps/erp/lib/core/router` → rỗng.
- Trang Kết nối hỏi lại 2 giây bằng `Timer` trong cubit, không còn khoá `'current-tenant'` (KI-16).
- Không còn `recheck()` / `VerifyProviderConnectionCommand`, `ConfigurationBlockerResult`, `OrderDataBlockerResult` trong app (KI-15 phần thiết lập; 2 widget này chưa từng vào app, chỉ không chép).
- HD-04 hiện đúng toast "Mẫu không tương thích" / "Chưa kết nối MISA" theo FR-04 (Q1).

**Không làm:** khu HĐĐT trên đơn, `features/sales`, `QueryClient` / `main.dart` / `pubspec.yaml` (7-A2b); KI-01 dòng "Đồng bộ gần nhất" (7-B2, `EInvoiceConfigurationDisplay.lastSyncedLabel` chép nguyên); bố cục web (7-B2); xoá module, xoá test module (7-C).

## 2. Quyết định

7-A1 mục 2 (Q1–Q7) vẫn áp dụng. Số Q của 7-A2a đánh riêng:

| # | Câu hỏi | Chốt |
|---|---|---|
| Q0 | Một hay hai plan cho 7-A2 | **Người dùng chốt 2026-11-08: tách 7-A2a (thiết lập) / 7-A2b (trên đơn).** Hai nhóm không dùng chung widget, chỉ dùng chung model 7-A1 |
| Q1 | HD-04 Lưu: toast "Mẫu không tương thích" / "Chưa kết nối MISA" (TH-08 FR-04) không bao giờ hiện. `on ValidationException` chỉ bắt lỗi validator (không thể xảy ra); `on ProviderNotConnectedException` không bao giờ chạy (7-A1 Q7); server `set_default_issuance_configuration` (`20261031004:101-155`) báo `TEMPLATE_NOT_AVAILABLE` / `SIGNING_CONFIGURATION_NOT_AVAILABLE` / `STATE_CHANGED` / `NO_PERMISSION`, mà mapper cũ xếp 2 mã đầu vào `SYSTEM_ERROR` ⇒ luôn "Không lưu được" | **Người dùng chốt 2026-11-08: sửa ở 7-A2a, đổi có chủ đích.** (a) Thêm `templateNotAvailable`, `signingConfigurationNotAvailable` vào **cuối** `_seventeenCodes` (`data/einvoice_errors.dart:38-56`). (b) Cubit: `TEMPLATE_NOT_AVAILABLE` / `SIGNING_CONFIGURATION_NOT_AVAILABLE` / `VALIDATION_ERROR` → `incompatible`; `PROVIDER_NOT_CONNECTED` → `notConnected` (server chưa trả, giữ cho đúng spec); còn lại → `failed`. Hệ quả kèm theo, cũng có chủ đích: khu trên đơn (7-A2b) ra câu 6.4 của 2 mã này thay vì câu "Khác" |
| Q2 | Tự động hoá: `on ConfigNotReadyException` không bao giờ chạy | Đã chốt ở 7-A1 Q7: `CONFIG_NOT_READY` → `notReady` (đổi có chủ đích; TH-08 HD-05 AC-03) |
| Q3 | Hỏi lại trang Kết nối (KI-16) | **Người dùng duyệt thiết kế 2026-11-08.** `Timer.periodic(2 giây)` trong cubit, chạy đúng khi state là `ProviderConnectionLoaded` với `checkRequired`; mục 6 |
| Q4 | Cubit dùng `ProviderConnectionCopy.accountRequired` / `passwordRequired` / `maskAccount`, `DefaultIssuanceConfigurationCopy.templateRequired`, `EInvoiceConfigurationDisplay` (id ký); state dùng `ConfigurationQueryFailure`. Để ở `presentation/support/` thì `logic/` → `presentation/` là **R2** | Hệ quả kỹ thuật của luật import (như 5-A3 Q15): 4 tệp đó đặt ở `logic/`; `presentation/` import ngược lại (cùng feature, hợp lệ). **Duyệt plan là chốt** |
| Q5 | Quyền `EInvoicePermissions.manageConfiguration` (router) nằm ở `vet45_einvoice_domain` | `features/einvoice/logic/einvoice_permissions.dart`, chỉ hằng `manageConfiguration` (như `partner_permissions.dart`). 7-A2b thêm hằng khác nếu cần |
| Q6 | Test module (`modules/einvoice/presentation/test`) | 7 tệp thiết lập **chép** sang app (đổi sang fake repository); bản module để nguyên, xoá ở 7-C. Bỏ ca `connect sets query data and updates query cache` (kiểm cache `QueryClient`, cơ chế bị bỏ), thay bằng ca Task 0 `connect pending then polls to connected` |

## 3. Hiện trạng (đo 2026-11-08)

- `apps/erp/lib/features/einvoice/presentation/pages/` có 4 trang. Mỗi trang dựng cubit của module bằng `IEInvoiceModule` + `IExecutionContext`, rồi gắn view của module. `provider_connection_page.dart:31` truyền thêm `getIt<QueryClient>()`. `EInvoiceConfigurationOverviewPage` gọi `_cubit.load()` lại sau mỗi lần quay về từ trang con.
- `app_router.dart:10-12` import `vet45_einvoice_{application,domain,presentation}`; dùng `EInvoicePermissions.manageConfiguration` (`:1124`), `ConfigurationPermissionDeniedState` (`:1129`), `getIt<IEInvoiceModule>()` + `getIt<IExecutionContext>()` (`:1132,1148,1160,1172`).
- Module presentation: 30 tệp mà 4 trang kéo theo (đo bằng bao đóng import, 2.688 dòng), trong đó `support/einvoice_query_keys.dart` chỉ phục vụ `QueryClient` (không chép). Tệp ngoài bao đóng (khu trên đơn, toast, `ConfigurationBlockerResult`, `OrderDataBlockerResult`) **không** thuộc 7-A2a.
- Kiểu module mà 29 tệp dùng đều đã có ở `data/models/` (7-A1): `AutomationPolicyDto`, `ConfigurationReadinessDto`, `ConfigurationReadinessLevel`, `IssuanceProfileDto`, `ProviderConnectionResultDto`, `ProviderConnectionScreenDto`, `ProviderConnectionStatus`, `ProviderConnectionSummaryDto`, `ProviderTemplateDto` (có `isMtt`), `LegalProfileSummaryDto`, `ReadinessBlockerDto`, `ReadinessWarningDto`. Kiểu không chép: `IEInvoiceModule`, `IExecutionContext`, 11 Command / Query, `EInvoiceBlockedException`, `EInvoiceBlockedCodes`, `ConfigNotReadyException`, `ProviderAuthFailedException`, `ProviderNotConnectedException`, `ProviderUnavailableException`, `ValidationException`, `UseQuery`.
- Server (đo theo `raise exception` trong `20261031003`, `20261031004`): `connect_provider` → `NO_PERMISSION`, `STATE_CHANGED`, `VALIDATION_ERROR`; `reconnect_provider` → thêm `INVALID_STATUS`, `NOT_FOUND`; `disconnect_provider` → `NO_PERMISSION`, `NOT_FOUND`, `VALIDATION_ERROR`; `update_automation_policy` → `NO_PERMISSION`, `CONFIG_NOT_READY`, `STATE_CHANGED`; `set_default_issuance_configuration` → Q1. Không RPC nào trả `PROVIDER_AUTH_FAILED` / `PROVIDER_UNAVAILABLE` ⇒ đổi `on ProviderAuthFailedException` sang so mã **không** đổi hành vi thật.
- Fake: `FakeEInvoiceModule` (`modules/einvoice/application/lib/src/testing/fake_einvoice_module.dart:104-340`) + `FakeEInvoiceFixtures` (`fake_einvoice_fixtures.dart`) phục vụ 21 kịch bản thiết lập (`fake_einvoice_scenario.dart:6-33`).
- Test app đụng tới: `test/features/einvoice/presentation/einvoice_configuration_overview_page_test.dart` (140 dòng), `einvoice_subroutes_direct_access_test.dart` (93), `test/core/di/injection_test.dart` (59). Test module thiết lập: `widgets/provider_connection_view_test.dart` (10 ca), `automation_policy_view_test.dart` (3), `default_issuance_configuration_view_test.dart` (5), `einvoice_configuration_overview_view_test.dart` (6), `configuration_state_messages_test.dart` (2), `provider_connection_overlays_test.dart` (1), `bloc/provider_connection_state_test.dart` (1).

### 3.1 Đang làm gì (giữ hành vi)

| # | Cơ chế cũ (nguồn) | Hành vi | Sau 7-A2a nằm ở | Test giữ hành vi |
|---|---|---|---|---|
| H1 | `provider_connection_view.dart:62-103` `UseQuery` | Chỉ khi `connection.status == checkRequired`: hỏi `GetProviderConnectionScreenQuery` mỗi 2 giây, `initialData` = màn đang có, không hỏi khi mount | `ProviderConnectionCubit._syncPolling` / `_pollOnce` (mục 6) | Task 0 B0-1, B0-2, B0-3; ca module `pending status automatically polls…` |
| H2 | cùng chỗ, `builder` | Chỉ khi trạng thái **khác** màn đang có mới thay màn (`updateScreenFromQuery` sau khung hình) | `_pollOnce` → `updateScreenFromQuery` khi khác trạng thái | B0-1 |
| H3 | `updateScreenFromQuery` (`provider_connection_cubit.dart:62-84`) | Đang `reconnectMode` → chỉ thay `screen`, giữ lỗi ô nhập; không thì thay `screen` + `isSubmitting: false`; state chưa `Loaded` → `ProviderConnectionLoaded(screen)` | chép nguyên | Task 3 `poll update keeps reconnect mode` |
| H4 | `UseQuery` khi `queryFn` ném | Không đổi màn (builder chỉ đọc `result.data`) | `_pollOnce` nuốt lỗi | B0-1 |
| H5 | `_setConnectionQueryData` / `_invalidateConnectionQuery` sau load / connect / reconnect / disconnect | Ghi / làm mới cache để `UseQuery` dùng | Bỏ; `onChange` → `_syncPolling` thay thế | B0-4 |
| H6 | `updateErrorFromQuery` | Không ai gọi (đo `git grep`) | Không chép | — |
| H7 | `recheck()` | Không nút nào gọi (KI-15) | Không chép; `ProviderConnectionSubmitResult.verified` / `unavailable` giữ trong `enum` (view có `case`) | — |
| H8 | `_submitCredentials` | `trim` tài khoản, kiểm rỗng → lỗi ô; reconnect thiếu `connectionId` → `failed`; dựng màn mới với `maskAccount`; `checkRequired` → `verificationPending` | chép nguyên, đổi lời gọi (mục 5) | ca module `connect shows worker-pending copy…`, D04-* |
| H9 | `EInvoiceConfigurationOverviewCubit.load` | Tuần tự: readiness → màn kết nối → hồ sơ → mẫu (chỉ khi `connected`) → chính sách | chép nguyên thứ tự | ca module `disconnected overview does not query provider templates`; ca app `reloads overview after returning…` |
| H10 | `mapConfigurationQueryFailure` | `NO_PERMISSION` → `permissionDenied`; còn lại → `loadFailure` | `logic/configuration_query_failure.dart`, so `AppException.code` | `connectPermissionDenied shows S01…`; ca app subroutes |
| H11 | Router `/more/einvoice` | Thiếu quyền → `VPageScaffold` + `ConfigurationPermissionDeniedState`; trang con không kiểm quyền (dựa vào lỗi `NO_PERMISSION` khi tải) | giữ, đổi import | ca app subroutes |
| H12 | Trang Tổng quan | `load()` lại sau khi quay về từ mỗi trang con | giữ | ca app `reloads overview…` |

## 4. Tệp

Tạo dưới `apps/erp/lib/features/einvoice/` (nguồn `modules/einvoice/presentation/lib/src/`, chép nguyên văn trừ chỗ ghi ở mục 5, 6):

| Tệp mới | Nguồn |
|---|---|
| `logic/provider_connection_cubit.dart`, `logic/provider_connection_state.dart` | `bloc/` |
| `logic/einvoice_configuration_overview_cubit.dart`, `logic/einvoice_configuration_overview_state.dart` | `bloc/` |
| `logic/default_issuance_configuration_cubit.dart`, `logic/default_issuance_configuration_state.dart` | `bloc/` |
| `logic/automation_policy_cubit.dart`, `logic/automation_policy_state.dart` | `bloc/` |
| `logic/configuration_query_failure.dart`, `logic/provider_connection_copy.dart`, `logic/default_issuance_configuration_copy.dart`, `logic/einvoice_configuration_display.dart` | `support/` (Q4) |
| `logic/einvoice_permissions.dart` | mới (Q5): `abstract final class EInvoicePermissions { static const manageConfiguration = 'einvoice.manage_configuration'; }` |
| `presentation/support/{automation_policy_copy,configuration_state_copy,einvoice_configuration_overview_copy,einvoice_datetime_copy}.dart` | `support/` |
| `presentation/widgets/{automation_policy_view,configuration_editor_bottom_bar,configuration_load_error_state,configuration_permission_denied_state,configuration_query_failure_view,default_issuance_configuration_view,disconnect_provider_sheet,einvoice_configuration_overview_view,provider_connection_view,readiness_summary,settings_info_row,settings_navigation_item,switch_setting_row}.dart` | `widgets/` |

Sửa: 4 tệp `presentation/pages/*.dart`, `data/einvoice_errors.dart:38-56`, `core/router/app_router.dart:10-12,28-31,1111-1178`, `core/di/injection.dart` (thêm sau `ReturnExchangeRepository`), `docs/refactor/PLAN.md` (dòng 7-A2a), `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md` (KI-16 ghi "xong 7-A2a"; KI-15 ghi phần thiết lập xong).

Test: mục 7.

## 5. Bắt lỗi trong cubit

`AppException` lấy từ `package:erp/core/errors/app_exception.dart`; mã so bằng `EInvoiceErrorCodes` (`data/einvoice_errors.dart`).

| Chỗ (nguồn) | Cũ | Mới |
|---|---|---|
| 4 cubit `load()` | `catch (error)` → `mapConfigurationQueryFailure(error)` | giữ; `mapConfigurationQueryFailure(Object error)` = `error is AppException && error.code == EInvoiceErrorCodes.noPermission ? permissionDenied : loadFailure` |
| `ProviderConnectionCubit._submitCredentials` | `on ProviderAuthFailedException` → `authFailed`; `catch (_)` → `failed` | `on AppException catch (e) when e.code == EInvoiceErrorCodes.providerAuthFailed` → `authFailed`; `catch (_)` → `failed` |
| `ProviderConnectionCubit.disconnect` | `catch (_)` → `failed` | giữ |
| `AutomationPolicyCubit.save` | `on ConfigNotReadyException` → `notReady`; `on EInvoiceBlockedException` mã `stateChanged` → `stateChanged`; còn lại → `failed` | `on AppException catch (e)`: `configNotReady` → `notReady` (Q2); `stateChanged` → `stateChanged`; khác → `failed`; `catch (_)` → `failed` |
| `DefaultIssuanceConfigurationCubit.save` | `on ProviderNotConnectedException` → `notConnected`; `on ValidationException` → `incompatible`; còn lại → `failed` | `on AppException catch (e)`: `providerNotConnected` → `notConnected`; `templateNotAvailable` / `signingConfigurationNotAvailable` / `validationError` → `incompatible` (Q1); khác → `failed`; `catch (_)` → `failed` |

Lời gọi mới (tham số **giống** Command cũ, bỏ `tenantId` / `actorId`):

| Cũ | Mới (`EInvoiceConfigurationRepository`) |
|---|---|
| `GetConfigurationReadinessQuery` | `getConfigurationReadiness()` |
| `GetProviderConnectionScreenQuery` | `getConnectionScreen()` |
| `GetIssuanceProfileQuery` | `getIssuanceProfile()` |
| `ListProviderTemplatesQuery` | `listTemplates()` |
| `GetAutomationPolicyQuery` | `getAutomationPolicy()` |
| `UpdateAutomationPolicyCommand(autoIssueEnabled, autoSendEnabled, expectedPolicyVersion)` | `updateAutomationPolicy(expectedPolicyVersion: …, autoIssueEnabled: …, autoSendEnabled: …)` |
| `SetDefaultIssuanceConfigurationCommand(templateId, signingConfigId, expectedProfileVersion)` | `setDefaultConfiguration(templateId: …, signingConfigId: …, expectedProfileVersion: …)` |
| `ConnectProviderCommand(username: trimmedAccount, password)` | `connect(username: trimmedAccount, password: password)` |
| `ReconnectProviderCommand(connectionId, username, password, expectedConnectionVersion)` | `reconnect(connectionId: …, username: …, password: …, expectedConnectionVersion: …)` |
| `DisconnectProviderCommand(connectionId, confirm: true)` | `disconnect(connectionId: connectionId, confirm: true)` |

## 6. Hỏi lại trong `ProviderConnectionCubit` (Q3)

```dart
ProviderConnectionCubit({
  required EInvoiceConfigurationRepository repository,
  Duration pollInterval = const Duration(seconds: 2),
});
```

- `Timer? _pollTimer; bool _pollInFlight = false;`
- `@override void onChange(Change<ProviderConnectionState> change)`: gọi `super.onChange(change)` rồi `_syncPolling(change.nextState)`. Lưu ý: `onChange` chạy **trước** khi `state` đổi, nên phải dùng `change.nextState`.
- `_syncPolling(next)`: `pending = next is ProviderConnectionLoaded && next.screen.connection.status == ProviderConnectionStatus.checkRequired`. Nếu `pending`, `_pollTimer == null` và `!isClosed` thì `_pollTimer = Timer.periodic(pollInterval, (_) => _pollOnce())`. Nếu `!pending` thì `cancel` và gán `null`.
- `_pollOnce()`: nếu `_pollInFlight || isClosed` thì `return`. Đặt `_pollInFlight = true`, rồi `try { final screen = await _repository.getConnectionScreen(); if (isClosed) return; final current = state; if (current is ProviderConnectionLoaded && screen.connection.status != current.screen.connection.status) updateScreenFromQuery(screen); } catch (_) {} finally { _pollInFlight = false; }`.
- `close()`: `_pollTimer?.cancel(); _pollTimer = null;` rồi `super.close()`.
- `ProviderConnectionView`: bỏ `UseQuery` (`:62-103`). `_ProviderConnectionLoadedBody.build` trả thẳng `_ProviderConnectionBody(state: state, onCancel: onCancel)`.
- `ProviderConnectionPage`: bỏ `queryClient`, bỏ import `async_query`.

## 7. Task

### Task 0: Bước 0 — test giữ hành vi trên code cũ

**Files:**
- Modify: `modules/einvoice/presentation/test/widgets/provider_connection_view_test.dart` (thêm 4 ca; dùng `_SequencedConnectionModule` có sẵn, thêm `Object?` vào danh sách để ném lỗi khi phần tử là `Exception`, thêm nhánh `ConnectProviderCommand` trả `ProviderConnectionResultDto(connectionId: 'connection-1', status: checkRequired)`)

Chỉ thêm test vào module, **không** sửa code module. Đây là ngoại lệ có chủ đích của ràng buộc "Không đụng `modules/einvoice/**`" ở Global Constraints. Bốn ca chạy trên code cũ, phải xanh trước Task 1. Task 4 chép nguyên các ca này sang app.

- [x] **B0-1** `poll error keeps pending screen`: chuỗi `[pending, Exception('net'), connected]`. Sau `pump(2s)` + `pump()` + `pump(100ms)`: thấy `'Chờ kết nối'`, không thấy `'Không thể tải dữ liệu'` (`ConfigurationStateCopy.loadErrorTitle`). Sau thêm tối đa 2 nhịp 2 giây: thấy `'Đã kết nối'`. Nếu trên code cũ `UseQuery` thử lại khiến số nhịp khác, ghi số nhịp thật vào Kết quả và dùng đúng số đó ở Task 4.
- [x] **B0-2** `polling stops after status leaves checkRequired`: `[pending, connected]`. Chờ tới khi thấy `'Đã kết nối'`, ghi `n = module.queryCount`, `pump(6s)` → `module.queryCount == n`.
- [x] **B0-3** `no polling when not pending`: `[connected]`. `pump(6s)` → `queryCount == 1`.
- [x] **B0-4** `connect pending then polls to connected`: `[disconnected, connected]`. Nhập tài khoản / mật khẩu, bấm `provider_connection_submit` (connect trả `checkRequired`) → thấy `'Chờ kết nối'`. Sau tối đa 2 nhịp 2 giây → thấy `'Đã kết nối'`.
- [x] Chạy `cd modules/einvoice/presentation && flutter test test/widgets/provider_connection_view_test.dart` → PASS (14 ca). Ghi số nhịp thật của B0-1, B0-4 vào Kết quả.
- [x] Commit `test(einvoice): 7-A2a bước 0 — giữ hành vi hỏi lại trang kết nối`.

### Task 1: `einvoiceException` nhận 2 mã cấu hình (Q1)

**Files:**
- Modify: `apps/erp/lib/features/einvoice/data/einvoice_errors.dart:38-56`
- Test: `apps/erp/test/features/einvoice/data/einvoice_errors_test.dart`, `apps/erp/test/features/einvoice/logic/einvoice_error_messages_test.dart`

**Interfaces:** Produces: `einvoiceException(PostgrestException('TEMPLATE_NOT_AVAILABLE: …'))` có `.code == EInvoiceErrorCodes.templateNotAvailable`.

- [x] `impact({target: "einvoiceException", direction: "upstream"})`, ghi vào Kết quả.
- [x] Thêm ca (đỏ) vào `einvoice_errors_test.dart`:
  - `template_not_available_code`: `einvoiceException(AppException('SYSTEM_ERROR', cause: PostgrestException(message: 'TEMPLATE_NOT_AVAILABLE: template has no invoice series', code: 'P0001')))` → `code == 'TEMPLATE_NOT_AVAILABLE'`, `serverMessage` là message gốc.
  - `signing_not_available_code`: tương tự với `'SIGNING_CONFIGURATION_NOT_AVAILABLE: MTT template requires SignType=5'` → `'SIGNING_CONFIGURATION_NOT_AVAILABLE'`.
  - `earlier_code_wins_over_template`: `'STATE_CHANGED: TEMPLATE_NOT_AVAILABLE'` → `'STATE_CHANGED'`.
  - `issuance_not_ready_still_wins`: `'ISSUANCE_NOT_READY: {"details":{"blockers":["TEMPLATE_NOT_AVAILABLE"]}}'` → `'ISSUANCE_NOT_READY'`, `details['blockers'] == ['TEMPLATE_NOT_AVAILABLE']`.
- [x] Chạy `cd apps/erp && flutter test test/features/einvoice/data/einvoice_errors_test.dart` → 2 ca đầu FAIL.
- [x] Thêm `EInvoiceErrorCodes.templateNotAvailable`, `EInvoiceErrorCodes.signingConfigurationNotAvailable` vào **cuối** `_seventeenCodes`; đổi tên hằng thành `_codesByPriority` (tên cũ sai số lượng). Sửa chú thích "17 mã" nếu có.
- [x] Thêm ca vào `einvoice_error_messages_test.dart`: `einvoiceErrorMessage(einvoiceException(<PostgrestException TEMPLATE_NOT_AVAILABLE>))` == `'Mẫu hóa đơn đã chọn không còn khả dụng. Vui lòng cập nhật cấu hình phát hành.'` (`einvoice_error_messages.dart:39`).
- [x] Chạy `flutter test test/features/einvoice/` → PASS. Ghi số ca.
- [x] Commit `feat(einvoice): 7-A2a einvoiceException nhận TEMPLATE_NOT_AVAILABLE / SIGNING_CONFIGURATION_NOT_AVAILABLE`.

### Task 2: Fake repository

**Files:**
- Create: `apps/erp/test/features/einvoice/support/fake_einvoice_configuration_repository.dart`
- Test: `apps/erp/test/features/einvoice/support/fake_einvoice_configuration_repository_test.dart`

**Interfaces:** Produces:

```dart
enum FakeEInvoiceConfigurationScenario { /* 21 giá trị, cùng tên với FakeEInvoiceScenario dòng 6-33 */ }
abstract final class FakeEInvoiceConfigurationFixtures { /* phần thiết lập của FakeEInvoiceFixtures, cùng tên, kiểu app */ }
class FakeEInvoiceConfigurationRepository extends EInvoiceConfigurationRepository {
  FakeEInvoiceConfigurationRepository({this.scenario = FakeEInvoiceConfigurationScenario.connectionScreenOk});
  final FakeEInvoiceConfigurationScenario scenario;
  final List<String> calls; // tên hàm theo thứ tự gọi, vd 'getConnectionScreen'
}
```

- Constructor cha cần `rpc`, `trigger`, `tenantId`, `actorId`. Truyền một `SupabaseRpc` giả (`implements SupabaseRpc`, mọi hàm ném `UnimplementedError`, như `_RecordingRpc` ở `einvoice_configuration_repository_test.dart:18`), `EInvoiceProcessorTrigger` dựng từ `FunctionsClient` giả theo `einvoice_processor_trigger_test.dart`, `tenantId: () async => 'tenant-1'`, `actorId: () async => 'actor-1'`; override cả 10 hàm (lớp cha là `class`, `einvoice_configuration_repository.dart:9`).
- Thân mỗi hàm chép nhánh tương ứng của `FakeEInvoiceModule` (`fake_einvoice_module.dart:142-340`), đổi lỗi:

| Fake cũ ném | Fake mới ném |
|---|---|
| `EInvoiceBlockedException(noPermission)` | `AppException(EInvoiceErrorCodes.noPermission)` |
| `EInvoiceBlockedException(systemError, message: 'Không thể tải thiết lập hóa đơn điện tử')` | `AppException(EInvoiceErrorCodes.systemError, serverMessage: <cùng chuỗi>)` |
| `ProviderAuthFailedException()` | `AppException(EInvoiceErrorCodes.providerAuthFailed)` |
| `EInvoiceBlockedException(validationError, …, details: {'subcode': 'legal_mismatch'})` | `AppException(EInvoiceErrorCodes.validationError, serverMessage: 'Legal identity mismatch', details: {'subcode': 'legal_mismatch'})` |
| `ProviderNotConnectedException()` | `AppException(EInvoiceErrorCodes.providerNotConnected)` |
| `ValidationException('Incompatible template and signing')` (`setDefaultIncompatible`) | `AppException(EInvoiceErrorCodes.templateNotAvailable)`, dạng server thật (Q1) |
| `ConfigNotReadyException(...)` | `AppException(EInvoiceErrorCodes.configNotReady)` |
| `EInvoiceBlockedException(stateChanged)` | `AppException(EInvoiceErrorCodes.stateChanged)` |

- `_throwIfConfigurationQueryBlocked` áp cho 5 hàm đọc như cũ.

- [x] Test (đỏ): `connectAuthFailed` → `connect` ném `AppException` mã `PROVIDER_AUTH_FAILED`; `setDefaultIncompatible` → `TEMPLATE_NOT_AVAILABLE`; `connectionScreenPending` → `getConnectionScreen()` trả `checkRequired`; `configurationLoadFailure` → cả 5 hàm đọc ném `SYSTEM_ERROR`; `calls` ghi đúng thứ tự.
- [x] Viết fake → `flutter test test/features/einvoice/support/` PASS.
- [x] Commit `test(einvoice): 7-A2a fake EInvoiceConfigurationRepository`.

### Task 3: Chép 29 tệp + đổi 4 cubit

**Files:** mục 4 (tạo 30 tệp). Test: `apps/erp/test/features/einvoice/logic/{provider_connection_cubit_test,automation_policy_cubit_test,default_issuance_configuration_cubit_test}.dart`.

**Interfaces:**
- Consumes: `EInvoiceConfigurationRepository` (7-A1), `EInvoiceErrorCodes`, model `data/models.dart`, fake Task 2.
- Produces: 4 cubit, mỗi cubit `({required EInvoiceConfigurationRepository repository})`, riêng `ProviderConnectionCubit` có thêm `Duration pollInterval` (mục 6); bỏ getter `einvoiceModule` / `executionContext`. Các `enum` `*SaveResult` / `ProviderConnectionSubmitResult` và state giữ nguyên tên, giá trị.

- [x] Chép 29 tệp theo mục 4, đổi import (`package:erp/features/einvoice/...`), chưa đổi thân.
- [x] Viết test cubit (đỏ):
  - `provider_connection_cubit_test.dart`:
    - `close cancels polling`: fake `connectionScreenPending`, `pollInterval: 10ms` (app không có `fake_async`: dùng `await Future<void>.delayed(...)` thật). `await load()` rồi `await close()`, chờ thêm 50ms → `calls.where((c) => c == 'getConnectionScreen').length == 1`.
    - `slow poll does not overlap`: repository con mà `getConnectionScreen` lần 2 chờ `Completer`. `pollInterval: 10ms`; chờ 35ms → đúng 2 lần gọi (load + lượt đang treo). `complete` xong, chờ thêm 15ms → 3 lần.
    - `poll update keeps reconnect mode`: state `Loaded(screen: reconnectRequired, reconnectMode: true, accountError: 'x')` dựng qua `emit` trong test con. Gọi `updateScreenFromQuery(<pending>)` → `reconnectMode` vẫn `true`, `accountError` vẫn `'x'`.
    - `auth failed code maps to authFailed`: `connectAuthFailed` → `connect(...) == ProviderConnectionSubmitResult.authFailed`.
  - `automation_policy_cubit_test.dart`: `enableAutoIssueNotReady` → `save() == notReady`; `automationStateChanged` → `stateChanged`; `AppException('SYSTEM_ERROR')` → `failed`.
  - `default_issuance_configuration_cubit_test.dart`:
    - `server template error shows incompatible`: repository con ném `einvoiceException(AppException('SYSTEM_ERROR', cause: PostgrestException(message: 'TEMPLATE_NOT_AVAILABLE: …')))` → `incompatible`;
    - `SIGNING_CONFIGURATION_NOT_AVAILABLE` → `incompatible`;
    - `setDefaultNotConnected` (fake ném ở `listTemplates` nên `load` lỗi): dùng repository con chỉ ném ở `setDefaultConfiguration` → `notConnected`;
    - `STATE_CHANGED` → `failed`;
    - `signing id`: mẫu `isMtt: true` → gọi `setDefaultConfiguration` với `signingConfigId == 'sign-nosign'`, ngược lại `'sign-hsm'`.
- [x] Đổi 4 cubit theo mục 5 + mục 6; bỏ `recheck()`, `updateErrorFromQuery`, `_setConnectionQueryData`, `_invalidateConnectionQuery`.
- [x] Sửa `ProviderConnectionView` theo mục 6 (bỏ `UseQuery`).
- [x] `flutter test test/features/einvoice/logic/` PASS; `dart analyze lib/features/einvoice` sạch; `dart run tool/check_feature_imports.dart` không dòng `einvoice` mới ngoài 4 dòng R1 đã có.
- [x] Commit `feat(einvoice): 7-A2a chép UI thiết lập, cubit dùng EInvoiceConfigurationRepository, hỏi lại bằng Timer`.

### Task 4: Chép 7 tệp test module

**Files:** Create dưới `apps/erp/test/features/einvoice/`:
- `presentation/widgets/{provider_connection_view_test,automation_policy_view_test,default_issuance_configuration_view_test,einvoice_configuration_overview_view_test,configuration_state_messages_test,provider_connection_overlays_test}.dart`
- `logic/provider_connection_state_test.dart`

- [x] Chép nguyên văn, đổi:
  - `FakeEInvoiceModule(scenario: X)` → `FakeEInvoiceConfigurationRepository(scenario: FakeEInvoiceConfigurationScenario.X)`;
  - bỏ `QueryClientProvider` / `QueryClient` / `FakeExecutionContext`;
  - cubit nhận `repository:`.
  - `_SequencedConnectionModule` → `_SequencedConnectionRepository extends FakeEInvoiceConfigurationRepository`, override `getConnectionScreen` và `connect`, giữ `queryCount`. Bỏ `verifyCount` và nhánh Verify.
  - `_DisconnectedOverviewModule` (`einvoice_configuration_overview_view_test.dart:12`) → repository con tương ứng.
- [x] Bỏ ca `connect sets query data and updates query cache` (Q6). Giữ 4 ca Task 0, đúng số nhịp đã ghi.
- [x] `flutter test test/features/einvoice/presentation/widgets test/features/einvoice/logic` → PASS. Số ca = số ca module (28) − 1 + 4 = **31**, cộng số ca Task 3.
- [x] Commit `test(einvoice): 7-A2a chép test UI thiết lập sang app`.

### Task 5: Trang, router, DI

**Files:**
- Modify: 4 tệp `apps/erp/lib/features/einvoice/presentation/pages/*.dart`, `apps/erp/lib/core/router/app_router.dart`, `apps/erp/lib/core/di/injection.dart`
- Test: `apps/erp/test/features/einvoice/presentation/einvoice_configuration_overview_page_test.dart`, `einvoice_subroutes_direct_access_test.dart`, `apps/erp/test/core/di/injection_test.dart`

**Interfaces:** Produces: mỗi trang `({Key? key, required EInvoiceConfigurationRepository repository, …callback như cũ})`.

- [x] `impact` cho 4 lớp trang, `AppRouter` / hàm dựng route liên quan, `initDependencies`; ghi vào Kết quả.
- [x] Sửa 3 test app (đỏ):
  - `einvoice_configuration_overview_page_test.dart`: `_CountingEinvoiceModule` → `_CountingRepository extends FakeEInvoiceConfigurationRepository`, đếm `getConnectionScreen`; ca `reloads overview after returning…` vẫn kỳ vọng `2`;
  - `einvoice_subroutes_direct_access_test.dart`: `_ForbiddenEinvoiceModule` → repository mà mọi hàm ghi tên vào `writes` / `reads` rồi ném `AppException(EInvoiceErrorCodes.noPermission)`. Kỳ vọng giữ: thấy `Key('wgt_e01_s01_01')`, không hàm ghi nào được gọi (`connect`, `reconnect`, `disconnect`, `setDefaultConfiguration`, `updateAutomationPolicy`);
  - `injection_test.dart`: thêm `expect(getIt.isRegistered<EInvoiceProcessorTrigger>(), isTrue); expect(getIt.isRegistered<EInvoiceConfigurationRepository>(), isTrue);`, giữ các dòng `IEInvoiceModule`.
- [x] Trang: thay `einvoiceModule` + `executionContext` bằng `repository`; import cubit / view mới; `ProviderConnectionPage` bỏ `getIt` / `QueryClient`.
- [x] `injection.dart`, sau `ReturnExchangeRepository`:
  - `registerLazySingleton<EInvoiceProcessorTrigger>(() => EInvoiceProcessorTrigger(supabaseModule.client.functions))`;
  - `registerLazySingleton<EInvoiceConfigurationRepository>(() => EInvoiceConfigurationRepository(rpc: getIt<SupabaseRpc>(), trigger: getIt<EInvoiceProcessorTrigger>(), tenantId: …, actorId: …))`, với `tenantId` / `actorId` viết giống hệt `PartnerRepository` (`injection.dart:112-118`).
- [x] `app_router.dart`: bỏ 3 import `vet45_einvoice_*`; import `features/einvoice/logic/einvoice_permissions.dart`, `features/einvoice/presentation/widgets/configuration_permission_denied_state.dart`, `features/einvoice/data/einvoice_configuration_repository.dart`; 4 route truyền `repository: getIt<EInvoiceConfigurationRepository>()`.
- [x] `flutter test test/features/einvoice/ test/core/di/injection_test.dart test/features/more/` → PASS.
- [x] Commit `feat(einvoice): 7-A2a trang thiết lập, router, DI dùng repository`.

### Task 6: Kiểm cuối + tài liệu

- [x] **6.1** `cd apps/erp && dart analyze lib test/features/einvoice test/core/di` → không lỗi / cảnh báo mới.
- [x] **6.2** `dart run tool/check_feature_imports.dart` → không dòng mới so với trước 7-A2a (ghi danh sách dòng `einvoice`).
- [x] **6.3** `git grep -n "vet45_einvoice\|async_query" -- apps/erp/lib/features/einvoice apps/erp/lib/core/router` → rỗng. `git grep -n "recheck\|VerifyProviderConnection\|current-tenant" -- apps/erp/lib/features/einvoice` → rỗng.
- [x] **6.4** `flutter test test/features/einvoice/` → PASS (ghi số ca). `flutter test` cả app → số lỗi đúng bằng `docs/refactor/TEST-BASELINE.md` mục "Sau 8-C" (55, so từng tên). `cd modules/einvoice/presentation && flutter test` → 79 + 4 ca Task 0, 0 lỗi.
- [x] **6.5** TH-08: KI-16 cột cuối ghi "✅ 7-A2a (2026-…)"; KI-15 ghi "phần thiết lập ✅ 7-A2a; `OrderDataBlockerResult` không vào app". PLAN.md: dòng 7-A2a cột Làm.
- [x] **6.6** `node .gitnexus/run.cjs analyze` rồi `detect_changes({scope: "all"})`. Chỉ được có tệp mục 4 + test + tài liệu. Ghi số tệp / symbol / luồng / rủi ro, kể cả các tệp mới chưa theo dõi.
- [ ] **6.7** Kiểm tay (iPhone + web, Dev, tài khoản có `einvoice.manage_configuration`):
  - Thiết lập → Hoá đơn điện tử: 3 thẻ hiện đúng;
  - Kết nối MISA khi đang "Chờ kết nối": ≤ 2 giây sau khi bộ xử lý xong thì đổi sang "Đã kết nối", không cần rời trang;
  - Cấu hình phát hành: Lưu mẫu hợp lệ → toast thành công;
  - Tự động hoá: bật khi chưa có mẫu → "Chưa đủ điều kiện";
  - tài khoản không có quyền → màn "Không có quyền truy cập".

## 8. Rủi ro / lưu ý

- **Hai bản cùng tên lớp:** sau 7-A2a, app có `ProviderConnectionCubit`… ở `features/einvoice` và module vẫn export cùng tên. Sales (7-A2b) vẫn import module presentation, nhưng không import tệp mới ⇒ không đụng tên. Tệp nào import cả hai thì phải `hide`; theo đo, không có tệp nào.
- **Đổi tenant khi đang hỏi lại:** repository đọc `tenantId()` mỗi lần gọi ⇒ lượt sau dùng tenant mới. Trang được dựng lại theo `StoreShell`, nên không giữ màn của tenant cũ (KI-16 hết khoá cố định).
- **Số nhịp B0-1 / B0-4:** `UseQuery` có thể thử lại khi lỗi. Task 0 ghi số thật; `Timer` mới bỏ qua lỗi và đợi nhịp sau. Nếu số nhịp mới khác bản cũ, ghi lệch vào Kết quả để review quyết.
- `EInvoiceConfigurationDisplay.lastSyncedLabel` vẫn là chuỗi cố định (KI-01, 7-B2).

## 9. Kết quả (phiên làm code ghi)

- **Task 0 — ✅**
  - Tệp:dòng đã đổi / thêm: `modules/einvoice/presentation/test/widgets/provider_connection_view_test.dart`:15-46 (mở rộng `_SequencedConnectionModule` nhận `List<Object?>`, ném lỗi nếu `Exception`, hỗ trợ `ConnectProviderCommand`), :347-514 (thêm 4 ca B0-1, B0-2, B0-3, B0-4).
  - Lệch plan + lý do: Không.
  - Test thêm / sửa, lệnh, số ca pass / fail: `cd modules/einvoice/presentation && flutter test test/widgets/provider_connection_view_test.dart` → 14/14 PASS.
  - Số nhịp thật: B0-1 cần 1 nhịp 2s để chạm `Exception('net')` và 1 nhịp 2s nữa để sang 'Đã kết nối' (tổng 2 nhịp 2s); B0-4 cần 1 nhịp 2s sau khi submit để sang 'Đã kết nối'.
  - Impact (symbol, số caller, luồng, mức rủi ro): Không (chỉ thêm test vào file test).
  - Ghi chú cho review: 4 ca kiểm chứng hành vi hỏi lại trên code cũ đều xanh; số nhịp chuyển trạng thái ăn khớp hoàn toàn với lý thuyết.

- **Task 1 — ✅**
  - Tệp:dòng đã đổi / thêm:
    - `apps/erp/lib/features/einvoice/data/einvoice_errors.dart`:38-56 (thêm `templateNotAvailable`, `signingConfigurationNotAvailable` vào cuối `_codesByPriority`, sửa vòng lặp :112).
    - `apps/erp/test/features/einvoice/data/einvoice_errors_test.dart`:12-20 (bỏ `TEMPLATE_NOT_AVAILABLE` khỏi parity cũ), :104-144 (thêm 4 ca: template_not_available_code, signing_not_available_code, earlier_code_wins_over_template, issuance_not_ready_still_wins).
    - `apps/erp/test/features/einvoice/logic/einvoice_error_messages_test.dart`:1-7, :198-208 (thêm ca kiểm einvoiceErrorMessage với einvoiceException mã TEMPLATE_NOT_AVAILABLE).
  - Lệch plan + lý do: Không.
  - Test thêm / sửa, lệnh, số ca pass / fail: `flutter test test/features/einvoice/` → 177 passed, 10 skipped, 0 failed.
  - Impact (symbol, số caller, luồng, mức rủi ro): `einvoiceException` (caller nội bộ `einvoice_configuration_repository.dart`, `einvoice_repository.dart`, `einvoice_errors_test.dart`). GitNexus impact upstream: direct 444 (chỉ số stale do chuỗi regex match file test/specs), trên thực tế chỉ ảnh hưởng 2 repository HĐĐT và các test liên quan; rủi ro thực tế: LOW (chỉ mở rộng 2 mã ở cuối danh sách ưu tiên theo Q1).
  - Ghi chú cho review: 2 mã cấu hình mới được ưu tiên sau các mã lỗi trạng thái/quyền, đảm bảo không che lấp `STATE_CHANGED` hay `ISSUANCE_NOT_READY`.

- **Task 2 — ✅**
  - Tệp:dòng đã đổi / thêm:
    - Tạo `apps/erp/test/features/einvoice/support/fake_einvoice_configuration_repository.dart` (định nghĩa `FakeEInvoiceConfigurationScenario`, `FakeEInvoiceConfigurationFixtures`, `FakeEInvoiceConfigurationRepository` kế thừa `EInvoiceConfigurationRepository`, override cả 10 phương thức, ánh xạ lỗi theo bảng mục 5 và ghi nhận thứ tự `calls`).
    - Tạo `apps/erp/test/features/einvoice/support/fake_einvoice_configuration_repository_test.dart` (5 ca kiểm tra các kịch bản ném lỗi và thứ tự ghi nhận calls).
  - Lệch plan + lý do: Không.
  - Test thêm / sửa, lệnh, số ca pass / fail: `flutter test test/features/einvoice/support/` → 5/5 PASS.
  - Impact (symbol, số caller, luồng, mức rủi ro): Fake trong thư mục test, không ảnh hưởng code production.
  - Ghi chú cho review: Sẵn sàng phục vụ Task 3 (test cubit), Task 4 (chép test module), Task 5 (test page/router).

- **Task 3 — ✅**
  - Tệp:dòng đã đổi / thêm:
    - Tạo 30 tệp theo mục 4 trong `apps/erp/lib/features/einvoice/`:
      - `logic/`: `einvoice_permissions.dart`, `configuration_query_failure.dart`, `provider_connection_copy.dart`, `default_issuance_configuration_copy.dart`, `einvoice_configuration_display.dart`, `einvoice_configuration_overview_state.dart`, `einvoice_configuration_overview_cubit.dart`, `automation_policy_state.dart`, `automation_policy_cubit.dart`, `default_issuance_configuration_state.dart`, `default_issuance_configuration_cubit.dart`, `provider_connection_state.dart`, `provider_connection_cubit.dart`.
      - `presentation/support/`: `automation_policy_copy.dart`, `configuration_state_copy.dart`, `einvoice_configuration_overview_copy.dart`, `einvoice_datetime_copy.dart`.
      - `presentation/widgets/`: `configuration_load_error_state.dart`, `configuration_permission_denied_state.dart`, `configuration_query_failure_view.dart`, `settings_info_row.dart`, `settings_navigation_item.dart`, `switch_setting_row.dart`, `configuration_editor_bottom_bar.dart`, `disconnect_provider_sheet.dart`, `readiness_summary.dart`, `einvoice_configuration_overview_view.dart`, `automation_policy_view.dart`, `default_issuance_configuration_view.dart`, `provider_connection_view.dart`.
    - Viết test cubit:
      - `apps/erp/test/features/einvoice/logic/provider_connection_cubit_test.dart` (4 ca: close cancels polling, slow poll does not overlap, poll update keeps reconnect mode, auth failed code maps to authFailed).
      - `apps/erp/test/features/einvoice/logic/automation_policy_cubit_test.dart` (3 ca: enableAutoIssueNotReady, automationStateChanged, AppException systemError).
      - `apps/erp/test/features/einvoice/logic/default_issuance_configuration_cubit_test.dart` (5 ca: server template error shows incompatible, SIGNING_CONFIGURATION_NOT_AVAILABLE, setDefaultNotConnected, STATE_CHANGED, signing id).
  - Lệch plan + lý do: Đổi `ProviderConnectionCubit` từ `final class` sang `class` để cho phép test subclass phát `emit` kiểm tra giữ reconnect mode.
  - Test thêm / sửa, lệnh, số ca pass / fail: `flutter test test/features/einvoice/logic/` → 59/59 PASS. `dart analyze lib/features/einvoice` → 0 errors, 0 warnings. `dart run tool/check_feature_imports.dart` → giữ nguyên 4 dòng R1 hiện có của `einvoice`, không phát sinh vi phạm mới.
  - Impact (symbol, số caller, luồng, mức rủi ro): Toàn bộ 4 cubit và 30 tệp thiết lập mới nằm trong `features/einvoice`, chưa nối vào router/pages, rủi ro: LOW.
  - Ghi chú cho review: Cơ chế hỏi lại của `ProviderConnectionCubit` chuyển sang `Timer` 2 giây hoàn toàn khép kín trong cubit; `ProviderConnectionView` không còn dùng `UseQuery`.

- **Task 4 — ✅**
  - Tệp:dòng đã đổi / thêm:
    - Tạo 7 tệp test dưới `apps/erp/test/features/einvoice/`:
      - `logic/provider_connection_state_test.dart` (1 ca)
      - `presentation/widgets/configuration_state_messages_test.dart` (2 ca)
      - `presentation/widgets/provider_connection_overlays_test.dart` (1 ca)
      - `presentation/widgets/automation_policy_view_test.dart` (3 ca)
      - `presentation/widgets/default_issuance_configuration_view_test.dart` (5 ca)
      - `presentation/widgets/einvoice_configuration_overview_view_test.dart` (6 ca)
      - `presentation/widgets/provider_connection_view_test.dart` (13 ca: 9 ca chuyển từ module - bỏ 1 ca query cache Q6 + 4 ca Task 0 B0-1..B0-4)
  - Lệch plan + lý do: Không.
  - Test thêm / sửa, lệnh, số ca pass / fail: `cd apps/erp && flutter test test/features/einvoice/presentation/widgets test/features/einvoice/logic` → 90/90 PASS (31 ca chuyển từ module + 59 ca unit test logic & Task 3).
  - Impact (symbol, số caller, luồng, mức rủi ro): File test, rủi ro: LOW.
  - Ghi chú cho review: Toàn bộ 7 file test UI thiết lập của module đã được chuyển sang app, chạy mượt mà với `FakeEInvoiceConfigurationRepository` và Timer polling của `ProviderConnectionCubit`.

- **Task 5 — ✅**
  - Tệp:dòng đã đổi / thêm:
    - `apps/erp/lib/features/einvoice/presentation/pages/einvoice_configuration_overview_page.dart`: nhận `required EInvoiceConfigurationRepository repository`, chuyển sang dùng `EInvoiceConfigurationOverviewCubit` và `EInvoiceConfigurationOverviewView` mới.
    - `apps/erp/lib/features/einvoice/presentation/pages/provider_connection_page.dart`: nhận `repository:`, loại bỏ hoàn toàn `queryClient` và `async_query`.
    - `apps/erp/lib/features/einvoice/presentation/pages/default_issuance_configuration_page.dart`: nhận `repository:`, dùng cubit và view mới.
    - `apps/erp/lib/features/einvoice/presentation/pages/automation_policy_page.dart`: nhận `repository:`, dùng cubit và view mới.
    - `apps/erp/lib/core/di/injection.dart`:14-15, :267-279: đăng ký `EInvoiceProcessorTrigger` và `EInvoiceConfigurationRepository` (dùng `SessionController.requireTenantId` và `sessionStore.userId`) sau `ReturnExchangeRepository`.
    - `apps/erp/lib/core/router/app_router.dart`:10-12, :1130-1175: loại bỏ 3 import `vet45_einvoice_*`, import `EInvoiceConfigurationRepository`, `EInvoicePermissions`, `ConfigurationPermissionDeniedState`; 4 route truyền `repository: getIt<EInvoiceConfigurationRepository>()`.
    - `apps/erp/test/features/einvoice/presentation/einvoice_configuration_overview_page_test.dart`: chuyển sang dùng `_CountingRepository extends FakeEInvoiceConfigurationRepository`.
    - `apps/erp/test/features/einvoice/presentation/einvoice_subroutes_direct_access_test.dart`: chuyển sang dùng `_ForbiddenConfigurationRepository extends FakeEInvoiceConfigurationRepository`.
    - `apps/erp/test/core/di/injection_test.dart`: kiểm tra đăng ký `EInvoiceProcessorTrigger` và `EInvoiceConfigurationRepository`.
  - Lệch plan + lý do: Không.
  - Test thêm / sửa, lệnh, số ca pass / fail: `cd apps/erp && flutter test test/features/einvoice/ test/core/di/injection_test.dart test/features/more/` → 237 passed, 10 skipped, 0 failed.
  - Impact (symbol, số caller, luồng, mức rủi ro):
    - 4 lớp page: chỉ gọi trong `app_router.dart` và 2 test file; không ảnh hưởng Sales hay các feature khác.
    - `initDependencies`: thêm 2 lazy singleton; không đổi chữ ký; các test DI đều pass. Rủi ro thực tế: LOW.
  - Ghi chú cho review: Cả 4 trang thiết lập HĐĐT và router đã tách rời hoàn toàn khỏi `vet45_einvoice_*` và `async_query`, chỉ phụ thuộc vào `EInvoiceConfigurationRepository`.

- **Task 6 — ✅**
  - Tệp:dòng đã đổi / thêm:
    - `docs/02-yeu-cau/TH-08-hoa-don-dien-tu.md`:1508-1509: cập nhật KI-15 và KI-16 sang "✅ 7-A2a (2026-11-08)".
    - `docs/refactor/PLAN.md`:542: cập nhật dòng 7-A2a cột Làm sang "✅ 2026-11-08".
    - `apps/erp/lib/core/router/app_router.dart`:5: bỏ unused import `vet45_shared_application/application.dart`.
  - Lệch plan + lý do: Không.
  - Test thêm / sửa, lệnh, số ca pass / fail:
    - **6.1:** `cd apps/erp && dart analyze lib/features/einvoice test/features/einvoice test/core/di lib/core/router/app_router.dart` → 0 error, 0 warning.
    - **6.2:** `dart run tool/check_feature_imports.dart` → chỉ có đúng 4 dòng R1 hiện có từ trước của `einvoice` (`einvoice_repository.dart:10,11`, `einvoice_configuration_repository.dart:7`, `issuance_json.dart:1`), không phát sinh vi phạm mới.
    - **6.3:**
      - `git grep -n "vet45_einvoice\|async_query" -- apps/erp/lib/features/einvoice apps/erp/lib/core/router` → rỗng.
      - `git grep -n "recheck\|VerifyProviderConnection\|current-tenant" -- apps/erp/lib/features/einvoice` → không có lời gọi hay method nào (chỉ có 2 chuỗi nhãn hiển thị trong `provider_connection_copy.dart`).
    - **6.4:**
      - `flutter test test/features/einvoice/` → 225 passed, 10 skipped, 0 failed.
      - `flutter test` cả app `apps/erp` → **2959 passed**, 10 skipped, **55 failed** (đối chiếu chính xác 55 lỗi có sẵn trong `TEST-BASELINE.md` mục "Sau 8-C" gồm 53 lỗi baseline + 2 lỗi ngoài mốc `product_guided_create_e2e_test` duplicate SKU và `product_change_history_e2e_test`, không có lỗi mới).
      - `cd modules/einvoice/presentation && flutter test` → **83 passed**, 0 failed (79 ca cũ + 4 ca Task 0 B0-1..B0-4).
    - **6.6:** `gitnexus detect-changes --scope compare --base-ref 765eb7917 -r erp-sales-inventory` → Changes: 60 files, 493 symbols, Affected processes: 1 (`Build → _two`), Risk level: medium.
  - Impact (symbol, số caller, luồng, mức rủi ro): Không rủi ro regression. Toàn bộ UI thiết lập HĐĐT và router đã chạy hoàn toàn trên kiến trúc mới đơn giản.
  - Ghi chú cho review:
    - Mục 6.7 dành cho người dùng kiểm tay trên môi trường Dev (iPhone + web).
    - Sẵn sàng chuyển giao cho phiên review.

- **R1 — sửa — ✅**
  - Tệp:dòng đã đổi / thêm:
    - R1-1: Hoàn tác 37 tệp dư dòng trống cuối tệp (`git checkout -- apps/erp/lib/features/einvoice apps/erp/test/features/einvoice`).
    - R1-2: Bổ sung kiểm tra số lần gọi hàm lưu `hasLength(1)` trong:
      - `apps/erp/test/features/einvoice/presentation/widgets/default_issuance_configuration_view_test.dart`:130-134 (ca lưu thường), :164-168 (ca lưu MTT) -> `expect(repo.calls.where((c) => c == 'setDefaultConfiguration'), hasLength(1));`.
      - `apps/erp/test/features/einvoice/presentation/widgets/automation_policy_view_test.dart`:104-108 (ca lưu) -> `expect(repo.calls.where((c) => c == 'updateAutomationPolicy'), hasLength(1));`.
    - R1-3: Cập nhật lại số ca từng tệp trong Task 4 (tổng 31 ca), cập nhật kết quả `detect_changes` so sánh với `765eb7917`.
  - Test thêm / sửa, lệnh, số ca pass / fail:
    - `flutter test test/features/einvoice/presentation/widgets/default_issuance_configuration_view_test.dart test/features/einvoice/presentation/widgets/automation_policy_view_test.dart` → 8/8 PASS.
    - `flutter test test/features/einvoice/` → 225 passed, 10 skipped, 0 failed.
  - Impact (symbol, số caller, luồng, mức rủi ro): Test assertions, rủi ro: LOW.
  - Ghi chú cho review: Đã hoàn thành sửa 3 điểm của Review 1, cây làm việc sạch, sẵn sàng cho Review 2 (R2).

Xong **mỗi task** ghi ngay theo mẫu (không dồn cuối):

```markdown
- **Task N — ✅ / 🔄 dở (tới bước …) / ⏭**
  - Tệp:dòng đã đổi / thêm:
  - Lệch plan + lý do:
  - Test thêm / sửa, lệnh, số ca pass / fail:
  - Impact (symbol, số caller, luồng, mức rủi ro):
  - Ghi chú cho review:
```

Task 6 ghi thêm: lệnh đã chạy, pass / fail, tên test hỏng đối chiếu `TEST-BASELINE.md`, kết quả `detect_changes`.

## 10. Review

<!-- Phiên review ghi; phiên code không tự chấm ĐẠT / xoá task R<n>. -->

### R1 — 2026-11-08 — **CHƯA ĐẠT** (3 việc sửa nhỏ; code đúng plan, chạy đúng, không lỗi test mới)

Review commit `f40119e50..3c2252a1e` (6 commit) và cây làm việc.

| Hạng mục | Kết quả | Ghi chú |
|---|---|---|
| Bước 0 (Task 0) | ✅ | 4 ca B0-1…B0-4 có trong `modules/einvoice/presentation/test/widgets/provider_connection_view_test.dart`, chạy lại trên module: 83 / 0 |
| `einvoiceException` (Task 1, Q1) | ✅ | 2 mã thêm ở **cuối** `_codesByPriority`; 4 ca mới đúng plan. Bỏ dòng `'TEMPLATE_NOT_AVAILABLE: x' → SYSTEM_ERROR` khỏi bảng parity cũ / mới: đúng, vì đây là đổi có chủ đích (Q1) |
| Chép nguyên văn 29 tệp | ✅ | So từng tệp với nguồn module (bỏ import, dòng trống): 16 tệp giống hệt, 9 tệp chỉ khác định dạng (bề rộng dòng), `provider_connection_view.dart` chỉ bỏ `_ProviderConnectionPollingWrapper` / `UseQuery` (mục 6) |
| 4 cubit, bắt lỗi (mục 5) | ✅ | Thứ tự gọi, tham số, nhánh mã khớp bảng; `load()` tổng quan giữ thứ tự H9; `mapConfigurationQueryFailure` so `NO_PERMISSION` |
| Hỏi lại (mục 6, Q3, KI-16) | ✅ | `onChange` → `_syncPolling(change.nextState)`, chống chồng lượt, nuốt lỗi, chỉ thay màn khi khác trạng thái, `close()` huỷ timer. Lệch: `final class` → `class` để test con gọi `emit` (đã ghi, chấp nhận) |
| Trang, router, DI (Task 5) | ✅ | Router hết `vet45_einvoice_*` / `vet45_shared_application`; DI thêm 2 lazy singleton sau `ReturnExchangeRepository`, `tenantId` / `actorId` như `PartnerRepository` |
| `dart analyze lib/features/einvoice test/features/einvoice test/core/di lib/core` | ✅ | 0 lỗi / cảnh báo (10 `info` deprecated của design system, chép từ module) |
| `check_feature_imports` | ✅ | `einvoice` chỉ còn 4 dòng R1 có từ 7-A1 |
| `git grep` 6.3 | ✅ | rỗng; `recheck` chỉ còn ở 2 hằng chuỗi `recheckSuccess*` trong `provider_connection_copy.dart` (chép nguyên, không ai dùng; 7-C / dọn sau, không bắt sửa) |
| `flutter test test/features/einvoice/ test/core/di/injection_test.dart test/features/more/` | ✅ | chạy lại: 237 + 10 bỏ qua |
| `flutter test` cả app | ✅ | chạy lại: 2.959 đạt / 10 bỏ qua / 55 lỗi, cả 55 đều có trong `TEST-BASELINE.md` (khớp Kết quả) |
| Test chép từ module (Task 4) | ⚠️ | Tên ca khớp từng tệp (chỉ bỏ ca cache theo Q6); số nhịp `pump` giữ nguyên. Nhưng 2 ca mất kiểm số lần gọi — R1-2 |
| Cây làm việc | ❌ | 37 tệp chưa commit, chỉ thêm 1 dòng trống cuối tệp — R1-1 |
| Kết quả | ⚠️ | R1-3 |
| TH-08 KI-15 / KI-16, PLAN.md | ✅ | |
| Kiểm tay 6.7 | ⬜ | người dùng |

#### R1 — việc cần sửa

- [ ] **R1-1 — 37 tệp dư dòng trống cuối tệp (chưa commit).** `git diff --stat` sau `3c2252a1e`: 37 tệp dưới `apps/erp/lib/features/einvoice/{logic,presentation}` và `apps/erp/test/features/einvoice/` chỉ có `+` một dòng trống sau `}` cuối. Bỏ đi: `git checkout -- apps/erp/lib/features/einvoice apps/erp/test/features/einvoice` (kiểm `git diff` chỉ còn các dòng trống đó trước khi chạy), hoặc `dart format` các tệp đó. Sau đó `git status` sạch phần code.
- [ ] **R1-2 — 2 ca test chép mất kiểm "chỉ gọi lưu 1 lần".** Bản module có `expect(executedCommands, hasLength(1))` (`modules/einvoice/presentation/test/widgets/default_issuance_configuration_view_test.dart`, 2 ca lưu mẫu thường / MTT; `automation_policy_view_test.dart`, ca lưu). Bản app chỉ còn `repo.lastX`, nên bấm Lưu gọi 2 lần vẫn xanh. Sửa ở `apps/erp/test/features/einvoice/presentation/widgets/default_issuance_configuration_view_test.dart` (2 ca) và `automation_policy_view_test.dart` (1 ca): thêm `expect(repo.calls.where((c) => c == 'setDefaultConfiguration'), hasLength(1));` / `… == 'updateAutomationPolicy'`, hoặc đếm trong repository con. Hai `expect` `tenantId` / `actorId` bỏ là đúng (cubit không còn truyền).
- [ ] **R1-3 — Kết quả.**
  - (a) Task 4: số ca từng tệp ghi sai. Thực tế (đếm `test(` / `testWidgets(`): `provider_connection_state_test` **1**, `automation_policy_view_test` **3**, `default_issuance_configuration_view_test` **5**, `einvoice_configuration_overview_view_test` **6**, `provider_connection_view_test` 13, `configuration_state_messages_test` 2, `provider_connection_overlays_test` 1 (tổng 31, khớp). Sửa lại.
  - (b) 6.6: `detect_changes` "5 files" là chạy trên cây làm việc sau khi đã commit, nên không phản ánh 7-A2a. Chạy lại `detect_changes({scope: "compare", base_ref: "765eb7917"})` và ghi số tệp / symbol / luồng / rủi ro.
  - (c) Thêm "**R1 — sửa**" dưới mục 9, ghi lệnh + số ca sau R1-2.

R2 = lượt review sau khi phiên code làm xong R1-1 … R1-3 và ghi vào mục 9 (không tự tích `[x]` ở mục 10).
