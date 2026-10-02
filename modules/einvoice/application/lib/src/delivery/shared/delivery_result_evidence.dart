import 'package:vet45_einvoice_domain/domain.dart';

import 'delivery_result_kind.dart';

/// Safe, allow-listed evidence for one delivery attempt outcome.
///
/// Carries no raw provider response, header, credential or exception text.
final class DeliveryResultEvidence {
  const DeliveryResultEvidence({
    required this.kind,
    this.providerReference,
    this.safeCode,
    this.failureSource,
  });

  final DeliveryResultKind kind;
  final String? providerReference;
  final String? safeCode;
  final FailureSource? failureSource;
}
