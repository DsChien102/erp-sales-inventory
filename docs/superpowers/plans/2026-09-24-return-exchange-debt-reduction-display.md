# Đổi/trả — sửa hiển thị giảm nợ đơn (phiếu đổi/trả + trường hợp đơn chưa thu) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Phiếu đổi/trả PDF in đúng cách server chia (hoàn tiền + giảm nợ của chính đơn), và màn quyết toán không còn báo «Không phát sinh chênh lệch» khi khách trả hàng trên đơn chưa thu đồng nào. **Công tắc «Cấn trừ công nợ hiện tại» và thẻ cấn trừ giữ nguyên như hiện tại.**

**Architecture:** Chỉ sửa app `apps/erp` (presentation). Không đổi SQL/RPC/DTO/command. Server giữ cách chia: hoàn tối đa bằng số đã thu (`refund_amount_minor`), phần còn lại giảm nợ của đơn (`receivable_reverse_amount_minor`) — `20260830013` `evaluate_return_exchange_valuation`. Cấn trừ nợ **qua nhiều đơn** thuộc Receivable (`01-domain-model.md` §36–37, §117) — ghi chú deferred.

**Tech Stack:** Flutter/Dart, flutter_bloc, `package:pdf`; `flutter_test`.

**Spec:** Thiết kế chốt trong chat 2026-09-24 (hướng B, user chọn giữ nguyên công tắc). Không có spec file.

## Global Constraints

- **Không đụng** công tắc `sw_sg12_offset_debt`, thẻ `wgt_sg12_debt_card`, `offsetDebt` trong state/cubit/page, `actualOffsetMinor`/`effectiveRefundMinor`/`remainingDebtMinor`, bottom bar «Đã cấn trừ» — user chốt giữ nguyên (biết rằng công tắc hiện chỉ đổi số hiển thị, server không nhận).
- **Phiếu đổi/trả bám template user gửi (2026-09-25):** khối tiền chỉ có 3 kiểu «Phải thu thêm · Đã thu · Công nợ phát sinh» / «Cần hoàn tiền · Đã hoàn» / «Không chênh lệch 0đ»; khối nợ «Công nợ cũ của khách · Tổng công nợ». Không thêm nhãn tiêu đề mới; trường hợp hoàn trên đơn còn nợ chỉ được **thêm một dòng** «Giảm nợ đơn» giữa «Cần hoàn tiền» và «Đã hoàn».
- Không đổi phương thức hoàn (user chốt tạm thời không xử lý).
- Không đổi SQL/RPC/DTO/command.
- Không `dart format` cả package.
- **Không `git commit`** — cuối mỗi task tóm tắt + đề xuất commit rồi dừng chờ review.
- Trước khi sửa symbol: `node .gitnexus/run.cjs impact "<symbol>" --direction upstream --repo .` cho `SalesReturnExchangeSettlementBody`, `SalesSlipPdfGenerator`; báo blast radius, cảnh báo nếu HIGH/CRITICAL.
- Test chạy từ `apps/erp`: `flutter test <file>`; analyze: `flutter analyze <file…>`.

## Lưu ý dễ sót

- **Task 2 — headline hoàn tiền:** dòng đầu luôn là **«Cần hoàn tiền» = `plan.refundAmountMinor`**. Không dùng `|net|`, không dùng nhãn «Giảm trừ đơn hàng» — cả hai đều sai template.
- **Task 2 — không in «Đã cấn trừ»:** `receivable_reverse_amount_minor` **là phần nợ của đơn đã được xoá** (khách chưa trả cho hàng đã trả lại), không phải «nợ hiện có». In thành dòng «Giảm nợ đơn»; không in «Đã cấn trừ» / «Công nợ trước/sau cấn trừ».
- **Task 1 — chỉ một getter:** chỉ đổi `_isZeroDifference`. Không sửa nhánh hoàn (`Builder` có công tắc), không sửa `_highlightAmount`, bottom bar hay state — sửa rộng hơn sẽ phá luồng công tắc cấn trừ đang giữ nguyên. Không xoá test cấn trừ hiện có trong `sales_return_exchange_settlement_body_test.dart` / `sales_return_exchange_settlement_cubit_test.dart`.
- **Không commit thay user:** agent chỉ đề xuất lệnh commit cuối mỗi task; user tự commit sau khi review.

