# Quyết toán đổi/trả — hiển thị đúng hoàn tiền / giảm nợ đơn, khóa công tắc cấn trừ (E-10) — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** (1) Màn «Quyết toán đổi/trả» hiển thị **đúng số server đã tính** cho nhánh hoàn tiền — «Cần hoàn tiền» = `refund_amount_minor`, «Giảm nợ đơn này» = `receivable_reverse_amount_minor` — **không phụ thuộc công tắc**. Công tắc «Cấn trừ công nợ hiện tại» vẫn hiện nhưng **khóa** kèm ghi chú «Sẽ áp dụng khi có module công nợ.». Sửa FAIL E-10. (2) Khoản hoàn khi xác nhận **ghi đúng phương thức người dùng chọn** (hết ghi cứng `cash`) và **bỏ nút «Kết hợp»** (chưa hỗ trợ hoàn nhiều phương thức) — sửa ý «đúng method» của E-09.

**Architecture:** Chỉ sửa app `apps/erp` (presentation). Server **đúng** (đã kiểm DB đơn DH202609250007: hoàn 100.000, giảm nợ 300.000, còn nợ 0, 1 lần hoàn, 1 điều chỉnh, 0 hủy, `completed`/`fully_returned`). Gỡ toàn bộ logic «cấn trừ phía app» (`offsetDebt`, `actualOffsetMinor`, `effectiveRefundMinor`, `remainingDebtMinor`, `updateOffsetDebt`, thẻ «Công nợ sau cấn trừ», bottom bar «Đã cấn trừ») vì nó hiểu sai `receivable_reverse` là «nợ hiện có» và server không nhận công tắc. Cấn trừ qua nhiều đơn thuộc module công nợ (đã ghi ở `01-domain-model.md` §9.2).

**Tech Stack:** Flutter/Dart, flutter_bloc; `flutter_test`.

**Spec:** Chốt trong chat 2026-09-25: màn luôn hiện số server; **khóa công tắc** (hiện, xám, không bấm được) + ghi chú.

## Global Constraints

- Không đổi SQL/RPC/DTO/command. Không đổi nhánh **thu thêm** và nhánh **không chênh lệch** (trừ getter `_isZeroDifference` đã sửa trước đó — giữ nguyên).
- **UI change được user yêu cầu** — chỉ trong nhánh hoàn tiền + bottom bar của màn quyết toán.
- **Phương thức hoàn (Task 2):** chỉ đổi đúng tham số `method` của lời gọi hoàn trong `confirm_return_exchange` (migration `20260904001`, owner theo REGISTRY) — dùng cùng biểu thức với khoản thu: `coalesce(nullif(btrim(payment_method), ''), 'cash')`. Không đổi chữ ký hàm, không đổi app/command (app đã gửi `payment_method` = `'cash'` | `'manualBankTransfer'`). User **không reset DB** → xuất SQL chạy tay.
- Mặc định phương thức ở màn quyết toán hiện là **Chuyển khoản** (state `paymentMethod = manualBankTransfer`) → sau khi sửa, khoản hoàn mặc định ghi `manualBankTransfer` nếu người dùng không đổi. Giữ nguyên mặc định (đồng nhất với nhánh thu); tester chọn phương thức rõ ràng khi test.
- Không đổi sheet xác nhận, màn kết quả, phiếu đổi/trả PDF (đã đúng).
- Không `dart format` cả package.
- **Không `git commit`** — cuối task tóm tắt + đề xuất commit rồi dừng chờ review.
- Trước khi sửa: `node .gitnexus/run.cjs impact "<symbol>" --direction upstream --repo .` cho `SalesReturnExchangeSettlementState`, `SalesReturnExchangeSettlementBody`, `SalesReturnExchangeSettlementCubit`; báo blast radius, cảnh báo nếu HIGH/CRITICAL.

## Lưu ý dễ sót

