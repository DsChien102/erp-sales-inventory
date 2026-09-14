import 'package:vet45_shared_application/application.dart';

import '../../../shared/return_exchange_settlement_result_dto.dart';
import '../../../return_exchange_order/ports/i_return_exchange_settlement_gateway.dart';
import 'record_sales_refund_command.dart';

@CommandHandlerFor(RecordSalesRefundCommand)
final class RecordSalesRefundCommandHandler
    implements ICommandHandler<RecordSalesRefundCommand, ReturnExchangeSettlementResultDto> {
  RecordSalesRefundCommandHandler({
    required IReturnExchangeSettlementGateway settlementGateway,
  }) : _settlementGateway = settlementGateway;

  final IReturnExchangeSettlementGateway _settlementGateway;

  @override
  Future<ReturnExchangeSettlementResultDto> handle(
    RecordSalesRefundCommand command,
  ) => _settlementGateway.recordRefund(command);
}
