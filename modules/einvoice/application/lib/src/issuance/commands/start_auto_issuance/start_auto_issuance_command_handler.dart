import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_auto_issuance_gateway.dart';
import 'auto_issuance_start_request.dart';
import 'start_auto_issuance_command.dart';
import 'start_auto_issuance_result.dart';

@CommandHandlerFor(StartAutoIssuanceCommand)
final class StartAutoIssuanceCommandHandler
    implements ICommandHandler<StartAutoIssuanceCommand, AutoIssuanceResultDto> {
  StartAutoIssuanceCommandHandler({
    required IAutoIssuanceGateway gateway,
  }) : _gateway = gateway;

  final IAutoIssuanceGateway _gateway;

  @override
  Future<AutoIssuanceResultDto> handle(StartAutoIssuanceCommand command) => _gateway.start(
    AutoIssuanceStartRequest(
      tenantId: command.tenantId,
      salesOrderId: command.salesOrderId,
      triggerKey: command.triggerKey,
      idempotencyKey: command.idempotencyKey,
    ),
  );
}