- `receivable_reverse_amount_minor` = **nợ của đơn được xoá**, KHÔNG phải «nợ hiện có». Không được trừ tiền hoàn vào nó; không tạo lại nhãn «Công nợ trước/sau cấn trừ», «Còn phải hoàn», «Đã cấn trừ», «Hoàn tiền trước xử lý».
- Gỡ `offsetDebt` phải gỡ **đủ**: constructor + field + 3 getter + `copyWith` (tham số và gán) + `props` (state); `updateOffsetDebt` (cubit); tham số `offsetDebt`/`onOffsetDebtChanged` ở **cả** `SalesReturnExchangeSettlementBody` và `_ReadyBody`; `_offsetDebt`, `_debtExpanded`, khối trong `initState`/`didUpdateWidget`, method `_debtRow` (body); `onOffsetDebtChanged:` (page); `_harness(onOffsetDebtChanged:)` (test). Sót một chỗ là không compile.
- Công tắc khóa: `VSwitch(value: false, enabled: false)` **không truyền `onChanged`** (VSwitch coi `onChanged == null` là disabled). Giữ key `sw_sg12_offset_debt`.
- Công tắc chỉ hiện khi `receivableReverseMinor > 0` (giữ điều kiện hiện có), không thêm vào chỗ khác.
- `_highlightAmount`: nhánh hoàn phải dựa trên `netDifferenceMinor < 0` (không phải `storeRefundMinor > 0`) để đơn chưa thu (hoàn 0đ) vẫn ra «Cần hoàn tiền 0đ» thay vì «Không phát sinh chênh lệch».
- «Phương thức hoàn» hiện khi `storeRefundMinor > 0` (không còn `actualRefund`).
- Test `'return on an unpaid order is not shown as zero difference'` đang tìm `wgt_sg12_debt_card` → đổi sang `wgt_sg12_debt_reduction`.

## Khảo sát (vị trí hiện tại)

| Vị trí | Hiện trạng |
|---|---|
| `lib/features/sales/presentation/bloc/return_exchange_order/sales_return_exchange_settlement_state.dart` | `this.offsetDebt = true` (~35), field `offsetDebt` (~64), getter `actualOffsetMinor` (~86), `effectiveRefundMinor` (~95), `remainingDebtMinor` (~103); `copyWith`/`props` có `offsetDebt` |
| `…/sales_return_exchange_settlement_cubit.dart` | `updateOffsetDebt(bool)` (~194-198) |
| `lib/features/sales/presentation/widgets/sales_return_exchange_settlement_body.dart` | Body truyền `offsetDebt`, `onOffsetDebtChanged`; `_ReadyBody` field (~159, 163, 175, 179); state `_offsetDebt`, `_debtExpanded` (~189-190), `initState`/`didUpdateWidget` (~200, 212-214); nhánh hoàn `: !_isCollect ? Builder(builder: …)` (~346-534) tính `actualOffset/actualRefund/remainingDebt`; `_highlightAmount` (~742) nhánh `storeRefundMinor > 0`; `_debtRow` (~812) |
| `lib/features/sales/presentation/pages/sales_return_exchange_settlement_page.dart` | `_bottomBarLabel/_bottomBarValue` (~70-96) dùng `effectiveRefundMinor/actualOffsetMinor` («Đã cấn trừ»); `onOffsetDebtChanged: _cubit.updateOffsetDebt` (~174) |
| `packages/vet45_design_system/lib/src/components/v_switch.dart` | `VSwitch({required value, onChanged, enabled, tone, …})`; disabled khi `enabled == false` hoặc `onChanged == null` |
| `test/features/sales/presentation_module/widgets/sales_return_exchange_settlement_body_test.dart` | test cấn trừ `'ready refund with debt offset flow …'` (~130), `'ready refund with full debt offset …'` (~175); fixture `_debtValuation`, `_fullDebtOffsetValuation` (số không cân bằng); `_harness(onOffsetDebtChanged:)` |
| `test/features/sales/presentation_module/bloc/sales_return_exchange_settlement_cubit_test.dart` | `'debt offset dynamic calculations …'` (~364), `'updateOffsetDebt toggles state on the cubit'` (~400) |

Dữ liệu chuẩn E-10: đơn 400.000đ, thu 100.000đ, trả toàn bộ → `net = -400000`, `refund = 100000`, `receivable_reverse = 300000`.

---

### Task 1: Màn quyết toán hiển thị theo server + khóa công tắc

