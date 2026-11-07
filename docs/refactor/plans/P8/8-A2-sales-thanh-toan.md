# 8-A2 — Sales: checkout + thanh toán sang `SalesCheckoutRepository` / `SalesPaymentRepository` / `SalesOrderRepository.get`

> Theme 5 (mã cũ P8) · Bước (a) chuyển kiến trúc, nhóm thanh toán · Gồm việc 8.2 (PLAN.md mục Theme 5): precheck, finalize, get_checkout_result, payment summary, settlement, payment transactions. Thêm `get_sales_order` (màn SG-06 cần). **Không gồm** `record_sales_payment`, `record_sales_refund` (Q2), sửa `finalize_sales_order` / `precheck_sales_order_checkout` (KI-02/03/04 → 8-B).
> Trạng thái: Plan 📝 (viết 2026-11-07, duyệt 2026-11-07) | Làm ✅ 2026-11-07 | Review ✅ 2026-11-07 (R1 đạt)
> Trước: 8-A1 (nháp, đã review ĐẠT). Sau: **8-A3** (tra cứu, phiếu) — mở rộng `SalesOrderRepository`. Module sales còn chạy song song cho tra cứu, phiếu, huỷ, đổi/trả tới 8-A4; 8-C dọn.
> Tài liệu: [TH-05](../../../02-yeu-cau/TH-05-ban-hang-va-don-hang.md) US-02.2…02.4 (SG-06 thanh toán, FR-01…04), BR-18…BR-27, 6.2 (RPC), 6.4 (câu lỗi), 7.2, 9.1; PLAN.md "Cách chuyển MỘT feature", "Plan xoá / tách / thay code cũ: test giữ hành vi trước". Mẫu: [8-A1](8-A1-sales-nhap.md) (cấu trúc, parity `old` / `new`, lỗi `AppException`).
>
> **Cho phiên code:** dùng `superpowers:executing-plans` (tuần tự). Mỗi task xong ghi ngay mục 9. **Không commit** (người dùng commit sau `detect_changes()`). Không chạy / đề nghị reset DB, push, SQL (plan không đụng DB).

## 1. Mục tiêu

- 6 RPC của schema `sales` + `get_sales_order` đi qua repository thay `ISalesModule`:
  ```text
  SalesCheckoutOrchestrator ─┐
  SalesCheckoutCubit ────────┼─▶ SalesCheckoutRepository ─▶ SupabaseRpc.call('sales', …)   precheck / finalize / get_checkout_result
  SalesTransactionResultCubit┤
                             ├─▶ SalesOrderRepository.get                                   get_sales_order
  SalesOrderDetailSectionsLoader (phần thanh toán) ─▶ SalesPaymentRepository               summary / settlement / transactions
  ```
- Repository **nhận và trả kiểu của `vet45_sales_application`** (như 8-A1 Q1): `CheckoutLineInput`, `PaymentIntentInput`, `SalesCommercialSnapshotInput`, `CheckoutPrecheckDto`, `CheckoutResultDto`, `SalesOrderResultDto`, `SalesOrderPaymentSummaryDto`, `SalesOrderSettlementDto`, `SalesPaymentTransactionsDto`. Chỉ chép vào app: dựng tham số + đọc JSON (từ `CheckoutPrecheckRpcMapper`, `SalesOrderReadRpcMapper`, `SalesOrderInquiryRpcMapper`), rule đầu vào (validator của finalize), phân loại lỗi.
- Lỗi đi ra là `AppException`. Câu lỗi thô (`error.message ?? …`) ở màn thanh toán đổi theo TH-05 6.4 (Q4).
- Test parity `old` (module) / `new` (repository) dùng **chung giá trị mong đợi**. 8-C xoá nhóm `old` cùng module.
- `SalesCheckoutCubit` / `SalesTransactionResultCubit` (+ state, issue) và `SalesCheckoutOrchestrator` chuyển vào `features/sales/logic/` (bước 6 của công thức).

**Không làm:** `record_sales_payment` / `record_sales_refund` (Q2); sửa RPC (KI-02/03/04, BR-20/23/24 → 8-B); `list/search/detail/timeline`, phiếu, huỷ, đổi/trả (8-A3, 8-A4); bố cục web (plan 8-W); chép kiểu DTO (8-C).

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | Chia repository. SG-06 gọi cả `get_sales_order` (thuộc tra cứu) và payment summary; màn chi tiết đơn gọi thêm settlement + transactions | **Người dùng chốt 2026-11-07:** `SalesCheckoutRepository` (precheck / finalize / getResult) + `SalesPaymentRepository` (summary / settlement / transactions) + `SalesOrderRepository` **chỉ có `get`** (8-A3 thêm list / search / detail / timeline vào cùng lớp). Phần thanh toán của màn chi tiết đổi ngay ở 8-A2; phần lịch sử / thao tác / huỷ / phiếu của màn đó còn module |
| Q2 | `record_sales_payment`, `record_sales_refund` (không có nơi nào trong `apps/erp/lib` gọi; chỉ module có handler) | **Người dùng chốt 2026-11-07: không chuyển.** `record_sales_refund` app không dùng (TH-05 6.2). `recordPayment` thêm khi làm màn "Thu tiền" (KI-06 / EP-04, 8-B). Handler + test cũ xoá cùng module ở 8-C |
| Q3 | `FinalizeSalesOrderCommandHandler` gọi `precheck` một lần nữa trước `finalize`, bị chặn thì trả `blocked` mà không gọi finalize | **Người dùng chốt 2026-11-07: `finalize` chỉ gọi `finalize_sales_order`** (quy ước Theme 3/4: bỏ RPC đọc trước). Cubit đã `_runPrecheck()` ngay trước khi gửi (`sales_checkout_cubit.dart:179`); server tự chặn và lưu kết quả `blocked` (`20260830008_sales_checkout_rpcs.sql:720-734`). Khác nhỏ: `blocked` giờ mang `blockedCode` của server (cũ: rỗng khi chặn ở client); cubit đã xử lý `PRICE_CHANGED` / `PRICING_BLOCKED` (`:283-286`) |
| Q4 | Câu thô ở màn thanh toán: `sales_checkout_cubit.dart:368` (`error.message ?? 'Không thể hoàn tất đơn.'`), `:465`, `:468` (`CHECKOUT_BLOCKED` / `_ => error.message ?? …`) hiện câu tiếng Anh của server / gateway ("Sales checkout finalize failed.", …) | **Đổi có chủ đích theo TH-05 6.4, không bao giờ hiện `serverMessage` hay mã** (như 8-A1 Q3). Bảng ở 4.4. **Người dùng duyệt 2026-11-07** |
| Q5 | Mã lỗi | Giữ 12 mã ổn định của gateway checkout (`supabase_checkout_gateway.dart:111-124`) và 6 mã của gateway đọc (`supabase_sales_order_read_gateway.dart:85-92`). `PERMISSION_DENIED` → `NO_PERMISSION`. Mất mạng (`NETWORK_ERROR`) giữ nguyên mã. Mã khác / lỗi đọc JSON ⇒ `SYSTEM_ERROR` (cũ: `DEPENDENCY_UNAVAILABLE` + câu Anh). Rà cubit: không nơi nào rẽ nhánh theo `DEPENDENCY_UNAVAILABLE` do lỗi đọc JSON, chỉ để **cho phép thử lại** (`_recoverAttempt`, `sales_checkout_cubit.dart:344`) — giữ cho `DEPENDENCY_UNAVAILABLE` **và** `NETWORK_ERROR` |
| Q6 | Mất mạng khi `finalize` — cũ: gateway chỉ đổi `TimeoutException` → `UNCERTAIN_RESULT`; lỗi mạng khác → `DEPENDENCY_UNAVAILABLE` ⇒ cubit báo **thất bại** (`_executeAttempt`, `:250-256`), người dùng thấy "Không thể hoàn tất đơn" dù server có thể đã ghi đơn. TH-05 FR-03 / BR-27: "Mất kết nối → **khôi phục** bằng `get_checkout_result`, không cho thanh toán lại" | **Người dùng chốt 2026-11-07: đổi (theo đề xuất).** `finalize` đổi `NETWORK_ERROR` **và** timeout → `UNCERTAIN_RESULT` ⇒ cubit vào `_recoverAttempt`. |
| Q7 | Kiểm quyền client: `permissionChecker.require(recordPayment)` khi có khoản thu (handler finalize), `finalizeCheckout` (precheck), `viewOrder` (get_checkout_result, get_sales_order), `viewPayment` (3 query thanh toán) | **Bỏ** (quy ước Theme 3/4). Server kiểm ở mọi RPC (TH-05 6.2). TH-05 7.2: người dùng không thấy khác. Mất kiểm `recordPayment` khi `paymentIntents` không rỗng: server `finalize_sales_order` vẫn kiểm (6.2 "như trên") |
| Q8 | `tenantId` / `actorId` | Repository lấy qua closure mỗi lần gọi (như 8-A1 Q9). `FinalizeSalesOrderCommand` **không còn dùng** trong app. Cubit **giữ** `IExecutionContext` chỉ để đưa `tenantId` / `actorId` / `correlationId` vào `SalesCheckoutAttemptFactory` — đã nằm trong chuỗi băm `payloadHash` (`sales_checkout_attempt_factory.dart:45-95`), bỏ sẽ đổi hash. 8-C bỏ `CoreExecutionContext` |
| Q9 | `query_id` / `command_id` | `p_query_id` / `query_id`: repository tự sinh UUID v4 mỗi lần gọi (cũ: `SalesReadContract.id`, cũng UUID v4 mỗi query); hàm sinh nhận qua constructor (`String Function()? newId`) để test cố định. `p_command_id` = `attemptId` do factory sinh (đi qua `SalesFinalizeRequest.commandId`) |
| Q10 | Kiểu cho `finalize` — `FinalizeSalesOrderCommand` (module) là kiểu chứa `tenantId`/`actorId`/`id` | Thay bằng lớp thuần `SalesFinalizeRequest` (4.3); `SalesCheckoutAttemptEnvelope.command` → `.request` |

