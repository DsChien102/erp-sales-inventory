import 'package:vet45_shared_application/application.dart';

import '../../ports/i_catalog_custom_field_config_gateway.dart';
import '../shared/custom_field_config_view_dto.dart';
import 'list_custom_field_config_query.dart';
import 'list_custom_field_config_query_validator.dart';

@QueryHandlerFor(ListCustomFieldConfigQuery)
final class ListCustomFieldConfigQueryHandler
    implements IQueryHandler<ListCustomFieldConfigQuery, CustomFieldConfigViewDto> {
  ListCustomFieldConfigQueryHandler({
    required ICatalogCustomFieldConfigGateway customFieldConfigGateway,
    ListCustomFieldConfigQueryValidator? validator,
  }) : _customFieldConfigGateway = customFieldConfigGateway,
       _validator = validator ?? ListCustomFieldConfigQueryValidator();

  final ICatalogCustomFieldConfigGateway _customFieldConfigGateway;
  final ListCustomFieldConfigQueryValidator _validator;

  @override
  Future<CustomFieldConfigViewDto> handle(
    ListCustomFieldConfigQuery query,
  ) async {
    await _validator.validate(query);
    return _customFieldConfigGateway.listConfig(tenantId: query.tenantId);
  }
}
