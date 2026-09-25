import '../../shared/sales_receipt_document_dto.dart';
import '../../shared/sales_receipt_dto.dart';
import '../commands/archive_sales_receipt/archive_sales_receipt_command.dart';
import '../commands/generate_sales_receipt/generate_sales_receipt_command.dart';
import '../commands/record_sales_receipt_printed/record_sales_receipt_printed_command.dart';
import '../commands/record_sales_receipt_shared/record_sales_receipt_shared_command.dart';
import '../queries/get_sales_order_original_receipt/get_sales_order_original_receipt_query.dart';
import '../queries/get_sales_receipt/get_sales_receipt_query.dart';

abstract interface class ISalesReceiptGateway {
  Future<SalesReceiptDto> generate(GenerateSalesReceiptCommand command);

  Future<SalesReceiptDto> recordPrinted(RecordSalesReceiptPrintedCommand command);

  Future<SalesReceiptDto> recordShared(RecordSalesReceiptSharedCommand command);

  Future<SalesReceiptDto> archive(ArchiveSalesReceiptCommand command);

  Future<SalesReceiptDto> getReceipt(GetSalesReceiptQuery query);

  Future<SalesReceiptDocumentDto> getOriginalReceipt(GetSalesOrderOriginalReceiptQuery query);
}
