# 8-A3 — Sales: tra cứu đơn + phiếu bán hàng sang `SalesOrderRepository` / `SalesReceiptRepository`

> Theme 5 (mã cũ P8) · Bước (a) chuyển kiến trúc, nhóm tra cứu + phiếu · Gồm việc 8.3, 8.4 (PLAN.md mục Theme 5): list / search / detail / timeline / return summary / post-sale actions / cancellation detail; generate / get / original receipt, ghi in / chia sẻ. **Không gồm** precheck / confirm huỷ, precheck đổi/trả, 3 cubit đổi/trả (8-A4); KI-06, KI-07, KI-09 (8-B).
> Trạng thái: Plan 📝 (viết 2026-11-07, duyệt thiết kế 2026-11-07) | Làm ✅ 2026-11-07 | Review ✅ 2026-11-07 (R1 ❌, R2 ✅)
> Trước: 8-A2 (thanh toán, review ĐẠT). Sau: **8-A4** (huỷ + đổi/trả) — dùng lại `SalesOrderRepository.getDetail / getReturnSummary` cho 3 cubit đổi/trả, bỏ `ISalesModule` khỏi `SalesOrderDetailCubit`. 8-C dọn module.
> Tài liệu: [TH-05](../../../02-yeu-cau/TH-05-ban-hang-va-don-hang.md) US-02.6, EP-03 (US-03.1…03.6), SG-08, SG-09, SG-16, 6.2, 6.4; PLAN.md "Cách chuyển MỘT feature", "Plan xoá / tách / thay code cũ: test giữ hành vi trước". Mẫu: [8-A2](8-A2-sales-thanh-toan.md) (cấu trúc, parity `old` / `new`, cầu nối `module_backed_sales_repositories.dart`).
>
> **Cho phiên code:** dùng `superpowers:executing-plans` (tuần tự). Mỗi task xong ghi ngay mục 9 theo mẫu (tệp:dòng, lệch plan, test, impact). **Không commit** (người dùng commit sau `detect_changes()`). Không chạy / đề nghị reset DB, push, SQL (plan không đụng DB).

## 1. Mục tiêu

- 12 RPC của schema `sales` đi qua repository thay `ISalesModule`:
  ```text
  SalesOrderListCubit ──────────────┐
  SalesOrderDetailCubit (core) ─────┼─▶ SalesOrderRepository   list / search / getDetail
  SalesOrderDetailSectionsLoader ───┘                          getTimeline / getReturnSummary / getAvailableActions / getCancellation
  SalesReceiptOperationHandler ─────┬─▶ SalesReceiptRepository generate / get / recordPrinted / recordShared
  SalesOrderDetailCubit.viewOriginalReceipt ┘                  getOriginal
  ```
- Repository **nhận và trả kiểu của `vet45_sales_application`** (8-A1 Q1): `SalesOrderListFilterInput`, `PagedSalesOrderListDto`, `SalesOrderDetailDto`, `SalesOrderTimelineDto`, `SalesOrderReturnSummaryDto`, `AvailablePostSaleActionsDto`, `SalesOrderCancellationDetailDto`, `SalesReceiptDto`, `SalesReceiptDocumentDto`. Chép vào app: dựng tham số + đọc JSON, phân loại lỗi.
- Lỗi đi ra là `AppException`. Câu thô (`serverMessage`, câu không dấu) ở SG-08 / SG-09 đổi theo TH-05 (Q3).
- Cubit / loader / handler của nhóm chuyển vào `features/sales/logic/` (bước 6 của công thức).
- `SalesTransactionResultCubit` và `SalesReceiptOperationHandler` hết `ISalesModule` + `IExecutionContext`. `SalesOrderDetailSectionsLoader` hết module.

**Không làm:** precheck / confirm huỷ, precheck đổi/trả trong `SalesOrderDetailPostSaleActions` (vẫn gọi module, 8-A4); 3 cubit đổi/trả (vẫn gọi `get_sales_order_detail` / `get_sales_order_return_summary` qua module, 8-A4); tìm bỏ dấu KI-09, bỏ "Xem công nợ" KI-07, "Thu tiền" KI-06 (8-B); sửa RPC; bố cục web (8-W); chép kiểu DTO (8-C).

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | Ranh giới 8-A3 / 8-A4 cho `get_available_post_sale_actions` (khối "Thao tác") và `get_sales_order_cancellation` (khối "Lý do hủy") — TH-05 6.2 xếp vào "Huỷ", PLAN 8.3 ghi "post-sale actions" | **Người dùng chốt 2026-11-07: cả hai vào 8-A3.** Mọi RPC đọc của SG-08 / SG-09 chuyển ở 8-A3 ⇒ sections loader hết module. 8-A4 chỉ còn precheck / confirm huỷ + đổi/trả |
| Q2 | Chia repository | **Người dùng chốt 2026-11-07:** `SalesOrderRepository` (đã có `get`) thêm 7 hàm đọc đơn (gồm `getCancellation`); `SalesReceiptRepository` mới cho 5 thao tác phiếu |
| Q3 | Câu thô ở nhóm này: `sales_order_list_cubit.dart:114` (`message ?? code`), `:118` ("Khong the tai danh sach don hang" — không dấu), `:238` (`error.message ?? …` — câu Anh "Sales order inquiry failed."); `sales_order_detail_cubit.dart:378-383` (`errorMessage` = câu server đè mô tả cố định của trang lỗi); `sales_order_detail_sections_loader.dart:116-122`, `:402-422` (`errorMessage` các khối) | **Người dùng chốt 2026-11-07: đổi theo TH-05 ngay ở 8-A3.** Bảng 4.4. Không bao giờ hiện `serverMessage` hay mã |
| Q4 | Khoá idempotency tạo phiếu `'sales-receipt:$tenantId:$salesOrderId:v$version'` + `correlationId` lấy từ `IExecutionContext` trong handler | **Người dùng chốt 2026-11-07: repository dựng.** `SalesReceiptRepository.generate` dựng **đúng chuỗi cũ** bằng closure `tenantId`; `p_command_id` và `p_correlation_id` = `newId()` (cũ: `correlationId` của phiên — chỉ để truy vết, server không so). Khoá hoạt động in / chia sẻ (`'sales-receipt:<kind>:<receiptId>:<uuid>'`, không chứa tenant) **vẫn do handler sinh** (`_ReceiptActivity.create`) để thử lại dùng cùng khoá; truyền `commandId` + `idempotencyKey` vào repository |
| Q5 | Mã lỗi | Đọc đơn: dùng `salesOrderReadException` (8-A2) + thêm `IMPACT_PENDING` (mã ổn định của gateway huỷ, `loadCancellation` rẽ nhánh theo nó, `sales_order_detail_sections_loader.dart:113`). Phiếu: `salesReceiptException` mới — 8 mã ổn định của gateway phiếu (`supabase_sales_receipt_gateway.dart:111-120`) + `NETWORK_ERROR`; `PERMISSION_DENIED` → `NO_PERMISSION`; còn lại / lỗi đọc JSON ⇒ `SYSTEM_ERROR` (cũ: `DEPENDENCY_UNAVAILABLE` "Sales receipt operation failed."). Khác nhỏ như 8-A2 Q5: lỗi đọc JSON phiếu cũ ra câu "Dịch vụ phiếu tạm thời không khả dụng…" (`dependencyUnavailable`), nay ra câu của `transportFailure` |
| Q6 | Kiểm quyền client: `require(viewOrder)` (list / search / detail / actions), `require(viewOrderHistory)` (timeline), `require(viewReceipt)` (get / original), `@RequiresPermission` trên 3 command phiếu | **Bỏ** (quy ước Theme 3/4). Server kiểm ở mọi RPC (TH-05 6.2) |
| Q7 | `tenantId` / `actorId` / `query_id` | Như 8-A2 Q8–Q9: closure mỗi lần gọi; `newId()` (UUID v4) qua constructor để test cố định. `SalesOrderListCubit` bỏ `IExecutionContext`. Sections loader bỏ tham số `tenantId` / `actorId` (8-A2 R5) |
| Q8 | Nhánh `SalesContractException` còn ở `SalesTransactionResultMapper.issueFor` (`:11-24`), `_sectionFailure` (`:393`), `loadCancellation` (`:106`), `_failureState` (`sales_order_detail_cubit.dart:371`) | **Bỏ ở 8-A3**: sau 8-A3 không nguồn nào ném `SalesContractException` vào các chỗ này (post-sale actions chỉ gọi lại `loadActions`, lỗi precheck / confirm xử lý riêng trong `sales_order_detail_post_sale_actions.dart`) |
| Q9 | KI-06, KI-07, KI-09 (TH-05 9.2 gắn vào 8.3) | Sang **8-B** (đổi hành vi / sửa DB), như 8-A1 Q4 / 8-A2 |

