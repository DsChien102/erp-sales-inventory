import 'package:vet45_einvoice_domain/domain.dart';

final class ProviderConnectionCheckResultDto {
  const ProviderConnectionCheckResultDto({
    required this.connectionId,
    required this.status,
    required this.checkedAt,
  });

  final String connectionId;
  final ProviderConnectionStatus status;
  final DateTime checkedAt;
}
