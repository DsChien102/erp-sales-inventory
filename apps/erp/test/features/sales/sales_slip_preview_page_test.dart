import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';
import 'package:erp/features/sales/data/models.dart';
import 'package:erp/features/sales/presentation.dart';

void main() {
  group('SalesSlipPreviewPage', () {
    testWidgets('renders PdfPreview from authoritative detail VM', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SalesSlipPreviewPage(
            detail: _detail(),
            orderNumber: 'SO-1',
            customerDisplayName: 'Khách A',
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('wgt_sg13_slip_preview_page')), findsOneWidget);
      expect(find.byType(PdfPreview), findsOneWidget);
      expect(find.byKey(const Key('btn_preview_options')), findsOneWidget);
      expect(find.text('Phiếu đổi/trả'), findsWidgets);
      expect(find.text('PDT-20260722-0018'), findsNothing);
    });
  });
}

SalesReturnExchangeDetailVm _detail() {
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
    sourceOrderVersion: 7,
    sourceSettlementVersion: 3,
  );
  return SalesReturnExchangeDetailVm(
    returnExchangeId: 'return-1',
    salesOrderId: 'order-1',
    referenceNumber: 'RE-1',
    status: ReturnExchangeStatus.completed,
    version: 2,
    confirmedAt: DateTime.utc(2026, 8, 13, 10),
    lines: const [],
    valuation: const ReturnExchangeValuationDto(
      returnValue: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      exchangeValue: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      settlementDifference: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      settlementPlan: plan,
      sourceOrderVersion: 7,
    ),
    settlementPlan: plan,
    completionReady: false,
  );
}
