# 8-B3 — Sales: màn Thu tiền SG-11 (KI-06 / EP-04)

> Theme 5 (mã cũ P8) · Bước (b) sửa theo TH-05, phần mới · Gồm: KI-06 (EP-04 US-04.1, SG-11), `SalesPaymentRepository.recordPayment` (8-A2 Q2), bố cục iPhone + web của SG-11.
> Trạng thái: Plan ✅ (viết 2026-11-07, duyệt 2026-11-07) | Làm ✅ (2026-11-08) | Review ✅ R2 (2026-11-08)
> Trước: 8-B2 (đã bỏ thẻ "Xem công nợ"; dùng chung `supabase/tests/sales_th05.sql`). Sau: 8-C.
> Tài liệu: [TH-05](../../../02-yeu-cau/TH-05-ban-hang-va-don-hang.md) BR-02, BR-30, BR-31, EP-04 (US-04.1 FR-01…05, AC-01…04, SC-01/02), SG-09 (thanh dưới "Thao tác"), SG-11, 6.2, 6.4, 9.3 (kịch bản 2); PLAN.md "Thiết bị (chốt 2026-10-20)". Mẫu: `presentation/support/sales_order_cancellation_attempt_factory.dart` (attempt giữ khoá + hash), `data/sales_cancellation_errors.dart` (tập mã ổn định), `presentation/widgets/sales_order_actions_sheet.dart`.
>
> **Cho phiên code:** dùng `superpowers:executing-plans` (tuần tự). Mỗi task xong ghi ngay mục 9 theo mẫu. **Không commit**. **Không chạy SQL, không reset DB, không push**. **Không ghi mục 10**.

## 1. Mục tiêu

Đơn `completed` còn phải thu > 0: sheet "Thao tác" ở SG-09 có "Thu tiền" → SG-11 → gọi `record_sales_payment` (nguồn `additional_collection`) → toast "Đã ghi nhận <số>", SG-09 tải lại. Bấm hai lần / thử lại sau mất mạng ⇒ đúng 1 giao dịch.

**Không làm:** sửa SQL (`record_sales_payment` giữ nguyên, `20260904001_sales_normalize_outbox_and_commands.sql:14-152`); thu gộp nhiều đơn (Theme 6); `record_sales_refund` (KI-13).

## 2. Quyết định

| # | Câu hỏi | Chốt |
|---|---|---|
| Q1 | Bố cục web | **Người dùng chốt 2026-11-07:** làm ngay ở 8-B3 bằng `showVAdaptiveSheet` (iPhone: bottom sheet; rộng ≥ `VBreakpoints.desktop`: `VSheetDialog` rộng tối đa 480); bàn phím: Tab qua các ô, Enter ở ô số tiền = "Xác nhận thu tiền", Esc đóng |
| Q2 | Khoá chống trùng | Như `SalesOrderCancellationAttemptFactory` (factory **không** nhớ; bên gọi giữ): cubit giữ `_attempt`. Bấm xác nhận ⇒ factory dựng attempt ứng viên; `_attempt != null` và cùng `payloadHash` ⇒ dùng lại `_attempt` (cùng `idempotency_key`), khác ⇒ dùng ứng viên. Lỗi không thử lại / thành công ⇒ `_attempt = null`. Mở sheet = cubit mới ⇒ khoá mới (FR-03) |
| Q3 | Điều kiện hiện "Thu tiền" | `vm.lifecycleStatus == SalesOrderLifecycleStatus.committed` **và** `state.paymentStatus == loaded` **và** `state.payment!.outstandingMinor > 0`. Không thoả ⇒ **không có** mục (AC-04), không phải mục bị tắt |
| Q4 | Vị trí mục | Đầu danh sách sheet "Thao tác", trước "Đổi/trả hàng" (mẫu SG-09 `TH-05:1841`) |
| Q5 | Mã giao dịch | Chỉ hiện khi chọn Chuyển khoản; gửi `p_external_reference` = chuỗi đã `trim`, rỗng ⇒ `null`. Đổi về Tiền mặt ⇒ không gửi |
| Q6 | Mã lỗi giữ (repository) | `NO_PERMISSION` (server `PERMISSION_DENIED`), `DATA_SCOPE_DENIED`, `CONTEXT_INVALID`, `REFERENCE_UNAVAILABLE`, `IDEMPOTENCY_CONFLICT`, `ORDER_CANCELLED`, `OVERPAYMENT_NOT_ALLOWED`, `NETWORK_ERROR`; còn lại / lỗi đọc JSON ⇒ `SYSTEM_ERROR`. Tệp lỗi riêng (không dùng `salesOrderReadException` — tập mã đọc không có mã ghi) |
| Q7 | Thử lại | `NETWORK_ERROR`, `SYSTEM_ERROR`, `IDEMPOTENCY_CONFLICT` ⇒ giữ attempt, nút "Thử lại" (cùng khoá). Mã khác ⇒ bỏ attempt, chỉ hiện câu |
| Q8 | `store_id` | Cubit nhận `ISalesActiveStoreContext` (như `SalesCheckoutCubit`), đọc mỗi lần gửi |

## 3. Hiện trạng (đo 2026-11-07, dưới `apps/erp/lib/features/sales/`)

- `data/sales_payment_repository.dart:8-100`: 3 hàm đọc, `_guard` → `salesOrderReadException`. DI: `lib/core/di/injection.dart:231-237`. Fake: `test/features/sales/support/fake_sales_payment_repository.dart`.
- `presentation/widgets/sales_order_actions_sheet.dart:4` `enum SalesOrderSheetAction { returnExchange, cancel }`; `:6-22` `showSalesOrderActionsSheet(context, {canReturnExchange, canCancel, cancelDisabledReason})` (dùng `showVBottomSheet`).
- `presentation/pages/sales_order_detail_page.dart:63-101` `_openActionsSheet` (đọc `state.actions`, `state.payment`, `switch (action)`), `_cubit.refresh()`.
- `presentation/models/sales_order_settlement/sales_order_payment_vm.dart:96-101`: `outstandingMinor`, `dueDateFormatted`; `presentation/models/sales_order/sales_order_detail_vm.dart:131`, `:146` `orderNumber`, `lifecycleStatus`.
- Wire phương thức: `'cash'`, `'manualBankTransfer'` (`data/mappers/sales_checkout_json.dart:243-248`).
- RPC trả `sales._settlement_mutation_snapshot` (`supabase/migrations/20260830009_sales_settlement_rpcs.sql`): `settlementId`, `salesOrderId`, `transactionId`, `currencyCode`, `currentPayableMinor`, `collectedMinor`, `refundedMinor`, `netCollectedMinor`, `outstandingMinor`, `paymentStatus`, `version`.

