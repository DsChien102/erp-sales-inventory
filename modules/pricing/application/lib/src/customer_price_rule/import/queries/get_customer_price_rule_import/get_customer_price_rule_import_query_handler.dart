import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_application/application.dart';

@QueryHandlerFor(GetCustomerPriceRuleImportQuery)
final class GetCustomerPriceRuleImportQueryHandler
    implements
        IQueryHandler<
          GetCustomerPriceRuleImportQuery,
          CustomerPriceRuleImportDetailDto
        > {
  const GetCustomerPriceRuleImportQueryHandler({
    required ICustomerPriceRuleImportGateway importGateway,
  }) : _importGateway = importGateway;

  final ICustomerPriceRuleImportGateway _importGateway;

  @override
  Future<CustomerPriceRuleImportDetailDto> handle(
    GetCustomerPriceRuleImportQuery query,
  ) => _importGateway.get(
    tenantId: query.tenantId,
    importId: query.importId.trim(),
    rowStatus: query.rowStatus,
    cursor: query.cursor,
    limit: query.limit,
  );
}
