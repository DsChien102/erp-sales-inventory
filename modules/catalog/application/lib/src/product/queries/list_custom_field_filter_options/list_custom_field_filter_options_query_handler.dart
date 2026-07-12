import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_read_gateway.dart';
import 'custom_field_filter_option_dto.dart';
import 'list_custom_field_filter_options_query.dart';
import 'list_custom_field_filter_options_query_validator.dart';

@QueryHandlerFor(ListCustomFieldFilterOptionsQuery)
final class ListCustomFieldFilterOptionsQueryHandler
    implements IQueryHandler<ListCustomFieldFilterOptionsQuery, List<CustomFieldFilterOptionDto>> {
  ListCustomFieldFilterOptionsQueryHandler({
    required ICatalogReadGateway readGateway,
    ListCustomFieldFilterOptionsQueryValidator? validator,
  }) : _readGateway = readGateway,
       _validator = validator ?? ListCustomFieldFilterOptionsQueryValidator();

  final ICatalogReadGateway _readGateway;
  final ListCustomFieldFilterOptionsQueryValidator _validator;

  @override
  Future<List<CustomFieldFilterOptionDto>> handle(
    ListCustomFieldFilterOptionsQuery query,
  ) async {
    await _validator.validate(query);
    return _readGateway.listCustomFieldFilterOptions(
      tenantId: query.tenantId,
      maxOptionsPerField: query.maxOptionsPerField,
    );
  }
}
