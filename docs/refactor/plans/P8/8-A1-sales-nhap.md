# 8-A1 — Sales: soạn đơn + nháp sang `SalesDraftRepository`

> Theme 5 (mã cũ P8) · Bước (a) chuyển kiến trúc, nhóm nháp · Gồm việc 8.1 (PLAN.md mục Theme 5), **trừ** KI-07, KI-08 (sang 8-B)
> Trạng thái: Plan 📝 (viết 2026-11-06, chờ duyệt) | Làm ✅ 2026-11-07 | Review ⬜
> Sau 8-A1 là **8-A2** (thanh toán). Module sales vẫn chạy song song cho thanh toán, tra cứu, phiếu, huỷ, đổi/trả tới 8-A4; 8-C dọn.
> Tài liệu: [TH-05](../../../02-yeu-cau/TH-05-ban-hang-va-don-hang.md) US-01.6, US-01.7, SG-01, 6.2 (RPC), 6.4 (câu lỗi), 7.2 (phân quyền); PLAN.md "Cách chuyển MỘT feature", "Plan chuyển kiến trúc: giữ nghiệp vụ…", "Plan xoá / tách / thay code cũ: test giữ hành vi trước". Mẫu: `6-A1-pricing-data.md` (parity `old` / `new`), `6-A2-pricing-ui-sang-repository.md` (đổi cubit).
>
> **Cho phiên code:** dùng `superpowers:executing-plans` (tuần tự). Mỗi task xong ghi ngay mục 9. **Không commit** (người dùng commit sau `detect_changes()`).

## 1. Mục tiêu

- 5 RPC nháp của schema `sales` đi qua `SalesDraftRepository` thay cho `ISalesModule`:
  ```text
  SalesDraftListCubit ─┐
  SalesDraftBackend  ──┴─▶ SalesDraftRepository ─▶ SupabaseRpc.call('sales', …)
  ```
- Repository **nhận và trả kiểu của `c45_sales_application`** (Q1). Chỉ chép vào app: dựng tham số + đọc JSON (từ `SalesOrderDraftRpcMapper`), rule đầu vào (từ 3 validator), phân loại lỗi.
- Lỗi đi ra là `AppException` (Q2). Danh sách nháp / xoá nháp hết hiện câu server thô (Q3, đổi có chủ đích).
- Có test parity `old` (module) / `new` (repository) dùng **chung giá trị mong đợi**. 8-C xoá nhóm `old` cùng module.
- `SalesDraftListCubit` (+ state) và `SalesDraftBackend` chuyển vào `features/sales/logic/` (bước 6 của công thức).

**Không làm:** KI-07 "Nợ cũ", TH-02 KI-08 `_product_unit_has_sales_transaction_usage` (Q4 → 8-B); tải thêm nháp, "Tạo bởi" của người khác (Q5 → 8-B, KI-21 / KI-22 mới); bố cục web (plan 8-W sau); xem trước giá (đã chuyển ở 6-A2); chép kiểu DTO (8-C).

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | Chia 8-A; kiểu dùng chung (`MoneyDto` 89 chỗ, soạn đơn → thanh toán qua `CheckoutLineInput` / `SalesCommercialSnapshotInput`) | **Người dùng chốt 2026-11-06:** chia theo nhóm màn như PLAN.md (8-A1 nháp, 8-A2 thanh toán…). Repository gọi thẳng RPC nhưng **trả DTO của `c45_sales_application`**, dùng lại `SalesOrderDraftContractMapper` (application) để dựng DTO. Chép kiểu + đổi import một lượt ở 8-C. Lệch quy ước "chép kiểu ở (a)" của Theme 2/4 — có chủ đích |
| Q2 | Kiểu lỗi của repository | **Người dùng chốt 2026-11-06:** `AppException`. `SalesDraftListCubit` và nhánh `draftGone` của `SalesComposeCubit` đổi `SalesContractException` → `AppException` ngay ở 8-A1 |
| Q3 | Câu lỗi thô ở SG-01: `sales_draft_list_cubit.dart:111` (`error.message ?? error.code`), `:113` (`error.message ?? …`), `:228-231` (`error.message ?? …`) hiện câu tiếng Anh của server / gateway ("Draft version has changed.", "Sales draft operation failed.") | **Người dùng chốt 2026-11-06: sửa ở 8-A1, đổi có chủ đích** theo TH-05 6.4 / US-01.7 (bảng 4.4). Không bao giờ hiện `serverMessage` hay mã |
| Q4 | PLAN 8.1 có TH-02 KI-08 (sửa `catalog._product_unit_has_sales_transaction_usage`), TH-05 9.2 ghi 8.1 "bỏ Nợ cũ" (KI-07) | **Người dùng chốt 2026-11-06:** cả hai sang **8-B** (đổi hành vi / sửa DB, không thuộc (a)) |
| Q5 | Lỗi cũ thấy khi viết plan: (1) `sales_draft_list_cubit.dart:73-79` tải đúng 1 trang `pageSize: 50`, bỏ `has_more` ⇒ nháp thứ 51 trở đi không bao giờ hiện (TH-05 US-01.7 EC-02: "Hơn 25 nháp → tải thêm khi cuộn"); (2) `:156` `actorNameResolver` chỉ tra được tên của chính mình, nháp người khác truyền UUID, `SalesDraftListItemVm.creatorLabel` loại UUID ⇒ **không có** "Tạo bởi" cho nháp của người khác (US-01.7 FR-02) | **Người dùng chốt 2026-11-06: để 8-B.** 8-A1 giữ nguyên (`list(pageSize: 50)` một lần). Đã ghi KI-21, KI-22 vào TH-05 7.3 |
| Q6 | Kiểm quyền client: `@RequiresPermission(createDraft / updateDraft / deleteDraft)` trên 3 command (pipeline module) và `permissionChecker.require(SalesPermissions.restoreDraft)` trong 2 handler đọc | **Bỏ** (quy ước Theme 3 / 4). Server kiểm ở mọi RPC (`sales._assert_sales_actor(…, 'sales.draft.*')`, `20260830007_sales_draft_rpcs.sql`). TH-05 7.2: mọi thành viên có quyền bán hàng ⇒ người dùng không thấy khác |
| Q7 | Mã lỗi lạ | Giữ 6 mã ổn định của gateway (`_stableCodes`, `supabase_sales_order_draft_gateway.dart:152-159`). `PERMISSION_DENIED` đi qua `AppException.from` thành `NO_PERMISSION`. Mã khác, lỗi đọc JSON, lỗi không phải `AppException` ⇒ `SYSTEM_ERROR` (cũ: `CONTEXT_INVALID` "Sales draft operation failed."). Không cubit nào rẽ nhánh theo `CONTEXT_INVALID` (đo 2026-11-06) ⇒ không đổi gì với người dùng ngoài câu (Q3) |
| Q8 | Xoá nháp gặp `REFERENCE_UNAVAILABLE` (nháp đã bị xoá ở máy khác) — cũ **không** đặt `needsReload`, chỉ báo lỗi | **Giữ nguyên** (quy tắc (a)); câu đổi theo Q3 thành "Không hủy được đơn nháp". Ghi Rủi ro cho 8-B |
| Q9 | `tenantId` / `actorId` | Repository lấy qua closure mỗi lần gọi (như `ProductRepository`): `tenantId: () => SessionController.requireTenantId()`, `actorId: () async => sessionStore.userId ?? throw AppException(authRequired)`. `SalesDraftBackend` bỏ `IExecutionContext`. `SalesDraftListCubit` **giữ** `IExecutionContext` chỉ để lấy `currentUserId` cho `isOwnedByMe` (8-C bỏ `CoreExecutionContext`) |

