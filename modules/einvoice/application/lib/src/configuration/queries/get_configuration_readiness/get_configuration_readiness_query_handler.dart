import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_configuration_readiness_read_gateway.dart';
import 'configuration_readiness_dto.dart';
import 'get_configuration_readiness_query.dart';

@QueryHandlerFor(GetConfigurationReadinessQuery)
final class GetConfigurationReadinessQueryHandler
    implements
        IQueryHandler<
          GetConfigurationReadinessQuery,
          ConfigurationReadinessDto
        > {
  GetConfigurationReadinessQueryHandler({
    required IConfigurationReadinessReadGateway readinessGateway,
  }) : _readinessGateway = readinessGateway;

  final IConfigurationReadinessReadGateway _readinessGateway;

  @override
  Future<ConfigurationReadinessDto> handle(
    GetConfigurationReadinessQuery query,
  ) {
    return _readinessGateway.getReadiness(
      tenantId: query.tenantId,
      actorId: query.actorId,
      purpose: query.purpose,
    );
  }
}
