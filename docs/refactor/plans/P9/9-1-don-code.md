# 9-1 — Dọn code: bỏ `c45_shared`, `c45_annotations`, `apps/erp/example`, Melos

> Dọn dẹp (mã cũ P9) · Gồm việc 9.1, 9.2, 9.3, 9.6 của PLAN.md mục "Dọn dẹp"
> Trạng thái: Plan ✅ (viết + người dùng duyệt 2026-11-19) | Làm ⬜ | Review ⬜
> Tài liệu: PLAN.md mục "Dọn dẹp" (9-1), 7-C Q1 (`CoreExecutionContext` giữ tới 9-1), 8-C Q5; SCOPE.md mục 6 (DoD); mẫu đã làm: 8-C (`plans/P8/8-C-don-module-sales.md`), 7-C.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `apps/erp` không còn phụ thuộc package `c45_shared_*` / `c45_annotations`; xoá `packages/c45_shared`, `packages/c45_annotations`, `apps/erp/example`; bỏ Melos khỏi workspace.

**Architecture:** Không đổi nghiệp vụ. Logic sales đang đọc tenant / user / correlationId qua `IExecutionContext` (cài bằng `CoreExecutionContext` đọc `SessionStore`) ⇒ đổi sang đọc thẳng `SessionController` (thêm `requireUserId()` và `correlationId`). Bốn thứ còn dùng thật của `c45_shared` (`ApplicationException`, `ValidationException`, `TenantAccessRevokedSignal`, 2 hàm logging) chép vào `apps/erp/lib/core/`. Sau đó xoá package, workspace chỉ còn `apps/erp`, `packages/c45_lints`, `packages/c45_design_system`.

**Tech Stack:** Flutter / Dart (`flutter_test`, `bloc_test`, `get_it`), Dart pub workspace.

**Spec:** thiết kế ngắn chốt trong chat 2026-11-19 (người dùng duyệt): "9-1 Dọn code" mục 1–5; phương án B (không gộp migration — thuộc 9-2).

## Global Constraints

- **Không đổi nghiệp vụ, không đổi RPC, không đụng `supabase/`.** DB là việc của 9-2.
- Test giữ hành vi (PLAN "Plan xoá / tách / thay code cũ"): chỉ được đổi **cách dựng** (fake `IExecutionContext` → `testSessionController(...)`, import), **không** đổi điều kiện kiểm, trừ đúng các chỗ ghi ở mục 2 (Q3, Q5).
- Mỗi tệp test đổi cách dựng: ghi số test trước / sau (`flutter test <tệp> 2>&1 | tail -1` ⇒ `+N`), phải bằng nhau.
- Trước khi sửa mỗi symbol Dart trong `lib`: `node .gitnexus/run.cjs impact <symbol> --direction upstream --repo erp-sales-inventory`, ghi vào Kết quả; HIGH / CRITICAL ⇒ báo người dùng trước khi sửa. Trước mỗi commit: `detect_changes`.
- `flutter analyze` có thể sập vì đường dẫn: dùng `dart analyze`.
- Tìm kiếm dùng `grep -r`; trong zsh luôn đặt `--include='*.dart'` trong nháy.
- Không chép lại CQRS / bus / pipeline / decorator / events bus / internal command / `IPermissionChecker` / `ITenantAccessChecker` / `ICurrentUser` / `ICurrentTenant` (app không dùng — đo 2026-11-19).
- Phiên code ghi Kết quả (mục 8) sau mỗi task: tệp:dòng, lệch plan, số test trước / sau, impact. Phiên code không tự chấm ĐẠT.

## Review Focus