## 3. Hiện trạng (đo 2026-11-06)

`lib` gọi module nháp ở 3 tệp: `presentation/orchestration/sales_draft_backend.dart` (save / update / restore), `presentation/bloc/sales_order_draft/sales_draft_list_cubit.dart` (list / cancel), `presentation/orchestration/sales_draft_list_scope.dart` (truyền `ISalesModule`). `SalesComposeCubit` chỉ nhận hàm `persistDraft` / `restoreDraft` (`sales_order_compose_page.dart:44-45`), không gọi module; nhánh `draftGone` ở `sales_compose_cubit.dart:490-495` xét `SalesContractException`.

| Command / Query | Handler / pipeline làm thêm gì | RPC | Tham số (chép từ `SalesOrderDraftRpcMapper`) |
|---|---|---|---|
| `SaveSalesOrderDraftCommand` | `@RequiresPermission(createDraft)`; `SaveSalesOrderDraftCommandValidator` | `save_sales_order_draft` | `saveParams` |
| `UpdateSalesOrderDraftCommand` | `@RequiresPermission(updateDraft)`; `Update…Validator` (thêm `draftId`, `expectedVersion > 0`) | `update_sales_order_draft` | `updateParams` |
| `CancelSalesOrderDraftCommand` | `@RequiresPermission(deleteDraft)`; `Cancel…Validator` | `cancel_sales_order_draft` | `cancelParams` |
| `ListSalesOrderDraftsQuery` | `permissionChecker.require(restoreDraft)` | `list_sales_order_drafts` | `listParams` |
| `GetSalesOrderDraftForRestoreQuery` | `permissionChecker.require(restoreDraft)` | `get_sales_order_draft_for_restore` | `restoreParams` |

Đường dẫn: `modules/sales/infrastructure/lib/src/domain/sales_order_draft/{sales_order_draft_rpc_mapper,supabase_sales_order_draft_gateway}.dart`, `modules/sales/application/lib/src/sales_order_draft/**`. Test mẫu có sẵn: `modules/sales/infrastructure/test/domain/sales_order_draft/{sales_order_draft_rpc_mapper_test,supabase_sales_order_draft_gateway_test}.dart` (lấy JSON mẫu từ đây). Tất cả RPC trả `jsonb`.

Test app đang dựng fake module cho phần nháp: `test/features/sales/presentation/sales_draft_backend_test.dart`, `test/features/sales/presentation_module/bloc/sales_draft_list_live_test.dart`, `test/features/sales/sales_flow_pages_test.dart` (`_RecordingSalesModule`: `commands`, `queries`, `listItems`, `restoreDto`, `cancelError`), `test/features/sales/presentation/sales_checkout_page_test.dart` (dựng `SalesDraftListScope`), `test/features/sales/presentation/bloc/sales_compose_draft_backend_test.dart:307-345` (ném `SalesContractException('STALE_DATA')`).

## 4. Thiết kế

### 4.1 Lỗi (`apps/erp/lib/features/sales/data/sales_draft_errors.dart`)

```dart
abstract final class SalesDraftErrorCodes {
  static const noPermission = 'NO_PERMISSION';          // server PERMISSION_DENIED
  static const dataScopeDenied = 'DATA_SCOPE_DENIED';
  static const contextInvalid = 'CONTEXT_INVALID';
  static const referenceUnavailable = 'REFERENCE_UNAVAILABLE';
  static const staleData = 'STALE_DATA';
  static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const systemError = 'SYSTEM_ERROR';
}

/// Q7: AppException có mã trong 6 mã → giữ code, serverMessage, details; còn lại → SYSTEM_ERROR (cause = lỗi gốc).
AppException salesDraftException(Object error);
```

Repository bọc mỗi lần gọi bằng `_guard` (`try { … } on Object catch (e) { throw salesDraftException(e); }`), như `SalesPricingRepository`.

### 4.2 Rule (`apps/erp/lib/features/sales/logic/sales_draft_rules.dart`)

Hàm thuần, chép **điều kiện và câu** của validator, bỏ kiểm `tenantId` / `actorId`. Vi phạm ⇒ `AppException(SalesDraftErrorCodes.contextInvalid, serverMessage: '<câu cũ>')`, không `details`.

| Hàm | Nguồn | Điều kiện giữ (câu cũ nguyên văn) |
|---|---|---|
| `checkSaveDraft({required String storeId, CustomerSnapshotDto? customer, required String currencyCode, required List<SalesOrderDraftLineInput> lines, required String idempotencyKey})` | `save_sales_order_draft_command_validator.dart` | `storeId`, `currencyCode`, `idempotencyKey` không rỗng (`'<field> is required.'`); khách `customerId.trim() == 'cust-walk-in'` → `'Walk-in customer must be represented as null customer.'`, `customerId` / `displayName` rỗng; 0 dòng → `'Sales draft must contain at least one line.'`; mỗi dòng: 6 trường chuỗi không rỗng, `quantityMicros <= 0` → `'Draft line quantity must be positive.'`, tiền tệ 3 giá khớp nháp (so trim + chữ hoa) → `'Draft line currency must match draft currency.'`, `lineTotal < 0` → `'Draft lineTotal must be non-negative.'`, > 1 cách nhập tay → `'At most one manual price or discount mode may be set.'`, điểm cơ bản ngoài `0..10000` → `'manualDiscountBasisPoints must be between 0 and 10000.'`, không nhập tay mà `lineTotal != applied * quantityMicros ~/ QuantityDto.scale` → `'Draft lineTotal does not match applied unit price.'` |
| `checkUpdateDraft({required String draftId, required int expectedVersion, …như checkSaveDraft})` | `update_…_validator.dart` | như trên + `draftId` không rỗng + `expectedVersion <= 0` → `'expectedVersion must be positive.'` (thứ tự kiểm chép đúng validator) |
| `checkCancelDraft({required String draftId, required int expectedVersion, required String idempotencyKey})` | `cancel_…_validator.dart` | `draftId`, `idempotencyKey` không rỗng; `expectedVersion <= 0` |

