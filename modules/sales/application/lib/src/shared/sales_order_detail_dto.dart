import 'actor_snapshot_dto.dart';
import 'customer_snapshot_dto.dart';
import 'sales_order_current_line_dto.dart';
import 'sales_order_dto.dart';
import 'sales_order_line_dto.dart';
import 'store_snapshot_dto.dart';

final class SalesOrderDetailDto {
  SalesOrderDetailDto({
    required this.order,
    required this.committedAt,
    required this.store,
    required this.seller,
    required List<SalesOrderLineDto> lines,
    this.customer,
    this.orderNote,
    this.currentReceiptId,
    List<SalesOrderCurrentLineDto> currentLines = const [],
  }) : lines = List.unmodifiable(lines),
       currentLines = List.unmodifiable(currentLines);

  final SalesOrderDto order;
  final DateTime committedAt;
  final StoreSnapshotDto store;
  final ActorSnapshotDto seller;
  final CustomerSnapshotDto? customer;
  final List<SalesOrderLineDto> lines;
  final String? orderNote;
  final String? currentReceiptId;
  final List<SalesOrderCurrentLineDto> currentLines;
}
