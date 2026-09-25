import '../sales_receipt/commands/archive_sales_receipt/archive_sales_receipt_command.dart';
import '../sales_receipt/commands/generate_sales_receipt/generate_sales_receipt_command.dart';
import '../sales_receipt/commands/record_sales_receipt_printed/record_sales_receipt_printed_command.dart';
import '../sales_receipt/commands/record_sales_receipt_shared/record_sales_receipt_shared_command.dart';
import '../sales_receipt/ports/i_sales_receipt_gateway.dart';
import '../sales_receipt/queries/get_sales_order_original_receipt/get_sales_order_original_receipt_query.dart';
import '../sales_receipt/queries/get_sales_receipt/get_sales_receipt_query.dart';
import '../shared/sales_receipt_document_dto.dart';
import '../shared/sales_receipt_dto.dart';

final class FakeSalesReceiptGateway implements ISalesReceiptGateway {
  FakeSalesReceiptGateway({
    required SalesReceiptDto receipt,
    this.generateError,
    this.getError,
    this.originalError,
    this.printedError,
    this.sharedError,
    this.archiveError,
  }) : _receipt = receipt;

  final SalesReceiptDto _receipt;
  final Object? generateError;
  final Object? getError;
  final Object? originalError;
  final Object? printedError;
  final Object? sharedError;
  final Object? archiveError;

  int generateCalls = 0;
  int printedCalls = 0;
  int sharedCalls = 0;
  int archiveCalls = 0;
  int getCalls = 0;
  int getOriginalCalls = 0;

  @override
  Future<SalesReceiptDto> generate(GenerateSalesReceiptCommand command) async {
    generateCalls += 1;
    if (generateError != null) throw generateError!;
    return _receipt;
  }

  @override
  Future<SalesReceiptDto> recordPrinted(RecordSalesReceiptPrintedCommand command) async {
    printedCalls += 1;
    if (printedError != null) throw printedError!;
    return _receipt;
  }

  @override
  Future<SalesReceiptDto> recordShared(RecordSalesReceiptSharedCommand command) async {
    sharedCalls += 1;
    if (sharedError != null) throw sharedError!;
    return _receipt;
  }

  @override
  Future<SalesReceiptDto> archive(ArchiveSalesReceiptCommand command) async {
    archiveCalls += 1;
    if (archiveError != null) throw archiveError!;
    return _receipt;
  }

  @override
  Future<SalesReceiptDto> getReceipt(GetSalesReceiptQuery query) async {
    getCalls += 1;
    if (getError != null) throw getError!;
    return _receipt;
  }

  @override
  Future<SalesReceiptDocumentDto> getOriginalReceipt(GetSalesOrderOriginalReceiptQuery query) async {
    getOriginalCalls += 1;
    if (originalError != null) throw originalError!;
    return _receipt.document;
  }
}