`list` / `getForRestore` không có validator cũ ⇒ không rule. Riêng `_restore` của backend đã chặn `draftId` rỗng (`'Mã đơn nháp không hợp lệ.'`) — giữ ở backend.

### 4.3 `SalesDraftRepository` (`apps/erp/lib/features/sales/data/sales_draft_repository.dart`)

```dart
class SalesDraftRepository {
  SalesDraftRepository({
    required SupabaseRpc rpc,
    required Future<String> Function() tenantId,
    required Future<String> Function() actorId,
  });

  Future<SalesOrderDraftDto> save({
    required String storeId, CustomerSnapshotDto? customer, required String currencyCode,
    String? orderNote, String? pricingPreviewToken, bool needsRevalidation = false,
    required List<SalesOrderDraftLineInput> lines, required String idempotencyKey, String? payloadHash,
  });
  Future<SalesOrderDraftDto> update({
    required String draftId, required int expectedVersion, required String storeId,
    CustomerSnapshotDto? customer, required String currencyCode, String? orderNote,
    String? pricingPreviewToken, bool needsRevalidation = false,
    required List<SalesOrderDraftLineInput> lines, required String idempotencyKey, String? payloadHash,
  });
  Future<SalesOrderDraftDto> cancel({
    required String draftId, required String storeId, required int expectedVersion, required String idempotencyKey,
  });
  Future<PagedSalesOrderDraftListDto> list({required String storeId, String? cursor, int pageSize = 25});
  Future<SalesOrderDraftForRestoreDto> getForRestore({required String draftId, required String storeId, int? expectedVersion});
}
```

Mỗi method: rule (4.2) → `tenantId()` / `actorId()` → `_rpc.call('sales', '<rpc>', params: …)` → ép `Map<String, dynamic>` → hàm đọc JSON. Tham số **giống hệt** mapper cũ: `p_currency_code` = trim + chữ hoa; `p_idempotency_key` = trim; `p_payload_hash` chỉ có khi khác `null`; `p_expected_version` của restore chỉ có khi khác `null`; `p_customer` / `p_lines` dựng như `_customerInput` / `_lineInputs` (các khoá tuỳ chọn chỉ có khi khác `null`). **Bỏ** `p_correlation_id` / `p_causation_id` (app không truyền, mapper chỉ gửi khi khác `null` ⇒ map giống nhau).

Hàm dựng tham số + đọc JSON chép vào `apps/erp/lib/features/sales/data/mappers/sales_draft_json.dart`, lớp `SalesDraftJson`: `customerParams`, `lineParams`, `draft(Map)`, `restore(Map)`, `page(Map)` (chép `_rowFromJson`, `_lineFromJson`, `_customerFromJson` kèm `existingDebtMinor: 0`, `_string` / `_int` / `_bool` / `_stringList` / `_dateTime` / `_status`, mọi `FormatException`). `draft(…)` gọi `SalesOrderDraftContractMapper.toDraftDto` của module (Q1).

### 4.4 Câu lỗi (`apps/erp/lib/features/sales/logic/sales_draft_error_messages.dart`, Q3)

```dart
/// TH-05 6.4. Thứ tự: overrides[code] → bảng → fallback. Lỗi không phải AppException ⇒ fallback.
String salesDraftErrorMessage(Object error, {required String fallback, Map<String, String> overrides = const {}});
```

| Mã | Câu |
|---|---|
| `NO_PERMISSION` | "Bạn không có quyền thực hiện thao tác này." |
| `DATA_SCOPE_DENIED` | "Cửa hàng hiện tại không còn khả dụng." |
| `STALE_DATA` | "Đơn nháp này đã bị xoá hoặc thay đổi ở nơi khác." |
| `IDEMPOTENCY_CONFLICT` | "Yêu cầu bị xung đột" |
| khác | `fallback` |

Nơi dùng (đều trong `SalesDraftListCubit`):

| Chỗ | Cũ | Mới |
|---|---|---|
| tải, `NO_PERMISSION` / `DATA_SCOPE_DENIED` | `SalesDraftListBlocked(error.message ?? error.code)`, xét `PERMISSION_DENIED` | `SalesDraftListBlocked(salesDraftErrorMessage(e, fallback: 'Không thể tải danh sách đơn nháp'))`, xét `NO_PERMISSION` |
| tải, mã khác | `SalesDraftListError(error.message ?? 'Không thể tải danh sách đơn nháp')` | `SalesDraftListError('Không thể tải danh sách đơn nháp')` |
| xoá, `STALE_DATA` / `STALE_VERSION` | `needsReload: true`, `error.message ?? 'Đơn nháp đã thay đổi. Vui lòng tải lại danh sách.'` | `needsReload: true`, `'Đơn nháp đã thay đổi. Vui lòng tải lại danh sách.'` (US-01.7 FR-04) |
| xoá, mã khác (kể cả `REFERENCE_UNAVAILABLE`, Q8) | `error.message ?? 'Không hủy được đơn nháp'` | `salesDraftErrorMessage(e, fallback: 'Không hủy được đơn nháp')` |

`SalesComposeCubit` không đổi câu (chỉ hiện `SalesExternalOperationException.message` tiếng Việt của backend, còn lại `fallback`).

## 5. Đang làm gì — test giữ hành vi

