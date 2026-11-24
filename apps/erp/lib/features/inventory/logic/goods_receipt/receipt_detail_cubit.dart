import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/inventory/data/goods_receipt/goods_receipt_repository.dart';
import 'package:erp/features/inventory/logic/goods_receipt/receipt_detail_state.dart';

class ReceiptDetailCubit extends Cubit<ReceiptDetailState> {
  ReceiptDetailCubit({
    required GoodsReceiptRepository repository,
  })  : _repository = repository,
        super(const ReceiptDetailState());

  final GoodsReceiptRepository _repository;

  Future<void> load(String receiptId) async {
    emit(state.copyWith(status: ReceiptDetailStatus.loading));
    try {
      final detail = await _repository.get(receiptId);
      emit(state.copyWith(
        status: ReceiptDetailStatus.ready,
        receipt: detail,
      ));
    } on AppException catch (e) {
      if (e.code == 'NOT_FOUND' || e.code == 'RECEIPT_NOT_FOUND') {
        emit(state.copyWith(status: ReceiptDetailStatus.notFound));
      } else {
        emit(state.copyWith(status: ReceiptDetailStatus.loadError));
      }
    } catch (_) {
      emit(state.copyWith(status: ReceiptDetailStatus.loadError));
    }
  }
}

