# T6-2c — Sửa màn cũ: cấn trừ ở đổi/trả, lối vào công nợ Implementation Plan

> Phase: Theme 6 · Trạng thái: Plan ✅ (duyệt 2026-11-19) | Làm ⬜ | Review ⬜
> Tài liệu liên quan: PLAN mục Theme 6 (T6-2c), [TH-06](../../../02-yeu-cau/TH-06-cong-no.md) 4.4–4.5, 5.1, 5.5, 5.6, 6.2–6.3, 7.3, 9.1, 9.3; [T6-1b](T6-1b-cong-no-thu-theo-khach-can-tru.md); [T6-2a prototype](T6-2a-prototype.md); [T6-2b](T6-2b-flutter-cong-no.md)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. (Dự án này: **người dùng tự code**, Claude review ở phiên khác.)

**Goal:** Kịch bản 9.1 TH-06 chạy từ đầu đến cuối trên iPhone và web: SG-13 cho tick đơn cấn trừ và gửi đúng đơn khi xác nhận; SG-14, phiếu đổi/trả, SG-09b, SG-09c, phiếu bán hàng hiện đúng tiền cấn trừ; SG-09 và PT-07 có lối vào CN-02; bỏ thu tiền từng đơn (SG-11).

**Architecture:** Một migration nhỏ sửa hai RPC (xác nhận ghi lại cách chia thật; lịch sử đơn gắn nhãn thu theo khách). Phía app: tầng dữ liệu `sales` nhận phương thức `offset` và các khoá mới → hàm thuần `planReturnSettlement` (tính lại khi tick) → cubit quyết toán giữ danh sách đơn đang tick → dựng lại nhánh "khách được hưởng" của SG-13 theo `sg13.js`; các màn còn lại chỉ thêm dòng. PT-07 nhận khối Công nợ qua tham số `customerSection` (khuôn `supplierSection`, partner không import receivable).

**Tech Stack:** Flutter (flutter_bloc, go_router, get_it), `vet45_design_system`, PostgreSQL plpgsql (Supabase local).

**Spec:** TH-06 v1.0 + prototype đã chốt `specs/themes/theme-06/03.design/prototype/html/` (`app/sg13.js`, `app/patches.js`, `app/allocate.js`, `styles/receivable.css`) + thiết kế duyệt trong chat 2026-11-19 (hướng A; bổ sung migration cùng ngày).

## Global Constraints

- Lệnh DB (`supabase db reset`, `psql`, `tools/db_check.sh`) **người dùng tự chạy local**. Không sửa migration cũ.
- Thân hàm trong migration **sinh từ DB local** (`pg_get_functiondef`) rồi vá đúng chỗ ghi trong Task 1 (cách 2, như T6-1a). Không gõ lại tay.
- Định dạng tiền: khối **mới hoàn toàn** (nhánh "khách được hưởng" SG-13, khối Công nợ PT-07) dùng `formatVnd` / `formatVndBare` của `receivable_format.dart` (`500.000 ₫` / `500.000`); dòng **chen vào khối cũ** (SG-09b, SG-14, phiếu PDF, sheet xác nhận) dùng định dạng sẵn của khối đó (`MoneyFormatter.formatMinor`). Mọi số: `FontFeature.tabularFigures()`.
- Chữ trên màn **đúng nguyên văn** prototype chép trong task. Nhãn hạn dùng `orderDueLabel` + `ReceivableDueBadge` (T6-2b), số ngày quá hạn lấy từ server (`overdueDays`).
- Màu / khoảng / bo góc dùng token Dart (`context.vColors.*`, `VColors.neutral*`, `VSpacing.*`, `VRadius.*`, `VTypography.*`); không gõ mã màu.
- Vùng chạm ≥ 44 (`VSpacing.minTouchTarget`): ô cấn trừ, dòng "Xem công nợ của khách", dòng giao dịch cấn trừ, khối Công nợ PT-07.
- App **không bao giờ gửi** mã `offset` (chỉ nhận): mọi hàm đổi enum → chữ gửi RPC ném `ArgumentError` với `offset`.
- Mở CN-02 từ màn khác chỉ qua `openCustomerReceivable(context, customerId)` (Task 6): iPhone `context.push`, web `context.go` tới `/more/receivables/<id>`.
- Ảnh đích: `docs/refactor/plans/T6/img/T6-2c/proto-SG-13-<state>-390|1280.png` (16 ảnh) và `proto-patch-<sg09|sg09b|sg09c|sg14|pt07>-390|1280.png` (10 ảnh) — đã chép. Golden Flutter ghi cạnh đó tên `flutter-…`.
- CLAUDE.md: trước khi sửa symbol có sẵn chạy GitNexus `impact({target, direction: "upstream"})`, ghi blast radius vào **Kết quả**; HIGH/CRITICAL thì dừng báo người dùng. Trước commit cuối chạy `detect_changes({scope: "compare", base_ref: "main"})`.

## Quyết định (chốt trong chat 2026-11-19 + quyết định của Claude, bạn sửa nếu sai)

1. Hướng A: dựng lại nhánh "khách được hưởng" SG-13 theo prototype, tick thì tính lại trên máy; server kiểm lại khi xác nhận. *(bạn chốt)*
2. Thêm một migration: xác nhận đổi/trả ghi lại cách chia **thật** vào `receivable.return_exchange_settlement_plans`; lịch sử đơn gắn `description = 'Ghi nhận thu nợ theo khách'` cho sự kiện thu theo khách. *(bạn duyệt)*
3. Xoá hẳn SG-11 (sheet, cubit, attempt factory, model, hàm repo, mapper, test). *(bạn duyệt)*
4. "Giảm nợ đơn này" lấy nguyên `receivableReverseAmountMinor` của server; phần đem chia = `offsetAmountMinor + refundAmountMinor` (giữ BR-27 do server tính). *(Claude)*
5. Lệnh xác nhận gửi `offset_target_order_ids` = các đơn đang tick **có số trừ > 0**, cũ trước (kết quả server giống hệt khi gửi cả đơn trừ 0, nhưng tránh `STALE_VERSION` vì một đơn không dùng tới). Khoá chống trùng băm cả danh sách này. *(Claude)*
6. `STALE_VERSION` / `OFFSET_TARGET_INVALID` khi **có** gửi đơn cấn trừ: không tự tải lại; hiện hộp thoại như ảnh `stale` (`Tải lại` → định giá lại, chọn lại tất cả). Không gửi đơn cấn trừ thì giữ hành vi cũ (tự tải lại + băng cảnh báo). *(Claude)*
7. Nhánh "khách được hưởng": chân trang chỉ có nút "Xác nhận đổi/trả" (như ảnh), bỏ cặp nhãn–số "Cần hoàn tiền". Hai nhánh còn lại giữ nguyên. *(prototype)*
8. SG-09b "Đã cấn trừ" = `collectedOffset + refundedOffset` (một đơn thường chỉ ở một phía), đặt trong khối "Tình trạng hiện tại"; hướng xem ở dòng giao dịch. *(Claude)*
9. PT-07: khối Công nợ đặt ngay dưới `PartnerDetailMainInfoCard`; đang tải hoặc lỗi thì **ẩn** khối (không làm hỏng PT-07). *(Claude)*
10. `planReturnSettlement` đặt ở `features/sales/logic` (dùng DTO của sales), không import chéo receivable cho phần tính; SG-13 chỉ import từ receivable phần hiển thị (`formatVnd`, `orderDueLabel`, `ReceivableDueBadge`). *(Claude)*

## Review Focus

1. **Bỏ tick rồi xác nhận, màn kết quả phải ra số thật** — SC-02: bỏ DH-002 → SG-14 "Hoàn cho khách 500.000đ", không có dòng "Cấn trừ vào DH-002"; phiếu đổi/trả không có dòng cấn trừ. Test: Task 1 ca B15 (DB), Task 6 `result shows actual split after untick`.
2. **Tick lại sau khi tải lại vì STALE** — sau `Tải lại`, danh sách đơn đề xuất mới (DH-002 đã hết nợ thì biến mất), tick mặc định là tất cả đơn **mới**, không giữ id cũ không còn trong danh sách. Test: Task 4 `reload after stale reselects new candidates`.
3. **Đơn nhận đã hết nợ ở chỗ khác, lần xác nhận thứ hai** — khoá chống trùng phải đổi khi danh sách đơn gửi đổi; thử lại cùng danh sách giữ khoá. Test: Task 2 `confirm hash includes offset targets`, Task 4 `retry keeps attempt when targets unchanged`.
4. **Có cấn trừ rồi mở đơn / phiếu** — DH-001 và DH-002 mở SG-09b, phiếu bán hàng, lịch sử không lỗi đọc. Test: Task 2 `parses offset method in receipt / transactions`.
5. **Khách lẻ và đối tác chỉ là NCC** — SG-09 đơn khách lẻ không có dòng "Xem công nợ của khách"; PT-07 NCC không gọi RPC công nợ. Test: Task 7 `walk-in has no receivable link`, Task 8 `supplier only has no section`.

---

## File Structure