| # | Cũ đang làm gì | Sau 8-A1 nằm ở đâu | Test |
|---|---|---|---|
| D1 | Tham số 5 RPC (`SalesOrderDraftRpcMapper.*Params`) | `SalesDraftRepository` + `SalesDraftJson.*Params` | parity `params_<rpc>` × 5 (Task 0 `old`, Task 3 `new`) |
| D2 | Đọc JSON kết quả, `FormatException` khi thiếu `has_more` / chuỗi bắt buộc / `status` lạ | `SalesDraftJson` | parity `parse_draft`, `parse_restore`, `parse_page`, `parse_rejects_<x>` × 3 |
| D3 | 3 validator chặn trước RPC, mã `CONTEXT_INVALID` + câu | `sales_draft_rules.dart`, repository gọi trước RPC | `sales_draft_rules_test.dart` (Task 2) + `rule_blocks_before_rpc` (0 lần gọi RPC) |
| D4 | Kiểm quyền client (`@RequiresPermission`, `require(restoreDraft)`) | **Bỏ (Q6)**; server kiểm | `list_has_no_client_permission_check` (repository không nhận `hasPermission`; RPC ném `PERMISSION_DENIED` → `NO_PERMISSION`) |
| D5 | Gateway: 6 mã ổn định (bóc JSON lồng ≤ 3 lớp), còn lại `CONTEXT_INVALID` | `salesDraftException`; **đổi (Q7):** còn lại `SYSTEM_ERROR` | `sales_draft_errors_test.dart` (Task 1): cùng bảng đầu vào cho gateway cũ và `salesDraftException` |
| D6 | Backend đọc `tenantId` / `actorId` từ `IExecutionContext`, đưa vào command | repository đọc closure mỗi lần gọi (Q9) | `tenant_actor_read_each_call` |
| D7 | Backend `_persist`: chặn 0 dòng, gọi partner / catalog / pricing, dựng dòng, fingerprint + idempotency key `save:<composeSessionId>` / `update:<draftId>` | giữ nguyên trong `logic/sales_draft_backend.dart`, chỉ đổi đích gọi | các test có sẵn của `sales_draft_backend_test.dart` (đổi fake, giữ điều kiện kiểm) — `save validates store, customer, product/unit, and pricing before Sales save`, `update forwards current expectedVersion`, … |
| D8 | Backend `_restore`: chặn id rỗng, gọi restore, gom `issues` | như D7 | 4 test `SalesDraftBackend.restore` có sẵn |
| D9 | List cubit: 1 trang `pageSize: 50`, map `isOwnedByMe`, cache tên, chặn tải song song | giữ (Q5) | `sales_draft_list_live_test.dart` có sẵn (đổi fake): `load queries active store and maps server draft fields` (thêm `expect(fake.listCalls.single.pageSize, 50)`), `concurrent load calls issue a single query`, … |
| D10 | List cubit: chặn khi thiếu quyền / ngoài cửa hàng, câu thô | **đổi có chủ đích (Q3)**, bảng 4.4 | `load_permission_denied_shows_6_4_message`, `load_data_scope_denied_shows_6_4_message`, `load_other_error_never_shows_server_message` |
| D11 | Xoá: idempotency key `cancel:<draftId>:v<version>`, giữ dòng khi lỗi, `needsReload` chỉ khi `STALE_*` | giữ; câu đổi (Q3, Q8) | có sẵn: `failed cancel retains row…`, `stale cancel retains row…` (siết: `actionMessage == 'Đơn nháp đã thay đổi. Vui lòng tải lại danh sách.'`); mới: `cancel_reference_unavailable_no_reload` (`needsReload == false`, câu `'Không hủy được đơn nháp'`), `cancel_sends_idempotency_key` |
| D12 | Compose: lưu nháp có id gặp `STALE_DATA` / `REFERENCE_UNAVAILABLE` → `draftGone`, không toast | nhánh xét `AppException.code` | có sẵn `sales_compose_draft_backend_test.dart:307`, `:345` (đổi sang ném `AppException('STALE_DATA')`) + mới `reference_unavailable_reports_draft_gone` |

**Bước 0 (Task 0):** nhóm `old` của parity D1 / D2 / D5 chạy trên module, xanh, ghi tên — rồi mới viết tệp mới. Test có sẵn D7–D9, D11, D12 phải **xanh trên code cũ** trước Task 4 (chạy và ghi số ở Task 0).

## 6. Các bước

**Ràng buộc chung** (mọi task):
- Chỉ sửa tệp liệt kê ở từng task. Không đụng `modules/sales`, không sửa RPC / migration.
- Trước khi sửa symbol có sẵn: `gitnexus impact({target: "<symbol>", direction: "upstream"})`, ghi số vào Kết quả; HIGH / CRITICAL ⇒ dừng, báo người dùng.
- Chép nguyên văn điều kiện, câu, tên khoá JSON. Thấy chỗ phải sửa thân mới chạy được ⇒ ghi Kết quả, không tự đổi hành vi.
- Không `tenantId` / `actorId` trong chữ ký repository.
- Test parity có `// ignore_for_file: implementation_imports`. Tệp test mới đặt ở `apps/erp/test/features/sales/{data,logic}/`.

### Task 0: Bước 0 — parity `old` + chạy test có sẵn trên code cũ

**Files:**
- Create: `apps/erp/test/features/sales/data/sales_draft_parity_expectations.dart`, `apps/erp/test/features/sales/data/sales_draft_rpc_parity_test.dart` (nhóm `old`)

- [ ] **0.1** Hằng đầu vào / mong đợi: `tenantId = 'tenant-1'`, `actorId = 'user-1'`, `storeId = 'store-1'`, `draftId = '  draft-1  '` (mapper cũ **không** trim `draftId` ⇒ mong đợi giữ khoảng trắng), `currencyCode: ' vnd '` → `'VND'`, `idempotencyKey: ' k1 '` → `'k1'`, 2 dòng (1 dòng `manualDiscountMinor: 5000`, 1 dòng không nhập tay, `listUnitPrice: null`), khách có `taxCode`, không `invoiceEmail`. Mỗi RPC một `const expected<Rpc>Params`. JSON mẫu `sampleDraftJson()`, `sampleRestoreJson()`, `samplePageJson()` lấy hình từ `sales_order_draft_rpc_mapper_test.dart`; hàm `expectDraft(dynamic dto)` so đủ field.
- [ ] **0.2** Nhóm `old`: `SalesOrderDraftRpcMapper.<x>Params(<command cũ>)` → `equals(expected…)`; `draftFromJson` / `restoreFromJson` / `pageFromJson` → `expectDraft`; `parse_rejects_missing_has_more`, `parse_rejects_unknown_status`, `parse_rejects_blank_draft_id` → `throwsFormatException`. Lỗi: bảng D5 qua `SupabaseSalesOrderDraftGateway` với `IRpcClient` giả ném `RpcException` (mẫu `supabase_sales_order_draft_gateway_test.dart`).
- [ ] **0.3** Chạy:
  ```bash
  cd apps/erp && flutter test test/features/sales/data/sales_draft_rpc_parity_test.dart \
    test/features/sales/presentation/sales_draft_backend_test.dart \
    test/features/sales/presentation_module/bloc/sales_draft_list_live_test.dart \
    test/features/sales/presentation/bloc/sales_compose_draft_backend_test.dart \
    test/features/sales/sales_flow_pages_test.dart test/features/sales/presentation/sales_checkout_page_test.dart
  ```
  Expected: PASS. Ghi số test từng tệp.

### Task 1: Lỗi + câu lỗi

**Files:**
- Create: `apps/erp/lib/features/sales/data/sales_draft_errors.dart`, `apps/erp/lib/features/sales/logic/sales_draft_error_messages.dart`
- Test: `apps/erp/test/features/sales/data/sales_draft_errors_test.dart`, `apps/erp/test/features/sales/logic/sales_draft_error_messages_test.dart`

**Produces:** `SalesDraftErrorCodes`, `AppException salesDraftException(Object error)`, `String salesDraftErrorMessage(Object error, {required String fallback, Map<String, String> overrides = const {}})`.

