import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/receivable_repository.dart';
import 'customer_receivable_state.dart';

/// CN-02: công nợ một khách. Chi tiết và lịch sử tải song song, lỗi độc lập (FR-06).
class CustomerReceivableCubit extends Cubit<CustomerReceivableState> {
  CustomerReceivableCubit({required ReceivableRepository repository, required this.customerId})
    : _repository = repository,
      super(const CustomerReceivableState());

  final ReceivableRepository _repository;
  final String customerId;

  int _detailId = 0;
  int _historyId = 0;

  /// Lần đầu / Thử lại: hiện khung chờ.
  Future<void> load() => _loadAll(showLoading: true);

  /// Sau khi thu / `Tải lại`: giữ nội dung cũ đến khi có số mới, lịch sử cũ bị xoá.
  Future<void> reload() => _loadAll(showLoading: false);

  Future<void> retryHistory() => _loadHistory(showLoading: true);

  Future<void> loadMoreHistory() async {
    final cursor = state.historyCursor;
    if (cursor == null || state.historyLoadingMore) return;
    final id = ++_historyId;
    emit(state.copyWith(historyLoadingMore: true));
    try {
      final page = await _repository.history(customerId, cursor: cursor);
      if (id != _historyId || isClosed) return;
      emit(
        state.copyWith(
          history: [...state.history, ...page.items],
          historyCursor: () => page.nextCursor,
          historyLoadingMore: false,
        ),
      );
    } catch (_) {
      if (id != _historyId || isClosed) return;
      emit(state.copyWith(historyLoadingMore: false));
    }
  }

  Future<void> _loadAll({required bool showLoading}) => Future.wait([
    _loadDetail(showLoading: showLoading),
    _loadHistory(showLoading: showLoading, clear: true),
  ]);

  Future<void> _loadDetail({required bool showLoading}) async {
    final id = ++_detailId;
    if (showLoading || state.detail == null) {
      emit(state.copyWith(detailStatus: LoadStatus.loading));
    }
    try {
      final detail = await _repository.getCustomer(customerId);
      if (id != _detailId || isClosed) return;
      emit(state.copyWith(detailStatus: LoadStatus.ready, detail: detail));
    } catch (_) {
      if (id != _detailId || isClosed) return;
      emit(state.copyWith(detailStatus: LoadStatus.error));
    }
  }

  Future<void> _loadHistory({required bool showLoading, bool clear = false}) async {
    final id = ++_historyId;
    if (showLoading) {
      emit(state.copyWith(historyStatus: LoadStatus.loading, historyLoadingMore: false));
    }
    try {
      final page = await _repository.history(customerId);
      if (id != _historyId || isClosed) return;
      emit(
        state.copyWith(
          historyStatus: LoadStatus.ready,
          history: page.items,
          historyCursor: () => page.nextCursor,
          historyLoadingMore: false,
        ),
      );
    } catch (_) {
      if (id != _historyId || isClosed) return;
      emit(
        state.copyWith(
          historyStatus: LoadStatus.error,
          history: clear ? const [] : null,
          historyLoadingMore: false,
        ),
      );
    }
  }
}