Không có bảng "Đang làm gì": chỉ thêm mục vào sheet (2 mục cũ giữ nguyên, test có sẵn của sheet / trang phải còn xanh).

## 4. Thiết kế

### 4.1 Dữ liệu (`data/`)

`data/models/sales_record_payment.dart`:
```dart
final class SalesRecordPaymentRequest {
  const SalesRecordPaymentRequest({
    required this.storeId, required this.salesOrderId, required this.amountMinor,
    required this.method, this.externalReference,
    required this.idempotencyKey, required this.payloadHash, required this.correlationId,
  });
  final String storeId; final String salesOrderId; final int amountMinor;
  final SalesPaymentMethod method; final String? externalReference;
  final String idempotencyKey; final String payloadHash; final String correlationId;
}

final class SalesRecordPaymentResult {
  const SalesRecordPaymentResult({
    required this.transactionId, required this.outstandingMinor,
    required this.paymentStatus, required this.version,
  });
  final String transactionId; final int outstandingMinor; final String paymentStatus; final int version;
}
```

`SalesPaymentRepository.recordPayment(SalesRecordPaymentRequest request) → Future<SalesRecordPaymentResult>`; params (đủ khoá, kể cả `null`):
`p_tenant_id`, `p_actor_id`, `p_store_id`, `p_sales_order_id`, `p_amount_minor`, `p_payment_method_code` (`'cash'` / `'manualBankTransfer'`), `p_idempotency_key`, `p_payload_hash`, `p_source_context: 'additional_collection'`, `p_payment_method_snapshot: null`, `p_external_reference`, `p_correlation_id`. JSON vào / ra ở `data/mappers/sales_payment_json.dart` (`recordParams`, `recordResultFromJson`). Lỗi qua `salesPaymentMutationException(Object) → AppException` ở `data/sales_payment_mutation_errors.dart` (tập Q6, mẫu `sales_cancellation_errors.dart`).

### 4.2 Attempt factory (`presentation/support/sales_record_payment_attempt_factory.dart`)

`SalesRecordPaymentAttemptFactory({String Function()? newAttemptId})`, `SalesRecordPaymentAttempt create({required String tenantId, required String actorId, required String storeId, required String salesOrderId, required int amountMinor, required SalesPaymentMethod method, String? externalReference, required String correlationId})` → attempt có `request`, `canonicalPayloadJson`, `payloadHash` (SHA-256 hex của canonical JSON gồm tenant, actor, store, đơn, số tiền, phương thức, mã giao dịch — như factory huỷ). `idempotencyKey` = `'sales-payment:<attemptId>'` (mẫu `'sales-order-cancellation:$attemptId'`). Mỗi lần `create` sinh id mới; việc dùng lại do cubit (Q2). Đầu vào rỗng / `amountMinor <= 0` ⇒ `AppException('CONTEXT_INVALID')`.

### 4.3 Cubit (`logic/sales_record_payment_cubit.dart`, `logic/sales_record_payment_state.dart`)

```dart
enum SalesRecordPaymentStatus { editing, submitting, failure, succeeded }

SalesRecordPaymentCubit({
  required SalesPaymentRepository repository,
  required IExecutionContext executionContext,
  required ISalesActiveStoreContext activeStoreContext,
  required String salesOrderId,
  required int outstandingMinor,
  SalesRecordPaymentAttemptFactory? attemptFactory,
})
void setAmountMinor(int? value);         // null = ô trống
void setMethod(SalesPaymentMethod method);
void setExternalReference(String value);
Future<void> submit();                   // cũng là "Thử lại"
```
State: `status`, `amountMinor` (mặc định = `outstandingMinor`), `method` (mặc định `cash`), `externalReference`, `fieldError`, `errorMessage`, `canRetry`, `result`.

Kiểm đầu vào (trước khi gửi, đặt `fieldError`, không gọi repository):
- trống hoặc ≤ 0 ⇒ "Số tiền phải lớn hơn 0."
- > `outstandingMinor` ⇒ "Số tiền vượt quá số còn phải thu."

Câu lỗi gửi (6.4):

| Mã | Câu | Thử lại |
|---|---|---|
| `OVERPAYMENT_NOT_ALLOWED` | "Số tiền vượt quá số còn phải thu." | không |
| `ORDER_CANCELLED` | "Đơn đã hủy, không thể thu thêm." | không |
| `IDEMPOTENCY_CONFLICT` | "Yêu cầu bị xung đột" | có |
| `NO_PERMISSION` | "Bạn không có quyền thực hiện thao tác này." | không |
| `DATA_SCOPE_DENIED` | "Cửa hàng hiện tại không còn khả dụng." | không |
| `REFERENCE_UNAVAILABLE` | "Đơn hàng không tồn tại hoặc đã bị xóa." | không |
| `CONTEXT_INVALID` | "Dữ liệu không hợp lệ." | không |
| `NETWORK_ERROR`, `SYSTEM_ERROR`, khác | "Không thể ghi nhận thanh toán. Vui lòng thử lại." | có |

Đang `submitting` ⇒ `submit()` bỏ qua (chống bấm hai lần). Thành công ⇒ `status = succeeded`, `result`.

### 4.4 UI

