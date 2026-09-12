import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_order_cancellation_result_dto.dart';
import '../../ports/i_sales_order_cancellation_gateway.dart';
import 'confirm_sales_order_cancellation_command.dart';

@CommandHandlerFor(ConfirmSalesOrderCancellationCommand)
final class ConfirmSalesOrderCancellationCommandHandler
    implements
        ICommandHandler<ConfirmSalesOrderCancellationCommand, SalesOrderCancellationResultDto> {
  ConfirmSalesOrderCancellationCommandHandler({
    required ISalesOrderCancellationGateway cancellationGateway,
  }) : _gateway = cancellationGateway;

  final ISalesOrderCancellationGateway _gateway;

  @override
  Future<SalesOrderCancellationResultDto> handle(
    ConfirmSalesOrderCancellationCommand command,
  ) => _gateway.confirm(command);
}
