import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';

void main() {
  const plan = ReturnExchangeSettlementPlanDto(
    currencyCode: 'VND',
    netDifferenceMinor: -400000,
    collectAmountMinor: 0,
    refundAmountMinor: 400000,
    receivableCreateAmountMinor: 0,
    receivableReverseAmountMinor: 0,
    processedCollectMinor: 0,
    processedRefundMinor: 0,
    pendingReceivableCreateMinor: 0,
    pendingReceivableReverseMinor: 0,
    remainderCollectMinor: 0,
    remainderRefundMinor: 400000,
    sourceOrderVersion: 7,
    sourceSettlementVersion: 3,
  );

  const refundValuation = ReturnExchangeValuationDto(
    returnValue: MoneyDto(amountMinor: 500000, currencyCode: 'VND'),
    exchangeValue: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
    settlementDifference: MoneyDto(amountMinor: -400000, currencyCode: 'VND'),
    settlementPlan: plan,
    sourceOrderVersion: 7,
  );

  const collectPlan = ReturnExchangeSettlementPlanDto(
    currencyCode: 'VND',
    netDifferenceMinor: 300000,
    collectAmountMinor: 300000,
    refundAmountMinor: 0,
    receivableCreateAmountMinor: 0,
    receivableReverseAmountMinor: 0,
    processedCollectMinor: 0,
    processedRefundMinor: 0,
    pendingReceivableCreateMinor: 0,
    pendingReceivableReverseMinor: 0,
    remainderCollectMinor: 300000,
    remainderRefundMinor: 0,
    sourceOrderVersion: 7,
    sourceSettlementVersion: 3,
  );

  const collectValuation = ReturnExchangeValuationDto(
    returnValue: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
    exchangeValue: MoneyDto(amountMinor: 400000, currencyCode: 'VND'),
    settlementDifference: MoneyDto(amountMinor: 300000, currencyCode: 'VND'),
    settlementPlan: collectPlan,
    sourceOrderVersion: 7,
  );

  test('maps settlement sign convention from backend plan amounts', () {
    expect(
      SalesReturnExchangeMapper.toSettlementVm(
        returnExchangeId: 'return-1',
        valuation: refundValuation,
      ).storeRefundMinor,
      400000,
    );
    expect(
      SalesReturnExchangeMapper.toSettlementVm(
        returnExchangeId: 'return-1',
        valuation: refundValuation,
      ).customerCollectMinor,
      0,
    );
    expect(
      SalesReturnExchangeMapper.toSettlementVm(
        returnExchangeId: 'return-1',
        valuation: collectValuation,
      ).customerCollectMinor,
      300000,
    );
    expect(
      SalesReturnExchangeMapper.toSettlementVm(
        returnExchangeId: 'return-1',
        valuation: collectValuation,
      ).storeRefundMinor,
      0,
    );
  });

  test('maps detail without inventing business literals', () {
    final detail = ReturnExchangeDetailDto(
      result: const ReturnExchangeResultDto(
        returnExchangeId: 'return-1',
        salesOrderId: 'order-1',
        version: 3,
        status: ReturnExchangeStatus.draft,
      ),
      referenceNumber: 'RE-1',
      entrySource: ReturnExchangeEntrySource.standard,
      createdAt: DateTime.utc(2026, 8, 13),
      confirmedByActorId: null,
      confirmedAt: null,
      completedAt: null,
      lines: const <ReturnExchangeDetailLineDto>[],
      valuation: refundValuation,
      settlementPlan: plan,
      completionReady: false,
    );

    final vm = SalesReturnExchangeMapper.toDetailVm(detail);
    expect(vm.referenceNumber, 'RE-1');
    expect(vm.confirmedAt, isNull);
    expect(vm.completionReady, isFalse);
    expect(vm.settlementPlan.refundAmountMinor, 400000);
  });
}
