import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_models.dart';

sealed class SupplierCompareState {
  const SupplierCompareState();
}

final class SupplierCompareLoading extends SupplierCompareState {
  const SupplierCompareLoading();
}

final class SupplierCompareLoaded extends SupplierCompareState {
  final SupplierCompare data;
  final String? cheapestId;

  const SupplierCompareLoaded(this.data, this.cheapestId);
}

final class SupplierCompareError extends SupplierCompareState {
  const SupplierCompareError();
}

