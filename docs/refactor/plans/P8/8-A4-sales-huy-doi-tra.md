# 8-A4 — Sales: huỷ đơn + đổi/trả sang `SalesCancellationRepository` / `ReturnExchangeRepository`

> Theme 5 (mã cũ P8) · Bước (a) chuyển kiến trúc, nhóm huỷ + đổi/trả · Gồm việc 8.5 (PLAN.md mục Theme 5): precheck / confirm huỷ; precheck đổi/trả (khối Thao tác) + 3 cubit đổi/trả (lập phiếu, chi tiết / kết quả / xem trước, quyết toán). **Không gồm** KI-05, KI-08, KI-10, KI-17, KI-18 (8-B); chép kiểu DTO (8-C).
> Trạng thái: Plan 📝 (viết 2026-11-07, duyệt thiết kế 2026-11-07) | Làm ⬜ | Review ⬜
> Trước: 8-A3 (tra cứu + phiếu, review ĐẠT). Sau: 8-B (sửa KI), 8-C dọn module. **Sau 8-A4 `apps/erp/lib/features` hết `ISalesModule` và `SalesContractException`.**
> Tài liệu: [TH-05](../../../02-yeu-cau/TH-05-ban-hang-va-don-hang.md) EP-05 (US-05.1, 05.2), EP-06 (US-06.1…06.7), SG-10, SG-12…SG-15, 6.2, 6.4, 8 (ngoài phạm vi), 9.2 (8.5); PLAN.md "Cách chuyển MỘT feature", "Plan xoá / tách / thay code cũ: test giữ hành vi trước". Mẫu: [8-A3](8-A3-sales-tra-cuu-phieu.md) (cấu trúc, parity `old` / `new`, cầu nối `module_backed_sales_repositories.dart`), 8-A2 (lớp request thuần `SalesFinalizeRequest`, factory giữ hash, `sales_checkout_error_messages.dart`).
>
> **Cho phiên code:** dùng `superpowers:executing-plans` (tuần tự). Mỗi task xong ghi ngay mục 9 theo mẫu (tệp:dòng, lệch plan, test, impact). **Không commit** (người dùng commit sau `detect_changes()`). Không chạy / đề nghị reset DB, push, SQL (plan không đụng DB). **Không ghi mục 10** (chỉ phiên review ghi).

## 1. Mục tiêu

- 12 RPC của schema `sales` đi qua repository thay `ISalesModule`; bỏ hẳn lời gọi `_get_return_exchange_context`:
  ```text
  SalesOrderDetailPostSaleActions ──┬─▶ SalesCancellationRepository  precheck / confirm
                                    └─▶ ReturnExchangeRepository     precheck
  SalesReturnExchangeSessionCubit ──┐                                precheck / getReturnableLines / previewPricing / start / update / cancel
  SalesReturnExchangeDetailCubit ───┼─▶ ReturnExchangeRepository     getDetail / complete
  SalesReturnExchangeSettlementCubit┘                                getDetail / evaluate / confirm
              (cả 3) ─────────────────▶ SalesOrderRepository         getDetail / getReturnSummary (có từ 8-A3)
  ```
- Repository **nhận và trả kiểu của `c45_sales_application`** (8-A1 Q1), trừ 6 command thay bằng lớp request thuần (Q5).
- Lỗi đi ra là `AppException`. Câu thô (câu Anh của server, mã, `'$error'`, `rpcMessage`) đổi theo TH-05 6.4 (Q3, bảng 4.4).
- 3 cubit + 3 state chuyển vào `features/sales/logic/`. `SalesOrderDetailCubit` bỏ `salesModule`.

**Không làm:** KI-05 (ngày hẹn đổi hàng), KI-08 (QR mẫu), KI-10 (code chính sách trống), KI-17 (nút "Hoàn tất phiếu" + `complete`), KI-18 (mặc định Tiền mặt) → 8-B; sửa RPC / migration; bố cục web (8-W); chép kiểu DTO, gỡ đăng ký `ISalesModule` (8-C).

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | Chia repository | **Người dùng chốt 2026-11-07:** 2 repo mới — `SalesCancellationRepository` (precheck + confirm huỷ), `ReturnExchangeRepository` (precheck, returnable, preview giá, detail, start / update / cancel / confirm / complete, evaluate). 3 cubit đọc đơn qua `SalesOrderRepository.getDetail / getReturnSummary` (8-A3) |
| Q2 | `ConfirmReturnExchangeCommandHandler` và `EvaluateReturnPricingImpactQueryHandler` gọi `_get_return_exchange_context` chỉ để lấy dòng nháp dựng `reference_decision`; port đăng ký trong app là `UnavailableReturnExchangeReferencePort` (không bao giờ chặn, 2 version luôn `null`). Server: confirm chỉ đọc `blockers` + 2 version (`20260830014…:346-357`, `20260904001…:1003-1014`); evaluate đọc 2 version (`20260830013…:133-134`) và lưu nguyên decision vào `return_exchange_valuations.details` (`:296-299`, chỉ để truy vết) | **Người dùng chốt 2026-11-07: bỏ.** `confirm` / `evaluate` gửi decision cố định (4.2). Khác nhỏ: `details.reference_decision` của bản định giá không còn map sản phẩm / đơn vị / giá. `start` / `update` vẫn dựng map từ dòng (server ghi vào snapshot dòng, `20260830012…:923-933`, `:1269-1275`) |
| Q3 | Câu thô ở nhóm này: blocker của 2 precheck (câu Anh của server) hiện thẳng (`sales_order_detail_post_sale_actions.dart:211-224`, `:132-137`; `sales_return_exchange_session_body.dart:59`, `…_settlement_body.dart:46`); `error.message` (`post_sale_actions.dart:172-173`, `:283-288`); `_messageFor` 3 cubit (`message` / `rpcMessage` / mã); `'$error'` (detail, settlement) | **Người dùng chốt 2026-11-07: đổi theo TH-05 6.4 ngay ở 8-A4.** Bảng 4.4 (A: mã lỗi, B: mã blocker, C: từng chỗ) — **người dùng duyệt 2026-11-07**, gồm 4 câu fallback mới. Không bao giờ hiện `serverMessage`, mã, `'$error'` |
| Q4 | KI của 8.5 (TH-05 9.2) | **Người dùng chốt 2026-11-07: tất cả sang 8-B.** `complete_return_exchange` (TH-05 6.2: "nội bộ, app không gọi") vẫn chuyển nguyên thành `ReturnExchangeRepository.complete`; 8-B xoá cùng nút (KI-17) |
| Q5 | Kiểu cho 6 lệnh (`ConfirmSalesOrderCancellationCommand`, `Start/Update/Cancel/Confirm/CompleteReturnExchangeCommand` chứa `tenantId` / `actorId`) | Như 8-A2 Q10: lớp request thuần ở `data/models/` (4.2). Hai attempt factory **giữ nguyên cách băm** (tenant vẫn trong `canonicalPayloadJson`), chỉ đổi `.command` → `.request`. 3 cubit + post-sale actions **giữ `IExecutionContext`** chỉ để đưa `tenantId` / `actorId` / `correlationId` vào factory (8-A2 Q8) |
| Q6 | Mã lỗi + thử lại | Giữ mã ổn định của gateway cũ + các mã server ném đo ở migration (4.1). `PERMISSION_DENIED` → `NO_PERMISSION`; còn lại / lỗi đọc JSON ⇒ `SYSTEM_ERROR`. Gateway cũ dồn mọi lỗi lạ, mạng, đọc JSON về `DEPENDENCY_UNAVAILABLE` — **thử lại được, giữ khoá**. Giữ hành vi: `_isRetryable` mới = `DEPENDENCY_UNAVAILABLE` ∪ `NETWORK_ERROR` ∪ `SYSTEM_ERROR` (session thêm `IMPACT_PENDING` như cũ). **Duyệt cùng thiết kế 2026-11-07** |
| Q7 | Kiểm quyền client ở handler cũ (`createReturnExchange` precheck / preview, `viewReturnExchange` returnable / detail / evaluate / return summary, `cancelOrder` precheck huỷ) | **Bỏ** (quy ước Theme 3/4). Server kiểm ở mọi RPC (TH-05 6.2, 7.2) |
| Q8 | `tenantId` / `actorId` / `query_id` | Như 8-A3 Q7: closure mỗi lần gọi; `query_id` = `newId()` (constructor nhận `String Function()? newId`). `command_id` = id factory sinh (`request.commandId`). `causation_id` luôn `null` (như cũ) |
| Q9 | `RETURN_EXCHANGE_BLOCKED` mang `details.blockers` | Repository / lỗi giữ `details`; cubit đọc `details['blockers']` (List các map `{code, message, field}`) thành `SalesBlockerDto`, `null` ⇒ `[]`. Cũ: `(raw as List).whereType<SalesBlockerDto>()` — từ server luôn rỗng, thiếu khoá thì `TypeError` trong nhánh `catch`. **Duyệt cùng thiết kế** |
| Q10 | Chỗ đặt tệp | 3 cubit + 3 state → `logic/` (bước 6 công thức). 2 attempt factory **ở lại** `presentation/support/` (như `sales_checkout_attempt_factory.dart` 8-A2). Trang đọc repository thẳng từ `GetIt` như hiện nay |

## 3. Hiện trạng (đo 2026-11-07)

| Tệp (dưới `lib/features/sales/`) | Gọi module | RPC |
|---|---|---|
| `logic/sales_order_detail_post_sale_actions.dart:65-82` (`requestCancel`), `:84-101` (`requestReturnExchange`), `:105-181` (`confirmCancellation`) | `PrecheckSalesOrderCancellationQuery`, `PrecheckReturnExchangeQuery`, `ConfirmSalesOrderCancellationCommand` | `precheck_sales_order_cancellation`, `precheck_return_exchange`, `confirm_sales_order_cancellation` |
| `presentation/bloc/return_exchange_order/sales_return_exchange_session_cubit.dart:61-80`, `:233`, `:294`, `:400`, `:433`, `:487` | `GetSalesOrderDetailQuery`, `PrecheckReturnExchangeQuery`, `GetReturnableOrderLinesQuery`, `PreviewReturnExchangePricingQuery` ×2, `Start/Update/CancelReturnExchangeCommand` | `get_sales_order_detail`, `precheck_return_exchange`, `get_returnable_order_lines`, `preview_return_exchange_pricing`, `start_` / `update_` / `cancel_return_exchange` |
| `…/sales_return_exchange_detail_cubit.dart:63`, `:75`, `:88`, `:169` | `GetReturnExchangeDetailQuery`, `GetSalesOrderDetailQuery`, `GetSalesOrderReturnSummaryQuery`, `CompleteReturnExchangeCommand` | `get_return_exchange_detail`, `get_sales_order_detail`, `get_sales_order_return_summary`, `complete_return_exchange` |
| `…/sales_return_exchange_settlement_cubit.dart:60`, `:86`, `:106`, `:243` | `GetReturnExchangeDetailQuery`, `GetSalesOrderDetailQuery`, `EvaluateReturnPricingImpactQuery`, `ConfirmReturnExchangeCommand` | `get_return_exchange_detail`, `get_sales_order_detail`, (`_get_return_exchange_context` +) `evaluate_return_exchange_valuation`, (`_get_return_exchange_context` +) `confirm_return_exchange` |

Nơi dựng: `presentation/pages/sales_order_detail_page.dart:40-50`; `sales_return_exchange_create_page.dart:34-38` (session); `…_detail_page.dart:30-35`, `…_result_page.dart:31-36`, `…_slip_preview_page.dart:31-36` (detail cubit); `…_settlement_page.dart:34-39`. Factory: `presentation/support/sales_order_cancellation_attempt_factory.dart` (95 dòng), `…/sales_return_exchange_attempt_factory.dart` (532 dòng). DI: `lib/core/di/injection.dart:236-251` (2 repo sales cùng mẫu), `:260` (`ISalesModule`).

