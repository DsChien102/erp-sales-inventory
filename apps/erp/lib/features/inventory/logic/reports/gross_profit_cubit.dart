import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:erp/features/inventory/logic/reports/gross_profit_state.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class GrossProfitCubit extends Cubit<GrossProfitState> {
  GrossProfitCubit(
    this._repo,
    ReportPeriod period, [
    GrossProfitMode mode = GrossProfitMode.product,
  ]) : super(GrossProfitState(period: period, mode: mode));

  final ReportsRepository _repo;
  int _request = 0;

  Future<void> load() => _fetch();

  Future<void> setPeriod(ReportPeriod period) {
    emit(state.copyWith(period: period));
    return _fetch();
  }

  Future<void> setMode(GrossProfitMode mode) {
    if (mode == state.mode) return Future.value();
    emit(state.copyWith(mode: mode));
    return _fetch();
  }

  Future<void> _fetch() async {
    final ticket = ++_request;
    final mode = state.mode;
    emit(state.copyWith(status: ReportStatus.loading, clearMessage: true));
    try {
      if (mode == GrossProfitMode.product) {
        final data = await _repo.grossProfitByProduct(state.period);
        if (isClosed || ticket != _request) return;
        emit(state.copyWith(status: ReportStatus.ready, byProduct: data));
      } else {
        final data = await _repo.grossProfitByOrder(state.period);
        if (isClosed || ticket != _request) return;
        emit(state.copyWith(status: ReportStatus.ready, byOrder: data));
      }
    } catch (e) {
      if (isClosed || ticket != _request) return;
      final r = classifyReportError(e, fallback: 'Không tải được báo cáo lãi gộp.');
      emit(state.copyWith(status: r.status, message: r.message));
    }
  }
}