## Khảo sát

| Vị trí | Hiện trạng |
|---|---|
| `lib/features/sales/presentation/widgets/sales_return_exchange_settlement_body.dart` | `_isZeroDifference => customerCollectMinor == 0 && storeRefundMinor == 0` → đơn chưa thu, trả hàng (`refund = 0`, `receivable_reverse > 0`) rơi vào nhánh «Không cần thu thêm, hoàn tiền hoặc ghi nhận công nợ.» |
| `lib/features/sales/presentation/support/sales_slip_pdf_generator.dart` `_buildReturnSlipBody` | `offsetMinor = receivableReverse`; dòng tiêu đề «Cần hoàn tiền» = \|net\| dù phần lớn là giảm nợ; «Đã cấn trừ»; khối nợ «Công nợ trước/sau cấn trừ» với `existingDebt` (luôn 0) |

Ví dụ chuẩn: đơn 400.000đ, đã thu 100.000đ, khách trả hết → `net = -400000`, `refund = 100000`, `receivable_reverse = 300000`.

---

### Task 1: Màn quyết toán — đơn chưa thu mà trả hàng không bị coi là «không chênh lệch»

**Files:**
- Modify: `apps/erp/lib/features/sales/presentation/widgets/sales_return_exchange_settlement_body.dart` (getter `_isZeroDifference`)
- Test: `apps/erp/test/features/sales/presentation_module/widgets/sales_return_exchange_settlement_body_test.dart`

**Interfaces:**
- Consumes: `SalesReturnExchangeSettlementVm.netDifferenceMinor` (đã có).
- Produces: không đổi API.

- [ ] **Step 1: Chạy impact**

Run: `node .gitnexus/run.cjs impact "SalesReturnExchangeSettlementBody" --direction upstream --repo .`

- [ ] **Step 2: Viết test fail**

Thêm test (sau test `'ready zero difference flow renders clean status card without inputs'`):

```dart
  testWidgets('return on an unpaid order is not shown as zero difference', (tester) async {
    await tester.pumpWidget(
      _harness(
        SalesReturnExchangeSettlementState(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
          status: SalesReturnExchangeSettlementStatus.ready,
          valuation: _debtReductionOnlyValuation(),
        ),
      ),
    );

    expect(find.text('Không phát sinh chênh lệch'), findsNothing);
    expect(find.text('Không cần thu thêm, hoàn tiền hoặc ghi nhận công nợ.'), findsNothing);
    expect(find.byKey(const Key('wgt_sg12_debt_card')), findsOneWidget);
  });
```

Thêm fixture cuối file:

```dart
/// Đơn chưa thu đồng nào, khách trả 200.000đ: không hoàn, giảm nợ đơn 200.000đ.
ReturnExchangeValuationDto _debtReductionOnlyValuation() {
  const plan = ReturnExchangeSettlementPlanDto(
    currencyCode: 'VND',
    netDifferenceMinor: -200000,
    collectAmountMinor: 0,
    refundAmountMinor: 0,
    receivableCreateAmountMinor: 0,
    receivableReverseAmountMinor: 200000,
    processedCollectMinor: 0,
    processedRefundMinor: 0,
    pendingReceivableCreateMinor: 0,
    pendingReceivableReverseMinor: 0,
    remainderCollectMinor: 0,
    remainderRefundMinor: 0,
    sourceOrderVersion: 1,
    sourceSettlementVersion: 1,
  );
  return const ReturnExchangeValuationDto(
    returnValue: MoneyDto(amountMinor: 200000, currencyCode: 'VND'),
    exchangeValue: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    settlementDifference: MoneyDto(amountMinor: -200000, currencyCode: 'VND'),
    settlementPlan: plan,
    sourceOrderVersion: 1,
  );
}
```

