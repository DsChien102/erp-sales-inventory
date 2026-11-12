import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';
import 'package:erp/features/inventory/logic/reports/supplier_purchase_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SupplierPurchaseCubit extends Cubit<SupplierPurchaseState> {
  SupplierPurchaseCubit(this._repo, ReportPeriod period)
      : super(SupplierPurchaseState(period: period));

  final ReportsRepository _repo;
  int _request = 0;

  Future<void> load() => _fetch();

  Future<void> setPeriod(ReportPeriod period) {
    emit(state.copyWith(period: period));
    return _fetch();
  }

  Future<void> _fetch() async {
    final ticket = ++_request;
    emit(state.copyWith(status: ReportStatus.loading, clearMessage: true));
    try {
      final data = await _repo.supplierPurchases(state.period);
      if (isClosed || ticket != _request) return;
      emit(state.copyWith(status: ReportStatus.ready, data: data));
    } catch (e) {
      if (isClosed || ticket != _request) return;
      final r = classifyReportError(
        e,
        fallback: 'Không tải được báo cáo nhập hàng theo NCC.',
      );
      emit(state.copyWith(status: r.status, message: r.message));
    }
  }
}
