import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class Warehouse extends Entity<String> {
  Warehouse({
    required super.id,
    required this.tenantId,
    required this.displayName,
    required this.status,
    required this.createdAt,
  });

  final String tenantId;
  final String displayName;
  final String status;
  final DateTime createdAt;
}
