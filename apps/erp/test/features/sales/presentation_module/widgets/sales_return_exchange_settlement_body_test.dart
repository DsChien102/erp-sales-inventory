import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/core/formatting/money_formatter.dart';
import 'package:erp/features/sales/presentation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('settlement_transfer_shows_no_qr', (tester) async {
    await tester.pumpWidget(
      _harness(
        SalesReturnExchangeSettlementState(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
          status: SalesReturnExchangeSettlementStatus.ready,
          valuation: _collectValuation(),
          paymentMethod: SalesPaymentMethod.manualBankTransfer,
        ),
      ),
    );

    expect(find.text('QR cửa hàng · ACB'), findsNothing);
    expect(find.text('Nguyễn Văn A'), findsNothing);
  });

  testWidgets('settlement_has_no_offset_debt_switch', (tester) async {
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

    expect(find.byKey(const Key('sw_sg12_offset_debt')), findsNothing);
    expect(find.text('Sẽ áp dụng khi có module công nợ.'), findsNothing);
  });

  testWidgets('retryable failure without plan shows the real error', (tester) async {
    await tester.pumpWidget(
      _harness(
        const SalesReturnExchangeSettlementState(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
          status: SalesReturnExchangeSettlementStatus.retryableFailure,
          screenError: 'Không tải được valuation.',
        ),
      ),
    );

    expect(find.text('Thiếu kế hoạch quyết toán'), findsNothing);
    expect(find.text('Không tải được quyết toán'), findsOneWidget);
    expect(find.text('Không tải được valuation.'), findsOneWidget);
  });

  testWidgets('ready derives settlement from valuation plan', (tester) async {
    await tester.pumpWidget(
      _harness(
        SalesReturnExchangeSettlementState(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
          status: SalesReturnExchangeSettlementStatus.ready,
          valuation: _valuation(),
        ),
      ),
    );

    expect(find.text('Thiếu kế hoạch quyết toán'), findsNothing);
    expect(find.byKey(const Key('wgt_sg12_settlement_plan')), findsOneWidget);

    // Summary is collapsed by default; its rows appear only after expanding.
    expect(find.byKey(const Key('wgt_sg12_plan_breakdown')), findsNothing);
    await tester.tap(find.byKey(const Key('btn_sg12_plan_toggle')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('wgt_sg12_plan_breakdown')), findsOneWidget);
    expect(find.text('Giá trị hàng trả'), findsOneWidget);
    expect(find.text('Giá trị hàng đổi'), findsOneWidget);
    expect(find.text('-320.000đ'), findsWidgets);
  });

  testWidgets('ready collect flow renders payment collection UI', (tester) async {
    await tester.pumpWidget(
      _harness(
        SalesReturnExchangeSettlementState(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
          orderNumber: 'DH-000129',
          status: SalesReturnExchangeSettlementStatus.ready,
          valuation: _collectValuation(),
        ),
      ),
    );

    expect(find.text('DH-000129'), findsOneWidget);
    expect(find.text('Phải thu thêm'), findsOneWidget);
    expect(find.text('Khách thanh toán ngay'), findsOneWidget);
    expect(find.text('Phương thức thu'), findsOneWidget);
    expect(find.text('Tiền mặt'), findsOneWidget);
    expect(find.text('Chuyển khoản'), findsOneWidget);
    expect(find.text('Kết hợp'), findsNothing);
    expect(find.text('Công nợ phát sinh'), findsOneWidget);
    expect(find.text('Tóm tắt đổi/trả'), findsOneWidget);

    // Summary is collapsed by default; the breakdown is hidden until expanded.
    expect(find.byKey(const Key('wgt_sg12_plan_breakdown')), findsNothing);
    await tester.tap(find.byKey(const Key('btn_sg12_plan_toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wgt_sg12_plan_breakdown')), findsOneWidget);
    expect(find.text('+760.000đ'), findsWidgets);
  });

  testWidgets('ready zero difference flow renders clean status card without inputs', (
    tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        SalesReturnExchangeSettlementState(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
          orderNumber: 'DH-000129',
          customerDisplayName: 'Nguyễn Văn An',
          status: SalesReturnExchangeSettlementStatus.ready,
          valuation: _zeroValuation(),
        ),
      ),
    );

    expect(find.text('DH-000129 · Nguyễn Văn An'), findsOneWidget);
    expect(find.text('Không phát sinh chênh lệch'), findsOneWidget);
    expect(find.text('Không cần thu thêm, hoàn tiền hoặc ghi nhận công nợ.'), findsOneWidget);
    expect(find.text('Khách thanh toán ngay'), findsNothing);
    expect(find.text('Hoàn cho khách ngay'), findsNothing);
    expect(find.text('Phương thức thu'), findsNothing);
    expect(find.text('Phương thức hoàn'), findsNothing);
    expect(find.byKey(const Key('txt_sg12_settlement_amount')), findsNothing);
    expect(find.byKey(const Key('seg_sg12_settlement_method')), findsNothing);
    expect(find.text('Tóm tắt đổi/trả'), findsOneWidget);
    expect(find.text('Chênh lệch 0đ'), findsOneWidget);
  });

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
    expect(find.byKey(const Key('wgt_sg12_debt_reduction')), findsOneWidget);
    expect(find.text('Cần hoàn tiền'), findsOneWidget);
    expect(find.text('Phương thức hoàn'), findsNothing);
  });

  testWidgets(
    'E-10 full return of a partially paid order shows server refund and order debt reduction',
    (tester) async {
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
        find.text(
          'Phần khách chưa thanh toán cho hàng trả được trừ khỏi nợ của đơn, không hoàn tiền.',
        ),
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
    },
  );

  testWidgets('outstanding balance follows the edited settle-now amount', (tester) async {
    await tester.pumpWidget(
      _harness(
        SalesReturnExchangeSettlementState(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
          status: SalesReturnExchangeSettlementStatus.ready,
          valuation: _collectValuation(),
        ),
      ),
    );

    // Prefilled with the full collectable amount → no outstanding debt.
    expect(find.text('Công nợ phát sinh'), findsOneWidget);
    expect(find.text('0đ'), findsWidgets);

    // Customer settles only part of it → outstanding debt updates live.
    await tester.enterText(
      find.byKey(const Key('txt_sg12_settlement_amount')),
      '600.000',
    );
    await tester.pump();

    expect(find.text('160.000đ'), findsWidgets);
  });

  testWidgets('due-date field appears only when a shortfall exists', (tester) async {
    DateTime? capturedDue;
    await tester.pumpWidget(
      _harness(
        SalesReturnExchangeSettlementState(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
          status: SalesReturnExchangeSettlementStatus.ready,
          valuation: _collectValuation(),
        ),
        onDueDateChanged: (value) => capturedDue = value,
      ),
    );

    // Prefilled with full amount → no debt → no due-date field.
    expect(find.byKey(const Key('fld_sg12_due_date')), findsNothing);
    expect(find.text('Ngày hẹn thanh toán'), findsNothing);

    // Partial payment creates a shortfall → due-date field is required.
    await tester.enterText(
      find.byKey(const Key('txt_sg12_settlement_amount')),
      '600.000',
    );
    await tester.pump();

    expect(find.byKey(const Key('fld_sg12_due_date')), findsOneWidget);
    expect(find.text('Ngày hẹn thanh toán'), findsOneWidget);
    expect(find.text('*'), findsOneWidget);
    expect(capturedDue, isNull);
  });

  testWidgets('walk-in collect locks settle-now amount at full and hides due date', (tester) async {
    await tester.pumpWidget(
      _harness(
        SalesReturnExchangeSettlementState(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
          status: SalesReturnExchangeSettlementStatus.ready,
          valuation: _collectValuation(),
          isWalkIn: true,
        ),
      ),
    );

    final field = tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const Key('txt_sg12_settlement_amount')),
        matching: find.byType(TextField),
      ),
    );
    expect(field.enabled, isFalse);
    expect(find.text('Thu đủ, không phát sinh công nợ.'), findsOneWidget);
    expect(find.byKey(const Key('fld_sg12_due_date')), findsNothing);
  });

  testWidgets('settle-now amount regroups thousands after deleting a digit', (tester) async {
    await tester.pumpWidget(
      _harness(
        SalesReturnExchangeSettlementState(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
          status: SalesReturnExchangeSettlementStatus.ready,
          valuation: _collectValuation(),
        ),
      ),
    );

    final field = find.descendant(
      of: find.byKey(const Key('txt_sg12_settlement_amount')),
      matching: find.byType(TextField),
    );
    final initial = tester.widget<TextField>(field).controller!.text;
    await tester.enterText(field, initial.substring(0, initial.length - 1));
    await tester.pump();

    final expected = MoneyFormatter.formatMinorPlain(
      MoneyFormatter.parseMinor(initial) ~/ 10,
    );
    expect(tester.widget<TextField>(field).controller!.text, expected);
  });

  testWidgets('identified customer collect shows no walk-in helper line', (tester) async {
    await tester.pumpWidget(
      _harness(
        SalesReturnExchangeSettlementState(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
          status: SalesReturnExchangeSettlementStatus.ready,
          valuation: _collectValuation(),
        ),
      ),
    );

    expect(find.text('Thu đủ, không phát sinh công nợ.'), findsNothing);
  });

  group('canConfirm gating on payment due date', () {
    SalesReturnExchangeSettlementState ready({
      int? settledNowMinor,
      DateTime? paymentDueDate,
    }) {
      return SalesReturnExchangeSettlementState(
        orderId: 'order-1',
        returnExchangeId: 'return-1',
        status: SalesReturnExchangeSettlementStatus.ready,
        valuation: _collectValuation(),
        settledNowMinor: settledNowMinor,
        paymentDueDate: paymentDueDate,
      );
    }

    test('full payment needs no due date', () {
      expect(ready().canConfirm, isTrue);
      expect(ready().requiresPaymentDueDate, isFalse);
    });

    test('shortfall without due date blocks confirmation', () {
      final state = ready(settledNowMinor: 600000);
      expect(state.requiresPaymentDueDate, isTrue);
      expect(state.outstandingCollectMinor, 160000);
      expect(state.canConfirm, isFalse);
    });

    test('shortfall with due date allows confirmation', () {
      final state = ready(
        settledNowMinor: 600000,
        paymentDueDate: DateTime(2026, 7, 30),
      );
      expect(state.canConfirm, isTrue);
    });
  });
}