| File | Hành động | Trách nhiệm |
|---|---|---|
| `supabase/migrations/20261126001_receivable_offset_actual_split.sql` | tạo | Task 1: `confirm_return_exchange` ghi cách chia thật; `get_sales_order_timeline` nhãn thu theo khách |
| `supabase/tests/receivable_th06.sql` | sửa | Task 1: ca B15, B16 |
| `supabase/migrations/REGISTRY.yaml` | sinh lại | Task 1 |
| `apps/erp/lib/features/sales/data/models/contracts/sales_contract_enums.dart` | sửa | Task 2: `SalesPaymentMethod.offset` |
| `…/sales/data/models/contracts/return_exchange_settlement_plan_dto.dart` | sửa | Task 2: `offsetAmountMinor`, `offsetCandidates` + `ReturnExchangeOffsetCandidateDto` |
| `…/sales/data/models/contracts/sales_payment_transaction_dto.dart`, `sales_order_payment_summary_dto.dart` | sửa | Task 2: khoá đối ứng, `collectedOffset` / `refundedOffset` |
| `…/sales/data/models/return_exchange_requests.dart` | sửa | Task 2: `offsetTargetOrderIds` |
| `…/sales/data/mappers/return_exchange_json.dart`, `sales_payment_json.dart`, `sales_receipt_json.dart`, `sales_checkout_json.dart` | sửa | Task 2 |
| `…/sales/presentation/support/sales_return_exchange_attempt_factory.dart` | sửa | Task 2: băm `offsetTargetOrderIds` |
| `…/sales/presentation/support/sales_order_detail_mapper.dart`, `sales_receipt_pdf_generator.dart` | sửa | Task 2: nhãn "Cấn trừ"; Task 7: dòng SG-09b, SG-09c |
| `…/sales/logic/return_settlement_preview.dart` | tạo | Task 3: `planReturnSettlement` |
| `…/sales/logic/sales_return_exchange_settlement_{cubit,state}.dart` | sửa | Task 4 |
| `…/sales/logic/sales_post_sale_error_messages.dart` | sửa | Task 4: `OFFSET_TARGET_INVALID` |
| `…/sales/presentation/widgets/sales_return_entitled_settlement.dart` | tạo | Task 5: nhánh "khách được hưởng" (hero, thẻ chia, khối cấn trừ) |
| `…/sales/presentation/widgets/sales_return_exchange_settlement_body.dart`, `sales_return_confirm_settlement_sheet.dart`, `pages/sales_return_exchange_settlement_page.dart` | sửa | Task 5 |
| `…/receivable/presentation/receivable_navigation.dart` | tạo | Task 6: `openCustomerReceivable` |
| `…/sales/presentation/widgets/sales_return_exchange_result_body.dart`, `sales_return_result_action_bar.dart`, `pages/sales_return_exchange_result_page.dart`, `support/sales_slip_pdf_generator.dart` | sửa | Task 6 |
| SG-11: `sales_record_payment_sheet.dart`, `sales_record_payment_{cubit,state}.dart`, `sales_record_payment_attempt_factory.dart`, `data/models/sales_record_payment.dart` (+ 4 test) | xoá | Task 7 |
| `…/sales/presentation/pages/sales_order_detail_page.dart`, `widgets/sales_order_actions_sheet.dart`, `widgets/sales_order_payment_debt_page.dart`, `models/sales_order_settlement/sales_order_payment_vm.dart`, `data/sales_payment_repository.dart` | sửa | Task 7 |
| `…/receivable/data/{receivable_models,receivable_repository}.dart` | sửa | Task 8: `getSummary` |
| `…/receivable/presentation/widgets/customer_receivable_summary_card.dart` | tạo | Task 8 |
| `…/partner/presentation/pages/partner_detail_page.dart`, `core/router/app_router.dart` | sửa | Task 8: `customerSection` |
| `docs/02-yeu-cau/TH-06-cong-no.md`, TH-05, TH-03, `docs/refactor/PLAN.md` | sửa | Task 9 |

---

### Task 1: DB — xác nhận ghi cách chia thật, nhãn thu theo khách

**Files:**
- Create: `supabase/migrations/20261126001_receivable_offset_actual_split.sql`
- Modify: `supabase/tests/receivable_th06.sql` (thêm B15 sau khối B06 dòng ~1050; B16 sau A07 dòng ~655)
- Modify: `supabase/migrations/REGISTRY.yaml`, TH-06 6.2

**Interfaces:**
- Produces: sau khi xác nhận, `get_return_exchange_detail.settlementPlan` có `offsetAmountMinor` = Σ cấn trừ thật, `refundAmountMinor` = số hoàn thật, `offsetCandidates[i].offsetAmountMinor` = số trừ thật của đơn đó (0 nếu không tick). Timeline: dòng `sales_payment_recorded.v1` có `customerCollectionId` → `description = 'Ghi nhận thu nợ theo khách'`.

- [ ] **Bước 1: Viết ca test đỏ.**

```sql
-- B15 (sau B06 confirm-a: bỏ hết cấn trừ, plan đề xuất cấn 200k vào g2)
v_res := sales.get_return_exchange_detail(gen_random_uuid()::text, v_ta, v_ua, (v_rx_a ->> 'id')::uuid);
perform public._th06_expect('B15 offset thật = 0', v_res #>> '{settlementPlan,offsetAmountMinor}', '0');
perform public._th06_expect('B15 hoàn thật = 200000', v_res #>> '{settlementPlan,refundAmountMinor}', '200000');
perform public._th06_expect('B15 ứng viên g2 trừ 0',
  (select c ->> 'offsetAmountMinor' from jsonb_array_elements(v_res #> '{settlementPlan,offsetCandidates}') c
   where c ->> 'salesOrderId' = v_g2::text), '0');
-- B15b: ca B02 (tick cả hai) vẫn offset 500000, hoàn 0 sau xác nhận (đọc lại ở khối B12 "đã xác nhận")
-- B16 (sau A07): timeline đơn 2 có description thu theo khách
perform public._th06_expect('B16 nhãn thu theo khách',
  (select count(*)::text from jsonb_array_elements(
     sales.get_sales_order_timeline(gen_random_uuid()::text, v_ta, v_ua, v_o2) -> 'entries') e
   where e ->> 'eventType' = 'sales_payment_recorded.v1'
     and e ->> 'description' = 'Ghi nhận thu nợ theo khách'), '1');
```

(Biến `v_rx_a` = kết quả `_th06_return` lần `th06-g1-start-a`; lưu lại thay vì ghi đè. `v_o2` = đơn 2 của khối A.)

- [ ] **Bước 2: Người dùng chạy** `tools/db_check.sh --no-reset receivable_th06` → `FAIL: B15 offset thật = 0` (đang là 200000).

- [ ] **Bước 3: Sinh thân hai hàm từ DB local** (`pg_get_functiondef` của `sales.confirm_return_exchange` bản 14 tham số và `sales.get_sales_order_timeline`) vào migration, đầu file theo `_migration.template.sql` (Kind `patch`, Touches `confirm_return_exchange, get_sales_order_timeline`, Depends on `20261125001_receivable_history_actor_name`). Vá:

  - `confirm_return_exchange`: thay câu `update receivable.return_exchange_settlement_plans set status = 'confirmed' where id = v_pl.id;` bằng:

```sql
  update receivable.return_exchange_settlement_plans p
  set status = 'confirmed',
      offset_amount_minor = x.actual,
      refund_amount_minor = p.offset_amount_minor + p.refund_amount_minor - x.actual,
      offset_candidates = coalesce((
        select jsonb_agg(c || jsonb_build_object('offsetAmountMinor', coalesce((
                 select sum(ro.amount_minor) from receivable.receivable_offsets ro
                 where ro.tenant_id = p.tenant_id and ro.return_exchange_order_id = v_session.id
                   and ro.target_sales_order_id = (c ->> 'salesOrderId')::uuid), 0))
               order by ord)
        from jsonb_array_elements(p.offset_candidates) with ordinality e(c, ord)), '[]'::jsonb)
  from (select coalesce(sum(ro.amount_minor), 0)::bigint as actual
        from receivable.receivable_offsets ro
        where ro.tenant_id = confirm_return_exchange.tenant_id
          and ro.return_exchange_order_id = v_session.id) x
  where p.id = v_pl.id;
```

  CHECK cân bằng `receivable_reverse + offset + refund = |net|` vẫn giữ vì tổng `offset + refund` không đổi.
  - `get_sales_order_timeline`: `'description', o.payload ->> 'description'` → `'description', coalesce(o.payload ->> 'description', case when o.event_type = 'sales_payment_recorded.v1' and o.payload ? 'customerCollectionId' then 'Ghi nhận thu nợ theo khách' end)`.

- [ ] **Bước 4: Người dùng chạy** `tools/db_check.sh receivable_th06` (reset + plpgsql_check + test) → `receivable_th06: OK`; chạy thêm `tools/db_check.sh --no-reset sales_th05` → OK.

- [ ] **Bước 5:** sinh lại REGISTRY (lệnh như T6-2b Task 1); TH-06 6.2 dòng `confirm_return_exchange` thêm "sau khi ghi, cập nhật kế hoạch theo cách chia thật". Commit `feat(receivable): T6-2c ghi cách chia cấn trừ thật, nhãn thu theo khách`.

---

### Task 2: Dữ liệu `sales` nhận cấn trừ