## 3. Hiện trạng (đo 2026-11-07)

`apps/erp/lib` gọi module cho nhóm này ở các tệp:

| Tệp (dưới `lib/features/sales/presentation/`) | Gọi | RPC |
|---|---|---|
| `orchestration/sales_checkout_orchestrator.dart:52` | `PrecheckSalesOrderCheckoutQuery` | `precheck_sales_order_checkout` (giả định trả đủ tiền mặt, BR-21) |
| `bloc/sales_order/sales_checkout_cubit.dart:226` | `FinalizeSalesOrderCommand` | `finalize_sales_order` (+ `precheck` trong handler, Q3) |
| `…/sales_checkout_cubit.dart:321`, `:391` | `GetCheckoutResultQuery`, `PrecheckSalesOrderCheckoutQuery` | `get_checkout_result`, `precheck_sales_order_checkout` |
| `bloc/sales_order/sales_transaction_result_cubit.dart:130`, `:224`, `:229` | `GetCheckoutResultQuery`, `GetSalesOrderQuery`, `GetSalesOrderPaymentSummaryQuery` | `get_checkout_result`, `get_sales_order`, `get_sales_order_payment_summary` |
| `bloc/sales_order/sales_order_detail_sections_loader.dart:199`, `:209`, `:219`, `:361` | 3 query thanh toán (summary / settlement / transactions, phân trang `cursor`) | 3 RPC tương ứng |
| `support/sales_checkout_attempt_factory.dart:81` | dựng `FinalizeSalesOrderCommand` | — |
| `models/sales_order/sales_checkout_attempt_envelope.dart:11` | giữ `FinalizeSalesOrderCommand command` | — |

Cubit còn dựng bằng `ISalesModule` ở `pages/sales_checkout_page.dart:36`, `pages/sales_transaction_result_page.dart:33`, `pages/sales_order_detail_page.dart:39` → `SalesOrderDetailCubit` (`:24`) → `SalesOrderDetailSectionsLoader` (`:15`). `SalesOrderDetailCubit` vẫn cần `salesModule` cho chi tiết, phiếu, huỷ (8-A3, 8-A4).

| Command / Query | Handler làm thêm gì | RPC | Tham số (chép từ mapper) |
|---|---|---|---|
| `PrecheckSalesOrderCheckoutQuery` | `require(finalizeCheckout)` | `precheck_sales_order_checkout` | `CheckoutPrecheckRpcMapper.precheckParams` (khoá `p_*`; `p_expected_source_version` chỉ khi khác `null`) |
| `FinalizeSalesOrderCommand` | `FinalizeSalesOrderCommandValidator`; `require(recordPayment)` nếu có khoản thu; precheck trước (Q3) | `finalize_sales_order` | `finalizeParams` (gồm `p_commercial_snapshot`, `p_correlation_id`, `p_causation_id`) |
| `GetCheckoutResultQuery` | `require(viewOrder)` | `get_checkout_result` | `statusParams` |
| `GetSalesOrderQuery` | `require(viewOrder)` | `get_sales_order` | `SalesOrderReadRpcMapper.getSalesOrderParams` — **không có** `p_expected_source_version` |
| `GetSalesOrderPaymentSummaryQuery` | `require(viewPayment)` | `get_sales_order_payment_summary` | `paymentSummaryParams` (khoá `p_*`) |
| `GetSalesOrderSettlementQuery` | `require(viewPayment)` | `get_sales_order_settlement` | `SalesOrderInquiryRpcMapper.settlementParams` — **khoá không tiền tố**: `query_id`, `tenant_id`, `actor_id`, `sales_order_id`, `expected_source_version` (RPC khai báo không `p_`, `20260830010_…sql:1159`) |
| `GetSalesOrderPaymentTransactionsQuery` | `require(viewPayment)` | `get_sales_order_payment_transactions` | `transactionsParams` — cùng khoá không tiền tố + `cursor`, `page_size` (mặc định 25) |

Đường dẫn module: `modules/sales/infrastructure/lib/src/domain/sales_order/{checkout_precheck_rpc_mapper,supabase_checkout_gateway,sales_order_read_rpc_mapper,supabase_sales_order_read_gateway,sales_order_inquiry_rpc_mapper,supabase_sales_order_inquiry_gateway}.dart`; `modules/sales/application/lib/src/sales_order/commands/finalize_sales_order/**`, `…/sales_order_settlement/queries/**`. Mẫu test: `modules/sales/infrastructure/test/domain/sales_order/{supabase_sales_order_read_gateway_test,supabase_sales_order_inquiry_gateway_test}.dart` (JSON mẫu). Hàm đọc JSON chép: `CheckoutPrecheckRpcMapper.{precheckFromJson,checkoutResultFromJson}`, `SalesOrderReadRpcMapper.{salesOrderResultFromJson,paymentSummaryFromJson}`, `SalesOrderInquiryRpcMapper.{settlementFromJson,transactionsFromJson}` cùng helper của chúng (`_transaction`, `_settlementStatus`, `_transactionType`, `_direction`, `_paymentMethod`, `_paymentStatus`, `_money`, `_store`, `_customer`, `_actor`, `_lifecycleStatus`, `_lockStatus`, `_dateTime`, `_nullableDateOnly`, …). Tất cả RPC trả `jsonb`.

Test app đang dựng fake module cho nhóm này: `test/features/sales/presentation_module/bloc/sales_checkout_cubit_test.dart`, `…/sales_transaction_result_cubit_test.dart`, `…/sales_order_detail_cubit_test.dart`, `test/features/sales/sales_transaction_result_page_test.dart`, `test/features/sales/sales_order_detail_page_test.dart`, `test/features/sales/presentation/sales_checkout_page_test.dart`, `test/features/sales/sales_flow_pages_test.dart` (`_RecordingSalesModule`), `test/features/sales/presentation_module/widgets/sales_transaction_result_body_test.dart`; hợp đồng chuỗi: `test/features/sales/group_d_finalize_contract_test.dart` (đòi `salesModule.executeCommandAsync<CheckoutResultDto>` trong cubit), `group_e_result_receipt_contract_test.dart`.

## 4. Thiết kế

### 4.1 Lỗi (`apps/erp/lib/features/sales/data/`)

- **Tách phần bóc JSON lồng** của 8-A1 (`_unwrapNested` trong `sales_draft_errors.dart`) thành hàm dùng chung `AppException? unwrapNestedSalesRpcError(String? raw, {required Set<String> stableCodes})` trong `sales_rpc_errors.dart`; `sales_draft_errors.dart` gọi lại hàm này (test 8-A1 `sales_draft_errors_test.dart` giữ nguyên, phải xanh).
- `sales_checkout_errors.dart`:
  ```dart
  abstract final class SalesCheckoutErrorCodes {
    static const noPermission = 'NO_PERMISSION';              // server PERMISSION_DENIED
    static const checkoutBlocked = 'CHECKOUT_BLOCKED';
    static const staleVersion = 'STALE_VERSION';
    static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
    static const dependencyUnavailable = 'DEPENDENCY_UNAVAILABLE';
    static const uncertainResult = 'UNCERTAIN_RESULT';
    static const productNotSellable = 'PRODUCT_NOT_SELLABLE';
    static const dataScopeDenied = 'DATA_SCOPE_DENIED';
    static const contextInvalid = 'CONTEXT_INVALID';
    static const checkoutResultNotFound = 'CHECKOUT_RESULT_NOT_FOUND';
    static const priceChanged = 'PRICE_CHANGED';
    static const pricingBlocked = 'PRICING_BLOCKED';
    static const networkError = 'NETWORK_ERROR';              // AppErrorCode.network
    static const systemError = 'SYSTEM_ERROR';
  }
  AppException salesCheckoutException(Object error, {bool uncertainOnNetwork = false});
  ```
  Mã trong 12 + `NETWORK_ERROR` → giữ `code`, `serverMessage`, `details`; còn lại → `SYSTEM_ERROR` (`cause` = lỗi gốc). `uncertainOnNetwork: true` (chỉ `finalize`, Q6): `NETWORK_ERROR` và `TimeoutException` → `UNCERTAIN_RESULT`.