1. **Sai giá trị tenant / user khi thay fake** (fake cũ trả `'tenant-demo'` / `'user-demo'`, `testSessionController` mặc định `'org-001'` / `'u1'`) ⇒ test vẫn xanh nhưng kiểm sai, hoặc assert `actorId` đỏ. Test: Task 2 Step 3 — mỗi tệp truyền **đúng** giá trị fake cũ trả về (bảng mục 3), số test không đổi.
2. **Thiếu user nhưng có tenant** (phiên còn tenant, `userId` trống) ⇒ trước ném `ApplicationException('User is required')`, sau phải ném `AppException(AUTHENTICATION_REQUIRED)`, không được trả chuỗi rỗng. Test: Task 1 `requireUserId throws AUTHENTICATION_REQUIRED when user id blank`.
3. **`correlationId` đổi mỗi lần đọc** ⇒ màn đổi trả / thu tiền gửi lần thử lại với id khác lần đầu. Hiện là một giá trị cố định suốt đời `CoreExecutionContext` (singleton). Test: Task 1 `correlationId is non-empty and stable across reads`.
4. **`TenantAccessRevokedSignal` bị nhân đôi** (chép vào `core/` nhưng còn chỗ import bản package) ⇒ hai `StreamController` khác nhau, shell không nghe được tín hiệu tạm ngưng tổ chức. Test: Task 3 Step 4 grep rỗng + `session_revoked_signal_test.dart` xanh.
5. **Workspace / tệp cấu hình còn trỏ thứ đã xoá** (`pubspec.yaml` gốc, `.vscode/launch.json` "ERP · example", `tasks.json`, `scripts/ci/guard_codegen_fresh.sh` gọi `melos`) ⇒ `dart pub get` gốc lỗi, launch config gãy. Test: Task 4 Step 4.

---

## 1. Mục tiêu

- `grep -rnE "c45_shared|c45_annotations|IExecutionContext|CoreExecutionContext|FakeExecutionContext|ICurrentUser|ICurrentTenant" apps packages tools scripts pubspec.yaml .vscode --include='*.dart' --include='*.yaml' --include='*.json' --include='*.sh'` rỗng.
- `ls packages` = `c45_design_system`, `c45_lints`; `apps/erp/example` không còn.
- `pubspec.yaml` gốc: không còn khối `melos:` / dev dependency `melos`; `dart pub get` ở gốc chạy được.
- `dart analyze apps/erp` không thêm lỗi; `flutter test` (apps/erp) không thêm lỗi so với `TEST-BASELINE.md`.
- PLAN.md (dòng 9-1, mục 9.2, 9.3, 9.6) và SCOPE.md mục 6 ghi đúng hiện trạng.

## 2. Quyết định

| Q | Nội dung |
|---|---|
| Q1 | **Thay `IExecutionContext` bằng `SessionController`** (PLAN 9-1, 7-C Q1). Thêm vào `SessionController`: `Future<String> requireUserId()` (giống `requireTenantId()`: lấy `_store.userId`, rỗng thì `state.userId`, đều rỗng ⇒ `throw const AppException(AppErrorCode.authRequired)`) và `final String correlationId` (tham số tuỳ chọn `String? correlationId` của constructor, mặc định `const Uuid().v4()`, sinh **một lần** — giữ đúng hành vi `CoreExecutionContext` singleton). Cubit / lớp logic nhận `required SessionController session` (trường `final SessionController session;`, riêng `SalesDraftListCubit` là `_session`); page / scope truyền `GetIt.instance<SessionController>()`. Mẫu có sẵn: `sales_pricing_lookup.dart:138-140` |
| Q2 | **Lỗi khi thiếu phiên đổi từ `ApplicationException('Tenant is required' / 'User is required')` sang `AppException('AUTHENTICATION_REQUIRED')`** (đổi có chủ đích). Đo 2026-11-19: không mapper nào trong `lib` so chuỗi `Tenant is required` / `User is required`; các cubit sales bắt lỗi chung rồi map qua `AppException` ⇒ thông báo thiếu phiên rõ hơn trước. Chỉ `test/core/session/session_contracts_test.dart` kiểm chuỗi cũ ⇒ xoá cùng `session_contracts.dart` (Task 3) |
| Q3 | **Test sales: fake `IExecutionContext` tự viết → `testSessionController(tenantId: …, userId: …)`** (`test/features/iam/support/iam_test_session.dart`) với **đúng** giá trị fake cũ trả về (bảng mục 3). `correlationId` của fake cũ (`'corr-1'`, `'corr-test'`) không được assert ở cubit / page test nào (đo 2026-11-19: chỉ `*_attempt_factory_test.dart` dùng, và truyền thẳng — không qua context) ⇒ bỏ. Lớp fake `_…ExecutionContext` trong mỗi tệp xoá |
| Q4 | **Chép vào `core/`, giữ nguyên thân:** `ApplicationException`, `ValidationException` → `apps/erp/lib/core/errors/application_exception.dart` (cả hai lớp một tệp; `session_store.dart` còn ném `ApplicationException` 3 chỗ, `iam_ui_failure_mapper.dart:30-44` và test của nó còn dùng cả hai). `TenantAccessRevokedSignal` → `apps/erp/lib/core/session/tenant_access_revoked_signal.dart` (bỏ dòng `TODO(P9)`). `configurePackageLogging`, `parseLogLevel` (+ `_loggingConfigured`, `_customOnRecord`, `_emitLogRecord`, typedef `LogRecordHandler`) → hàm riêng tư trong `apps/erp/lib/core/config/app_logging.dart` (nguồn: `packages/c45_shared/infrastructure/lib/src/logging/logging_logger.dart`) |
| Q5 | **Test DI** (`test/core/di/injection_test.dart`): bỏ assert `IExecutionContext` / `ICurrentUser` / `ICurrentTenant` là `CoreExecutionContext` (dòng 49-51, 68-74) và assert `isRegistered<IPermissionChecker / ITenantAccessChecker / IEventsBus>() == false` (dòng 82-85) — các kiểu đó không còn tồn tại. Thay bằng một assert: `getIt<SessionController>().correlationId` không rỗng. `active_store_registration_test.dart:52` đổi sang `getIt<SessionController>().requireTenantId()` |
| Q6 | **Xoá `apps/erp/example`** (người dùng duyệt trong thiết kế 2026-11-19): app xem trước kiểu cũ, phụ thuộc `c45_shared_*` / `c45_annotations`, không nằm trong workspace. **Giữ** `packages/c45_design_system/example` |
| Q7 | **Melos:** bỏ khỏi `pubspec.yaml` gốc (dev dependency + khối `melos:`); `.vscode/extensions.json` bỏ `blaugold.melos-code`; `scripts/ci/guard_codegen_fresh.sh` đổi `melos bootstrap` + `melos run codegen` thành `dart pub get` + `(cd apps/erp && dart run build_runner build --delete-conflicting-outputs)` (app còn `sales_typed_routes.g.dart`); README / AGENTS / `.cursor/rules/c45-design-system-example.mdc:55` đổi lệnh `melos run …` sang lệnh gốc. Tài liệu harness cũ trong `docs/themes/**`, `specs/**`, và `docs/operations/*.md` (mô tả `c45_env` đã xoá) **không sửa** |

