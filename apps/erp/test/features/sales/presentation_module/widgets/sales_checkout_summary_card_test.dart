import 'package:erp/features/sales/presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:c45_design_system/design_system.dart';

void main() {
  group('KI-07: Sales checkout summary card and payment debt page', () {
    testWidgets('summary_card_has_no_debt_badge', (tester) async {
      const vm = SalesCheckoutVm(
        runtimeDraftId: 'draft-1',
        customerName: 'Nguyễn Văn A',
        customerPhone: '0901234567',
        isWalkIn: false,
        provisionalTotalAmountMinor: 500000,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: const Scaffold(
            body: SalesCheckoutSummaryCard(vm: vm),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Nguyễn Văn A'), findsOneWidget);
      expect(find.textContaining('Nợ cũ'), findsNothing);
      expect(find.byKey(const Key('txt_sg05_customer_debt')), findsNothing);
    });

    testWidgets('payment_debt_page_has_no_view_debt_card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: VTheme.lightTheme,
          home: Scaffold(
            body: SalesOrderPaymentDebtPage(
              orderNumber: 'SO-2026-00125',
              customerName: 'Đại lý An Bình',
              payment: _paymentVm(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Xem công nợ'), findsNothing);
      expect(find.byKey(const Key('btn_sg08_view_receivable')), findsNothing);
    });
  });
}

SalesOrderPaymentVm _paymentVm() {
  return const SalesOrderPaymentVm(
    orderTotalMinor: 1000000,
    paidTotalMinor: 1000000,
    paidCashAmountMinor: 1000000,
    paidBankAmountMinor: 0,
    outstandingMinor: 0,
    settlementStatus: SalesSettlementStatus.fullyPaid,
    transactions: [],
    hasMoreTransactions: false,
    returnSlipBreakdowns: [],
  );
}
