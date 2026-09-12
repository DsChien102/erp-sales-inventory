import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_order_payment_summary_dto.dart';
import '../../../return_exchange_order/ports/i_return_exchange_settlement_gateway.dart';
import 'record_sales_payment_command.dart';

@CommandHandlerFor(RecordSalesPaymentCommand)
final class RecordSalesPaymentCommandHandler
    implements ICommandHandler<RecordSalesPaymentCommand, SalesOrderPaymentSummaryDto> {
  RecordSalesPaymentCommandHandler({
    required IReturnExchangeSettlementGateway settlementGateway,
  }) : _settlementGateway = settlementGateway;

  final IReturnExchangeSettlementGateway _settlementGateway;

  @override
  Future<SalesOrderPaymentSummaryDto> handle(RecordSalesPaymentCommand command) =>
      _settlementGateway.recordPayment(command);
}