Widget _harness(
  SalesReturnExchangeSettlementState state, {
  ValueChanged<DateTime?>? onDueDateChanged,
}) {
  return MaterialApp(
    theme: VTheme.lightTheme,
    home: Scaffold(
      body: SalesReturnExchangeSettlementBody(
        state: state,
        onRetry: () {},
        onDueDateChanged: onDueDateChanged,
      ),
    ),
  );
}

ReturnExchangeValuationDto _valuation() {
  const plan = ReturnExchangeSettlementPlanDto(
    currencyCode: 'VND',
    netDifferenceMinor: -320000,
    collectAmountMinor: 0,
    refundAmountMinor: 320000,
    receivableCreateAmountMinor: 0,
    receivableReverseAmountMinor: 0,
    processedCollectMinor: 0,
    processedRefundMinor: 0,
    pendingReceivableCreateMinor: 0,
    pendingReceivableReverseMinor: 0,
    remainderCollectMinor: 0,
    remainderRefundMinor: 320000,
    sourceOrderVersion: 1,
    sourceSettlementVersion: 1,
  );
  return const ReturnExchangeValuationDto(
    returnValue: MoneyDto(amountMinor: 320000, currencyCode: 'VND'),
    exchangeValue: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    settlementDifference: MoneyDto(amountMinor: -320000, currencyCode: 'VND'),
    settlementPlan: plan,
    sourceOrderVersion: 1,
  );
}

