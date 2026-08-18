import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_provider_connection_read_gateway.dart';
import 'get_provider_connection_screen_query.dart';
import 'provider_connection_screen_dto.dart';

@QueryHandlerFor(GetProviderConnectionScreenQuery)
final class GetProviderConnectionScreenQueryHandler
    implements
        IQueryHandler<
          GetProviderConnectionScreenQuery,
          ProviderConnectionScreenDto
        > {
  GetProviderConnectionScreenQueryHandler({
    required IProviderConnectionReadGateway readGateway,
  }) : _readGateway = readGateway;

  final IProviderConnectionReadGateway _readGateway;

  @override
  Future<ProviderConnectionScreenDto> handle(
    GetProviderConnectionScreenQuery query,
  ) {
    return _readGateway.getConnectionScreen(
      tenantId: query.tenantId,
      actorId: query.actorId,
    );
  }
}