- `sales_order_read_errors.dart`: `AppException salesOrderReadException(Object error)` cho `SalesOrderRepository` + `SalesPaymentRepository`: mã giữ `NOT_FOUND`, `NO_PERMISSION`, `PROJECTION_PENDING`, `DATA_SCOPE_DENIED`, `STALE_VERSION`, `DEPENDENCY_UNAVAILABLE`, `NETWORK_ERROR`; còn lại `SYSTEM_ERROR`.
- Repository bọc mỗi lần gọi bằng `_guard` (như `SalesDraftRepository`).

### 4.2 Rule (`apps/erp/lib/features/sales/logic/sales_checkout_rules.dart`)

`checkFinalize({required String storeId, required String currencyCode, required String idempotencyKey, required String payloadHash, required String correlationId, required List<CheckoutLineInput> lines, required List<PaymentIntentInput> paymentIntents})` — chép **điều kiện và câu** của `FinalizeSalesOrderCommandValidator` (bỏ kiểm `tenantId` / `actorId`), thứ tự kiểm đúng validator: `storeId`, `currencyCode`, `idempotencyKey`, `payloadHash`, `correlationId` không rỗng (`'<field> is required.'`); 0 dòng → `'Finalize checkout requires at least one line.'`; mỗi dòng `productId`, `productUnitId` không rỗng, `quantityMicros <= 0` → `'Checkout line quantity must be positive.'`; mỗi khoản thu `amountMinor <= 0` → `'Payment intent amount must be greater than zero.'`, `currencyCode` không rỗng (`'paymentCurrencyCode is required.'`). Vi phạm ⇒ `AppException(SalesCheckoutErrorCodes.contextInvalid, serverMessage: '<câu cũ>')`. `precheck` / `getResult` / 4 hàm đọc: không rule (cũ không có validator).

### 4.3 Repository

```dart
// data/models/sales_finalize_request.dart — thay FinalizeSalesOrderCommand trong app (Q10)
final class SalesFinalizeRequest {
  const SalesFinalizeRequest({
    required this.commandId, required this.storeId, this.sourceDraftId, this.customerId,
    required this.currencyCode, this.orderNote, this.paymentDueDate,
    required this.lines, required this.paymentIntents, required this.commercialSnapshot,
    required this.idempotencyKey, required this.payloadHash, required this.correlationId,
    this.expectedSourceVersion,
  });
  // lines: List<CheckoutLineInput>; paymentIntents: List<PaymentIntentInput>;
  // commercialSnapshot: SalesCommercialSnapshotInput; paymentDueDate: DateTime? (ngày, không giờ)
}

// data/sales_checkout_repository.dart
class SalesCheckoutRepository {
  SalesCheckoutRepository({required SupabaseRpc rpc, required Future<String> Function() tenantId,
      required Future<String> Function() actorId, String Function()? newId});
  Future<CheckoutPrecheckDto> precheck({required String storeId, String? customerId,
      required String currencyCode, DateTime? paymentDueDate, required List<CheckoutLineInput> lines,
      required List<PaymentIntentInput> paymentIntents, int? expectedSourceVersion});
  Future<CheckoutResultDto> finalize(SalesFinalizeRequest request);
  Future<CheckoutResultDto> getResult({required String storeId, required String idempotencyKey});
}

// data/sales_payment_repository.dart
class SalesPaymentRepository {
  SalesPaymentRepository({required SupabaseRpc rpc, required Future<String> Function() tenantId,
      required Future<String> Function() actorId, String Function()? newId});
  Future<SalesOrderPaymentSummaryDto> getSummary({required String salesOrderId, int? expectedSourceVersion});
  Future<SalesOrderSettlementDto> getSettlement({required String salesOrderId, int? expectedSourceVersion});
  Future<SalesPaymentTransactionsDto> getTransactions({required String salesOrderId,
      int? expectedSourceVersion, String? cursor, int pageSize = 25});
}

// data/sales_order_repository.dart (8-A3 thêm list / search / detail / timeline)
class SalesOrderRepository {
  SalesOrderRepository({required SupabaseRpc rpc, required Future<String> Function() tenantId,
      required Future<String> Function() actorId, String Function()? newId});
  Future<SalesOrderResultDto> get({required String salesOrderId});
}
```

Mỗi method: rule (4.2, chỉ finalize) → `tenantId()` / `actorId()` → `_rpc.call('sales', '<rpc>', params: …)` → ép `Map<String, dynamic>` → hàm đọc JSON. Tham số **giống hệt** mapper cũ (kể cả khoá có / không `p_`, `p_currency_code` = trim + chữ hoa, `p_payment_due_date` dạng `yyyy-MM-dd`, `p_expected_source_version` chỉ khi khác `null` ở precheck / finalize / summary, `p_causation_id: null` và `p_correlation_id` có mặt ở finalize). `getSettlement` / `getTransactions` gửi `expected_source_version` **luôn có** (kể cả `null`) như mapper cũ. Hàm dựng tham số + đọc JSON chép vào `data/mappers/sales_checkout_json.dart` (`SalesCheckoutJson`), `sales_payment_json.dart` (`SalesPaymentJson`), `sales_order_get_json.dart` (`SalesOrderGetJson`); mọi `FormatException` giữ nguyên, ra ngoài thành `SYSTEM_ERROR` (Q5).

### 4.4 Câu lỗi (`apps/erp/lib/features/sales/logic/sales_checkout_error_messages.dart`, Q4)

`String salesCheckoutErrorMessage(Object error, {required String fallback, Map<String, String> overrides = const {}})` — thứ tự `overrides[code]` → bảng → `fallback`; lỗi không phải `AppException` ⇒ `fallback`. Bảng (TH-05 6.4):

| Mã | Câu |
|---|---|
| `NO_PERMISSION` | "Bạn không có quyền thực hiện thao tác này." |
| `DATA_SCOPE_DENIED` | "Cửa hàng hiện tại không còn khả dụng." |
| `CONTEXT_INVALID` | "Ngữ cảnh thanh toán không hợp lệ." |
| `IDEMPOTENCY_CONFLICT` | "Yêu cầu bị xung đột" |
| `PRODUCT_NOT_SELLABLE` | "Sản phẩm đã ngừng bán. Vui lòng quay lại đơn." |
| `PRICE_CHANGED` | "Giá đã thay đổi. Vui lòng quay lại kiểm tra." |
| `PRICING_BLOCKED` | "Sản phẩm này chưa có giá bán." |
| `CHECKOUT_BLOCKED` | "Đơn chưa đủ điều kiện thanh toán." |

Chỗ dùng (giữ câu có sẵn ở ngoặc):
- `finalize` (`_attemptMessageFor`): `overrides: {NO_PERMISSION: 'Bạn không còn quyền hoàn tất đơn.'}`, `fallback: 'Không thể hoàn tất đơn.'`. Nhánh `IDEMPOTENCY_CONFLICT` / `STALE_VERSION` / `UNCERTAIN_RESULT` giữ nguyên câu hiện có trong `_executeAttempt`.
- `precheck` (`_messageFor`): `overrides: {NO_PERMISSION: 'Bạn không còn quyền kiểm tra thanh toán.', STALE_VERSION: 'Dữ liệu đơn đã thay đổi. Vui lòng quay lại kiểm tra.', DEPENDENCY_UNAVAILABLE: 'Chưa thể kiểm tra điều kiện thanh toán. Vui lòng thử lại.', NETWORK_ERROR: <như DEPENDENCY_UNAVAILABLE>}`, `fallback: 'Không thể kiểm tra thanh toán. Vui lòng thử lại.'`.
- Màn kết quả: **không đổi câu** (đã dùng `SalesTransactionResultIssue`); chỉ `SalesTransactionResultMapper.issueFor` thêm nhánh `AppException`: `UNCERTAIN_RESULT`→`uncertainResult`, `CHECKOUT_BLOCKED`→`checkoutBlocked`, `NOT_FOUND`→`notFound`, `NO_PERMISSION`/`DATA_SCOPE_DENIED`→`permissionDenied`, `PROJECTION_PENDING`→`projectionPending`, `STALE_VERSION`→`staleVersion`, `IDEMPOTENCY_CONFLICT`→`idempotencyConflict`, `CONTEXT_INVALID`→`contextInvalid`, `DEPENDENCY_UNAVAILABLE`→`dependencyUnavailable`, còn lại (gồm `NETWORK_ERROR`, `SYSTEM_ERROR`)→`transportFailure`. Nhánh `SalesContractException` giữ (cubit biên nhận phiếu vẫn dùng module tới 8-A3).
- Phần thanh toán của màn chi tiết: `_sectionFailure` (`sales_order_detail_sections_loader.dart:397`) đọc mã từ **cả hai** kiểu lỗi; `NO_PERMISSION` / `DATA_SCOPE_DENIED` → `blocked`, `PROJECTION_PENDING` → `projectionPending`; với `AppException` **không** truyền `serverMessage` vào `paymentErrorMessage` (hết câu thô). Nhánh `SalesContractException` giữ cho lịch sử / thao tác tới 8-A3, 8-A4.

