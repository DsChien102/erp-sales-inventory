import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

class _RecordingProductCommandGateway implements IProductCommandGateway {
  String? lastProductId;
  String? lastTenantId;
  ProductStockProfile? lastStockProfile;
  ProductBasePriceProfile? lastPriceProfile;
  ProductUnitPriceBand? lastPriceBand;

  @override
  Future<String> create({
    required Product product,
    required String idempotencyKey,
  }) async {
    return 'id';
  }

  @override
  Future<void> setInitialStock({
    required String productId,
    required String tenantId,
    required ProductStockProfile profile,
  }) async {
    lastProductId = productId;
    lastTenantId = tenantId;
    lastStockProfile = profile;
  }

  @override
  Future<void> setManualBasePrice({
    required String productId,
    required String tenantId,
    required ProductBasePriceProfile profile,
  }) async {
    lastProductId = productId;
    lastTenantId = tenantId;
    lastPriceProfile = profile;
  }

  @override
  Future<void> setInitialPriceBand({
    required String productId,
    required String tenantId,
    required ProductUnitPriceBand priceBand,
  }) async {
    lastProductId = productId;
    lastTenantId = tenantId;
    lastPriceBand = priceBand;
  }
}

void main() {
  group('SetInitialStockCommandHandler & Validator', () {
    test('valid basic stock sets initial stock on gateway', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = SetInitialStockCommandHandler(commandGateway: gateway);
      final validator = SetInitialStockCommandValidator();

      final command = SetInitialStockCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        quantity: 100,
      );

      await validator.validate(command);
      await handler.handle(command);

      expect(gateway.lastProductId, 'prod-1');
      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastStockProfile?.initialStock, 100.0);
    });

    test('negative quantity throws ValidationException', () async {
      final validator = SetInitialStockCommandValidator();
      final command = SetInitialStockCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        quantity: -5,
      );

      expect(
        () => validator.validate(command),
        throwsA(isA<ValidationException>()),
      );
    });

    test('non basic mode throws NotBasicStockModeException', () async {
      final validator = SetInitialStockCommandValidator();
      final command = SetInitialStockCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        quantity: 10,
        mode: 'advanced',
      );

      expect(
        () => validator.validate(command),
        throwsA(isA<NotBasicStockModeException>()),
      );
    });
  });

  group('SetManualBasePriceCommandHandler & Validator', () {
    test('valid manual base price sets profile on gateway', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = SetManualBasePriceCommandHandler(commandGateway: gateway);
      final validator = SetManualBasePriceCommandValidator();

      final command = SetManualBasePriceCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        basePrice: 50000.0,
      );

      await validator.validate(command);
      await handler.handle(command);

      expect(gateway.lastProductId, 'prod-1');
      expect(gateway.lastTenantId, 'tenant-1');
      expect(gateway.lastPriceProfile?.basePrice?.amount, 50000.0);
    });

    test('negative base price throws ValidationException', () async {
      final validator = SetManualBasePriceCommandValidator();
      final command = SetManualBasePriceCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        basePrice: -100.0,
      );

      expect(
        () => validator.validate(command),
        throwsA(isA<ValidationException>()),
      );
    });

    test('non manual mode throws NotManualBasePriceModeException', () async {
      final validator = SetManualBasePriceCommandValidator();
      final command = SetManualBasePriceCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        basePrice: 10000.0,
        mode: 'costing',
      );

      expect(
        () => validator.validate(command),
        throwsA(isA<NotManualBasePriceModeException>()),
      );
    });
  });

  group('SetInitialPriceBandCommandHandler & Validator', () {
    test('valid price band sets band on gateway', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = SetInitialPriceBandCommandHandler(commandGateway: gateway);
      final validator = SetInitialPriceBandCommandValidator();

      final command = SetInitialPriceBandCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        listPrice: 100000.0,
        floorPrice: 80000.0,
      );

      await validator.validate(command);
      await handler.handle(command);

      expect(gateway.lastProductId, 'prod-1');
      expect(gateway.lastPriceBand!.listPrice!.amount, 100000.0);
      expect(gateway.lastPriceBand!.floorPrice!.amount, 80000.0);
    });

    test('omitted product unit id leaves null for RPC base-unit resolution', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = SetInitialPriceBandCommandHandler(commandGateway: gateway);

      await handler.handle(
        SetInitialPriceBandCommand(
          tenantId: 'tenant-1',
          productId: 'prod-1',
          listPrice: 100000.0,
          floorPrice: 80000.0,
        ),
      );

      expect(gateway.lastPriceBand!.productUnitId, isNull);
    });

    test('floor price greater than list price throws exception', () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = SetInitialPriceBandCommandHandler(commandGateway: gateway);
      final validator = SetInitialPriceBandCommandValidator();

      final command = SetInitialPriceBandCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        listPrice: 50000.0,
        floorPrice: 80000.0,
      );

      expect(
        () => validator.validate(command),
        throwsA(isA<FloorPriceGreaterThanListPriceException>()),
      );
      expect(
        () => handler.handle(command),
        throwsA(isA<FloorPriceGreaterThanListPriceException>()),
      );
    });

    test('useStoreRule true without base price throws MissingBasePriceException',
        () async {
      final gateway = _RecordingProductCommandGateway();
      final handler = SetInitialPriceBandCommandHandler(commandGateway: gateway);

      final command = SetInitialPriceBandCommand(
        tenantId: 'tenant-1',
        productId: 'prod-1',
        useStoreRule: true,
      );

      expect(
        () => handler.handle(command),
        throwsA(isA<MissingBasePriceException>()),
      );
    });
  });
}
