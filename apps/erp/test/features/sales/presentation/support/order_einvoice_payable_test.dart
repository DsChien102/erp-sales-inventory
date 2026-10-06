import 'package:erp/features/sales/presentation/support/order_einvoice_payable.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps the original total when the order has no return', () {
    expect(
      OrderEInvoicePayable.minor(originalTotalMinor: 1000000),
      1000000,
    );
  });

  test('uses the settlement total after a return or exchange', () {
    expect(
      OrderEInvoicePayable.minor(
        originalTotalMinor: 1000000,
        currentPayableMinor: 800000,
        hasReturnOrExchange: true,
      ),
      800000,
    );
  });

  test('uses remaining holdings when settlement has not loaded', () {
    expect(
      OrderEInvoicePayable.minor(
        originalTotalMinor: 1000000,
        currentHoldingTotals: const [500000, 300000],
        hasReturnOrExchange: true,
      ),
      800000,
    );
  });

  test('keeps the original total while settlement is still loading', () {
    expect(
      OrderEInvoicePayable.minor(
        originalTotalMinor: 1000000,
        currentHoldingTotals: const [800000],
      ),
      1000000,
    );
  });
}
