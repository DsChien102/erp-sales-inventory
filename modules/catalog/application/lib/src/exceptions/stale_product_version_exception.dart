import 'package:vet45_shared_application/application.dart';

/// Thrown when a product was changed after the caller loaded it for editing.
final class StaleProductVersionException extends ApplicationException {
  StaleProductVersionException({
    required this.expectedVersion,
    required this.currentVersion,
  }) : super(
         'Product changed since it was loaded. Reload the product before saving.',
       );

  final int expectedVersion;
  final int currentVersion;
}