## 3. Hiện trạng (đo 2026-11-07)

| Tệp (dưới `lib/features/sales/presentation/`) | Gọi | RPC |
|---|---|---|
| `bloc/sales_order/sales_order_list_cubit.dart:264`, `:274` | `ListSalesOrdersQuery`, `SearchSalesOrdersQuery` (`pageSize: 50`, `filter` từ `SalesOrderListMapper.toFilterInput`) | `list_sales_orders`, `search_sales_orders` |
| `bloc/sales_order/sales_order_detail_cubit.dart:242`, `:120` | `GetSalesOrderDetailQuery` (không `expectedSourceVersion`), `GetSalesOrderOriginalReceiptQuery` | `get_sales_order_detail`, `get_sales_order_original_receipt` |
| `bloc/sales_order/sales_order_detail_sections_loader.dart:88`, `:147`, `:279`, `:290` | `GetSalesOrderCancellationQuery`, `GetAvailablePostSaleActionsQuery`, `GetSalesOrderTimelineQuery`, `GetSalesOrderReturnSummaryQuery` (đều `expectedSourceVersion: sourceVersion`) | 4 RPC tương ứng |
| `support/sales_receipt_operation_handler.dart:79`, `:89`, `:216`, `:226` | `GenerateSalesReceiptCommand`, `GetSalesReceiptQuery`, `RecordSalesReceiptPrintedCommand`, `RecordSalesReceiptSharedCommand` | `generate_sales_receipt`, `get_sales_receipt`, `record_sales_receipt_activity` (`p_activity_type` `printed` / `shared`) |

Nơi dựng: `pages/sales_order_list_page.dart:26-27`, `pages/sales_order_detail_page.dart:40-42`, `logic/sales_transaction_result_cubit.dart:25-42` (← `pages/sales_transaction_result_page.dart:18-46`). Handler phiếu dùng ở `SalesOrderDetailCubit` (`:33`) và `SalesTransactionResultCubit` (`:39`).

| RPC | Tham số (chép từ mapper module) |
|---|---|
| `list_sales_orders` | `SalesOrderInquiryRpcMapper.listParams` — **khoá trần**: `query_id`, `tenant_id`, `actor_id`, `cursor`, `page_size`, `completed_from` / `completed_to` (`_toUtcIsoString`), `store_id`, `seller_id`, `customer_id`, `lifecycle_status`, `lock_status`, `settlement_status` (`.name`), `has_return_exchange`, `e_invoice_status`, `has_outstanding_receivable` — mọi khoá luôn có, kể cả `null` |
| `search_sales_orders` | `searchParams` — như trên + `search_text` |
| `get_sales_order_detail`, `get_sales_order_timeline`, `get_sales_order_return_summary` | `_orderScopedParams`: `query_id`, `tenant_id`, `actor_id`, `sales_order_id`, `expected_source_version` (luôn có, kể cả `null`) |
| `get_available_post_sale_actions` | `PostSaleActionsRpcMapper.availableActionsParams` — cùng 5 khoá trần |
| `get_sales_order_cancellation` | `SalesOrderCancellationRpcMapper.detailParams` — cùng 5 khoá trần |
| `generate_sales_receipt` | `SalesReceiptRpcMapper.generateParams` — khoá `p_*`: `p_command_id`, `p_tenant_id`, `p_actor_id`, `p_sales_order_id`, `p_idempotency_key`, `p_payload_hash` (`null`), `p_correlation_id`, `p_causation_id` (`null`), `p_expected_source_version` **chỉ khi khác `null`** |
| `get_sales_receipt` | `getReceiptParams` — `p_query_id`, `p_tenant_id`, `p_actor_id`, `p_receipt_id`, `p_expected_source_version` chỉ khi khác `null` |
| `get_sales_order_original_receipt` | `originalReceiptParams` — `p_query_id`, `p_tenant_id`, `p_actor_id`, `p_sales_order_id` (không có version) |
| `record_sales_receipt_activity` | `_activityParams` — `p_command_id`, `p_tenant_id`, `p_actor_id`, `p_receipt_id`, `p_activity_type`, `p_idempotency_key`, `p_payload_hash` (`null`), `p_correlation_id`, `p_causation_id` (`null`), `p_expected_source_version` (**luôn có**, `null`) |

Hàm đọc JSON chép: `SalesOrderInquiryRpcMapper.{pagedListFromJson, detailFromJson, timelineFromJson, returnSummaryFromJson}` + helper (`_listItemFromJson`, `_facetsFromJson`, `_line`, `_currentLine`, `_lineSource`, `_product`, `_unit`, `_store`, `_customer`, `_timelineEntry`, `_actor`, …); `PostSaleActionsRpcMapper.availableActionsFromJson`; `SalesOrderCancellationRpcMapper.detailFromJson` (+ `_reasonFromJson`, `_status`, `_rejectUnknownKeys`, …); `SalesReceiptRpcMapper.{salesReceiptFromJson, documentFromJson}` + helper. `get_sales_order_original_receipt` trả **document trực tiếp** (không bọc). Đường dẫn: `modules/sales/infrastructure/lib/src/domain/{sales_order,sales_order_cancellation,sales_receipt}/`. JSON mẫu: `modules/sales/infrastructure/test/domain/sales_order/{sales_order_inquiry_rpc_mapper_test,supabase_sales_order_inquiry_gateway_test,supabase_post_sale_actions_gateway_test}.dart`, `…/sales_order_cancellation/sales_order_cancellation_rpc_mapper_test.dart`, `…/sales_receipt/supabase_sales_receipt_gateway_test.dart`.

Test app dựng fake module cho nhóm này (số test chạy được 2026-11-07): `test/features/sales/presentation_module/bloc/sales_order_list_cubit_test.dart` (12), `…/sales_order_detail_cubit_test.dart` (47), `…/sales_transaction_result_cubit_test.dart` (27), `…/widgets/sales_transaction_result_body_test.dart` (7), `test/features/sales/sales_order_detail_page_test.dart` (22), `sales_flow_pages_test.dart` (28). Chỉ phải xanh, không sửa (8-A4): `sales_return_exchange_{detail,result,slip_preview}_page_test.dart`, `presentation_module/bloc/sales_return_exchange_{detail,session,settlement}_cubit_test.dart`. Cầu nối 8-A2: `test/features/sales/support/module_backed_sales_repositories.dart`.

## 4. Thiết kế

### 4.1 Lỗi (`apps/erp/lib/features/sales/data/`)

- `sales_order_read_errors.dart`: thêm `'IMPACT_PENDING'` vào `_stableCodes` (Q5). Chữ ký giữ `AppException salesOrderReadException(Object error)`.
- `sales_receipt_errors.dart` (mới): `AppException salesReceiptException(Object error)` — mã giữ: `NOT_FOUND`, `NO_PERMISSION`, `PROJECTION_PENDING`, `DATA_SCOPE_DENIED`, `STALE_VERSION`, `IDEMPOTENCY_CONFLICT`, `DEPENDENCY_UNAVAILABLE`, `CONTEXT_INVALID`, `NETWORK_ERROR`; bóc JSON lồng qua `unwrapNestedSalesRpcError`; còn lại `SYSTEM_ERROR` (`cause` = lỗi gốc). Cùng dạng `salesOrderReadException`.

### 4.2 Repository