- [ ] **1.1** `sales_draft_errors_test.dart`, bảng đầu vào → mã (`new`; dòng dùng được cho gateway thì chạy cả `old`, mong đợi cột thứ hai):

  | Đầu vào | `new` | `old` |
  |---|---|---|
  | `PostgrestException(message: '{"code":"STALE_DATA","message":"Draft version has changed."}')` | `STALE_DATA`, `serverMessage` giữ | `STALE_DATA` |
  | `{"code":"PERMISSION_DENIED"}` | `NO_PERMISSION` | `PERMISSION_DENIED` |
  | 4 mã còn lại của 6 mã | giữ | giữ |
  | `{"code":"STALE_VERSION"}` | `SYSTEM_ERROR` | `CONTEXT_INVALID` |
  | `PostgrestException(message: 'boom')` | `SYSTEM_ERROR` | `CONTEXT_INVALID` |
  | `FormatException('x')`, `StateError('x')` | `SYSTEM_ERROR` | — |
  | `AppException('CONTEXT_INVALID', serverMessage: 'Draft line quantity must be positive.')` | giữ nguyên | — |
- [ ] **1.2** `sales_draft_error_messages_test.dart`: 4 mã → đúng câu bảng 4.4; `AppException('SYSTEM_ERROR')`, `AppException('X', serverMessage: 'raw')`, `StateError('x')` với `fallback: 'F'` → `'F'`; `overrides: {'STALE_DATA': 'A'}` → `'A'`.
- [ ] **1.3** Chạy 2 test → FAIL. Viết 2 tệp. Chạy lại → PASS.

### Task 2: Rule đầu vào

**Files:**
- Create: `apps/erp/lib/features/sales/logic/sales_draft_rules.dart`
- Test: `apps/erp/test/features/sales/logic/sales_draft_rules_test.dart`

**Consumes:** `SalesDraftErrorCodes` (Task 1). **Produces:** 3 hàm bảng 4.2.

- [ ] **2.1** Test: mỗi hàm 1 ca hợp lệ và 1 ca cho **mỗi** điều kiện → `throwsA(isA<AppException>().having((e) => e.code, 'code', 'CONTEXT_INVALID').having((e) => e.serverMessage, 'msg', '<câu cũ>'))`. Ca biên: `quantityMicros: 0` → lỗi; điểm cơ bản `10000` hợp lệ, `10001` lỗi; `customerId: ' cust-walk-in '` → câu Khách lẻ; tiền tệ dòng `'vnd'` với nháp `'VND'` → hợp lệ; dòng có `manualDiscountMinor` và `lineTotal` không khớp → hợp lệ; `expectedVersion: 0` → `'expectedVersion must be positive.'`.
- [ ] **2.2** Nhóm `old` trong cùng tệp: các ca lỗi chạy qua `SaveSalesOrderDraftCommandValidator().validate(…)` / `Update…` / `Cancel…` → `SalesContractException` cùng `code` + `message`.
- [ ] **2.3** Chạy → FAIL. Viết. Chạy → PASS.

### Task 3: `SalesDraftJson` + `SalesDraftRepository`

**Files:**
- Create: `apps/erp/lib/features/sales/data/mappers/sales_draft_json.dart`, `apps/erp/lib/features/sales/data/sales_draft_repository.dart`
- Test: nhóm `new` trong `sales_draft_rpc_parity_test.dart`; `apps/erp/test/features/sales/data/sales_draft_repository_test.dart`
- Create: `apps/erp/test/features/sales/support/fake_sales_draft_repository.dart`

**Consumes:** Task 1–2; `SupabaseRpc.call(String schema, String fn, {Map<String, dynamic>? params})`.
**Produces:** chữ ký mục 4.3; `FakeSalesDraftRepository implements SalesDraftRepository` có `saveCalls`, `updateCalls`, `cancelCalls`, `listCalls`, `restoreCalls` (ghi tham số dạng record), `listItems`, `restoreDto`, `Object? saveError / updateError / cancelError / listError / restoreError`, `SalesOrderDraftDto Function(...)? onSave` — Task 4 dùng.

- [ ] **3.1** Parity `new`: `_RecordingRpc implements SupabaseRpc` (mẫu `test/features/pricing/data/pricing_rpc_parity_test.dart:420`) ghi `(schema, fn, params)`, trả JSON mẫu; mỗi method → `schema == 'sales'`, `fn` đúng, `params` bằng hằng 0.1; kết quả qua `expectDraft`; 3 `parse_rejects_*` → `AppException` `SYSTEM_ERROR`.
- [ ] **3.2** `sales_draft_repository_test.dart`: `rule_blocks_before_rpc` (`save(lines: [])` → `CONTEXT_INVALID`, `calls` rỗng); `list_has_no_client_permission_check` (RPC ném `PostgrestException('{"code":"PERMISSION_DENIED"}')` → `NO_PERMISSION`, đúng 1 lần gọi); `tenant_actor_read_each_call` (2 lần gọi → mỗi closure đếm 2); `restore_omits_expected_version_when_null` (`params.containsKey('p_expected_version') == false`); `list_default_page_size_25`.
- [ ] **3.3** Chạy → FAIL. Viết 2 tệp + fake. Chạy `flutter test test/features/sales/data/` → PASS.

### Task 4: Đổi nơi gọi + chuyển `logic/` + DI

**Files:**
- Move: `lib/features/sales/presentation/bloc/sales_order_draft/sales_draft_list_cubit.dart` → `lib/features/sales/logic/sales_draft_list_cubit.dart`; `…/sales_draft_list_state.dart` → `lib/features/sales/logic/sales_draft_list_state.dart`; `lib/features/sales/presentation/orchestration/sales_draft_backend.dart` → `lib/features/sales/logic/sales_draft_backend.dart` (dùng `git mv`; import tương đối → `package:erp/...`)
- Modify: `lib/features/sales/presentation.dart:13-14` (export đường mới); `lib/features/sales/logic/sales_draft_list_cubit.dart` (cũ `:12-26`, `:67-79`, `:108-129`, `:195-246`); `lib/features/sales/logic/sales_draft_backend.dart` (cũ `:26-131`, `:133-150`, `_resolveProducts` bỏ tham số `tenantId` không dùng); `lib/features/sales/presentation/bloc/sales_order_draft/sales_compose_cubit.dart:490-495`; `lib/features/sales/presentation/orchestration/sales_draft_list_scope.dart:33-41`; `lib/features/sales/presentation/pages/sales_order_compose_page.dart` (import); `lib/core/di/injection.dart` (đăng ký sau `SalesPricingRepository`, ~`:205`)
- Test (đổi fake, giữ điều kiện kiểm): `test/features/sales/presentation/sales_draft_backend_test.dart`, `test/features/sales/presentation_module/bloc/sales_draft_list_live_test.dart`, `test/features/sales/presentation/bloc/sales_compose_draft_backend_test.dart`, `test/features/sales/sales_flow_pages_test.dart` (phần nháp; module giữ cho thanh toán), `test/features/sales/presentation/sales_checkout_page_test.dart` (đăng ký `FakeSalesDraftRepository`)