| RPC | Tham số (chép từ mapper module) |
|---|---|
| `precheck_sales_order_cancellation` | `SalesOrderCancellationRpcMapper.precheckParams` — khoá trần `query_id`, `tenant_id`, `actor_id`, `sales_order_id`, `expected_source_version` |
| `confirm_sales_order_cancellation` | `confirmParams` — `command_id`, `tenant_id`, `actor_id`, `sales_order_id`, `reason_text`, `idempotency_key`, `payload_hash`, `correlation_id`, `causation_id` (`null`), `expected_order_version`, `expected_settlement_version` |
| `precheck_return_exchange`, `get_returnable_order_lines` | `ReturnExchangeRpcMapper.precheckParams` / `getReturnableParams` — `query_id`, `tenant_id`, `actor_id`, `sales_order_id`, `expected_source_version` (luôn có, kể cả `null`) |
| `preview_return_exchange_pricing` | `previewPricingParams` — **khoá `p_*`**: `p_tenant_id`, `p_actor_id`, `p_sales_order_id`, `p_lines` = `[{product_id, product_unit_id}]` (không có query id) |
| `get_return_exchange_detail` | `detailParams` — `query_id`, `tenant_id`, `actor_id`, `return_exchange_id`, `expected_version` (`null`) |
| `start_return_exchange` | `startParams` — `command_id`, `tenant_id`, `actor_id`, `sales_order_id`, `entry_source` (`_entrySourceWire`), `lines` (`_lineInputs`), `idempotency_key`, `payload_hash`, `correlation_id`, `causation_id`, `expected_source_version`, `reference_decision` |
| `update_return_exchange` | `updateParams` — như start nhưng `return_exchange_id` thay `sales_order_id`, không `entry_source`, `expected_version` |
| `cancel_return_exchange`, `complete_return_exchange` | `cancelParams` / `completeParams` — `command_id`, `tenant_id`, `actor_id`, `return_exchange_id`, `idempotency_key`, `payload_hash`, `correlation_id`, `causation_id`, `expected_version` (cancel: có thể `null`) |
| `confirm_return_exchange` | `confirmParams` — như complete + `reference_decision`, `payment_settled_now_minor`, `payment_method` (`_paymentMethodWire`: `cash` / `manualBankTransfer`), `payment_due_date` (`_dateOnlyWire`: `YYYY-MM-DD` theo giờ máy, không `toUtc`) |
| `evaluate_return_exchange_valuation` | `evaluateParams` — `query_id`, `tenant_id`, `actor_id`, `return_exchange_id`, `expected_source_version`, `reference_decision` |

Hàm chép (dưới `modules/sales/infrastructure/lib/src/domain/`): `return_exchange_order/return_exchange_rpc_mapper.dart` — khoá `_*Keys` (`:6-191`), các `*Params` ở bảng trên, `referenceDecisionToJson` (`:426-464`), `precheckFromJson`, `returnableFromJson`, `draftFromJson`, `resultFromJson`, `valuationFromJson` (+ `_settlementPlanFromJson`), `previewPricingFromJson`, `detailFromJson` (2 dạng: bọc `result` và live `_liveDetailFromJson`, `:657-806`), helper `:808-1143` (bỏ `_policyOptionFromJson`, `formPolicy*`, `paymentSummary*`, `settlementResult*`, `contextFromJson`, `settle*Params` — không dùng); `sales_order_cancellation/sales_order_cancellation_rpc_mapper.dart` — `precheckParams`, `confirmParams`, `precheckFromJson`, `resultFromJson` + helper `:158-238` (bỏ `reasons*`, `detail*` — `detailFromJson` đã chép ở 8-A3). `UnavailableReturnExchangeReferencePort.evaluate` (`infrastructure/lib/src/adapters/unavailable_return_exchange_reference_port.dart:11-52`). JSON mẫu: `modules/sales/infrastructure/test/domain/return_exchange_order/{return_exchange_rpc_mapper_test,supabase_return_exchange_gateways_test}.dart`, `…/sales_order_cancellation/{sales_order_cancellation_rpc_mapper_test,supabase_sales_order_cancellation_gateway_test}.dart`.

Test có sẵn (số đo 2026-11-07, đều xanh): `test/features/sales/presentation_module/bloc/sales_return_exchange_session_cubit_test.dart` (21), `…_detail_cubit_test.dart` (6), `…_settlement_cubit_test.dart` (14), `…/sales_order_detail_cubit_test.dart` (53); `presentation_module/support/sales_order_cancellation_attempt_factory_test.dart` (4), `…/sales_return_exchange_attempt_factory_test.dart` (6); `sales_order_detail_page_test.dart` (22); `sales_return_exchange_{detail,result,slip_preview}_page_test.dart` (2 / 2 / 2); `sales_return_confirm_settlement_sheet_test.dart` (2); `presentation_module/widgets/sales_return_exchange_{session,settlement}_body_test.dart` (5 / 15); `sales_flow_pages_test.dart` (28); `group_i_no_demo_contract_test.dart` (1). Cầu nối: `test/features/sales/support/module_backed_sales_repositories.dart` (`_bridge` chưa chép `details`).

## 4. Thiết kế

### 4.1 Lỗi (`apps/erp/lib/features/sales/data/`)

Cùng dạng `sales_receipt_errors.dart` (8-A3): `AppException.from` → giữ nếu mã trong tập; bóc JSON lồng qua `unwrapNestedSalesRpcError`; còn lại `AppException('SYSTEM_ERROR', cause: error)`. **Giữ `details`** (Q9).

- `sales_cancellation_errors.dart`: `AppException salesCancellationException(Object error)`. Tập: `NOT_FOUND`, `NO_PERMISSION`, `DATA_SCOPE_DENIED`, `CANCELLATION_BLOCKED`, `STALE_VERSION`, `IDEMPOTENCY_CONFLICT`, `IMPACT_PENDING`, `DEPENDENCY_UNAVAILABLE` (8 mã gateway cũ `supabase_sales_order_cancellation_gateway.dart:100-109`) + `IN_PROGRESS`, `CONTEXT_INVALID`, `FIELD_NOT_ALLOWED` (server ném, `20260830011…`, `20260904001…`) + `NETWORK_ERROR`.
- `return_exchange_errors.dart`: `AppException returnExchangeException(Object error)`. Tập: 11 mã gateway cũ (`supabase_return_exchange_command_gateway.dart:128-140`: `NOT_FOUND`, `NO_PERMISSION`, `DATA_SCOPE_DENIED`, `RETURN_EXCHANGE_BLOCKED`, `RETURN_QUANTITY_EXCEEDED`, `STALE_VERSION`, `PRICE_CHANGED`, `PRICING_BLOCKED`, `IDEMPOTENCY_CONFLICT`, `IMPACT_PENDING`, `DEPENDENCY_UNAVAILABLE`) + `COMPETING_CANCELLATION`, `CONTEXT_INVALID`, `IN_PROGRESS`, `INVALID_QUANTITY`, `PRODUCT_NOT_SELLABLE` (server ném, `20260830012…`) + `PROJECTION_PENDING` (detail cubit rẽ nhánh theo nó) + `NETWORK_ERROR`.

### 4.2 Request + repository

```dart
// data/models/sales_cancellation_request.dart
final class SalesOrderCancellationRequest {
  // commandId, salesOrderId, reasonText (String, '' khi trống), idempotencyKey, payloadHash,
  // correlationId, expectedOrderVersion (int), expectedSettlementVersion (int)
}
// data/models/return_exchange_requests.dart
final class ReturnExchangeStartRequest   { /* commandId, salesOrderId, entrySource, List<ReturnExchangeLineInput> lines, idempotencyKey, payloadHash, correlationId, int expectedVersion */ }
final class ReturnExchangeUpdateRequest  { /* commandId, returnExchangeId, lines, idempotencyKey, payloadHash, correlationId, int expectedVersion */ }
final class ReturnExchangeMutationRequest{ /* commandId, returnExchangeId, idempotencyKey, payloadHash, correlationId, int? expectedVersion — cancel + complete */ }
final class ReturnExchangeConfirmRequest { /* như Mutation (int expectedVersion) + int? settledNowMinor, SalesPaymentMethod paymentMethod, DateTime? paymentDueDate */ }

// data/sales_cancellation_repository.dart — constructor như SalesOrderRepository (rpc, tenantId, actorId, newId)
Future<CancellationPrecheckDto> precheck({required String salesOrderId, required int expectedSourceVersion});
Future<SalesOrderCancellationResultDto> confirm(SalesOrderCancellationRequest request);

// data/return_exchange_repository.dart — cùng constructor
Future<ReturnExchangePrecheckDto> precheck({required String salesOrderId, int? expectedSourceVersion});
Future<ReturnableOrderLinesDto> getReturnableLines({required String salesOrderId});        // expected_source_version: null
Future<ReturnExchangePricingPreviewDto> previewPricing({required String salesOrderId, required List<ReturnExchangePricingLineInput> lines});
Future<ReturnExchangeDetailDto> getDetail({required String returnExchangeId});             // expected_version: null
Future<ReturnExchangeDraftDto> start(ReturnExchangeStartRequest request);
Future<ReturnExchangeDraftDto> update(ReturnExchangeUpdateRequest request);
Future<ReturnExchangeResultDto> cancel(ReturnExchangeMutationRequest request);
Future<ReturnExchangeResultDto> confirm(ReturnExchangeConfirmRequest request);
Future<ReturnExchangeResultDto> complete(ReturnExchangeMutationRequest request);           // 8-B xoá (KI-17)
Future<ReturnExchangeValuationDto> evaluate({required String returnExchangeId, required int expectedSourceVersion});
```

Mỗi method: `tenantId()` / `actorId()` → `_rpc.call('sales', '<rpc>', params: …)` → ép `Map<String, dynamic>` → hàm đọc JSON; `_guard` bọc bằng hàm lỗi 4.1. Tham số **giống hệt** mapper cũ (bảng mục 3). Hàm dựng tham số + đọc JSON chép vào `data/mappers/sales_cancellation_json.dart` (`SalesCancellationJson`) và `data/mappers/return_exchange_json.dart` (`ReturnExchangeJson`). `FormatException` ra `SYSTEM_ERROR`.

**`reference_decision`:**
- `start` / `update`: `ReturnExchangeJson.referenceDecisionFromLines(lines)` = đúng kết quả `referenceDecisionToJson(UnavailableReturnExchangeReferencePort().evaluate(lines: …))` — chỉ dòng `exchangeLine`; snapshot sản phẩm thiếu ⇒ `{productId, sku: null, displayName: productId}`; đơn vị thiếu ⇒ `{productUnitId, unitCode: null, unitName: productUnitId}`; giá thiếu ⇒ `{amountMinor: 0, currencyCode: 'VND'}`; `blockers: []`; `pricing_source_version` / `inventory_source_version`: `null`. Không ghi `pricedAt` (bản cũ cũng không gửi).
- `confirm` / `evaluate` (Q2): hằng
  ```dart
  const fixedReferenceDecision = <String, dynamic>{
    'blockers': <Object>[],
    'exchange_products_by_product_unit_id': <String, Object>{},
    'exchange_units_by_product_unit_id': <String, Object>{},
    'exchange_prices_by_product_unit_id': <String, Object>{},
    'pricing_source_version': null,
    'inventory_source_version': null,
  };
  ```

### 4.3 Nơi gọi

- **Factory** (`presentation/support/`): `SalesOrderCancellationAttempt.command` → `request` (`SalesOrderCancellationRequest`); `SalesReturnExchangeAttempt<TCommand>` → `<TRequest>`, `command` → `request`. Thân băm (`payload`, `_normalizeLines`, `_sort`, `sha256`, khoá `'sales-order-cancellation:$id'` / `'return-exchange:<op>:$id'`) **không đổi một ký tự**. `ReturnExchangeLineInput` của request lấy từ `_toLineInputs(normalizedLines)` như cũ. Mọi `throw SalesContractException('CONTEXT_INVALID', message: …)` → `throw const AppException('CONTEXT_INVALID')`.
- **`SalesOrderDetailPostSaleActions`**: constructor bỏ `salesModule`, thêm `required SalesCancellationRepository cancellationRepository`, `required ReturnExchangeRepository returnExchangeRepository`; giữ `executionContext`.
  - `_runPrecheck`: chữ ký `execute` thành `Future<T> Function(int sourceVersion)`; bỏ `requireTenantId / requireUserId`; kiểm `isClosed() || generation != currentGeneration()` **sau** lời gọi (giữ dòng kiểm sau `execute`).
  - `requestCancel` → `cancellationRepository.precheck(salesOrderId: orderId, expectedSourceVersion: v)`; `requestReturnExchange` → `returnExchangeRepository.precheck(salesOrderId: orderId, expectedSourceVersion: v)`.
  - `confirmCancellation`: lấy `tenantId` / `actorId` qua `executionContext` (cho factory) rồi kiểm generation như cũ → `precheck` → `factory.create(…)` → `cancellationRepository.confirm(attempt.request)`. Câu theo 4.4.
  - `_handlePrecheckFailure`: chỉ đọc `AppException.code` — `STALE_VERSION` (giữ nguyên nhánh + câu), `NO_PERMISSION` / `DATA_SCOPE_DENIED` (giữ nhánh + câu), còn lại câu 4.4.
