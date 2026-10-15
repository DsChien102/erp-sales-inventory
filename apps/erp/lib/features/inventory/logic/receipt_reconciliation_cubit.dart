import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../data/goods_receipt_repository.dart';
import '../data/models/receipt_document_model.dart';

enum ReconciliationStatus { loading, ready, empty, permissionDenied }

class ReceiptReconciliationState extends Equatable {
  const ReceiptReconciliationState({
    this.status = ReconciliationStatus.loading,
    this.document,
    this.checkedAt,
    this.isRefreshing = false,
  });

  final ReconciliationStatus status;
  final ReceiptDocumentModel? document;

  /// Thời điểm hỏi lại gần nhất.
  final DateTime? checkedAt;
  final bool isRefreshing;

  bool get isTerminal =>
      document != null &&
      (document!.status == ReceiptStatus.completed ||
          document!.status == ReceiptStatus.executionRejected);

  @override
  List<Object?> get props => [status, document, checkedAt, isRefreshing];
}

/// SCR-013: chỉ hỏi lại kết quả của cùng lần nhận, không tạo thao tác mới.
class ReceiptReconciliationCubit extends Cubit<ReceiptReconciliationState> {
  ReceiptReconciliationCubit({
    required GoodsReceiptRepository repository,
    DateTime Function()? clock,
  }) : _repository = repository,
       _clock = clock ?? DateTime.now,
       super(const ReceiptReconciliationState());

  final GoodsReceiptRepository _repository;
  final DateTime Function() _clock;

  Future<void> check(String id) async {
    final first = state.document == null;
    emit(
      ReceiptReconciliationState(
        status: first ? ReconciliationStatus.loading : ReconciliationStatus.ready,
        document: state.document,
        checkedAt: state.checkedAt,
        isRefreshing: !first,
      ),
    );
    try {
      final doc = await _repository.checkReceiptResult(id);
      if (isClosed) return;
      if (doc == null) {
        emit(const ReceiptReconciliationState(status: ReconciliationStatus.empty));
        return;
      }
      emit(
        ReceiptReconciliationState(
          status: ReconciliationStatus.ready,
          document: doc,
          checkedAt: _clock(),
        ),
      );
    } catch (e) {
      if (isClosed) return;
      if (AppException.from(e).isNoPermission) {
        emit(
          const ReceiptReconciliationState(
            status: ReconciliationStatus.permissionDenied,
          ),
        );
      } else {
        emit(
          ReceiptReconciliationState(
            status: state.document == null
                ? ReconciliationStatus.empty
                : ReconciliationStatus.ready,
            document: state.document,
            checkedAt: state.checkedAt,
          ),
        );
      }
    }
  }
}
