import 'sales_contract_enums.dart';
import 'sales_receipt_document_dto.dart';

final class SalesReceiptDto {
  const SalesReceiptDto({
    required this.receiptId,
    required this.salesOrderId,
    required this.version,
    required this.status,
    required this.generatedAt,
    required this.document,
  });

  final String receiptId;
  final String salesOrderId;
  final int version;
  final SalesReceiptStatus status;
  final DateTime generatedAt;
  final SalesReceiptDocumentDto document;
}