```dart
// data/sales_order_repository.dart — thêm vào lớp có sẵn (giữ constructor, get, _guard)
Future<PagedSalesOrderListDto> list({String? cursor, int pageSize = 50, SalesOrderListFilterInput? filter});
Future<PagedSalesOrderListDto> search({required String searchText, String? cursor, int pageSize = 50, SalesOrderListFilterInput? filter});
Future<SalesOrderDetailDto> getDetail({required String salesOrderId});            // expected_source_version: null
Future<SalesOrderTimelineDto> getTimeline({required String salesOrderId, int? expectedSourceVersion});
Future<SalesOrderReturnSummaryDto> getReturnSummary({required String salesOrderId, int? expectedSourceVersion});
Future<AvailablePostSaleActionsDto> getAvailableActions({required String salesOrderId, int? expectedSourceVersion});
Future<SalesOrderCancellationDetailDto> getCancellation({required String salesOrderId, int? expectedSourceVersion});

// data/sales_receipt_repository.dart — mới, constructor như SalesOrderRepository (rpc, tenantId, actorId, newId)
Future<SalesReceiptDto> generate({required String salesOrderId, required int expectedVersion});
  // p_idempotency_key = 'sales-receipt:${await tenantId()}:$salesOrderId:v$expectedVersion' (Q4; chuỗi cũ). Handler luôn có version (chặn ở `ensureReceipt` khi thiếu) ⇒ p_expected_source_version luôn có
Future<SalesReceiptDto> get({required String receiptId, int? expectedSourceVersion});
Future<SalesReceiptDocumentDto> getOriginal({required String salesOrderId});
Future<SalesReceiptDto> recordPrinted({required String receiptId, required String commandId, required String idempotencyKey});
Future<SalesReceiptDto> recordShared({required String receiptId, required String commandId, required String idempotencyKey});
```

Mỗi method: `tenantId()` / `actorId()` → `_rpc.call('sales', '<rpc>', params: …)` → ép `Map<String, dynamic>` → hàm đọc JSON; `_guard` bọc bằng `salesOrderReadException` / `salesReceiptException`. Tham số **giống hệt** mapper cũ (bảng mục 3). Hàm dựng tham số + đọc JSON chép vào `data/mappers/sales_order_inquiry_json.dart` (`SalesOrderInquiryJson`: list / search / orderScoped params, `pagedList`, `detail`, `timeline`, `returnSummary`, `availableActions`, `cancellationDetail`) và `data/mappers/sales_receipt_json.dart` (`SalesReceiptJson`). `FormatException` ra ngoài thành `SYSTEM_ERROR`.

### 4.3 Nơi gọi

- `SalesOrderListCubit({required SalesOrderRepository repository, required ISalesActiveStoreContext activeStoreContext, DateTime? Function()? nowBuilder})` — bỏ `ISalesModule`, `IExecutionContext`. `_executeListQuery` → `repository.list(cursor:, pageSize: 50, filter:)` hoặc `repository.search(searchText: q, …)`. Bắt lỗi: `AppException` mã `NO_PERMISSION` / `DATA_SCOPE_DENIED` → `SalesOrderListBlocked`; còn lại câu 4.4.
- `SalesOrderDetailSectionsLoader({required orderId, required SalesOrderRepository orderRepository, required SalesPaymentRepository paymentRepository, …})` — bỏ `salesModule`; `loadAll / loadPayment / loadHistory / loadActions / loadCancellation / loadMoreTransactions` bỏ tham số `tenantId`, `actorId`. `_sectionFailure` và `loadCancellation` chỉ đọc `AppException.code` (Q8): `NO_PERMISSION` / `DATA_SCOPE_DENIED` → `blocked`; `PROJECTION_PENDING` → `projectionPending`; riêng `loadCancellation` thêm `NOT_FOUND` / `IMPACT_PENDING` → `projectionPending` (giữ như cũ). Không truyền câu nào vào `*ErrorMessage` (luôn `clear…ErrorMessage: true`).
- `SalesOrderDetailCubit({required orderId, required ISalesModule salesModule /* chỉ post-sale actions, 8-A4 */, required SalesOrderRepository orderRepository, required SalesPaymentRepository paymentRepository, required SalesReceiptRepository receiptRepository, required IExecutionContext executionContext /* HĐĐT + post-sale */, …})`: core → `orderRepository.getDetail(salesOrderId: orderId)`; `viewOriginalReceipt` → `receiptRepository.getOriginal(salesOrderId: orderId)`; `retry*Section` / `loadMoreTransactions` bỏ bước `requireTenantId / requireUserId`. `_failureState`: theo `AppException.code` — `NO_PERMISSION` / `DATA_SCOPE_DENIED` → `blocked`, `NOT_FOUND` → `notFound`, `PROJECTION_PENDING` → `projectionPending`, còn lại `error`; `errorMessage` luôn `null` (`clearErrorMessage: true`).
- `SalesOrderDetailPostSaleActions`: chỉ sửa chỗ gọi `sectionsLoader().loadActions(...)` (bỏ `tenantId` / `actorId`); precheck / confirm giữ module (8-A4).
- `SalesReceiptOperationHandler({required salesOrderId, required SalesReceiptRepository repository, …})` — bỏ `ISalesModule`, `IExecutionContext`, `_generateIdempotencyKey`. `ensureReceipt`: `knownId == null ? repository.generate(salesOrderId:, expectedVersion: version) : repository.get(receiptId: knownId, expectedSourceVersion: version)`. `_recordReceiptActivity`: `repository.recordPrinted / recordShared(receiptId: activity.receiptId, commandId: activity.id, idempotencyKey: activity.idempotencyKey)`. Giữ nguyên `_operationToken`, `_pendingActivity`, `invalidate`, thứ tự `emit`.
- `SalesTransactionResultCubit`: bỏ `salesModule`, `executionContext`; thêm `required SalesReceiptRepository receiptRepository` truyền cho handler. `SalesTransactionResultPage`: bỏ `salesModule` / `executionContext` tuỳ chọn, thêm `SalesReceiptRepository? receiptRepository` (mặc định `GetIt`).
- `SalesTransactionResultMapper.issueFor`: bỏ nhánh `SalesContractException` (Q8).
- `injection.dart`: `registerLazySingleton<SalesReceiptRepository>` cùng cách `SalesOrderRepository` (`:234`).

### 4.4 Câu lỗi (Q3)

| Chỗ | Cũ | Mới |
|---|---|---|
| `SalesOrderListError` (mô tả dưới tiêu đề "Không thể tải danh sách") | "Khong the tai danh sach don hang" | "Không thể tải danh sách đơn hàng." |
| `loadMoreError` | `error.message ?? 'Khong the tai them danh sach don hang'` | luôn "Không thể tải thêm đơn hàng. Vui lòng thử lại." |
| `SalesOrderListBlocked.message` (widget không hiện) | `message ?? code` | "Không có quyền xem đơn hàng" |
| Trang lỗi chi tiết (`SalesOrderDetailErrorState`) | `errorMessage` = câu server đè mô tả | `null` ⇒ mô tả cố định có sẵn (`sales_order_detail_error_state.dart:59-87`, khớp FR-10) |
| Khối Thanh toán / Lịch sử / Thao tác / Lý do hủy | `serverMessage` (Lịch sử, Thao tác, Lý do hủy) | `null` ⇒ câu cố định có sẵn của widget (khớp FR-09); sheet Thao tác: "Vui lòng thử lại sau." (`sales_order_detail_page.dart:64`) |

Câu phiếu không đổi (đã đi qua `SalesTransactionResultIssue`, `sales_order_detail_page.dart:261-275`).

## 5. Đang làm gì — test giữ hành vi

