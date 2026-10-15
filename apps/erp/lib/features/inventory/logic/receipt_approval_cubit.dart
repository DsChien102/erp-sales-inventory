import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../data/goods_receipt_repository.dart';
import '../data/models/receipt_actor.dart';
import 'receipt_approval_state.dart';
import 'receipt_rules.dart';

class ReceiptApprovalCubit extends Cubit<ReceiptApprovalState> {
  ReceiptApprovalCubit({
    required GoodsReceiptRepository repository,
    required ReceiptActorLoader actorLoader,
  })  : _repository = repository,
        _actorLoader = actorLoader,
        super(const ReceiptApprovalInitial());

  final GoodsReceiptRepository _repository;
  final ReceiptActorLoader _actorLoader;

  Future<void> load(String id) async {
    emit(const ReceiptApprovalLoading());
    try {
      final actor = await _actorLoader();
      final doc = await _repository.getReceiptById(id);
      if (doc == null) {
        emit(const ReceiptApprovalNotFound());
        return;
      }
      emit(ReceiptApprovalLoaded(document: doc, actor: actor));
    } catch (e) {
      final error = AppException.from(e);
      emit(
        error.isNoPermission
            ? const ReceiptApprovalPermissionDenied()
            : ReceiptApprovalError(error.userMessage(receiptErrorMessages)),
      );
    }
  }

  Future<void> approve() async {
    final current = state;
    if (current is! ReceiptApprovalLoaded) return;

    emit(current.copyWith(isProcessing: true, clearActionError: true));
    try {
      final updated = await _repository.approveReceipt(
        current.document.id,
        approver: current.actor,
      );
      emit(ReceiptApprovalSuccess(updated));
    } catch (e) {
      await _handleDecisionError(current, e);
    }
  }

  Future<void> reject({required String reason}) async {
    final current = state;
    if (current is! ReceiptApprovalLoaded) return;

    emit(current.copyWith(isProcessing: true, clearActionError: true));
    try {
      final updated = await _repository.rejectReceipt(
        current.document.id,
        approver: current.actor,
        reason: reason,
      );
      emit(ReceiptApprovalSuccess(updated));
    } catch (e) {
      await _handleDecisionError(current, e);
    }
  }

  Future<void> _handleDecisionError(
    ReceiptApprovalLoaded current,
    Object e,
  ) async {
    final error = AppException.from(e);
    if (error.code == 'APPROVAL_ALREADY_DECIDED') {
      await load(current.document.id); // hiện banner "Yêu cầu đã được xử lý", ẩn footer
      return;
    }
    emit(current.copyWith(
      isProcessing: false,
      actionError: error.userMessage(receiptErrorMessages),
    ));
  }
}
