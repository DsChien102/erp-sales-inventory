import 'actor_snapshot_dto.dart';
import 'customer_snapshot_dto.dart';
import 'sales_order_dto.dart';
import 'store_snapshot_dto.dart';

final class SalesOrderResultDto {
  const SalesOrderResultDto({
    required this.order,
    required this.committedAt,
    required this.store,
    required this.seller,
    this.customer,
  });

  final SalesOrderDto order;
  final DateTime committedAt;
  final StoreSnapshotDto store;
  final ActorSnapshotDto seller;
  final CustomerSnapshotDto? customer;
}