**Files:**
- Modify: `apps/erp/lib/features/sales/presentation/bloc/return_exchange_order/sales_return_exchange_settlement_state.dart`
- Modify: `apps/erp/lib/features/sales/presentation/bloc/return_exchange_order/sales_return_exchange_settlement_cubit.dart`
- Modify: `apps/erp/lib/features/sales/presentation/widgets/sales_return_exchange_settlement_body.dart`
- Modify: `apps/erp/lib/features/sales/presentation/pages/sales_return_exchange_settlement_page.dart`
- Test: `apps/erp/test/features/sales/presentation_module/widgets/sales_return_exchange_settlement_body_test.dart`
- Test: `apps/erp/test/features/sales/presentation_module/bloc/sales_return_exchange_settlement_cubit_test.dart`

**Interfaces:**
- Consumes: `SalesReturnExchangeSettlementVm` (`netDifferenceMinor`, `storeRefundMinor`, `receivableReverseMinor`, `customerCollectMinor`) — không đổi.
- Produces: state **không còn** `offsetDebt` / `actualOffsetMinor` / `effectiveRefundMinor` / `remainingDebtMinor`; cubit **không còn** `updateOffsetDebt`; body **không còn** tham số `onOffsetDebtChanged`. Key mới `wgt_sg12_debt_reduction`, `txt_sg12_offset_debt_pending`; giữ `sw_sg12_offset_debt` (khóa).

- [ ] **Step 1: Chạy impact**

```bash
node .gitnexus/run.cjs impact "SalesReturnExchangeSettlementState" --direction upstream --repo .
node .gitnexus/run.cjs impact "SalesReturnExchangeSettlementBody" --direction upstream --repo .
node .gitnexus/run.cjs impact "SalesReturnExchangeSettlementCubit" --direction upstream --repo .
```

- [ ] **Step 2: Sửa test widget (fail)**

Trong `sales_return_exchange_settlement_body_test.dart`:

(a) **Xoá** 2 test `'ready refund with debt offset flow renders switch and expandable debt card'` và `'ready refund with full debt offset hides payment method and shows remaining debt'`. Thêm vào đúng chỗ đó:

```dart
  testWidgets('E-10 full return of a partially paid order shows server refund and order debt reduction', (tester) async {
    await tester.pumpWidget(
      _harness(
        SalesReturnExchangeSettlementState(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
          orderNumber: 'DH-000129',
          customerDisplayName: 'Nguyễn Văn An',
          status: SalesReturnExchangeSettlementStatus.ready,
          valuation: _refundWithDebtReductionValuation(),
        ),
      ),
    );

    expect(find.text('Cần hoàn tiền'), findsOneWidget);
    expect(find.text('100.000đ'), findsWidgets);
    expect(find.byKey(const Key('wgt_sg12_debt_reduction')), findsOneWidget);
    expect(find.text('Giảm nợ đơn này'), findsOneWidget);
    expect(find.text('300.000đ'), findsOneWidget);
    expect(
      find.text('Phần khách chưa thanh toán cho hàng trả được trừ khỏi nợ của đơn, không hoàn tiền.'),
      findsOneWidget,
    );
    expect(find.text('Phương thức hoàn'), findsOneWidget);
    expect(find.text('Tiền mặt'), findsOneWidget);
    expect(find.text('Chuyển khoản'), findsOneWidget);
    expect(find.text('Kết hợp'), findsNothing);
    // Old app-side offset math is gone.
    expect(find.text('Còn phải hoàn'), findsNothing);
    expect(find.text('Hoàn tiền trước xử lý'), findsNothing);
    expect(find.text('Công nợ sau cấn trừ'), findsNothing);
    expect(find.byKey(const Key('wgt_sg12_debt_card')), findsNothing);
  });

  testWidgets('offset switch is shown locked with a pending note and cannot change amounts', (tester) async {
    await tester.pumpWidget(
      _harness(
        SalesReturnExchangeSettlementState(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
          status: SalesReturnExchangeSettlementStatus.ready,
          valuation: _refundWithDebtReductionValuation(),
        ),
      ),
    );

    final toggle = tester.widget<VSwitch>(find.byKey(const Key('sw_sg12_offset_debt')));
    expect(toggle.value, isFalse);
    expect(toggle.enabled, isFalse);
    expect(toggle.onChanged, isNull);
    expect(find.text('Cấn trừ công nợ hiện tại'), findsOneWidget);
    expect(find.byKey(const Key('txt_sg12_offset_debt_pending')), findsOneWidget);
    expect(find.text('Sẽ áp dụng khi có module công nợ.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('sw_sg12_offset_debt')));
    await tester.pumpAndSettle();
    expect(find.text('100.000đ'), findsWidgets);
    expect(find.text('300.000đ'), findsOneWidget);
    expect(find.text('Còn phải hoàn'), findsNothing);
  });
```