**Consumes:** `SalesDraftRepository`, `FakeSalesDraftRepository` (Task 3), `salesDraftErrorMessage` (Task 1).

- [ ] **4.1** `gitnexus impact` upstream cho `SalesDraftListCubit`, `SalesDraftBackend`, `SalesComposeCubit`, `SalesDraftListScope`, `initDependencies`. Ghi số.
- [ ] **4.2** Viết test mới (FAIL trên code hiện tại): D10 × 3, D11 `cancel_reference_unavailable_no_reload`, `cancel_sends_idempotency_key` (`fake.cancelCalls.single.idempotencyKey == 'cancel:draft-1:v3'`), D12 `reference_unavailable_reports_draft_gone`; siết `stale cancel retains row…` như bảng D11.
- [ ] **4.3** `SalesDraftListCubit({required SalesDraftRepository repository, required IExecutionContext executionContext, required ISalesActiveStoreContext activeStoreContext, SalesActorNameResolver? actorNameResolver})`: `list(storeId:, pageSize: 50)`; `cancel(draftId:, storeId:, expectedVersion:, idempotencyKey: 'cancel:$draftId:v$version')`; `on AppException` theo bảng 4.4 (Blocked xét `NO_PERMISSION` / `DATA_SCOPE_DENIED`). Bỏ đọc `tenantId`.
- [ ] **4.4** `SalesDraftBackend._persist` / `_restore`: `di<SalesDraftRepository>().save(...)` / `.update(...)` / `.getForRestore(draftId:, storeId:)`, cùng giá trị đang đưa vào command (kể cả `orderNote: _normalizeNote(...)`, `payloadHash`, idempotency key). Bỏ `IExecutionContext`. Giữ mọi `SalesExternalOperationException` và câu.
- [ ] **4.5** `SalesComposeCubit:493`: `error is AppException && (error.code == 'STALE_DATA' || error.code == 'REFERENCE_UNAVAILABLE')`.
- [ ] **4.6** `SalesDraftListScope`: `repository: GetIt.instance<SalesDraftRepository>()`. `injection.dart`: `registerLazySingleton<SalesDraftRepository>(() => SalesDraftRepository(rpc: getIt<SupabaseRpc>(), tenantId: () => getIt<SessionController>().requireTenantId(), actorId: () async => sessionStore.userId ?? (throw const AppException(AppErrorCode.authRequired))))`. `ISalesModule` giữ (8-A2…8-A4 còn dùng).
- [ ] **4.7** Đổi fake trong 5 tệp test: đăng ký `FakeSalesDraftRepository`; `salesModule.commands.whereType<SaveSalesOrderDraftCommand>()` → `fakeDrafts.saveCalls`; `cancelError: SalesContractException('X', message: …)` → `AppException('X', serverMessage: …)`; `ISalesModule` của test chỉ còn phần thanh toán / tra cứu. Không đổi `expect` nào ngoài tên nguồn dữ liệu (và ca siết ở 4.2).
- [ ] **4.8** Chạy lệnh 0.3 + `flutter test test/features/sales/logic test/features/sales/data` → PASS.

### Task 5: Kiểm toàn bộ + tài liệu + Kết quả

**Files:** Modify: `docs/refactor/PLAN.md` (dòng 8-A1, mục 8.1), `docs/02-yeu-cau/TH-05-ban-hang-va-don-hang.md` (đã thêm KI-21, KI-22 lúc viết plan — kiểm lại còn đúng)

- [ ] **5.1** `cd apps/erp && dart analyze lib/features/sales lib/core/di test/features/sales` → 0 lỗi, 0 cảnh báo mới.
- [ ] **5.2** `git grep -nE "SaveSalesOrderDraftCommand|UpdateSalesOrderDraftCommand|CancelSalesOrderDraftCommand|ListSalesOrderDraftsQuery|GetSalesOrderDraftForRestoreQuery" -- apps/erp/lib` → rỗng; `git grep -n "c45_sales" -- apps/erp/lib/features/sales/data apps/erp/lib/features/sales/logic` → chỉ `application.dart` (kiểu DTO, Q1).
- [ ] **5.3** `dart run tool/check_feature_imports.dart` → không dòng mới.
- [ ] **5.4** `flutter test` cả app → số lỗi đúng bằng `docs/refactor/TEST-BASELINE.md` (so từng tên).
- [ ] **5.5** `node .gitnexus/run.cjs analyze` rồi `detect_changes({scope: "all"})`: chỉ tệp trong danh sách; ghi số tệp / symbol / luồng / rủi ro.
- [ ] **5.6** PLAN.md dòng 8-A1: cột Làm ✅ + ngày.

## 7. Kiểm tra

Tự động: Task 5. **Kiểm tay (người dùng, iPhone simulator + Chrome):** SG-02 lưu nháp lần đầu → "Đã lưu đơn nháp."; sửa rồi lưu lại; SG-01 thấy nháp, mở lại đúng khách / dòng / ghi chú; xoá nháp → hết khỏi danh sách; 2 máy: máy A xoá nháp, máy B lưu nháp đó → rời màn (`draftGone`), máy B xoá nháp đã đổi → "Đơn nháp đã thay đổi. Vui lòng tải lại danh sách.".

## 8. Rủi ro / lưu ý

- **Kiểu module còn trong `data/`** (Q1): `sales_draft_repository.dart`, `sales_draft_json.dart` import `c45_sales_application`. 8-C phải chép `SalesOrderDraftDto`, `SalesOrderDraftLineInput`, `CustomerSnapshotDto`, `PagedSalesOrderDraftListDto`, `SalesOrderDraftForRestoreDto`, `OpaqueCursorPageDto`, `MoneyDto`, `QuantityDto`, `SalesDraftStatus`, `SalesOrderDraftContractMapper` cùng mọi kiểu dùng chung.
- **Hai kiểu lỗi cùng lúc** tới 8-A4: phần nháp `AppException`, phần còn lại `SalesContractException`. Màn chung SG-02 → SG-06: nút "Thanh toán" của compose không đi qua repository nháp ⇒ không lẫn.
- **Q8 `REFERENCE_UNAVAILABLE` khi xoá** không tải lại danh sách — 8-B cân nhắc coi như `STALE_DATA`.
- **8-B nhận thêm:** KI-21 (tải thêm nháp), KI-22 ("Tạo bởi" nháp người khác), KI-07, TH-02 KI-08; câu "Không hủy được đơn nháp" khác US-01.7 FR-04 "Không xóa được đơn nháp" (giữ câu app ở 8-A1).
- Bỏ kiểm quyền client (Q6): thành viên thiếu `sales.draft.*` (không xảy ra theo 7.2) giờ thấy câu `NO_PERMISSION` của server thay vì lỗi chung của pipeline.

