import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

final class _RecordingStockGateway implements ICatalogStockGateway {
  AdjustBasicStockCommand? lastCommand;
  AdjustBasicStockGatewayResult result = const AdjustBasicStockGatewayResult(
    previousQuantity: 150,
    newQuantity: 25,
    unitName: 'Lọ',
  );

  @override
  Future<AdjustBasicStockGatewayResult> adjustBasicStock({
    required AdjustBasicStockCommand command,
  }) async {
    lastCommand = command;
    return result;
  }
}

final class _FakeReadinessReadPort implements IProductReadinessReadPort {
  _FakeReadinessReadPort({
    required this.facts,
  });

  ProductReadinessFacts? facts;

  @override
  Future<ProductReadinessFacts?> loadFacts({
    required String tenantId,
    required String productId,
  }) async {
    return facts;
  }
}

ProductReadinessFacts _basicFacts({
  bool hasBaseUnit = true,
  bool hasStock = true,
}) {
  return ProductReadinessFacts(
    productId: 'product-1',
    productName: 'Thuốc A',
    hasBaseUnit: hasBaseUnit,
    hasImages: true,
    hasStock: hasStock,
    hasBasePrice: true,
    hasPriceBand: true,
    hasRequiredCustomFields: true,
    stockMode: StockMode.basic,
    basePriceMode: BasePriceMode.manual,
  );
}

void main() {
  group('AdjustBasicStockCommandHandler', () {
    test('scn_e05_u02_fr02_01 valid adjust returns result with readiness', () async {
      final gateway = _RecordingStockGateway();
      final readinessPort = _FakeReadinessReadPort(
        facts: _basicFacts(),
      );
      final handler = AdjustBasicStockCommandHandler(
        stockGateway: gateway,
        readinessReadPort: readinessPort,
      );

      final result = await handler.handle(
        AdjustBasicStockCommand(
          tenantId: 'tenant-1',
          productId: 'product-1',
          newQuantity: 25.0,
          reason: 'Kiểm kê thực tế',
          expectedQuantity: 150.0,
        ),
      );

      expect(result.previousQuantity, 150.0);
      expect(result.newQuantity, 25.0);
      expect(result.unitName, 'Lọ');
      expect(result.readinessSummary.status, ReadinessStatus.readyToSell);
      expect(gateway.lastCommand?.newQuantity, 25.0);
    });

    test('negative quantity rejected by validator', () async {
      final validator = AdjustBasicStockCommandValidator();

      await expectLater(
        validator.validate(
          AdjustBasicStockCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            newQuantity: -1.0,
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('missing base unit throws MissingBaseUnitException', () async {
      final handler = AdjustBasicStockCommandHandler(
        stockGateway: _RecordingStockGateway(),
        readinessReadPort: _FakeReadinessReadPort(
          facts: _basicFacts(hasBaseUnit: false),
        ),
      );

      await expectLater(
        handler.handle(
          AdjustBasicStockCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            newQuantity: 10.0,
          ),
        ),
        throwsA(isA<MissingBaseUnitException>()),
      );
    });

    test('advanced stock mode throws NotBasicStockModeException', () async {
      final handler = AdjustBasicStockCommandHandler(
        stockGateway: _RecordingStockGateway(),
        readinessReadPort: _FakeReadinessReadPort(
          facts: ProductReadinessFacts(
            productId: 'product-1',
            productName: 'Thuốc A',
            hasBaseUnit: true,
            hasImages: true,
            hasStock: false,
            hasBasePrice: false,
            hasPriceBand: false,
            hasRequiredCustomFields: true,
            stockMode: StockMode.advanced,
            basePriceMode: BasePriceMode.manual,
          ),
        ),
      );

      await expectLater(
        handler.handle(
          AdjustBasicStockCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            newQuantity: 10.0,
          ),
        ),
        throwsA(isA<NotBasicStockModeException>()),
      );
    });

    test('product not found throws ApplicationException', () async {
      final handler = AdjustBasicStockCommandHandler(
        stockGateway: _RecordingStockGateway(),
        readinessReadPort: _FakeReadinessReadPort(facts: null),
      );

      await expectLater(
        handler.handle(
          AdjustBasicStockCommand(
            tenantId: 'tenant-1',
            productId: 'product-1',
            newQuantity: 10.0,
          ),
        ),
        throwsA(isA<ApplicationException>()),
      );
    });
  });
}
