import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_list_state.dart';

class ReceiptListCubit extends Cubit<ReceiptListState> {
  ReceiptListCubit({
    required GoodsReceiptRepository repository,
    String? initialSupplierId,
  })  : _repository = repository,
        super(ReceiptListState(supplierId: initialSupplierId));

  final GoodsReceiptRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: ReceiptListStatus.loading));
    try {
      final rows = await _repository.list(supplierId: state.supplierId);
      final opts = await _repository.formOptions();

      emit(state.copyWith(
        status: rows.isEmpty ? ReceiptListStatus.empty : ReceiptListStatus.ready,
        all: rows,
        suppliers: opts.suppliers,
      ));
    } catch (_) {
      emit(state.copyWith(status: ReceiptListStatus.loadError));
    }
  }

  Future<void> refresh() => load();

  Future<void> setSupplier(String? id) async {
    final newId = (id == null || id.isEmpty) ? null : id;
    if (newId == state.supplierId) return;

    if (newId == null) {
      emit(state.copyWith(clearSupplier: true));
    } else {
      emit(state.copyWith(supplierId: newId));
    }
    await load();
  }

  void setQuery(String query) {
    emit(state.copyWith(query: query));
  }
}