## 3. Hiện trạng (đo 2026-11-19, HEAD `941594c2b`)

| Thứ | Ai còn dùng |
|---|---|
| `IExecutionContext` trong `lib` | `core/di/injection.dart:85-91` (đăng ký `CoreExecutionContext` cho `IExecutionContext`, `ICurrentUser`, `ICurrentTenant`); `core/session/session_contracts.dart` (định nghĩa); `features/sales/logic/` 8 tệp: `sales_checkout_cubit.dart:49,186-195`, `sales_checkout_orchestrator.dart:14-19` (`GetIt.instance<IExecutionContext>()`), `sales_draft_list_cubit.dart:15,23,89,163`, `sales_order_detail_cubit.dart:35,64,320` (chỉ chuyển tiếp cho post-sale actions), `sales_order_detail_post_sale_actions.dart:34,96-125`, `sales_return_exchange_detail_cubit.dart:30,49-51`, `sales_return_exchange_session_cubit.dart:34,55-57`, `sales_return_exchange_settlement_cubit.dart:34,55-57`; 8 page / scope truyền `GetIt.instance<IExecutionContext>()`: `presentation/orchestration/sales_draft_list_scope.dart:34`, `presentation/pages/` `sales_checkout_page.dart:38`, `sales_order_detail_page.dart:51`, `sales_return_exchange_{create:39, settlement:41, detail:36, result:38, slip_preview:37}_page.dart` |
| Khác trong `lib` | `core/supabase/supabase_rpc.dart`, `core/session/session_controller.dart` (`TenantAccessRevokedSignal`); `core/session/session_store.dart:55,110,115` (`ApplicationException`); `core/iam/iam_ui_failure_mapper.dart:3,30-44`; `core/config/app_logging.dart:5` (`c45_shared_infrastructure`) |
| Test dùng `IExecutionContext` / `FakeExecutionContext` | 36 tệp: sales 15 tệp + 3 `integration_test` (Task 2); còn lại 18 tệp chỉ đăng ký vào DI (Task 3) |
| Workspace | `pubspec.yaml:12-16` (5 package), `:18-19` melos, `:21-…` khối `melos:`; `apps/erp/pubspec.yaml:20-21, 44`; `apps/erp/example/pubspec.yaml` |
| Khác | `.vscode/launch.json:67-82` (2 cấu hình "ERP · example"), `.vscode/tasks.json:20-24` (`erp:example pub get`), `.vscode/extensions.json:5`; `scripts/ci/guard_codegen_fresh.sh:16-17, 21`; `README.md:13,31,42,79-82,115`; `AGENTS.md:35,60`; `TEST-BASELINE.md:28,34-37` (4 hàng package); tệp `melos_*.iml` (không nằm trong git) |