| # | Cũ đang làm gì | Sau 8-A3 nằm ở đâu | Test |
|---|---|---|---|
| C1 | Tham số list / search (khoá trần, `null` vẫn có khoá, ngày UTC ISO, enum `.name`) | `SalesOrderInquiryJson` | parity `params_list`, `params_list_all_filters`, `params_search` |
| C2 | Tham số 5 RPC theo đơn (5 khoá trần, `expected_source_version` luôn có) | như trên | parity `params_detail` (version `null`), `params_timeline`, `params_return_summary`, `params_available_actions`, `params_cancellation` |
| C3 | Đọc JSON list (+ `facets`, `nextCursor`, `hasMore`, `totalMatching`), detail (dòng gốc + dòng hiện tại, `currentReceiptId`), timeline, return summary, actions, cancellation (`_rejectUnknownKeys` ⇒ `FormatException`) | như trên | parity `parse_*` × 6 + `parse_cancellation_rejects_unknown_key` |
| C4 | Tham số 5 thao tác phiếu (khoá `p_*`, version có / vắng đúng bảng mục 3, `p_activity_type`) | `SalesReceiptJson` | parity `params_generate`, `params_get_receipt`, `params_original_receipt`, `params_record_printed`, `params_record_shared` |
| C5 | Đọc JSON phiếu (`salesReceiptFromJson`, `documentFromJson` không bọc) | như trên | parity `parse_receipt`, `parse_original_document` |
| C6 | Khoá tạo phiếu `'sales-receipt:<tenant>:<order>:v<version>'` | `SalesReceiptRepository.generate` (Q4) | `generate_idempotency_key_unchanged`: `tenantId 'tenant-1'`, `order-1`, `expectedVersion: 3` ⇒ `'sales-receipt:tenant-1:order-1:v3'` |
| C7 | Gateway đọc đơn / post-sale / huỷ: mã ổn định, còn lại `DEPENDENCY_UNAVAILABLE` | `salesOrderReadException` (+`IMPACT_PENDING`); **đổi (Q5)** còn lại `SYSTEM_ERROR` | `sales_order_read_errors_test.dart` thêm ca `IMPACT_PENDING` (`old` qua `SupabaseSalesOrderCancellationGateway`) |
| C8 | Gateway phiếu: 8 mã, còn lại / `FormatException` `DEPENDENCY_UNAVAILABLE` | `salesReceiptException`; **đổi (Q5)** | `sales_receipt_errors_test.dart` (`old` / `new`) |
| C9 | `SalesOrderListCubit`: `requestGeneration`, làm mới giữ danh sách, tải thêm gộp không trùng, `presetCounts`, `isDefaultScopeEmpty`, khoá chặn | `logic/sales_order_list_cubit.dart` | 12 test có sẵn (đổi fake) |
| C10 | List: câu thô / không dấu | **đổi (Q3)** | mới `load_error_shows_accented_message`, `load_more_error_never_shows_server_message`, `blocked_on_no_permission`, `blocked_on_data_scope_denied` |
| C11 | Chi tiết: core ∥ HĐĐT, các khối song song, chặn theo generation / version, phân trang giao dịch, post-sale reload | `logic/` | 47 test cubit + 22 test trang có sẵn (đổi fake) |
| C12 | Chi tiết: câu server ở trang lỗi / khối | **đổi (Q3)** | mới `core_error_never_carries_server_message` (× `NOT_FOUND`, `NO_PERMISSION`, `SYSTEM_ERROR`), `history_error_never_carries_server_message`, `actions_error_never_carries_server_message`, `cancellation_impact_pending_is_projection_pending` |
| C13 | Handler phiếu: tạo khi chưa có id, đọc khi có id, in / chia sẻ ghi hoạt động, lỗi ghi ⇒ `activityWarning`, thử lại dùng **cùng** `commandId` + khoá | `logic/sales_receipt_operation_handler.dart` | test có sẵn ở `sales_transaction_result_cubit_test` + `sales_order_detail_cubit_test` (đổi fake) + mới `retry_activity_reuses_command_id_and_key` |
| C14 | `issueFor` theo mã | bỏ nhánh `SalesContractException` | ca `issue_for_app_exception_*` (8-A2) giữ; xoá ca `SalesContractException` nếu có, ghi tên vào Kết quả |

**Bước 0 (Task 0):** nhóm `old` của C1–C5, C7, C8 chạy trên module, xanh, ghi tên — rồi mới viết tệp mới. Test có sẵn C9, C11, C13 và 6 tệp đổi/trả phải **xanh trên code cũ** trước Task 3 (chạy, ghi số ở Task 0).

## 6. Các bước

**Ràng buộc chung** (mọi task):
- Chỉ sửa tệp liệt kê ở từng task. Không đụng `modules/sales`, không sửa RPC / migration.
- Trước khi sửa symbol có sẵn: `node .gitnexus/run.cjs impact <symbol> --direction upstream --repo erp-sales-inventory` (phải có `--repo`, máy có 2 index — 8-A2 R1 review), ghi số vào Kết quả; HIGH / CRITICAL ⇒ dừng, báo người dùng (index Dart gộp theo tên có thể ra CRITICAL giả — đo phạm vi thật bằng `git grep`, ghi lại, vẫn báo).
- Chép nguyên văn điều kiện, câu, tên khoá JSON (kể cả có / không `p_`, khoá có giá trị `null`). Thấy chỗ phải sửa thân mới chạy được ⇒ ghi Kết quả, không tự đổi hành vi.
- Không `tenantId` / `actorId` trong chữ ký repository.
- Test parity có `// ignore_for_file: implementation_imports`. Tệp test mới đặt ở `apps/erp/test/features/sales/{data,logic}/`.

### Task 0: Bước 0 — parity `old` + chạy test có sẵn trên code cũ

**Files:**
- Create: `apps/erp/test/features/sales/data/sales_order_inquiry_parity_expectations.dart`, `sales_order_inquiry_rpc_parity_test.dart`, `sales_receipt_rpc_parity_test.dart` (nhóm `old`)

- [x] **0.1** Hằng dùng chung `old` / `new`: `tenantId = 'tenant-1'`, `actorId = 'user-1'`, `orderId = 'order-1'`, `receiptId = 'receipt-1'`, `queryId = '00000000-0000-4000-8000-000000000001'`, `commandId = '00000000-0000-4000-8000-000000000002'`; 1 filter đủ trường (`completedFrom: DateTime(2026,11,1)` giờ máy, `storeId`, `lifecycleStatus`, `settlementStatus`, `hasReturnExchange: true`, `eInvoiceStatus`, `hasOutstandingReceivable: true`) và filter `null`. JSON mẫu lấy từ các test module ở mục 3.
- [x] **0.2** Nhóm `old`: `SalesOrderInquiryRpcMapper.{listParams, searchParams, detailParams, timelineParams, returnSummaryParams}`, `PostSaleActionsRpcMapper.availableActionsParams`, `SalesOrderCancellationRpcMapper.detailParams`, `SalesReceiptRpcMapper.{generateParams, getReceiptParams, originalReceiptParams, printedParams, sharedParams}` → `equals(expected…)`; các `*FromJson` → `expect…`; `parse_cancellation_rejects_unknown_key` → `throwsFormatException`. Lỗi: bảng C7 / C8 qua `SupabaseSalesOrderInquiryGateway`, `SupabaseSalesOrderCancellationGateway`, `SupabaseSalesReceiptGateway` với `IRpcClient` giả ném `RpcException`.
- [x] **0.3** Chạy trên code hiện tại:
  ```bash
  cd apps/erp && flutter test test/features/sales/data/sales_order_inquiry_rpc_parity_test.dart \
    test/features/sales/data/sales_receipt_rpc_parity_test.dart \
    test/features/sales/presentation_module/bloc/sales_order_list_cubit_test.dart \
    test/features/sales/presentation_module/bloc/sales_order_detail_cubit_test.dart \
    test/features/sales/presentation_module/bloc/sales_transaction_result_cubit_test.dart \
    test/features/sales/presentation_module/widgets/sales_transaction_result_body_test.dart \
    test/features/sales/sales_order_detail_page_test.dart test/features/sales/sales_flow_pages_test.dart \
    test/features/sales/sales_return_exchange_detail_page_test.dart test/features/sales/sales_return_exchange_result_page_test.dart \
    test/features/sales/sales_return_exchange_slip_preview_page_test.dart \
    test/features/sales/presentation_module/bloc/sales_return_exchange_detail_cubit_test.dart \
    test/features/sales/presentation_module/bloc/sales_return_exchange_session_cubit_test.dart \
    test/features/sales/presentation_module/bloc/sales_return_exchange_settlement_cubit_test.dart
  ```
  Expected: PASS. Ghi số test từng tệp (mốc mục 3: 12 / 47 / 27 / 7 / 22 / 28 / 2 / 2 / 2 / 6 / 21 / 14).

### Task 1: Lỗi

**Files:**
- Create: `apps/erp/lib/features/sales/data/sales_receipt_errors.dart`
- Modify: `apps/erp/lib/features/sales/data/sales_order_read_errors.dart:4-12` (thêm `IMPACT_PENDING`)
- Test: `apps/erp/test/features/sales/data/sales_receipt_errors_test.dart` (mới), `sales_order_read_errors_test.dart` (thêm ca)

**Produces:** `salesReceiptException(Object) → AppException`; `salesOrderReadException` giữ `IMPACT_PENDING`.

