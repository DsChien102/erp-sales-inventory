import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_issuance_reconciliation_gateway.dart';
import '../../shared/reconciliation_case_dto.dart';
import 'resolve_reconciliation_case_command.dart';

@CommandHandlerFor(ResolveReconciliationCaseCommand)
final class ResolveReconciliationCaseCommandHandler
    implements ICommandHandler<ResolveReconciliationCaseCommand, ReconciliationCaseDto> {
  ResolveReconciliationCaseCommandHandler({
    required IIssuanceReconciliationGateway gateway,
  }) : _gateway = gateway;

  final IIssuanceReconciliationGateway _gateway;

  @override
  Future<ReconciliationCaseDto> handle(
    ResolveReconciliationCaseCommand command,
  ) {
    return _gateway.resolveReconciliationCase(
      tenantId: command.tenantId,
      caseId: command.caseId,
      outcome: command.outcome,
      evidence: command.evidence,
    );
  }
}
