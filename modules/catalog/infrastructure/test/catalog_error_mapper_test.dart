import 'package:test/test.dart';
import 'package:vet45_catalog_application/application.dart';
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
  });
}