- [ ] **Step 3: Chạy test, xác nhận fail**

Run: `cd apps/erp && flutter test test/features/sales/presentation_module/widgets/sales_return_exchange_settlement_body_test.dart`
Expected: FAIL — vẫn thấy «Không phát sinh chênh lệch».

- [ ] **Step 4: Sửa getter**

Thay:

```dart
  bool get _isZeroDifference =>
      widget.settlement.customerCollectMinor == 0 && widget.settlement.storeRefundMinor == 0;
```

bằng:

```dart
  // A return on an unpaid order refunds nothing but still reduces the order
  // debt, so only a zero net difference means "no difference".
  bool get _isZeroDifference => widget.settlement.netDifferenceMinor == 0;
```

- [ ] **Step 5: Chạy test + analyze**

```bash
cd apps/erp
flutter test test/features/sales/presentation_module/widgets/sales_return_exchange_settlement_body_test.dart test/features/sales/presentation_module/bloc/sales_return_exchange_settlement_cubit_test.dart
flutter analyze lib/features/sales/presentation/widgets/sales_return_exchange_settlement_body.dart test/features/sales/presentation_module/widgets/sales_return_exchange_settlement_body_test.dart
```

Expected: PASS toàn bộ (kể cả các test cấn trừ cũ); «No issues found!».

- [ ] **Step 6: Tóm tắt + đề xuất commit, dừng chờ review**

```bash
git add apps/erp/lib/features/sales/presentation/widgets/sales_return_exchange_settlement_body.dart apps/erp/test/features/sales/presentation_module/widgets/sales_return_exchange_settlement_body_test.dart
git commit -m "fix(sales): trả hàng trên đơn chưa thu không hiển thị là không chênh lệch"
```

(User tự commit.)

---

### Task 2: Phiếu đổi/trả PDF — tách «Giảm nợ đơn» và «Đã hoàn»

**Files:**
- Modify: `apps/erp/lib/features/sales/presentation/support/sales_slip_pdf_generator.dart` (`_buildReturnSlipBody` + method public mới)
- Test: `apps/erp/test/features/sales/presentation_module/support/sales_slip_pdf_generator_test.dart`

**Interfaces:**
- Consumes: `ReturnExchangeSettlementPlanDto` (`netDifferenceMinor`, `refundAmountMinor`, `receivableReverseAmountMinor`, `pendingReceivableReverseMinor`, `processedRefundMinor`, `processedCollectMinor`, `receivableCreateAmountMinor`, `pendingReceivableCreateMinor`).
- Produces: `static List<(String, String)> SalesSlipPdfGenerator.settlementRows(ReturnExchangeSettlementPlanDto plan)` — dòng đầu là dòng tiêu đề (in đậm, xanh).

- [ ] **Step 1: Chạy impact**

Run: `node .gitnexus/run.cjs impact "SalesSlipPdfGenerator" --direction upstream --repo .`

- [ ] **Step 2: Viết test fail**

Thêm vào `group('SalesSlipPdfGenerator', …)`:

