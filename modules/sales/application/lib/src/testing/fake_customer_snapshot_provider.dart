import '../ports/i_customer_snapshot_provider.dart';
import '../shared/customer_snapshot_dto.dart';

final class FakeCustomerSnapshotProvider implements ICustomerSnapshotProvider {
  const FakeCustomerSnapshotProvider({this.snapshot});

  final CustomerSnapshotDto? snapshot;

  @override
  Future<CustomerSnapshotDto?> getCustomerSnapshot({
    required String tenantId,
    required String customerId,
  }) async => snapshot;
}
