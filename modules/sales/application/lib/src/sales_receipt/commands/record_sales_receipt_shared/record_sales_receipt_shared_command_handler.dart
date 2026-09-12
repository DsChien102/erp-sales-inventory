import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_receipt_dto.dart';
import '../../ports/i_sales_receipt_gateway.dart';
import 'record_sales_receipt_shared_command.dart';

@CommandHandlerFor(RecordSalesReceiptSharedCommand)
final class RecordSalesReceiptSharedCommandHandler
    implements ICommandHandler<RecordSalesReceiptSharedCommand, SalesReceiptDto> {
  RecordSalesReceiptSharedCommandHandler({required ISalesReceiptGateway receiptGateway})
    : _receiptGateway = receiptGateway;

  final ISalesReceiptGateway _receiptGateway;

  @override
  Future<SalesReceiptDto> handle(RecordSalesReceiptSharedCommand command) =>
      _receiptGateway.recordShared(command);
}