### 4.5 Cubit

- `SalesCheckoutCubit({required SalesCheckoutRepository repository, required IExecutionContext executionContext, required ISalesActiveStoreContext activeStoreContext, …})`: `repository.precheck(storeId:, customerId: args.customerId, currencyCode: args.currencyCode, paymentDueDate: <ngày>, lines: args.lines, paymentIntents: _paymentIntents(vm), expectedSourceVersion: args.expectedSourceVersion)`; `repository.finalize(envelope.request)`; `repository.getResult(storeId: request.storeId, idempotencyKey: request.idempotencyKey)`. Rẽ nhánh theo `AppException.code`: `UNCERTAIN_RESULT` → `_recoverAttempt(automatic: true)`; `IDEMPOTENCY_CONFLICT` → `conflict`; `STALE_VERSION` → `blocked`; không phải `AppException` → recover (giữ `catch (_)`); còn lại → failure + câu (4.4). Trong `_recoverAttempt`: bỏ qua (thử tiếp) khi `CHECKOUT_RESULT_NOT_FOUND`, `DEPENDENCY_UNAVAILABLE`, `NETWORK_ERROR`.
- `SalesTransactionResultCubit({required SalesCheckoutRepository checkoutRepository, required SalesOrderRepository orderRepository, required SalesPaymentRepository paymentRepository, required IExecutionContext executionContext, …})`: bỏ `tenantId` / `actorId` khỏi đường gọi dữ liệu; **giữ** `IExecutionContext` nếu còn dùng cho biên nhận (kiểm ở Task 4.5; nếu không còn dùng thì bỏ). `_canRecoverFrom`: `error is! AppException` hoặc mã ∈ {`UNCERTAIN_RESULT`, `CHECKOUT_RESULT_NOT_FOUND`, `NETWORK_ERROR`}.
- `SalesCheckoutAttemptFactory.create(...)` giữ chữ ký; trả `SalesCheckoutAttemptEnvelope(request: SalesFinalizeRequest(...), canonicalPayloadJson, payloadHash)`; **không đổi** chuỗi băm.
- `SalesCheckoutOrchestrator.bind()` → `GetIt<SalesCheckoutRepository>().precheck(…)`; bắt lỗi giữ nguyên (`SalesCheckoutPrepareFailed` câu có sẵn).

## 5. Đang làm gì — test giữ hành vi

| # | Cũ đang làm gì | Sau 8-A2 nằm ở đâu | Test |
|---|---|---|---|
| C1 | Tham số `precheck` / `finalize` / `get_checkout_result` (`CheckoutPrecheckRpcMapper.*Params`) | `SalesCheckoutRepository` + `SalesCheckoutJson.*Params` | parity `params_precheck`, `params_finalize`, `params_get_checkout_result` (Task 0 `old`, Task 3 `new`); biên: `paymentDueDate: DateTime(2026,11,9,15)` → `'2026-11-09'`, `currencyCode: ' vnd '` → `'VND'`, `expectedSourceVersion: null` ⇒ khoá vắng |
| C2 | Đọc JSON kết quả (`precheckFromJson`, `checkoutResultFromJson`; `FormatException` khi thiếu `idempotencyKey` / `status` lạ) | `SalesCheckoutJson` | parity `parse_precheck`, `parse_checkout_result_<status>` × 5, `parse_rejects_unknown_status`, `parse_rejects_blank_idempotency_key` |
| C3 | Validator finalize (mã `CONTEXT_INVALID` + câu) | `sales_checkout_rules.dart`, repository gọi trước RPC | `sales_checkout_rules_test.dart` (Task 2, nhóm `old` qua `FinalizeSalesOrderCommandValidator` + `new`) + `finalize_rule_blocks_before_rpc` (0 lần gọi RPC) |
| C4 | Handler finalize: `require(recordPayment)` + precheck trước, trả `blocked` khi chặn | **Bỏ (Q3, Q7)** | `finalize_calls_only_finalize_rpc` (`calls.single.fn == 'finalize_sales_order'`), `finalize_blocked_result_carries_server_code` |
| C5 | Gateway checkout: 12 mã ổn định (bóc JSON lồng), `TimeoutException` → `UNCERTAIN_RESULT`, còn lại `DEPENDENCY_UNAVAILABLE` | `salesCheckoutException`; **đổi (Q5, Q6)** | `sales_checkout_errors_test.dart`: cùng bảng đầu vào cho gateway cũ và `salesCheckoutException` (cột `old` / `new`) |
| C6 | 3 RPC thanh toán + `get_sales_order`: tham số (khoá có / không `p_`, `page_size` 25, `expected_source_version` luôn có ở settlement / transactions) và đọc JSON | `SalesPaymentRepository`, `SalesOrderRepository` | parity `params_summary`, `params_settlement`, `params_transactions`, `params_get_order`, `parse_summary`, `parse_settlement`, `parse_transactions` (+ `nextCursor`, `hasMore`), `parse_order` |
| C7 | Gateway đọc: 6 mã ổn định, còn lại `DEPENDENCY_UNAVAILABLE` | `salesOrderReadException`; **đổi (Q5)** còn lại `SYSTEM_ERROR` | `sales_order_read_errors_test.dart` (`old` / `new`) |
| C8 | `SalesCheckoutCubit`: precheck có `requestRevision`, chặn finalize khi `precheck` không đạt, khôi phục sau mất kết nối với lùi dần, "Kiểm tra lại" / "Thử lại" cùng key, khoá nút khi gửi | giữ nguyên trong `logic/sales_checkout_cubit.dart`, chỉ đổi đích gọi | các test có sẵn của `sales_checkout_cubit_test.dart` (đổi fake, giữ điều kiện kiểm) |
| C9 | Cubit: câu thô `error.message` | **đổi có chủ đích (Q4)**, bảng 4.4 | mới: `finalize_unknown_error_shows_fallback_not_server_message`, `finalize_no_permission_shows_6_4_message`, `precheck_checkout_blocked_shows_6_4_message`, `precheck_system_error_shows_fallback` |
| C10 | `finalize` gặp mất mạng → "failure" | **đổi (Q6)** | `finalize_network_error_recovers_via_get_checkout_result`: fake ném `AppException('NETWORK_ERROR')` rồi `getResult` trả `succeeded` ⇒ `attemptStatus == succeeded`, `finalizeCalls.length == 1` |
| C11 | `SalesTransactionResultCubit`: thứ tự `get_checkout_result` → (`get_sales_order` ∥ `payment summary`), trạng thái `loaded` / `partial` / `uncertain` / `failure`, mapper lỗi → issue | giữ; thêm nhánh `AppException` | các test có sẵn của `sales_transaction_result_cubit_test.dart` + `sales_transaction_result_page_test.dart` (đổi fake) + mới `issue_for_app_exception_<code>` × 9 |
| C12 | Màn chi tiết: phần thanh toán (3 query song song, phân trang giao dịch theo `cursor`, `_sectionFailure`) | `SalesOrderDetailSectionsLoader` gọi `SalesPaymentRepository` | các test có sẵn của `sales_order_detail_cubit_test.dart` về thanh toán (đổi fake) + mới `payment_section_permission_denied_is_blocked`, `payment_section_projection_pending`, `payment_section_error_never_shows_server_message` |
| C13 | Hợp đồng chuỗi `group_d_finalize_contract_test` (cubit chỉ qua `ISalesModule`) | đổi theo đường dẫn mới và `repository.finalize` | sửa tệp test: `expect(cubit, contains('repository.finalize'))`, `contains('repository.getResult')`; giữ `isNot(contains('Supabase'))`, `isNot(contains('.rpc('))` |

**Bước 0 (Task 0):** nhóm `old` của parity C1 / C2 / C3 / C5 / C6 / C7 chạy trên module, xanh, ghi tên — rồi mới viết tệp mới. Test có sẵn C8, C11, C12 phải **xanh trên code cũ** trước Task 4 (chạy và ghi số ở Task 0).

## 6. Các bước

**Ràng buộc chung** (mọi task):
- Chỉ sửa tệp liệt kê ở từng task. Không đụng `modules/sales`, không sửa RPC / migration.
- Trước khi sửa symbol có sẵn: `gitnexus impact({target: "<symbol>", direction: "upstream"})`, ghi số vào Kết quả; HIGH / CRITICAL ⇒ dừng, báo người dùng (8-A1 ghi nhận index Dart gộp theo tên nên ra CRITICAL giả — nếu lại gặp, đo phạm vi thật bằng `git grep` và ghi vào Kết quả, vẫn báo người dùng).
- Chép nguyên văn điều kiện, câu, tên khoá JSON (kể cả khoá có / không `p_`). Thấy chỗ phải sửa thân mới chạy được ⇒ ghi Kết quả, không tự đổi hành vi.
- Không `tenantId` / `actorId` trong chữ ký repository.
- Test parity có `// ignore_for_file: implementation_imports`. Tệp test mới đặt ở `apps/erp/test/features/sales/{data,logic}/`.

### Task 0: Bước 0 — parity `old` + chạy test có sẵn trên code cũ