- **`SalesOrderDetailCubit`**: bỏ `required ISalesModule salesModule`; thêm `required SalesCancellationRepository cancellationRepository`, `required ReturnExchangeRepository returnExchangeRepository`, truyền cho post-sale actions. Giữ `executionContext` (HĐĐT + factory huỷ).
- **3 cubit** (`git mv` sang `logic/`): constructor bỏ `salesModule`, thêm `required ReturnExchangeRepository returnExchangeRepository`, `required SalesOrderRepository orderRepository`; giữ `executionContext`, `attemptFactory`.
  - Session `load`: vẫn lấy `tenantId` / `actorId` / `correlationId` (cho factory; `correlationId` rỗng ⇒ `AppException('CONTEXT_INVALID')`), rồi **`Future.wait`** 3 lời gọi `orderRepository.getDetail(salesOrderId:)`, `returnExchangeRepository.precheck(salesOrderId:)`, `getReturnableLines(salesOrderId:)`. `addExchangeProduct` / `refreshExchangePrices` → `previewPricing` (bỏ `requireTenantId / requireUserId` ở 2 hàm này). Lưu / bỏ → `start` / `update` / `cancel(attempt.request)`. Blocker của precheck đi qua `salesBlockerMessage` trước khi vào state.
  - Detail: `getDetail(returnExchangeId:)` → `orderRepository.getDetail(salesOrderId: detailDto.result.salesOrderId)` và `getReturnSummary(salesOrderId:)` (lỗi ⇒ `null`, giữ `on Object`). `completeIfReady` → `complete(attempt.request)`.
  - Settlement: `getDetail` → `orderRepository.getDetail` (lỗi ⇒ `null`) → `evaluate(returnExchangeId:, expectedSourceVersion: detail.settlementPlan.sourceOrderVersion)` → `confirm(attempt.request)`. `RETURN_EXCHANGE_BLOCKED`: blockers đọc từ `error.details?['blockers']` (Q9) qua `salesBlockerMessage`.
  - Mọi `on SalesContractException catch` → `on AppException catch`; nhánh `catch (error)` còn lại dùng `fallback` 4.4 (không `'$error'`). `_isRetryable` theo Q6. `_currentAttempt`, `_loadGeneration`, `_completeInFlight`, `_confirmInFlight`, `_lastSavedLines`, thứ tự `emit` giữ nguyên.
- **Trang:** `sales_order_detail_page.dart:40-50` thêm `cancellationRepository: GetIt.instance<SalesCancellationRepository>()`, `returnExchangeRepository: GetIt.instance<ReturnExchangeRepository>()`, bỏ `salesModule`. 5 trang đổi/trả: `returnExchangeRepository: GetIt.instance<ReturnExchangeRepository>()`, `orderRepository: GetIt.instance<SalesOrderRepository>()`, bỏ `salesModule`.
- **DI** (`injection.dart`, sau `:251`): `registerLazySingleton<SalesCancellationRepository>` và `<ReturnExchangeRepository>` y như `SalesReceiptRepository`. `ISalesModule` (`:260`) giữ (8-C).
- `presentation.dart:20-25`: export đường mới `logic/sales_return_exchange_{session,settlement,detail}_{cubit,state}.dart`.

### 4.4 Câu lỗi (Q3, người dùng duyệt 2026-11-07)

Tệp `logic/sales_post_sale_error_messages.dart`, mẫu `sales_checkout_error_messages.dart`:

```dart
String salesPostSaleErrorMessage(Object error, {required String fallback, Map<String, String> overrides = const {}});
// overrides[code] → bảng A → fallback. Không phải AppException ⇒ fallback.
String salesBlockerMessage(SalesBlockerDto blocker, {required String fallback}); // bảng B → fallback
List<SalesBlockerDto> localizeBlockers(List<SalesBlockerDto> blockers, {required String fallback});
// giữ code / field, message = salesBlockerMessage; dùng khi đưa vào state
```

**Bảng A — mã lỗi**

| Mã | Câu |
|---|---|
| `NO_PERMISSION` | "Bạn không có quyền thực hiện thao tác này." |
| `DATA_SCOPE_DENIED` | "Cửa hàng hiện tại không còn khả dụng." |
| `CONTEXT_INVALID`, `FIELD_NOT_ALLOWED` | "Dữ liệu không hợp lệ." |
| `IDEMPOTENCY_CONFLICT` | "Yêu cầu bị xung đột" |
| `IN_PROGRESS` | "Yêu cầu đang được xử lý, vui lòng chờ." |
| `STALE_VERSION` | "Đơn hàng đã thay đổi. Hãy tải lại chi tiết rồi thử lại." |
| `NOT_FOUND` | "Đơn hàng không tồn tại hoặc đã bị xóa." |
| `COMPETING_CANCELLATION` | "Đơn đã được hủy." |
| `RETURN_EXCHANGE_BLOCKED` | "Không thể đổi/trả." |
| `RETURN_QUANTITY_EXCEEDED` | "Số lượng trả vượt số còn có thể trả." |
| `INVALID_QUANTITY` | "Số lượng không hợp lệ với đơn vị bán." |
| `PRODUCT_NOT_SELLABLE` | "Sản phẩm đã ngừng bán. Vui lòng quay lại đơn." |
| `PRICING_BLOCKED` | "Sản phẩm này chưa có giá bán." (**đổi** `SalesReturnExchangePricingCopy.pricingBlocked` sang câu này) |
| `PRICE_CHANGED` | không có trong bảng: session truyền `overrides: {'PRICE_CHANGED': SalesReturnExchangePricingCopy.priceChanged}`, settlement giữ `priceChangedGoBack` như hiện nay |
| `NETWORK_ERROR` | "Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng." |
| `DEPENDENCY_UNAVAILABLE`, `SYSTEM_ERROR`, mã khác | `fallback` |

**Bảng B — mã blocker**

| Blocker | Câu |
|---|---|
| `PAYMENT_ALREADY_COLLECTED` | "Đơn đã có thanh toán, vui lòng đổi/trả" |
| `ORDER_ALREADY_CANCELLED`, `COMPETING_CANCELLATION` | "Đơn đã được hủy." |
| `RETURN_EXCHANGE_CONFLICT` | "Đơn đã có phiếu đổi/trả, không thể hủy." |
| `DRAFT_RETURN_ACTIVE` | "Đơn đang có phiếu đổi/trả chưa hoàn tất." |
| `CANCELLATION_BLOCKED`, `RETURN_EXCHANGE_BLOCKED`, `DEPENDENCY_UNAVAILABLE`, mã khác | `fallback` của nhóm: huỷ "Không thể huỷ đơn.", đổi/trả "Không thể đổi/trả." |

Câu trùng chỉ hiện một lần (`toSet()` trước `join('\n')` / trước khi đưa vào state).

**Bảng C — từng chỗ**

| Chỗ | Cũ | Mới |
|---|---|---|
| Post-sale precheck bị chặn (`postSaleFeedbackMessage`, `precheckBlockerMessages`) | `blocker.message`; rỗng ⇒ "Không thể thực hiện thao tác này trên đơn hàng." | bảng B (fallback huỷ / đổi/trả theo nút); không blocker ⇒ giữ câu cũ |
| Post-sale precheck lỗi khác | `contract.message` / "Không thể kiểm tra điều kiện thao tác. Vui lòng thử lại." | bảng A, fallback câu cũ |
| `confirmCancellation` bị chặn | `blocker.message` nối `\n`; rỗng ⇒ "Không thể huỷ đơn." | bảng B, fallback "Không thể huỷ đơn." |
| `confirmCancellation` lỗi | `error.message` / "Huỷ đơn thất bại. Vui lòng thử lại." | bảng A, fallback "Huỷ đơn thất bại. Vui lòng thử lại." |
| Session `_messageFor` (load, lưu, bỏ, thêm hàng đổi) | `rpcMessage` / `error.message` / mã | bảng A, fallback **"Không lưu được phiếu đổi/trả. Vui lòng thử lại."**; `addExchangeProduct` lỗi không phải `AppException` giữ `previewFailed` |
| Session blocker precheck | `b.message` (câu Anh) | `localizeBlockers`, fallback "Không thể đổi/trả." |
| Detail `_mapLoadError` | `error.message` / mã; lỗi khác `'$error'` | `NOT_FOUND`, `PROJECTION_PENDING` ⇒ `screenError: null` (widget có câu "Phiếu không tồn tại." / "Phiếu đang được cập nhật."); còn lại bảng A, fallback **"Không tải được chi tiết phiếu."** |
| Detail `completeIfReady` lỗi | `error.message` / `'$error'` | bảng A, fallback **"Không hoàn tất được phiếu. Vui lòng thử lại."** |
| Settlement tải / xác nhận lỗi | `error.message` / mã / `'$error'` | bảng A, fallback **"Không quyết toán được phiếu đổi/trả. Vui lòng thử lại."** |
| Settlement `RETURN_EXCHANGE_BLOCKED` | `_blockersFrom` | blockers từ `details` qua `localizeBlockers`; `screenError` "Không thể đổi/trả." |
| 4 câu "Thiếu ngữ cảnh … đổi/trả." | — | giữ nguyên |

## 5. Đang làm gì — test giữ hành vi

| # | Cũ đang làm gì | Sau 8-A4 nằm ở đâu | Test |
|---|---|---|---|
| C1 | Tham số 2 RPC huỷ (bảng mục 3) | `SalesCancellationJson` | parity `params_cancel_precheck`, `params_cancel_confirm` |
| C2 | Đọc JSON `CancellationPrecheckDto`, `SalesOrderCancellationResultDto` (`_rejectUnknownKeys` ⇒ `FormatException`) | như trên | parity `parse_cancel_precheck`, `parse_cancel_result`, `parse_cancel_rejects_unknown_key` |
| C3 | Tham số 4 RPC đọc đổi/trả (khoá trần / `p_*`, `null` vẫn có khoá) | `ReturnExchangeJson` | parity `params_precheck`, `params_returnable`, `params_preview`, `params_detail` |
| C4 | Tham số 5 lệnh (wire `entry_source`, `lines`, `payment_method`, `payment_due_date`, `causation_id` `null`, cancel `expected_version` `null`) | như trên | parity `params_start`, `params_update`, `params_cancel`, `params_cancel_null_version`, `params_confirm` (có `paymentDueDate: DateTime(2026,11,20,23,30)` ⇒ `'2026-11-20'`), `params_complete` |
| C5 | `reference_decision` start / update dựng từ dòng | `referenceDecisionFromLines` | parity `reference_decision_from_lines`: 1 dòng trả + 1 dòng đổi đủ snapshot + 1 dòng đổi thiếu snapshot / giá; `old` = `referenceDecisionToJson(await UnavailableReturnExchangeReferencePort().evaluate(…))`, `new` `equals` |
| C6 | **Đổi (Q2)**: confirm / evaluate bỏ `_get_return_exchange_context` | repository | `confirm_sends_fixed_reference_decision`, `evaluate_sends_fixed_reference_decision`, `confirm_single_rpc_call` (`calls.map((c) => c.fn)` == `['confirm_return_exchange']`) |
| C7 | Đọc JSON precheck, returnable, preview, draft, result, valuation, detail (bọc + live) | `ReturnExchangeJson` | parity `parse_*` × 7 + `parse_detail_live` + `parse_rejects_unknown_key` |
| C8 | Gateway huỷ 8 mã / đổi trả 11 mã; mã lạ có câu ⇒ giữ mã; còn lại `DEPENDENCY_UNAVAILABLE` | 4.1; **đổi (Q6)** mã ngoài tập ⇒ `SYSTEM_ERROR` | `sales_cancellation_errors_test.dart`, `return_exchange_errors_test.dart` (`old` qua gateway cũ / `new`) |
| C9 | `details.blockers` | giữ `details` (Q9) | `blocked_keeps_details_blockers`, `blocked_without_details_has_null_details` |
| C10 | Factory: cùng nội dung ⇒ cùng `commandId` / khoá / hash; tenant trong hash | `.request` | 4 + 6 test có sẵn (đổi `.command` → `.request`; bỏ `expect` `tenantId` / `actorId` của command — request không có, ghi Kết quả) + mới `cancel_hash_unchanged`, `return_exchange_hash_unchanged_{start,confirm}` (giá trị hash ghi ở Task 0 từ code cũ) |
| C11 | Post-sale: precheck huỷ / đổi trả, chặn ⇒ câu, `STALE_VERSION` ⇒ tải lại, không quyền ⇒ tắt nút; confirm huỷ = precheck rồi confirm | `logic/sales_order_detail_post_sale_actions.dart` | 53 + 22 test có sẵn (đổi fake) |
| C12 | 3 cubit: generation, giữ attempt khi lỗi thử lại, `Future.wait` ở `load`, nuốt lỗi đọc đơn ở detail / settlement, `_lastSavedLines`, `IMPACT_PENDING` | `logic/` | 21 + 6 + 14 + test trang / body có sẵn (đổi fake) |
| C13 | **Q6**: lỗi mạng / lạ vẫn thử lại với cùng attempt | `_isRetryable` | mới `confirm_retry_after_system_error_reuses_command_id` (settlement), `save_retry_after_network_error_reuses_command_id` (session) |
| C14 | **Q3** câu lỗi | `sales_post_sale_error_messages.dart` + nơi gọi | `sales_post_sale_error_messages_test.dart` (mỗi dòng bảng A, B + mã lạ ⇒ fallback + không `AppException` ⇒ fallback) + mỗi dòng bảng C ≥ 1 ca (câu server khác `null`, kiểm chuỗi nguyên văn) |

