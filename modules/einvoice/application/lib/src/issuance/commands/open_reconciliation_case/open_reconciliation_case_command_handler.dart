import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_issuance_reconciliation_gateway.dart';
import '../../shared/reconciliation_case_dto.dart';
import 'open_reconciliation_case_command.dart';

@CommandHandlerFor(OpenReconciliationCaseCommand)
final class OpenReconciliationCaseCommandHandler
    implements ICommandHandler<OpenReconciliationCaseCommand, ReconciliationCaseDto> {
  OpenReconciliationCaseCommandHandler({
    required IIssuanceReconciliationGateway gateway,
  }) : _gateway = gateway;

  final IIssuanceReconciliationGateway _gateway;

  @override
  Future<ReconciliationCaseDto> handle(
    OpenReconciliationCaseCommand command,
  ) {
    return _gateway.openReconciliationCase(
      tenantId: command.tenantId,
      attemptId: command.attemptId,
      reason: command.reason,
    );
  }
}
