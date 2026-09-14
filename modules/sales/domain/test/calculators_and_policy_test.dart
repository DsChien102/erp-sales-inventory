import 'package:test/test.dart';
import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_sales_domain/enums.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

void main() {
  group('OrderTotalsCalculator', () {
    const calculator = OrderTotalsCalculator();

    test('balances line totals minus discount plus tax and rounding', () {
      final summary = calculator.calculate(
        lineTotals: [
          Money(amountMinor: 100000, currencyCode: 'VND'),
          Money(amountMinor: 50000, currencyCode: 'VND'),
        ],
        discountTotal: Money(amountMinor: 10000, currencyCode: 'VND'),
        taxTotal: Money(amountMinor: 5000, currencyCode: 'VND'),
        rounding: Money(amountMinor: 0, currencyCode: 'VND'),
      );

      expect(summary.subtotal.amountMinor, 150000);
      expect(summary.grandTotal.amountMinor, 145000);
      expect(calculator.balances(summary), isTrue);
    });
  });

  group('SettlementSummaryCalculator', () {
    const calculator = SettlementSummaryCalculator();

    test('marks unpaid and partially paid', () {
      final unpaid = calculator.calculate(
        orderGrandTotal: Money(amountMinor: 100, currencyCode: 'VND'),
        confirmedCollected: Money.zero('VND'),
        confirmedRefunded: Money.zero('VND'),
      );
      expect(unpaid.status, SalesSettlementStatus.unpaid);

      final partial = calculator.calculate(
        orderGrandTotal: Money(amountMinor: 100, currencyCode: 'VND'),
        confirmedCollected: Money(amountMinor: 40, currencyCode: 'VND'),
        confirmedRefunded: Money.zero('VND'),
      );
      expect(partial.status, SalesSettlementStatus.partiallyPaid);
      expect(partial.outstanding.amountMinor, 60);
    });
  });

  group('ReturnExchangeValuationCalculator', () {
    const calculator = ReturnExchangeValuationCalculator();

    test('computes signed net difference', () {
      final valuation = calculator.calculate(
        returnedTotal: Money(amountMinor: 100, currencyCode: 'VND'),
        exchangeTotal: Money(amountMinor: 40, currencyCode: 'VND'),
      );
      expect(valuation.netDifferenceMinor, -60);
      expect(valuation.customerReceivesRefund, isTrue);
    });
  });

  group('SalesOrderEditPolicy', () {
    const policy = SalesOrderEditPolicy();

    test('normalizes and detects no-op notes', () {
      expect(policy.normalizeNote('  '), isNull);
      expect(
        policy.isNoOp(currentNote: 'hello', nextNote: ' hello '),
        isTrue,
      );
      expect(
        policy.canUpdateOrderNote(
          lifecycleStatus: SalesOrderLifecycleStatus.cancelled,
        ),
        isFalse,
      );
    });
  });
}
