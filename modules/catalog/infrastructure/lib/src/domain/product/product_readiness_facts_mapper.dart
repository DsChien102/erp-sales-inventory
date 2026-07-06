import 'package:vet45_catalog_domain/domain.dart';

abstract final class ProductReadinessFactsMapper {
  static ProductReadinessFacts fromRow(Map<String, dynamic> row) {
    return ProductReadinessFacts(
      productId: row['product_id'] as String,
      productName: row['product_name'] as String,
      hasBaseUnit: row['has_base_unit'] as bool? ?? false,
      hasImages: row['has_images'] as bool? ?? false,
      hasStock: row['has_stock'] as bool? ?? false,
      hasBasePrice: row['has_base_price'] as bool? ?? false,
      hasPriceBand: row['has_price_band'] as bool? ?? false,
      hasRequiredCustomFields:
          row['has_required_custom_fields'] as bool? ?? true,
      stockMode: stockModeFromRpc(row['stock_mode'] as String?),
      basePriceMode: basePriceModeFromRpc(row['base_price_mode'] as String?),
    );
  }

  static StockMode stockModeFromRpc(String? value) {
    return switch (value) {
      'advanced' => StockMode.advanced,
      _ => StockMode.basic,
    };
  }

  static BasePriceMode basePriceModeFromRpc(String? value) {
    return switch (value) {
      'costing_module' => BasePriceMode.costingModule,
      _ => BasePriceMode.manual,
    };
  }
}
