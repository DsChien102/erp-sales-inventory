import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_issuance_reconciliation_gateway.dart';
import 'recover_internal_finalization_command.dart';
import 'recover_internal_finalization_result.dart';

@CommandHandlerFor(RecoverInternalFinalizationCommand)
final class RecoverInternalFinalizationCommandHandler
    implements
        ICommandHandler<RecoverInternalFinalizationCommand, RecoverInternalFinalizationResultDto> {
  RecoverInternalFinalizationCommandHandler({
    required IIssuanceReconciliationGateway gateway,
  }) : _gateway = gateway;

  final IIssuanceReconciliationGateway _gateway;

  @override
  Future<RecoverInternalFinalizationResultDto> handle(
    RecoverInternalFinalizationCommand command,
  ) {
    return _gateway.recoverFinalization(
      tenantId: command.tenantId,
      attemptId: command.attemptId,
    );
  }
}
