import 'package:vet45_shared_application/application.dart';

import 'upsert_legal_profile_result_dto.dart';
import '../../../ports/i_tenant_profile_command_gateway.dart';
import 'upsert_legal_profile_command.dart';

@CommandHandlerFor(UpsertLegalProfileCommand)
final class UpsertLegalProfileCommandHandler
    implements
        ICommandHandler<UpsertLegalProfileCommand, UpsertLegalProfileResultDto> {
  UpsertLegalProfileCommandHandler({
    required ITenantProfileCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final ITenantProfileCommandGateway _commandGateway;

  @override
  Future<UpsertLegalProfileResultDto> handle(
    UpsertLegalProfileCommand command,
  ) {
    return _commandGateway.upsertLegalProfile(
      tenantId: command.tenantId,
      legalEntityType: command.legalEntityType,
      legalName: command.legalName,
      taxCode: command.taxCode,
      registeredAddressText: command.registeredAddressText,
      provinceCode: command.provinceCode,
      communeCode: command.communeCode,
      expectedVersion: command.expectedVersion,
      allowDuplicateTaxCode: command.allowDuplicateTaxCode,
    );
  }
}