ReturnExchangeValuationDto _collectValuation() {
  const plan = ReturnExchangeSettlementPlanDto(
    currencyCode: 'VND',
    netDifferenceMinor: 760000,
    collectAmountMinor: 760000,
    refundAmountMinor: 0,
    receivableCreateAmountMinor: 0,
    receivableReverseAmountMinor: 0,
    processedCollectMinor: 0,
    processedRefundMinor: 0,
    pendingReceivableCreateMinor: 0,
    pendingReceivableReverseMinor: 0,
    remainderCollectMinor: 760000,
    remainderRefundMinor: 0,
    sourceOrderVersion: 1,
    sourceSettlementVersion: 1,
  );
  return const ReturnExchangeValuationDto(
    returnValue: MoneyDto(amountMinor: 320000, currencyCode: 'VND'),
    exchangeValue: MoneyDto(amountMinor: 1080000, currencyCode: 'VND'),
    settlementDifference: MoneyDto(amountMinor: 760000, currencyCode: 'VND'),
    settlementPlan: plan,
    sourceOrderVersion: 1,
  );
}

ReturnExchangeValuationDto _zeroValuation() {
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
  return const ReturnExchangeValuationDto(
    returnValue: MoneyDto(amountMinor: 320000, currencyCode: 'VND'),
    exchangeValue: MoneyDto(amountMinor: 320000, currencyCode: 'VND'),
    settlementDifference: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    settlementPlan: plan,
    sourceOrderVersion: 1,
  );
}

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
