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

    test('maps duplicate product unit name', () {
      final error = mapCatalogRpcError(
        RpcException('duplicate product unit "Thùng"'),
      );

      expect(error, isA<DuplicateMeasurementUnitNameException>());
      expect(
        (error as DuplicateMeasurementUnitNameException).name,
        'Thùng',
      );
    });

    test('maps missing base unit', () {
      final error = mapCatalogRpcError(RpcException('missing base unit'));

      expect(error, isA<MissingBaseUnitException>());
    });

    test('maps not basic stock mode', () {
      final error = mapCatalogRpcError(RpcException('not_basic_stock_mode'));

      expect(error, isA<NotBasicStockModeException>());
    });

    test('maps not manual base price mode', () {
      final error = mapCatalogRpcError(RpcException('not_manual_base_price_mode'));

      expect(error, isA<NotManualBasePriceModeException>());
    });

    test('maps stale stock quantity', () {
      final error = mapCatalogRpcError(RpcException('stale_stock_quantity'));

      expect(error, isA<StaleStockQuantityException>());
    });

    test('maps stale product version', () {
      final error = mapCatalogRpcError(
        RpcException('stale_product_version: expected=0 current=1'),
      );

      expect(error, isA<StaleProductVersionException>());
      expect((error as StaleProductVersionException).expectedVersion, 0);
      expect(error.currentVersion, 1);
    });

    test('maps product delete blocked as validation exception', () {
      final error = mapCatalogRpcError(
        RpcException('product_delete_blocked: open_transaction'),
      );

      expect(error, isA<ValidationException>());
      expect((error as ValidationException).message, contains('open_transaction'));
    });

    test('maps product restore blocked as validation exception', () {
      final error = mapCatalogRpcError(
        RpcException('product_restore_blocked: duplicate active references'),
      );

      expect(error, isA<ValidationException>());
      expect(
        (error as ValidationException).message,
        contains('duplicate active references'),
      );
    });

    test('maps soft deleted product locked as application exception', () {
      final error = mapCatalogRpcError(
        RpcException('soft_deleted_product_locked'),
      );

      expect(error, isA<ApplicationException>());
      expect((error as ApplicationException).message, contains('soft_deleted_product_locked'));
    });

    test('maps product business status warning acknowledgment', () {
      final error = mapCatalogRpcError(
        RpcException(
          'product_business_status_warnings_require_acknowledgment: '
          '[{"code":"has_stock","message":"Sản phẩm vẫn còn tồn kho hiện hành."}]',
        ),
      );

      expect(
        error,
        isA<ProductBusinessStatusWarningsRequireAcknowledgmentException>(),
      );
      expect(
        (error as ProductBusinessStatusWarningsRequireAcknowledgmentException).warnings.single.code,
        ProductBusinessStatusWarningCode.hasStock,
      );
    });

    test('maps product conversion unit delete blocked', () {
      final error = mapCatalogRpcError(
        RpcException(
          'product_conversion_unit_delete_blocked: Đơn vị đã được dùng trong giao dịch. Hãy dùng "Tắt đơn vị" để bảo toàn lịch sử.',
        ),
      );

      expect(error, isA<ProductConversionUnitDeleteBlockedException>());
      expect(
        (error as ProductConversionUnitDeleteBlockedException).message,
        contains('Tắt đơn vị'),
      );
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

    test('maps duplicate custom field group name', () {
      final error = mapCatalogRpcError(
        RpcException('duplicate custom field group name "Thông tin thuốc"'),
      );

      expect(error, isA<DuplicateCustomFieldGroupNameException>());
      expect(
        (error as DuplicateCustomFieldGroupNameException).name,
        'Thông tin thuốc',
      );
    });

    test('maps duplicate custom field name', () {
      final error = mapCatalogRpcError(
        RpcException('duplicate custom field name "Thành phần"'),
      );

      expect(error, isA<DuplicateCustomFieldNameException>());
    });

    test('maps custom field group not found', () {
      final error = mapCatalogRpcError(
        RpcException('custom field group not found'),
      );

      expect(error, isA<CustomFieldGroupNotFoundException>());
    });

    test('maps custom field not found', () {
      final error = mapCatalogRpcError(
        RpcException('custom field not found'),
      );

      expect(error, isA<CustomFieldNotFoundException>());
    });
  });
}
