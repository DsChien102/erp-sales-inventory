import 'package:vet45_sales_application/application.dart';

enum SalesReturnExchangeResultKind { confirmed, processing, completed }

final class SalesReturnExchangeResult {
  const SalesReturnExchangeResult({
    required this.kind,
    required this.returnExchangeId,
    required this.salesOrderId,
    required this.version,
    required this.status,
  });

  final SalesReturnExchangeResultKind kind;
  final String returnExchangeId;
  final String salesOrderId;
  final int version;
  final ReturnExchangeStatus status;
}
