import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';
import 'package:erp/features/inventory/logic/reports/stock_card_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StockCardCubit extends Cubit<StockCardState> {
  StockCardCubit(this._repo, this.productId, ReportPeriod period)
      : super(StockCardState(period: period));

  final ReportsRepository _repo;
  final String productId;
  int _request = 0;

  Future<void> load() => _fetch();

  Future<void> setPeriod(ReportPeriod period) {
    emit(state.copyWith(period: period));
    return _fetch();
  }

  /// `null` = "Tất cả lô".
  Future<void> selectLot(String? lotId) {
    emit(
      lotId == null ? state.copyWith(clearLot: true) : state.copyWith(lotId: lotId),
    );
    return _fetch();
  }

  Future<void> _fetch() async {
    final ticket = ++_request;
    emit(state.copyWith(status: ReportStatus.loading, clearMessage: true));
    try {
      final data = await _repo.stockCard(
        productId,
        state.period,
        lotId: state.lotId,
      );
      if (isClosed || ticket != _request) return;
      emit(state.copyWith(status: ReportStatus.ready, data: data));
    } catch (e) {
      if (isClosed || ticket != _request) return;
      final r = classifyReportError(e, fallback: 'Không tải được thẻ kho.');
      emit(state.copyWith(status: r.status, message: r.message));
    }
  }
}
