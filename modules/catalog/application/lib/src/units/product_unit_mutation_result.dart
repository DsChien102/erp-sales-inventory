import 'product_unit_dto.dart';

final class ProductUnitMutationResult {
  const ProductUnitMutationResult({
    required this.productId,
    required this.unit,
  });

  final String productId;
  final ProductUnitDto unit;
}