**Files:**
- Modify: các file dữ liệu trong File Structure (Task 2)
- Test: `test/features/sales/data/return_exchange_repository_test.dart`, `sales_payment_repository_test.dart`, `sales_receipt_repository_test.dart`; `test/features/sales/presentation_module/support/sales_receipt_pdf_generator_test.dart`

**Interfaces:**
- Produces:
  - `enum SalesPaymentMethod { cash, manualBankTransfer, offset }`
  - `final class ReturnExchangeOffsetCandidateDto { String salesOrderId; String orderCode; DateTime completedAt; int outstandingMinor; int offsetAmountMinor; DateTime? dueDate; int overdueDays; int settlementVersion; }`
  - `ReturnExchangeSettlementPlanDto` thêm `int offsetAmountMinor` (mặc định 0), `List<ReturnExchangeOffsetCandidateDto> offsetCandidates` (mặc định `const []`).
  - `SalesPaymentTransactionDto` thêm `String? counterpartSalesOrderId`, `String? counterpartOrderCode`, `String? customerCollectionId`.
  - `SalesOrderPaymentSummaryDto` thêm `MoneyDto collectedOffset`, `MoneyDto refundedOffset` (khoá vắng → 0).
  - `ReturnExchangeConfirmRequest` thêm `List<String> offsetTargetOrderIds` (mặc định `const []`); `confirmParams` gửi `'offset_target_order_ids': request.offsetTargetOrderIds`.
  - `SalesReturnExchangeAttemptFactory.confirm(…, List<String> offsetTargetOrderIds = const [])`.

- [ ] **Bước 1: Chạy `impact`** cho `SalesPaymentMethod`, `ReturnExchangeSettlementPlanDto`, `ReturnExchangeConfirmRequest`; ghi vào Kết quả (enum dự kiến rủi ro cao vì ~40 file — báo người dùng trước khi sửa).

- [ ] **Bước 2: Test đỏ.**

```dart
test('settlement plan parses offset fields', () {
  // json = plan đủ khoá cũ + 'offsetAmountMinor': 500000,
  // 'offsetCandidates': [{salesOrderId:'o2', orderCode:'DH-002', completedAt:'2026-11-01T03:00:00Z',
  //   outstandingMinor:2000000, offsetAmountMinor:500000, dueDate:'2026-11-16', overdueDays:3, settlementVersion:4}]
  expect(plan.offsetAmountMinor, 500000);
  expect(plan.offsetCandidates.single.orderCode, 'DH-002');
  expect(plan.offsetCandidates.single.dueDate, DateTime(2026, 11, 16));
});
test('settlement plan without offset keys still parses', () { /* offsetAmountMinor 0, candidates [] */ });
test('confirm params send offset_target_order_ids', () {
  expect(params['offset_target_order_ids'], ['o2', 'o3']);
});
test('confirm hash includes offset targets', () {
  // cùng mọi tham số, targets ['o2'] vs [] → payloadHash khác; ['o2'] hai lần → giống
});
test('parses offset method in transactions', () {
  // item method 'offset', transactionType 'refund', counterpartOrderCode 'DH-002', counterpartSalesOrderId 'o2'
  expect(tx.method, SalesPaymentMethod.offset);
  expect(tx.counterpartOrderCode, 'DH-002');
});
test('payment summary parses collectedOffset / refundedOffset', () {});
test('parses offset method in receipt', () {});
test('receipt pdf labels offset as Cấn trừ', () {
  // payment method offset 500000 → bảng thanh toán có 'Cấn trừ'
});
```

- [ ] **Bước 3: Chạy** `cd apps/erp && flutter test test/features/sales/data test/features/sales/presentation_module/support/sales_receipt_pdf_generator_test.dart` → FAIL.

- [ ] **Bước 4: Sửa.**
  - `_settlementPlanKeys` thêm `'offsetAmountMinor'`, `'offsetCandidates'` (vẫn từ chối khoá lạ khác). Ứng viên đọc chặt như các DTO khác của file (`_string`, `_int`, ngày `dueDate` dạng `YYYY-MM-DD` → `DateTime` ngày).
  - Ba hàm `_paymentMethod` (đọc) thêm `'offset' => SalesPaymentMethod.offset`.
  - Ba hàm ghi (`return_exchange_json.dart:826`, `sales_checkout_json.dart:247`, `sales_payment_json.dart:59`): `SalesPaymentMethod.offset => throw ArgumentError('offset is never sent by the app')`.
  - Nhãn: `sales_order_detail_mapper._paymentMethodLabel` và `sales_receipt_pdf_generator._paymentLabel` → `'Cấn trừ'`.
  - Attempt factory: `payload['offsetTargetOrderIds'] = offsetTargetOrderIds` (giữ thứ tự cũ trước do cubit gửi).
  - Chạy `flutter analyze` để bắt mọi `switch` còn thiếu nhánh `offset`; nhánh nào là chọn phương thức của người dùng (`_methods` SG-13, checkout) **không** thêm `offset`.

- [ ] **Bước 5: Chạy lại** lệnh Bước 3 + `flutter analyze` → PASS / sạch.

- [ ] **Bước 6: Commit** `feat(sales): T6-2c nhận phương thức offset và khoá cấn trừ`.

---

### Task 3: Hàm thuần `planReturnSettlement`

**Files:**
- Create: `apps/erp/lib/features/sales/logic/return_settlement_preview.dart`
- Test: `apps/erp/test/features/sales/logic/return_settlement_preview_test.dart`

**Interfaces:**
- Consumes: `ReturnExchangeOffsetCandidateDto` (Task 2).
- Produces:

```dart
class ReturnOffsetShare extends Equatable {
  final String salesOrderId; final String orderCode; final int amountMinor;
}
class ReturnSettlementPreview extends Equatable {
  final int reduceOwnDebtMinor;   // = server receivableReverseAmountMinor
  final int distributableMinor;   // offsetAmountMinor + refundAmountMinor của server
  final List<ReturnOffsetShare> offsets; // một phần tử mỗi ứng viên, đúng thứ tự server
  final int offsetTotalMinor;
  final int refundMinor;          // distributable − offsetTotal
  final bool showOffsetBlock;     // candidates.isNotEmpty && distributable > 0
  List<String> get targetOrderIds; // salesOrderId của offsets có amountMinor > 0, theo thứ tự
}
ReturnSettlementPreview planReturnSettlement({
  required int reduceOwnDebtMinor,
  required int distributableMinor,
  required List<ReturnExchangeOffsetCandidateDto> candidates,
  required Set<String> selectedIds,
});
```

Chia: đi theo thứ tự `candidates` (server đã xếp cũ trước), đơn được tick nhận `min(còn lại, outstandingMinor)` — đúng `allocate.js` `planReturnSettlement` (chép ở dưới), chỉ khác đầu vào lấy số server thay cho `entitled` / `sourceOutstanding`.

```js
// specs/themes/theme-06/03.design/prototype/html/app/allocate.js:10-18
export function planReturnSettlement({ entitled, sourceOutstanding, candidates, selectedIds }) {
  const reduceOwnDebt = Math.min(entitled, sourceOutstanding);
  const remaining = entitled - reduceOwnDebt;
  const chosen = candidates.filter((c) => selectedIds.includes(c.id));
  const alloc = allocateOldestFirst(chosen, remaining);
  const offsets = candidates.map((c) => ({ id: c.id, amountMinor: alloc.find((a) => a.id === c.id)?.allocatedMinor ?? 0 }));
  const refund = remaining - offsets.reduce((s, o) => s + o.amountMinor, 0);
  return { reduceOwnDebt, remaining, offsets, refund, showOffsetBlock: candidates.length > 0 && remaining > 0 };
}
```

- [ ] **Bước 1: Test đỏ** (ứng viên `DH-002` nợ 2.000.000, `DH-003` nợ 6.000.000 — chép `tests/allocate.test.mjs`):

| Test | Vào (reduce, distributable, tick) | Kỳ vọng |
|---|---|---|
| `AC-01 offset 500k into DH-002` | 0, 500000, {DH-002, DH-003} | offsets [500000, 0], refund 0, showOffsetBlock true, targetOrderIds [DH-002] |
| `FR-04 untick DH-002 moves to DH-003` | 0, 500000, {DH-003} | [0, 500000], refund 0 |
| `AC-02 untick all refunds` | 0, 500000, {} | [0, 0], refund 500000, targetOrderIds [] |
| `AC-03 own debt only hides block` | 600000, 0, {DH-002} | reduce 600000, refund 0, showOffsetBlock false |
| `AC-02 US-03.2 offset 2tr refund 1tr` | 0, 3000000, {DH-002} (chỉ ứng viên DH-002) | [2000000], refund 1000000 |
| `mixed` | 400000, 2600000, {DH-002} | reduce 400000, [2000000], refund 600000 |
| `BR-27 server cap kept` | 2000000, 1000000, {DH-002, DH-003} | reduce 2000000, [1000000, 0], refund 0 |
| `no candidates` | 0, 500000, {} với `candidates: []` | offsets [], refund 500000, showOffsetBlock false |

- [ ] **Bước 2: Chạy** `flutter test test/features/sales/logic/return_settlement_preview_test.dart` → FAIL (chưa có file).
- [ ] **Bước 3: Viết hàm.**
- [ ] **Bước 4: Chạy lại** → PASS.
- [ ] **Bước 5: Commit** `feat(sales): T6-2c hàm thuần chia tiền khách được hưởng`.