**Giá trị fake cũ trong test sales (Q3)** — đường dẫn dưới `apps/erp/test/features/sales/`:

| Tệp | tenantId | userId |
|---|---|---|
| `sales_flow_pages_test.dart`, `sales_order_detail_page_test.dart`, `presentation/sales_checkout_page_test.dart` | `tenant-demo` | `user-demo` |
| `sales_return_exchange_slip_preview_page_test.dart`, `sales_transaction_result_page_test.dart`, `sales_return_exchange_result_page_test.dart`, `sales_return_exchange_detail_page_test.dart`, `presentation_module/bloc/sales_return_exchange_{detail,settlement,session}_cubit_test.dart` | `tenant-1` | `actor-1` |
| `presentation_module/widgets/sales_draft_list_body_test.dart`, `presentation_module/bloc/sales_draft_list_live_test.dart`, `logic/sales_draft_list_cubit_test.dart` | `tenant-1` | `user-1` |
| `presentation_module/bloc/sales_checkout_cubit_test.dart`, `presentation_module/bloc/sales_order_detail_cubit_test.dart` | theo tham số fake (giữ đúng giá trị từng chỗ dựng) | như trái |

Integration test (`apps/erp/integration_test/sales_group_{a_s03_s05,b_s06_s07,c_s08_s11}_live_test.dart`): `di<IExecutionContext>()` → `di<SessionController>()`.

## 4. Đang làm gì (thứ bị xoá / thay)

| # | Thứ cũ đang làm | Sau khi sửa nằm ở đâu | Test giữ hành vi |
|---|---|---|---|
| 1 | `CoreExecutionContext.requireTenantId/UserId`: đọc `SessionStore`, thiếu ⇒ `ApplicationException` | `SessionController.requireTenantId` (có sẵn) / `requireUserId` (Task 1), thiếu ⇒ `AppException(AUTHENTICATION_REQUIRED)` (Q2) | Task 1 |
| 2 | `CoreExecutionContext.correlationId`: uuid v4 sinh một lần lúc dựng singleton | `SessionController.correlationId`, sinh một lần lúc dựng (Q1) | Task 1 |
| 3 | DI đăng ký `IExecutionContext` / `ICurrentUser` / `ICurrentTenant` | **Bỏ** | `injection_test.dart` (Q5) |
| 4 | `TenantAccessRevokedSignal`, `ApplicationException`, `ValidationException`, logging của `c45_shared` | `core/` (Q4), cùng thân | `session_revoked_signal_test.dart`, `iam_ui_failure_mapper_test.dart`, `session_store` test có sẵn |

## 5. Thay đổi

| Tệp | Hành động |
|---|---|
| `apps/erp/lib/core/session/session_controller.dart`; `apps/erp/test/core/session/session_controller_test.dart` | sửa (Task 1) |
| 8 tệp `features/sales/logic`, 8 page / scope (mục 3); 15 test sales + 3 integration test | sửa (Task 2) |
| `apps/erp/lib/core/errors/application_exception.dart`, `apps/erp/lib/core/session/tenant_access_revoked_signal.dart` | tạo (Task 3) |
| `core/di/injection.dart`, `core/config/app_logging.dart`, `core/supabase/supabase_rpc.dart`, `core/session/session_store.dart`, `core/iam/iam_ui_failure_mapper.dart`; 18 test chỉ đăng ký DI, `injection_test.dart`, `active_store_registration_test.dart`, test import `ApplicationException` / `TenantAccessRevokedSignal` | sửa (Task 3) |
| `apps/erp/lib/core/session/session_contracts.dart`, `apps/erp/test/core/session/session_contracts_test.dart` | xoá (Task 3) |
| `packages/c45_shared/`, `packages/c45_annotations/`, `apps/erp/example/` | xoá (Task 4) |
| `pubspec.yaml`, `apps/erp/pubspec.yaml`, `.vscode/{launch,tasks,extensions}.json`, `scripts/ci/guard_codegen_fresh.sh`, `README.md`, `AGENTS.md`, `.cursor/rules/c45-design-system-example.mdc` | sửa (Task 4) |
| `docs/refactor/PLAN.md`, `docs/refactor/SCOPE.md` | sửa (Task 5) |
| `docs/refactor/TEST-BASELINE.md` | phiên review cập nhật (như 8-C) |