```dart
    test('refund on an order with debt adds a debt-reduction row to the refund template', () {
      const plan = ReturnExchangeSettlementPlanDto(
        currencyCode: 'VND',
        netDifferenceMinor: -400000,
        collectAmountMinor: 0,
        refundAmountMinor: 100000,
        receivableCreateAmountMinor: 0,
        receivableReverseAmountMinor: 300000,
        processedCollectMinor: 0,
        processedRefundMinor: 0,
        pendingReceivableCreateMinor: 0,
        pendingReceivableReverseMinor: 0,
        remainderCollectMinor: 0,
        remainderRefundMinor: 100000,
        sourceOrderVersion: 1,
        sourceSettlementVersion: 1,
      );

      expect(SalesSlipPdfGenerator.settlementRows(plan), [
        ('Cần hoàn tiền', '100.000đ'),
        ('Giảm nợ đơn', '300.000đ'),
        ('Đã hoàn', '100.000đ'),
      ]);
    });

    test('collect follows the template: Phải thu thêm · Đã thu · Công nợ phát sinh', () {
      const plan = ReturnExchangeSettlementPlanDto(
        currencyCode: 'VND',
        netDifferenceMinor: 254762,
        collectAmountMinor: 254762,
        refundAmountMinor: 0,
        receivableCreateAmountMinor: 0,
        receivableReverseAmountMinor: 0,
        processedCollectMinor: 150000,
        processedRefundMinor: 0,
        pendingReceivableCreateMinor: 0,
        pendingReceivableReverseMinor: 0,
        remainderCollectMinor: 104762,
        remainderRefundMinor: 0,
        sourceOrderVersion: 1,
        sourceSettlementVersion: 1,
      );

      expect(SalesSlipPdfGenerator.settlementRows(plan), [
        ('Phải thu thêm', '254.762đ'),
        ('Đã thu', '150.000đ'),
        ('Công nợ phát sinh', '104.762đ'),
      ]);
    });

    test('zero difference follows the template: Không chênh lệch 0đ', () {
      const plan = ReturnExchangeSettlementPlanDto(
        currencyCode: 'VND',
        netDifferenceMinor: 0,
        collectAmountMinor: 0,
        refundAmountMinor: 0,
        receivableCreateAmountMinor: 0,
        receivableReverseAmountMinor: 0,
        processedCollectMinor: 0,
        processedRefundMinor: 0,
        pendingReceivableCreateMinor: 0,
        pendingReceivableReverseMinor: 0,
        remainderCollectMinor: 0,
        remainderRefundMinor: 0,
        sourceOrderVersion: 1,
        sourceSettlementVersion: 1,
      );

      expect(SalesSlipPdfGenerator.settlementRows(plan), [
        ('Không chênh lệch', '0đ'),
      ]);
    });

    test('plain refund follows the template: Cần hoàn tiền · Đã hoàn', () {
      const plan = ReturnExchangeSettlementPlanDto(
        currencyCode: 'VND',
        netDifferenceMinor: -50000,
        collectAmountMinor: 0,
        refundAmountMinor: 50000,
        receivableCreateAmountMinor: 0,
        receivableReverseAmountMinor: 0,
        processedCollectMinor: 0,
        processedRefundMinor: 0,
        pendingReceivableCreateMinor: 0,
        pendingReceivableReverseMinor: 0,
        remainderCollectMinor: 0,
        remainderRefundMinor: 50000,
        sourceOrderVersion: 1,
        sourceSettlementVersion: 1,
      );

      expect(SalesSlipPdfGenerator.settlementRows(plan), [
        ('Cần hoàn tiền', '50.000đ'),
        ('Đã hoàn', '50.000đ'),
      ]);
    });
```

- [ ] **Step 3: Chạy test, xác nhận fail**

Run: `cd apps/erp && flutter test test/features/sales/presentation_module/support/sales_slip_pdf_generator_test.dart`
Expected: FAIL — `settlementRows` chưa tồn tại (compile error).

- [ ] **Step 4: Thêm `settlementRows`**

Trong `SalesSlipPdfGenerator`, ngay trước `static String sanitizeFileName(`:

