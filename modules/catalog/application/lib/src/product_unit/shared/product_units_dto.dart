import 'product_unit_dto.dart';

final class ProductUnitsDto {
  const ProductUnitsDto({
    required this.productId,
    required this.baseUnitName,
    required this.units,
  });

  final String productId;
  final String baseUnitName;
  final List<ProductUnitDto> units;
}
