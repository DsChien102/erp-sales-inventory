import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_provider_connection_read_gateway.dart';
import 'list_provider_templates_query.dart';
import 'provider_template_dto.dart';

@QueryHandlerFor(ListProviderTemplatesQuery)
final class ListProviderTemplatesQueryHandler
    implements IQueryHandler<ListProviderTemplatesQuery, List<ProviderTemplateDto>> {
  ListProviderTemplatesQueryHandler({
    required IProviderConnectionReadGateway readGateway,
  }) : _readGateway = readGateway;

  final IProviderConnectionReadGateway _readGateway;

  @override
  Future<List<ProviderTemplateDto>> handle(
    ListProviderTemplatesQuery query,
  ) {
    return _readGateway.listProviderTemplates(query);
  }
}