- `sales_order_actions_sheet.dart`: thêm `SalesOrderSheetAction.collectPayment`, tham số `bool canCollectPayment = false`; khi `true` thêm tile đầu danh sách `Key('btn_order_action_collect_payment')`, icon tiền (chọn trong `VIcons` có sẵn, vd `VIcons.banknoteArrowDown` đang dùng ở thẻ cũ), tiêu đề "Thu tiền", phụ đề "Ghi nhận khoản khách trả thêm cho đơn".
- `presentation/widgets/sales_record_payment_sheet.dart`: `Future<int?> showSalesRecordPaymentSheet(BuildContext context, {required String salesOrderId, required String orderNumber, required int outstandingMinor, String? dueDateFormatted})` — dựng cubit (lấy repository / context từ `GetIt` như trang chi tiết), mở bằng `showVAdaptiveSheet(title: 'Thu tiền', …)`. Nội dung theo mẫu SG-11 (`TH-05:1896-1908`): "Đơn <mã>", "Còn phải thu <số>", "Hẹn thanh toán <ngày>" (ẩn khi `null`), ô "Số tiền" (bộ định dạng nhóm số như ô tiền của SG-06), `VSegmentedControl` Tiền mặt / Chuyển khoản, ô "Mã giao dịch (Không bắt buộc)" khi Chuyển khoản, nút "Quay lại" / "Xác nhận thu tiền" (khoá khi `submitting`; `failure` + `canRetry` ⇒ chữ nút "Thử lại"). Khoá: `inp_sg11_amount`, `seg_sg11_method`, `inp_sg11_reference`, `btn_sg11_confirm`, `txt_sg11_error`.
- `sales_order_detail_page.dart` `_openActionsSheet`: truyền `canCollectPayment` (Q3); `case collectPayment:` mở sheet. Sheet trả **số tiền đã ghi nhận** (`int`, lấy `state.amountMinor` lúc `succeeded`) hoặc `null` (đóng mà chưa ghi). Khác `null` ⇒ `VToast` success "Đã ghi nhận <MoneyFormatter.formatMinor(amount)>". Sau khi sheet đóng **luôn** gọi `_cubit.refresh()` (kể cả `null`: lỗi `OVERPAYMENT_NOT_ALLOWED` / `ORDER_CANCELLED` nghĩa là số trên SG-09 đã cũ).

### 4.5 DI
Không thêm đăng ký (repository có sẵn). Factory dựng trong sheet.

## 5. Review Focus (chưa task nào test, phiên review soi)

1. **Thử lại sau khi sửa số tiền:** lỗi mạng, người dùng sửa số rồi bấm "Thử lại" ⇒ phải là attempt **mới** (nội dung khác); dùng lại khoá cũ ⇒ server `IDEMPOTENCY_CONFLICT`. Test 3.2 `changed_amount_creates_new_attempt` phủ cubit; review kiểm cả UI không giữ chữ "Thử lại" sai.
2. **Đơn vừa trả đủ ở máy khác:** mở sheet với `outstandingMinor` cũ ⇒ server `OVERPAYMENT_NOT_ALLOWED` ⇒ câu; đóng sheet ⇒ SG-09 tải lại (4.4) và không còn mục "Thu tiền". Test 4.2 `closed_without_payment_still_refreshes` phủ lời gọi; review kiểm trên máy thật.
3. **Bàn phím web:** Enter ở ô số tiền gửi đúng một lần (không cộng với nút đang focus); Esc khi `submitting` không được đóng sheet giữa chừng rồi mất kết quả.
4. **Số tiền lớn / dán chuỗi có dấu chấm:** ô tiền nhận "600.000" ⇒ 600000; không tràn `int`.
5. **"Thu tiền" khi khối thanh toán lỗi tải:** `paymentStatus != loaded` ⇒ không hiện mục (Q3) — không được rơi về `outstandingMinor = 0` rồi vẫn hiện.

## 6. Các bước

**Ràng buộc chung:** chỉ sửa tệp liệt kê; `impact` trước khi sửa symbol có sẵn (ghi bảng; HIGH / CRITICAL ⇒ dừng, báo); câu tiếng Việt chép nguyên văn mục 4; tệp test mới ở `apps/erp/test/features/sales/{data,logic,presentation}/`.

### Task 0: Mốc test có sẵn

- [x] **0.1** `cd apps/erp && flutter test test/features/sales/data/sales_payment_repository_test.dart test/features/sales/sales_order_detail_page_test.dart test/features/sales/presentation_module/bloc/sales_order_detail_cubit_test.dart` → PASS, ghi số.

### Task 1: Repository + lỗi

**Files:** Create: `data/models/sales_record_payment.dart`, `data/sales_payment_mutation_errors.dart`. Modify: `data/sales_payment_repository.dart`, `data/mappers/sales_payment_json.dart`, `test/features/sales/support/fake_sales_payment_repository.dart` (thêm `recordCalls`, `recordResult`, `List<Object> recordErrors` dạng hàng đợi). Test: `test/features/sales/data/sales_payment_repository_test.dart`, `test/features/sales/data/sales_payment_mutation_errors_test.dart`

**Produces:** `SalesRecordPaymentRequest`, `SalesRecordPaymentResult`, `SalesPaymentRepository.recordPayment`, `salesPaymentMutationException`.

- [x] **1.1** Test: `record_payment_params` (đủ 12 khoá ở 4.1; `p_source_context == 'additional_collection'`, `p_payment_method_snapshot` có khoá giá trị `null`, `method: manualBankTransfer` ⇒ `'manualBankTransfer'`); `record_payment_null_reference_keeps_key`; `record_payment_parses_result` (`outstandingMinor: 0`, `paymentStatus: 'paid'`); lỗi: mỗi mã Q6 giữ (`PERMISSION_DENIED` ⇒ `NO_PERMISSION`), `{"code":"WEIRD"}` ⇒ `SYSTEM_ERROR`, `FormatException` ⇒ `SYSTEM_ERROR`, JSON lồng 2 lớp `NOT_FOUND`… ⇒ `SYSTEM_ERROR` (không trong tập), `OVERPAYMENT_NOT_ALLOWED` lồng ⇒ giữ.
- [x] **1.2** Chạy → FAIL. Viết. Chạy → PASS.

### Task 2: Attempt factory

**Files:** Create: `presentation/support/sales_record_payment_attempt_factory.dart`. Test: `test/features/sales/presentation/support/sales_record_payment_attempt_factory_test.dart`

- [x] **2.1** Test: `same_content_same_hash` (2 lần `create` cùng đầu vào ⇒ `payloadHash` bằng nhau, `idempotencyKey` là `'sales-payment:a1'` / `'sales-payment:a2'` theo `newAttemptId`); `changed_amount_changes_hash`; `changed_method_changes_hash`; `changed_reference_changes_hash`; `reference_trimmed_empty_is_null` (`'  '` ⇒ `request.externalReference == null`, hash bằng ca `null`); `amount_zero_throws_context_invalid`; `hash_is_sha256_of_canonical_json`.
- [x] **2.2** Chạy → FAIL. Viết. Chạy → PASS.

