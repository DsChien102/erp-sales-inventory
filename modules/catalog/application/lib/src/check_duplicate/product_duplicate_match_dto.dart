import 'package:vet45_catalog_domain/domain.dart';

final class ProductDuplicateMatchDto {
  const ProductDuplicateMatchDto({
    required this.field,
    required this.productId,
    required this.productName,
    required this.matchedValue,
  });

  final ProductDuplicateField field;
  final String productId;
  final String productName;
  final String matchedValue;
}
