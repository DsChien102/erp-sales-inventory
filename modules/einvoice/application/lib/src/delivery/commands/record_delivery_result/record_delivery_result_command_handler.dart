import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_delivery_command_gateway.dart';
import '../../shared/delivery_result_record.dart';
import 'record_delivery_result_command.dart';
import 'record_delivery_result_result.dart';

@CommandHandlerFor(RecordDeliveryResultCommand)
final class RecordDeliveryResultCommandHandler
    implements ICommandHandler<RecordDeliveryResultCommand, RecordDeliveryResultDto> {
  RecordDeliveryResultCommandHandler({
    required IDeliveryCommandGateway gateway,
  }) : _gateway = gateway;

  final IDeliveryCommandGateway _gateway;

  @override
  Future<RecordDeliveryResultDto> handle(RecordDeliveryResultCommand command) {
    return _gateway.recordResult(
      DeliveryResultRecord(
        tenantId: command.tenantId,
        deliveryId: command.deliveryId,
        retryCount: command.retryCount,
        expectedDeliveryVersion: command.expectedDeliveryVersion,
        evidence: command.evidence,
      ),
    );
  }
}
