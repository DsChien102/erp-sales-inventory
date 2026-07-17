import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_application/application.dart';

@CommandHandlerFor(ConfirmCustomerPriceRuleImportCommand)
final class ConfirmCustomerPriceRuleImportCommandHandler
    implements
        ICommandHandler<
          ConfirmCustomerPriceRuleImportCommand,
          CustomerPriceRuleImportResultDto
        > {
  const ConfirmCustomerPriceRuleImportCommandHandler({
    required ICustomerPriceRuleImportGateway importGateway,
  }) : _importGateway = importGateway;

  final ICustomerPriceRuleImportGateway _importGateway;

  @override
  Future<CustomerPriceRuleImportResultDto> handle(
    ConfirmCustomerPriceRuleImportCommand command,
  ) => _importGateway.confirm(
    tenantId: command.tenantId,
    importId: command.importId.trim(),
    expectedVersion: command.expectedVersion,
    businessDate: command.businessDate,
    acknowledgeWarningRows: command.acknowledgeWarningRows,
  );
}
