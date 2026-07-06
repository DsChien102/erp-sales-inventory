import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_catalog_infrastructure/src/errors/catalog_error_mapper.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  group('mapCatalogRpcError', () {
    test('maps duplicate sku', () {
      final error = mapCatalogRpcError(RpcException('duplicate sku'));
      expect(error, isA<DuplicateSkuException>());
    });

    test('maps duplicate barcode', () {
      final error = mapCatalogRpcError(RpcException('duplicate barcode'));
      expect(error, isA<DuplicateBarcodeException>());
    });

    test('maps permission denied', () {
      final error = mapCatalogRpcError(
        RpcException('permission denied: catalog.product.create'),
      );
      expect(error, isA<ApplicationException>());
      expect(error, isNot(isA<DuplicateSkuException>()));
    });

    test('maps duplicate measurement unit name', () {
      final error = mapCatalogRpcError(
        RpcException('duplicate measurement unit "Lọ"'),
      );

      expect(error, isA<DuplicateMeasurementUnitNameException>());
    });

    test('maps missing base unit', () {
      final error = mapCatalogRpcError(RpcException('missing base unit'));

      expect(error, isA<MissingBaseUnitException>());
    });

    test('maps validation exceptions', () {
      final error = mapCatalogRpcError(
        RpcException('validation_exception: Measurement unit is inactive.'),
      );

      expect(error, isA<ValidationException>());
      expect(
        (error as ValidationException).message,
        contains('Measurement unit is inactive.'),
      );
    });
  });
}
