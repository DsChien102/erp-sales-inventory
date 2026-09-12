import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_design_system/design_system.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    expect(find.text('QR cửa hàng · ACB'), findsOneWidget);
    expect(find.text('Công nợ phát sinh'), findsOneWidget);
    expect(find.text('Tóm tắt đổi/trả'), findsOneWidget);

    // Summary is collapsed by default; the breakdown is hidden until expanded.
    expect(find.byKey(const Key('wgt_sg12_plan_breakdown')), findsNothing);
    await tester.tap(find.byKey(const Key('btn_sg12_plan_toggle')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('wgt_sg12_plan_breakdown')), findsOneWidget);
    expect(find.text('+760.000đ'), findsWidgets);
  });

  testWidgets('ready zero difference flow renders clean status card without inputs', (tester) async {
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

  testWidgets('ready refund with debt offset flow renders switch and expandable debt card', (tester) async {
    bool? capturedOffset;
    await tester.pumpWidget(
      _harness(
        SalesReturnExchangeSettlementState(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
          orderNumber: 'DH-000129',
          customerDisplayName: 'Nguyễn Văn An',
          status: SalesReturnExchangeSettlementStatus.ready,
          valuation: _debtValuation(),
          offsetDebt: true,
        ),
        onOffsetDebtChanged: (val) => capturedOffset = val,
      ),
    );

    expect(find.text('DH-000129 · Nguyễn Văn An'), findsOneWidget);
    expect(find.text('Hoàn tiền trước xử lý'), findsOneWidget);
    expect(find.text('2.350.000đ'), findsWidgets);
    expect(find.text('Cấn trừ công nợ hiện tại'), findsOneWidget);
    expect(find.byKey(const Key('sw_sg12_offset_debt')), findsOneWidget);
    expect(find.byKey(const Key('wgt_sg12_debt_card')), findsOneWidget);
    expect(find.text('Công nợ sau cấn trừ'), findsOneWidget);
    expect(find.text('1.200.000đ → 0đ'), findsOneWidget);
    expect(find.text('Còn phải hoàn'), findsOneWidget);
    expect(find.text('1.150.000đ'), findsOneWidget); // 2.350.000 - 1.200.000 = 1.150.000

    // Expand debt card breakdown
    expect(find.text('Công nợ trước cấn trừ'), findsNothing);
    await tester.tap(find.byKey(const Key('btn_sg12_debt_toggle')));
    await tester.pumpAndSettle();
    expect(find.text('Công nợ trước cấn trừ'), findsOneWidget);
    expect(find.text('Cấn trừ từ phiếu đổi/trả'), findsOneWidget);
    expect(find.text('-1.200.000đ'), findsOneWidget);
    expect(find.text('0đ'), findsWidgets);

    // Toggle switch OFF -> updates subtitle and refund amount
    await tester.tap(find.byKey(const Key('sw_sg12_offset_debt')));
    await tester.pumpAndSettle();
    expect(capturedOffset, isFalse);
    expect(find.text('1.200.000đ · Giữ nguyên'), findsOneWidget);
    expect(find.text('2.350.000đ'), findsWidgets);
  });

  testWidgets('ready refund with full debt offset hides payment method and shows remaining debt', (tester) async {
    await tester.pumpWidget(
      _harness(
        SalesReturnExchangeSettlementState(
          orderId: 'order-1',
          returnExchangeId: 'return-1',
          orderNumber: 'DH-000129',
          customerDisplayName: 'Nguyễn Văn An',
          status: SalesReturnExchangeSettlementStatus.ready,
          valuation: _fullDebtOffsetValuation(),
          offsetDebt: true,
        ),
      ),
    );

    expect(find.text('Hoàn tiền trước xử lý'), findsOneWidget);
    expect(find.text('900.000đ'), findsOneWidget);
    expect(find.text('Cấn trừ công nợ hiện tại'), findsOneWidget);
    expect(find.text('Công nợ sau cấn trừ'), findsOneWidget);
    expect(find.text('1.200.000đ → 300.000đ'), findsOneWidget);
    expect(find.text('Còn phải hoàn'), findsOneWidget);
    expect(find.text('0đ'), findsWidgets);
    expect(find.text('Phương thức hoàn'), findsNothing);
    expect(find.byKey(const Key('seg_sg12_settlement_method')), findsNothing);
  });

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
  ValueChanged<bool>? onOffsetDebtChanged,
}) {
  return MaterialApp(
    theme: VTheme.lightTheme,
    home: Scaffold(
      body: SalesReturnExchangeSettlementBody(
        state: state,
        onRetry: () {},
        onDueDateChanged: onDueDateChanged,
        onOffsetDebtChanged: onOffsetDebtChanged,
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

ReturnExchangeValuationDto _debtValuation() {
  const plan = ReturnExchangeSettlementPlanDto(
    currencyCode: 'VND',
    netDifferenceMinor: -2350000,
    collectAmountMinor: 0,
    refundAmountMinor: 2350000,
    receivableCreateAmountMinor: 0,
    receivableReverseAmountMinor: 1200000,
    processedCollectMinor: 0,
    processedRefundMinor: 0,
    pendingReceivableCreateMinor: 0,
    pendingReceivableReverseMinor: 1200000,
    remainderCollectMinor: 0,
    remainderRefundMinor: 2350000,
    sourceOrderVersion: 1,
    sourceSettlementVersion: 1,
  );
  return const ReturnExchangeValuationDto(
    returnValue: MoneyDto(amountMinor: 2350000, currencyCode: 'VND'),
    exchangeValue: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    settlementDifference: MoneyDto(amountMinor: -2350000, currencyCode: 'VND'),
    settlementPlan: plan,
    sourceOrderVersion: 1,
  );
}

ReturnExchangeValuationDto _fullDebtOffsetValuation() {
  const plan = ReturnExchangeSettlementPlanDto(
    currencyCode: 'VND',
    netDifferenceMinor: -900000,
    collectAmountMinor: 0,
    refundAmountMinor: 900000,
    receivableCreateAmountMinor: 0,
    receivableReverseAmountMinor: 1200000,
    processedCollectMinor: 0,
    processedRefundMinor: 0,
    pendingReceivableCreateMinor: 0,
    pendingReceivableReverseMinor: 1200000,
    remainderCollectMinor: 0,
    remainderRefundMinor: 900000,
    sourceOrderVersion: 1,
    sourceSettlementVersion: 1,
  );
  return const ReturnExchangeValuationDto(
    returnValue: MoneyDto(amountMinor: 900000, currencyCode: 'VND'),
    exchangeValue: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    settlementDifference: MoneyDto(amountMinor: -900000, currencyCode: 'VND'),
    settlementPlan: plan,
    sourceOrderVersion: 1,
  );
}


