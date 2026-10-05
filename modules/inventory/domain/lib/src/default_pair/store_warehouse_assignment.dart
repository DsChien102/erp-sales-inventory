import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class StoreWarehouseAssignment extends Entity<String> {
  StoreWarehouseAssignment({
    required super.id,
    required this.tenantId,
    required this.storeId,
    required this.warehouseId,
    required this.status,
    required this.createdAt,
  });

  final String tenantId;
  final String storeId;
  final String warehouseId;
  final String status;
  final DateTime createdAt;
}
