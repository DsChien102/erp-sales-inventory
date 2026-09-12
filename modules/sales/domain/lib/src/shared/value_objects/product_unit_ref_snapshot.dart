import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class ProductUnitRefSnapshot extends ValueObject {
  ProductUnitRefSnapshot({
    required this.unitId,
    required this.unitCode,
    required this.unitName,
  });

  final String unitId;
  final String unitCode;
  final String unitName;

  @override
  List<Object?> get props => [unitId, unitCode, unitName];
}
