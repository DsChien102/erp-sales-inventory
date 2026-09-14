import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';

void main() {
  test('creates one canonical idempotent checkout envelope', () {
    final factory = SalesCheckoutAttemptFactory(
      newAttemptId: () => '11111111-1111-4111-8111-111111111111',
    );
    final envelope = factory.create(
      args: _draftArgs(),
      vm: _vm(dueDate: DateTime(2026, 8, 30)),
      tenantId: ' tenant-1 ',
      actorId: ' actor-1 ',
      storeId: ' store-1 ',
      correlationId: 'corr-1',
    );

    expect(envelope.command.id, '11111111-1111-4111-8111-111111111111');
    expect(envelope.command.idempotencyKey, 'checkout:11111111-1111-4111-8111-111111111111');
    expect(envelope.command.sourceDraftId, 'draft-7');
    expect(envelope.command.paymentIntents, hasLength(2));
    expect(envelope.payloadHash, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(envelope.command.payloadHash, envelope.payloadHash);
    expect(envelope.command.orderNote, 'Giao chiều');
    expect(envelope.command.paymentDueDate, DateTime(2026, 8, 30));
    expect(envelope.command.commercialSnapshot.store.displayName, 'Chi nhánh Quận 1');
    expect(envelope.canonicalPayloadJson, contains('commercialSnapshot'));
    expect(envelope.canonicalPayloadJson, contains('"paymentDueDate":"2026-08-30"'));
  });

  test('normalization is deterministic and business changes change hash', () {
    final ids = ['attempt-1', 'attempt-2', 'attempt-3', 'attempt-4', 'attempt-5'].iterator;
    final factory = SalesCheckoutAttemptFactory(
      newAttemptId: () {
        ids.moveNext();
        return ids.current;
      },
    );
    final first = factory.create(
      args: _draftArgs(orderNote: ' Giao chiều '),
      vm: _vm(),
      tenantId: 'tenant-1',
      actorId: 'actor-1',
      storeId: 'store-1',
      correlationId: 'corr-1',
    );
    final normalized = factory.create(
      args: _draftArgs(orderNote: 'Giao chiều'),
      vm: _vm(reference: ' TX-1 '),
      tenantId: 'tenant-1',
      actorId: 'actor-1',
      storeId: 'store-1',
      correlationId: 'corr-2',
    );
    final changed = factory.create(
      args: _draftArgs(),
      vm: _vm(cash: 399999, bank: 600001),
      tenantId: 'tenant-1',
      actorId: 'actor-1',
      storeId: 'store-1',
      correlationId: 'corr-3',
    );

    expect(normalized.payloadHash, first.payloadHash);
    expect(changed.payloadHash, isNot(first.payloadHash));

    final changedDueDate = factory.create(
      args: _draftArgs(),
      vm: _vm(dueDate: DateTime(2026, 8, 30)),
      tenantId: 'tenant-1',
      actorId: 'actor-1',
      storeId: 'store-1',
      correlationId: 'corr-4',
    );
    expect(changedDueDate.payloadHash, isNot(first.payloadHash));

    final changedCommercialSnapshot = factory.create(
      args: _draftArgs(commercialSnapshot: _commercialSnapshot(storeName: 'Chi nhánh Quận 2')),
      vm: _vm(),
      tenantId: 'tenant-1',
      actorId: 'actor-1',
      storeId: 'store-1',
      correlationId: 'corr-4',
    );
    expect(changedCommercialSnapshot.payloadHash, isNot(first.payloadHash));
  });
}

SalesCheckoutDraftArgs _draftArgs({
  String orderNote = ' Giao chiều ',
  SalesCommercialSnapshotInput? commercialSnapshot,
}) => SalesCheckoutDraftArgs(
  runtimeDraftId: 'runtime-7',
  sourceDraftId: 'draft-7',
  customerId: 'customer-2',
  customerDisplayName: 'PK A',
  isWalkIn: false,
  currencyCode: 'vnd',
  orderNote: orderNote,
  expectedSourceVersion: 3,
  provisionalTotalAmountMinor: 1000000,
  commercialSnapshot: commercialSnapshot ?? _commercialSnapshot(),
  lines: const [
    CheckoutLineInput(
      productId: 'product-1',
      productUnitId: 'unit-1',
      quantity: QuantityDto(quantityMicros: QuantityDto.scale),
      unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
    ),
  ],
);

SalesCommercialSnapshotInput _commercialSnapshot({String storeName = 'Chi nhánh Quận 1'}) =>
    SalesCommercialSnapshotInput(
      store: StoreSnapshotDto(
        storeId: 'store-1',
        storeCode: 'HCM-01',
        displayName: storeName,
      ),
      seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh Anh'),
      customer: const CustomerSnapshotDto(
        customerId: 'customer-2',
        displayName: 'Nguyễn Văn An',
      ),
      lines: const [
        SalesReceiptLineDto(
          lineId: 'line-1',
          product: ProductSnapshotDto(
            productId: 'product-1',
            sku: 'SKU-001',
            displayName: 'Vaccine A',
          ),
          unit: ProductUnitSnapshotDto(
            productUnitId: 'unit-1',
            unitCode: 'VIAL',
            unitName: 'Lọ',
          ),
          quantity: QuantityDto(quantityMicros: QuantityDto.scale),
          unitPrice: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
          discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
          lineTotal: MoneyDto(amountMinor: 1000000, currencyCode: 'VND'),
        ),
      ],
    );

SalesCheckoutVm _vm({
  int cash = 400000,
  int bank = 600000,
  String reference = 'TX-1',
  DateTime? dueDate,
}) => SalesCheckoutVm(
  runtimeDraftId: 'runtime-7',
  provisionalTotalAmountMinor: 1000000,
  cashPaidMinor: cash,
  bankPaidMinor: bank,
  paymentMode: SalesPaymentMode.mixed,
  transactionCode: reference,
  dueDate: dueDate,
  note: ' Giao chiều ',
);