```dart
  /// Settlement rows the return slip prints; the first row is the headline.
  ///
  /// Follows the slip template (collect / refund / zero difference). A refund
  /// on an order that still owes is split by the server into the cash refund
  /// and a reduction of this order's own debt, so the refund template gets one
  /// extra "Giảm nợ đơn" row. Sales does not offset debt across orders
  /// (Receivable-owned), so no "offset" rows are printed.
  static List<(String, String)> settlementRows(ReturnExchangeSettlementPlanDto plan) {
    final netMinor = plan.netDifferenceMinor;
    if (netMinor > 0) {
      final processedCollect = plan.processedCollectMinor;
      final pendingReceivable = plan.receivableCreateAmountMinor > 0
          ? plan.receivableCreateAmountMinor
          : plan.pendingReceivableCreateMinor;
      final newlyIncurredDebt = pendingReceivable > 0
          ? pendingReceivable
          : (processedCollect < netMinor ? netMinor - processedCollect : 0);
      return [
        ('Phải thu thêm', MoneyFormatter.formatMinor(netMinor)),
        ('Đã thu', MoneyFormatter.formatMinor(processedCollect)),
        ('Công nợ phát sinh', MoneyFormatter.formatMinor(newlyIncurredDebt)),
      ];
    }
    if (netMinor < 0) {
      final debtReduction = plan.receivableReverseAmountMinor > 0
          ? plan.receivableReverseAmountMinor
          : plan.pendingReceivableReverseMinor;
      final refunded = plan.processedRefundMinor > 0
          ? plan.processedRefundMinor
          : plan.refundAmountMinor;
      return [
        // Headline is the real cash refund, not |net|: with order debt the
        // rest of |net| is the debt reduction below.
        ('Cần hoàn tiền', MoneyFormatter.formatMinor(plan.refundAmountMinor)),
        if (debtReduction > 0) ('Giảm nợ đơn', MoneyFormatter.formatMinor(debtReduction)),
        ('Đã hoàn', MoneyFormatter.formatMinor(refunded)),
      ];
    }
    return [('Không chênh lệch', MoneyFormatter.formatMinor(0))];
  }
```

- [ ] **Step 5: Dùng `settlementRows` trong `_buildReturnSlipBody`**

1. Thay đoạn khai báo từ `String outcomeLabel = 'Không chênh lệch';` tới hết `final finalDebt = isOffsetScenario ? … : (existingDebt + newlyIncurredDebt);` bằng:

```dart
    final rows = settlementRows(plan);
    final pendingReceivable = plan.receivableCreateAmountMinor > 0
        ? plan.receivableCreateAmountMinor
        : plan.pendingReceivableCreateMinor;
    final newlyIncurredDebt = pendingReceivable > 0
        ? pendingReceivable
        : (netMinor > 0 && plan.processedCollectMinor < netMinor
              ? netMinor - plan.processedCollectMinor
              : 0);
    final existingDebt = existingCustomerDebtMinor ?? 0;
    final finalDebt = existingDebt + newlyIncurredDebt;
```

2. Thay khối in tiền, từ `_row(\n          outcomeLabel,` tới hết nhánh `] else if (netMinor < 0) ...[ … ],` (ngay trước `if (customerDisplayName.trim().isNotEmpty) ...[` của khối công nợ), bằng:

```dart
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) pw.SizedBox(height: 3),
          _row(
            rows[i].$1,
            rows[i].$2,
            fonts,
            isBoldLabel: i == 0,
            isBoldValue: i == 0,
            valueColor: i == 0 ? PdfColor.fromHex('#1F7A36') : null,
          ),
        ],
```

3. Khối công nợ: thay 2 nhãn điều kiện

```dart
            isOffsetScenario ? 'Công nợ trước cấn trừ' : 'Công nợ cũ của khách',
```
```dart
            isOffsetScenario ? 'Công nợ sau cấn trừ' : 'Tổng công nợ',
```

bằng `'Công nợ cũ của khách',` và `'Tổng công nợ',`.

- [ ] **Step 6: Kiểm tra không còn biến cũ**

Run: `cd apps/erp && grep -nE "isOffsetScenario|offsetMinor|remainingRefund|outcomeLabel|outcomeColor|Đã cấn trừ|cấn trừ" lib/features/sales/presentation/support/sales_slip_pdf_generator.dart`
Expected: không có kết quả.