### Task 3: Cubit

**Files:** Create: `logic/sales_record_payment_cubit.dart`, `logic/sales_record_payment_state.dart`. Test: `test/features/sales/logic/sales_record_payment_cubit_test.dart`

**Consumes:** Task 1, Task 2.

- [x] **3.1** Test: `default_amount_is_outstanding_and_method_cash`; `zero_amount_field_error` ("Số tiền phải lớn hơn 0.", không gọi repo); `over_outstanding_field_error` ("Số tiền vượt quá số còn phải thu.", không gọi repo); `submit_success` (AC-01: 600000 / 600000 ⇒ `succeeded`, 1 lời gọi, `request.amountMinor == 600000`, `method == cash`); `partial_success` (AC-02: 200000); `network_error_retry_reuses_key` (lần 1 `NETWORK_ERROR` ⇒ `failure`, `canRetry`; `submit()` lần 2 ⇒ `idempotencyKey` như lần 1) — AC-03; `changed_amount_creates_new_attempt`; `double_submit_ignored` (gọi `submit()` 2 lần không `await` ⇒ 1 lời gọi); mỗi dòng bảng câu lỗi 4.3 (câu nguyên văn + `canRetry`); `transfer_sends_trimmed_reference`; `cash_ignores_reference`.
- [x] **3.2** Chạy → FAIL. Viết. Chạy → PASS.

### Task 4: UI + nối trang chi tiết

**Files:** Create: `presentation/widgets/sales_record_payment_sheet.dart`. Modify: `presentation/widgets/sales_order_actions_sheet.dart`, `presentation/pages/sales_order_detail_page.dart:63-101`. Test: `test/features/sales/presentation/widgets/sales_record_payment_sheet_test.dart`, `test/features/sales/sales_order_detail_page_test.dart`

- [x] **4.1** Test sheet: `shows_outstanding_and_due_date` ("Còn phải thu", "Hẹn thanh toán"); `reference_only_for_transfer` (`inp_sg11_reference` `findsNothing` khi Tiền mặt, `findsOneWidget` khi Chuyển khoản); `confirm_disabled_while_submitting`; `retry_label_after_network_error` ("Thử lại"); `narrow_is_bottom_sheet_wide_is_dialog` (`tester.view.physicalSize` 390×844 ⇒ không có `VSheetDialog`; 1440×900 ⇒ có `VSheetDialog`); `enter_submits_once`; `escape_closes`.
- [x] **4.2** Test trang: `collect_payment_shown_when_outstanding` (payment `outstandingMinor: 600000`, đơn `committed` ⇒ `btn_order_action_collect_payment` có); `collect_payment_hidden_when_paid` (AC-04, `outstandingMinor: 0` ⇒ không có); `collect_payment_hidden_when_cancelled`; `collect_payment_hidden_when_payment_section_failed`; `success_toasts_and_refreshes` (fake trả kết quả ⇒ toast "Đã ghi nhận 600.000 ₫" — định dạng theo `MoneyFormatter.formatMinor` thật, ghi chuỗi vào Kết quả — và cubit `refresh` được gọi); `closed_without_payment_still_refreshes` (đóng sheet bằng "Quay lại" ⇒ không toast, `refresh` vẫn được gọi). Test có sẵn của 2 mục cũ giữ xanh.
- [x] **4.3** Chạy → FAIL. Viết. Chạy → PASS.

### Task 5: SQL + tài liệu + kiểm toàn bộ

**Files:** Modify: `supabase/tests/sales_th05.sql`; `docs/02-yeu-cau/TH-05-ban-hang-va-don-hang.md` (EP-04, SG-11, SG-09 FR-08 bỏ 🆕; 7.3 KI-06 "Đã làm 8-B3"; 9.2 dòng 8.3 ghi Thu tiền làm ở 8-B3); `docs/refactor/PLAN.md` (dòng 8-B3: Làm ✅ + ngày)

- [x] **5.1** `sales_th05.sql` thêm: P01 đơn còn 600.000, `record_sales_payment` 600.000 ⇒ `payment_status = 'paid'`, `outstanding_amount_minor = 0`, giao dịch `source_context = 'additional_collection'` đếm = 1; P02 thu 200.000 của đơn 600.000 ⇒ `partially_paid`, còn 400.000; P03 gọi lại cùng `p_idempotency_key` + `p_payload_hash` ⇒ cùng `transactionId`, đếm giao dịch không tăng; P04 cùng khoá khác hash ⇒ `IDEMPOTENCY_CONFLICT`.
- [x] **5.2** Sửa tài liệu.
- [x] **5.3** `cd apps/erp && dart analyze lib/features/sales test/features/sales` → 0 lỗi, 0 cảnh báo mới; `dart run tool/check_feature_imports.dart` → ghi dòng mới (chấp nhận cùng loại 8-A: `logic/` → `presentation/`, `data/` → `c45_sales_*`).
- [x] **5.4** `flutter test` cả app → số lỗi đúng bằng mốc sau 8-B2; 0 lỗi `features/sales`.
- [x] **5.5** `node .gitnexus/run.cjs analyze` rồi `detect-changes --repo erp-sales-inventory --scope all`: chỉ tệp trong plan; ghi số. Hoàn nguyên `AGENTS.md` / `CLAUDE.md` nếu bị sửa.

## 7. Kiểm tra

### 7.1 Tự động
Task 0–5.

### 7.2 Việc của người dùng
- DB local: chạy `supabase/tests/sales_th05.sql` (thêm P01–P04) → `sales_th05: OK`.
- Kiểm tay **kịch bản 2 TH-05 9.3** trên iPhone simulator và Chrome (rộng + hẹp): bán nợ khách A trả 40%, hẹn ngày → SG-09 "Thao tác" → "Thu tiền" → số mặc định = còn phải thu → Tiền mặt → xác nhận → toast, đơn "Đã thanh toán", lịch sử có "Ghi nhận thanh toán tiền mặt". Thêm: nhập vượt số nợ ⇒ câu chặn; Chuyển khoản + mã giao dịch; tắt mạng → "Thử lại" sau khi bật lại ⇒ 1 giao dịch; Chrome: Tab / Enter / Esc.

