import 'package:erp/features/inventory/data/supplier_rebate/supplier_rebate_repository.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/rebate_rules.dart';
import 'package:erp/features/inventory/logic/supplier_rebate/supplier_compare_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SupplierCompareCubit extends Cubit<SupplierCompareState> {
  final SupplierRebateRepository _rebates;
  final String _productId;

  SupplierCompareCubit({
    required SupplierRebateRepository rebates,
    required String productId,
  })  : _rebates = rebates,
        _productId = productId,
        super(const SupplierCompareLoading());

  Future<void> load() async {
    emit(const SupplierCompareLoading());
    try {
      final data = await _rebates.compareSuppliers(_productId);
      if (isClosed) return;
      final cheapestId =
          data.financialMasked ? null : cheapestSupplierId(data.suppliers);
      emit(SupplierCompareLoaded(data, cheapestId));
    } catch (_) {
      if (isClosed) return;
      emit(const SupplierCompareError());
    }
  }
}