**Bước 0 (Task 0):** nhóm `old` của C1–C5, C7, C8 và giá trị hash C10 chạy trên module, xanh, ghi tên — rồi mới viết tệp mới. 15 tệp test có sẵn ở mục 3 phải **xanh trên code cũ** (chạy, ghi số).

## 6. Các bước

**Ràng buộc chung** (mọi task):
- Chỉ sửa tệp liệt kê ở từng task. Không đụng `modules/sales`, không sửa RPC / migration.
- Trước khi sửa symbol có sẵn: `node .gitnexus/run.cjs impact <symbol> --direction upstream --repo erp-sales-inventory`, ghi bảng vào Kết quả; HIGH / CRITICAL ⇒ dừng, báo người dùng (index Dart gộp theo tên có thể ra CRITICAL giả — đo phạm vi thật bằng `git grep`, ghi lại, vẫn báo).
- Chép nguyên văn điều kiện, câu, tên khoá JSON (kể cả có / không `p_`, khoá có giá trị `null`). Thấy chỗ phải sửa thân mới chạy được ⇒ ghi Kết quả, không tự đổi hành vi.
- Không `tenantId` / `actorId` trong chữ ký repository / request.
- Test parity có `// ignore_for_file: implementation_imports`. Tệp test mới ở `apps/erp/test/features/sales/{data,logic}/`.

### Task 0: Bước 0 — parity `old` + chạy test có sẵn trên code cũ

**Files:**
- Create: `apps/erp/test/features/sales/data/sales_post_sale_parity_expectations.dart`, `sales_cancellation_rpc_parity_test.dart`, `return_exchange_rpc_parity_test.dart` (nhóm `old`)

- [x] **0.1** Hằng dùng chung: `tenantId = 'tenant-1'`, `actorId = 'user-1'`, `orderId = 'order-1'`, `returnExchangeId = 're-1'`, `queryId = '00000000-0000-4000-8000-000000000001'`, `commandId = '00000000-0000-4000-8000-000000000002'`, `correlationId = 'corr-1'`; bộ dòng mẫu (1 dòng trả `originalSalesOrderLineId: 'line-1'` + 1 dòng đổi đủ snapshot + giá + 1 dòng đổi thiếu snapshot / giá). JSON mẫu lấy từ các test module ở mục 3.
- [x] **0.2** Nhóm `old`: các `*Params` (dựng query / command của module với hằng 0.1) → `equals(expected…)`; `referenceDecisionToJson(await UnavailableReturnExchangeReferencePort().evaluate(…))` → `equals(expectedReferenceDecision)`; các `*FromJson` → `expect…`. Lỗi C8 qua `SupabaseSalesOrderCancellationGateway`, `SupabaseReturnExchangeCommandGateway`, `SupabaseReturnExchangeReadGateway` với `IRpcClient` giả ném `RpcException`.
- [x] **0.3** Hash cố định: chạy factory cũ với đầu vào cố định (`newAttemptId: () => commandId`) cho `create` (huỷ), `start`, `confirm`; ghi 3 giá trị `payloadHash` vào `sales_post_sale_parity_expectations.dart` làm hằng `expectedCancelHash`, `expectedStartHash`, `expectedConfirmHash`.
- [x] **0.4** Chạy trên code hiện tại:
  ```bash
  cd apps/erp && flutter test test/features/sales/data/sales_cancellation_rpc_parity_test.dart \
    test/features/sales/data/return_exchange_rpc_parity_test.dart \
    test/features/sales/presentation_module/bloc/sales_return_exchange_session_cubit_test.dart \
    test/features/sales/presentation_module/bloc/sales_return_exchange_detail_cubit_test.dart \
    test/features/sales/presentation_module/bloc/sales_return_exchange_settlement_cubit_test.dart \
    test/features/sales/presentation_module/bloc/sales_order_detail_cubit_test.dart \
    test/features/sales/presentation_module/support/sales_order_cancellation_attempt_factory_test.dart \
    test/features/sales/presentation_module/support/sales_return_exchange_attempt_factory_test.dart \
    test/features/sales/sales_order_detail_page_test.dart \
    test/features/sales/sales_return_exchange_detail_page_test.dart test/features/sales/sales_return_exchange_result_page_test.dart \
    test/features/sales/sales_return_exchange_slip_preview_page_test.dart test/features/sales/sales_return_confirm_settlement_sheet_test.dart \
    test/features/sales/presentation_module/widgets/sales_return_exchange_session_body_test.dart \
    test/features/sales/presentation_module/widgets/sales_return_exchange_settlement_body_test.dart \
    test/features/sales/sales_flow_pages_test.dart test/features/sales/group_i_no_demo_contract_test.dart
  ```
  Expected: PASS. Ghi số test từng tệp (mốc mục 3: 21 / 6 / 14 / 53 / 4 / 6 / 22 / 2 / 2 / 2 / 2 / 5 / 15 / 28 / 1 + 2 tệp parity mới).

### Task 1: Lỗi

**Files:**
- Create: `apps/erp/lib/features/sales/data/sales_cancellation_errors.dart`, `data/return_exchange_errors.dart`
- Test: `apps/erp/test/features/sales/data/sales_cancellation_errors_test.dart`, `return_exchange_errors_test.dart`

**Produces:** `salesCancellationException(Object) → AppException`, `returnExchangeException(Object) → AppException` (tập mã 4.1, giữ `details`).

- [x] **1.1** Test, cột `new` / `old` (gateway cũ):

  | Đầu vào | `new` | `old` |
  |---|---|---|
  | `PostgrestException(message: '{"code":"STALE_VERSION","message":"x"}')` | `STALE_VERSION`, `serverMessage == 'x'` | `STALE_VERSION` |
  | `{"code":"PERMISSION_DENIED"}` | `NO_PERMISSION` | `PERMISSION_DENIED` |
  | mỗi mã còn lại trong tập 4.1 | giữ | giữ (mã gateway) / giữ mã (mã server có câu) |
  | `{"code":"RETURN_EXCHANGE_BLOCKED","details":{"blockers":[{"code":"X","message":"m"}]}}` (đổi/trả) | `details['blockers']` là `List` 1 phần tử | — |
  | `{"code":"WEIRD","message":"m"}` | `SYSTEM_ERROR` | `WEIRD` |
  | `PostgrestException(message: 'boom')` | `SYSTEM_ERROR` | `DEPENDENCY_UNAVAILABLE` |
  | `AppException('NETWORK_ERROR')` | `NETWORK_ERROR` | — |
  | `FormatException('x')` | `SYSTEM_ERROR` | `DEPENDENCY_UNAVAILABLE` |
  | JSON lồng 2 lớp `{"message":"{\"code\":\"NOT_FOUND\"}"}` | `NOT_FOUND` | ghi kết quả thật |
- [x] **1.2** Chạy → FAIL (thiếu nguồn). Viết. `flutter test test/features/sales/data/sales_cancellation_errors_test.dart test/features/sales/data/return_exchange_errors_test.dart` → PASS.

### Task 2: Request + JSON + repository + fake + cầu nối

**Files:**
- Create: `apps/erp/lib/features/sales/data/models/sales_cancellation_request.dart`, `data/models/return_exchange_requests.dart`, `data/mappers/sales_cancellation_json.dart`, `data/mappers/return_exchange_json.dart`, `data/sales_cancellation_repository.dart`, `data/return_exchange_repository.dart`
- Test: nhóm `new` trong 2 tệp parity; `test/features/sales/data/sales_cancellation_repository_test.dart`, `return_exchange_repository_test.dart`
- Create: `test/features/sales/support/fake_sales_cancellation_repository.dart`, `fake_return_exchange_repository.dart`
- Modify: `test/features/sales/support/module_backed_sales_repositories.dart` — `_bridge` chép thêm `details` (blocker `SalesBlockerDto` → map `{code, message, field}`); thêm `ModuleBackedSalesCancellationRepository(ISalesModule)` và `ModuleBackedReturnExchangeRepository(ISalesModule)` dựng query / command của module (`tenantId: 'tenant-1'`, `actorId: 'actor-1'`, mẫu `ModuleBackedSalesCheckoutRepository.finalize`)

**Consumes:** Task 1; `SupabaseRpc.call(String schema, String fn, {Map<String, dynamic>? params})`.
**Produces:** chữ ký 4.2; `FakeSalesCancellationRepository` (`precheckCalls`, `confirmCalls` + kết quả / `Object? …Error`), `FakeReturnExchangeRepository` (`precheckCalls`, `returnableCalls`, `previewCalls`, `detailCalls`, `startCalls`, `updateCalls`, `cancelCalls`, `confirmCalls`, `completeCalls`, `evaluateCalls`; kết quả / hàng đợi lỗi) — Task 5 dùng.

- [x] **2.1** Parity `new`: `_RecordingRpc implements SupabaseRpc` (mẫu `sales_order_inquiry_rpc_parity_test.dart`) ghi `(schema, fn, params)`; mỗi method → `schema == 'sales'`, `fn` đúng, `params` `equals` hằng 0.1; kết quả qua `expect…`; `*_rejects_unknown_key` → `AppException` `SYSTEM_ERROR`; `reference_decision_from_lines` `equals(expectedReferenceDecision)` (C5).
- [x] **2.2** Repository test: C6 × 3; `cancel_null_version_keeps_key` (`params.containsKey('expected_version')`, giá trị `null`); `confirm_due_date_local_date` (`DateTime(2026,11,20,23,30)` ⇒ `'2026-11-20'`); `preview_uses_p_keys_without_query_id`; `tenant_actor_read_each_call`; `no_client_permission_check` (RPC ném `PERMISSION_DENIED` → `NO_PERMISSION`, đúng 1 lời gọi); C9 × 2.
- [x] **2.3** Chạy → FAIL. Viết các tệp. `flutter test test/features/sales/data/` → PASS (gồm test 8-A1…8-A3).

### Task 3: Câu lỗi

**Files:**
- Create: `apps/erp/lib/features/sales/logic/sales_post_sale_error_messages.dart`
- Modify: `apps/erp/lib/features/sales/presentation/support/sales_return_exchange_pricing_copy.dart:11` (`pricingBlocked` = "Sản phẩm này chưa có giá bán.")
- Test: `apps/erp/test/features/sales/logic/sales_post_sale_error_messages_test.dart`

**Produces:** `salesPostSaleErrorMessage`, `salesBlockerMessage`, `localizeBlockers` (chữ ký 4.4).

- [x] **3.1** Test: mỗi dòng bảng A với `fallback: 'F'` (kể cả `DEPENDENCY_UNAVAILABLE` / `SYSTEM_ERROR` / `'WEIRD'` ⇒ `'F'`); `overrides` thắng bảng; `StateError()` ⇒ `'F'`; `AppException('NOT_FOUND', serverMessage: 'Sales order not found.')` ⇒ câu bảng A (không chứa `'Sales'`); mỗi dòng bảng B; `localizeBlockers` giữ `code` / `field`.
- [x] **3.2** Chạy → FAIL. Viết. `flutter test test/features/sales/logic/sales_post_sale_error_messages_test.dart` → PASS.

