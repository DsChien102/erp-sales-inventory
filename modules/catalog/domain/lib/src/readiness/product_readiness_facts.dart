import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../pricing/base_price_mode.dart';
import '../stock/stock_mode.dart';

/// Inputs for computing product readiness (loaded from DB / RPC).
final class ProductReadinessFacts extends ValueObject {
  const ProductReadinessFacts({
    required this.productId,
    required this.productName,
    required this.hasBaseUnit,
    required this.hasImages,
    required this.hasStock,
    required this.hasBasePrice,
    required this.hasPriceBand,
    required this.hasRequiredCustomFields,
    this.stockMode = StockMode.basic,
    this.basePriceMode = BasePriceMode.manual,
  });

  final String productId;
  final String productName;
  final bool hasBaseUnit;
  final bool hasImages;
  final bool hasStock;
  final bool hasBasePrice;
  final bool hasPriceBand;
  final bool hasRequiredCustomFields;
  final StockMode stockMode;
  final BasePriceMode basePriceMode;

  factory ProductReadinessFacts.forCreate({
    required String productId,
    required String productName,
    required bool hasBaseUnit,
    required bool hasImages,
  }) {
    return ProductReadinessFacts(
      productId: productId,
      productName: productName,
      hasBaseUnit: hasBaseUnit,
      hasImages: hasImages,
      hasStock: false,
      hasBasePrice: false,
      hasPriceBand: false,
      hasRequiredCustomFields: true,
    );
  }

  @override
  List<Object?> get props => [
        productId,
        productName,
        hasBaseUnit,
        hasImages,
        hasStock,
        hasBasePrice,
        hasPriceBand,
        hasRequiredCustomFields,
        stockMode,
        basePriceMode,
      ];
}
