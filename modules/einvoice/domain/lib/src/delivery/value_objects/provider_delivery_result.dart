import 'package:vet45_shared_domain/shared_kernel_domain.dart';

/// Domain classification of a provider delivery outcome.
///
/// Provider HTTP mapping stays outside Domain; only these categories and safe
/// codes may enter the aggregate.
enum ProviderDeliveryResultCategory {
  success,
  definiteFailure,
  retryableFailure,
  undetermined,
}

/// Safe, allow-listed provider delivery result embedded on delivery/attempt.
final class ProviderDeliveryResult extends ValueObject {
  const ProviderDeliveryResult._({
    required this.category,
    this.safeCode,
    this.providerReference,
  });

  const ProviderDeliveryResult.success({String? providerReference})
    : this._(
        category: ProviderDeliveryResultCategory.success,
        providerReference: providerReference,
      );

  const ProviderDeliveryResult.definiteFailure({String? safeCode})
    : this._(
        category: ProviderDeliveryResultCategory.definiteFailure,
        safeCode: safeCode,
      );

  const ProviderDeliveryResult.retryableFailure({String? safeCode})
    : this._(
        category: ProviderDeliveryResultCategory.retryableFailure,
        safeCode: safeCode,
      );

  const ProviderDeliveryResult.undetermined({String? safeCode})
    : this._(
        category: ProviderDeliveryResultCategory.undetermined,
        safeCode: safeCode,
      );

  final ProviderDeliveryResultCategory category;
  final String? safeCode;
  final String? providerReference;

  @override
  List<Object?> get props => [category, safeCode, providerReference];
}