---

## 6. Các task

### Task 0: Đếm test trên code cũ

**Files:** không sửa.

- [ ] **Step 1:** Chạy `cd apps/erp && flutter test 2>&1 | tail -1`, ghi `+N -M` vào Kết quả làm mốc (so với `TEST-BASELINE.md` mục `apps/erp`).
- [ ] **Step 2:** Với mỗi tệp ở bảng mục 3 và 18 tệp của Task 3: `flutter test <tệp> 2>&1 | tail -1`, ghi số `+N` vào bảng trong Kết quả.

### Task 1: `SessionController.requireUserId` + `correlationId`

**Files:**
- Modify: `apps/erp/lib/core/session/session_controller.dart` (constructor `:24-48`, cạnh `requireTenantId` `:187-193`; sửa comment `:23` bỏ nhắc `CoreExecutionContext`)
- Test: `apps/erp/test/core/session/session_controller_test.dart`; Modify `apps/erp/test/features/iam/support/iam_test_session.dart` (thêm tham số `correlationId`)

**Interfaces:**
- Produces: `Future<String> SessionController.requireUserId()`; `String get SessionController.correlationId` (trường `final`); constructor thêm `String? correlationId`.

- [ ] **Step 1: Viết test đỏ** (nhóm `group('execution identity', …)`, dựng bằng `testSessionController` từ `test/features/iam/support/iam_test_session.dart`):
  - `requireUserId returns the signed-in user id`: `testSessionController(userId: 'u-42')` ⇒ `expect(await c.requireUserId(), 'u-42')`.
  - `requireUserId throws AUTHENTICATION_REQUIRED when signed out`: `testSessionController(signedIn: false)` ⇒ `expect(c.requireUserId(), throwsA(isA<AppException>().having((e) => e.code, 'code', AppErrorCode.authRequired)))`.
  - `requireUserId throws AUTHENTICATION_REQUIRED when user id blank`: `testSessionController(userId: '  ')` ⇒ như trên.
  - `correlationId is non-empty and stable across reads`: `final a = c.correlationId; expect(a.trim(), isNotEmpty); expect(c.correlationId, a);`.
  - `correlationId can be injected`: `testSessionController(correlationId: 'corr-x')` ⇒ `c.correlationId == 'corr-x'` (thêm tham số `String? correlationId` vào `testSessionController` ở `test/features/iam/support/iam_test_session.dart`, truyền xuống constructor).
- [ ] **Step 2:** `flutter test test/core/session/session_controller_test.dart` ⇒ FAIL (thiếu `requireUserId` / `correlationId`).
- [ ] **Step 3:** Impact `SessionController` (ghi Kết quả), rồi cài theo Q1. `requireUserId` ưu tiên `_store.userId`, rồi `state.userId`, cả hai qua `_blankToNull`.
- [ ] **Step 4:** Chạy lại tệp test ⇒ PASS; `dart analyze lib/core/session` sạch.
- [ ] **Step 5: Commit** `refactor(core): SessionController có requireUserId và correlationId (9-1)`.

### Task 2: Sales đọc phiên qua `SessionController`

**Files:**
- Modify: 8 tệp `apps/erp/lib/features/sales/logic/*` và 8 page / scope ở mục 3.
- Test: 15 tệp sales + 3 integration test ở mục 3.

**Interfaces:**
- Consumes: Task 1 (`requireTenantId`, `requireUserId`, `correlationId`).
- Produces: constructor các cubit sales nhận `required SessionController session` thay `required IExecutionContext executionContext` (Q1). Không đổi tham số nào khác.