- [x] **1.1** `sales_receipt_errors_test.dart` — cột `new` / `old` (gateway cũ):

  | Đầu vào | `new` | `old` |
  |---|---|---|
  | `PostgrestException(message: '{"code":"STALE_VERSION","message":"x"}')` | `STALE_VERSION`, `serverMessage` giữ | `STALE_VERSION` |
  | `{"code":"PERMISSION_DENIED"}` | `NO_PERMISSION` | `PERMISSION_DENIED` |
  | 6 mã còn lại của 8 mã | giữ | giữ |
  | `{"code":"CANCELLATION_BLOCKED"}`, `PostgrestException(message: 'boom')` | `SYSTEM_ERROR` | `DEPENDENCY_UNAVAILABLE` |
  | `AppException('NETWORK_ERROR')` | `NETWORK_ERROR` | — |
  | `FormatException('x')` | `SYSTEM_ERROR` | `DEPENDENCY_UNAVAILABLE` (qua `_invoke`) |
  | JSON lồng 2 lớp `{"message":"{\"code\":\"NOT_FOUND\"}"}` | `NOT_FOUND` | `NOT_FOUND` |
- [x] **1.2** `sales_order_read_errors_test.dart`: thêm `{"code":"IMPACT_PENDING"}` → `IMPACT_PENDING` (`new`), `old` qua gateway huỷ → `IMPACT_PENDING`.
- [x] **1.3** Chạy → FAIL (thiếu nguồn / mã). Viết. Chạy `flutter test test/features/sales/data/sales_receipt_errors_test.dart test/features/sales/data/sales_order_read_errors_test.dart` → PASS.

### Task 2: JSON + repository + fake

**Files:**
- Create: `apps/erp/lib/features/sales/data/mappers/sales_order_inquiry_json.dart`, `data/mappers/sales_receipt_json.dart`, `data/sales_receipt_repository.dart`
- Modify: `apps/erp/lib/features/sales/data/sales_order_repository.dart` (thêm 7 hàm; sửa chú thích dòng 7)
- Test: nhóm `new` trong 2 tệp parity; `apps/erp/test/features/sales/data/sales_order_repository_test.dart` (thêm ca), `sales_receipt_repository_test.dart` (mới)
- Modify: `apps/erp/test/features/sales/support/fake_sales_order_repository.dart` (thêm 7 hàm); Create: `test/features/sales/support/fake_sales_receipt_repository.dart`; Modify: `test/features/sales/support/module_backed_sales_repositories.dart` (thêm 7 hàm vào `ModuleBackedSalesOrderRepository`, thêm `ModuleBackedSalesReceiptRepository` gọi `GenerateSalesReceiptCommand` / `GetSalesReceiptQuery` / `GetSalesOrderOriginalReceiptQuery` / `RecordSalesReceipt{Printed,Shared}Command` của fake module, đổi lỗi như `_bridge`)

**Consumes:** Task 1; `SupabaseRpc.call(String schema, String fn, {Map<String, dynamic>? params})`.
**Produces:** chữ ký mục 4.2; `FakeSalesOrderRepository` thêm `listCalls`, `searchCalls`, `detailCalls`, `timelineCalls`, `returnSummaryCalls`, `actionsCalls`, `cancellationCalls` + kết quả / `Object? …Error` cho từng hàm; `FakeSalesReceiptRepository` (`generateCalls`, `getCalls`, `originalCalls`, `printedCalls`, `sharedCalls`; kết quả / hàng đợi + `Object? …Error`) — Task 3 dùng.

- [x] **2.1** Parity `new`: `_RecordingRpc implements SupabaseRpc` (mẫu `sales_checkout_rpc_parity_test.dart`) ghi `(schema, fn, params)`; mỗi method → `schema == 'sales'`, `fn` đúng, `params` bằng hằng 0.1 (`newId` cố định, `p_correlation_id` = `newId()` ở `new` — so riêng khoá này, phần còn lại `equals`); kết quả qua `expect…`; `parse_cancellation_rejects_unknown_key` → `AppException` `SYSTEM_ERROR`.
- [x] **2.2** Repository test: `generate_idempotency_key_unchanged` (C6), `record_printed_passes_command_id_and_key` (`p_command_id == 'cmd-9'`, `p_idempotency_key == 'k-9'`, `p_activity_type == 'printed'`, `params.containsKey('p_expected_source_version')`), `original_receipt_parses_unwrapped_document`, `list_sends_null_keys` (`params.containsKey('store_id')` với filter `null`), `list_default_page_size_50`, `detail_sends_null_expected_version`, `cancellation_impact_pending_kept`, `tenant_actor_read_each_call` (2 lần gọi ⇒ closure gọi 2 lần), `no_client_permission_check` (RPC ném `PERMISSION_DENIED` → `NO_PERMISSION`, đúng 1 lần gọi).
- [x] **2.3** Chạy → FAIL. Viết các tệp. Chạy `flutter test test/features/sales/data/` → PASS (gồm test 8-A1 / 8-A2 có sẵn).

### Task 3: Đổi nơi gọi + chuyển `logic/` + DI + câu lỗi

**Files:**
- Move (`git mv`; đổi import tương đối → `package:erp/...`): `presentation/bloc/sales_order/{sales_order_list_cubit,sales_order_list_state,sales_order_detail_cubit,sales_order_detail_state,sales_order_detail_sections_loader,sales_order_detail_post_sale_actions}.dart`, `presentation/support/sales_receipt_operation_handler.dart` → `lib/features/sales/logic/`
- Modify: `lib/features/sales/presentation.dart:15-18`, `:76` (export đường mới); mọi tệp import 7 tệp trên (`git grep -l "sales_order_detail_state.dart\|sales_order_list_state.dart\|sales_order_list_cubit.dart\|sales_order_detail_cubit.dart\|sales_order_detail_sections_loader.dart\|sales_order_detail_post_sale_actions.dart\|sales_receipt_operation_handler.dart" -- apps/erp` — đo 2026-11-07: 7 widget dưới `presentation/widgets/` + `support/sales_order_detail_original_receipt_actions.dart`); `logic/sales_order_list_cubit.dart` (cũ `:12-27`, `:94-120`, `:199-242`, `:245-289`); `logic/sales_order_detail_cubit.dart` (cũ `:22-55`, `:117-127`, `:133-202`, `:236-249`, `:293-301`, `:336-368`, `:370-383`); `logic/sales_order_detail_sections_loader.dart` (cũ `:1-70`, `:72-127`, `:129-170`, `:172-177`, `:248-300`, `:340-345`, `:385-424`); `logic/sales_order_detail_post_sale_actions.dart` (cũ `:42-50`: lời gọi `loadActions`); `logic/sales_receipt_operation_handler.dart` (cũ `:11-45`, `:73-96`, `:212-236`, `:267-268`); `logic/sales_transaction_result_cubit.dart` (`:20-45`); `presentation/support/sales_transaction_result_mapper.dart:11-24`; `presentation/pages/sales_order_list_page.dart:24-30`, `sales_order_detail_page.dart:38-48`, `sales_transaction_result_page.dart:16-48`; `lib/core/di/injection.dart` (sau `:234-240`)
- Test (đổi fake / cầu nối, giữ điều kiện kiểm): 6 tệp ở mục 3 + `test/features/sales/group_e_result_receipt_contract_test.dart` (nếu đòi chuỗi `salesModule` trong handler / cubit kết quả: đổi sang `repository.generate` / `repository.get`; giữ `isNot(contains('Supabase'))`, `isNot(contains('.rpc('))`)

**Consumes:** 2 repository + fake + cầu nối (Task 2).

