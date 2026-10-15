import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../data/goods_receipt_repository.dart';

enum ReceiptEntryStatus { loading, ready, permissionDenied, conflict }

class ReceiptEntryState extends Equatable {
  const ReceiptEntryState({
    this.status = ReceiptEntryStatus.loading,
    this.warehouseLocked = false,
  });

  final ReceiptEntryStatus status;
  final bool warehouseLocked;

  @override
  List<Object?> get props => [status, warehouseLocked];
}

/// SCR-006: đọc quyền / khoá kho trước khi cho chọn cách nhận.
class ReceiptEntryCubit extends Cubit<ReceiptEntryState> {
  ReceiptEntryCubit({required GoodsReceiptRepository repository})
    : _repository = repository,
      super(const ReceiptEntryState());

  final GoodsReceiptRepository _repository;

  Future<void> load() async {
    emit(const ReceiptEntryState());
    try {
      final capability = await _repository.getCapability();
      emit(
        ReceiptEntryState(
          status: ReceiptEntryStatus.ready,
          warehouseLocked: capability.warehouseLocked,
        ),
      );
    } catch (e) {
      final error = AppException.from(e);
      emit(
        ReceiptEntryState(
          status: error.isNoPermission
              ? ReceiptEntryStatus.permissionDenied
              : error.isStateChanged
              ? ReceiptEntryStatus.conflict
              : ReceiptEntryStatus.ready,
        ),
      );
    }
  }
}
