import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../enums/delivery_attempt_status.dart';
import '../enums/delivery_status.dart';
import '../value_objects/provider_delivery_result.dart';

/// Whether an incoming provider delivery result may mutate state.
///
/// Duplicate results and late failures after success are not broken — callers
/// treat those as idempotent no-ops. Broken means an illegal transition.
final class DeliveryResultCanBeAppliedRule implements IBusinessRule {
  const DeliveryResultCanBeAppliedRule({
    required this.deliveryStatus,
    required this.attemptStatus,
    required this.result,
    required this.isTargetAttempt,
  });

  final DeliveryStatus deliveryStatus;
  final DeliveryAttemptStatus attemptStatus;
  final ProviderDeliveryResult result;
  final bool isTargetAttempt;

  @override
  bool isBroken() {
    if (!isTargetAttempt) {
      return true;
    }
    // Idempotent / non-reversing cases — aggregate no-ops without throwing.
    if (deliveryStatus == DeliveryStatus.succeeded) {
      return false;
    }
    if (attemptStatus == DeliveryAttemptStatus.succeeded ||
        attemptStatus == DeliveryAttemptStatus.failed) {
      return false;
    }

    return switch (attemptStatus) {
      DeliveryAttemptStatus.queued => !_isPreDispatchFailure(result.category),
      DeliveryAttemptStatus.submitted => false,
      DeliveryAttemptStatus.unknown => !_isAuthoritativeResolution(
        result.category,
      ),
      DeliveryAttemptStatus.succeeded || DeliveryAttemptStatus.failed => false,
    };
  }

  static bool _isPreDispatchFailure(ProviderDeliveryResultCategory category) {
    return category == ProviderDeliveryResultCategory.definiteFailure ||
        category == ProviderDeliveryResultCategory.retryableFailure;
  }

  static bool _isAuthoritativeResolution(
    ProviderDeliveryResultCategory category,
  ) {
    return category == ProviderDeliveryResultCategory.success ||
        category == ProviderDeliveryResultCategory.definiteFailure;
  }

  @override
  String get message =>
      'Provider delivery result cannot be applied to attempt in '
      '$attemptStatus under delivery $deliveryStatus';
}