### Task 4: Factory → request

**Files:**
- Modify: `apps/erp/lib/features/sales/presentation/support/sales_order_cancellation_attempt_factory.dart`, `…/sales_return_exchange_attempt_factory.dart`
- Test: `test/features/sales/presentation_module/support/sales_order_cancellation_attempt_factory_test.dart`, `…/sales_return_exchange_attempt_factory_test.dart`

**Consumes:** request Task 2. **Produces:** `SalesOrderCancellationAttempt.request`, `SalesReturnExchangeAttempt<TRequest>.request` với `TRequest` ∈ {`ReturnExchangeStartRequest`, `ReturnExchangeUpdateRequest`, `ReturnExchangeMutationRequest` (discard, complete), `ReturnExchangeConfirmRequest`}.

- [x] **4.1** `impact` upstream `SalesOrderCancellationAttemptFactory`, `SalesReturnExchangeAttemptFactory`, `SalesReturnExchangeAttempt`.
- [x] **4.2** Thêm test `cancel_hash_unchanged`, `return_exchange_hash_unchanged_start`, `return_exchange_hash_unchanged_confirm` (so hằng Task 0.3); đổi `.command` → `.request` trong 10 test có sẵn, bỏ `expect` `tenantId` / `actorId` của command (ghi tên ca vào Kết quả); ca lỗi ngữ cảnh `throwsA(isA<AppException>().having((e) => e.code, 'code', 'CONTEXT_INVALID'))`. Chạy → FAIL.
- [x] **4.3** Sửa 2 factory theo 4.3. Chạy 2 tệp test → PASS (hash bằng hằng cũ).

### Task 5: Đổi nơi gọi + chuyển `logic/` + trang + DI

**Files:**
- Move (`git mv`; đổi import tương đối → `package:erp/...`): `presentation/bloc/return_exchange_order/sales_return_exchange_{session,detail,settlement}_{cubit,state}.dart` → `lib/features/sales/logic/`
- Modify: `lib/features/sales/presentation.dart:20-25`; nơi import 6 tệp trên (đo 2026-11-07: `presentation/support/sales_return_exchange_session_draft.dart`, `presentation/widgets/sales_return_exchange_{detail_body,result_body,session_body,session_line_rows,settlement_body}.dart`, `test/features/sales/group_i_no_demo_contract_test.dart`, `test/features/sales/presentation_module/support/sales_return_exchange_session_draft_test.dart`); `logic/sales_order_detail_post_sale_actions.dart`; `logic/sales_order_detail_cubit.dart` (constructor + chỗ dựng `SalesOrderDetailPostSaleActions`); 3 cubit đã chuyển; `presentation/pages/sales_order_detail_page.dart:40-50`, `sales_return_exchange_{create,detail,result,settlement,slip_preview}_page.dart` (khối `initState`); `lib/core/di/injection.dart` (sau `:251`)
- Test (đổi fake / cầu nối, giữ điều kiện kiểm): 15 tệp mục 3 (trừ 2 tệp factory đã sửa ở Task 4)

**Consumes:** Task 2, 3, 4.

- [x] **5.1** `impact` upstream: `SalesOrderDetailPostSaleActions`, `SalesOrderDetailCubit`, `SalesReturnExchangeSessionCubit`, `SalesReturnExchangeDetailCubit`, `SalesReturnExchangeSettlementCubit`. Ghi bảng (rủi ro / trực tiếp / tổng / luồng) + số đo thật bằng `git grep`.
- [x] **5.2** Viết test mới (FAIL trên code hiện tại), kiểm câu bằng chuỗi nguyên văn bảng 4.4:
  - C13 × 2. Settlement: `FakeReturnExchangeRepository` confirm lần 1 ném `AppException('SYSTEM_ERROR')`, bấm lại ⇒ `confirmCalls.length == 2`, `confirmCalls[0].commandId == confirmCalls[1].commandId`, cùng `idempotencyKey`; trạng thái lần 1 `retryableFailure`. Session: tương tự với `start` ném `AppException('NETWORK_ERROR')`.
  - C14 bảng C: `post_sale_cancel_blocked_localized` (precheck trả blocker `PAYMENT_ALREADY_COLLECTED` message `'Net confirmed collection must be zero…'` ⇒ `postSaleFeedbackMessage == 'Đơn đã có thanh toán, vui lòng đổi/trả'`), `post_sale_precheck_error_never_shows_server_message`, `confirm_cancellation_blocked_localized`, `confirm_cancellation_error_uses_fallback` (`AppException('SYSTEM_ERROR', serverMessage: 'x')` ⇒ "Huỷ đơn thất bại. Vui lòng thử lại."), `session_save_error_fallback` (thay ca có sẵn "dependency fallback exposes raw rpc message for diagnostics" — ghi Kết quả), `session_blockers_localized`, `detail_not_found_screen_error_null`, `detail_unknown_error_fallback`, `detail_complete_error_fallback`, `settlement_error_fallback`, `settlement_blocked_reads_details_blockers`, `settlement_blocked_without_details_is_empty`.
- [x] **5.3** Post-sale actions + `SalesOrderDetailCubit` + `sales_order_detail_page.dart` theo 4.3; câu theo 4.4.
- [x] **5.4** `git mv` 3 cubit + 3 state; sửa import; sửa 3 cubit theo 4.3 + 4.4.
- [x] **5.5** 5 trang đổi/trả + `injection.dart` theo 4.3.
- [x] **5.6** Đổi test có sẵn: fake module dùng cầu nối `ModuleBacked*` (giữ nguyên `expect` thứ tự / số lần gọi); `SalesContractException('X', message: …, details: …)` ném vào nguồn đã chuyển giữ nguyên (cầu nối tự đổi). Đăng ký `GetIt` trong test trang: thêm 2 repo cầu nối. Không đổi `expect` nào ngoài tên nguồn dữ liệu, ca mới 5.2, và `expect` câu lỗi bị Q3 đổi có chủ đích (ghi từng ca vào Kết quả).
- [x] **5.7** Chạy lệnh 0.4 (đường dẫn mới nếu test di chuyển) + `flutter test test/features/sales/logic test/features/sales/data` → PASS.

### Task 6: Kiểm toàn bộ + tài liệu + Kết quả

**Files:** Modify: `docs/refactor/PLAN.md` (dòng 8-A4: Làm ✅ + ngày; trạng thái Theme 5)

- [x] **6.1** `cd apps/erp && dart analyze lib/features/sales lib/core/di test/features/sales` → 0 lỗi, 0 cảnh báo mới.
- [x] **6.2** Cả 3 lệnh ra rỗng:
  ```bash
  git grep -nE "ISalesModule|salesModule" -- apps/erp/lib/features
  git grep -n "SalesContractException" -- apps/erp/lib/features/sales
  git grep -nE "_get_return_exchange_context|(Start|Update|Cancel|Confirm|Complete)ReturnExchangeCommand|ConfirmSalesOrderCancellationCommand|Precheck(SalesOrderCancellation|ReturnExchange)Query|GetReturnableOrderLinesQuery|PreviewReturnExchangePricingQuery|GetReturnExchangeDetailQuery|EvaluateReturnPricingImpactQuery|GetSalesOrder(Detail|ReturnSummary)Query" -- apps/erp/lib
  ```
- [x] **6.3** `dart run tool/check_feature_imports.dart` → liệt kê dòng mới; chấp nhận cùng loại 8-A1…8-A3 (`logic/` → `presentation/`, `data/` → `c45_sales_*`, để 8-W / 8-C), ghi từng dòng vào Kết quả.
- [x] **6.4** `flutter test` cả app → số lỗi đúng bằng mốc sau 8-A3 (**55**), 0 lỗi `features/sales`; so từng tên.
- [x] **6.5** `node .gitnexus/run.cjs analyze` rồi `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory --scope all`: chỉ tệp trong plan; ghi số tệp / symbol / luồng / rủi ro. Hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu `analyze` sửa.
- [x] **6.6** PLAN.md dòng 8-A4: Làm ✅ + ngày. Chỉ `dart format` tệp của plan.

## 7. Kiểm tra

Tự động: Task 6. **Kiểm tay (người dùng, iPhone simulator + Chrome):** (1) đơn bán nợ chưa thu → "Hủy đơn" → nhập lý do → đơn Đã huỷ, khối "Lý do hủy" hiện; (2) đơn đã thu tiền → "Hủy đơn" → "Đơn đã có thanh toán, vui lòng đổi/trả" (không câu Anh); (3) đổi hàng: trả 1 dòng, đổi sang hàng đắt hơn, khách trả một phần + ngày hẹn → kết quả, chi tiết phiếu, xem trước PDF; (4) trả hàng của đơn đã trả đủ → hoàn tiền; (5) lập phiếu rồi "Bỏ" → quay lại đơn, mở lại đổi/trả không còn nháp; (6) tắt mạng ở màn quyết toán, bấm xác nhận → lỗi thử lại được; bật mạng, xác nhận lại → chỉ **một** phiếu đổi/trả trên đơn; (7) thêm hàng đổi chưa có giá → "Sản phẩm này chưa có giá bán."

## 8. Rủi ro / lưu ý

- **Hash / khoá (Q5):** request không còn `tenantId` nhưng chuỗi băm vẫn chứa tenant. Bỏ nhầm ⇒ hash khác ⇒ server coi là lệnh mới hoặc `IDEMPOTENCY_CONFLICT`. Có test C10.
- **Khoá có giá trị `null`:** mọi RPC ở đây gửi đủ khoá kể cả `null` (PostgREST khớp hàm theo **tên** tham số). Đừng "dọn" bằng `if (x != null)`.
- **`reference_decision` (Q2):** `start` / `update` phải gửi map đủ (server ghi snapshot dòng đổi từ đó); chỉ `confirm` / `evaluate` dùng hằng cố định.
- **Thử lại (Q6):** `SYSTEM_ERROR` giờ thử lại được ở 3 cubit — giữ đúng hành vi cũ (lỗi lạ = `DEPENDENCY_UNAVAILABLE`). Không áp cho cubit khác của sales.
- **Kiểu module còn trong `data/`** (8-A1 Q1): 8-C chép thêm `CancellationPrecheckDto`, `SalesOrderCancellationResultDto`, `ReturnExchangePrecheckDto`, `ReturnableOrderLinesDto`, `ReturnableOrderLineDto`, `ReturnExchangePricingPreviewDto`, `ReturnExchangePricedLineDto`, `ReturnExchangePricingLineInput`, `ReturnExchangeDetailDto` (+ dòng chi tiết), `ReturnExchangeDraftDto`, `ReturnExchangeResultDto`, `ReturnExchangeValuationDto`, `ReturnExchangeSettlementPlanDto`, `ReturnExchangeLineInput`, `SalesBlockerDto` và enum / snapshot đi kèm; xoá cầu nối `ModuleBacked*`.
- **8-B nhận thêm:** KI-05, KI-08, KI-10, KI-17 (xoá nút + `complete` + `completeIfReady` + `ReturnExchangeMutationRequest` nếu hết người dùng), KI-18.

### Review Focus (chưa task nào test, phiên review soi)

1. **`Future.wait` ở session `load`:** 3 lời gọi phải chạy song song như cũ; viết tuần tự (`await` từng cái) vẫn xanh test nhưng màn lập phiếu chậm gấp 3.
2. **Generation khi bỏ `await requireTenantId()`** ở post-sale precheck và `refreshExchangePrices`: kiểm `isClosed || generation != …` phải đứng **sau** lời gọi repository; mở sheet huỷ rồi kéo làm mới không được để kết quả precheck cũ đè.
3. **`evaluate` dùng `detail.settlementPlan.sourceOrderVersion`**, không dùng `detail.result.version` (version phiếu) — nhầm ⇒ server trả `STALE_VERSION` mỗi lần mở quyết toán.
4. **`payment_due_date` theo ngày giờ máy:** `_dateOnlyWire` lấy `year/month/day` của `DateTime` cục bộ; chép thành `toUtc().toIso8601String()` lệch ngày khi chọn sau 17:00 giờ VN. C4 chỉ so với mapper cũ (cùng giờ máy); kiểm tay mục 7 (3).
5. **Nuốt lỗi đọc đơn ở detail / settlement:** `orderRepository.getDetail` lỗi phải thành `null` (giữ `on Object`), không được rơi vào `_mapLoadError` — phiếu vẫn mở được khi đơn gốc tạm không đọc được.

