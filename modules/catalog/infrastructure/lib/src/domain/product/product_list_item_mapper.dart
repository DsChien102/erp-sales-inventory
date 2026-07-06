import 'package:vet45_catalog_application/application.dart';
import 'package:vet45_catalog_domain/domain.dart';

import 'product_readiness_facts_mapper.dart';

abstract final class ProductListItemMapper {
  static ProductListItemReadRow fromRow(Map<String, dynamic> row) {
    final productId = row['product_id'] as String;
    final productName = row['name'] as String;

    final facts = ProductReadinessFacts(
      productId: productId,
      productName: productName,
      hasBaseUnit: row['has_base_unit'] as bool? ?? false,
      hasImages: row['has_images'] as bool? ?? false,
      hasStock: row['has_stock'] as bool? ?? false,
      hasBasePrice: row['has_base_price'] as bool? ?? false,
      hasPriceBand: row['has_price_band'] as bool? ?? false,
      hasRequiredCustomFields: row['has_required_custom_fields'] as bool? ?? true,
      stockMode: ProductReadinessFactsMapper.stockModeFromRpc(
        row['stock_mode'] as String?,
      ),
      basePriceMode: ProductReadinessFactsMapper.basePriceModeFromRpc(
        row['base_price_mode'] as String?,
      ),
    );

    return ProductListItemReadRow(
      id: productId,
      name: productName,
      tradeName: row['trade_name'] as String?,
      sku: row['sku'] as String?,
      barcode: row['barcode'] as String?,
      primaryImageUrl: row['primary_image_url'] as String?,
      businessStatus: _businessStatusFromRpc(row['business_status'] as String?),
      isSoftDeleted: row['is_soft_deleted'] as bool? ?? false,
      facts: facts,
      listPrice: _toDouble(row['list_price']),
      floorPrice: _toDouble(row['floor_price']),
      baseUnit: row['base_unit_name'] as String?,
      stockQuantity: _toInt(row['stock_qty']),
      updatedAt: DateTime.parse(row['updated_at'] as String),
    );
  }

  static ProductStatus _businessStatusFromRpc(String? value) {
    return switch (value) {
      'inactive' => ProductStatus.inactive,
      _ => ProductStatus.active,
    };
  }

  static double? _toDouble(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static int? _toInt(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.round();
    }
    return int.tryParse(value.toString());
  }
}
