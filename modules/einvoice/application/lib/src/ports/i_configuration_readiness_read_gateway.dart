import 'package:vet45_einvoice_domain/domain.dart';

import '../configuration/queries/get_configuration_readiness/configuration_readiness_dto.dart';

/// Configuration readiness projection read port.
abstract interface class IConfigurationReadinessReadGateway {
  Future<ConfigurationReadinessDto> getReadiness({
    required String tenantId,
    required String actorId,
    IssuancePurpose? purpose,
  });
}
