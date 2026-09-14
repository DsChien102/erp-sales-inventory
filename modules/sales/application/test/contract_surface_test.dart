import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_application/testing.dart';

void main() {
  group('TH-05 public contract surface', () {
    test('binds execution context without changing command identity', () {
      final command = SaveSalesOrderDraftCommand(
        storeId: 'store-1',
        customer: const CustomerSnapshotDto(
          customerId: 'customer-1',
          displayName: 'Nguyen Van A',
        ),
        currencyCode: 'VND',
        orderNote: 'Giao buoi chieu',
        pricingPreviewToken: 'preview-token-1',
        needsRevalidation: false,
        lines: [
          SalesOrderDraftLineInput(
            productId: 'product-1',
            productSku: 'SKU-1',
            productName: 'Thuoc A',
            productUnitId: 'unit-1',
            unitCode: 'BOX',
            unitName: 'Hop',
            quantity: const QuantityDto(quantityMicros: 1000000),
            appliedUnitPrice: const MoneyDto(
              amountMinor: 120000,
              currencyCode: 'VND',
            ),
            lineTotal: const MoneyDto(amountMinor: 115000, currencyCode: 'VND'),
            listUnitPrice: const MoneyDto(
              amountMinor: 130000,
              currencyCode: 'VND',
            ),
            manualDiscountMinor: 5000,
            pricingSourceCode: 'list',
            pricingWarningCodes: const ['PRICE_STALE'],
          ),
        ],
        idempotencyKey: 'draft-1',
        payloadHash: 'hash-1',
      );

      final bound = command.withExecutionContext(
        tenantId: 'tenant-1',
        actorId: 'user-1',
      );

      expect(bound.id, command.id);
      expect(bound.tenantId, 'tenant-1');
      expect(bound.actorId, 'user-1');
      expect(bound.storeId, 'store-1');
      expect(bound.customer?.displayName, 'Nguyen Van A');
      expect(bound.orderNote, 'Giao buoi chieu');
      expect(bound.lines.single.manualDiscountMinor, 5000);
      expect(bound.lines.single.appliedUnitPrice.amountMinor, 120000);
      expect(bound.lines.single.needsRevalidation, isFalse);
    });

    test('models payment intents as checkout input', () {
      final command = FinalizeSalesOrderCommand(
        storeId: 'store-1',
        currencyCode: 'VND',
        lines: const [
          CheckoutLineInput(
            productId: 'product-1',
            productUnitId: 'unit-1',
            quantity: QuantityDto(quantityMicros: 1000000),
          ),
        ],
        paymentIntents: const [
          PaymentIntentInput(
            method: SalesPaymentMethod.cash,
            amount: MoneyDto(amountMinor: 125000, currencyCode: 'VND'),
          ),
        ],
        idempotencyKey: 'checkout-1',
        payloadHash: 'hash-1',
        correlationId: 'correlation-1',
        commercialSnapshot: _commercialSnapshot(),
      );

      expect(command.paymentIntents, hasLength(1));
      expect(command.paymentIntents.single.method, SalesPaymentMethod.cash);
    });

    test('pricing preview from ID-only checkout lines does not invent SKU/unit code', () async {
      final preview = await FakePricingPreviewPort().previewWorkingState(
        tenantId: 'tenant-1',
        workingState: SalesOrderWorkingStateDto(
          store: const StoreSnapshotDto(
            storeId: 'store-1',
            storeCode: 'HCM-01',
            displayName: 'Chi nhánh Quận 1',
          ),
          currencyCode: 'VND',
          customer: null,
          lines: const [
            CheckoutLineInput(
              productId: 'product-1',
              productUnitId: 'unit-1',
              quantity: QuantityDto(quantityMicros: QuantityDto.scale),
            ),
          ],
        ),
      );

      expect(preview.lines.single.product.sku, isNull);
      expect(preview.lines.single.unit.unitCode, isNull);
    });

    test('S12 finalize preserves the original order note through execution context', () {
      final command = FinalizeSalesOrderCommand(
        id: 'attempt-1',
        tenantId: '',
        actorId: '',
        storeId: 'store-1',
        sourceDraftId: 'draft-7',
        customerId: 'customer-2',
        currencyCode: 'VND',
        orderNote: ' Giao sau 17:00 ',
        lines: const <CheckoutLineInput>[
          CheckoutLineInput(
            productId: 'product-1',
            productUnitId: 'unit-1',
            quantity: QuantityDto(quantityMicros: QuantityDto.scale),
            unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
          ),
        ],
        paymentIntents: const <PaymentIntentInput>[],
        idempotencyKey: 'idem-note-1',
        payloadHash: 'hash-note-1',
        correlationId: 'corr-note-1',
        commercialSnapshot: _commercialSnapshot(),
      ).withExecutionContext(tenantId: 'tenant-1', actorId: 'actor-1');

      expect(command.orderNote, ' Giao sau 17:00 ');
      expect(command.sourceDraftId, 'draft-7');
      expect(command.customerId, 'customer-2');
      expect(command.id, 'attempt-1');
      expect(command.commercialSnapshot.store.displayName, 'Chi nhánh Quận 1');
      expect(command.commercialSnapshot.seller.displayName, 'Minh Anh');
      expect(command.commercialSnapshot.lines.single.product.displayName, 'Vaccine A');
      expect(command.commercialSnapshot.customer?.displayName, 'Nguyễn Văn An');
    });

    test('S13 commercial snapshot keeps an immutable captured receipt line', () {
      final snapshot = SalesCommercialSnapshotInput(
        store: const StoreSnapshotDto(
          storeId: 'store-1',
          storeCode: 'HCM-01',
          displayName: 'Chi nhánh Quận 1',
        ),
        seller: const ActorSnapshotDto(actorId: 'actor-1', displayName: 'Minh Anh'),
        customer: null,
        lines: [
          const SalesReceiptLineDto(
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
            unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
            discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
            lineTotal: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
          ),
        ],
      );

      expect(snapshot.customer, isNull);
      expect(snapshot.lines, hasLength(1));
      expect(
        () => snapshot.lines.add(snapshot.lines.single),
        throwsUnsupportedError,
      );
    });

    test('fails clearly for unsupported fake requests', () async {
      final module = FakeSalesModule(
        scenarioId: SalesFakeScenarioRegistry.ids.first,
      );

      expect(
        () => module.executeQueryAsync(
          GetSalesOrderQuery(salesOrderId: 'unsupported'),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}

SalesCommercialSnapshotInput _commercialSnapshot() => SalesCommercialSnapshotInput(
  store: const StoreSnapshotDto(
    storeId: 'store-1',
    storeCode: 'HCM-01',
    displayName: 'Chi nhánh Quận 1',
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
      unitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
      discountTotal: MoneyDto(amountMinor: 0, currencyCode: 'VND'),
      lineTotal: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
    ),
  ],
);
