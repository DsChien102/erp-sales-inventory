import 'package:vet45_shared_application/application.dart';

import '../../ports/i_sales_order_draft_gateway.dart';
import '../../../shared/sales_order_draft_dto.dart';
import 'cancel_sales_order_draft_command.dart';

@CommandHandlerFor(CancelSalesOrderDraftCommand)
final class CancelSalesOrderDraftCommandHandler
    implements ICommandHandler<CancelSalesOrderDraftCommand, SalesOrderDraftDto> {
  CancelSalesOrderDraftCommandHandler({required ISalesOrderDraftGateway gateway})
    : _gateway = gateway;

  final ISalesOrderDraftGateway _gateway;

  @override
  Future<SalesOrderDraftDto> handle(CancelSalesOrderDraftCommand command) {
    return _gateway.cancel(command);
  }
}