---

### Task 4: Cubit quyết toán giữ đơn đang tick

**Files:**
- Modify: `apps/erp/lib/features/sales/logic/sales_return_exchange_settlement_state.dart`, `…_cubit.dart`, `sales_post_sale_error_messages.dart`
- Test: `apps/erp/test/features/sales/presentation_module/bloc/sales_return_exchange_settlement_cubit_test.dart`

**Interfaces:**
- Consumes: Task 2 (`offsetCandidates`, `offsetTargetOrderIds`), Task 3 (`planReturnSettlement`).
- Produces:
  - State: `Set<String> selectedOffsetOrderIds` (mặc định rỗng); `bool receivableChanged` (mặc định false); getter `ReturnSettlementPreview? get offsetPreview` — `null` khi chưa có `valuation?.settlementPlan` hoặc `netDifferenceMinor >= 0`; còn lại gọi `planReturnSettlement(reduceOwnDebtMinor: plan.receivableReverseAmountMinor, distributableMinor: plan.offsetAmountMinor + plan.refundAmountMinor, candidates: plan.offsetCandidates, selectedIds: selectedOffsetOrderIds)`.
  - Cubit: `void toggleOffsetTarget(String salesOrderId)`; `loadAndEvaluate()` sau khi có plan đặt `selectedOffsetOrderIds = {mọi ứng viên}` và `receivableChanged: false`; `confirm()` gửi `offsetTargetOrderIds: state.offsetPreview?.targetOrderIds ?? const []`.
  - Lỗi: `'OFFSET_TARGET_INVALID': 'Đơn được chọn để cấn trừ không hợp lệ.'` trong `sales_post_sale_error_messages.dart`. Khi đã gửi ≥ 1 đơn cấn trừ mà nhận `STALE_VERSION` hoặc `OFFSET_TARGET_INVALID`: `_currentAttempt = null`, **không** gọi `loadAndEvaluate`, emit `status: stale, receivableChanged: true, screenError: 'Công nợ của khách vừa thay đổi. Hãy tải lại quyết toán.'` (với `OFFSET_TARGET_INVALID` dùng thông điệp của mã). Không gửi đơn cấn trừ → giữ nhánh cũ.
  - `toggleOffsetTarget` đổi danh sách → `_currentAttempt = null` (khoá mới); không đổi → thử lại giữ attempt.

- [ ] **Bước 1: Test đỏ.**

```dart
blocTest('load selects all offset candidates', /* plan 2 ứng viên → selected {o2, o3}; preview.offsets [500000, 0] */);
blocTest('toggle recomputes preview', /* toggle o2 → preview.offsets [0, 500000]; toggle o3 → refund 500000 */);
blocTest('confirm sends targets with positive share', /* tick cả hai → request.offsetTargetOrderIds == ['o2'] */);
blocTest('confirm sends empty targets when none selected', /* [] */);
blocTest('stale with offset targets shows receivableChanged without reload', /* repo.evaluate gọi đúng 1 lần; status stale; receivableChanged true; screenError đúng chữ */);
blocTest('reload after stale reselects new candidates', /* evaluate lần 2 trả chỉ o3 → selected {o3}; receivableChanged false */);
blocTest('OFFSET_TARGET_INVALID shows code message', /* screenError 'Đơn được chọn để cấn trừ không hợp lệ.' */);
blocTest('retry keeps attempt when targets unchanged', /* NETWORK_ERROR rồi confirm lại → cùng idempotencyKey */);
blocTest('toggle after error makes new attempt', /* khoá khác */);
blocTest('stale without offset targets keeps old behaviour', /* tự gọi evaluate lần 2, receivableChanged false */);
```

- [ ] **Bước 2: Chạy** `flutter test test/features/sales/presentation_module/bloc/sales_return_exchange_settlement_cubit_test.dart` → FAIL.
- [ ] **Bước 3: `impact`** `SalesReturnExchangeSettlementCubit`, `SalesReturnExchangeSettlementState` → ghi Kết quả. Sửa.
- [ ] **Bước 4: Chạy lại** → PASS (cả test cũ).
- [ ] **Bước 5: Commit** `feat(sales): T6-2c quyết toán đổi/trả chọn đơn cấn trừ`.

---

### Task 5: SG-13 nhánh "khách được hưởng" theo prototype

**Files:**
- Create: `apps/erp/lib/features/sales/presentation/widgets/sales_return_entitled_settlement.dart`
- Modify: `sales_return_exchange_settlement_body.dart` (nhánh `!_isCollect`, dòng ~329–420), `sales_return_confirm_settlement_sheet.dart`, `pages/sales_return_exchange_settlement_page.dart`
- Test: `test/features/sales/presentation_module/widgets/sales_return_exchange_settlement_body_test.dart`, golden mới `test/features/sales/presentation_module/widgets/sales_return_entitled_golden_test.dart`

**Interfaces:**
- Consumes: `state.offsetPreview`, `state.selectedOffsetOrderIds`, `cubit.toggleOffsetTarget` (Task 4); `formatVnd`, `formatVndBare`, `orderDueLabel`, `ReceivableDueBadge`, `receivableMoneyStyle` (T6-2b).
- Produces:
  - `class SalesReturnEntitledSettlement extends StatelessWidget { required String orderCode; required String customerDisplayName; required int entitledMinor; required int returnValueMinor; required int exchangeValueMinor; required ReturnSettlementPreview preview; required List<ReturnExchangeOffsetCandidateDto> candidates; required Set<String> selectedIds; required ValueChanged<String> onToggle; required SalesPaymentMethod method; required ValueChanged<SalesPaymentMethod>? onMethodChanged; DateTime? today; }`
  - Body thêm `ValueChanged<String>? onToggleOffset`.
  - `showSalesReturnConfirmSettlementSheet(context, vm:, List<String> settlementLines = const [])` — có `settlementLines` thì hiện danh sách gạch đầu dòng thay cho phần tóm tắt cũ.
  - Trang: `receivableChanged` → hộp thoại `showDialog(barrierDismissible: false)` dựng như `_ConfirmBox` của `customer_collection_sheet.dart:157` (chép sang, một nút) tiêu đề `Công nợ của khách vừa thay đổi. Hãy tải lại quyết toán.` (hoặc thông điệp `OFFSET_TARGET_INVALID`), một nút `Tải lại` → `loadAndEvaluate()`.

**Prototype (nguồn, chép nguyên):**

```js
// app/sg13.js:20-45 — thân màn
function offsetRow(c, cand, amountMinor, on) {
  return `<button class="rc-offset" type="button" role="checkbox" aria-checked="${on}" data-offset="${esc(cand.id)}">${k7CheckMark(on)}<span class="rc-offset__main"><span class="rc-offset__title">${esc(cand.code)} · còn nợ ${formatVnd(cand.outstandingMinor)}</span>${dueBadge(dueLabel(cand.dueDate, TODAY))}</span><span class="rc-offset__amt rc-money${amountMinor === 0 ? ' is-zero' : ''}">Trừ ${bare(amountMinor)}</span></button>`;
}
export function sg13Body(m) {
  const { c, plan, selectedIds } = m;
  const diff = c.returnValue - c.exchangeValue;
  const seg = '<div class="ds-segmented" role="group" aria-label="Phương thức hoàn">…Tiền mặt…CK…</div>';
  const offsetSum = plan.offsets.reduce((x, o) => x + o.amountMinor, 0);
  const segs = [['own', plan.reduceOwnDebt], ['offset', offsetSum], ['refund', plan.refund]].filter(([, v]) => v > 0);
  const bar = segs.length ? `<div class="rs-bar" aria-hidden="true">${segs.map(([k, v]) => `<span class="rs-bar__${k}" style="flex:${v}"></span>`).join('')}</div>` : '';
  const flowRow = (k, label, value, note = '') => `<div class="rs-flow__row" role="listitem"><span class="rs-dot rs-dot--${k}"></span><span>${label}${note ? `<small class="rs-flow__note">${note}</small>` : ''}</span><b class="rc-money">${value}</b></div>`;
  return `<p class="rc-sub rc-sub--pad">${esc(c.orderCode)} · ${esc(c.customer)}</p>
  <div class="rs-hero"><span class="rs-hero__label">Khách được hưởng</span><span class="rs-hero__amt rc-money">${formatVnd(c.entitled)}</span><span class="rs-hero__meta">Chênh lệch −${formatVnd(diff)} · Hàng trả ${bare(c.returnValue)} · Hàng đổi ${bare(c.exchangeValue)}</span></div>
  <div class="rs-flow" role="list" aria-label="Tiền được chia">${bar}
    ${plan.reduceOwnDebt > 0 ? flowRow('own', 'Giảm nợ đơn này', formatVnd(plan.reduceOwnDebt), 'Trừ vào nợ của chính đơn này') : ''}
    ${plan.showOffsetBlock ? flowRow('offset', 'Cấn trừ vào đơn khác', formatVnd(offsetSum)) : ''}
    ${flowRow('refund', 'Hoàn cho khách', formatVnd(plan.refund))}
    ${plan.refund > 0 ? `<div class="rc-method"><span class="rc-method__label">Phương thức hoàn</span>${seg}</div>` : ''}
  </div>
  ${plan.showOffsetBlock ? `<h4 class="rc-section">CẤN TRỪ VÀO ĐƠN KHÁC</h4><p class="rc-note rc-note--tight rc-note--pad">Trừ vào nợ đơn khác của khách thay vì hoàn tiền.</p>${c.candidates.map((cd) => offsetRow(…)).join('')}` : ''}`;
}
// app/sg13.js:47-53 — sheet xác nhận
if (plan.reduceOwnDebt > 0) rows.push(`Giảm nợ đơn này ${formatVnd(plan.reduceOwnDebt)}`);
for (const o of plan.offsets.filter((x) => x.amountMinor > 0)) rows.push(`Cấn trừ ${formatVnd(o.amountMinor)} vào đơn ${code}`);
if (plan.refund > 0) rows.push(`Hoàn ${formatVnd(plan.refund)} cho khách`);
```