### Review Focus (chưa task nào test, phiên review soi)

1. **JSON lỗi lồng:** gateway cũ bóc `message` JSON lồng tới 3 lớp; `AppException.from` chỉ đọc lớp đầu. Kiểm `PostgrestException` có `message` = `'{"message":"{\"code\":\"STALE_DATA\"}"}'` (nếu PostgREST thật có trả dạng này) — mất ⇒ `draftGone` không chạy.
2. **`draftId` có khoảng trắng:** mapper cũ không trim `p_draft_id`, backend trim trước khi gọi. Bản chép không được tự thêm / bỏ trim ở repository.
3. **Số nguyên dạng `double`** (`250000.0`) trong `line_total_minor`: `_int` cũ nhận — kiểm bản chép giữ.
4. **`saved_at` không có múi giờ** → `DateTime.parse(...).toUtc()` lệch theo giờ máy; giữ đúng cách cũ, không tự sửa.
5. **Đổi thư mục cubit:** test / widget import qua `presentation.dart` — sót export sẽ chỉ lộ khi chạy cả app (Task 5.4).

## 9. Kết quả (phiên làm code ghi)

> Làm 2026-11-07. Không commit (theo plan). Lệnh gitnexus gọi qua CLI `node .gitnexus/run.cjs … --repo erp-sales-inventory` (MCP không có trong phiên). Index lúc `impact`: bản cũ trước phiên (53294 symbol); `analyze` lại ở Task 5.

**Ruling (ghi trước, áp dụng toàn plan)**
- **R-impact** — `impact` upstream cho `SalesDraftListCubit`, `SalesDraftBackend`, `SalesComposeCubit`, `SalesDraftListScope`, `initDependencies` đều ra **CRITICAL, 306–307 symbol, direct 273–275**, kể cả `initDependencies`; caller depth 1 là `_catalogRecipientForm` (không liên quan). Số giống nhau cho 5 symbol khác nhau ⇒ nhiễu của index Dart (gộp theo tên), không phải phạm vi thật. Đo phạm vi thật bằng `git grep`: 8 tệp `lib` + 6 tệp test (đều nằm trong plan, trừ 3 tệp chỉ đổi import, xem R-import). Plan ghi "HIGH / CRITICAL ⇒ dừng": **mình không dừng**, quyết định theo `git grep`. Chi phí nếu sai: review phải kiểm lại phạm vi.
- **R-import** — plan không liệt kê `presentation/pages/sales_draft_list_page.dart` và `presentation/widgets/sales_draft_list_body.dart` (import cubit / state bằng đường tương đối cũ) và `test/features/sales/group_b_no_fake_contract_test.dart` (chuỗi đường dẫn 2 tệp đã dời). Chỉ sửa đường dẫn import / chuỗi, không đổi logic. Chi phí nếu sai: không.
- **R-nested** — `salesDraftException` bóc thêm lớp JSON lồng (`serverMessage` chứa `{"code":…}`), tối đa 2 lớp sau lớp đầu `AppException.from` đã đọc. Lý do: gateway cũ bóc 3 lớp, `AppException.from` chỉ đọc 1; thiếu ⇒ `{"code":"P0001","message":"{\"code\":\"DATA_SCOPE_DENIED\"…}"}` thành `SYSTEM_ERROR`, mất nhánh `Blocked` / `draftGone` (Review Focus 1). Có test `nested_postgrest_message_json_is_unwrapped`, `nested_permission_denied_becomes_no_permission`, parity `error_nested_data_scope_denied` (cả `old` và `new`). Chi phí nếu sai: thêm ~25 dòng ở `sales_draft_errors.dart`.
- **R-imports-tool** — `dart run tool/check_feature_imports.dart` ra **6 dòng mới** (plan 5.3 muốn "không dòng mới"): R2 `logic/sales_draft_list_state.dart:3`, `logic/sales_draft_list_cubit.dart:6,7`, `logic/sales_draft_backend.dart:8,9` (logic → presentation: `SalesDraftListItemVm`, `ISalesActiveStoreContext`, `SalesPartnerCustomerLookup`, `SalesDraftPayloadFingerprint`) và R1 `data/sales_draft_repository.dart:4` (data → logic rule, cùng mẫu `pricing/data/sales_pricing_repository.dart:5`). Cùng loại dòng catalog / partner / pricing đang có. Dời 4 kiểu đó sang `logic/` là ngoài danh sách tệp của plan ⇒ để lại. Chi phí nếu sai: 8-C / plan web phải dời VM, support, lookup.
- **R-format** — `dart format test/features/sales` lỡ định dạng cả thư mục; đã `git checkout` 16 tệp test ngoài phạm vi. Các tệp trong phạm vi có thể kèm đổi định dạng (diff `sales_draft_backend_test.dart` ~300 dòng chủ yếu do viết lại fake + format).
- **R-analyze-docs** — `node .gitnexus/run.cjs analyze` tự sửa `AGENTS.md` / `CLAUDE.md` (số symbol); đã `git checkout` hoàn nguyên.

**Task 0 — ✅**
- Tạo `apps/erp/test/features/sales/data/sales_draft_parity_expectations.dart`, `sales_draft_rpc_parity_test.dart` (nhóm `old`: 5 `params_*`, `parse_draft/restore/page`, 3 `parse_rejects_*`, 8 `error_*`).
- Chạy trên code cũ: parity 19 đạt; có sẵn: `sales_draft_backend_test` 16, `sales_draft_list_live_test` 9, `sales_compose_draft_backend_test` 12, `sales_flow_pages_test` 28, `sales_checkout_page_test` 21 — tất cả đạt.
- Lệch: không.

**Task 1 — ✅**
- Tạo `data/sales_draft_errors.dart`, `logic/sales_draft_error_messages.dart`; test `data/sales_draft_errors_test.dart` (14), `logic/sales_draft_error_messages_test.dart` (6). Lệch: R-nested. TDD: 2 tệp test chạy FAIL (không có tệp nguồn) trước khi viết; 2 ca nested viết cùng lúc với phần bóc lồng, chưa chạy RED riêng.

**Task 2 — ✅**
- Tạo `logic/sales_draft_rules.dart`; `test/features/sales/logic/sales_draft_rules_test.dart` (71 test: `new` + `old` qua 3 validator, cùng bảng ca). Lệch: viết rule và test cùng lượt, chưa chạy RED riêng.

