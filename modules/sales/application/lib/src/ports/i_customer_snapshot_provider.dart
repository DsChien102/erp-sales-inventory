import '../shared/customer_snapshot_dto.dart';

abstract interface class ICustomerSnapshotProvider {
  Future<CustomerSnapshotDto?> getCustomerSnapshot({
    required String tenantId,
    required String customerId,
  });
}
