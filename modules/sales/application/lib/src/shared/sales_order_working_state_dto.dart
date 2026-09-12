import 'checkout_line_input.dart';
import 'customer_snapshot_dto.dart';
import 'store_snapshot_dto.dart';

final class SalesOrderWorkingStateDto {
  SalesOrderWorkingStateDto({
    required this.store,
    required this.currencyCode,
    required List<CheckoutLineInput> lines,
    this.customer,
  }) : lines = List.unmodifiable(lines);

  final StoreSnapshotDto store;
  final CustomerSnapshotDto? customer;
  final String currencyCode;
  final List<CheckoutLineInput> lines;
}
