import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class _RecordingStockReadPort implements IProductStockReadPort {
  List<ProductStockMovementReadRow> rows = const [];
  String? lastTenantId;
  String? lastProductId;
  int? lastLimit;

  @override
  Future<List<ProductStockMovementReadRow>> listMovements({
    required String tenantId,
    required String productId,
    int limit = 50,
  }) async {
    lastTenantId = tenantId;
    lastProductId = productId;
    lastLimit = limit;
    return rows;
  }
}

final class _FakeReadinessReadPort implements IProductReadinessReadPort {
  _FakeReadinessReadPort({required this.facts});

  final ProductReadinessFacts? facts;

  @override
  Future<ProductReadinessFacts?> loadFacts({
    required String tenantId,
    required String productId,
  }) async {
    return facts;
  }
}

ProductReadinessFacts _facts({StockMode stockMode = StockMode.basic}) {
  return ProductReadinessFacts(
    productId: 'product-1',
    productName: 'Thuốc A',
    hasBaseUnit: true,
    hasImages: true,
    hasStock: true,
    hasBasePrice: true,
    hasPriceBand: true,
    hasRequiredCustomFields: true,
    stockMode: stockMode,
    basePriceMode: BasePriceMode.manual,
  );
}

void main() {
  group('GetProductStockHistoryQueryHandler', () {
    test('scn_e05_u02_fr03_01 maps movement rows to dto', () async {
      final occurredAt = DateTime.utc(2026, 1, 15, 10, 30);
      final readPort = _RecordingStockReadPort()
        ..rows = [
          ProductStockMovementReadRow(
            id: 'movement-1',
            occurredAt: occurredAt,
            actorDisplayName: 'user-abc',
            movementType: StockMovementType.initial,
            quantityBefore: 0,
            quantityAfter: 50,
            delta: 50,
          ),
          ProductStockMovementReadRow(
            id: 'movement-2',
            occurredAt: occurredAt.add(const Duration(hours: 1)),
            actorDisplayName: 'user-def',
            movementType: StockMovementType.adjust,
            quantityBefore: 50,
            quantityAfter: 25,
            delta: -25,
            reason: 'Kiểm kê',
          ),
        ];
      final handler = GetProductStockHistoryQueryHandler(
        stockReadPort: readPort,
        readinessReadPort: _FakeReadinessReadPort(facts: _facts()),
      );

      final result = await handler.handle(
        GetProductStockHistoryQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
          limit: 10,
        ),
      );

      expect(result.productId, 'product-1');
      expect(result.isHistoricalBasicOnly, isFalse);
      expect(result.movements.first.movementType, StockMovementType.initial);
      expect(result.movements.last.reason, 'Kiểm kê');
      expect(readPort.lastLimit, 10);
    });

    test('advanced mode still returns historical movements', () async {
      final readPort = _RecordingStockReadPort()
        ..rows = [
          ProductStockMovementReadRow(
            id: 'movement-1',
            occurredAt: DateTime.utc(2026, 1, 1),
            actorDisplayName: 'user-abc',
            movementType: StockMovementType.adjust,
            quantityBefore: 30,
            quantityAfter: 25,
            delta: -5,
          ),
        ];
      final handler = GetProductStockHistoryQueryHandler(
        stockReadPort: readPort,
        readinessReadPort: _FakeReadinessReadPort(
          facts: _facts(stockMode: StockMode.advanced),
        ),
      );

      final result = await handler.handle(
        GetProductStockHistoryQuery(
          tenantId: 'tenant-1',
          productId: 'product-1',
        ),
      );

      expect(result.isHistoricalBasicOnly, isTrue);
      expect(result.movements, hasLength(1));
      expect(readPort.lastProductId, 'product-1');
    });

    test('product not found throws ApplicationException', () async {
      final handler = GetProductStockHistoryQueryHandler(
        stockReadPort: _RecordingStockReadPort(),
        readinessReadPort: _FakeReadinessReadPort(facts: null),
      );

      await expectLater(
        handler.handle(
          GetProductStockHistoryQuery(
            tenantId: 'tenant-1',
            productId: 'product-1',
          ),
        ),
        throwsA(isA<ApplicationException>()),
      );
    });
  });
}
