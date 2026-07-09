import 'product_unit_price_band_row_dto.dart';

final class ProductUnitPriceBandsDto {
  const ProductUnitPriceBandsDto({
    required this.productId,
    required this.baseUnitName,
    required this.rows,
    this.currency = 'VND',
    this.basePrice,
  });

  final String productId;
  final String baseUnitName;
  final String currency;
  final double? basePrice;
  final List<ProductUnitPriceBandRowDto> rows;
}
