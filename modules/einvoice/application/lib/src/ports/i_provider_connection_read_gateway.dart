import '../configuration/queries/get_provider_connection_screen/provider_connection_screen_dto.dart';
import '../configuration/queries/list_provider_templates/provider_template_dto.dart';
import '../configuration/queries/list_provider_templates/list_provider_templates_query.dart';

/// Read-side provider connection and template queries.
abstract interface class IProviderConnectionReadGateway {
  Future<ProviderConnectionScreenDto> getConnectionScreen({
    required String tenantId,
    required String actorId,
  });

  Future<List<ProviderTemplateDto>> listProviderTemplates(
    ListProviderTemplatesQuery query,
  );
}