(b) Test `'return on an unpaid order is not shown as zero difference'`: đổi dòng

```dart
    expect(find.byKey(const Key('wgt_sg12_debt_card')), findsOneWidget);
```

thành

```dart
    expect(find.byKey(const Key('wgt_sg12_debt_reduction')), findsOneWidget);
    expect(find.text('Cần hoàn tiền'), findsOneWidget);
    expect(find.text('Phương thức hoàn'), findsNothing);
```

(c) `_harness`: bỏ tham số `ValueChanged<bool>? onOffsetDebtChanged,` và dòng `onOffsetDebtChanged: onOffsetDebtChanged,`.

(d) Thay fixture `_debtValuation()` và `_fullDebtOffsetValuation()` bằng:

```dart
/// E-10: đơn 400.000đ đã thu 100.000đ, trả toàn bộ → hoàn 100.000đ, giảm nợ đơn 300.000đ.
ReturnExchangeValuationDto _refundWithDebtReductionValuation() {
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
  return const ReturnExchangeValuationDto(
    returnValue: MoneyDto(amountMinor: 400000, currencyCode: 'VND'),
    exchangeValue: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    settlementDifference: MoneyDto(amountMinor: -400000, currencyCode: 'VND'),
    settlementPlan: plan,
    sourceOrderVersion: 1,
  );
}
```

- [ ] **Step 3: Sửa test cubit**

Trong `sales_return_exchange_settlement_cubit_test.dart`, **xoá** `'debt offset dynamic calculations follow state and authoritative amounts'` và `'updateOffsetDebt toggles state on the cubit'`, thêm:

```dart
  test('refund plan keeps the server split of refund and order debt reduction', () {
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

    final state = SalesReturnExchangeSettlementState(
      orderId: 'order-1',
      returnExchangeId: 'return-1',
      valuation: valuationFor(plan),
      status: SalesReturnExchangeSettlementStatus.ready,
    );

    expect(state.effectiveSettlement!.storeRefundMinor, 100000);
    expect(state.effectiveSettlement!.receivableReverseMinor, 300000);
    expect(state.canConfirm, isTrue);
  });
```

- [ ] **Step 4: Chạy test, xác nhận fail**

Run: `cd apps/erp && flutter test test/features/sales/presentation_module/widgets/sales_return_exchange_settlement_body_test.dart`
Expected: FAIL — chưa có `wgt_sg12_debt_reduction` / công tắc chưa khóa (và/hoặc compile vì `_harness` còn truyền `onOffsetDebtChanged` cho body — sẽ hết ở Step 7).

- [ ] **Step 5: Sửa state**

Trong `sales_return_exchange_settlement_state.dart`:
1. Xoá `this.offsetDebt = true,` trong constructor.
2. Xoá field + doc `/// Whether to offset the customer's existing receivable debt in a refund flow.` / `final bool offsetDebt;`.
3. Xoá nguyên 3 getter `actualOffsetMinor`, `effectiveRefundMinor`, `remainingDebtMinor` (kèm doc comment).
4. `copyWith`: xoá tham số `bool? offsetDebt,` và dòng `offsetDebt: offsetDebt ?? this.offsetDebt,`.
5. `props`: xoá `offsetDebt,`.

- [ ] **Step 6: Sửa cubit**

Xoá:

```dart
  /// Toggles whether to offset customer debt in a refund flow.
  void updateOffsetDebt(bool value) {
    if (isClosed) return;
    emit(state.copyWith(offsetDebt: value));
  }
```

- [ ] **Step 7: Body — gỡ tham số cấn trừ**