## 8. Rủi ro / lưu ý

- **Hash do client tính** (`record_sales_payment` dùng `p_payload_hash` gửi lên, khác `finalize`): cùng khoá khác nội dung chỉ bị chặn nếu hash khác ⇒ factory phải băm đủ trường nội dung (Task 2 `changed_*`).
- **Phiếu bán hàng phiên bản mới** (FR-04): do RPC phiếu sinh theo version settlement — không có việc ở app; kiểm tay: xem phiếu sau khi thu thấy số mới.
- **Kiểu module** (`SalesPaymentMethod`): 8-C chép.

## 9. Kết quả (phiên làm code ghi)

*Ngày thực hiện:* 2026-11-08.
*Môi trường:* macOS, Flutter test / Dart analyze, GitNexus re-index (49.935 nodes, 111.158 edges).

### 9.1 Tổng hợp các task

| Task | Trạng thái | Tệp tạo mới / sửa | Số test |
|---|---|---|---|
| Task 0 | ✅ Đạt | Không (chạy mốc ban đầu) | 83/83 pass |
| Task 1 | ✅ Đạt | 2 tạo mới (`sales_record_payment.dart`, `sales_payment_mutation_errors.dart`), 2 sửa repo/mapper, 2 sửa fake | 17/17 pass (6 errors + 11 repo) |
| Task 2 | ✅ Đạt | 1 tạo mới (`sales_record_payment_attempt_factory.dart`) | 7/7 pass |
| Task 3 | ✅ Đạt | 2 tạo mới (`sales_record_payment_state.dart`, `sales_record_payment_cubit.dart`) | 20/20 pass |
| Task 4 | ✅ Đạt | 1 tạo mới (`sales_record_payment_sheet.dart`), 2 sửa (`sales_order_actions_sheet.dart`, `sales_order_detail_page.dart`) | 72/72 pass (7 sheet + 65 detail page) |
| Task 5.1 | ✅ Đạt | `supabase/tests/sales_th05.sql` (thêm P01..P04) | Chưa chạy SQL (việc người dùng, 7.2) |
| Task 5.2 | ✅ Đạt | `docs/02-yeu-cau/TH-05-ban-hang-va-don-hang.md`, `docs/refactor/PLAN.md` | Tài liệu đồng bộ |
| Task 5.3 | ✅ Đạt | `dart analyze`, `check_feature_imports.dart` | 0 lỗi, 0 cảnh báo mới |
| Task 5.4 | ✅ Đạt | `flutter test` toàn bộ app | 2926 đạt / 55 lỗi = mốc (0 lỗi `features/sales`) |
| Task 5.5 | ✅ Đạt | GitNexus `analyze` & `detect-changes` | 13 files, 23 symbols, 0 flow, risk: low |

### 9.2 Chi tiết từng task

#### Task 0: Mốc test có sẵn
- Chạy: `sales_payment_repository_test.dart` (4 tests), `sales_order_detail_page_test.dart` (59 tests), `sales_order_detail_cubit_test.dart` (20 tests).
- Kết quả: **83/83 tests PASS**.

#### Task 1: Repository + lỗi
- **Tạo:**
  - `apps/erp/lib/features/sales/data/models/sales_record_payment.dart`: `SalesRecordPaymentRequest`, `SalesRecordPaymentResult`.
  - `apps/erp/lib/features/sales/data/sales_payment_mutation_errors.dart`: `salesPaymentMutationException` chuẩn hoá tập mã lỗi Q6 (`NO_PERMISSION`, `DATA_SCOPE_DENIED`, `CONTEXT_INVALID`, `REFERENCE_UNAVAILABLE`, `IDEMPOTENCY_CONFLICT`, `ORDER_CANCELLED`, `OVERPAYMENT_NOT_ALLOWED`, `NETWORK_ERROR`, còn lại `SYSTEM_ERROR`).
- **Sửa:**
  - `apps/erp/lib/features/sales/data/mappers/sales_payment_json.dart`: thêm `recordParams` (đủ 12 tham số) và `recordResultFromJson`.
  - `apps/erp/lib/features/sales/data/sales_payment_repository.dart`: thêm hàm `recordPayment`.
  - `apps/erp/test/features/sales/support/fake_sales_payment_repository.dart`: thêm `recordCalls`, `recordResult`, `recordErrors`, `Completer? recordCompleter`.
  - `apps/erp/test/features/sales/support/module_backed_sales_repositories.dart`: implement `recordPayment`.
- **Test:**
  - `apps/erp/test/features/sales/data/sales_payment_mutation_errors_test.dart`: 6 tests mới.
  - `apps/erp/test/features/sales/data/sales_payment_repository_test.dart`: thêm 7 tests mới (tổng 11 tests).
- Kết quả: **17/17 tests PASS**.

#### Task 2: Attempt factory
- **Tạo:**
  - `apps/erp/lib/features/sales/presentation/support/sales_record_payment_attempt_factory.dart`: `SalesRecordPaymentAttempt` (giữ `request`, `canonicalPayloadJson`, `payloadHash`), `SalesRecordPaymentAttemptFactory` tạo attempt với idempotency key `sales-payment:<attemptId>` và băm SHA-256 chuỗi canonical JSON.
- **Test:**
  - `apps/erp/test/features/sales/presentation/support/sales_record_payment_attempt_factory_test.dart`: 7 tests mới phủ: trùng hash khi cùng nội dung, khác hash khi đổi số tiền/phương thức/mã tham chiếu, mã tham chiếu rỗng trim thành `null`, số tiền <= 0 ném `CONTEXT_INVALID`, SHA-256 hex chính xác.
- Kết quả: **7/7 tests PASS**.

#### Task 3: Cubit
- **Tạo:**
  - `apps/erp/lib/features/sales/logic/sales_record_payment_state.dart`: `SalesRecordPaymentStatus`, `SalesRecordPaymentState` (`amountMinor`, `method`, `externalReference`, `fieldError`, `errorMessage`, `canRetry`, `result`).
  - `apps/erp/lib/features/sales/logic/sales_record_payment_cubit.dart`: quản lý trạng thái nhập, kiểm tra số tiền `<= 0` hoặc `> outstandingMinor`, chống gọi đúp khi đang submitting, tái sử dụng attempt khi lỗi mạng/xung đột, tạo attempt mới khi đổi số tiền, ánh xạ câu lỗi nghiệp vụ tiếng Việt theo 4.3.