- [ ] **Step 7: Chạy test + analyze**

```bash
cd apps/erp
flutter test test/features/sales/presentation_module/support/sales_slip_pdf_generator_test.dart
flutter analyze lib/features/sales/presentation/support/sales_slip_pdf_generator.dart test/features/sales/presentation_module/support/sales_slip_pdf_generator_test.dart
```

Expected: PASS; «No issues found!».

- [ ] **Step 8: Tóm tắt + đề xuất commit, dừng chờ review**

```bash
git add apps/erp/lib/features/sales/presentation/support/sales_slip_pdf_generator.dart apps/erp/test/features/sales/presentation_module/support/sales_slip_pdf_generator_test.dart
git commit -m "fix(sales): phiếu đổi/trả tách giảm nợ đơn và tiền đã hoàn"
```

(User tự commit.)

---

### Task 3: Ghi chú deferred — cấn trừ nợ qua nhiều đơn thuộc Receivable

**Files:**
- Modify: `docs/themes/TH-05-sales-orders/harness/01-domain-model.md` (mục `### 9.2 Cross-module handoff — deferred`)

- [ ] **Step 1: Thêm ghi chú**

Ngay sau dòng `**Do not** put apply/retry/reconcile imperatives on outbox as integration events.` thêm:

```markdown

**Cấn trừ công nợ qua nhiều đơn — deferred (Receivable).** Dùng tiền lẽ ra hoàn của đơn này để trả nợ đơn khác cùng khách là thu nợ (collection) của Receivable, không phải Sales. Sales chỉ tách trong phạm vi **một đơn**: `refund_amount_minor` (hoàn tối đa bằng số đã thu) + `receivable_reverse_amount_minor` (phần nợ của chính đơn được xoá). Công tắc «Cấn trừ công nợ hiện tại» trên màn quyết toán đổi/trả hiện **chỉ đổi số hiển thị**, không gửi lên server (2026-09-24); nối với server khi theme công nợ live — Sales chỉ phát fact khoản hoàn, Receivable quyết định cấn trừ hay chi tiền.
```

- [ ] **Step 2: Tóm tắt + đề xuất commit, dừng chờ review**

```bash
git add docs/themes/TH-05-sales-orders/harness/01-domain-model.md
git commit -m "docs(sales): ghi chú cấn trừ công nợ qua nhiều đơn thuộc Receivable"
```

(User tự commit.)

---

## Kiểm tra thủ công (user, sau Task 1–2)

Kịch bản: khách có tên, đơn 8 thùng × 50.000đ = 400.000đ.

| Kịch bản | Kỳ vọng |
|---|---|
| Thu 100.000đ, trả hết 8 thùng | Phiếu đổi/trả: **Cần hoàn tiền** 100.000đ · Giảm nợ đơn 300.000đ · Đã hoàn 100.000đ; khối nợ «Công nợ cũ của khách» / «Tổng công nợ» |
| Thu 100.000đ, trả 4 thùng | Phiếu đổi/trả: **Cần hoàn tiền** 100.000đ · Giảm nợ đơn 100.000đ · Đã hoàn 100.000đ |
| Chưa thu đồng nào, trả 4 thùng | Màn quyết toán **không** hiện «Không phát sinh chênh lệch»; hiện thẻ cấn trừ như luồng hoàn. Phiếu: **Cần hoàn tiền** 0đ · Giảm nợ đơn 200.000đ · Đã hoàn 0đ |
| Đơn đã trả đủ: thu thêm / hoàn / không chênh lệch | Phiếu **giống hệt template**: «Phải thu thêm · Đã thu · Công nợ phát sinh» / «Cần hoàn tiền · Đã hoàn» / «Không chênh lệch 0đ» |
| Mọi kịch bản | Công tắc «Cấn trừ công nợ hiện tại» vẫn hiển thị và bật/tắt như trước |
