import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../data/goods_receipt_repository.dart';
import '../data/models/receipt_document_model.dart';

sealed class ReceiptResultState extends Equatable {
  const ReceiptResultState();

  @override
  List<Object?> get props => [];
}

class ReceiptResultLoading extends ReceiptResultState {
  const ReceiptResultLoading();
}

class ReceiptResultPermissionDenied extends ReceiptResultState {
  const ReceiptResultPermissionDenied();
}

class ReceiptResultNotFound extends ReceiptResultState {
  const ReceiptResultNotFound();
}

class ReceiptResultLoaded extends ReceiptResultState {
  const ReceiptResultLoaded(this.document);

  final ReceiptDocumentModel document;

  @override
  List<Object?> get props => [document];
}

class ReceiptResultCubit extends Cubit<ReceiptResultState> {
  ReceiptResultCubit({
    required GoodsReceiptRepository repository,
    this.pollInterval = const Duration(seconds: 2),
  }) : _repository = repository,
       super(const ReceiptResultLoading());

  final GoodsReceiptRepository _repository;
  final Duration pollInterval;
  Timer? _poll;

  Future<void> load(String id) async {
    emit(const ReceiptResultLoading());
    try {
      final doc = await _repository.getReceiptById(id);
      if (isClosed) return;
      if (doc == null) {
        emit(const ReceiptResultNotFound());
        return;
      }
      emit(ReceiptResultLoaded(doc));
      if (doc.status == ReceiptStatus.processing) _startPolling(id);
    } catch (e) {
      if (isClosed) return;
      emit(
        AppException.from(e).isNoPermission
            ? const ReceiptResultPermissionDenied()
            : const ReceiptResultNotFound(),
      );
    }
  }

  void _startPolling(String id) {
    _poll?.cancel();
    _poll = Timer.periodic(pollInterval, (_) async {
      try {
        final doc = await _repository.checkReceiptResult(id);
        if (isClosed || doc == null) return;
        if (doc.status != ReceiptStatus.processing) {
          _poll?.cancel();
          emit(ReceiptResultLoaded(doc));
        }
      } catch (_) {
        // Lần hỏi tiếp theo sẽ thử lại; không đổi màn hình.
      }
    });
  }

  @override
  Future<void> close() {
    _poll?.cancel();
    return super.close();
  }
}
