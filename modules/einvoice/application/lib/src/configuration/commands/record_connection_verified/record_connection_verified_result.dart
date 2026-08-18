import 'package:vet45_einvoice_domain/domain.dart';

/// Outcome payload for record connection verified (RPC maps to connection DTO).
final class RecordConnectionVerifiedResult {
  const RecordConnectionVerifiedResult({
    required this.connectionId,
    required this.status,
  });

  final String connectionId;
  final ProviderConnectionStatus status;
}