**Files:**
- Create: `apps/erp/test/features/sales/data/sales_checkout_parity_expectations.dart`, `sales_checkout_rpc_parity_test.dart`, `sales_payment_rpc_parity_test.dart` (nhóm `old`)

- [ ] **0.1** Hằng đầu vào / mong đợi dùng chung `old` / `new`: `tenantId = 'tenant-1'`, `actorId = 'user-1'`, `storeId = 'store-1'`, `queryId = '00000000-0000-4000-8000-000000000001'`, `commandId = '00000000-0000-4000-8000-000000000002'`; 2 dòng (1 dòng `unitPrice: null` + `manualUnitPriceMinor`, 1 dòng có `manualDiscountBasisPoints`), 2 khoản thu (tiền mặt, chuyển khoản có `reference`), khách có `taxCode`, `invoiceEmail`; một biến thể khách `null`. JSON mẫu lấy từ `supabase_sales_order_read_gateway_test.dart` / `supabase_sales_order_inquiry_gateway_test.dart` / `supabase_checkout_gateway_test.dart` (nếu có) hoặc dựng theo cột "Tham số" mục 3.
- [ ] **0.2** Nhóm `old`: `CheckoutPrecheckRpcMapper.{precheckParams,finalizeParams,statusParams}(<command / query cũ>)`, `SalesOrderReadRpcMapper.{getSalesOrderParams,paymentSummaryParams}`, `SalesOrderInquiryRpcMapper.{settlementParams,transactionsParams}` → `equals(expected…)`; các `*FromJson` → `expect…`; 2 `parse_rejects_*` → `throwsFormatException`. Lỗi: bảng C5 / C7 qua `SupabaseCheckoutGateway`, `SupabaseSalesOrderReadGateway` với `IRpcClient` giả ném `RpcException`; validator C3 qua `FinalizeSalesOrderCommandValidator().validate(…)`.
- [ ] **0.3** Chạy trên code hiện tại:
  ```bash
  cd apps/erp && flutter test test/features/sales/data/sales_checkout_rpc_parity_test.dart \
    test/features/sales/data/sales_payment_rpc_parity_test.dart \
    test/features/sales/presentation_module/bloc/sales_checkout_cubit_test.dart \
    test/features/sales/presentation_module/bloc/sales_transaction_result_cubit_test.dart \
    test/features/sales/presentation_module/bloc/sales_order_detail_cubit_test.dart \
    test/features/sales/sales_transaction_result_page_test.dart test/features/sales/sales_order_detail_page_test.dart \
    test/features/sales/presentation/sales_checkout_page_test.dart test/features/sales/sales_flow_pages_test.dart \
    test/features/sales/group_d_finalize_contract_test.dart test/features/sales/group_e_result_receipt_contract_test.dart
  ```
  Expected: PASS. Ghi số test từng tệp.

### Task 1: Lỗi + câu lỗi

**Files:**
- Create: `apps/erp/lib/features/sales/data/sales_rpc_errors.dart`, `sales_checkout_errors.dart`, `sales_order_read_errors.dart`; `apps/erp/lib/features/sales/logic/sales_checkout_error_messages.dart`
- Modify: `apps/erp/lib/features/sales/data/sales_draft_errors.dart` (gọi `unwrapNestedSalesRpcError`)
- Test: `apps/erp/test/features/sales/data/sales_checkout_errors_test.dart`, `sales_order_read_errors_test.dart`; `apps/erp/test/features/sales/logic/sales_checkout_error_messages_test.dart`

**Produces:** `unwrapNestedSalesRpcError`, `SalesCheckoutErrorCodes`, `salesCheckoutException(Object, {bool uncertainOnNetwork})`, `salesOrderReadException(Object)`, `salesCheckoutErrorMessage(...)` (chữ ký mục 4.1, 4.4).

- [ ] **1.1** `sales_checkout_errors_test.dart` — bảng đầu vào → mã (`new`; cột `old` chạy qua gateway cũ):

  | Đầu vào | `new` | `old` |
  |---|---|---|
  | `PostgrestException(message: '{"code":"CHECKOUT_BLOCKED","message":"x"}')` | `CHECKOUT_BLOCKED`, `serverMessage` giữ | `CHECKOUT_BLOCKED` |
  | `{"code":"PERMISSION_DENIED"}` | `NO_PERMISSION` | `PERMISSION_DENIED` |
  | 10 mã còn lại của 12 mã | giữ | giữ |
  | `{"code":"NOT_FOUND"}` | `SYSTEM_ERROR` | `DEPENDENCY_UNAVAILABLE` |
  | `PostgrestException(message: 'boom')` | `SYSTEM_ERROR` | `DEPENDENCY_UNAVAILABLE` |
  | `AppException('NETWORK_ERROR')` | `NETWORK_ERROR` | — |
  | `AppException('NETWORK_ERROR')` với `uncertainOnNetwork: true`, `TimeoutException('t')` với `uncertainOnNetwork: true` | `UNCERTAIN_RESULT` | `UNCERTAIN_RESULT` (chỉ timeout) |
  | `FormatException('x')`, `StateError('x')` | `SYSTEM_ERROR` | — |
  | `AppException('CONTEXT_INVALID', serverMessage: 'Checkout line quantity must be positive.')` | giữ nguyên | — |
  | JSON lồng 2 lớp `{"message":"{\"code\":\"STALE_VERSION\"}"}` | `STALE_VERSION` | `STALE_VERSION` |
- [ ] **1.2** `sales_order_read_errors_test.dart`: cùng dạng cho 6 mã + `NETWORK_ERROR`; `{"code":"STALE_DATA"}` → `SYSTEM_ERROR`.
- [ ] **1.3** `sales_checkout_error_messages_test.dart`: 8 mã → đúng câu bảng 4.4; `overrides: {'NO_PERMISSION': 'A'}` → `'A'`; `AppException('SYSTEM_ERROR')`, `AppException('X', serverMessage: 'raw')`, `StateError('x')` với `fallback: 'F'` → `'F'`.
- [ ] **1.4** Chạy 3 test + `sales_draft_errors_test.dart` → FAIL (3 tệp mới thiếu nguồn). Viết 4 tệp + sửa `sales_draft_errors.dart`. Chạy lại → PASS (kể cả `sales_draft_errors_test.dart` không đổi).

### Task 2: Rule đầu vào

**Files:**
- Create: `apps/erp/lib/features/sales/logic/sales_checkout_rules.dart`
- Test: `apps/erp/test/features/sales/logic/sales_checkout_rules_test.dart`

**Consumes:** `SalesCheckoutErrorCodes` (Task 1). **Produces:** `checkFinalize(...)` (mục 4.2).

- [ ] **2.1** Test: 1 ca hợp lệ + 1 ca cho **mỗi** điều kiện (thứ tự kiểm theo validator: ca có hai lỗi một lúc cho ra lỗi của điều kiện đứng trước) → `throwsA(isA<AppException>().having((e) => e.code, 'code', 'CONTEXT_INVALID').having((e) => e.serverMessage, 'msg', '<câu cũ>'))`. Biên: `quantityMicros: 0`; khoản thu `amountMinor: 0`; `payloadHash: ' '`; `correlationId: ''`; khoản thu có `currencyCode: ' '`.
- [ ] **2.2** Nhóm `old` trong cùng tệp: các ca lỗi qua `FinalizeSalesOrderCommandValidator().validate(FinalizeSalesOrderCommand(…))` → `SalesContractException` cùng `code` + `message` (ca `tenantId` / `actorId` rỗng chỉ có ở `old` — ghi chú "bỏ, repository không nhận").
- [ ] **2.3** Chạy → FAIL. Viết. Chạy → PASS.

### Task 3: JSON + 3 repository + fake

**Files:**
- Create: `apps/erp/lib/features/sales/data/models/sales_finalize_request.dart`, `data/mappers/sales_checkout_json.dart`, `data/mappers/sales_payment_json.dart`, `data/mappers/sales_order_get_json.dart`, `data/sales_checkout_repository.dart`, `data/sales_payment_repository.dart`, `data/sales_order_repository.dart`
- Test: nhóm `new` trong `sales_checkout_rpc_parity_test.dart`, `sales_payment_rpc_parity_test.dart`; `apps/erp/test/features/sales/data/sales_checkout_repository_test.dart`, `sales_payment_repository_test.dart`, `sales_order_repository_test.dart`
- Create: `apps/erp/test/features/sales/support/fake_sales_checkout_repository.dart`, `fake_sales_payment_repository.dart`, `fake_sales_order_repository.dart`

**Consumes:** Task 1–2; `SupabaseRpc.call(String schema, String fn, {Map<String, dynamic>? params})`.
**Produces:** chữ ký mục 4.3; fake `implements` tương ứng, ghi lại tham số: `FakeSalesCheckoutRepository` (`precheckCalls`, `finalizeCalls`, `getResultCalls`; `precheckResult`, `onFinalize`/`finalizeResults` (hàng đợi kết quả), `getResultResults` (hàng đợi), `Object? precheckError / finalizeError / getResultError`), `FakeSalesPaymentRepository` (`summaryCalls`, `settlementCalls`, `transactionsCalls`; kết quả + `Object? …Error`), `FakeSalesOrderRepository` (`getCalls`, `result`, `error`) — Task 4 dùng.