Trong `sales_return_exchange_settlement_body.dart`:
1. `SalesReturnExchangeSettlementBody`: xoá `this.onOffsetDebtChanged,`, field + doc `/// Notifies whether to offset existing customer debt in a refund flow.` / `final ValueChanged<bool>? onOffsetDebtChanged;`, và hai dòng `offsetDebt: state.offsetDebt,` / `onOffsetDebtChanged: onOffsetDebtChanged,` khi dựng `_ReadyBody`.
2. `_ReadyBody`: xoá `required this.offsetDebt,`, `required this.onOffsetDebtChanged,`, `final bool offsetDebt;`, `final ValueChanged<bool>? onOffsetDebtChanged;`.
3. `_ReadyBodyState`: xoá `late bool _offsetDebt;`, `bool _debtExpanded = false;`, dòng `_offsetDebt = widget.offsetDebt;` (initState), khối `if (oldWidget.offsetDebt != widget.offsetDebt) { _offsetDebt = widget.offsetDebt; }` (didUpdateWidget).
4. Xoá nguyên method `Widget _debtRow(…) { … }`.

- [ ] **Step 8: Body — `_highlightAmount` nhánh hoàn**

Trong `_highlightAmount`, thay:

```dart
    } else if (widget.settlement.storeRefundMinor > 0) {
      label = 'Cần hoàn tiền';
      amountMinor = widget.settlement.storeRefundMinor;
```

bằng:

```dart
    } else if (widget.settlement.netDifferenceMinor < 0) {
      label = 'Cần hoàn tiền';
      amountMinor = widget.settlement.storeRefundMinor;
```

- [ ] **Step 9: Body — thay nhánh hoàn tiền**

Thay toàn bộ nhánh bắt đầu `: !_isCollect` / `? Builder(` (khối `builder: (context) { final int receivableReverse = … return Column(…); }`) cho tới ngay trước `: Column(` của nhánh thu (`'Khách thanh toán ngay'`) bằng:

```dart
                : !_isCollect
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Server split (Sales): refund up to what was collected; the
                      // rest reduces this order's own debt. Cross-order debt offset
                      // belongs to Receivable, so the switch below is locked.
                      _highlightAmount(context),
                      if (widget.settlement.receivableReverseMinor > 0) ...[
                        const VGap.sm(),
                        VCard(
                          key: const Key('wgt_sg12_debt_reduction'),
                          backgroundColor: colors.surfaceAlt,
                          border: Border.all(color: colors.borderDefault),
                          padding: const EdgeInsets.symmetric(
                            horizontal: VSpacing.space3,
                            vertical: VSpacing.space3,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const VText(
                                'Giảm nợ đơn này',
                                variant: VTextVariant.bodyDefault,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              VText(
                                MoneyFormatter.formatMinor(widget.settlement.receivableReverseMinor),
                                variant: VTextVariant.bodyDefault,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const VGap.xs(),
                        VText(
                          'Phần khách chưa thanh toán cho hàng trả được trừ khỏi nợ của đơn, không hoàn tiền.',
                          variant: VTextVariant.bodySmall,
                          color: colors.textSecondary,
                        ),
                        const VGap.md(),
                        Row(
                          children: [
                            VSwitch(
                              key: const Key('sw_sg12_offset_debt'),
                              value: false,
                              enabled: false,
                              tone: VComponentTone.success,
                            ),
                            const VGap.horizontalSm(),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const VText(
                                    'Cấn trừ công nợ hiện tại',
                                    variant: VTextVariant.bodyDefault,
                                    style: TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  VText(
                                    'Sẽ áp dụng khi có module công nợ.',
                                    key: const Key('txt_sg12_offset_debt_pending'),
                                    variant: VTextVariant.bodySmall,
                                    color: colors.textSecondary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (widget.settlement.storeRefundMinor > 0) ...[
                        const VGap.md(),
                        const VText(
                          'Phương thức hoàn',
                          variant: VTextVariant.bodyDefault,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const VGap.sm(),
                        // Refund supports one method; "Kết hợp" (split) is not
                        // supported by the confirm RPC, so it is not offered.
                        VSegmentedControl(
                          key: const Key('seg_sg12_settlement_method'),
                          segments: const ['Tiền mặt', 'Chuyển khoản'],
                          selectedIndex: _methods.indexOf(widget.method),
                          tone: VComponentTone.success,
                          onChanged: (index) {
                            widget.onMethodChanged?.call(_methods[index]);
                          },
                        ),
                      ],
                    ],
                  )
```

