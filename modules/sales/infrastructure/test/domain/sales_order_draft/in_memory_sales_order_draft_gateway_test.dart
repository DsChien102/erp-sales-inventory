import 'package:test/test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:vet45_sales_infrastructure/src/domain/sales_order_draft/in_memory_sales_order_draft_gateway.dart';

void main() {
  group('InMemorySalesOrderDraftGateway', () {
    test('saves draft idempotently and lists only active drafts', () async {
      final gateway = InMemorySalesOrderDraftGateway(clock: () => DateTime.utc(2026, 8, 6, 1));
      final command = _saveCommand(idempotencyKey: 'idem-1');

      final first = await gateway.save(command);
      final retry = await gateway.save(command);
      final page = await gateway.list(
        ListSalesOrderDraftsQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          storeId: 'store-1',
        ),
      );

      expect(first.draftId, retry.draftId);
      expect(first.version, 1);
      expect(page.page.items.single.draftId, first.draftId);
    });

    test('updates active draft with expected version', () async {
      final gateway = InMemorySalesOrderDraftGateway();
      final saved = await gateway.save(_saveCommand(idempotencyKey: 'idem-1'));

      final updated = await gateway.update(
        UpdateSalesOrderDraftCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          draftId: saved.draftId,
          storeId: 'store-1',
          currencyCode: 'VND',
          lines: [
            _lineInput(
              productId: 'product-2',
              productUnitId: 'unit-2',
              quantityMicros: 2 * QuantityDto.scale,
            ),
          ],
          idempotencyKey: 'idem-2',
          expectedVersion: 1,
        ),
      );

      expect(updated.version, 2);
      expect(updated.lines.single.productId, 'product-2');
    });

    test('rejects stale expected version without mutating draft', () async {
      final gateway = InMemorySalesOrderDraftGateway();
      final saved = await gateway.save(_saveCommand(idempotencyKey: 'idem-1'));

      expect(
        () => gateway.update(
          UpdateSalesOrderDraftCommand(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            draftId: saved.draftId,
            storeId: 'store-1',
            currencyCode: 'VND',
            lines: [
              _lineInput(
                productId: 'product-2',
                productUnitId: 'unit-2',
              ),
            ],
            idempotencyKey: 'idem-2',
            expectedVersion: 99,
          ),
        ),
        throwsA(isA<SalesContractException>()),
      );
      expect(
        (await gateway.getForRestore(
          GetSalesOrderDraftForRestoreQuery(
            tenantId: 'tenant-1',
            actorId: 'actor-1',
            draftId: saved.draftId,
            storeId: 'store-1',
          ),
        )).draft.version,
        1,
      );
    });

    test('cancels active draft and hides it from active list', () async {
      final gateway = InMemorySalesOrderDraftGateway();
      final saved = await gateway.save(_saveCommand(idempotencyKey: 'idem-1'));

      final cancelled = await gateway.cancel(
        CancelSalesOrderDraftCommand(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          draftId: saved.draftId,
          storeId: 'store-1',
          idempotencyKey: 'idem-3',
          expectedVersion: 1,
        ),
      );
      final page = await gateway.list(
        ListSalesOrderDraftsQuery(
          tenantId: 'tenant-1',
          actorId: 'actor-1',
          storeId: 'store-1',
        ),
      );

      expect(cancelled.status, SalesDraftStatus.cancelled);
      expect(page.page.items, isEmpty);
    });
  });
}

SaveSalesOrderDraftCommand _saveCommand({required String idempotencyKey}) {
  return SaveSalesOrderDraftCommand(
    tenantId: 'tenant-1',
    actorId: 'actor-1',
    storeId: 'store-1',
    customer: const CustomerSnapshotDto(
      customerId: 'customer-1',
      displayName: 'Customer 1',
    ),
    currencyCode: 'VND',
    lines: [
      _lineInput(
        productId: 'product-1',
        productUnitId: 'unit-1',
      ),
    ],
    idempotencyKey: idempotencyKey,
  );
}

SalesOrderDraftLineInput _lineInput({
  required String productId,
  required String productUnitId,
  int quantityMicros = QuantityDto.scale,
}) {
  return SalesOrderDraftLineInput(
    productId: productId,
    productSku: productId,
    productName: productId,
    productUnitId: productUnitId,
    unitCode: productUnitId,
    unitName: productUnitId,
    quantity: QuantityDto(quantityMicros: quantityMicros),
    appliedUnitPrice: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
    lineTotal: const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
  );
}