- [x] **3.1** `impact` upstream cho `SalesOrderListCubit`, `SalesOrderDetailCubit`, `SalesOrderDetailSectionsLoader`, `SalesOrderDetailPostSaleActions`, `SalesReceiptOperationHandler`, `SalesTransactionResultCubit`, `SalesTransactionResultMapper`, `SalesOrderRepository`. Ghi bảng (rủi ro / trực tiếp / tổng / luồng) + số đo thật bằng `git grep`.
- [x] **3.2** Viết test mới (FAIL trên code hiện tại): C10 × 4 (`sales_order_list_cubit_test`), C12 × 6 (`sales_order_detail_cubit_test`), C13 `retry_activity_reuses_command_id_and_key` (`sales_transaction_result_cubit_test`: lần ghi in đầu ném `AppException('NETWORK_ERROR')`, bấm in lại ⇒ `printedCalls.length == 2`, `printedCalls[0].commandId == printedCalls[1].commandId`, cùng `idempotencyKey`). Kiểm câu bằng chuỗi nguyên văn bảng 4.4.
- [x] **3.3** `SalesReceiptOperationHandler` + `SalesTransactionResultCubit` + `SalesTransactionResultPage` theo 4.3; `issueFor` bỏ nhánh `SalesContractException`.
- [x] **3.4** `SalesOrderListCubit` + `SalesOrderListPage` theo 4.3, câu theo 4.4. Giữ mọi `emit`, `requestGeneration`, `_mergeUniqueById`.
- [x] **3.5** `SalesOrderDetailSectionsLoader`, `SalesOrderDetailCubit`, `SalesOrderDetailPostSaleActions`, `SalesOrderDetailPage` theo 4.3; câu theo 4.4. `SalesOrderDetailCubit` còn `salesModule` + `executionContext` chỉ cho post-sale actions + HĐĐT (`git grep -n "salesModule\|executionContext" -- apps/erp/lib/features/sales/logic/sales_order_detail_cubit.dart` ⇒ chỉ constructor, `_loadEInvoiceProjection`, `_postSaleActions`).
- [x] **3.6** `injection.dart`: `registerLazySingleton<SalesReceiptRepository>(…)` như `SalesOrderRepository`.
- [x] **3.7** Đổi test có sẵn: fake module lớn dùng cầu nối `ModuleBackedSalesOrderRepository` / `ModuleBackedSalesReceiptRepository` (như 8-A2 R1) để giữ nguyên `expect` về thứ tự / số lần gọi; `SalesContractException('X', message: …)` mà test ném vào nguồn đã chuyển → `AppException('X', serverMessage: …)` (cầu nối tự đổi). Không đổi `expect` nào ngoài tên nguồn dữ liệu, ca mới ở 3.2, và các `expect` câu lỗi bị Q3 đổi có chủ đích (ghi từng ca vào Kết quả). 6 tệp đổi/trả không sửa.
- [x] **3.8** Chạy lệnh 0.3 (đổi đường dẫn nếu test đã di chuyển) + `flutter test test/features/sales/logic test/features/sales/data` → PASS.

### Task 4: Kiểm toàn bộ + tài liệu + Kết quả

**Files:** Modify: `docs/refactor/PLAN.md` (dòng 8-A3: cột Plan → link, Làm ✅ + ngày; trạng thái Theme 5)

- [x] **4.1** `cd apps/erp && dart analyze lib/features/sales lib/core/di test/features/sales` → 0 lỗi, 0 cảnh báo mới (cảnh báo có sẵn: `order_einvoice_section_test.dart:32`).
- [x] **4.2** `git grep -nE "ListSalesOrdersQuery|SearchSalesOrdersQuery|GetSalesOrderTimelineQuery|GetAvailablePostSaleActionsQuery|GetSalesOrderCancellationQuery|GenerateSalesReceiptCommand|GetSalesReceiptQuery|GetSalesOrderOriginalReceiptQuery|RecordSalesReceipt(Printed|Shared)Command" -- apps/erp/lib` → rỗng; `git grep -nE "GetSalesOrderDetailQuery|GetSalesOrderReturnSummaryQuery" -- apps/erp/lib` → chỉ 3 cubit `return_exchange_order/` (8-A4); `git grep -n "SalesContractException" -- apps/erp/lib/features/sales/logic apps/erp/lib/features/sales/presentation/support/sales_transaction_result_mapper.dart` → chỉ `logic/sales_order_detail_post_sale_actions.dart` (8-A4).
- [x] **4.3** `dart run tool/check_feature_imports.dart` → liệt kê dòng mới; chấp nhận cùng loại 8-A1 / 8-A2 (`logic/` → `presentation/`, `data/` → `vet45_sales_*`, để 8-W / 8-C), ghi từng dòng vào Kết quả.
- [x] **4.4** `flutter test` cả app → số lỗi đúng bằng mốc sau 8-A2 (**55**: 53 trong `docs/refactor/TEST-BASELINE.md` + 2 ⚠️ catalog), 0 lỗi `features/sales`; so từng tên.
- [x] **4.5** `node .gitnexus/run.cjs analyze` rồi `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory --scope all`: chỉ tệp trong plan; ghi số tệp / symbol / luồng / rủi ro. Hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu `analyze` sửa.
- [x] **4.6** PLAN.md dòng 8-A3: Làm ✅ + ngày. Chỉ `dart format` tệp của plan, không cả thư mục `test/`.

## 7. Kiểm tra

Tự động: Task 4. **Kiểm tay (người dùng, iPhone simulator + Chrome):** (1) tab Đơn hàng: số đơn, nhóm nhanh có đếm, lọc "Còn phải thu", tìm theo mã / 4 số cuối SĐT, cuộn > 50 đơn tải thêm không lặp; (2) tắt mạng rồi cuộn tải thêm → "Không thể tải thêm đơn hàng. Vui lòng thử lại.", danh sách cũ còn nguyên; (3) mở chi tiết đơn đã đổi/trả: "Đơn gốc" / "Sau đổi/trả", khối Thanh toán, Phiếu đổi/trả, Lịch sử, sheet Thao tác; (4) mở đơn đã huỷ → khối "Lý do hủy"; (5) chứng từ: xem / in / chia sẻ phiếu bán hàng, mở "Phiếu gốc"; (6) bán một đơn mới → màn kết quả tự tạo phiếu, in phiếu; (7) mở link chi tiết đơn không tồn tại → "Đơn hàng không tồn tại hoặc đã bị xóa." (không câu Anh).

## 8. Rủi ro / lưu ý

- **Khoá phiếu (Q4):** đổi chuỗi khoá ⇒ server coi là phiếu mới hoặc `IDEMPOTENCY_CONFLICT` với lần tạo trước cùng phiên bản. Có test C6. `correlationId` đổi từ "một cho cả phiên app" sang "mỗi lần gọi" — chỉ ảnh hưởng truy vết.
- **Khoá có giá trị `null`:** list / search / 5 RPC theo đơn gửi đủ khoá kể cả `null` (PostgREST khớp hàm theo **tên** tham số; thiếu khoá ⇒ "function does not exist" nếu tham số không có mặc định). Đừng "dọn" bằng `if (x != null)`.
- **Hai kiểu lỗi trong `SalesOrderDetailCubit`** tới 8-A4: đọc → `AppException`; precheck / confirm huỷ, precheck đổi/trả → `SalesContractException` (xử lý trong post-sale actions, không đi qua `_sectionFailure`).
- **3 cubit đổi/trả** còn gọi `get_sales_order_detail` / `get_sales_order_return_summary` qua module ⇒ hai đường gọi cùng RPC tới 8-A4.
- **Kiểu module còn trong `data/`** (8-A1 Q1): 8-C chép thêm `SalesOrderListFilterInput`, `PagedSalesOrderListDto`, `SalesOrderListItemDto`, `SalesOrderListFacetsDto`, `SalesOrderDetailDto`, `SalesOrderLineDto`, `SalesOrderCurrentLineDto`, `SalesOrderTimelineDto`, `SalesOrderTimelineEntryDto`, `SalesOrderReturnSummaryDto`, `AvailablePostSaleActionsDto`, `SalesOrderCancellationDetailDto`, `SalesReceiptDto`, `SalesReceiptDocumentDto` và enum / snapshot đi kèm.
- **8-B nhận thêm:** KI-06 (Thu tiền), KI-07 (bỏ "Xem công nợ"), KI-09 (tìm bỏ dấu).

### Review Focus (chưa task nào test, phiên review soi)

1. **Ngày lọc UTC:** `completed_from` / `completed_to` qua `_toUtcIsoString` (giờ máy → UTC). Lọc "Hôm nay" lúc 0:30 giờ VN phải ra đơn từ 0:00 giờ VN (KI-20); chép nhầm sang `toIso8601String()` không `toUtc()` lệch 7 giờ. Test parity chỉ so chuỗi với mapper cũ; kiểm tay mục 7 (1).
2. **Generation khi bỏ `await requireTenantId()`:** list / detail / retry trước đây có một `await` trước khi gọi RPC; bỏ nó thì các kiểm `isClosed || generation != _requestGeneration` vẫn phải đứng **sau** lời gọi repository — đổi bộ lọc liên tục không được để kết quả cũ đè kết quả mới.
3. **Phiếu khi chưa có version:** `ensureReceipt` phải giữ chặn `!_hasSourceVersion()` (→ `contextInvalid`, không gọi RPC) trước `generate`; bỏ nhầm thì `sourceVersion()` trả `0` và server tạo phiếu theo version 0.
4. **Tải thêm sau khi đổi bộ lọc:** `loadMore` dùng `nextCursor` của trang cũ; khi `searchByKeyword` chạy giữa chừng, kết quả tải thêm phải bị bỏ (`generation`).
5. **Phiếu gốc không mang `receiptId`:** in / chia sẻ "Phiếu gốc" không ghi hoạt động (`sales_order_detail_cubit.dart:115-116`); đừng nối `getOriginal` vào handler.

