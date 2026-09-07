import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_delivery_command_gateway.dart';
import '../../shared/auto_delivery_start_request.dart';
import 'start_auto_delivery_command.dart';
import 'start_auto_delivery_result.dart';

@CommandHandlerFor(StartAutoDeliveryCommand)
final class StartAutoDeliveryCommandHandler
    implements ICommandHandler<StartAutoDeliveryCommand, AutoDeliveryResultDto> {
  StartAutoDeliveryCommandHandler({
    required IDeliveryCommandGateway gateway,
  }) : _gateway = gateway;

  final IDeliveryCommandGateway _gateway;

  @override
  Future<AutoDeliveryResultDto> handle(StartAutoDeliveryCommand command) {
    return _gateway.startAuto(
      AutoDeliveryStartRequest(
        tenantId: command.tenantId,
        electronicInvoiceId: command.electronicInvoiceId,
        triggerId: command.triggerId,
        idempotencyKey: command.idempotencyKey,
      ),
    );
  }
}
