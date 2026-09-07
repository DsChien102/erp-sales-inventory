import 'package:vet45_einvoice_domain/domain.dart';

/// Connection summary for settings screen.
final class ProviderConnectionSummaryDto {
  const ProviderConnectionSummaryDto({
    this.connectionId,
    required this.status,
    this.lastCheckedAt,
    this.maskedAccount,
    this.connectionVersion,
  });

  final String? connectionId;
  final ProviderConnectionStatus status;
  final DateTime? lastCheckedAt;
  final String? maskedAccount;
  final int? connectionVersion;
}