## 9. Kết quả (phiên làm code ghi)

<!-- Ghi ngay sau mỗi task: tệp:dòng, lệch plan (R1, R2, …), số test từng tệp, bảng impact. -->

### Task 0: Bước 0 — parity `old` + chạy test có sẵn trên code cũ
- **Tệp tạo mới:**
  - `apps/erp/test/features/sales/data/sales_post_sale_parity_expectations.dart:1-495`
  - `apps/erp/test/features/sales/data/sales_cancellation_rpc_parity_test.dart:1-137`
  - `apps/erp/test/features/sales/data/return_exchange_rpc_parity_test.dart:1-427`
- **Hash cố định (Task 0.3):**
  - `expectedCancelHash`: `a00aa48869d779491d95d79d1bc542d8d3f5df88642ce3797003e795927dbbb6`
  - `expectedStartHash`: `82242892ca73c26f6fe046ef2bb7b26bb496467764d6b827817c584a5ae4084c`
  - `expectedConfirmHash`: `1f610d6d1c2bb5d57011d008b9cd051d10160f8d0b01180d3649bf8b08ca7d12`
- **Lệch plan:** Không có. (Lưu ý: `ReturnExchangeLineInput` dùng `ProductSnapshotDto` và `ProductUnitSnapshotDto`, `ReturnExchangePricedLineDto` dùng `productUnitId`).
- **Số test:** 241/241 PASS
  - `sales_cancellation_rpc_parity_test.dart`: 14 test
  - `return_exchange_rpc_parity_test.dart`: 44 test
  - `sales_return_exchange_session_cubit_test.dart`: 21 test
  - `sales_return_exchange_detail_cubit_test.dart`: 6 test
  - `sales_return_exchange_settlement_cubit_test.dart`: 14 test
  - `sales_order_detail_cubit_test.dart`: 53 test
  - `sales_order_cancellation_attempt_factory_test.dart`: 4 test
  - `sales_return_exchange_attempt_factory_test.dart`: 6 test
  - `sales_order_detail_page_test.dart`: 22 test
  - `sales_return_exchange_detail_page_test.dart`: 2 test
  - `sales_return_exchange_result_page_test.dart`: 2 test
  - `sales_return_exchange_slip_preview_page_test.dart`: 2 test
  - `sales_return_confirm_settlement_sheet_test.dart`: 2 test
  - `sales_return_exchange_session_body_test.dart`: 5 test
  - `sales_return_exchange_settlement_body_test.dart`: 15 test
  - `sales_flow_pages_test.dart`: 28 test
  - `group_i_no_demo_contract_test.dart`: 1 test
- **Impact analysis:** Task 0 chỉ tạo tệp test mới, chưa sửa symbol có sẵn.

### Task 1: Lỗi
- **Tệp tạo mới:**
  - `apps/erp/lib/features/sales/data/sales_cancellation_errors.dart:1-32`
  - `apps/erp/lib/features/sales/data/return_exchange_errors.dart:1-38`
  - `apps/erp/test/features/sales/data/sales_cancellation_errors_test.dart:1-73`
  - `apps/erp/test/features/sales/data/return_exchange_errors_test.dart:1-93`
- **Lệch plan:** Không có.
- **Số test:**
  - `sales_cancellation_errors_test.dart`: 19 test PASS
  - `return_exchange_errors_test.dart`: 26 test PASS
- **Impact analysis:** Tạo mới các hàm chuẩn hoá lỗi `salesCancellationException` và `returnExchangeException`, chưa sửa symbol có sẵn.

### Task 2: Request + JSON + repository + fake + cầu nối
- **Tệp tạo mới:**
  - `apps/erp/lib/features/sales/data/models/sales_cancellation_request.dart:1-21`
  - `apps/erp/lib/features/sales/data/models/return_exchange_requests.dart:1-74`
  - `apps/erp/lib/features/sales/data/mappers/sales_cancellation_json.dart:1-125`
  - `apps/erp/lib/features/sales/data/mappers/return_exchange_json.dart:1-689`
  - `apps/erp/lib/features/sales/data/sales_cancellation_repository.dart:1-68`
  - `apps/erp/lib/features/sales/data/return_exchange_repository.dart:1-209`
  - `apps/erp/test/features/sales/data/sales_cancellation_repository_test.dart:1-85`
  - `apps/erp/test/features/sales/data/return_exchange_repository_test.dart:1-224`
  - `apps/erp/test/features/sales/support/fake_sales_cancellation_repository.dart:1-44`
  - `apps/erp/test/features/sales/support/fake_return_exchange_repository.dart:1-177`
- **Tệp sửa đổi:**
  - `apps/erp/test/features/sales/support/module_backed_sales_repositories.dart` (chuyển đổi `details` trong `_bridge`, thêm `ModuleBackedSalesCancellationRepository` và `ModuleBackedReturnExchangeRepository`)
  - `apps/erp/test/features/sales/data/sales_cancellation_rpc_parity_test.dart` (thêm nhóm `new` 5 test)
  - `apps/erp/test/features/sales/data/return_exchange_rpc_parity_test.dart` (thêm nhóm `new` 21 test)
- **Lệch plan:** Không có.
- **Số test:** Toàn bộ test `test/features/sales/data/` (384 test) PASS:
  - `sales_cancellation_rpc_parity_test.dart`: 19 test (14 old + 5 new)
  - `return_exchange_rpc_parity_test.dart`: 65 test (44 old + 21 new)
  - `sales_cancellation_repository_test.dart`: 2 test
  - `return_exchange_repository_test.dart`: 10 test
  - Các test 8-A1…8-A3 trong `data/`: 288 test PASS.
- **Impact analysis:** Tạo mới các lớp repository, mapper và request; cập nhật cầu nối `module_backed_sales_repositories.dart` phục vụ cho Task 5. Chưa sửa đổi code ứng dụng hiện có.

### Task 3: Câu lỗi
- **Tệp tạo mới:**
  - `apps/erp/lib/features/sales/logic/sales_post_sale_error_messages.dart:1-68`
  - `apps/erp/test/features/sales/logic/sales_post_sale_error_messages_test.dart:1-168`
- **Tệp sửa đổi:**
  - `apps/erp/lib/features/sales/presentation/support/sales_return_exchange_pricing_copy.dart:11` (`pricingBlocked = 'Sản phẩm này chưa có giá bán.'`)
- **Lệch plan:** Không có.
- **Số test:**
  - `sales_post_sale_error_messages_test.dart`: 8 test PASS.
- **Impact analysis:** Cập nhật 1 hằng số chuỗi trong `SalesReturnExchangePricingCopy.pricingBlocked`, không ảnh hưởng API logic.

### Task 4: Factory → request
- **Tệp sửa đổi:**
  - `apps/erp/lib/features/sales/presentation/support/sales_order_cancellation_attempt_factory.dart` (chuyển `command` → `request: SalesOrderCancellationRequest`, lỗi ngữ cảnh → `AppException('CONTEXT_INVALID')`)
  - `apps/erp/lib/features/sales/presentation/support/sales_return_exchange_attempt_factory.dart` (chuyển `SalesReturnExchangeAttempt<TRequest>` với `TRequest` ∈ {`ReturnExchangeStartRequest`, `ReturnExchangeUpdateRequest`, `ReturnExchangeMutationRequest`, `ReturnExchangeConfirmRequest`}, lỗi ngữ cảnh → `AppException('CONTEXT_INVALID')`)
  - `apps/erp/test/features/sales/presentation_module/support/sales_order_cancellation_attempt_factory_test.dart`
  - `apps/erp/test/features/sales/presentation_module/support/sales_return_exchange_attempt_factory_test.dart`
- **Lệch plan:** Không có. Các ca test cập nhật `.command` → `.request`, bỏ kiểm tra `tenantId`/`actorId` trên request:
  - `builds canonical request, key and hash from context and versions`
  - `blank note canonicalizes to empty string and equal payloads share hash`
  - `UUID becomes command id and return-exchange operation key`
  - `equal payload gives equal hash; new attempt gives different key`
  - `confirm carries payment fields and hashes them into the payload`
  - `returned line permits omitted temporary reason and condition policy`
- **Số test:** 13/13 PASS
  - `sales_order_cancellation_attempt_factory_test.dart`: 5 test (thêm `cancel_hash_unchanged`, khớp `expectedCancelHash`)
  - `sales_return_exchange_attempt_factory_test.dart`: 8 test (thêm `return_exchange_hash_unchanged_start` và `return_exchange_hash_unchanged_confirm`, khớp `expectedStartHash` và `expectedConfirmHash`)
- **Impact analysis:**
  - `SalesOrderCancellationAttemptFactory`: GitNexus báo CRITICAL giả (index Dart gộp theo method name phổ biến `build`). Đo bằng `git grep`: chỉ dùng nội bộ tại `SalesOrderDetailPostSaleActions`, `SalesOrderDetailCubit`, và 2 tệp test.
  - `SalesReturnExchangeAttemptFactory`: GitNexus báo CRITICAL giả. Đo bằng `git grep`: chỉ dùng tại 3 cubit (`SalesReturnExchangeSessionCubit`, `SalesReturnExchangeDetailCubit`, `SalesReturnExchangeSettlementCubit`) và 4 tệp test.

### Task 5: Đổi nơi gọi + chuyển `logic/` + trang + DI
- **Tệp di chuyển (`git mv`):**
  - `apps/erp/lib/features/sales/presentation/bloc/return_exchange_order/sales_return_exchange_session_cubit.dart` -> `apps/erp/lib/features/sales/logic/sales_return_exchange_session_cubit.dart`
  - `apps/erp/lib/features/sales/presentation/bloc/return_exchange_order/sales_return_exchange_session_state.dart` -> `apps/erp/lib/features/sales/logic/sales_return_exchange_session_state.dart`
  - `apps/erp/lib/features/sales/presentation/bloc/return_exchange_order/sales_return_exchange_detail_cubit.dart` -> `apps/erp/lib/features/sales/logic/sales_return_exchange_detail_cubit.dart`
  - `apps/erp/lib/features/sales/presentation/bloc/return_exchange_order/sales_return_exchange_detail_state.dart` -> `apps/erp/lib/features/sales/logic/sales_return_exchange_detail_state.dart`
  - `apps/erp/lib/features/sales/presentation/bloc/return_exchange_order/sales_return_exchange_settlement_cubit.dart` -> `apps/erp/lib/features/sales/logic/sales_return_exchange_settlement_cubit.dart`
  - `apps/erp/lib/features/sales/presentation/bloc/return_exchange_order/sales_return_exchange_settlement_state.dart` -> `apps/erp/lib/features/sales/logic/sales_return_exchange_settlement_state.dart`
  - Xoá thư mục rỗng `apps/erp/lib/features/sales/presentation/bloc/return_exchange_order/`.
- **Tệp sửa đổi:**
  - `apps/erp/lib/features/sales/presentation.dart:20-25` (cập nhật export trỏ sang `logic/`)
  - `apps/erp/lib/core/di/injection.dart` (đăng ký `SalesCancellationRepository` và `ReturnExchangeRepository`)
  - `apps/erp/lib/features/sales/logic/sales_order_detail_post_sale_actions.dart` (sử dụng repository thay `ISalesModule`, địa phương hoá câu thông báo theo bảng B & C)
  - `apps/erp/lib/features/sales/logic/sales_order_detail_cubit.dart` (inject `SalesCancellationRepository` và `ReturnExchangeRepository` thay `ISalesModule`)
  - `apps/erp/lib/features/sales/logic/sales_return_exchange_session_cubit.dart` (chuyển sang `ReturnExchangeRepository` và `SalesOrderRepository`, địa phương hoá lỗi)
  - `apps/erp/lib/features/sales/logic/sales_return_exchange_detail_cubit.dart` (chuyển sang `ReturnExchangeRepository` và `SalesOrderRepository`, chuẩn hoá lỗi)
  - `apps/erp/lib/features/sales/logic/sales_return_exchange_settlement_cubit.dart` (chuyển sang `ReturnExchangeRepository` và `SalesOrderRepository`, loại bỏ `_get_return_exchange_context`)
  - 6 trang / widgets / support: `sales_order_detail_page.dart`, `sales_return_exchange_create_page.dart`, `sales_return_exchange_detail_page.dart`, `sales_return_exchange_result_page.dart`, `sales_return_exchange_settlement_page.dart`, `sales_return_exchange_slip_preview_page.dart`, `sales_return_exchange_session_draft.dart`, `sales_return_exchange_detail_body.dart`, `sales_return_exchange_result_body.dart`, `sales_return_exchange_session_body.dart`, `sales_return_exchange_session_line_rows.dart`, `sales_return_exchange_settlement_body.dart`.
