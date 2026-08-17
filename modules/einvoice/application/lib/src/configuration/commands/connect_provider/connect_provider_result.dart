import 'package:vet45_einvoice_domain/domain.dart';

final class ProviderConnectionResultDto {
  const ProviderConnectionResultDto({
    required this.connectionId, required this.status,
  });

  final String connectionId;
  final ProviderConnectionStatus status;
}