```css
/* styles/receivable.css — --rc-fs-sm 13px, --rc-fs-md 14px, --rc-fs-xs 12px */
.rc-sub { color: text-secondary; font-weight: 600; }  .rc-sub--pad { padding: space-3 space-4 0; }
.rs-hero { flex column; gap: 2px; padding: space-2 space-4 0; }
.rs-hero__label { color: text-secondary; font-weight: 600; font-size: 13px; }
.rs-hero__amt { font-size: 28px; line-height: 1.3; letter-spacing: -.5px; color: text-success; }
.rs-hero__meta { color: text-secondary; font-size: 13px; }
.rs-flow { flex column; gap: space-2; margin: space-3 space-4 0; padding: space-3; border: 1px border-default; radius-card; background: surface-default; }
.rs-bar { height: 8px; radius-pill; gap: 2px; background: neutral-200; }  .rs-bar__own: info-500; __offset: primary-500; __refund: neutral-400
.rs-flow__row { grid 12px | 1fr | auto; gap: space-2; font-size: 14px; }  .rs-flow__note { color: text-secondary; 13px; weight 500 }
.rs-dot { 10×10; radius-pill } (màu như rs-bar)
.rc-method { column; gap: space-2 }  .rc-method__label { weight 600; 13px }
.rc-section { padding: space-4 space-4 space-2; color: text-secondary; 12px; weight 700; letter-spacing .4px }
.rc-offset { grid 44px | 1fr | auto; gap: space-2; min-height: 44px; margin: 0 space-4 space-2; padding: space-2 space-3 space-2 0; border 1px border-default; radius-card; background surface-default }
.rc-offset__title { weight 600; tabular; nowrap }  .rc-offset__main .rc-due { 13px }  .rc-offset__amt { align-self: end }
.rc-offset__amt.is-zero { color: text-muted; weight 600 }  .rc-money { tabular; right; nowrap; weight 700 }
```

**Ánh xạ:**

| Prototype | Flutter |
|---|---|
| `rc-sub--pad` "DH-010 · Anh Tuấn" | `Padding(fromLTRB(space4, space3, space4, 0))` + `Text` `labelDefault` w600 `textSecondary` (bỏ nếu trang đã có dòng này phía trên) |
| `rs-hero__amt` | `Text(formatVnd(entitled))` cỡ 28, `height 1.3`, `letterSpacing -0.5`, w700, `colors.success`, tabular |
| `rs-hero__meta` | `Chênh lệch −${formatVnd(diff)} · Hàng trả ${formatVndBare(returnValue)} · Hàng đổi ${formatVndBare(exchangeValue)}`, 13, `textSecondary` |
| `rs-flow` | `Container` viền `borderDefault`, `VRadius.r12` (`--vet45-v2-radius-card` 12px), nền `surface`, `padding space3`, `margin fromLTRB(space4, space3, space4, 0)` |
| `rs-bar` | `ClipRRect(pill)` cao 8 nền `VColors.neutral200`; `Row` các `Expanded(flex: số tiền rút gọn về int an toàn — chia cho 1000)` cách 2; màu `colors.info` / `colors.primary` / `VColors.neutral400`; `ExcludeSemantics` |
| `rs-flow__row` | `Row`: chấm 10×10 trong ô rộng 12, `SizedBox(space2)`, `Expanded` (nhãn 14 + ghi chú 13 `textSecondary` w500), số `receivableMoneyStyle` |
| `rc-method` + `ds-segmented` | nhãn "Phương thức hoàn" 13 w600 + bộ chọn phương thức **đang có** trong body (`_methods`: Tiền mặt / CK), chỉ khi `refundMinor > 0` |
| `rc-section` | `ReceivableSectionTitle('CẤN TRỪ VÀO ĐƠN KHÁC')` |
| `rc-note` | `Padding(space4 ngang)` + "Trừ vào nợ đơn khác của khách thay vì hoàn tiền." `textSecondary` |
| `rc-offset` | `Semantics(checked:, button: true)` + `InkWell` + viền như `rs-flow`, `minHeight 44`; ô 44 chứa `VCheckbox`; giữa: tiêu đề `${orderCode} · còn nợ ${formatVnd(outstanding)}` w600 `ellipsis` + `ReceivableDueBadge(orderDueLabel(dueDate:, overdueDays:, today:), fontSize: 13)`; phải: `Trừ ${formatVndBare(share)}` canh đáy, 0 thì `textMuted` w600 |
| chân trang | chỉ `VButton('Xác nhận đổi/trả')` rộng hết (Quyết định 7) |

Ẩn/hiện đúng prototype: dòng "Giảm nợ đơn này" khi `reduceOwnDebtMinor > 0`; dòng "Cấn trừ vào đơn khác" + khối danh sách khi `showOffsetBlock`; "Hoàn cho khách" luôn hiện; "Phương thức hoàn" khi `refundMinor > 0`. `entitledMinor = |netDifferenceMinor|`; `returnValue` / `exchangeValue` từ `state.valuation`.

- [ ] **Bước 1: Widget test đỏ** (dùng state dựng tay, không cubit):
  - `all-selected`: thấy `Trừ 500.000` và `Trừ 0`, `Hoàn cho khách` `0 ₫`, không thấy `Phương thức hoàn`.
  - `none-selected`: chạm hai ô → `onToggle` gọi `o2`, `o3`; với preview bỏ hết: `500.000 ₫` ở dòng hoàn + `Phương thức hoàn`.
  - `source-has-debt`: thấy `Giảm nợ đơn này` `600.000 ₫`, `Trừ vào nợ của chính đơn này`, không thấy `CẤN TRỪ VÀO ĐƠN KHÁC`.
  - `no-other-debt`: không thấy khối cấn trừ.
  - ô cấn trừ cao ≥ 44; semantics `checked`.
  - Sheet: `settlementLines` mixed → ba dòng `Giảm nợ đơn này 400.000 ₫`, `Cấn trừ 2.000.000 ₫ vào đơn DH-002`, `Hoàn 600.000 ₫ cho khách`.
- [ ] **Bước 2: Chạy** test → FAIL.
- [ ] **Bước 3: `impact`** `_ReadyBody`, `showSalesReturnConfirmSettlementSheet`, `SalesReturnExchangeSettlementPage` → ghi Kết quả. Viết widget, nối body (nhánh `!_isCollect && netDifferenceMinor < 0` thay bằng `SalesReturnEntitledSettlement`), trang truyền `onToggleOffset: _cubit.toggleOffsetTarget`, dựng `settlementLines` từ `offsetPreview` theo `confirmBody` và nghe `receivableChanged`.
- [ ] **Bước 4: Golden** 8 trạng thái × 390/1280 tên `flutter-SG-13-<state>-<w>.png` (dữ liệu = `sg13Cases` của `data.js`: base DH-001 trả 500.000, ứng viên DH-002 nợ 2.000.000 quá hạn 3 ngày, DH-003 nợ 6.000.000 hẹn 30/11; mixed DH-010 trả 3.000.000, reduce 400.000; source-has-debt reduce 600.000; ngày hôm nay 2026-11-19). `flutter test --update-goldens …golden_test.dart`, so từng cặp với `proto-SG-13-*` và sửa đến khi khớp bố cục, chữ, màu.
- [ ] **Bước 5: Chạy** `flutter test test/features/sales` → PASS.
- [ ] **Bước 6: Commit** `feat(sales): T6-2c SG-13 khối cấn trừ theo prototype`.