(Phương thức hoàn: chỉ còn «Tiền mặt / Chuyển khoản», dùng chung `_methods` với nhánh thu; điều kiện hiện đổi sang `storeRefundMinor > 0`.)

- [ ] **Step 10: Page — bottom bar + wiring**

Trong `sales_return_exchange_settlement_page.dart`, thay `_bottomBarLabel` và `_bottomBarValue` bằng:

```dart
  String _bottomBarLabel(SalesReturnExchangeSettlementState state) {
    final settlement = state.effectiveSettlement;
    if (settlement == null) return 'Quyết toán';
    if (settlement.customerCollectMinor > 0) return 'Phải thu thêm';
    if (settlement.netDifferenceMinor < 0) return 'Cần hoàn tiền';
    return 'Không chênh lệch';
  }

  String _bottomBarValue(SalesReturnExchangeSettlementState state) {
    final settlement = state.effectiveSettlement;
    if (settlement == null) return '—';
    if (settlement.customerCollectMinor > 0) {
      return MoneyFormatter.formatMinor(settlement.customerCollectMinor);
    }
    if (settlement.netDifferenceMinor < 0) {
      return MoneyFormatter.formatMinor(settlement.storeRefundMinor);
    }
    return MoneyFormatter.formatMinor(0);
  }
```

và xoá dòng `onOffsetDebtChanged: _cubit.updateOffsetDebt,`.

- [ ] **Step 11: Kiểm tra không còn tham chiếu cũ**

Run: `cd apps/erp && grep -rnE "offsetDebt|OffsetDebt|actualOffsetMinor|effectiveRefundMinor|remainingDebtMinor|_debtRow|_debtExpanded|btn_sg12_debt_toggle|Còn phải hoàn|Hoàn tiền trước xử lý|Đã cấn trừ|Công nợ sau cấn trừ" lib/features/sales/presentation/widgets/sales_return_exchange_settlement_body.dart lib/features/sales/presentation/pages/sales_return_exchange_settlement_page.dart lib/features/sales/presentation/bloc/return_exchange_order/ test/features/sales/presentation_module/`
Expected: chỉ còn các dòng `findsNothing` trong test mới (Step 2).

- [ ] **Step 12: Chạy test + analyze**

```bash
cd apps/erp
flutter test test/features/sales/presentation_module/widgets/sales_return_exchange_settlement_body_test.dart test/features/sales/presentation_module/bloc/sales_return_exchange_settlement_cubit_test.dart
flutter test test/features/sales/
flutter analyze lib/features/sales/presentation/bloc/return_exchange_order/ lib/features/sales/presentation/widgets/sales_return_exchange_settlement_body.dart lib/features/sales/presentation/pages/sales_return_exchange_settlement_page.dart test/features/sales/presentation_module/widgets/sales_return_exchange_settlement_body_test.dart test/features/sales/presentation_module/bloc/sales_return_exchange_settlement_cubit_test.dart
```

Expected: PASS toàn bộ; analyze «No issues found!». Nếu `SalesReturnExchangeSettlementState` còn được dùng `offsetDebt` ở chỗ khác (ví dụ `sales_slip_pdf_generator.dart`, page detail) → compile báo lỗi, gỡ theo cùng nguyên tắc.

- [ ] **Step 13: Tóm tắt + đề xuất commit, dừng chờ review**

```bash
git add apps/erp/lib/features/sales/presentation/bloc/return_exchange_order/sales_return_exchange_settlement_state.dart apps/erp/lib/features/sales/presentation/bloc/return_exchange_order/sales_return_exchange_settlement_cubit.dart apps/erp/lib/features/sales/presentation/widgets/sales_return_exchange_settlement_body.dart apps/erp/lib/features/sales/presentation/pages/sales_return_exchange_settlement_page.dart apps/erp/test/features/sales/presentation_module/widgets/sales_return_exchange_settlement_body_test.dart apps/erp/test/features/sales/presentation_module/bloc/sales_return_exchange_settlement_cubit_test.dart
git commit -m "fix(sales): quyết toán đổi/trả hiện đúng hoàn tiền và giảm nợ đơn, khóa công tắc cấn trừ"
```

(User tự commit; các file có thể còn thay đổi của đợt trước → dùng `git add -p` nếu muốn tách.)

---

