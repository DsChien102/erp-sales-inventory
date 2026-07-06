import 'package:vet45_shared_domain/shared_kernel_domain.dart';
import 'floor_price.dart';
import 'list_price.dart';

final class ProductUnitPriceBand extends ValueObject {
  const ProductUnitPriceBand({
    required this.id,
    required this.tenantId,
    required this.productId,
    required this.productUnitId,
    this.listPrice,
    this.floorPrice,
    this.storePriceRuleId,
  });

  final String id;
  final String tenantId;
  final String productId;
  final String productUnitId;
  final ListPrice? listPrice;
  final FloorPrice? floorPrice;
  final String? storePriceRuleId;

  bool get isComplete => listPrice != null && floorPrice != null;

  @override
  List<Object?> get props => [
        id,
        tenantId,
        productId,
        productUnitId,
        listPrice,
        floorPrice,
        storePriceRuleId,
      ];
}