| Proto 390 | Flutter 390 | Proto 1280 | Flutter 1280 |
|---|---|---|---|
| ![](img/T6-2c/proto-SG-13-all-selected-390.png) | ![](img/T6-2c/flutter-SG-13-all-selected-390.png) | ![](img/T6-2c/proto-SG-13-all-selected-1280.png) | ![](img/T6-2c/flutter-SG-13-all-selected-1280.png) |
| ![](img/T6-2c/proto-SG-13-one-unchecked-390.png) | ![](img/T6-2c/flutter-SG-13-one-unchecked-390.png) | ![](img/T6-2c/proto-SG-13-one-unchecked-1280.png) | ![](img/T6-2c/flutter-SG-13-one-unchecked-1280.png) |
| ![](img/T6-2c/proto-SG-13-none-selected-390.png) | ![](img/T6-2c/flutter-SG-13-none-selected-390.png) | ![](img/T6-2c/proto-SG-13-none-selected-1280.png) | ![](img/T6-2c/flutter-SG-13-none-selected-1280.png) |
| ![](img/T6-2c/proto-SG-13-mixed-390.png) | ![](img/T6-2c/flutter-SG-13-mixed-390.png) | ![](img/T6-2c/proto-SG-13-mixed-1280.png) | ![](img/T6-2c/flutter-SG-13-mixed-1280.png) |
| ![](img/T6-2c/proto-SG-13-source-has-debt-390.png) | ![](img/T6-2c/flutter-SG-13-source-has-debt-390.png) | ![](img/T6-2c/proto-SG-13-source-has-debt-1280.png) | ![](img/T6-2c/flutter-SG-13-source-has-debt-1280.png) |
| ![](img/T6-2c/proto-SG-13-no-other-debt-390.png) | ![](img/T6-2c/flutter-SG-13-no-other-debt-390.png) | ![](img/T6-2c/proto-SG-13-no-other-debt-1280.png) | ![](img/T6-2c/flutter-SG-13-no-other-debt-1280.png) |
| ![](img/T6-2c/proto-SG-13-confirm-390.png) | ![](img/T6-2c/flutter-SG-13-confirm-390.png) | ![](img/T6-2c/proto-SG-13-confirm-1280.png) | ![](img/T6-2c/flutter-SG-13-confirm-1280.png) |
| ![](img/T6-2c/proto-SG-13-stale-390.png) | ![](img/T6-2c/flutter-SG-13-stale-390.png) | ![](img/T6-2c/proto-SG-13-stale-1280.png) | ![](img/T6-2c/flutter-SG-13-stale-1280.png) |

---

### Task 6: SG-14, phiếu đổi/trả, lối mở CN-02

**Files:**
- Create: `apps/erp/lib/features/receivable/presentation/receivable_navigation.dart`
- Modify: `sales_return_exchange_result_body.dart` (`_settlementCard`, dòng ~236), `sales_return_result_action_bar.dart`, `pages/sales_return_exchange_result_page.dart`, `support/sales_slip_pdf_generator.dart` (`settlementRows`)
- Test: `test/features/sales/sales_return_exchange_result_page_test.dart`, `test/features/sales/presentation_module/support/sales_slip_pdf_generator_test.dart`

**Interfaces:**
- Consumes: `settlementPlan.offsetCandidates`, `offsetAmountMinor` (sau Task 1 là số thật); `orderDetail.customer?.customerId` của `SalesReturnExchangeDetailState`.
- Produces: `void openCustomerReceivable(BuildContext context, String customerId)` — `kIsWeb ? context.go('/more/receivables/$customerId') : context.push('/more/receivables/$customerId')`. `SalesReturnResultActionBar` thêm `VoidCallback? onViewCustomerReceivable` (null → không có nút).

Prototype `patches.js` sg14: sau dòng phiếu, mỗi đơn nhận một dòng `Cấn trừ vào DH-002` + số, rồi `Hoàn cho khách`; nút phụ `Xem công nợ của khách` trên nút chính.

- [ ] **Bước 1: Test đỏ.**
  - `result shows offset rows`: plan đã xác nhận `offsetAmountMinor 500000`, ứng viên DH-002 trừ 500000, DH-003 trừ 0 → thấy `Cấn trừ vào DH-002: 500.000đ`, không thấy `DH-003`; thấy nút `Xem công nợ của khách`.
  - `result shows actual split after untick`: `offsetAmountMinor 0`, `refundAmountMinor 500000` → `Hoàn cho khách: 500.000đ`, không có dòng cấn trừ, không có nút.
  - `slip rows include offset`: `settlementRows(plan)` refund 1.000.000, offset 2.000.000 → chứa `('Cấn trừ sang đơn khác', '2.000.000đ')` ngay sau `Giảm nợ đơn` (nếu có) và trước `Đã hoàn`.
- [ ] **Bước 2: Chạy** → FAIL.
- [ ] **Bước 3: `impact`** `settlementRows`, `SalesReturnResultActionBar` → ghi Kết quả. Sửa: `_settlementCard` thêm dòng `Cấn trừ vào ${code}: ${MoneyFormatter.formatMinor(x)}` cho từng ứng viên `offsetAmountMinor > 0`, giữa dòng nợ và dòng tiền; trang truyền `onViewCustomerReceivable` khi `plan.offsetAmountMinor > 0 && customerId != null`; sửa chú thích "Sales does not offset…" trong `sales_slip_pdf_generator.dart`.
- [ ] **Bước 4: Chạy** `flutter test test/features/sales` → PASS. Golden `flutter-patch-sg14-390|1280.png` so `proto-patch-sg14-*` (chỉ phần SAU).
- [ ] **Bước 5: Commit** `feat(sales): T6-2c kết quả và phiếu đổi/trả hiện cấn trừ`.

---

### Task 7: SG-09 bỏ thu từng đơn, SG-09b / 09c dòng cấn trừ

**Files:**
- Delete: `lib/features/sales/presentation/widgets/sales_record_payment_sheet.dart`, `lib/features/sales/logic/sales_record_payment_cubit.dart`, `…_state.dart`, `lib/features/sales/presentation/support/sales_record_payment_attempt_factory.dart`, `lib/features/sales/data/models/sales_record_payment.dart`; test `sales_record_payment_cubit_test.dart`, `sales_record_payment_attempt_factory_test.dart`, `sales_record_payment_sheet_test.dart`; `sales_payment_mutation_errors.dart` + test **nếu** sau khi xoá `recordPayment` không còn ai dùng.
- Modify: `sales_payment_repository.dart` (xoá `recordPayment`, `_mutationGuard` nếu thừa), `sales_payment_json.dart` (xoá `recordParams`, `recordResultFromJson`), `test/features/sales/support/fake_sales_payment_repository.dart`, `test/features/sales/data/sales_payment_repository_test.dart`, `sales_order_actions_sheet.dart` (bỏ mục "Thu tiền" + `SalesOrderSheetAction.collectPayment`), `sales_order_detail_page.dart` (bỏ nhánh, thêm dòng công nợ), `sales_order_payment_vm.dart`, `sales_order_detail_mapper.dart`, `sales_order_payment_debt_page.dart`, `test/features/sales/sales_order_detail_page_test.dart`, `test/features/sales/presentation_module/support/sales_order_detail_mapper_test.dart`

**Interfaces:**
- Consumes: Task 2 (khoá giao dịch đối ứng, `collectedOffset` / `refundedOffset`), Task 6 (`openCustomerReceivable`).
- Produces:
  - `SalesOrderPaymentTransactionVm` thêm `String? counterpartSalesOrderId`; nhãn dòng cấn trừ đặt sẵn trong `methodLabel` và `kindLabel = null`: refund → `Cấn trừ · sang ${code}`, collection → `Cấn trừ · từ ${code}`.
  - `SalesOrderPaymentVm` thêm `int offsetMinor` (= `collectedOffset + refundedOffset`).
  - `_timelineTitle`: `'RECEIVABLE_OFFSET_RECORDED' => 'Cấn trừ công nợ'` ("Ghi nhận thu nợ theo khách" đến từ `description` của Task 1, rơi vào nhánh `_ => value`).

- [ ] **Bước 1: `impact`** `SalesOrderSheetAction`, `SalesPaymentRepository.recordPayment`, `SalesOrderPaymentVm`, `_timelineTitle` → ghi Kết quả.
- [ ] **Bước 2: Test đỏ.**
  - `actions sheet has no Thu tiền`.
  - `customer order shows receivable link`: SG-09 `customerId: 'c1'` → dòng `Xem công nợ của khách` (key `wgt_sg09_view_customer_receivable`), cao ≥ 44, có chevron; chạm → điều hướng `/more/receivables/c1`.
  - `walk-in has no receivable link`: `customerId: null` → không có.
  - mapper: tx offset refund `DH-002` → `methodLabel 'Cấn trừ · sang DH-002'`, `kindLabel null`, `counterpartSalesOrderId 'o2'`; collection → `Cấn trừ · từ DH-001`.
  - mapper: `offsetMinor` 500000 khi `refundedOffset` 500000; TM/CK không đổi.
  - debt page: có dòng `Đã cấn trừ` `500.000đ` khi `offsetMinor > 0`, không có khi 0; dòng giao dịch cấn trừ chạm → `push('/sales/orders/o2')`.
  - mapper timeline: `receivable_offset_recorded.v1` → `Cấn trừ công nợ`; description `Ghi nhận thu nợ theo khách` giữ nguyên.
- [ ] **Bước 3: Chạy** `flutter test test/features/sales` → FAIL.
- [ ] **Bước 4: Xoá SG-11, sửa.** Dòng SG-09 đặt ngay dưới `SalesOrderDetailPaymentSummaryCard`: `InkWell` + `minHeight 44` + `Text('Xem công nợ của khách')` + `Icon(chevronRight)`, viền/nền như các thẻ cạnh đó. Dòng giao dịch cấn trừ trong `_TransactionsCard`: bọc `SalesAmountHighlightRow` bằng `InkWell` khi `counterpartSalesOrderId != null`, thêm chevron.
- [ ] **Bước 5: Chạy** `flutter test` (toàn app) + `flutter analyze` → PASS / sạch (không còn tham chiếu SG-11).
- [ ] **Bước 6: Golden** `flutter-patch-sg09|sg09b|sg09c-390|1280.png` so `proto-patch-*` (phần SAU).
- [ ] **Bước 7: Commit** `feat(sales): T6-2c SG-09 bỏ thu từng đơn, giao dịch và lịch sử cấn trừ`.

