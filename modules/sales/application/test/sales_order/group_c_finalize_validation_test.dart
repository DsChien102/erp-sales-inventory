import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';

// Handler-level finalize behavior (blocked/ready/gateway delegation) is covered
// by group_d_finalize_checkout_commit_test.dart; this file focuses on the
// FinalizeSalesOrderCommandValidator contract only.
void main() {
  group('TH-05 Group C finalize validation hook', () {
    test('S09 accepts cash payment intent that covers the amount due', () async {
      final validator = FinalizeSalesOrderCommandValidator();

      await validator.validate(_command(paymentMinor: 1000000));
    });

    test('S09 accepts manual bank transfer payment intent with reference', () async {
      final validator = FinalizeSalesOrderCommandValidator();

      await validator.validate(
        _command(
          paymentIntents: const <PaymentIntentInput>[
            PaymentIntentInput(
              method: SalesPaymentMethod.manualBankTransfer,
              amount: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
              reference: 'BANK-001',
            ),
          ],
        ),
      );
    });

    test('S09 rejects zero or negative payment intent amount', () async {
      final validator = FinalizeSalesOrderCommandValidator();

      expect(
        () => validator.validate(_command(paymentMinor: 0)),
        throwsA(
          isA<SalesContractException>().having(
            (error) => error.code,
            'code',
            'CONTEXT_INVALID',
          ),
        ),
      );
    });
  });
}

FinalizeSalesOrderCommand _command({
  int paymentMinor = 1000000,
  List<PaymentIntentInput>? paymentIntents,
}) {
  return FinalizeSalesOrderCommand(
    id: 'cmd-1',
    tenantId: 'tenant-1',
    actorId: 'actor-1',
    storeId: 'store-1',
    customerId: 'customer-1',
    currencyCode: 'VND',
    lines: const <CheckoutLineInput>[
      CheckoutLineInput(
        productId: 'product-1',
        productUnitId: 'unit-1',
        quantity: QuantityDto(quantityMicros: QuantityDto.scale),
        unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
      ),
    ],
    paymentIntents:
        paymentIntents ??
        <PaymentIntentInput>[
          PaymentIntentInput(
            method: SalesPaymentMethod.cash,
            amount: MoneyDto(amountMinor: paymentMinor, currencyCode: 'VND'),
          ),
        ],
    commercialSnapshot: _commercialSnapshot(),
    idempotencyKey: 'idem-1',
    payloadHash: 'hash-1',
    correlationId: 'corr-1',
  );
}

SalesCommercialSnapshotInput _commercialSnapshot() => SalesCommercialSnapshotInput(
  store: const StoreSnapshotDto(
    storeId: 'store-1',
    storeCode: 'HCM-01',
    displayName: 'Chi nhánh Quận 1',
  ),
  seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh Anh'),
  customer: const CustomerSnapshotDto(
    customerId: 'customer-1',
    displayName: 'Nguyễn Văn An',
  ),
  lines: const [
    SalesReceiptLineDto(
      lineId: 'line-1',
      product: ProductSnapshotDto(
        productId: 'product-1',
        sku: null,
        displayName: 'Vaccine A',
      ),
      unit: ProductUnitSnapshotDto(
        productUnitId: 'unit-1',
        unitCode: null,
        unitName: 'Lọ',
      ),
      quantity: QuantityDto(quantityMicros: QuantityDto.scale),
      unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
      discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      lineTotal: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
    ),
  ],
);