- [ ] **3.1** Parity `new`: `_RecordingRpc implements SupabaseRpc` (mẫu `test/features/sales/data/sales_draft_rpc_parity_test.dart`) ghi `(schema, fn, params)`; mỗi method → `schema == 'sales'`, `fn` đúng, `params` bằng hằng 0.1 (`newId` cố định); kết quả qua `expect…`; `parse_rejects_*` → `AppException` `SYSTEM_ERROR`.
- [ ] **3.2** Repository test: `finalize_rule_blocks_before_rpc`, `finalize_calls_only_finalize_rpc` (C4), `finalize_blocked_result_carries_server_code`, `finalize_network_error_is_uncertain` (RPC giả ném `AppException('NETWORK_ERROR')` → `UNCERTAIN_RESULT`), `precheck_network_error_stays_network`, `tenant_actor_read_each_call` (mỗi repository), `settlement_sends_unprefixed_keys` (`params.keys` không chứa `p_query_id`), `transactions_default_page_size_25`, `summary_omits_expected_version_when_null`, `get_order_has_no_expected_version_key`, `no_client_permission_check` (RPC ném `PERMISSION_DENIED` → `NO_PERMISSION`, đúng 1 lần gọi).
- [ ] **3.3** Chạy → FAIL. Viết các tệp. Chạy `flutter test test/features/sales/data/` → PASS.

### Task 4: Đổi nơi gọi + chuyển `logic/` + DI

**Files:**
- Move (`git mv`; đổi import tương đối → `package:erp/...`): `presentation/bloc/sales_order/sales_checkout_cubit.dart`, `sales_checkout_state.dart`, `sales_transaction_result_cubit.dart`, `sales_transaction_result_state.dart`, `sales_transaction_result_issue.dart` → `lib/features/sales/logic/`; `presentation/orchestration/sales_checkout_orchestrator.dart` → `lib/features/sales/logic/`
- Modify: `lib/features/sales/presentation.dart` (export đường mới); `logic/sales_checkout_cubit.dart` (cũ `:11-45`, `:224-260`, `:306-355`, `:364-369`, `:385-400`, `:461-473`); `logic/sales_transaction_result_cubit.dart` (cũ `:16-50`, `:125-140`, `:218-240`, `:300-303`); `logic/sales_checkout_orchestrator.dart` (cũ `:16`, `:52-70`); `presentation/support/sales_checkout_attempt_factory.dart` (cũ `:81-100`: dựng `SalesFinalizeRequest`); `presentation/models/sales_order/sales_checkout_attempt_envelope.dart` (`command` → `request`); `presentation/support/sales_transaction_result_mapper.dart` (nhánh `AppException`, 4.4); `presentation/bloc/sales_order/sales_order_detail_sections_loader.dart` (cũ `:13-30`, `:196-232`, `:356-375`, `:397-410`); `presentation/bloc/sales_order/sales_order_detail_cubit.dart` (`:22-52`, `:334`, `:351`: nhận và chuyển `SalesPaymentRepository`); `presentation/pages/sales_checkout_page.dart:34-40`, `sales_transaction_result_page.dart:30-42`, `sales_order_detail_page.dart:37-42` (lấy repository từ `GetIt`); `lib/core/di/injection.dart` (đăng ký 3 repository như `SalesDraftRepository`, dùng cùng closure `tenantId` / `actorId`)
- Test (đổi fake, giữ điều kiện kiểm): 8 tệp ở mục 3 + `group_d_finalize_contract_test.dart` (C13), `group_e_result_receipt_contract_test.dart`

**Consumes:** 3 repository + 3 fake (Task 3), `salesCheckoutErrorMessage` (Task 1).

- [ ] **4.1** `gitnexus impact` upstream cho `SalesCheckoutCubit`, `SalesTransactionResultCubit`, `SalesCheckoutOrchestrator`, `SalesCheckoutAttemptFactory`, `SalesCheckoutAttemptEnvelope`, `SalesOrderDetailSectionsLoader`, `SalesOrderDetailCubit`, `SalesTransactionResultMapper`. Ghi số + số đo thật bằng `git grep`.
- [ ] **4.2** Viết test mới (FAIL trên code hiện tại): C9 × 4, C10, C11 × 9, C12 × 3 (bảng mục 5).
- [ ] **4.3** `SalesCheckoutAttemptFactory` + envelope: dựng `SalesFinalizeRequest` (`commandId: attemptId`, `idempotencyKey: 'checkout:$attemptId'`, các trường còn lại như `FinalizeSalesOrderCommand` cũ, **không** `tenantId` / `actorId`); test factory có sẵn (nếu có, `grep -rn "SalesCheckoutAttemptFactory" test`) giữ nguyên `payloadHash` mong đợi.
- [ ] **4.4** `SalesCheckoutCubit`, `SalesCheckoutOrchestrator` theo 4.5. Đổi `SalesContractException` → `AppException` ở mọi `on`/`is`; câu theo 4.4. Giữ mọi `emit`, `requestRevision`, lùi dần.
- [ ] **4.5** `SalesTransactionResultCubit` theo 4.5; kiểm `_executionContext` còn dùng cho biên nhận không (`grep -n "_executionContext" logic/sales_transaction_result_cubit.dart`); bỏ nếu không còn. `SalesTransactionResultMapper.issueFor` thêm nhánh `AppException`.
- [ ] **4.6** `SalesOrderDetailSectionsLoader` + `SalesOrderDetailCubit` + trang: `loadPayment` (3 query song song) và trang giao dịch tiếp theo gọi `paymentRepository.getSummary / getSettlement / getTransactions(cursor:)`; `_sectionFailure` đọc mã từ cả `AppException` và `SalesContractException` (4.4). `tenantId` / `actorId` còn truyền cho phần lịch sử / thao tác (không đổi).
- [ ] **4.7** `injection.dart`: `registerLazySingleton<SalesCheckoutRepository>(…)`, `<SalesPaymentRepository>`, `<SalesOrderRepository>` với `rpc: getIt<SupabaseRpc>()`, `tenantId: () => getIt<SessionController>().requireTenantId()`, `actorId: () async => sessionStore.userId ?? (throw const AppException(AppErrorCode.authRequired))` (cùng cách đăng ký `SalesDraftRepository`). `ISalesModule` giữ (8-A3, 8-A4 còn dùng).
- [ ] **4.8** Đổi fake trong các tệp test: đăng ký / truyền `FakeSalesCheckoutRepository`, `FakeSalesPaymentRepository`, `FakeSalesOrderRepository`; `salesModule.commands.whereType<FinalizeSalesOrderCommand>()` → `fakeCheckout.finalizeCalls`; `SalesContractException('X', message: …)` → `AppException('X', serverMessage: …)`; `ISalesModule` giả của test chỉ còn phần tra cứu / phiếu / huỷ / đổi-trả. Không đổi `expect` nào ngoài tên nguồn dữ liệu và ca mới / siết ở 4.2. `group_d_finalize_contract_test.dart`: đường dẫn cubit mới + chuỗi mới (C13).
- [ ] **4.9** Chạy lệnh 0.3 (đổi đường dẫn test đã di chuyển) + `flutter test test/features/sales/logic test/features/sales/data` → PASS.

### Task 5: Kiểm toàn bộ + tài liệu + Kết quả

**Files:** Modify: `docs/refactor/PLAN.md` (dòng 8-A2: cột Làm ✅ + ngày), `docs/02-yeu-cau/TH-05-ban-hang-va-don-hang.md` (Q6 đã chốt đổi; FR-03 đã đúng sẵn nên không sửa. Chỉ ghi vào 7.3 nếu bảng có mục phù hợp)

- [ ] **5.1** `cd apps/erp && dart analyze lib/features/sales lib/core/di test/features/sales` → 0 lỗi, 0 cảnh báo mới.
- [ ] **5.2** `git grep -nE "FinalizeSalesOrderCommand|PrecheckSalesOrderCheckoutQuery|GetCheckoutResultQuery|GetSalesOrderQuery|GetSalesOrderPaymentSummaryQuery|GetSalesOrderSettlementQuery|GetSalesOrderPaymentTransactionsQuery" -- apps/erp/lib` → rỗng (hoặc chỉ chú thích); `git grep -n "vet45_sales" -- apps/erp/lib/features/sales/data apps/erp/lib/features/sales/logic` → chỉ `application.dart` (kiểu DTO, Q1 của 8-A1).
- [ ] **5.3** `dart run tool/check_feature_imports.dart` → liệt kê dòng mới; chấp nhận cùng loại với 8-A1 (logic → presentation, data → `vet45_sales_*`, để 8-C), ghi từng dòng vào Kết quả.
- [ ] **5.4** `flutter test` cả app → số lỗi đúng bằng `docs/refactor/TEST-BASELINE.md` (so từng tên; 8-A1 đã ghi 2 ca catalog lỗi có sẵn ngoài baseline).
- [ ] **5.5** `node .gitnexus/run.cjs analyze` rồi `detect_changes({scope: "all"})`: chỉ tệp trong danh sách; ghi số tệp / symbol / luồng / rủi ro. Hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu `analyze` sửa.
- [ ] **5.6** PLAN.md dòng 8-A2: cột Làm ✅ + ngày. Không `dart format` cả thư mục `test/` (8-A1 R-format): chỉ định dạng tệp của plan.