- **Test:**
  - `apps/erp/test/features/sales/logic/sales_record_payment_cubit_test.dart`: 20 tests mới phủ toàn diện các ca kiểm thử.
- Kết quả: **20/20 tests PASS**.

#### Task 4: UI + nối trang chi tiết
- **Tạo:**
  - `apps/erp/lib/features/sales/presentation/widgets/sales_record_payment_sheet.dart`: `showSalesRecordPaymentSheet` dùng `showVAdaptiveSheet` (iPhone: bottom sheet, Desktop: `VSheetDialog` rộng tối đa 480). Các trường theo SG-11, phím tắt Enter/Esc, dùng `VField` + `VFieldError` chuẩn design system.
- **Sửa:**
  - `apps/erp/lib/features/sales/presentation/widgets/sales_order_actions_sheet.dart`: thêm action `collectPayment`, cờ `canCollectPayment`, tile `Key('btn_order_action_collect_payment')` tại vị trí đầu danh sách.
  - `apps/erp/lib/features/sales/presentation/pages/sales_order_detail_page.dart`: kiểm tra điều kiện hiện mục (`committed`, `paymentStatus == loaded`, `outstandingMinor > 0`), mở sheet, toast `Đã ghi nhận <số>`, và luôn gọi `_cubit.refresh()`.
- **Test:**
  - `apps/erp/test/features/sales/presentation/widgets/sales_record_payment_sheet_test.dart`: 7 tests mới.
  - `apps/erp/test/features/sales/sales_order_detail_page_test.dart`: thêm 6 tests mới (tổng 65 tests).
- Kết quả: **72/72 tests PASS** (chạy toàn bộ 6 file test liên quan của Task 0..4: **136/136 test assertions PASS**).

#### Task 5: SQL + tài liệu + kiểm toàn bộ
- **5.1 Test SQL:** `supabase/tests/sales_th05.sql`: Thêm 4 khối P01..P04 (`P01` thu đủ 600.000, `P02` thu 200.000 nợ còn 400.000, `P03` lặp lại cùng idempotency key + hash ⇒ cùng transactionId và đếm giao dịch không đổi, `P04` cùng key khác hash ⇒ `IDEMPOTENCY_CONFLICT`). Tuân thủ bài học R2-1 từ 8-B2: các khối test được bọc `reset role;` ... `set local role authenticated;` để không bị chặn bởi RLS. Không chạy SQL (chờ người dùng thực hiện ở 7.2).
- **5.2 Tài liệu:**
  - `docs/02-yeu-cau/TH-05-ban-hang-va-don-hang.md`: Bỏ `🆕` ở EP-04, SG-11, SG-09 FR-08; cập nhật 7.3 KI-06 ("Đã làm 8-B3"); cập nhật 9.2 dòng 8.3.
  - `docs/refactor/PLAN.md`: Dòng 8-B3 cập nhật cột Làm thành `✅ 2026-11-08`.
- **5.3 Phân tích tĩnh & Feature Imports:**
  - `dart analyze lib/features/sales test/features/sales`: **0 errors, 0 warnings** (9 info `deprecated_member_use` có sẵn từ phase trước). Đã dọn dẹp import `flutter_bloc` và chuyển sang `VField` + `VFieldError`.
  - `dart run tool/check_feature_imports.dart`: Có thêm 2 dòng R2 (`sales_record_payment_cubit.dart` import `i_sales_active_store_context.dart` và `sales_record_payment_attempt_factory.dart` ở `presentation/support/`), đúng quy ước cấu trúc có sẵn của `sales_checkout_cubit` và `sales_order_list_cubit` như plan đã ghi nhận.
- **5.4 Full test suite:**
  - `flutter test` cả app: **2926 đạt / 55 lỗi** (đúng chính xác bằng 55 lỗi baseline sau 6-C và 8-B2; không phát sinh bất kỳ lỗi mới nào; **0 lỗi ở `features/sales`**).
- **5.5 GitNexus Detect Changes:**
  - Đã chạy `node .gitnexus/run.cjs analyze` (re-index hoàn tất trong 100.9s: 49.935 nodes, 111.158 edges).
  - Đã chạy `detect-changes -s all -r erp-sales-inventory`: 13 files thay đổi, 23 symbols, 0 flow bị ảnh hưởng, risk level: **LOW**.
  - Đã hoàn nguyên `AGENTS.md` và `CLAUDE.md` về trạng thái ban đầu của commit git.

### 9.3 Bảng Impact Analysis (GitNexus)

| Ký hiệu | Tệp | Gọi trực tiếp / Bị ảnh hưởng | Đánh giá rủi ro |
|---|---|---|---|
| `SalesPaymentRepository.recordPayment` | `apps/erp/lib/features/sales/data/sales_payment_repository.dart` | `SalesRecordPaymentCubit` | LOW (hàm mới thêm) |
| `SalesOrderSheetAction.collectPayment` | `apps/erp/lib/features/sales/presentation/widgets/sales_order_actions_sheet.dart` | `SalesOrderDetailPage._openActionsSheet` | LOW (thêm giá trị enum mới) |
| `showSalesOrderActionsSheet` | `apps/erp/lib/features/sales/presentation/widgets/sales_order_actions_sheet.dart` | `SalesOrderDetailPage` | LOW (thêm tham số tuỳ chọn `canCollectPayment = false`) |
| `_SalesOrderDetailPageState._openActionsSheet` | `apps/erp/lib/features/sales/presentation/pages/sales_order_detail_page.dart` | Private state method | LOW (chỉ thêm nhánh `collectPayment`) |

### 9.4 Chuỗi Toast thật & Bảng Lệch Plan

- **Chuỗi toast thành công thực tế:** `'Đã ghi nhận 600.000đ'` (do `MoneyFormatter.formatMinor(600000)` sinh ra không có khoảng trắng trước `đ`, khác với ước đoán `'600.000 ₫'` trong plan 4.2). Đã được kiểm chứng qua `sales_order_detail_page_test.dart:711`.