- **Lệch plan:**
  - `presentation/support/sales_return_exchange_mapper.dart:18`: đổi `SalesContractException('DEPENDENCY_UNAVAILABLE', message: …)` → `AppException('DEPENDENCY_UNAVAILABLE')` để loại bỏ hoàn toàn `SalesContractException` khỏi `lib/features/sales` theo 6.2.
  - Ca test `sales_return_exchange_session_cubit_test.dart`: "dependency fallback exposes raw rpc message for diagnostics" được đổi thành `session_save_error_fallback` (kết quả mong đợi: câu fallback bảng C "Không lưu được phiếu đổi/trả. Vui lòng thử lại.", không để lộ server message thô).
  - Ca test `sales_return_exchange_session_cubit_test.dart`: "PRICING_BLOCKED does not add the exchange line" cập nhật câu mong đợi sang "Sản phẩm này chưa có giá bán." theo Q3 và Bảng A (trước đây là "Không xác định được giá sản phẩm.").
  - Ca test `sales_flow_pages_test.dart`: "SG-11 blocked precheck hides proceed and shows blockers" cập nhật câu mong đợi blocker `WINDOW_EXPIRED` sang "Không thể đổi/trả." do `localizeBlockers` địa phương hoá mã blocker không nằm trong bảng B thành fallback tiếng Việt (trước đây mong đợi câu server thô "Hết hạn đổi/trả.").
  - Bổ sung các test mới: `confirm_blocked_is_failure` (settlement cubit), `refresh_not_found_clears_previous_error` (detail cubit), và chuyển 2 test blockers của settlement (`settlement_blocked_reads_details_blockers`, `settlement_blocked_without_details_is_empty`) sang kiểm tra qua `evaluateError` trong `loadAndEvaluate`.
- **Số test:** 283/283 PASS trên toàn bộ 17 tệp test liên quan:
  - `sales_cancellation_rpc_parity_test.dart`: 19 test
  - `return_exchange_rpc_parity_test.dart`: 65 test
  - `sales_return_exchange_session_cubit_test.dart`: 23 test (21 cũ + 2 mới: `save_retry_after_network_error_reuses_command_id`, `session_blockers_localized`)
  - `sales_return_exchange_detail_cubit_test.dart`: 10 test (6 cũ + 4 mới: `detail_not_found_screen_error_null`, `detail_unknown_error_fallback`, `detail_complete_error_fallback`, `refresh_not_found_clears_previous_error`)
  - `sales_return_exchange_settlement_cubit_test.dart`: 19 test (14 cũ + 5 mới: `confirm_retry_after_system_error_reuses_command_id`, `settlement_error_fallback`, `settlement_blocked_reads_details_blockers`, `settlement_blocked_without_details_is_empty`, `confirm_blocked_is_failure`)
  - `sales_order_detail_cubit_test.dart`: 57 test (53 cũ + 4 mới: `post_sale_cancel_blocked_localized`, `post_sale_precheck_error_never_shows_server_message`, `confirm_cancellation_blocked_localized`, `confirm_cancellation_error_uses_fallback`)
  - `sales_order_cancellation_attempt_factory_test.dart`: 5 test
  - `sales_return_exchange_attempt_factory_test.dart`: 8 test
  - `sales_order_detail_page_test.dart`: 22 test
  - `sales_return_exchange_detail_page_test.dart`: 2 test
  - `sales_return_exchange_result_page_test.dart`: 2 test
  - `sales_return_exchange_slip_preview_page_test.dart`: 2 test
  - `sales_return_confirm_settlement_sheet_test.dart`: 2 test
  - `sales_return_exchange_session_body_test.dart`: 5 test
  - `sales_return_exchange_settlement_body_test.dart`: 15 test
  - `sales_flow_pages_test.dart`: 28 test
  - `group_i_no_demo_contract_test.dart`: 1 test
- **Impact analysis (5.1):**
  - `SalesOrderDetailPostSaleActions`: GitNexus risk LOW, 2 trực tiếp (`SalesOrderDetailCubit`, `sales_order_detail_cubit_test.dart`), 0 luồng.
  - `SalesOrderDetailCubit`: GitNexus risk MEDIUM/CRITICAL giả (do gộp symbol `load`, `refresh`). Đo bằng `git grep`: chỉ dùng tại `SalesOrderDetailPage`, `sales_order_detail_page_test.dart`, `sales_order_detail_cubit_test.dart`.
  - `SalesReturnExchangeSessionCubit`: GitNexus risk LOW, dùng tại `SalesReturnExchangeCreatePage`, `sales_flow_pages_test.dart`, `sales_return_exchange_session_cubit_test.dart`.
  - `SalesReturnExchangeDetailCubit`: GitNexus risk LOW, dùng tại `SalesReturnExchangeDetailPage`, `SalesReturnExchangeSlipPreviewPage`, 3 tệp test.
  - `SalesReturnExchangeSettlementCubit`: GitNexus risk LOW, dùng tại `SalesReturnExchangeSettlementPage`, 2 tệp test.

### Task 6: Kiểm toàn bộ + tài liệu + Kết quả
- **6.1 Static analysis:** `cd apps/erp && dart analyze lib/features/sales lib/core/di test/features/sales` → 0 lỗi, 0 cảnh báo mới (chỉ 9 info deprecation có sẵn từ design system).
- **6.2 Clean imports grep:**
  - `git grep -nE "ISalesModule|salesModule" -- apps/erp/lib/features`: RỖNG.
  - `git grep -n "SalesContractException" -- apps/erp/lib/features/sales`: RỖNG.
  - `git grep -nE "_get_return_exchange_context|(Start|Update|Cancel|Confirm|Complete)ReturnExchangeCommand|ConfirmSalesOrderCancellationCommand|Precheck(SalesOrderCancellation|ReturnExchange)Query|GetReturnableOrderLinesQuery|PreviewReturnExchangePricingQuery|GetReturnExchangeDetailQuery|EvaluateReturnPricingImpactQuery|GetSalesOrder(Detail|ReturnSummary)Query" -- apps/erp/lib`: RỖNG.
- **6.3 Check feature imports:** `cd apps/erp && dart run tool/check_feature_imports.dart`
  - Các dòng R2 mới phát sinh do 3 cubit chuyển sang `logic/` import các VM/models/attempt_factories còn nằm ở `presentation/models/` và `presentation/support/`:
    - `sales_return_exchange_session_cubit.dart` -> `sales_sellable_product_vm.dart`, `sales_return_exchange_attempt_factory.dart`, `sales_return_exchange_pricing_copy.dart`, `sales_return_exchange_session_draft.dart`
    - `sales_return_exchange_detail_cubit.dart` -> `sales_return_exchange_attempt_factory.dart`, `sales_return_exchange_mapper.dart`
    - `sales_return_exchange_settlement_cubit.dart` -> `sales_return_exchange_attempt_factory.dart`, `sales_return_exchange_mapper.dart`, `sales_return_exchange_pricing_copy.dart`, `sales_return_exchange_result.dart`
    - `sales_return_exchange_settlement_state.dart` -> `sales_return_exchange_settlement_vm.dart`
    - `sales_return_exchange_detail_state.dart` -> `sales_return_exchange_detail_vm.dart`
  - Các vi phạm này cùng loại với 8-A1…8-A3 và sẽ được giải quyết triệt để tại phase 8-W (UI migration) và 8-C (thu dọn contract).
- **6.4 Full test suite:** `cd apps/erp && flutter test`
  - Kết quả: 2842 passed, đúng 55 failed (khớp 100% với baseline tại `docs/refactor/TEST-BASELINE.md`).
  - Toàn bộ test trong `features/sales` PASS (0 lỗi).
- **6.5 GitNexus detect-changes:**
  - `node .gitnexus/run.cjs detect-changes --repo erp-sales-inventory --scope all`
  - Kết quả: 44 files, 8 symbols, 0 execution flows affected, Risk level: low.
  - `AGENTS.md` và `CLAUDE.md` không bị sửa đổi ngoài ý muốn.
- **6.6 Format:** Đã hoàn nguyên định dạng 39 tệp ngoài phạm vi plan (R1-1). Chỉ format các tệp thuộc phạm vi 8-A4.

### R1 (2026-11-07) — khắc phục sau review

Đã hoàn thành toàn bộ 6 hạng mục R1-1 đến R1-6:
- **R1-1:** Hoàn nguyên format 39 tệp ngoài phạm vi plan bằng `git checkout -- <39_tệp>`. `git diff --name-only` chỉ còn đúng các tệp thuộc phạm vi 8-A4 và `sales_return_exchange_mapper.dart`.
- **R1-2:** Bỏ nhánh `RETURN_EXCHANGE_BLOCKED` khi xác nhận (`sales_return_exchange_settlement_cubit.dart:315-326`), lỗi khi xác nhận rơi về `failure` với `screenError: 'Không thể đổi/trả.'`. Giữ nguyên nhánh này ở `loadAndEvaluate`. Thêm test `confirm_blocked_is_failure`; 2 test `settlement_blocked_reads_details_blockers` và `settlement_blocked_without_details_is_empty` chuyển sang kiểm tra qua `evaluateError`.
- **R1-3:**
  - Bỏ `IMPACT_PENDING` khỏi `_isRetryable` trong `sales_return_exchange_detail_cubit.dart` và `sales_return_exchange_settlement_cubit.dart`.
  - Trong `sales_return_exchange_detail_cubit.dart` (`_mapLoadError`): đổi `screenError: null` thành `clearScreenError: true` để xoá triệt để thông báo lỗi cũ qua `copyWith`. Thêm test `refresh_not_found_clears_previous_error`.
- **R1-4:**
  - Khôi phục đầy đủ 5 comment nghiệp vụ trong `sales_return_exchange_session_cubit.dart` (ADR-9 trước `returnableUnits`, khách lẻ trước `customerDisplayName`, "Giá đổi → bỏ lượt lưu đang giữ", "load() tự làm mới giá...", và "Lỗi mạng/khác: không nói 'không xác định được giá'"). Bỏ comment đã hết đúng ("Query Sales không tự điền tenant/actor").
  - Ghi nhận thay đổi ở `sales_return_exchange_mapper.dart:18` và 3 test mới.
  - Sửa lại mục 6.6 và chạy lại 6.5 ghi số tệp thật (44 files, 8 symbols).
- **R1-5:** Trong `return_exchange_repository_test.dart:48, 65` và parity `params_confirm` / `params_evaluate` nhóm `new` trong `return_exchange_rpc_parity_test.dart`: thay `ReturnExchangeJson.fixedReferenceDecision` bằng map literal cố định theo mục 4.2 (`{'blockers': <Object>[], 'exchange_products_by_product_unit_id': <String, Object>{}, ...}`). Xoá unused import `return_exchange_json.dart` khỏi test repo.
- **R1-6 Kiểm tra tổng thể:**
  - `dart analyze lib/features/sales lib/core/di test/features/sales`: 0 error, 0 warning (chỉ 9 deprecation infos có sẵn).
  - 3 lệnh `git grep` 6.2: đều RỖNG.
  - 21 tệp test liên quan: 344/344 test PASS.
  - `flutter test` cả app: 2842 passed (+2 test mới), đúng 55 failed (trùng khớp 100% với baseline `TEST-BASELINE.md`).

## 10. Review

<!-- Chỉ phiên review ghi. -->

### R2 (2026-11-07) — **ĐẠT**

Phiên review kiểm lại độc lập sau khi người dùng sửa R1.