- [ ] **Step 1:** Impact từng lớp trong 8 tệp logic (ghi Kết quả).
- [ ] **Step 2:** Đổi kiểu + tên tham số theo Q1; `executionContext.requireTenantId()` → `session.requireTenantId()`, `…requireUserId()` → `session.requireUserId()`, `executionContext.correlationId` → `session.correlationId`. `sales_checkout_orchestrator.dart:14` → `GetIt.instance<SessionController>()`. Page / scope: `executionContext: GetIt.instance<IExecutionContext>()` → `session: GetIt.instance<SessionController>()`. Bỏ import `c45_shared_application` nếu không còn dùng.
- [ ] **Step 3:** Test: xoá lớp fake `_…ExecutionContext implements IExecutionContext` ở mỗi tệp, thay chỗ dựng bằng `testSessionController(tenantId: <bảng mục 3>, userId: <bảng mục 3>)` (Q3); nơi test đăng ký `IExecutionContext` vào `GetIt` ⇒ đăng ký `SessionController`. Integration test: `di<IExecutionContext>()` → `di<SessionController>()`.
- [ ] **Step 4:** `grep -rnE "IExecutionContext|executionContext" apps/erp/lib/features/sales apps/erp/test/features/sales apps/erp/integration_test --include='*.dart'` rỗng.
- [ ] **Step 5:** `dart analyze lib/features/sales test/features/sales integration_test` sạch; từng tệp test ở bảng mục 3: số `+N` = mốc Task 0.
- [ ] **Step 6: Commit** `refactor(sales): đọc tenant / user / correlationId từ SessionController (9-1)`.

### Task 3: Chuyển phần còn dùng của `c45_shared` vào `core/`, bỏ `CoreExecutionContext`

**Files:**
- Create: `apps/erp/lib/core/errors/application_exception.dart`, `apps/erp/lib/core/session/tenant_access_revoked_signal.dart`
- Modify: `core/di/injection.dart:85-91`, `core/config/app_logging.dart`, `core/supabase/supabase_rpc.dart`, `core/session/session_controller.dart`, `core/session/session_store.dart`, `core/iam/iam_ui_failure_mapper.dart`
- Delete: `core/session/session_contracts.dart`, `test/core/session/session_contracts_test.dart`
- Test: `test/core/di/injection_test.dart`, `test/core/di/active_store_registration_test.dart`, 18 tệp còn `FakeExecutionContext` / `IExecutionContext` (catalog 5, partner 2, iam 2, tenant_context 2, dashboard, inventory, tenant_admin, invitations, my_account, 2 tệp `core/di`), 4 tệp import `ApplicationException` / `ValidationException` / `TenantAccessRevokedSignal`

**Interfaces:**
- Produces: `package:erp/core/errors/application_exception.dart` (`ApplicationException`, `ValidationException`); `package:erp/core/session/tenant_access_revoked_signal.dart` (`TenantAccessRevokedSignal`). Thân lớp chép nguyên (Q4).

- [ ] **Step 1:** Impact `CoreExecutionContext`, `TenantAccessRevokedSignal`, `configureAppLogging` (ghi Kết quả).
- [ ] **Step 2:** Tạo 2 tệp mới theo Q4; `app_logging.dart` chép 2 hàm logging thành hàm riêng tư (Q4); đổi import các tệp `lib` sang bản `core/`.
- [ ] **Step 3:** `injection.dart`: bỏ khối `:85-91` (`CoreExecutionContext` + 3 `registerSingleton`) và import; xoá `session_contracts.dart` + test của nó. Sửa comment `session_store.dart:9`.
- [ ] **Step 4:** Test: xoá mọi đăng ký `IExecutionContext` / `FakeExecutionContext` (không ai trong `lib` đọc nữa) và lớp fake tự viết ở 2 tệp catalog (`edit_product_unit_price_band_e2e_test.dart`, `product_catalog_tab_page_test.dart`); sửa `injection_test.dart`, `active_store_registration_test.dart` theo Q5; đổi import 4 tệp test còn lại sang `package:erp/core/...`. Rồi `grep -rn "c45_shared\|IExecutionContext\|FakeExecutionContext\|CoreExecutionContext" apps/erp --include='*.dart'` rỗng.
- [ ] **Step 5:** `dart analyze` (apps/erp) không lỗi mới; chạy 18 tệp + `test/core` + `test/features/iam/logic/iam_ui_failure_mapper_test.dart`: số `+N` = mốc (trừ `session_contracts_test` đã xoá và các assert bỏ theo Q5 — ghi số giảm).
- [ ] **Step 6: Commit** `refactor(core): chuyển phần còn dùng của c45_shared vào core, bỏ CoreExecutionContext (9-1)`.

