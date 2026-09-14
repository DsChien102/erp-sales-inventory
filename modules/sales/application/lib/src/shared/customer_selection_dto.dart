import 'customer_snapshot_dto.dart';

final class CustomerSelectionDto {
  const CustomerSelectionDto({
    required this.customer,
    required this.isWalkIn,
  });

  final CustomerSnapshotDto? customer;
  final bool isWalkIn;
}
