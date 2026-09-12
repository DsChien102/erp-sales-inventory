import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../../errors/catalog_error_mapper.dart';

abstract final class CatalogSalesLookupRpcMapper {
  static Map<String, dynamic> searchSellableProductsParams({
    required String tenantId,
    required String storeId,
    required String keyword,
    required int limit,
    required int offset,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_store_id': storeId,
      'p_keyword': keyword,
      'p_limit': limit,
      'p_offset': offset,
    };
  }

  static Map<String, dynamic> resolveSellableBarcodeParams({
    required String tenantId,
    required String storeId,
    required String barcode,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_store_id': storeId,
      'p_barcode': barcode,
    };
  }

  static Map<String, dynamic> listSellableProductUnitsParams({
    required String tenantId,
    required String storeId,
    required String productId,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_store_id': storeId,
      'p_product_id': productId,
    };
  }

  static Map<String, dynamic> resolveSellableProductsParams({
    required String tenantId,
    required String storeId,
    required List<String> productIds,
  }) {
    return <String, dynamic>{
      'p_tenant_id': tenantId,
      'p_store_id': storeId,
      'p_product_ids': productIds,
    };
  }

  static List<SellableProductResolutionDto> resolutionsFromPayload(
    Object? payload,
  ) {
    final json = _requiredObject(payload, 'response');
    final items = _requiredList(json['items'], 'response.items');
    return items
        .map(
          (item) => _resolutionFromJson(
            _requiredObject(item, 'response.items[]'),
          ),
        )
        .toList(growable: false);
  }

  static List<SellableProductDto> productsFromPayload(Object? payload) {
    final json = _requiredObject(payload, 'response');
    final items = _requiredList(json['items'], 'response.items');
    return items
        .map((item) => _productFromJson(_requiredObject(item, 'response.items[]')))
        .toList(growable: false);
  }

  static List<SellableProductUnitDto> unitsFromPayload(Object? payload) {
    final json = _requiredObject(payload, 'response');
    final units = _requiredList(json['units'], 'response.units');
    return units
        .map((item) => _unitFromJson(_requiredObject(item, 'response.units[]')))
        .toList(growable: false);
  }

  static SellableProductResolutionDto _resolutionFromJson(
    Map<String, dynamic> json,
  ) {
    final productId = _requiredUuid(json['product_id'], 'resolution.product_id');
    final resolution = _requiredResolution(
      json['resolution'],
      'resolution.resolution',
    );
    final product = json['product'];

    if (resolution == SellableProductResolution.sellable) {
      return SellableProductResolutionDto(
        productId: productId,
        resolution: resolution,
        product: _productFromJson(
          _requiredObject(product, 'resolution.product'),
        ),
      );
    }

    if (product != null) {
      _invalid('resolution.product', 'must be null unless the product is sellable');
    }

    if (resolution == SellableProductResolution.notFound) {
      return SellableProductResolutionDto(
        productId: productId,
        resolution: resolution,
      );
    }

    return SellableProductResolutionDto(
      productId: productId,
      resolution: resolution,
      notSellable: NotSellableProductDto(
        productId: productId,
        sku: _optionalText(json['sku'], 'resolution.sku'),
        displayName: _optionalText(json['display_name'], 'resolution.display_name'),
        blockReason: _optionalText(json['block_reason'], 'resolution.block_reason'),
      ),
    );
  }

  static SellableProductResolution _requiredResolution(
    Object? value,
    String field,
  ) {
    final raw = _requiredText(value, field);
    return switch (raw) {
      'sellable' => SellableProductResolution.sellable,
      'not_sellable' => SellableProductResolution.notSellable,
      'not_found' => SellableProductResolution.notFound,
      _ => _invalid(field, 'must be sellable, not_sellable, or not_found'),
    };
  }