### Task 2: Server ghi đúng phương thức hoàn khi xác nhận

**Files:**
- Modify: `supabase/migrations/20260904001_sales_normalize_outbox_and_commands.sql` (hàm `sales.confirm_return_exchange`, khối `if v_remainder_refund > 0 then … perform sales.settle_return_exchange_difference(…)`)
- Create: `modules/sales/infrastructure/test/domain/return_exchange_order/confirm_refund_method_sql_contract_test.dart`

**Interfaces:**
- Consumes: tham số sẵn có `payment_method text` của `confirm_return_exchange` (app gửi `'cash'` | `'manualBankTransfer'`).
- Produces: giao dịch hoàn (`sales_payment_transactions.transaction_type = 'refund'`, `source_context = 'return_exchange'`) có `payment_method_code` = phương thức người dùng chọn; thiếu thì `cash`.

- [ ] **Step 1: Chạy impact**

Run: `node .gitnexus/run.cjs impact "confirm_return_exchange" --direction upstream --repo .`

- [ ] **Step 2: Viết test fail**

Tạo `modules/sales/infrastructure/test/domain/return_exchange_order/confirm_refund_method_sql_contract_test.dart`:

```dart
import 'dart:io';

import 'package:test/test.dart';

/// SQL contract — khoản hoàn khi xác nhận đổi/trả ghi đúng phương thức người
/// dùng chọn (trước đây ghi cứng 'cash').
void main() {
  final sql = _readMigration('20260904001_sales_normalize_outbox_and_commands.sql');

  String settleCall(String fn, String suffix) {
    final start = fn.indexOf("|| '$suffix')");
    expect(start, greaterThan(-1), reason: suffix);
    return fn.substring(start, fn.indexOf('expected_source_version', start));
  }

  test('confirm refund uses the chosen payment method like the collect', () {
    final confirm = _lastFunctionBlock(sql, 'sales.confirm_return_exchange');
    const chosen = "method => coalesce(nullif(btrim(payment_method), ''), 'cash')::text,";
    expect(settleCall(confirm, ':refund'), contains(chosen));
    expect(settleCall(confirm, ':collect'), contains(chosen));
    expect(confirm, isNot(contains("method => 'cash'::text")));
  });
}

String _readMigration(String fileName) {
  final root = _findRepoRoot();
  return File('${root.path}/supabase/migrations/$fileName').readAsStringSync();
}

/// Last `create or replace function <qualifiedName>(` … `$$;` in [sql].
String _lastFunctionBlock(String sql, String qualifiedName) {
  final start = sql.lastIndexOf('create or replace function $qualifiedName(');
  if (start < 0) {
    throw StateError('$qualifiedName not found');
  }
  final end = sql.indexOf(r'$$;', start);
  return sql.substring(start, end + 3);
}

Directory _findRepoRoot() {
  var current = Directory.current.absolute;
  while (!Directory('${current.path}/supabase/migrations').existsSync()) {
    final parent = current.parent;
    if (parent.path == current.path) {
      throw StateError('Could not locate Vet45 workspace root');
    }
    current = parent;
  }
  return current;
}
```

- [ ] **Step 3: Chạy test, xác nhận fail**

Run: `cd modules/sales/infrastructure && dart test test/domain/return_exchange_order/confirm_refund_method_sql_contract_test.dart`
Expected: FAIL — khối `:refund` chứa `method => 'cash'::text`.

- [ ] **Step 4: Sửa SQL**

Trong `sales.confirm_return_exchange`, khối gọi hoàn (có `command_id => (confirm_return_exchange.command_id || ':refund')::text`), thay đúng dòng:

```sql
      method => 'cash'::text,
```

bằng:

```sql
      method => coalesce(nullif(btrim(payment_method), ''), 'cash')::text,
```

(Không sửa gì khác; khối thu `':collect'` đã dùng biểu thức này.)

- [ ] **Step 5: Chạy test + so baseline**

```bash
cd modules/sales/infrastructure
dart test test/domain/return_exchange_order/ test/domain/schema/
```

Expected: test mới PASS; các fail còn lại trùng baseline (so bằng `git stash push -q -- ../../../supabase/migrations/20260904001_sales_normalize_outbox_and_commands.sql` → chạy → `git stash pop -q`).

- [ ] **Step 6: Xuất SQL chạy tay (không commit)**

```bash
F=supabase/migrations/20260904001_sales_normalize_outbox_and_commands.sql
O="$SCRATCH/confirm_refund_method_manual.sql"
s=$(grep -n "^create or replace function sales.confirm_return_exchange(" "$F" | tail -1 | cut -d: -f1)
e=$(awk -v s="$s" 'NR>s && /^\$\$;/ {print NR; exit}' "$F")
{
  echo "-- Chạy tay trên SQL editor: khoản hoàn đổi/trả ghi đúng phương thức người dùng chọn."
  echo "begin;"; echo
  sed -n "${s},${e}p" "$F"; echo
  echo "commit;"
} > "$O"
grep -c "coalesce(nullif(btrim(payment_method), ''), 'cash')::text" "$O"
```

Expected: in ra `2` (thu + hoàn). Đọc lại file, gửi user. Chữ ký không đổi nên grant cũ giữ nguyên.

- [ ] **Step 7: Tóm tắt + đề xuất commit, dừng chờ review**

```bash
git add supabase/migrations/20260904001_sales_normalize_outbox_and_commands.sql modules/sales/infrastructure/test/domain/return_exchange_order/confirm_refund_method_sql_contract_test.dart
git commit -m "fix(sales): hoàn tiền đổi/trả ghi đúng phương thức người dùng chọn"
```

(User tự commit; file `20260904001` còn thay đổi của đợt refactor trước → `git add -p` chỉ chọn dòng `method`.)

---

## Kiểm tra thủ công (user)

Khách có tên; sản phẩm wxdie 50.000đ/hộp, Căng quá 100.000đ/thùng.

| Tình huống | Màn quyết toán kỳ vọng | Bottom bar |
|---|---|---|
| **E-10**: đơn 400.000đ (Căng quá × 4), thu 100.000đ, trả toàn bộ | Cần hoàn tiền **100.000đ** · Giảm nợ đơn này **300.000đ** + ghi chú · công tắc **xám, không bấm được** + «Sẽ áp dụng khi có module công nợ.» · Phương thức hoàn | Cần hoàn tiền 100.000đ |
| Đơn 400.000đ, thu 100.000đ, trả 2 thùng | Cần hoàn tiền 100.000đ · Giảm nợ đơn này 100.000đ | Cần hoàn tiền 100.000đ |
| Đơn 400.000đ **chưa thu**, trả 2 thùng | Cần hoàn tiền **0đ** · Giảm nợ đơn này 200.000đ · **không** có Phương thức hoàn | Cần hoàn tiền 0đ |
| **E-09**: đơn đã trả đủ, trả 1 thùng Căng quá đổi 1 hộp wxdie | Cần hoàn tiền 50.000đ · **không** có dòng giảm nợ, **không** có công tắc | Cần hoàn tiền 50.000đ |
| **E-08**: đổi sang hàng đắt hơn | Nhánh thu thêm như cũ | Phải thu thêm … |
| Đổi ngang giá | «Không phát sinh chênh lệch» như cũ | Không chênh lệch |

Sau khi xác nhận E-10, chạy lại câu SQL kiểm tra đơn (hoàn 100.000, giảm nợ 300.000, còn nợ 0, 1 lần hoàn, 1 điều chỉnh, 0 hủy) — số tiền phải **giống hệt** trước khi sửa.

**Phương thức hoàn (sau khi chạy SQL tay của Task 2):**

| Chọn ở màn quyết toán | `payment_method_code` của giao dịch `refund` |
|---|---|
| Tiền mặt | `cash` |
| Chuyển khoản | `manualBankTransfer` |
| (không còn nút «Kết hợp») | — |

```sql
select t.transaction_type, t.payment_method_code, t.amount_minor, t.source_context
from sales.sales_payment_transactions t
join sales.sales_order_settlements s on s.id = t.sales_order_settlement_id
join sales.sales_orders o on o.id = s.sales_order_id
where o.order_code = '<mã đơn>' and t.transaction_type = 'refund';
```

Phiếu bán hàng «Sau đổi/trả» của đơn hoàn bằng Chuyển khoản: khoản hoàn trừ vào dòng **Chuyển khoản**, không còn trừ vào Tiền mặt.