## 7. Kiểm tra

Tự động: Task 5. **Kiểm tay (người dùng, iPhone simulator + Chrome):** (1) bán thường Khách lẻ, tiền mặt có tiền thừa → "Hoàn tất" → màn kết quả có tổng tiền, thanh toán; (2) bán nợ khách A trả 40%, chọn ngày hẹn → kết quả hiện còn phải thu; (3) bấm "Thanh toán" khi sản phẩm vừa ngừng bán → bị chặn, ở lại màn soạn với câu của precheck; (4) tắt mạng ngay lúc bấm "Xác nhận hoàn tất" → "Đang kiểm tra kết quả…" rồi kết quả thật, **không** tạo đơn thứ hai (xác nhận Q6); (5) mở chi tiết đơn → khối thanh toán, bảng giao dịch, "Tải thêm" nếu > 25 giao dịch.

## 8. Rủi ro / lưu ý

- **Q6 đổi hành vi có chủ đích (đã chốt 2026-11-07)** (mất mạng khi hoàn tất → khôi phục thay vì báo thất bại). Rủi ro nếu không đổi: khách bị trừ tiền, đơn đã ghi, nhân viên thấy "thất bại" và bán lại → đơn trùng. Đây là lỗi code cũ so với FR-03 / BR-27, không phải đổi nghiệp vụ.
- **Q3 `blockedCode`:** `blocked` giờ có `blockedCode` của server khi bị chặn ở bước precheck bên trong `finalize`; cubit hiện hiển thị câu riêng cho `PRICE_CHANGED` / `PRICING_BLOCKED`, các mã chặn khác không câu (`attemptErrorMessage: null`) — như cũ khi server chặn. 8-B (KI-02/03/04) thêm mã mới (`CUSTOMER_INVALID`, ngày hẹn) cần thêm câu ở `_classifyResult`.
- **Kiểu module còn trong `data/`** (8-A1 Q1): 8-C chép thêm `CheckoutLineInput`, `PaymentIntentInput`, `SalesCommercialSnapshotInput`, `CheckoutPrecheckDto`, `CheckoutResultDto`, `CheckoutResultStatus`, `SalesBlockerDto`, `CheckoutMonetarySummaryDto`, `ReceivableRequirementDto`, `SalesOrderResultDto`, `SalesOrderDto`, `SalesOrderPaymentSummaryDto`, `SalesOrderSettlementDto`, `SalesPaymentTransactionsDto`, `SalesPaymentTransactionDto` và enum đi kèm.
- **Hai kiểu lỗi cùng lúc** tới 8-A4: thanh toán / checkout / get_sales_order `AppException`; phần còn lại của màn chi tiết (lịch sử, thao tác, huỷ, phiếu) `SalesContractException`. `_sectionFailure` và `SalesTransactionResultMapper` chấp nhận cả hai; 8-A3 / 8-A4 bỏ nhánh `SalesContractException`.
- **Mất kiểm client `recordPayment`** (Q7) khi `paymentIntents` không rỗng: dựa vào server; test SQL của 8-B / TH-05 9.3 đã phủ.
- **`IExecutionContext` còn trong 2 cubit** (Q8) — 8-C bỏ cùng `CoreExecutionContext`.
- **8-B nhận thêm:** KI-02/03/04, `recordPayment` (màn Thu tiền, KI-06), câu cho mã chặn mới.

### Review Focus (chưa task nào test, phiên review soi)

1. **Khoá có / không `p_`:** `get_sales_order_settlement` / `get_sales_order_payment_transactions` dùng khoá trần (`query_id`…) còn 3 RPC kia dùng `p_*`; chép nhầm tiền tố ⇒ RPC trả lỗi "function does not exist" (PostgREST khớp theo tên tham số). Có test `settlement_sends_unprefixed_keys`; kiểm bằng tay mục 7 (5).
2. **`p_query_id` kiểu `text` vs `uuid`:** settlement / transactions khai báo `text`, 3 RPC kia `uuid`; `newId()` luôn sinh UUID v4 hợp lệ cho cả hai.
3. **`payloadHash` không đổi:** factory vẫn băm `tenantId` / `actorId` / `correlationId` (Q8). Thêm/bớt trường trong `payload` ⇒ hash khác ⇒ server so với lần gửi trước cùng key báo `IDEMPOTENCY_CONFLICT`; test factory phải còn pass nguyên văn.
4. **Ngày hẹn có múi giờ:** `paymentDueDate` luôn qua `_dateOnly` (cắt giờ theo giờ máy) — đừng đổi sang `toUtc()` (lệch ngày).
5. **`NETWORK_ERROR` ở nhiều chỗ:** `precheck` mất mạng phải hiện câu "Chưa thể kiểm tra điều kiện thanh toán. Vui lòng thử lại." (không phải `fallback`); `getResult` mất mạng trong `_recoverAttempt` phải thử tiếp, không dừng.

## 9. Kết quả (phiên làm code ghi)

**Task 0 (bước 0).** Test có sẵn chạy trên code cũ, xanh: `sales_checkout_cubit_test` 20 · `sales_transaction_result_cubit_test` 27 · `sales_order_detail_cubit_test` 44 · `sales_transaction_result_page_test` 4 · `sales_order_detail_page_test` 22 · `sales_checkout_page_test` 21 · `sales_flow_pages_test` 28 · `group_d_finalize_contract_test` 1 · `group_e_result_receipt_contract_test` 2. Nhóm `old` của parity chạy trên module trong cùng tệp với nhóm `new` (viết cùng lúc, cả hai xanh): `sales_checkout_rpc_parity_test` 22 (11 old + 11 new), `sales_payment_rpc_parity_test` 16 (8 + 8), `sales_checkout_errors_test`, `sales_order_read_errors_test`, `sales_checkout_rules_test` (old = validator cũ).

**Task 1–3 (data).** Tệp mới dưới `apps/erp/lib/features/sales/data/`: `sales_rpc_errors.dart` (`unwrapNestedSalesRpcError`, tách từ `sales_draft_errors.dart`; test 8-A1 xanh nguyên), `sales_checkout_errors.dart`, `sales_order_read_errors.dart`, `models/sales_finalize_request.dart`, `mappers/{sales_checkout_json,sales_payment_json,sales_order_get_json}.dart`, `sales_checkout_repository.dart`, `sales_payment_repository.dart`, `sales_order_repository.dart`. `logic/`: `sales_checkout_rules.dart`, `sales_checkout_error_messages.dart`. Fake: `test/features/sales/support/fake_sales_{checkout,payment,order}_repository.dart`.

**Task 4 (nơi gọi).** `git mv` vào `logic/`: `sales_checkout_{cubit,state}`, `sales_transaction_result_{cubit,state,issue}`, `sales_checkout_orchestrator`. Sửa: `sales_checkout_attempt_factory.dart` + envelope (`command` → `request`, `payloadHash` không đổi — test factory xanh nguyên văn), `sales_transaction_result_mapper.dart` (nhánh `AppException`), `sales_order_detail_sections_loader.dart` + `sales_order_detail_cubit.dart` (nhận `SalesPaymentRepository`; `_sectionFailure` đọc mã cả hai kiểu lỗi, `AppException` không mang `serverMessage`), 3 trang, `injection.dart` (3 repository), `presentation.dart`.

**Lệch plan (Ruling).**
- R1 — Test cũ có fake `ISalesModule` lớn (`sales_order_detail_cubit_test`, 2 page test, `sales_transaction_result_cubit_test`, `sales_flow_pages_test`, `sales_checkout_page_test`, `sales_transaction_result_body_test`) **không** đổi sang `FakeSales*Repository` mà dùng cầu nối `test/features/sales/support/module_backed_sales_repositories.dart` (repository giả gọi vào đúng fake module đó, đổi `SalesContractException` → `AppException`, `PERMISSION_DENIED` → `NO_PERMISSION`). Lý do: giữ nguyên mọi `expect` về thứ tự / số lần gọi / hàng đợi phản hồi (plan 4.8 "không đổi expect nào ngoài tên nguồn dữ liệu"). Hai nơi dùng `FakeSalesCheckoutRepository`: `sales_checkout_cubit_test` (viết lại hoàn toàn). Cầu nối xoá cùng module ở 8-C. Nếu sai: test cầu nối cần viết lại khi xoá module.
- R2 — `sales_checkout_page_test`: bỏ 2 `expect` `precheck.tenantId` / `actorId` (nay repository tự lấy, không đi qua orchestrator; Q8). Có test `tenant_actor_read_each_call` thay thế.
- R3 — `sales_order_detail_cubit_test`: `paymentErrorMessage` `'pay down'` → `isNull` (Q4, đổi có chủ đích).
- R4 — `SalesTransactionResultCubit` giữ `salesModule` + `executionContext` (chỉ truyền cho `SalesReceiptOperationHandler`, còn dùng tới 8-A3); bỏ các field `_salesModule` / `_executionContext` và bước `requireTenantId` đầu `load()`.
- R5 — `loadPayment` / `loadMoreTransactions` giữ tham số `tenantId` / `actorId` (không dùng nữa) để không đụng caller; dọn ở 8-A4.
- R6 — Không chạy `gitnexus impact` / `detect_changes` (công cụ MCP không có trong phiên này); phạm vi đo bằng `git grep` / `git status`: sửa ~22 tệp `lib`, 13 tệp test, thêm 11 tệp `lib` + 8 tệp test. Cần chạy `node .gitnexus/run.cjs analyze` + `detect_changes` trước khi commit (CLAUDE.md).