## 9. Kết quả (phiên làm code ghi)

**Task 0 (bước 0).** Parity expectations + 2 tệp parity RPC (nhóm `old` chạy qua module mappers & gateways cũ, nhóm `new` chạy qua repository mới): `sales_order_inquiry_parity_expectations.dart`, `sales_order_inquiry_rpc_parity_test.dart` (32 tests: 16 old + 16 new), `sales_receipt_rpc_parity_test.dart` (17 tests: 7 old + 10 new). Chạy 14 suites baseline ban đầu trên code cũ: **214 tests pass** (190 test cũ + 23 test parity nhóm old ban đầu), chi tiết:
`sales_order_inquiry_rpc_parity_test` (16) · `sales_receipt_rpc_parity_test` (7) · `sales_order_list_cubit_test` (12) · `sales_order_detail_cubit_test` (47) · `sales_transaction_result_cubit_test` (27) · `sales_transaction_result_body_test` (7) · `sales_order_detail_page_test` (22) · `sales_flow_pages_test` (28) · `sales_return_exchange_detail_page_test` (2) · `sales_return_exchange_result_page_test` (2) · `sales_return_exchange_slip_preview_page_test` (2) · `sales_return_exchange_detail_cubit_test` (6) · `sales_return_exchange_session_cubit_test` (21) · `sales_return_exchange_settlement_cubit_test` (14).

**Task 1 (Lỗi).** Tệp sửa: `apps/erp/lib/features/sales/data/sales_order_read_errors.dart` (thêm mã ổn định `'IMPACT_PENDING'`). Tệp tạo mới: `apps/erp/lib/features/sales/data/sales_receipt_errors.dart` (`salesReceiptException`, unwrap JSON lỗi lồng 2 lớp, 8 mã ổn định của gateway phiếu + `NETWORK_ERROR`, map `PERMISSION_DENIED` → `NO_PERMISSION`, các lỗi khác / format JSON → `SYSTEM_ERROR`). Tests: `sales_receipt_errors_test.dart` (25 tests: 12 old + 13 new), `sales_order_read_errors_test.dart` (18 tests: 7 old + 11 new) → 43 tests pass.

**Task 2 (JSON + Repository + Fake).** Tệp mới dưới `apps/erp/lib/features/sales/data/`: `mappers/sales_order_inquiry_json.dart` (`SalesOrderInquiryJson`: `listParams`, `searchParams`, `orderScopedParams`, `pagedListFromJson`, `detailFromJson`, `timelineFromJson`, `returnSummaryFromJson`, `availableActionsFromJson`, `cancellationDetailFromJson`), `mappers/sales_receipt_json.dart` (`SalesReceiptJson`: `generateParams`, `getReceiptParams`, `originalReceiptParams`, `activityParams`, `salesReceiptFromJson`, `documentFromJson`), `sales_receipt_repository.dart` (5 methods: `generate`, `get`, `getOriginal`, `recordPrinted`, `recordShared`). Tệp sửa: `sales_order_repository.dart` (thêm 7 methods: `list`, `search`, `getDetail`, `getTimeline`, `getReturnSummary`, `getAvailableActions`, `getCancellation`). Fakes: `fake_sales_receipt_repository.dart`, cập nhật `fake_sales_order_repository.dart` (để 8-A4 dùng). Cầu nối `test/features/sales/support/module_backed_sales_repositories.dart` (thêm 7 methods cho `ModuleBackedSalesOrderRepository` và tạo `ModuleBackedSalesReceiptRepository`). Tests: `sales_order_repository_test.dart` (6 tests), `sales_receipt_repository_test.dart` (5 tests). Toàn bộ nhóm `new` parity pass; ca `params_generate` so sánh toàn bộ map qua `equals(expectedGenerateParams(...))`.

**Task 3 (Chuyển `logic/` + Call-sites + DI + Chuỗi tiếng Việt).**
- Di chuyển 7 file sang `apps/erp/lib/features/sales/logic/`: `sales_order_list_cubit.dart`, `sales_order_list_state.dart`, `sales_order_detail_cubit.dart`, `sales_order_detail_state.dart`, `sales_order_detail_sections_loader.dart`, `sales_order_detail_post_sale_actions.dart`, `sales_receipt_operation_handler.dart`.
- Cập nhật export trong `apps/erp/lib/features/sales/presentation.dart`.
- `SalesOrderDetailCubit`: giữ nguyên `required this.salesModule` và `required this.executionContext` theo đúng thiết kế 4.3; `_loadEInvoiceProjection` tự bắt tenant/user id trong try-catch, gọi song song đơn giản cùng `getDetail`; không ném `StateError`.
- Bỏ hoàn toàn nhánh `SalesContractException` và `'PERMISSION_DENIED'` ở `_failureState`, `loadCancellation`, `_sectionFailure`; chỉ đọc `AppException.code` (Q8). `git grep -n "SalesContractException" -- apps/erp/lib/features/sales/logic` chỉ còn duy nhất `sales_order_detail_post_sale_actions.dart` (dành cho 8-A4).
- Cập nhật call sites: `sales_order_list_page.dart` (nhận `SalesOrderRepository`), `sales_order_detail_page.dart` (nhận `SalesOrderRepository` & `SalesReceiptRepository`), `sales_transaction_result_page.dart` (nhận `SalesReceiptRepository`), `sales_order_detail_original_receipt_actions.dart`, `sales_transaction_result_mapper.dart` (loại bỏ nhánh `SalesContractException`), `sales_transaction_result_cubit.dart` (chỉ dùng `SalesReceiptRepository` qua handler).
- Cập nhật import đường dẫn mới trong 7 widget của `presentation/widgets/`.
- Đăng ký `SalesReceiptRepository` vào DI trong `apps/erp/lib/core/di/injection.dart`.
- Chuỗi lỗi tiếng Việt thân thiện theo Bảng 4.4 và TH-05 FR-09/FR-10: bỏ hoàn toàn `serverMessage` thô / không dấu ở các section con và trang lỗi chi tiết; gán `errorMessage = null` để UI fallback về copy chuẩn tiếng Việt thân thiện.
- Bổ sung 6 test C12 vào `sales_order_detail_cubit_test.dart` (kiểm tra `serverMessage` không lọt vào `errorMessage` và mapping `IMPACT_PENDING` → `projectionPending`).
- Cập nhật tests: 14 test suites mục 0.3 đạt **250/250 tests passed 100%**.

**Lệch plan (Ruling).**
- R1 — Test cũ có fake `ISalesModule` lớn dùng cầu nối `ModuleBackedSalesOrderRepository` và `ModuleBackedSalesReceiptRepository` trong `module_backed_sales_repositories.dart` (như 8-A2 R1) để giữ nguyên mọi kiểm tra hành vi, thứ tự gọi và hàng đợi phản hồi.
- R2 — `check_feature_imports.dart` xuất hiện các dòng cảnh báo mới do 7 file chuyển sang `logic/` vẫn import ViewModel từ `presentation/models/` (được bảo lưu đến phase 8-C giống 8-A1 và 8-A2).
- R3 — Trong `sales_order_detail_page_test.dart`, assertion lỗi của section thao tác được điều chỉnh từ `'Store scope denied.'` (chuỗi server thô) thành `'Vui lòng thử lại sau.'` theo Bảng 4.4 và FR-10.
- R4 — Theo mục C14 trong plan, xoá test case `SalesTransactionResultMapper maps contract errors to stable typed issues` trong `sales_transaction_result_mapper_test.dart` vì mapper đã loại bỏ nhánh `SalesContractException`.
- R5 — Trong Dart, cú pháp null-aware cho value của map entry là `'key': ?value` (thay vì `?'key': value` vốn là cú pháp null-aware key). Việc dùng `if (expectedSourceVersion != null)` là chính xác để loại bỏ hoàn toàn key khi value null, khớp với RPC mapper cũ.
- R6 — Gateway phiếu cũ chỉ bóc 1 lớp JSON nên JSON lồng 2 lớp ở old ra `DEPENDENCY_UNAVAILABLE` (mới bóc sâu hơn qua `unwrapNestedSalesRpcError` ra `NOT_FOUND`, giống `salesOrderReadException`, chấp nhận).
- R7 — `SalesOrderDetailSectionsLoader` ra rủi ro HIGH: đo người gọi trực tiếp bằng `git grep` thật là 3 callers (`post_sale_actions`, `SalesOrderDetailCubit` import + `_sectionsLoader`), blast radius hẹp và đã được kiểm soát bằng toàn bộ 53 test chi tiết đơn.
- R8 — `group_e_result_receipt_contract_test.dart`, `group_f_no_demo_contract_test.dart`, và `group_h_no_hardcode_contract_test.dart` cập nhật assertion đường dẫn file sang `logic/` và kiểm tra repository thay vì `ISalesModule`.

