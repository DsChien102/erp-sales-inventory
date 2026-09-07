import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_auto_issuance_gateway.dart';
import '../start_auto_issuance/start_auto_issuance_result.dart';
import 'auto_issuance_reevaluation_request.dart';
import 'reevaluate_auto_issuance_command.dart';

@CommandHandlerFor(ReevaluateAutoIssuanceCommand)
final class ReevaluateAutoIssuanceCommandHandler
    implements ICommandHandler<ReevaluateAutoIssuanceCommand, AutoIssuanceResultDto> {
  ReevaluateAutoIssuanceCommandHandler({
    required IAutoIssuanceGateway gateway,
  }) : _gateway = gateway;

  final IAutoIssuanceGateway _gateway;

  @override
  Future<AutoIssuanceResultDto> handle(
    ReevaluateAutoIssuanceCommand command,
  ) => _gateway.reevaluate(
    AutoIssuanceReevaluationRequest(
      tenantId: command.tenantId,
      processId: command.processId,
      sourceEventId: command.sourceEventId,
    ),
  );
}