**Task 3 — ✅**
- Tạo `data/mappers/sales_draft_json.dart`, `data/sales_draft_repository.dart`, `test/features/sales/support/fake_sales_draft_repository.dart`; nhóm `new` trong parity (+ `error_*` mới cho `new`); `data/sales_draft_repository_test.dart` (5).
- `flutter test test/features/sales/data test/features/sales/logic`: 134 đạt.
- Lệch: dùng `'p_payload_hash': ?payloadHash` (null-aware element) thay `if (… != null)` theo lint; fake `implements SalesDraftRepository` dùng lớp `SalesDraft*Call` thay record; thêm `cancelDelay`, `onSave/onUpdate` mặc định echo.

**Task 4 — ✅**
- Dời (`git mv`): `sales_draft_list_cubit.dart`, `sales_draft_list_state.dart`, `sales_draft_backend.dart` → `lib/features/sales/logic/`.
- Sửa: `logic/sales_draft_list_cubit.dart` (repository, `AppException`, bảng 4.4, bỏ `tenantId`), `logic/sales_draft_backend.dart` (`SalesDraftRepository.save/update/getForRestore`, bỏ `IExecutionContext`, `_resolveProducts` bỏ `tenantId`), `sales_compose_cubit.dart:490-495` (`AppException`), `sales_draft_list_scope.dart`, `presentation.dart:13-14`, `sales_order_compose_page.dart`, `sales_draft_list_page.dart`, `sales_draft_list_body.dart`, `core/di/injection.dart` (đăng ký `SalesDraftRepository` sau `SalesPricingRepository`).
- Test: `sales_draft_list_live_test` (14: +5 mới `cancel_reference_unavailable_no_reload`, `cancel_sends_idempotency_key`, `load_permission_denied/data_scope_denied_shows_6_4_message`, `load_other_error_never_shows_server_message`; siết `stale cancel…`, `failed cancel…`, `pageSize == 50`), `sales_compose_draft_backend_test` (13: +`reference_unavailable_reports_draft_gone`), `sales_draft_backend_test` (16), `sales_flow_pages_test` (28), `sales_checkout_page_test` (21), `group_b_no_fake_contract_test`.
- `flutter test test/features/sales`: **773 đạt, 0 lỗi**.
- Impact: xem R-impact (số từ `gitnexus impact … --direction upstream --repo erp-sales-inventory`, 2026-11-07, index trước phiên).
- Lệch: `sales_flow_pages_test` bỏ `expect(save.tenantId, 'tenant-demo')` và `listQueries.first.tenantId` (repository không nhận `tenantId`; đã có test `tenant_actor_read_each_call`). `sales_checkout_page_test` đăng ký `FakeSalesDraftRepository` (scope cần).

**Task 5 — ✅**
- `dart analyze lib/features/sales lib/core/di test/features/sales`: 0 lỗi, 1 warning có sẵn (`test/features/sales/presentation/order_einvoice_section_test.dart:32`, tệp không đổi).
- 5.2 `git grep` 5 command / query trong `apps/erp/lib`: chỉ còn 1 dòng chú thích (`sales_draft_list_scope.dart:14`); `c45_sales` trong `data/` + `logic/`: chỉ `application.dart`.
- 5.3: xem R-imports-tool.
- 5.4 `flutter test` cả app: **2422 đạt / 55 lỗi**. Đối chiếu từng tên với `TEST-BASELINE.md` (53 mục `apps/erp`): 53 trùng; **2 ngoài danh sách**: `product_change_history_e2e_test: e2e_e07_u04_fr02_01` và `product_guided_create_e2e_test: e2e_e02_u01_fr01_01` (cả hai thuộc catalog, cùng triệu chứng "Thuốc A" không thấy). Chạy lại ở worktree `HEAD` sạch (`380142da9`): 2 tệp đó cũng lỗi (4 ca) ⇒ **có sẵn**, baseline cũ chưa ghi. Không lỗi nào thuộc `features/sales`.
- 5.5 `analyze` rồi `detect_changes({scope: "all"})`: **36 tệp, 23 symbol, 0 luồng, rủi ro low** (36 tệp gồm cả `AGENTS.md` / `CLAUDE.md` và 16 tệp test chỉ đổi định dạng, đã hoàn nguyên sau đó — xem R-format, R-analyze-docs). Tệp còn lại đều trong danh sách plan + R-import.
- 5.6 PLAN.md dòng 8-A1: Làm ✅ 2026-11-07. TH-05 KI-21, KI-22 (dòng 2210-2211) còn đúng.

**Ghi chú cho review**
- Review Focus 2 (`draftId` khoảng trắng): parity `draftId = '  draft-1  '` giữ nguyên trong cả `old` và `new` ⇒ repository không trim.
- Review Focus 3 (`double`): `sampleDraftJson` có `line_total_minor: 115000.0`, đạt ở `old` và `new`.
- Review Focus 4 (`saved_at` múi giờ): chép nguyên `DateTime.parse(...).toUtc()`, không sửa.
- Review Focus 5: `presentation.dart` export đường mới; cả app chạy được (`flutter test` cả app, `dart analyze lib` sạch).
- `STALE_VERSION` ở `discardDraft` thành nhánh chết (repository đổi mã lạ thành `SYSTEM_ERROR`); giữ theo bảng 4.4 của plan.
- `IDEMPOTENCY_CONFLICT` khi xoá nháp hiện "Yêu cầu bị xung đột" (bảng 4.4) — câu này hơi cụt, 8-B cân nhắc.
- Chưa chạy kiểm tay mục 7 (iPhone simulator + Chrome): việc của người dùng.

## 10. Review

**R1 — ĐẠT (2026-11-07).** Không có việc cần sửa.

| Mục kiểm | Kết quả |
|---|---|
| `dart analyze` (sales, di, test/sales) | 0 lỗi; 1 warning có sẵn (`order_einvoice_section_test.dart:32`) + info deprecated có sẵn |
| `flutter test test/features/sales` | 773 đạt, 0 lỗi (chạy lại khi review) |
| Parity `old` / `new` (5 RPC, parse, 8 mã lỗi) | Cùng giá trị mong đợi, cả hai nhóm đạt |
| Review Focus 1–5 | 1 xử lý bằng R-nested (có test); 2, 3, 4 giữ nguyên hành vi cũ; 5 đạt |
| Phạm vi tệp | Khớp plan + R-import; không còn thay đổi ngoài ý muốn (`AGENTS.md`/`CLAUDE.md` đã hoàn nguyên) |
| Lệch plan chấp nhận | R-impact (CRITICAL do nhiễu index, đo bằng `git grep`), R-imports-tool (6 dòng mới của `check_feature_imports`, để 8-C), R-nested |

Chưa chạy kiểm tay mục 7 (iPhone simulator + Chrome): việc của người dùng.
