import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/receivable_models.dart';
import '../data/receivable_repository.dart';
import 'receivable_list_state.dart';

/// CN-01: danh sách khách còn nợ. Lọc / tìm gọi lại RPC; thứ tự là của server (BR-10).
class ReceivableListCubit extends Cubit<ReceivableListState> {
  ReceivableListCubit({
    required ReceivableRepository repository,
    this.searchDebounce = const Duration(milliseconds: 300),
  }) : _repository = repository,
       super(const ReceivableListState());

  final ReceivableRepository _repository;
  final Duration searchDebounce;

  Timer? _debounce;
  int _requestId = 0;
  int _moreId = 0;

  /// Tải lại từ đầu, hiện khung chờ (lần đầu / sau lỗi / bấm Thử lại).
  Future<void> load() => _fetch(showLoading: true);

  /// Tải lại giữ nguyên danh sách đang hiện (sau khi thu tiền, đổi lọc / tìm).
  Future<void> refresh() => _fetch(showLoading: false);

  void toggleOverdue() {
    _debounce?.cancel();
    final next = state.filter == ReceivableFilter.all
        ? ReceivableFilter.overdue
        : ReceivableFilter.all;
    emit(state.copyWith(filter: next, nextCursor: () => null));
    unawaited(_fetch(showLoading: false));
  }

  void setQuery(String text) {
    _debounce?.cancel();
    emit(state.copyWith(query: text, nextCursor: () => null));
    _debounce = Timer(searchDebounce, () => unawaited(_fetch(showLoading: false)));
  }

  void clearQuery() {
    _debounce?.cancel();
    emit(state.copyWith(query: '', nextCursor: () => null));
    unawaited(_fetch(showLoading: false));
  }

  Future<void> loadMore() async {
    final cursor = state.nextCursor;
    if (cursor == null || state.loadingMore || state.status != ReceivableListStatus.ready) return;
    final id = ++_moreId;
    emit(state.copyWith(loadingMore: true));
    try {
      final page = await _repository.list(
        filter: state.filter,
        search: state.query,
        cursor: cursor,
      );
      if (id != _moreId || isClosed) return;
      emit(
        state.copyWith(
          items: [...state.items, ...page.items],
          summary: page.summary,
          nextCursor: () => page.nextCursor,
          loadingMore: false,
        ),
      );
    } catch (_) {
      if (id != _moreId || isClosed) return;
      emit(state.copyWith(loadingMore: false));
    }
  }

  Future<void> _fetch({required bool showLoading}) async {
    final id = ++_requestId;
    _moreId++; // trang tải thêm của lọc / tìm cũ về muộn bị bỏ
    if (showLoading) {
      emit(state.copyWith(status: ReceivableListStatus.loading, loadingMore: false));
    }
    try {
      final page = await _repository.list(filter: state.filter, search: state.query);
      if (id != _requestId || isClosed) return;
      emit(
        state.copyWith(
          status: ReceivableListStatus.ready,
          summary: page.summary,
          items: page.items,
          nextCursor: () => page.nextCursor,
          loadingMore: false,
        ),
      );
    } catch (_) {
      if (id != _requestId || isClosed) return;
      emit(state.copyWith(status: ReceivableListStatus.error, loadingMore: false));
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
