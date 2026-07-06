import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class StorePriceRule extends ValueObject {
  const StorePriceRule({
    required this.id,
    required this.tenantId,
    required this.name,
    required this.ratio,
  });

  final String id;
  final String tenantId;
  final String name;
  final double ratio;

  @override
  List<Object?> get props => [id, tenantId, name, ratio];
}
