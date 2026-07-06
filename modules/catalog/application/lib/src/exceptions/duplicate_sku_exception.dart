import 'package:vet45_shared_application/application.dart';

/// Thrown when a product SKU already exists in the tenant.
final class DuplicateSkuException extends ApplicationException {
  DuplicateSkuException({
    required this.sku,
    this.existingProductId,
    this.existingProductName,
  }) : super('SKU "$sku" is already in use.');

  final String sku;
  final String? existingProductId;
  final String? existingProductName;
}
