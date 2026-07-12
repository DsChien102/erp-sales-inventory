import '../../ids/product_id.dart';
import '../../shared/product_duplicate_field.dart';
import '../barcode.dart';
import '../sku.dart';
import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class ProductDuplicateMatch {
  const ProductDuplicateMatch({
    required this.field,
    required this.productId,
    required this.productName,
    required this.matchedValue,
  });

  final ProductDuplicateField field;
  final ProductId productId;
  final String productName;
  final String matchedValue;
}

abstract interface class IProductDuplicateChecker {
  Future<List<ProductDuplicateMatch>> findMatches({
    required TenantId tenantId,
    Sku? sku,
    Barcode? barcode,
    ProductId? excludeProductId,
  });
}
