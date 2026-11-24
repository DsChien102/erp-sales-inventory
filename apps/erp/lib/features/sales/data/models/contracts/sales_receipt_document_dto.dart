import 'actor_snapshot_dto.dart';
import 'customer_snapshot_dto.dart';
import 'money_dto.dart';
import 'payment_intent_summary_dto.dart';
import 'sales_receipt_line_dto.dart';
import 'sales_receipt_settlement_snapshot_dto.dart';
import 'store_snapshot_dto.dart';

final class SalesReceiptDocumentDto {
  SalesReceiptDocumentDto({
    required this.receiptNumber,
    required this.orderNumber,
    required this.soldAt,
    required this.store,
    required this.seller,
    this.customer,
    required List<SalesReceiptLineDto> lines,
    required this.subtotal,
    required this.discountTotal,
    this.taxTotal,
    this.roundingTotal,
    required this.orderTotal,
    required this.paidTotal,
    required this.outstandingTotal,
    required List<PaymentIntentSummaryDto> payments,
    this.dueAt,
    this.settlementSnapshot,
  }) : lines = List.unmodifiable(lines),
       payments = List.unmodifiable(payments);

  final String receiptNumber;
  final String orderNumber;
  final DateTime soldAt;
  final StoreSnapshotDto store;
  final ActorSnapshotDto seller;
  final CustomerSnapshotDto? customer;
  final List<SalesReceiptLineDto> lines;
  final MoneyDto subtotal;
  final MoneyDto discountTotal;
  final MoneyDto? taxTotal;
  final MoneyDto? roundingTotal;

  /// Original sale total. Not the post-sale current payable.
  final MoneyDto orderTotal;
  final MoneyDto paidTotal;
  final MoneyDto outstandingTotal;
  final List<PaymentIntentSummaryDto> payments;
  final DateTime? dueAt;
  final SalesReceiptSettlementSnapshotDto? settlementSnapshot;
}
