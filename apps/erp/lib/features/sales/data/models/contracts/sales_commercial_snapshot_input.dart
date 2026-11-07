import 'actor_snapshot_dto.dart';
import 'customer_snapshot_dto.dart';
import 'sales_receipt_line_dto.dart';
import 'store_snapshot_dto.dart';

final class SalesCommercialSnapshotInput {
  SalesCommercialSnapshotInput({
    required this.store,
    required this.seller,
    this.customer,
    required List<SalesReceiptLineDto> lines,
  }) : lines = List.unmodifiable(lines);

  final StoreSnapshotDto store;
  final ActorSnapshotDto seller;
  final CustomerSnapshotDto? customer;
  final List<SalesReceiptLineDto> lines;
}
