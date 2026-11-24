import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:erp/features/sales/presentation.dart';

void main() {
  group('SalesReturnConfirmSettlementSheet', () {
    const refundVm = SalesReturnExchangeSettlementVm(
      returnExchangeId: 'return-1',
      currencyCode: 'VND',
      netDifferenceMinor: 400000,
      storeRefundMinor: 400000,
      customerCollectMinor: 0,
      receivableCreateMinor: 0,
      receivableReverseMinor: 0,
      sourceOrderVersion: 7,
      sourceSettlementVersion: 3,
    );

    const collectVm = SalesReturnExchangeSettlementVm(
      returnExchangeId: 'return-1',
      currencyCode: 'VND',
      netDifferenceMinor: -250000,
      storeRefundMinor: 0,
      customerCollectMinor: 150000,
      receivableCreateMinor: 104762,
      receivableReverseMinor: 0,
      sourceOrderVersion: 7,
      sourceSettlementVersion: 3,
    );

    const zeroVm = SalesReturnExchangeSettlementVm(
      returnExchangeId: 'return-1',
      currencyCode: 'VND',
      netDifferenceMinor: 0,
      storeRefundMinor: 0,
      customerCollectMinor: 0,
      receivableCreateMinor: 0,
      receivableReverseMinor: 0,
      sourceOrderVersion: 7,
      sourceSettlementVersion: 3,
    );

    test('buildReturnConfirmationMessage uses plan amounts only', () {
      expect(
        buildReturnConfirmationMessage(collectVm),
        'Thu thêm 150.000đ từ khách và ghi nhận công nợ 104.762đ.',
      );
      expect(
        buildReturnConfirmationMessage(refundVm),
        'Hoàn 400.000đ cho khách.',
      );
      expect(
        buildReturnConfirmationMessage(zeroVm),
        'Xác nhận đổi/trả hàng không phát sinh chênh lệch.',
      );
    });

    testWidgets('renders title, dynamic message and action buttons', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await showSalesReturnConfirmSettlementSheet(
                    context,
                    vm: collectVm,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Xác nhận đổi/trả?'), findsOneWidget);
      expect(
        find.text('Thu thêm 150.000đ từ khách và ghi nhận công nợ 104.762đ.'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('btn_confirm_settlement_submit')));
      await tester.pumpAndSettle();

      expect(result, true);
    });
  });
}
