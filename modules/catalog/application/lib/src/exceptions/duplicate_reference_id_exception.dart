import 'package:vet45_shared_application/application.dart';

/// Thrown when a product reference id already exists in the tenant.
final class DuplicateReferenceIdException extends ApplicationException {
  DuplicateReferenceIdException({
    required this.referenceId,
    this.existingProductId,
    this.existingProductName,
  }) : super('Reference id "$referenceId" is already in use.');

  final String referenceId;
  final String? existingProductId;
  final String? existingProductName;
}