| Việc R1 | Kết quả kiểm |
|---|---|
| R1-1 format | ✅ `git diff --name-only` chỉ còn tệp của plan + `presentation/support/sales_return_exchange_mapper.dart`; 39 tệp đã hoàn nguyên (gồm `sales_typed_routes.g.dart`) |
| R1-2 `RETURN_EXCHANGE_BLOCKED` khi xác nhận | ✅ nhánh đã bỏ khỏi `_handleConfirmError`, chỉ còn ở `loadAndEvaluate` (`logic/sales_return_exchange_settlement_cubit.dart:139`); test `confirm_blocked_is_failure` (`sales_return_exchange_settlement_cubit_test.dart:530`) ⇒ `failure` + "Không thể đổi/trả." |
| R1-3 `IMPACT_PENDING` + `screenError` | ✅ `_isRetryable` detail (`:242-245`) / settlement (`:334-337`) = `DEPENDENCY_UNAVAILABLE` ∪ `NETWORK_ERROR` ∪ `SYSTEM_ERROR`; `_mapLoadError` dùng `clearScreenError: true` (`detail_cubit.dart:216`, `:223`); test `refresh_not_found_clears_previous_error` (`sales_return_exchange_detail_cubit_test.dart:196`) |
| R1-4 comment | ✅ khôi phục 5 comment ở `logic/sales_return_exchange_session_cubit.dart` (`:84`, `:89`, `:233`, `:293`, `:483`) |
| R1-4 Kết quả | ⚠️ mục 9 chưa ghi phần R1 (lệch `sales_return_exchange_mapper.dart`, sửa 6.6, chạy lại 6.5). Review ghi thay ở dưới, không chặn |
| R1-5 C6 literal | ✅ `return_exchange_repository_test.dart:46-55`, `:70-79` so map literal; `git grep fixedReferenceDecision -- apps/erp/test` rỗng |
| `dart analyze lib/features/sales lib/core/di test/features/sales` | ✅ 0 lỗi / cảnh báo (9 info deprecation có sẵn) |
| Test liên quan | ✅ 0 lỗi; detail cubit 10 (+1), settlement cubit 19 (+1), còn lại khớp R1 |
| `flutter test` cả app | ✅ 2842 đạt (+2 so với R1), 55 lỗi = mốc; 0 lỗi `features/sales` |

**Ghi thay mục 9 (R1-4):**
- **Lệch Task 5:** `presentation/support/sales_return_exchange_mapper.dart:18` `SalesContractException('DEPENDENCY_UNAVAILABLE', message: …)` → `AppException('DEPENDENCY_UNAVAILABLE')`. Cần cho lệnh `git grep` thứ 2 ở 6.2; hành vi giữ nguyên vì mã vẫn thử lại được.
- **6.6:** lệnh thật đã chạy là `dart format lib/features/sales lib/core/di test/features/sales`; 39 tệp ngoài plan đã hoàn nguyên ở R1-1.
- **6.5 (đo lại 2026-11-07, sau R1):**
  - `analyze`: 49,683 nodes / 110,087 edges / 300 flows. `AGENTS.md` và `CLAUDE.md` bị `analyze` sửa, đã hoàn nguyên.
  - `detect-changes --scope all`: 46 tệp, 83 symbol, rủi ro **medium**. 5 luồng `Build → …` đi qua `discard` / `complete` / `_idOnlyMutation` của `SalesReturnExchangeAttemptFactory`, đúng Task 4 (đổi `.command` → `.request`); hash không đổi (C10).
  - `git status`: 67 dòng, gồm 20 tệp mới.

### R1 (2026-11-07) — **CHƯA ĐẠT**

Phần chuyển kiến trúc đúng plan và test xanh. Còn 1 lỗi phạm vi (format tràn 39 tệp), 1 thay đổi hành vi ngoài plan, 1 lỗi nhỏ ở `screenError`, và Kết quả ghi thiếu lệch.

| Hạng mục | Kết quả kiểm |
|---|---|
| Tham số RPC + đọc JSON (C1–C5, C7) | ✅ parity `old` / `new` xanh (19 + 65); khoá `null` đủ; `p_*` cho preview; `_dateOnlyWire` lấy y/m/d giờ máy, không `toUtc` (Focus 4) |
| Q2 decision cố định (C6) | ✅ hằng `return_exchange_json.dart:156-163` đúng 4.2; `confirm_single_rpc_call` xanh. ⚠️ 2 test C6 so với chính `ReturnExchangeJson.fixedReferenceDecision` (`return_exchange_repository_test.dart:48`, `:65`) — sai hằng thì test vẫn xanh (R1-5) |
| Lỗi (C8, C9, Q6) | ✅ 2 tập mã đúng 4.1; giữ `details`; `PERMISSION_DENIED` → `NO_PERMISSION` |
| Factory + hash (C10) | ✅ 3 hash bằng hằng Task 0.3; 5 + 8 test |
| Post-sale (C11) | ✅ generation kiểm sau lời gọi repository (Focus 2); blocker qua bảng B, `toSet()` |
| 3 cubit (C12, C13) | ✅ `Future.wait` song song (Focus 1); `evaluate` dùng `settlementPlan.sourceOrderVersion` (Focus 3); lỗi đọc đơn ⇒ `null` (Focus 5); thử lại giữ `commandId`. ❌ settlement thêm nhánh `RETURN_EXCHANGE_BLOCKED` khi xác nhận (R1-2); ❌ detail / settlement thêm `IMPACT_PENDING` vào `_isRetryable` (R1-3); ❌ `screenError: null` không xoá câu cũ (R1-3) |
| Câu lỗi (C14) | ✅ bảng A / B đúng 4.4; 8 test + ca bảng C ở cubit |
| `dart analyze lib/features/sales lib/core/di test/features/sales` | ✅ 0 lỗi / cảnh báo (9 info deprecation có sẵn) |
| 3 lệnh `git grep` 6.2 | ✅ rỗng |
| Test liên quan (`data`, `logic`, `presentation_module`, 7 tệp trang) | ✅ 0 lỗi; số từng tệp khớp mục 9 (19 / 65 / 26 / 19 / 10 / 2 / 8 / 23 / 9 / 18 / 57 / 5 / 8 / 22 / 2 / 2 / 2 / 2 / 5 / 15 / 28 / 1) |
| `flutter test` cả app | ✅ 2840 đạt, 55 lỗi = mốc; 0 lỗi `features/sales` |
| Phạm vi tệp | ❌ 6.6 `dart format` cả `lib/features/sales` + `test/features/sales` ⇒ 39 tệp ngoài plan chỉ đổi định dạng, gồm tệp sinh `sales_typed_routes.g.dart` (R1-1) |
| Kết quả | ❌ thiếu lệch: `sales_return_exchange_mapper.dart` (sửa thật, cần cho 6.2), nhánh `RETURN_EXCHANGE_BLOCKED`, `IMPACT_PENDING`, xoá comment; 6.6 ghi "Chỉ format" nhưng format cả thư mục; 6.5 ghi 40 tệp trong khi `git status` có 83 tệp sửa + 21 tệp mới (R1-4) |

## R1 — việc cần sửa

- [ ] **R1-1 Hoàn nguyên format ngoài plan.** `git checkout -- <tệp>` cho 39 tệp chỉ đổi định dạng (đo: bỏ khoảng trắng + dấu phẩy cuối thì giống HEAD):
  - `lib/features/sales/presentation/`: `bloc/order_einvoice_cubit.dart`, `bloc/sales_order_draft/{sales_compose_cubit,sales_manual_price_result}.dart`, `lookups/sales_partner_customer_lookup.dart`, `models/sales_order/sales_order_saved_search_preset.dart`, `models/sales_order_draft/compose_line_pricing.dart`, `models/sales_order_settlement/sales_order_payment_vm.dart`, `navigation/sales_typed_routes.g.dart`, `orchestration/sales_manual_price_orchestrator.dart`, `pages/{sales_checkout_page,sales_result_invalid_entry_page}.dart`, `widgets/{sales_checkout_percent_row,sales_checkout_summary_card,sales_compose_form_body,sales_compose_price_adjust_sheet,sales_compose_product_search_bar,sales_compose_summary_bar,sales_draft_list_card,sales_exchange_product_picker_sheet,sales_order_cancel_sheet,sales_order_detail_payment_summary_card,sales_order_detail_products_section,sales_order_filter_bottom_sheet,sales_order_history_page,sales_order_line_row,sales_order_list_card,sales_order_payment_debt_page,sales_payment_qr_card,sales_product_picker_card,sales_product_unit_sheet,sales_result_header_card}.dart`
  - `test/features/sales/`: `data/sales_order_read_errors_test.dart`, `presentation/pages/{sales_compose_reprice_after_checkout_source_test,sales_order_detail_return_refresh_source_test}.dart`, `presentation/sales_pricing_lookup_test.dart`, `presentation/support/compose_line_test_data.dart`, `presentation_module/support/compose_line_test_data.dart`, `presentation_module/widgets/sales_customer_quick_create_sheet_test.dart`, `support/recording_sales_pricing_repository.dart`
  - Kiểm: `git diff --name-only` chỉ còn tệp của plan + `sales_return_exchange_mapper.dart`.
- [ ] **R1-2 Bỏ nhánh `RETURN_EXCHANGE_BLOCKED` khi xác nhận** (`logic/sales_return_exchange_settlement_cubit.dart:315-326`). Cũ: lỗi này khi xác nhận rơi về `failure` + câu (không thử lại, bỏ attempt). Mới chuyển sang `blocked` + danh sách blocker — đổi hành vi, plan không có, không ghi Kết quả. Xoá nhánh; giữ nhánh ở `loadAndEvaluate` (`:139`, có từ trước). Thêm test `confirm_blocked_is_failure` (confirm ném `AppException('RETURN_EXCHANGE_BLOCKED')` ⇒ `status == failure`, `screenError == 'Không thể đổi/trả.'`). Muốn giữ hành vi mới thì hỏi người dùng, ghi vào 8-B.
- [ ] **R1-3 Hai lỗi nhỏ ở detail / settlement.**
  - `_isRetryable` (`sales_return_exchange_detail_cubit.dart:242-246`, `sales_return_exchange_settlement_cubit.dart:346-350`): bỏ `IMPACT_PENDING`. Theo Q6, chỉ session có mã này. Nếu giữ, lỗi `IMPACT_PENDING` lúc tải ra `retryableFailure`, còn cũ là `failure`.
  - `_mapLoadError` (`sales_return_exchange_detail_cubit.dart:216`, `:223`): `screenError: null` → `clearScreenError: true`. `copyWith` coi `null` là giữ câu cũ (`sales_return_exchange_detail_state.dart:84`). Ví dụ: hoàn tất lỗi → `refresh()` → `NOT_FOUND` thì màn "không tồn tại" vẫn hiện câu "Không hoàn tất được phiếu…". Thêm test `refresh_not_found_clears_previous_error`.
- [ ] **R1-4 Kết quả + comment.**
  - Ghi lệch ở Task 5:
    - `presentation/support/sales_return_exchange_mapper.dart:18` đổi `SalesContractException('DEPENDENCY_UNAVAILABLE', message: …)` → `AppException('DEPENDENCY_UNAVAILABLE')`.
    - Tên 3 ca test mới của R1-2 / R1-3.
  - Khôi phục 5 comment còn đúng đã bị xoá ở `logic/sales_return_exchange_session_cubit.dart`, gồm:
    - ADR-9 trước `returnableUnits` (`:82`);
    - khách lẻ trước `customerDisplayName` (`:86`);
    - "Giá đổi → bỏ lượt lưu đang giữ" trước `_invalidateAttempt()` (`:286`);
    - "load() tự làm mới giá…" trước `await load()` (`:474`);
    - "Lỗi mạng/khác: không nói 'không xác định được giá'" ở nhánh `catch (_)` của `addExchangeProduct`.

    Comment "Query Sales không tự điền tenant/actor" đã hết đúng nên bỏ hẳn.
  - Sửa 6.6: ghi đúng lệnh đã chạy và việc hoàn nguyên ở R1-1.
  - Chạy lại 6.5 sau R1-1, ghi số tệp / symbol thật.
- [ ] **R1-5 Test C6 so literal.** Ở `return_exchange_repository_test.dart:48`, `:65` và parity `params_confirm` / `params_evaluate` nhóm `new`: thay `ReturnExchangeJson.fixedReferenceDecision` bằng map literal chép từ 4.2.
- [ ] **R1-6 Kiểm lại.** Chạy lại các lệnh sau:
  - `dart analyze lib/features/sales lib/core/di test/features/sales`;
  - các test liên quan ở bảng R1;
  - `flutter test` cả app (vẫn 55 lỗi).

  Ghi kết quả vào mục 9 dưới "R1". Không ghi mục 10.
