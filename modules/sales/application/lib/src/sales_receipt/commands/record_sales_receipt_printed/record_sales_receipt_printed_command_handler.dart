import 'package:vet45_shared_application/application.dart';

import '../../../shared/sales_receipt_dto.dart';
import '../../ports/i_sales_receipt_gateway.dart';
import 'record_sales_receipt_printed_command.dart';

@CommandHandlerFor(RecordSalesReceiptPrintedCommand)
final class RecordSalesReceiptPrintedCommandHandler
    implements ICommandHandler<RecordSalesReceiptPrintedCommand, SalesReceiptDto> {
  RecordSalesReceiptPrintedCommandHandler({required ISalesReceiptGateway receiptGateway})
    : _receiptGateway = receiptGateway;

  final ISalesReceiptGateway _receiptGateway;

  @override
  Future<SalesReceiptDto> handle(RecordSalesReceiptPrintedCommand command) =>
      _receiptGateway.recordPrinted(command);
}
