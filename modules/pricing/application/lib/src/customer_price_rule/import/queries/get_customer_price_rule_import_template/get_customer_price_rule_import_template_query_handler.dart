import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_application/application.dart';

@QueryHandlerFor(GetCustomerPriceRuleImportTemplateQuery)
final class GetCustomerPriceRuleImportTemplateQueryHandler
    implements
        IQueryHandler<
          GetCustomerPriceRuleImportTemplateQuery,
          CustomerPriceRuleImportTemplateDto
        > {
  const GetCustomerPriceRuleImportTemplateQueryHandler({
    required ICustomerPriceRuleImportFilePort filePort,
  }) : _filePort = filePort;

  final ICustomerPriceRuleImportFilePort _filePort;

  @override
  Future<CustomerPriceRuleImportTemplateDto> handle(
    GetCustomerPriceRuleImportTemplateQuery query,
  ) async => _filePort.createTemplateV1();
}