### Task 4: Xoá package, example, Melos

**Files:** Delete `packages/c45_shared/`, `packages/c45_annotations/`, `apps/erp/example/`; Modify các tệp Task 4 ở mục 5.

- [ ] **Step 1:** `apps/erp/pubspec.yaml`: bỏ `c45_shared_application`, `c45_shared_infrastructure` (`:20-21`), `c45_shared_testing` (`:44`).
- [ ] **Step 2:** `pubspec.yaml` gốc: `workspace:` chỉ còn `apps/erp`, `packages/c45_lints`, `packages/c45_design_system`; bỏ `dev_dependencies: melos` và toàn khối `melos:`. Xoá 3 thư mục. Xoá `melos_*.iml` (không trong git).
- [ ] **Step 3:** Sửa `.vscode` (bỏ 2 cấu hình "ERP · example" + task `erp:example pub get` + `blaugold.melos-code`), `guard_codegen_fresh.sh`, README, AGENTS (`:35` bỏ dòng nói `c45_shared`; `:60` `melos run analyze` → `dart analyze apps/erp packages`), `.cursor/rules/c45-design-system-example.mdc:55` theo Q7.
- [ ] **Step 4:** Kiểm: `dart pub get` ở gốc OK; `grep` ở mục 1 rỗng; `grep -rn "melos" pubspec.yaml README.md AGENTS.md .vscode scripts .cursor` rỗng; `GUARD_CODEGEN_STRICT=1 scripts/ci/guard_codegen_fresh.sh` in `OK: generated files are fresh`.
- [ ] **Step 5:** `dart analyze apps/erp packages/c45_design_system packages/c45_lints` không lỗi mới; `cd apps/erp && flutter test 2>&1 | tail -1` ⇒ số lỗi ≤ mốc Task 0, không lỗi mới (liệt kê nếu khác).
- [ ] **Step 6: Commit** `chore: xoá c45_shared, c45_annotations, erp example và Melos (9-1)`.

### Task 5: Tài liệu

- [ ] **Step 1:** `docs/refactor/PLAN.md`: dòng 9-1 cột Làm; mục 9.2 bỏ "(4 package … đã xoá ở 7-C)" thừa nếu cần, ghi xoá cả `apps/erp/example`; mục 9.3 workspace còn `apps/erp`, `c45_lints`, `c45_design_system` (bỏ `tools/c45_env`, bỏ câu `c45_misa`); mục 9.6 ghi `c45_env` + `c45_supabase_migrate` **đã xoá** ở `8ad18cd27`; dòng 9-1 bỏ "gọn `c45_env`"; dòng 9-2 + mục 9.5 ghi **không gộp migration** (người dùng chốt 2026-11-19, phương án B).
- [ ] **Step 2:** `docs/refactor/SCOPE.md` mục 6: dòng "`supabase db reset` chạy được từ baseline migration mới + seed" → "`supabase db reset` chạy được từ migration hiện có + seed (không gộp baseline — chốt 2026-11-19)".
- [ ] **Step 3: Commit** `docs: cập nhật PLAN / SCOPE sau 9-1`.

## 7. Rủi ro / lưu ý

- `sales_order_detail_cubit_test.dart` (1849 dòng) và `sales_checkout_cubit_test.dart` dựng fake với tham số ở nhiều chỗ ⇒ đổi từng chỗ, giữ giá trị; đây là nơi dễ lệch nhất (Review Focus 1).
- `SessionController` là Cubit: test dựng nhiều instance không cần `close()` (giống các test dùng `testSessionController` hiện có).
- `docs/operations/environments.md`, `environment-manager.md` còn mô tả `c45_env` / `melos run env:*` (tool đã xoá) — ngoài phạm vi 9-1, ghi vào Kết quả để người dùng quyết (xoá hoặc viết lại ở Báo cáo).

## 8. Kết quả

<!-- Phiên code ghi sau mỗi task -->

## 9. Review

<!-- Phiên review ghi -->
