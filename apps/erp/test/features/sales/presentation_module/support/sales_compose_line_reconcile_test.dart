import 'package:flutter_test/flutter_test.dart';
import 'package:vet45_sales_application/application.dart';
import 'package:erp/features/sales/presentation.dart';

import 'compose_line_test_data.dart';

void main() {
  group('reconcileComposeLinesAfterPersist', () {
    test('adopts server line id and persisted amounts', () {
      final local = composeTestLine(
        lineId: 'line-local-1',
        productId: 'product-1',
        productUnitId: 'unit-1',
        productName: 'Thuốc A',
        unitLabel: 'Hộp',
        quantity: 2,
        baseUnitPrice: MoneyDto(amountMinor: 90000, currencyCode: 'VND'),
        appliedUnitPrice: MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
        stockQuantity: 5,
        floorUnitPrice: MoneyDto(amountMinor: 80000, currencyCode: 'VND'),
        pricedLineTotal: MoneyDto(amountMinor: 200000, currencyCode: 'VND'),
        pricedContextVersion: 3,
      );

      final persisted = SalesOrderDraftLineDto(
        lineId: 'server-uuid-1',
        productId: 'product-1',
        productSku: 'SP-1',
        productName: 'Thuốc A',
        productUnitId: 'unit-1',
        unitCode: 'BOX',
        unitName: 'Hộp',
        quantity: const QuantityDto(quantityMicros: 3 * QuantityDto.scale),
        appliedUnitPrice: const MoneyDto(amountMinor: 95000, currencyCode: 'VND'),
        lineTotal: const MoneyDto(amountMinor: 285000, currencyCode: 'VND'),
        listUnitPrice: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
      );

      final result = reconcileComposeLinesAfterPersist(
        current: [local],
        persisted: [persisted],
      );

      expect(result, hasLength(1));
      expect(result.single.identity.lineId, 'server-uuid-1');
      expect(result.single.input.quantity, 3);
      expect(result.single.pricing.appliedUnitPrice.amountMinor, 95000);
      expect(result.single.pricing.lineTotal?.amountMinor, 285000);
      expect(result.single.stock?.availableQuantity, 5);
      expect(result.single.pricing.floorUnitPrice?.amountMinor, 80000);
      expect(result.single.identity.catalogUnitPrice.amountMinor, 90000);
      expect(result.single.pricing.contextVersion, 3);
    });

    test('throws when persisted line count differs from working state', () {
      final local = composeTestLine(
        lineId: 'line-1',
        productId: 'product-1',
        productUnitId: 'unit-1',
        productName: 'A',
        unitLabel: 'Hộp',
        quantity: 1,
        baseUnitPrice: composeTestMoney(100000),
        appliedUnitPrice: composeTestMoney(100000),
      );

      expect(
        () => reconcileComposeLinesAfterPersist(
          current: [local],
          persisted: const [],
        ),
        throwsA(isA<FormatException>()),
      );
    });

    test('reconciles multiple lines in order', () {
      final current = [
        _localLine(lineId: 'line-a', productId: 'p1'),
        _localLine(lineId: 'line-b', productId: 'p2'),
      ];
      final persisted = [
        _persistedLine(lineId: 'server-a', productId: 'p1'),
        _persistedLine(lineId: 'server-b', productId: 'p2'),
      ];

      final result = reconcileComposeLinesAfterPersist(
        current: current,
        persisted: persisted,
      );

      expect(result.map((line) => line.identity.lineId), ['server-a', 'server-b']);
      expect(result.map((line) => line.identity.productId), ['p1', 'p2']);
    });
  });
}

SalesComposeLineVm _localLine({
  required String lineId,
  required String productId,
}) {
  return composeTestLine(
    lineId: lineId,
    productId: productId,
    productUnitId: 'unit-1',
    productName: 'Product',
    unitLabel: 'Hộp',
    quantity: 1,
    baseUnitPrice: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
    appliedUnitPrice: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
    stockQuantity: 10,
  );
}

SalesOrderDraftLineDto _persistedLine({
  required String lineId,
  required String productId,
}) {
  return SalesOrderDraftLineDto(
    lineId: lineId,
    productId: productId,
    productSku: 'SP',
    productName: 'Product',
    productUnitId: 'unit-1',
    unitCode: 'BOX',
    unitName: 'Hộp',
    quantity: const QuantityDto(quantityMicros: QuantityDto.scale),
    appliedUnitPrice: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
    lineTotal: const MoneyDto(amountMinor: 100000, currencyCode: 'VND'),
  );
}
