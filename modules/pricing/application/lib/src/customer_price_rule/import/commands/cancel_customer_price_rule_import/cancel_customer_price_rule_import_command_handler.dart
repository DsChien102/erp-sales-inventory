import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_application/application.dart';

@CommandHandlerFor(CancelCustomerPriceRuleImportCommand)
final class CancelCustomerPriceRuleImportCommandHandler
    implements
        ICommandHandler<
          CancelCustomerPriceRuleImportCommand,
          CustomerPriceRuleImportDto
        > {
  const CancelCustomerPriceRuleImportCommandHandler({
    required ICustomerPriceRuleImportGateway importGateway,
  }) : _importGateway = importGateway;

  final ICustomerPriceRuleImportGateway _importGateway;

  @override
  Future<CustomerPriceRuleImportDto> handle(
    CancelCustomerPriceRuleImportCommand command,
  ) => _importGateway.cancel(
    tenantId: command.tenantId,
    importId: command.importId.trim(),
    expectedVersion: command.expectedVersion,
  );
}