  static SellableProductDto _productFromJson(Map<String, dynamic> json) {
    final units = _requiredList(json['units'], 'product.units')
        .map((item) => _unitFromJson(_requiredObject(item, 'product.units[]')))
        .toList(growable: false);

    return SellableProductDto(
      productId: _requiredUuid(json['product_id'], 'product.product_id'),
      sku: _optionalText(json['sku'], 'product.sku'),
      displayName: _requiredText(json['display_name'], 'product.display_name'),
      tradeName: _optionalText(json['trade_name'], 'product.trade_name'),
      isSellable: _requiredBool(json['is_sellable'], 'product.is_sellable'),
      blockReason: _optionalText(json['block_reason'], 'product.block_reason'),
      currencyCode: _requiredCurrency(json['currency_code'], 'product.currency_code'),
      listPriceMinor: _requiredMinor(json['list_price_minor'], 'product.list_price_minor'),
      floorPriceMinor: _optionalMinor(json['floor_price_minor'], 'product.floor_price_minor'),
      availableStockMicros: _optionalInteger(
        json['available_stock_micros'],
        'product.available_stock_micros',
      ),
      units: units,
    );
  }

  static SellableProductUnitDto _unitFromJson(Map<String, dynamic> json) {
    return SellableProductUnitDto(
      productUnitId: _requiredUuid(json['product_unit_id'], 'unit.product_unit_id'),
      unitCode: _requiredText(json['unit_code'], 'unit.unit_code'),
      unitName: _requiredText(json['unit_name'], 'unit.unit_name'),
      barcode: _optionalText(json['barcode'], 'unit.barcode'),
      isDefault: _requiredBool(json['is_default'], 'unit.is_default'),
      isActive: _requiredBool(json['is_active'], 'unit.is_active'),
      isSellable: _requiredBool(json['is_sellable'], 'unit.is_sellable'),
      blockReason: _optionalText(json['block_reason'], 'unit.block_reason'),
      listPriceMinor: _requiredMinor(json['list_price_minor'], 'unit.list_price_minor'),
      floorPriceMinor: _optionalMinor(json['floor_price_minor'], 'unit.floor_price_minor'),
      availableStockMicros: _optionalInteger(
        json['available_stock_micros'],
        'unit.available_stock_micros',
      ),
    );
  }

  static Map<String, dynamic> _requiredObject(Object? value, String field) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    _invalid(field, 'must be a JSON object');
  }

  static List<dynamic> _requiredList(Object? value, String field) {
    if (value is List) {
      return value;
    }
    _invalid(field, 'must be a JSON array');
  }

  static String _requiredUuid(Object? value, String field) {
    final text = _requiredText(value, field);
    if (!_uuidPattern.hasMatch(text)) {
      _invalid(field, 'must be a UUID');
    }
    return text;
  }

  static String _requiredCurrency(Object? value, String field) {
    final currency = _requiredText(value, field);
    if (!_currencyPattern.hasMatch(currency)) {
      _invalid(field, 'must be an uppercase ISO currency code');
    }
    return currency;
  }

  static String _requiredText(Object? value, String field) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    _invalid(field, 'must be non-blank text');
  }

  static String? _optionalText(Object? value, String field) {
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    _invalid(field, 'must be text or null');
  }

  static bool _requiredBool(Object? value, String field) {
    if (value is bool) {
      return value;
    }
    _invalid(field, 'must be boolean');
  }

  static int _requiredMinor(Object? value, String field) {
    final minor = _optionalInteger(value, field);
    if (minor == null || minor < 0) {
      _invalid(field, 'must be a non-negative integer');
    }
    return minor;
  }

  static int? _optionalMinor(Object? value, String field) {
    final minor = _optionalInteger(value, field);
    if (minor != null && minor < 0) {
      _invalid(field, 'must be a non-negative integer or null');
    }
    return minor;
  }

  static int? _optionalInteger(Object? value, String field) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    _invalid(field, 'must be an integer or null');
  }

  static Never _invalid(String field, String expectation) {
    throw mapCatalogRpcError(
      RpcException('invalid_catalog_sales_lookup_payload: $field $expectation'),
    );
  }

  static final _uuidPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static final _currencyPattern = RegExp(r'^[A-Z]{3}$');
}