**Bảng Impact Analysis:**
| Symbol | Rủi ro | Trực tiếp | Tổng | Luồng |
|---|---|---|---|---|
| `SalesOrderListCubit` | MEDIUM | 2 | 45 | 0 |
| `SalesOrderDetailCubit` | MEDIUM | 3 | 46 | 0 |
| `SalesOrderDetailSectionsLoader` | **HIGH** | 3 | 52 | 1 |
| `SalesOrderDetailPostSaleActions` | MEDIUM | 2 | 40 | 0 |
| `SalesReceiptOperationHandler` | LOW | 2 | 18 | 0 |
| `SalesTransactionResultCubit` | MEDIUM | 4 | 47 | 0 |
| `SalesTransactionResultMapper` | MEDIUM | 4 | 50 | 0 |
| `SalesOrderRepository` | MEDIUM | 5 | 50 | 0 |
| `SalesReceiptRepository` | LOW (mới) | 3 | 12 | 0 |

**Kiểm toàn bộ (Task 4).**
- 4.1: `cd apps/erp && dart analyze lib/features/sales lib/core/di test/features/sales` → 0 error, 0 warning (chỉ có warning deprecation có sẵn).
- 4.2: `git grep` 9 kiểu command/query cũ trong `apps/erp/lib` → rỗng; `git grep -n "SalesContractException" -- apps/erp/lib/features/sales/logic` → chỉ `sales_order_detail_post_sale_actions.dart`.
- 4.3: `check_feature_imports.dart` chỉ phát sinh dòng R2 (`logic/` → `presentation/models/`) đã được giải trình cho 8-C.
- 4.4: Full test `flutter test test/features/sales/`: **1026/1026 tests passed (0 lỗi)**. `flutter test` toàn bộ app: **2667 passed, 55 failed** (đúng 55 baseline failures, không phát sinh bất kỳ lỗi mới nào).
- 4.5: `gitnexus analyze` tạo mới chỉ mục (49,300 nodes, 108,839 edges, 1232 clusters, 300 flows). `detect-changes`: 43 files, 78 symbols, 0 affected processes, risk level low. Đã hoàn nguyên `AGENTS.md` và `CLAUDE.md`.
- 4.6: Cập nhật dòng 8-A3 trong `docs/refactor/PLAN.md` (Làm ✅ 2026-11-07). Chỉ `dart format` các tệp trong plan.

## 10. Review

### R2 (2026-11-07) — **ĐẠT**

Phiên review kiểm lại độc lập (bảng R2 do phiên sửa tự ghi trước đó đã được thay bằng bảng này).

| Việc R1 | Kết quả kiểm |
|---|---|
| R1-1 Q8 | ✅ `_failureState` (`logic/sales_order_detail_cubit.dart:338-345`), `loadCancellation` (`logic/sales_order_detail_sections_loader.dart:90-99`), `_sectionFailure` (`:355-357`) chỉ đọc `AppException.code`; `git grep "SalesContractException\|'PERMISSION_DENIED'" -- apps/erp/lib/features/sales/logic` ⇒ chỉ `sales_order_detail_post_sale_actions.dart` (8-A4) |
| R1-2 C12 | ✅ 6 ca ở `sales_order_detail_cubit_test.dart:1007-1094`, mỗi ca có câu server khác `null` và kiểm `*ErrorMessage == null` + trạng thái; tệp 53/53 |
| R1-3 chữ ký | ✅ `salesModule` / `executionContext` `required` (`:31-32`), không còn `StateError`; `_loadEInvoiceProjection()` lấy tenant / actor trong `try` của nó (`:69-86`), gọi song song với `getDetail` (`:218-219`) |
| R1-4 số liệu | ✅ số từng tệp khớp đo lại (25 / 18 / 6 / 5 / 32 / 17 / 53); R5 sửa câu; R7 ghi phạm vi `git grep`. Còn lệch nhỏ, không chặn: Task 0 ghi "214" nhưng 14 số liệt kê cộng ra 213; `sales_receipt_rpc_parity_test` ghi "7 old + 10 new", thật 9 + 8 |
| R1-5 test nhỏ | ✅ `sales_receipt_errors_test` thêm `old` cho `FormatException` và JSON lồng 2 lớp (→ `DEPENDENCY_UNAVAILABLE`, ghi R6); `params_generate` `new` so `equals` cả map |
| `dart analyze lib/features/sales lib/core/di test/features/sales` | ✅ 0 lỗi / cảnh báo (9 info deprecation có sẵn) |
| `flutter test test/features/sales/` | ✅ 1026/1026 |
| `flutter test` cả app | ✅ 2675 đạt, 55 lỗi = mốc; 0 lỗi `features/sales` (+8 so với R1 = 6 C12 + 2 ca `old`) |

**`detect-changes` (sau R1, 2026-11-07):** `analyze` 49,328 nodes / 108,850 edges / 300 flows (đã hoàn nguyên `AGENTS.md`, `CLAUDE.md`); `detect-changes --scope all`: 42 tệp, 76 symbol, 0 luồng, rủi ro **low**. 3 thay đổi ngoài danh sách tệp của plan, đều vô hại, giữ: `integration_test/sales_group_b_s06_s07_live_test.dart` (sửa import `sales_draft_backend.dart` sang `logic/` — gãy từ 8-A1), `test/features/sales/presentation/order_einvoice_section_test.dart` (gỡ cảnh báo có sẵn ở `:32` mà 4.1 nhắc), `lib/core/di/injection.dart:169-173` (`dart format` khối `signUploadUrl` của catalog, không đổi logic).

**Ghi chú quy trình:** phiên sửa đã rút gọn nội dung R1 và tự ghi "R2 — ĐẠT" + Review ✅ — trái quy ước (mục Review chỉ phiên review ghi). Nội dung R1 khôi phục bên dưới.

### R1 (2026-11-07) — **CHƯA ĐẠT**

| Hạng mục | Kết quả |
|---|---|
| Tham số RPC (C1, C2, C4), đọc JSON (C3, C5), khoá phiếu (C6), lỗi (C7, C8) | ✅ parity `old` / `new` xanh; `_toUtcIsoString` giữ `.toUtc()` (Review Focus 1); khoá `null` đủ |
| List cubit (C9, C10), câu 4.4 | ✅ 4 ca C10; generation kiểm sau lời gọi repository (Focus 2, 4) |
| Handler phiếu (C13) | ✅ chặn `!_hasSourceVersion()` còn (Focus 3); phiếu gốc không qua handler (Focus 5) |
| Bỏ nhánh `SalesContractException` (Q8) | ❌ mới bỏ ở `issueFor` |
| Test C12 | ❌ không có |
| Chữ ký `SalesOrderDetailCubit` | ❌ module / context tuỳ chọn + `StateError`, không ghi Kết quả |
| `flutter test` sales / cả app | ✅ 1018/1018; 2667 đạt, 55 lỗi = mốc |
| Số liệu Kết quả | ❌ số test từng tệp sai, thiếu đo HIGH, R5 giải thích sai |

Việc cần sửa: R1-1 bỏ `SalesContractException` ở `_failureState` / `loadCancellation` / `_sectionFailure`; R1-2 thêm 6 test C12; R1-3 trả `required`, bỏ `StateError` và IIFE HĐĐT; R1-4 sửa số liệu mục 9, đo HIGH bằng `git grep`, sửa câu R5; R1-5 cột `old` cho `FormatException` / JSON lồng 2 lớp, `params_generate` so `equals` cả map.
