import 'package:vet45_shared_application/application.dart';

/// Thrown when a product barcode already exists in the tenant.
final class DuplicateBarcodeException extends ApplicationException {
  DuplicateBarcodeException({
    required this.barcode,
    this.existingProductId,
    this.existingProductName,
  }) : super('Barcode "$barcode" is already in use.');

  final String barcode;
  final String? existingProductId;
  final String? existingProductName;
}
