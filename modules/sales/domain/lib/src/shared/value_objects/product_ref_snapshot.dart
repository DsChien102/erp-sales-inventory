import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class ProductRefSnapshot extends ValueObject {
  ProductRefSnapshot({
    required this.productId,
    required this.sku,
    required this.name,
  });

  final String productId;
  final String sku;
  final String name;

  @override
  List<Object?> get props => [productId, sku, name];
}
