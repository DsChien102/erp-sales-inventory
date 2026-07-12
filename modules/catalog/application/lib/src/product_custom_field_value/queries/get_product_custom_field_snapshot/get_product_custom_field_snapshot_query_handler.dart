import 'package:vet45_annotations/vet45_annotations.dart';
import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_catalog_custom_field_read_gateway.dart';
import 'get_product_custom_field_snapshot_query.dart';
import 'get_product_custom_field_snapshot_query_validator.dart';
import 'product_custom_field_snapshot_dto.dart';

@QueryHandlerFor(GetProductCustomFieldSnapshotQuery)
final class GetProductCustomFieldSnapshotQueryHandler
    implements IQueryHandler<GetProductCustomFieldSnapshotQuery, ProductCustomFieldSnapshotDto> {
  GetProductCustomFieldSnapshotQueryHandler({
    required ICatalogCustomFieldReadGateway readGateway,
    GetProductCustomFieldSnapshotQueryValidator? validator,
  }) : _readGateway = readGateway,
       _validator = validator ?? GetProductCustomFieldSnapshotQueryValidator();

  final ICatalogCustomFieldReadGateway _readGateway;
  final GetProductCustomFieldSnapshotQueryValidator _validator;

  @override
  Future<ProductCustomFieldSnapshotDto> handle(
    GetProductCustomFieldSnapshotQuery query,
  ) async {
    await _validator.validate(query);
    return _readGateway.getSnapshot(
      tenantId: query.tenantId,
      productIds: query.productIds,
      includeInactiveValues: query.includeInactiveValues,
    );
  }
}
