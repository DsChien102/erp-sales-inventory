import 'delivery_result_kind.dart';

/// Safe, allow-listed evidence for one delivery attempt outcome.
///
/// Carries no raw provider response, header, credential or exception text.
final class DeliveryResultEvidence {
  const DeliveryResultEvidence({
    required this.kind,
    this.providerReference,
    this.safeCode,
  });

  final DeliveryResultKind kind;
  final String? providerReference;
  final String? safeCode;
}