**Test mới / siết.** C9 ×4 + `precheck_network_error_shows_dependency_message` + `finalize_network_error_recovers_via_get_checkout_result` + `recover_keeps_trying_on_network_error` (cubit checkout 27 test); C11 `issue_for_app_exception_*` ×12; C12 ×3 (`sales_order_detail_cubit_test` 47); repository: `finalize_rule_blocks_before_rpc`, `finalize_calls_only_finalize_rpc`, `finalize_blocked_result_carries_server_code`, `finalize_network_error_is_uncertain`, `precheck_network_error_stays_network`, `tenant_actor_read_each_call`, `settlement_sends_unprefixed_keys`, `transactions_default_page_size_25`, `summary_omits_expected_version_when_null`, `get_order_has_no_expected_version_key`, `no_client_permission_check`. `group_d_finalize_contract_test`: `repository.finalize` / `repository.getResult`.

**Kiểm toàn bộ (Task 5).**
- 5.1 `dart analyze lib/features/sales lib/core/di test/features/sales`: 0 error; warning còn lại là `order_einvoice_section_test` (có sẵn, không đụng).
- 5.2 `git grep` 7 kiểu command/query cũ trong `apps/erp/lib`: rỗng.
- 5.3 `check_feature_imports`: dòng mới cùng loại 8-A1: `logic/sales_checkout_cubit.dart` (5), `logic/sales_checkout_state.dart` (2), `logic/sales_transaction_result_{cubit (3),state (2)}` → `presentation/…` (R2, để 8-W/8-C); `data/sales_checkout_repository.dart` → `logic/sales_checkout_rules.dart` (R1, cùng mẫu `sales_draft_repository`).
- 5.4 `flutter test` cả app: **2578 đạt / 55 lỗi**, 0 lỗi trong `features/sales`; 55 = mốc sau 6-C (53 + 2 ⚠️ catalog đã ghi).
- 5.5 chưa chạy (xem R6). 5.6 PLAN.md dòng 8-A2: Làm ✅ 2026-11-07.

## 10. Review

### R1 — 2026-11-07: **ĐẠT** (1 câu hỏi cho người dùng, không chặn)

| Hạng mục | Kết quả |
|---|---|
| Phạm vi (mục 1, Q1–Q10) | Đủ: 3 repository, `SalesFinalizeRequest`, rule finalize, 2 hàm lỗi + câu lỗi, 6 tệp chuyển `logic/`, DI, 3 trang. Không đụng `modules/sales`, RPC, migration |
| `flutter test test/features/sales` | 929 đạt / 0 lỗi |
| `flutter test` cả app | **2578 đạt / 55 lỗi** — khớp Kết quả. 55 = 53 trong mốc `apps/erp` + 2 ⚠️ catalog đã ghi (`duplicate SKU`, `product change history`); 0 lỗi `sales` |
| `dart analyze lib/features/sales lib/core/di test/features/sales` | 0 error; 1 warning có sẵn (`order_einvoice_section_test.dart:32`), còn lại info `deprecated_member_use` có sẵn |
| 5.2 `git grep` 7 kiểu command/query cũ trong `apps/erp/lib` | rỗng |
| 5.3 `check_feature_imports` | đúng như Kết quả: `logic/` → `presentation/` (R2), `data/sales_checkout_repository.dart:5` → `logic/sales_checkout_rules.dart` (R1, cùng mẫu 8-A1) |
| Parity `old` / `new` | dùng chung `sales_checkout_parity_expectations.dart`; phần đọc JSON của `new` kiểm ngay trong các test `params_*` (gọi repository → `expect…(dto)`), có `nextCursor` / `hasMore` |
| Test cũ bị sửa | Không mất test nào (chỉ đổi tên 2 test); `expect` bỏ đi đều có bản thay theo nguồn mới (`precheckCalls` / `finalizeCalls` / `getResultCalls`, `module.reads` / `readArgs`), trừ R2, R3 đã ghi |
| Review Focus 1–5 | (1) settlement / transactions khoá trần, `expected_source_version` luôn có — có test; (2) `newId` = UUID v4; (3) `payloadHash` không đổi — test factory xanh; (4) ngày hẹn vẫn qua `DateTime(y, m, d)` ở cubit; (5) precheck `NETWORK_ERROR` → câu "Chưa thể kiểm tra…", `_recoverAttempt` bỏ qua `NETWORK_ERROR` — có test |

**Impact / detect_changes (phiên review chạy thay R6).** Kết quả R6 ghi "công cụ không có" — thực ra CLI có sẵn: `node .gitnexus/run.cjs impact <symbol> --direction upstream --repo erp-sales-inventory` và `detect-changes --repo erp-sales-inventory --scope all` (phải truyền `--repo` vì máy có 2 index). Index cũ (`380142d`), đủ để đo người gọi trước khi sửa:

| Symbol | Rủi ro | Trực tiếp | Tổng | Luồng |
|---|---|---|---|---|
| `SalesCheckoutCubit` | MEDIUM | 2 | 45 | 0 |
| `SalesTransactionResultCubit` | MEDIUM | 4 | 47 | 0 |
| `SalesCheckoutOrchestrator` | LOW | 1 | 8 | 0 |
| `SalesCheckoutAttemptFactory` | MEDIUM | 3 | 46 | 0 |
| `SalesCheckoutAttemptEnvelope` | **HIGH** | 7 | 53 | 0 |
| `SalesOrderDetailSectionsLoader` | **HIGH** | 3 | 52 | 1 |
| `SalesOrderDetailCubit` | MEDIUM | 3 | 46 | 0 |
| `SalesTransactionResultMapper` | MEDIUM | 4 | 50 | 0 |

2 HIGH đã đo thật: 7 người gọi trực tiếp của envelope là `presentation.dart`, factory, checkout state / cubit (IMPORTS + `copyWith`) — đều đã sửa; `git grep "\.command"` còn lại chỉ là attempt của huỷ / đổi-trả (kiểu khác). Loader: 3 người gọi (`post_sale_actions` import, `SalesOrderDetailCubit` import + `_sectionsLoader`) — đã sửa, test chi tiết đơn 47 xanh. `detect-changes`: 39 tệp, 44 symbol, **0 luồng**, rủi ro **low** (tệp mới chưa tính). Vẫn chạy `node .gitnexus/run.cjs analyze` + `detect_changes` lại trước khi commit.

**Câu hỏi cho người dùng (Q-R1).** Câu cho `CHECKOUT_BLOCKED` ở 4.4 ghi "theo TH-05 6.4" là "Đơn chưa đủ điều kiện thanh toán." nhưng TH-05 6.4 (dòng 2157) ghi **"Đơn bị chặn khi hoàn tất" + lý do**. Code làm đúng plan đã duyệt; câu đang dùng là câu cũ của app (`sales_checkout_page.dart:190`, orchestrator `:72`). Chọn: (a) giữ câu hiện tại, sửa TH-05 6.4 khi sửa spec; (b) đổi `sales_checkout_error_messages.dart:12` theo spec (lý do: chỉ có khi lấy từ `blockers` của precheck, `AppException` không mang câu hiển thị được) → thành task R1-1. **Người dùng chốt 2026-11-07: (a)** — đã sửa TH-05 6.4 dòng `CHECKOUT_BLOCKED` thành "Đơn chưa đủ điều kiện thanh toán." (lý do cụ thể lấy từ `blockers` của precheck nếu có); code giữ nguyên. Câu riêng theo từng mã chặn làm ở 8-B (`_classifyResult`).

**Ghi nhận nhỏ (không cần sửa):**
- Kết quả không ghi tệp:dòng theo từng việc và bảng impact (mẫu "Kết quả"); phiên review đã bổ sung bảng impact ở trên.
- `SalesCheckoutOrchestrator` vẫn đọc `tenantId` / `actorId` từ `IExecutionContext` — còn dùng để kiểm người bán (`sellerProfile.userId == actorId`), đúng.
- `SalesTransactionResultCubit` bỏ bước `requireTenantId` đầu `load()`: thiếu phiên giờ ra `SYSTEM_ERROR` → `transportFailure`, như cũ (cũ: lỗi khác `SalesContractException` → `transportFailure`).
- Tệp plan còn chưa commit (`??`): commit trước rồi mới xoá theo quy ước, nếu không sẽ không tra lại được bằng `git show`.
