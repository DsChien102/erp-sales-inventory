// ignore_for_file: implementation_imports

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/catalog/data/catalog_errors.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_catalog_infrastructure/src/errors/catalog_error_mapper.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

void main() {
  group('catalog_errors parity', () {
    group('old (mapCatalogRpcError)', () {
      test('duplicate sku with quotes', () {
        final err = mapCatalogRpcError(RpcException('duplicate sku "A1"'));
        expect(err, isA<DuplicateSkuException>());
        expect((err as DuplicateSkuException).sku, 'A1');
      });

      test('duplicate reference_id', () {
        final err = mapCatalogRpcError(RpcException('duplicate reference_id "REF-1"'));
        expect(err, isA<DuplicateReferenceIdException>());
        expect((err as DuplicateReferenceIdException).referenceId, 'REF-1');
      });

      test('duplicate barcode', () {
        final err = mapCatalogRpcError(RpcException('duplicate barcode "893123456"'));
        expect(err, isA<DuplicateBarcodeException>());
        expect((err as DuplicateBarcodeException).barcode, '893123456');
      });

      test('duplicate measurement unit name', () {
        final err = mapCatalogRpcError(RpcException('duplicate measurement unit "Hop"'));
        expect(err, isA<DuplicateMeasurementUnitNameException>());
        expect((err as DuplicateMeasurementUnitNameException).name, 'Hop');
      });

      test('duplicate product unit name', () {
        final err = mapCatalogRpcError(RpcException('duplicate product unit "Vi"'));
        expect(err, isA<DuplicateMeasurementUnitNameException>());
        expect((err as DuplicateMeasurementUnitNameException).name, 'Vi');
      });

      test('missing base unit', () {
        final err = mapCatalogRpcError(RpcException('missing base unit'));
        expect(err, isA<MissingBaseUnitException>());
      });

      test('base_unit_not_found', () {
        final err = mapCatalogRpcError(RpcException('base_unit_not_found'));
        expect(err, isA<MissingBaseUnitException>());
      });

      test('not_basic_stock_mode', () {
        final err = mapCatalogRpcError(RpcException('not_basic_stock_mode'));
        expect(err, isA<NotBasicStockModeException>());
      });

      test('not_manual_base_price_mode', () {
        final err = mapCatalogRpcError(RpcException('not_manual_base_price_mode'));
        expect(err, isA<NotManualBasePriceModeException>());
      });

      test('store_price_rule_not_found', () {
        final err = mapCatalogRpcError(RpcException('store_price_rule_not_found'));
        expect(err, isA<StorePriceRuleNotFoundException>());
      });

      test('store_price_rule_inactive', () {
        final err = mapCatalogRpcError(RpcException('store_price_rule_inactive'));
        expect(err, isA<StorePriceRuleInactiveException>());
      });

      test('price_band_overwrite_required', () {
        final err = mapCatalogRpcError(RpcException('price_band_overwrite_required'));
        expect(err, isA<PriceBandOverwriteRequiredException>());
      });

      test('stale_base_price', () {
        final err = mapCatalogRpcError(RpcException('stale_base_price'));
        expect(err, isA<StaleBasePriceException>());
      });

      test('missing_base_price', () {
        final err = mapCatalogRpcError(RpcException('missing_base_price'));
        expect(err, isA<MissingBasePriceException>());
      });

      test('floor_price_greater_than_list_price', () {
        final err = mapCatalogRpcError(RpcException('floor_price_greater_than_list_price'));
        expect(err, isA<FloorPriceGreaterThanListPriceException>());
      });

      test('floor_before_vat_greater_than_list_before_vat', () {
        final err = mapCatalogRpcError(RpcException('floor_before_vat_greater_than_list_before_vat'));
        expect(err, isA<FloorPriceGreaterThanListPriceException>());
      });

      test('floor_after_vat_greater_than_list_after_vat', () {
        final err = mapCatalogRpcError(RpcException('floor_after_vat_greater_than_list_after_vat'));
        expect(err, isA<FloorPriceGreaterThanListPriceException>());
      });

      test('inactive_product_unit', () {
        final err = mapCatalogRpcError(RpcException('inactive_product_unit'));
        expect(err, isA<InactiveProductUnitException>());
      });

      test('product_conversion_unit_delete_blocked', () {
        final err = mapCatalogRpcError(
          RpcException('product_conversion_unit_delete_blocked: Đơn vị đã được dùng trong giao dịch.'),
        );
        expect(err, isA<ProductConversionUnitDeleteBlockedException>());
        expect((err as ProductConversionUnitDeleteBlockedException).message, 'Đơn vị đã được dùng trong giao dịch.');
      });

      test('duplicate custom field group name', () {
        final err = mapCatalogRpcError(RpcException('duplicate custom field group name "Nhom 1"'));
        expect(err, isA<DuplicateCustomFieldGroupNameException>());
        expect((err as DuplicateCustomFieldGroupNameException).name, 'Nhom 1');
      });

      test('duplicate custom field name', () {
        final err = mapCatalogRpcError(RpcException('duplicate custom field name "Truong 1"'));
        expect(err, isA<DuplicateCustomFieldNameException>());
        expect((err as DuplicateCustomFieldNameException).name, 'Truong 1');
      });

      test('custom field group not found', () {
        final err = mapCatalogRpcError(RpcException('custom field group not found'));
        expect(err, isA<CustomFieldGroupNotFoundException>());
      });

      test('custom_field_value_validation with json array', () {
        final err = mapCatalogRpcError(
          RpcException(
            'custom_field_value_validation: [{"field_id":"f1","group_id":"g1","code":"invalid","message":"Lỗi"}]',
          ),
        );
        expect(err, isA<CustomFieldValueValidationException>());
        final ex = err as CustomFieldValueValidationException;
        expect(ex.errors.length, 1);
        expect(ex.errors.first.fieldId, 'f1');
        expect(ex.errors.first.code, 'invalid');
        expect(ex.errors.first.message, 'Lỗi');
      });

      test('custom_field_value_validation with invalid json', () {
        final err = mapCatalogRpcError(
          RpcException('custom_field_value_validation: not_json'),
        );
        expect(err, isA<CustomFieldValueValidationException>());
        final ex = err as CustomFieldValueValidationException;
        expect(ex.errors.length, 1);
        expect(ex.errors.first.message, 'not_json');
      });

      test('custom field not found', () {
        final err = mapCatalogRpcError(RpcException('custom field not found "f123"'));
        expect(err, isA<CustomFieldNotFoundException>());
        expect((err as CustomFieldNotFoundException).fieldId, 'f123');
      });

      test('custom_field_type_change_blocked', () {
        final err = mapCatalogRpcError(RpcException('custom_field_type_change_blocked'));
        expect(err, isA<CustomFieldTypeChangeBlockedException>());
      });

      test('stale_stock_quantity', () {
        final err = mapCatalogRpcError(RpcException('stale_stock_quantity'));
        expect(err, isA<StaleStockQuantityException>());
      });

      test('stale_product_version', () {
        final err = mapCatalogRpcError(RpcException('stale_product_version: expected=3 current=4'));
        expect(err, isA<StaleProductVersionException>());
        final ex = err as StaleProductVersionException;
        expect(ex.expectedVersion, 3);
        expect(ex.currentVersion, 4);
      });

      test('product_business_status_warnings_require_acknowledgment', () {
        final err = mapCatalogRpcError(
          RpcException(
            'product_business_status_warnings_require_acknowledgment: [{"code":"has_stock","message":"Còn tồn kho"}]',
          ),
        );
        expect(err, isA<ProductBusinessStatusWarningsRequireAcknowledgmentException>());
        final ex = err as ProductBusinessStatusWarningsRequireAcknowledgmentException;
        expect(ex.warnings.length, 1);
        expect(ex.warnings.first.code, 'has_stock');
        expect(ex.warnings.first.message, 'Còn tồn kho');
      });

      test('product_delete_blocked', () {
        final err = mapCatalogRpcError(RpcException('product_delete_blocked: Còn tồn kho'));
        expect(err, isA<ValidationException>());
        expect((err as ValidationException).message, 'Còn tồn kho');
      });

      test('product_restore_blocked', () {
        final err = mapCatalogRpcError(RpcException('product_restore_blocked: Product is not soft-deleted.'));
        expect(err, isA<ValidationException>());
        expect((err as ValidationException).message, 'Product is not soft-deleted.');
      });

      test('validation_exception', () {
        final err = mapCatalogRpcError(RpcException('validation_exception: Field invalid'));
        expect(err, isA<ValidationException>());
        expect((err as ValidationException).message, 'Field invalid');
      });

      test('product name is required', () {
        final err = mapCatalogRpcError(RpcException('product name is required'));
        expect(err, isA<ApplicationException>());
        expect((err as ApplicationException).message, 'Product name is required.');
      });

      test('product not found', () {
        final err = mapCatalogRpcError(RpcException('product not found'));
        expect(err, isA<ApplicationException>());
        expect((err as ApplicationException).message, 'Product not found');
      });

      test('permission denied', () {
        final err = mapCatalogRpcError(RpcException('permission denied: catalog.product.view'));
        expect(err, isA<ApplicationException>());
        expect((err as ApplicationException).message, 'permission denied: catalog.product.view');
      });

      test('unknown message', () {
        final err = mapCatalogRpcError(RpcException('some technical database error'));
        expect(err, isA<ApplicationException>());
        expect((err as ApplicationException).message, 'some technical database error');
      });
    });

    group('new (catalogException)', () {
      AppException classify(String message) {
        return catalogException(AppException.from(PostgrestException(message: message)));
      }

      test('duplicate sku with quotes', () {
        final err = classify('duplicate sku "A1"');
        expect(err.code, CatalogErrorCodes.duplicateSku);
        expect(err.details?['value'], 'A1');
      });

      test('duplicate reference_id', () {
        final err = classify('duplicate reference_id "REF-1"');
        expect(err.code, CatalogErrorCodes.duplicateReferenceId);
        expect(err.details?['value'], 'REF-1');
      });

      test('duplicate barcode', () {
        final err = classify('duplicate barcode "893123456"');
        expect(err.code, CatalogErrorCodes.duplicateBarcode);
        expect(err.details?['value'], '893123456');
      });

      test('duplicate measurement unit name', () {
        final err = classify('duplicate measurement unit "Hop"');
        expect(err.code, CatalogErrorCodes.duplicateProductUnit);
        expect(err.details?['value'], 'Hop');
      });

      test('duplicate product unit name', () {
        final err = classify('duplicate product unit "Vi"');
        expect(err.code, CatalogErrorCodes.duplicateProductUnit);
        expect(err.details?['value'], 'Vi');
      });

      test('missing base unit', () {
        final err = classify('missing base unit');
        expect(err.code, CatalogErrorCodes.missingBaseUnit);
      });

      test('base_unit_not_found', () {
        final err = classify('base_unit_not_found');
        expect(err.code, CatalogErrorCodes.missingBaseUnit);
      });

      test('not_basic_stock_mode', () {
        final err = classify('not_basic_stock_mode');
        expect(err.code, CatalogErrorCodes.notBasicStockMode);
      });

      test('not_manual_base_price_mode', () {
        final err = classify('not_manual_base_price_mode');
        expect(err.code, CatalogErrorCodes.notManualBasePriceMode);
      });

      test('store_price_rule_not_found', () {
        final err = classify('store_price_rule_not_found');
        expect(err.code, CatalogErrorCodes.storePriceRuleNotFound);
      });

      test('store_price_rule_inactive', () {
        final err = classify('store_price_rule_inactive');
        expect(err.code, CatalogErrorCodes.storePriceRuleInactive);
      });

      test('price_band_overwrite_required', () {
        final err = classify('price_band_overwrite_required');
        expect(err.code, CatalogErrorCodes.priceBandOverwriteRequired);
      });

      test('stale_base_price', () {
        final err = classify('stale_base_price');
        expect(err.code, CatalogErrorCodes.staleBasePrice);
      });

      test('missing_base_price', () {
        final err = classify('missing_base_price');
        expect(err.code, CatalogErrorCodes.missingBasePrice);
      });

      test('floor_price_greater_than_list_price', () {
        final err = classify('floor_price_greater_than_list_price');
        expect(err.code, CatalogErrorCodes.floorGreaterThanList);
      });

      test('floor_before_vat_greater_than_list_before_vat', () {
        final err = classify('floor_before_vat_greater_than_list_before_vat');
        expect(err.code, CatalogErrorCodes.floorGreaterThanList);
      });

      test('floor_after_vat_greater_than_list_after_vat', () {
        final err = classify('floor_after_vat_greater_than_list_after_vat');
        expect(err.code, CatalogErrorCodes.floorGreaterThanList);
      });

      test('inactive_product_unit', () {
        final err = classify('inactive_product_unit');
        expect(err.code, CatalogErrorCodes.inactiveProductUnit);
      });

      test('product_conversion_unit_delete_blocked', () {
        final err = classify('product_conversion_unit_delete_blocked: Đơn vị đã được dùng trong giao dịch.');
        expect(err.code, CatalogErrorCodes.conversionUnitDeleteBlocked);
        expect(err.serverMessage, 'Đơn vị đã được dùng trong giao dịch.');
      });

      test('duplicate custom field group name', () {
        final err = classify('duplicate custom field group name "Nhom 1"');
        expect(err.code, CatalogErrorCodes.duplicateCustomFieldGroupName);
        expect(err.details?['value'], 'Nhom 1');
      });

      test('duplicate custom field name', () {
        final err = classify('duplicate custom field name "Truong 1"');
        expect(err.code, CatalogErrorCodes.duplicateCustomFieldName);
        expect(err.details?['value'], 'Truong 1');
      });

      test('custom field group not found', () {
        final err = classify('custom field group not found');
        expect(err.code, CatalogErrorCodes.customFieldGroupNotFound);
      });

      test('custom_field_value_validation with json array', () {
        final err = classify(
          'custom_field_value_validation: [{"field_id":"f1","group_id":"g1","code":"invalid","message":"Lỗi"}]',
        );
        expect(err.code, CatalogErrorCodes.customFieldValueValidation);
        final errors = err.details?['errors'] as List<dynamic>;
        expect(errors.length, 1);
        final first = errors.first as Map<String, dynamic>;
        expect(first['field_id'], 'f1');
        expect(first['code'], 'invalid');
        expect(first['message'], 'Lỗi');
      });

      test('custom_field_value_validation with invalid json', () {
        final err = classify('custom_field_value_validation: not_json');
        expect(err.code, CatalogErrorCodes.customFieldValueValidation);
        final errors = err.details?['errors'] as List<dynamic>;
        expect(errors.length, 1);
        final first = errors.first as Map<String, dynamic>;
        expect(first['message'], 'not_json');
      });

      test('custom field not found', () {
        final err = classify('custom field not found "f123"');
        expect(err.code, CatalogErrorCodes.customFieldNotFound);
        expect(err.details?['value'], 'f123');
      });

      test('custom_field_type_change_blocked', () {
        final err = classify('custom_field_type_change_blocked');
        expect(err.code, CatalogErrorCodes.customFieldTypeChangeBlocked);
      });

      test('stale_stock_quantity', () {
        final err = classify('stale_stock_quantity');
        expect(err.code, CatalogErrorCodes.staleStockQuantity);
      });

      test('stale_product_version', () {
        final err = classify('stale_product_version: expected=3 current=4');
        expect(err.code, CatalogErrorCodes.staleProductVersion);
        expect(err.details?['expected'], 3);
        expect(err.details?['current'], 4);
      });

      test('product_business_status_warnings_require_acknowledgment', () {
        final err = classify(
          'product_business_status_warnings_require_acknowledgment: [{"code":"has_stock","message":"Còn tồn kho"}]',
        );
        expect(err.code, CatalogErrorCodes.statusWarningsRequireAck);
        final warnings = err.details?['warnings'] as List<dynamic>;
        expect(warnings.length, 1);
        final first = warnings.first as Map<String, dynamic>;
        expect(first['code'], 'has_stock');
        expect(first['message'], 'Còn tồn kho');
      });

      test('product_delete_blocked', () {
        final err = classify('product_delete_blocked: Còn tồn kho');
        expect(err.code, CatalogErrorCodes.productDeleteBlocked);
        expect(err.serverMessage, 'Còn tồn kho');
      });

      test('product_restore_blocked', () {
        final err = classify('product_restore_blocked: Product is not soft-deleted.');
        expect(err.code, CatalogErrorCodes.productRestoreBlocked);
        expect(err.serverMessage, 'Product is not soft-deleted.');
      });

      test('validation_exception', () {
        final err = classify('validation_exception: Field invalid');
        expect(err.code, AppErrorCode.validation);
        expect(err.serverMessage, 'Field invalid');
      });

      test('product name is required', () {
        final err = classify('product name is required');
        expect(err.code, CatalogErrorCodes.productNameRequired);
        expect(err.serverMessage, 'Product name is required.');
      });

      test('product not found', () {
        final err = classify('product not found');
        expect(err.code, CatalogErrorCodes.productNotFound);
        expect(err.serverMessage, 'Product not found');
      });

      test('permission denied', () {
        final err = classify('permission denied: catalog.product.view');
        expect(err.code, AppErrorCode.noPermission);
      });

      test('unknown message', () {
        final err = classify('some technical database error');
        expect(err.code, AppErrorCode.unknown);
        expect(err.serverMessage, 'some technical database error');
      });

      // 2 ca thêm mới chỉ có ở nhóm new (H3)
      test('product is soft-deleted', () {
        final err = classify('product is soft-deleted');
        expect(err.code, CatalogErrorCodes.productSoftDeleted);
      });

      test('actor mismatch', () {
        final err = classify('actor mismatch: tenant_id');
        expect(err.code, AppErrorCode.noPermission);
      });
    });
  });
}