---

### Task 8: PT-07 khối Công nợ

**Files:**
- Modify: `lib/features/receivable/data/receivable_models.dart`, `receivable_repository.dart`, `test/features/receivable/support/fake_receivable_repository.dart`
- Create: `lib/features/receivable/presentation/widgets/customer_receivable_summary_card.dart`
- Modify: `lib/features/partner/presentation/pages/partner_detail_page.dart`, `lib/core/router/app_router.dart` (route `partner.detail`, dòng ~605)
- Test: `test/features/receivable/presentation/customer_receivable_summary_card_test.dart`, `test/features/partner/presentation/partner_detail_customer_section_test.dart`

**Interfaces:**
- Consumes: `openCustomerReceivable` (Task 6), `formatVnd`, `customerDueLabel`, `ReceivableDueBadge`.
- Produces:
  - `class CustomerReceivableSummary extends Equatable { int outstandingMinor; int openOrderCount; int maxOverdueDays; factory fromJson }`
  - `Future<CustomerReceivableSummary> ReceivableRepository.getSummary(String customerId)` → `get_customer_receivable_summary` `{p_customer_partner_id}`.
  - `class CustomerReceivableSummaryCard extends StatefulWidget { required String customerId; ReceivableRepository? repository; DateTime? today; }`
  - `PartnerDetailPage` thêm `final Widget Function(BuildContext context, PartnerDetailDto dto)? customerSection;` — dựng khi `!dto.isSystem && dto.roles.contains(PartnerRoleType.customer)`, ngay dưới `PartnerDetailMainInfoCard` + `VGap.sm()`.

Prototype `patches.js` pt07: thẻ một dòng, tiêu đề `Công nợ`, dòng phụ `Còn nợ 18.000.000 ₫ · 3 đơn` + nhãn `Quá hạn 8 ngày`; biến thể `Không còn nợ`; chevron bên phải.

- [ ] **Bước 1: Test đỏ.**
  - `repository getSummary sends customer id and parses`.
  - card: `{18000000, 3, 8}` → `Công nợ`, `Còn nợ 18.000.000 ₫ · 3 đơn`, `Quá hạn 8 ngày` (có icon cảnh báo); `{0, 0, 0}` → `Không còn nợ`, không nhãn; repo ném lỗi → `SizedBox.shrink` (không chữ lỗi); chạm → `/more/receivables/c1`; cao ≥ 44; semantics đọc đủ "Công nợ, Còn nợ 18.000.000 ₫ · 3 đơn, Quá hạn 8 ngày".
  - partner: vai trò `[customer]` → dựng `customerSection`; `[supplier]` → không gọi; `isSystem` → không gọi.
- [ ] **Bước 2: Chạy** → FAIL.
- [ ] **Bước 3: `impact`** `PartnerDetailPage`, `ReceivableRepository` → ghi Kết quả. Viết model, hàm repo, thẻ (`maxOverdueDays > 0` → `customerDueLabel(maxOverdueDays:, nextDueDate: null, today:)`), tham số trang, nối router `customerSection: (ctx, dto) => CustomerReceivableSummaryCard(customerId: dto.partnerId)`.
- [ ] **Bước 4: Chạy** `flutter test test/features/receivable test/features/partner` → PASS. Golden `flutter-patch-pt07-390|1280.png` so `proto-patch-pt07-*`.
- [ ] **Bước 5: Commit** `feat(receivable): T6-2c khối Công nợ ở hồ sơ khách`.

---

### Task 9: Audit, kịch bản 9.1, tài liệu

**Files:** `docs/02-yeu-cau/TH-06-cong-no.md`, `docs/02-yeu-cau/TH-05-ban-hang-va-don-hang.md`, `docs/02-yeu-cau/TH-03-doi-tac-giao-dich.md`, `docs/refactor/PLAN.md`, plan này (Kết quả)

- [ ] **Bước 1:** `/impeccable audit` trên SG-13 (nhánh khách được hưởng), SG-09b, SG-14, PT-07 (iPhone + web); sửa mục nặng, ghi phần còn lại vào Kết quả.
- [ ] **Bước 2: Người dùng chạy kịch bản 9.1** trên DB local, iPhone và web, mỗi bước so CN-01 = CN-02 = PT-07 = Σ còn nợ các đơn:

| # | Làm | Nhìn |
|---|---|---|
| 1 | Bán nợ DH-001 4tr, DH-002 8tr, DH-003 6tr cho Anh Tuấn (hẹn DH-001 lùi 8 ngày) | CN-01 18.000.000 ₫, "Quá hạn 8 ngày"; PT-07 "Còn nợ 18.000.000 ₫ · 3 đơn" |
| 2 | CN-03 thu 10tr tiền mặt (tick DH-001, DH-002) | DH-001 hết nợ, DH-002 còn 2tr; SG-09c DH-002 có "Ghi nhận thu nợ theo khách" |
| 3 | Trả 500.000 hàng DH-001, giữ tick | SG-13 "Trừ 500.000" ở DH-002; SG-14 "Cấn trừ vào DH-002"; SG-09b hai đơn có dòng cấn trừ chạm sang nhau; phiếu bán hàng DH-002 có "Cấn trừ"; không lỗi đọc |
| 4 | Trả 1tr hàng DH-003 | SG-13 chỉ "Giảm nợ đơn này 1.000.000 ₫"; công nợ 6.500.000 ₫ |
| 5 | Trả hàng đơn đã trả đủ, bỏ hết tick | "Hoàn cho khách" + phương thức; SG-14 hoàn đúng số, không dòng cấn trừ |
| 6 | CN-03 "Tất cả đơn · trả hết" | khách biến khỏi CN-01; PT-07 "Không còn nợ" |

  Thêm: SG-09 không còn "Thu tiền"; SG-09 → "Xem công nợ của khách" → CN-02, quay lại về SG-09 (iPhone) / đúng khách ở cột trái (web).
- [ ] **Bước 3: Tài liệu.** TH-05: SG-11 bỏ khỏi giao diện (link TH-06 5.1), SG-13 / 14 / 09b / 09c ghi "xem TH-06 EP-03"; TH-03 PT-07 khối Công nợ; TH-06 9.4 + 6.2 khớp code; PLAN dòng T6-2c (Plan ✅ / Làm ✅) và trạng thái Theme 6.
- [ ] **Bước 4:** `detect_changes({scope: "compare", base_ref: "main"})` — chỉ các symbol trong plan; ghi vào Kết quả. Commit `docs(receivable): T6-2c tài liệu và kết quả`.

---

## Self-review (người viết plan)

- Phủ spec: US-03.1 FR-01…05 (Task 3–5), US-03.2 FR-01…04 (Task 2, 4–6), US-03.3 FR-01…04 (Task 1, 2, 7), US-04.1 FR-02…03 (Task 7–8), 5.1 bỏ SG-11 (Task 7), 9.1 (Task 9), 9.3 SG-13 / PT-07 (Task 3–5, 8).
- Lỗi có sẵn phát hiện khi viết plan: (a) `_settlementPlanKeys` từ chối `offsetAmountMinor` / `offsetCandidates` → SG-13 hỏng sau T6-1b (Task 2); (b) `offset` ném `FormatException` ở phiếu và giao dịch (Task 2); (c) kế hoạch quyết toán không ghi cách chia thật (Task 1).

## Kết quả

**Trạng thái 2026-11-19:** Task 2–8 xong phía Flutter; Task 1 viết xong nhưng **chưa chạy DB, chưa commit**; Task 9 còn audit, kịch bản 9.1, golden `patch-*`.

**Impact (GitNexus).** Chỉ mục Dart không đáng tin: `SalesPaymentMethod` báo LOW / 0 trong khi ~23 file dùng; `ReturnExchangeConfirmRequest` và cubit SG-13 báo CRITICAL (1865) do trùng tên symbol (ambiguous). Blast radius thật theo grep: cubit chỉ được `SalesReturnExchangeSettlementPage` dùng; thay đổi đều là thêm khoá/tham số có mặc định. Không dừng vì CRITICAL (kết quả nhiễu, thay đổi cộng thêm). `detect_changes compare main` trả 3997 file (cả nhánh refactor) nên không dùng được làm bằng chứng; chỉ mục cũ.

**Task 1 (DB) — chưa xác minh.** Migration `20261126001_receivable_offset_actual_split.sql` (thân hai hàm trích từ `20261124002` và `20261123001`, không gọi DB), ca B15 / B16 trong `receivable_th06.sql`, REGISTRY (owner hai hàm), TH-06 6.2. Người dùng chạy: `tools/db_check.sh receivable_th06` (kỳ vọng OK), `tools/db_check.sh --no-reset sales_th05`; chỉ sau đó commit.