| Hạng mục | Trong Plan | Thực tế triển khai | Lý do |
|---|---|---|---|
| Tham số `cubit` trong sheet | Không có trong chữ ký 4.4 | Thêm `SalesRecordPaymentCubit? cubit` vào `showSalesRecordPaymentSheet` | Cho phép inject cubit giả/mock trong widget test mà không phụ thuộc DI toàn cục |
| Async timing trong fake repo | Chỉ thêm `recordCalls`, `recordResult`, `recordErrors` | Bổ sung `Completer<SalesRecordPaymentResult>? recordCompleter` | Giữ trạng thái asynchronous có chủ đích trong widget test để kiểm tra `isLoading / disabled` |
| File hỗ trợ test ngoài plan | Chỉ danh sách tệp Task 1 | Sửa thêm `test/.../module_backed_sales_repositories.dart` | Cần implement stub `recordPayment` để tránh lỗi abstract class khi chạy `sales_order_detail_page_test` |

### 9.5 Kết quả sửa các lỗi Review 1 (R1)

- **Task R1-1 (SQL):**
  - Sửa `supabase/tests/sales_th05.sql`: Đổi `null` $\rightarrow$ `v_today + 7` ở 2 lần gọi `_th05_finalize` dòng 840 và 882 (khắc phục lỗi server ném `RECEIVABLE_DUE_DATE_REQUIRED` khi phát sinh nợ mà không có ngày hẹn).
  - Đổi `'partiallyPaid'` $\rightarrow$ `'partially_paid'` ở dòng 906 và câu raise exception dòng 907 (khớp đúng enum snake_case của database schema).
- **Task R1-2 (Cubit & UI - Focus 1):**
  - Sửa `apps/erp/lib/features/sales/logic/sales_record_payment_cubit.dart`: Trong 3 setter `setAmountMinor`, `setMethod`, `setExternalReference`, nếu `state.status == SalesRecordPaymentStatus.failure` thì đặt lại `status: SalesRecordPaymentStatus.editing` và `canRetry: false` (giữ lại `_attempt`).
  - Thêm test `edit_after_network_error_resets_retry` trong `sales_record_payment_cubit_test.dart`.
  - Thêm test `retry_label_cleared_after_edit` trong `sales_record_payment_sheet_test.dart`.
- **Task R1-3 (Loại bỏ store giả):**
  - Xoá hoàn toàn `_DefaultActiveStoreContext` khỏi `sales_record_payment_sheet.dart`.
  - Chuẩn hoá `_SalesRecordPaymentActiveStoreAdapter` chỉ uỷ quyền trực tiếp qua `SessionController.requireActiveStoreId()`.
  - Bổ sung đăng ký `SessionController` (dùng `testSessionController`) trong `setUp` của `sales_order_detail_page_test.dart`.
- **Task R1-4 (Đóng cubit):**
  - Trong `showSalesRecordPaymentSheet`: Khi `cubit == null`, bổ sung `sheetFuture.whenComplete(() => effectiveCubit.close())` để đóng cubit khi sheet kết thúc.
- **Kiểm tra sau R1:**
  - 7 tệp test mục tiêu Task 0–4: **138/138 PASS** (tăng 2 tests so với 136).
  - `dart analyze lib/features/sales test/features/sales`: **0 errors, 0 warnings** (9 info `deprecated_member_use` có sẵn).

---

## 10. Review

### R1 — 2026-11-08: **CHƯA ĐẠT**

| Hạng mục | Kết quả |
|---|---|
| Test mục tiêu (7 tệp Task 0–4) | ✅ chạy lại: 136/136 PASS (83 mốc + 53 mới, khớp mục 9) |
| `flutter test` cả app | ✅ chạy lại: +2926 −55 (= mốc), 0 lỗi `features/sales` — khớp mục 9 |
| `dart analyze lib/features/sales test/features/sales` | ✅ 0 lỗi, 0 cảnh báo (9 info `deprecated_member_use` có sẵn) |
| `check_feature_imports` | ✅ đúng 2 dòng R2 mới như mục 9 (`logic/` → `presentation/support/`) |
| Repository / lỗi / factory / cubit (4.1–4.3) | ✅ đúng plan: đủ 12 khoá, tập mã Q6, hash băm đủ trường nội dung, dùng lại attempt khi cùng hash, bảng câu lỗi nguyên văn |
| Trang chi tiết (Q3, 4.4) | ✅ điều kiện hiện mục đủ 3 vế (kể cả `paymentStatus == loaded` — Focus 5), luôn `refresh()` sau khi đóng |
| Tài liệu TH-05 / PLAN.md | ✅ |
| **Test SQL P01–P04** | ❌ chắc chắn lỗi khi chạy (R1-1) |
| **Focus 1 — chữ "Thử lại" sau khi sửa** | ❌ (R1-2) |
| Sheet lấy cửa hàng | ❌ có cửa hàng giả `'store-1'` trong `lib/` (R1-3) |
| Focus 3 (Enter / Esc) | ✅ Enter: cubit chặn gửi lần 2; Esc khi `submitting`: `PopScope(canPop: false)` chặn. ⚠ Kéo để đóng bottom sheet trên iPhone có thể bỏ qua `PopScope` — kiểm tay ở 7.2 (nếu xảy ra: tiền vẫn ghi, không toast, SG-09 vẫn tải lại — không mất dữ liệu) |
| Focus 4 (số lớn / dán "600.000") | ✅ bộ định dạng bỏ ký tự không phải số; quá `int` ⇒ `parseMinor` trả 0 ⇒ "Số tiền phải lớn hơn 0." (không crash) |

### R1 — việc cần sửa

**R1-1 (cao) — `supabase/tests/sales_th05.sql` P01–P04 sẽ fail.**
- P01 / P02 tạo đơn còn nợ bằng `_th05_finalize(…, public._th05_pay(400000), null, …)`: `p_due = null` ⇒ server ném `RECEIVABLE_DUE_DATE_REQUIRED` (`20261031017_sales_buyer_invoice_snapshot.sql:440-445`), test dừng trước P01. Mẫu đúng: C11 `sales_th05.sql:491` dùng `v_today + 7`.
- P02 so `v_p_status is distinct from 'partiallyPaid'`, nhưng cột `payment_status` lưu `'partially_paid'` (check `20260830005_sales_rebuild_schema.sql:206`; plan 5.1 cũng ghi `partially_paid`).
- Task R1-1-1: đổi `null` ⇒ `v_today + 7` ở 2 lần `_th05_finalize` của khối P; đổi `'partiallyPaid'` ⇒ `'partially_paid'` (cả câu `raise`). Không chạy SQL (việc người dùng, 7.2).

