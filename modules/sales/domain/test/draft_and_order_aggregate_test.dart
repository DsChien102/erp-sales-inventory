import 'package:test/test.dart';
import 'package:vet45_sales_domain/domain.dart';
import 'package:vet45_sales_domain/enums.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

SalesOrderDraftLine _line({int qtyMicros = 1000000, int lineTotal = 10000}) {
  return SalesOrderDraftLine(
    id: SalesOrderDraftLineId('line-1'),
    product: ProductRefSnapshot(
      productId: 'p1',
      sku: 'SKU-1',
      name: 'Product',
    ),
    unit: ProductUnitRefSnapshot(
      unitId: 'u1',
      unitCode: 'CAI',
      unitName: 'Cái',
    ),
    quantity: Quantity(quantityMicros: qtyMicros),
    unitPrice: Money(amountMinor: lineTotal, currencyCode: 'VND'),
    lineTotal: Money(amountMinor: lineTotal, currencyCode: 'VND'),
  );
}

void main() {
  group('SalesOrderDraft', () {
    test('save emits saved event and rejects empty lines', () {
      final draft = SalesOrderDraft.save(
        tenantId: const TenantId('t1'),
        storeId: 'store-1',
        currencyCode: 'vnd',
        lines: [_line()],
      );
      expect(draft.status, SalesDraftStatus.active);
      expect(draft.domainEvents!.first, isA<SalesOrderDraftSavedEvent>());

      expect(
        () => SalesOrderDraft.save(
          tenantId: const TenantId('t1'),
          storeId: 'store-1',
          currencyCode: 'VND',
          lines: const [],
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });

    test('cancel blocks further updates', () {
      final draft = SalesOrderDraft.save(
        tenantId: const TenantId('t1'),
        storeId: 'store-1',
        currencyCode: 'VND',
        lines: [_line()],
      );
      draft.cancel(expectedVersion: 1);
      expect(draft.status, SalesDraftStatus.cancelled);
      expect(
        () => draft.update(
          lines: [_line()],
          expectedVersion: 2,
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });

  group('SalesOrder', () {
    test('finalize requires balanced summary and emits event', () {
      final summary = MonetarySummary(
        subtotal: Money(amountMinor: 10000, currencyCode: 'VND'),
        discountTotal: Money.zero('VND'),
        taxTotal: Money.zero('VND'),
        rounding: Money.zero('VND'),
        grandTotal: Money(amountMinor: 10000, currencyCode: 'VND'),
      );
      final order = SalesOrder.finalize(
        tenantId: const TenantId('t1'),
        storeId: 'store-1',
        currencyCode: 'VND',
        lines: [
          SalesOrderLine(
            id: const SalesOrderLineId('ol-1'),
            product: ProductRefSnapshot(
              productId: 'p1',
              sku: 'SKU',
              name: 'P',
            ),
            unit: ProductUnitRefSnapshot(
              unitId: 'u1',
              unitCode: 'CAI',
              unitName: 'Cái',
            ),
            quantity: Quantity(quantityMicros: Quantity.scale),
            unitPrice: Money(amountMinor: 10000, currencyCode: 'VND'),
            lineTotal: Money(amountMinor: 10000, currencyCode: 'VND'),
          ),
        ],
        monetarySummary: summary,
      );
      expect(order.lifecycleStatus, SalesOrderLifecycleStatus.completed);
      expect(order.domainEvents!.first, isA<SalesOrderFinalizedEvent>());

      order.lock();
      expect(order.lockStatus, SalesOrderLockStatus.locked);
      order.unlock();
      expect(order.lockStatus, SalesOrderLockStatus.unlocked);
    });

    test('S12 finalizes from a source draft with immutable snapshot', () {
      final order = SalesOrder.finalize(
        id: const SalesOrderId('order-1'),
        tenantId: const TenantId('t1'),
        storeId: 'store-1',
        currencyCode: 'vnd',
        lines: [_orderLine()],
        monetarySummary: _summary(),
        customer: CustomerRefSnapshot(
          customerId: 'c1',
          displayName: 'Customer',
          isWalkIn: false,
        ),
        sourceDraft: SalesOrderDraftRef(
          draftId: 'draft-1',
          draftVersion: 2,
        ),
      );

      expect(order.lifecycleStatus, SalesOrderLifecycleStatus.completed);
      expect(order.currencyCode, 'VND');
      expect(order.sourceDraft?.draftId, 'draft-1');
      expect(order.sourceDraft?.draftVersion, 2);
      expect(
        () => order.lines.add(_orderLine(id: 'ol-2')),
        throwsUnsupportedError,
      );
      expect(order.domainEvents, hasLength(1));
      expect(order.domainEvents!.single, isA<SalesOrderFinalizedEvent>());
    });

    test('rejects unbalanced commercial snapshot', () {
      expect(
        () => SalesOrder.finalize(
          tenantId: const TenantId('t1'),
          storeId: 'store-1',
          currencyCode: 'VND',
          lines: [
            SalesOrderLine(
              id: const SalesOrderLineId('ol-1'),
              product: ProductRefSnapshot(
                productId: 'p1',
                sku: 'SKU',
                name: 'P',
              ),
              unit: ProductUnitRefSnapshot(
                unitId: 'u1',
                unitCode: 'CAI',
                unitName: 'Cái',
              ),
              quantity: Quantity(quantityMicros: Quantity.scale),
              unitPrice: Money(amountMinor: 10000, currencyCode: 'VND'),
              lineTotal: Money(amountMinor: 10000, currencyCode: 'VND'),
            ),
          ],
          monetarySummary: MonetarySummary(
            subtotal: Money(amountMinor: 10000, currencyCode: 'VND'),
            discountTotal: Money.zero('VND'),
            taxTotal: Money.zero('VND'),
            rounding: Money.zero('VND'),
            grandTotal: Money(amountMinor: 9999, currencyCode: 'VND'),
          ),
        ),
        throwsA(isA<BusinessRuleValidationException>()),
      );
    });
  });
}

SalesOrderLine _orderLine({String id = 'ol-1', int lineTotal = 10000}) {
  return SalesOrderLine(
    id: SalesOrderLineId(id),
    product: ProductRefSnapshot(
      productId: 'p1',
      sku: 'SKU',
      name: 'P',
    ),
    unit: ProductUnitRefSnapshot(
      unitId: 'u1',
      unitCode: 'CAI',
      unitName: 'Cái',
    ),
    quantity: Quantity(quantityMicros: Quantity.scale),
    unitPrice: Money(amountMinor: lineTotal, currencyCode: 'VND'),
    lineTotal: Money(amountMinor: lineTotal, currencyCode: 'VND'),
  );
}

MonetarySummary _summary({int grandTotal = 10000}) {
  return MonetarySummary(
    subtotal: Money(amountMinor: 10000, currencyCode: 'VND'),
    discountTotal: Money.zero('VND'),
    taxTotal: Money.zero('VND'),
    rounding: Money.zero('VND'),
    grandTotal: Money(amountMinor: grandTotal, currencyCode: 'VND'),
  );
}