**Lệnh đã chạy (Flutter):** `flutter test test/features/sales` 1006 → sau xoá SG-11 và thêm test: xanh; `test/features/receivable`, `test/features/partner` xanh; `flutter analyze` không error / warning. `flutter test` toàn app: chỉ rớt 62 ca e2e `catalog/presentation/pages` (`pumpAndSettle timed out`), **có sẵn từ trước** (chạy lại một file khi tạm cất thay đổi vẫn rớt).

**Quyết định / lệch plan (Ruling).**
- Băm khoá chống trùng chỉ thêm `offsetTargetOrderIds` khi danh sách không rỗng, giữ nguyên hash cũ (test `return_exchange_hash_unchanged_confirm`); chi phí nếu sai: không có.
- Test parity `params_confirm` cập nhật thêm `offset_target_order_ids: []`.
- Bộ chọn phương thức hoàn ở nhánh khách được hưởng ghi `CK` (đúng prototype), nhánh thu giữ `Chuyển khoản`.
- Dòng cấn trừ ở SG-14 đặt trước dòng "Hoàn cho khách" (đúng ảnh prototype); khi có cấn trừ mà hoàn 0 thì hiện `Hoàn cho khách: 0đ`.
- Xoá `record_sales_payment` khỏi danh sách RPC app gọi trong `sales_sql_contract_test` (35 → 34); hàm SQL giữ.
- Dòng meta của hero (`Chênh lệch … · Hàng trả … · Hàng đổi …`) và tiêu đề ô cấn trừ không dùng số đều (tabular) vì tabular làm chữ rộng hơn bản HTML, gây xuống dòng / cắt `…`.

**Golden.** `flutter-SG-13-*` đủ 16 ảnh (cạnh ảnh `proto-*`). Khác prototype còn lại: icon cảnh báo hiện ô vuông (font icon không nạp trong test, như golden T6-2b), nền trang xám theo `VPageScaffold`, sheet xác nhận xếp nút dọc (sheet có sẵn), hero meta ở 390 xuống dòng. **Chưa làm** golden `patch-sg14 / sg09 / sg09b / sg09c / pt07`.

**Chưa làm (cần người dùng):** chạy DB Task 1; `/impeccable audit`; kịch bản 9.1 trên iPhone và web; golden `patch-*`; tài liệu TH-06 9.4 và `detect_changes` sau cùng.

## Review

### R1 — 2026-11-19 · 🔄 cần sửa 2 việc + chờ kết quả DB

**Đã kiểm.**
- Migration `20261126001` so với thân gốc (`20261124002` cho `confirm_return_exchange`, `20261123001` cho `get_sales_order_timeline`): chỉ khác câu `update` cuối và dòng `description`, đúng Task 1. Không migration nào sau đó định nghĩa lại hai hàm (REGISTRY), nên trích từ file thay cho `pg_get_functiondef` là chấp nhận được. CHECK `balance` vẫn giữ vì `offset + refund` không đổi. Ca B15 / B16 đúng plan; ca "tick cả hai" đã có ở B12 (`offsetAmountMinor 500000` sau xác nhận).
- Đọc diff 8 commit: dữ liệu (`offset`, khoá kế hoạch, khoá giao dịch, hash), `planReturnSettlement`, cubit (tick, gửi đơn có số trừ > 0, STALE / `OFFSET_TARGET_INVALID` có gửi đơn thì hộp thoại, không tự tải lại), SG-13, SG-14, phiếu đổi/trả, xoá SG-11, SG-09 / 09b / 09c, PT-07 (`customerSection`). Route `/more/receivables/:id` nằm ngoài shell nên `push` từ tab khác quay lại được.
- So ảnh SG-13 `mixed-390`, `all-selected-390`, `all-selected-1280` với prototype: bố cục, chữ, màu khớp, trừ mục 1 dưới đây.
- `flutter test test/features/sales test/features/receivable test/features/partner`: **1440 PASS**. `flutter analyze`: không error, **1 warning mới** (gợi ý dưới).
- Review Focus 1–5 đều có test.

**Cần sửa**

1. **(Trung bình) SG-13 ở 390: tiêu đề ô cấn trừ bị cắt mất số còn nợ** — `sales_return_entitled_settlement.dart` `_OffsetRow`. Cột "Trừ …" chiếm cả chiều cao ô nên tiêu đề chỉ còn chỗ hẹp: `DH-002 · còn nợ 2.000.0…` (ảnh `flutter-SG-13-all-selected-390`, `mixed-390`). Prototype hiện đủ `DH-002 · còn nợ 2.000.000 ₫` vì số "Trừ" canh đáy, tiêu đề tràn sang khoảng trống phía trên số. Nhân viên cần thấy đơn còn nợ bao nhiêu để quyết định bỏ tick.
   Cách sửa: phần giữa thành `Column` hai hàng — hàng 1: tiêu đề chiếm hết bề ngang (trừ ô tick); hàng 2: `Row(ReceivableDueBadge, Spacer, Text('Trừ …'))`. Chạy lại golden SG-13 (16 ảnh); thêm kiểm `find.text('DH-002 · còn nợ 2.000.000 ₫')` hiện đủ ở 390.

2. **(Trung bình) Quay lại từ CN-02 thì PT-07 và SG-09 vẫn hiện số cũ (iPhone)** — `openCustomerReceivable` bỏ qua `Future` của `context.push`. `CustomerReceivableSummaryCard` chỉ tải trong `initState`; SG-09 không tải lại sau khi quay về. Kịch bản 9.1 bước 6 (iPhone): PT-07 → CN-02 → thu "Tất cả đơn · trả hết" → quay lại, PT-07 vẫn "Còn nợ 18.000.000 ₫ · 3 đơn", trái với "CN-01 = CN-02 = PT-07 ở mọi bước". Kéo làm mới PT-07 cũng không tải lại khối này (cùng `customerId`).
   Cách sửa:
   - `Future<void> openCustomerReceivable(...)`: iPhone `return context.push(path)` (đợi tới khi quay lại); web giữ `go`.
   - Thẻ PT-07: `await openCustomerReceivable(...)` rồi `_load()`.
   - SG-09: `await openCustomerReceivable(...)` rồi `_cubit.refresh()`.
   - Test: fake repo đổi số giữa hai lần gọi; chạm thẻ, đóng route → thẻ hiện số mới; SG-09 tương tự (`refresh` được gọi).

**Chưa xác minh (người dùng chạy local)**

3. **Task 1 DB.** Chạy:
   - `tools/db_check.sh --no-reset receivable_th06` **trước** migration → phải ra `FAIL: B15 offset thật = 0`;
   - `tools/db_check.sh receivable_th06` → `receivable_th06: OK`;
   - `tools/db_check.sh --no-reset sales_th05` → OK.

   Gửi lại kết quả. Đến lúc đó SG-14 / phiếu đổi/trả ở ca bỏ tick (Review Focus 1) mới đúng khi chạy thật; test Flutter chỉ dùng dữ liệu giả.

4. **Còn lại của Task 9:** golden `patch-sg09 / sg09b / sg09c / sg14 / pt07` (Task 6–8 Bước "Golden"), `/impeccable audit`, kịch bản 9.1 iPhone + web, `detect_changes` sau cùng.

**Gợi ý (không bắt buộc)**

- `test/features/sales/data/sales_payment_repository_test.dart:8` import `models.dart` thừa sau khi xoá test SG-11 (warning mới) — xoá.
- SG-14: dòng `Cấn trừ vào DH-002: …` tô `colors.warning` (vàng) như thể cảnh báo; prototype là dòng thường — nên dùng `textPrimary` / `textSecondary`.
- `_OffsetRow`: `Semantics(checked:)` bọc ngoài `VCheckbox` nên trình đọc màn hình có thể đọc hai lần trạng thái chọn; bọc `MergeSemantics` hoặc `ExcludeSemantics` ô tick, kèm `label: '${orderCode}, còn nợ …, Trừ …'`.

**Phản hồi R1 (2026-11-19, người làm).** Xác nhận cả 2 việc là đúng, đã sửa:
1. SG-13 ô cấn trừ: phần giữa thành `Column` (tiêu đề đủ bề ngang; hàng 2 = nhãn hạn + `Trừ …` canh phải). Test `offset row title shows full outstanding at 390` (font Inter thật, `didExceedMaxLines` false) **đỏ trên bản cũ, xanh trên bản mới**; 16 golden SG-13 chạy lại, ảnh 390 hiện đủ `DH-002 · còn nợ 2.000.000 ₫`.
2. `openCustomerReceivable` giờ `Future<void>` (iPhone đợi `push`); thẻ PT-07 `_load()` và SG-09 `_cubit.refresh()` sau khi quay về. Test: thẻ PT-07 đổi số sau khi pop CN-02; SG-09 `summaryCalls` tăng sau pop.
3. Gợi ý cũng làm: bỏ import thừa (hết warning); dòng cấn trừ SG-14 dùng `textPrimary`; `_OffsetRow` gộp semantics một nhãn `DH-002 · còn nợ …, Trừ …`.
`flutter test test/features/sales test/features/receivable test/features/partner`: 1442 PASS; `flutter analyze`: sạch. Mục 3–4 (DB, audit, kịch bản 9.1, golden `patch-*`) vẫn chờ.

**Commit.** Migration, B15 / B16, REGISTRY chưa commit — commit sau khi DB xanh.