**R1-2 (vừa) — nút vẫn ghi "Thử lại" sau khi người dùng sửa đầu vào (Focus 1).**
- `sales_record_payment_cubit.dart` `setAmountMinor` / `setMethod` / `setExternalReference` chỉ xoá `errorMessage`, giữ `status = failure` + `canRetry = true` ⇒ `sales_record_payment_sheet.dart:296-299` vẫn hiện "Thử lại" dù lần bấm sau là attempt **mới** (nội dung khác). Gửi thì đúng (cubit dựng attempt mới theo hash), nhưng chữ nút sai.
- Task R1-2-1: 3 setter đặt `status: editing`, `canRetry: false` khi trạng thái đang là `failure` (giữ `_attempt` — sửa lại về đúng số cũ vẫn trùng hash ⇒ dùng lại khoá, đúng Q2).
- Task R1-2-2: test cubit `edit_after_network_error_resets_retry` (sau `NETWORK_ERROR`, `setAmountMinor(500000)` ⇒ `status == editing`, `canRetry == false`); test sheet `retry_label_cleared_after_edit` (sau lỗi mạng, nhập số khác ⇒ nút "Xác nhận thu tiền").

**R1-3 (vừa) — cửa hàng giả trong code chạy thật.**
- `sales_record_payment_sheet.dart:33-41` `_DefaultActiveStoreContext` trả `'store-1'` khi GetIt không có `ISalesActiveStoreContext` lẫn `SessionController` — đường dành cho test nằm trong `lib/`; nếu đăng ký DI đổi, app gửi `p_store_id = 'store-1'` thay vì báo lỗi. Thêm nữa `_SalesRecordPaymentActiveStoreAdapter:24-30` tự đọc `activeStoreId` và tự ném `DATA_SCOPE_DENIED`, khác 3 adapter có sẵn (vd `sales_checkout_page.dart:428-438` gọi `SessionController.requireActiveStoreId()`).
- Task R1-3-1: bỏ `_DefaultActiveStoreContext` và nhánh `isRegistered<ISalesActiveStoreContext>`; adapter chỉ chuyển tiếp `activeStoreId` / `requireActiveStoreId()` của `SessionController` (như checkout). Test trang / sheet cần cửa hàng thì đăng ký `SessionController` giả hoặc truyền `cubit` (tham số đã có). 136 test mục tiêu phải còn xanh.

**R1-4 (thấp) — cubit không được đóng.** `showSalesRecordPaymentSheet:74-96` tự dựng cubit nhưng dùng `BlocProvider.value` và không `close()`.
- Task R1-4-1: khi cubit do hàm tự dựng (`cubit == null`), gọi `close()` sau khi `showVAdaptiveSheet` trả về (`whenComplete`); cubit truyền vào thì để bên gọi đóng.

**R1-5 (thấp) — mục 9 thiếu / lệch chưa ghi.**
- Plan 4.2 yêu cầu ghi chuỗi toast thật: test dùng `'Đã ghi nhận 600.000đ'` (`sales_order_detail_page_test.dart:711`), plan đoán `600.000 ₫` — ghi vào mục 9.
- Lệch plan chưa đánh dấu là lệch: tham số `SalesRecordPaymentCubit? cubit` thêm vào `showSalesRecordPaymentSheet` (chữ ký 4.4 không có); sửa `test/.../module_backed_sales_repositories.dart` (ngoài danh sách tệp Task 1); `recordCompleter` trong fake.
- Task R1-5-1: bổ sung vào mục 9 một bảng "Lệch plan" + chuỗi toast; ghi kết quả R1 theo mẫu (tệp:dòng, test).

**Sau khi sửa:** chạy lại 7 tệp test mục tiêu + `dart analyze lib/features/sales test/features/sales`; ghi số vào mục 9 (phần R1). Lượt kiểm tiếp theo là R2.

### R2 — 2026-11-08: **ĐẠT**

| Việc R1 | Kiểm lại | Kết quả |
|---|---|---|
| R1-1 SQL | `sales_th05.sql:840`, `:882` dùng `v_today + 7`; `:906-907` so `'partially_paid'` | ✅ (chưa chạy SQL — việc người dùng, 7.2) |
| R1-2 "Thử lại" sau khi sửa | 3 setter của cubit đưa `failure` ⇒ `editing`, `canRetry = false`, giữ `_attempt`; test `edit_after_network_error_resets_retry` (cubit) + `retry_label_cleared_after_edit` (sheet: nhập "500.000" ⇒ "Xác nhận thu tiền", không còn "Thử lại") | ✅ |
| R1-3 cửa hàng giả | `_DefaultActiveStoreContext` đã bỏ; adapter chuyển tiếp `SessionController.requireActiveStoreId()` như checkout; test trang đăng ký `testSessionController` (`sales_order_detail_page_test.dart:58-64`) | ✅ |
| R1-4 đóng cubit | `whenComplete(close)` chỉ khi hàm tự dựng cubit | ✅ |
| R1-5 mục 9 | 9.4: chuỗi toast `'Đã ghi nhận 600.000đ'` + bảng lệch plan (tham số `cubit`, `recordCompleter`, `module_backed_sales_repositories.dart`) | ✅ |

Số liệu chạy lại: 7 tệp mục tiêu **138/138** (khớp 9.5); `flutter test test/features/sales` **1279/1279**; `dart analyze lib/features/sales test/features/sales` 0 lỗi, 0 cảnh báo (9 info cũ). Phần sửa R1 chỉ đụng `features/sales` nên không chạy lại cả app (R1: +2926 −55 = mốc).

**Còn lại (người dùng, 7.2):** chạy `supabase/tests/sales_th05.sql` → `sales_th05: OK`; kiểm tay kịch bản 2 trên iPhone + Chrome, gồm kéo để đóng sheet khi đang gửi (ghi chú Focus 3 ở R1).
