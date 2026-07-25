import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_application/application.dart';

@CommandHandlerFor(StartCustomerPriceRuleImportCommand)
final class StartCustomerPriceRuleImportCommandHandler
    implements
        ICommandHandler<
          StartCustomerPriceRuleImportCommand,
          CustomerPriceRuleImportDetailDto
        > {
  const StartCustomerPriceRuleImportCommandHandler({
    required ICustomerPriceRuleImportFilePort filePort,
    required ICustomerPriceRuleImportGateway importGateway,
  }) : _filePort = filePort,
       _importGateway = importGateway;

  final ICustomerPriceRuleImportFilePort _filePort;
  final ICustomerPriceRuleImportGateway _importGateway;

  @override
  Future<CustomerPriceRuleImportDetailDto> handle(
    StartCustomerPriceRuleImportCommand command,
  ) async {
    late final CustomerPriceRuleImportParseResult parseResult;
    try {
      parseResult = _filePort.parse(
        templateVersion: command.templateVersion.trim(),
        originalFileName: command.originalFileName.trim(),
        bytes: command.fileBytes,
      );
    } on Object {
      throw const PricingBlockedException(
        PricingBlockedCodes.systemError,
        message: 'Import file parsing failed.',
      );
    }

    return _importGateway.create(
      tenantId: command.tenantId,
      templateVersion: command.templateVersion.trim(),
      originalFileName: command.originalFileName.trim(),
      importMode: command.importMode,
      parseResult: parseResult,
    );
  }
}
