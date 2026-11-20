import 'dart:async';

import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';
import 'package:erp/features/inventory/logic/reports/stock_report_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StockReportCubit extends Cubit<StockReportState> {
  StockReportCubit(this._repo, ReportPeriod period)
      : super(StockReportState(period: period));

  final ReportsRepository _repo;
  Timer? _debounce;
  int _request = 0;

  Future<void> load() => _fetch(showLoading: true);

  Future<void> setPeriod(ReportPeriod period) {
    emit(state.copyWith(period: period));
    return _fetch(showLoading: true);
  }

  /// Gõ tìm: đổi chữ ngay, gọi lại RPC sau 300 ms, giữ danh sách cũ trong lúc chờ.
  void search(String query) {
    _debounce?.cancel();
    emit(state.copyWith(search: query));
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _fetch(showLoading: false),
    );
  }

  Future<void> _fetch({required bool showLoading}) async {
    final ticket = ++_request;
    if (showLoading) {
      emit(state.copyWith(status: ReportStatus.loading, clearMessage: true));
    }
    try {
      final data = await _repo.stockReport(state.period, search: state.search);
      if (isClosed || ticket != _request) return;
      emit(state.copyWith(
        status: ReportStatus.ready,
        data: data,
        clearMessage: true,
      ));
    } catch (e) {
      if (isClosed || ticket != _request) return;
      final r = classifyReportError(
        e,
        fallback: 'Không tải được báo cáo nhập – xuất – tồn.',
      );
      emit(state.copyWith(status: r.status, message: r.message));
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
