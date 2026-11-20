import 'package:erp/features/inventory/data/reports/reports_repository.dart';
import 'package:erp/features/inventory/logic/reports/movement_detail_state.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MovementDetailCubit extends Cubit<MovementDetailState> {
  MovementDetailCubit(this._repo, this.movementId)
      : super(const MovementDetailState());

  final ReportsRepository _repo;
  final String movementId;

  Future<void> load() async {
    emit(const MovementDetailState());
    try {
      final data = await _repo.movementDetail(movementId);
      if (isClosed) return;
      emit(MovementDetailState(status: ReportStatus.ready, data: data));
    } catch (e) {
      if (isClosed) return;
      final r = classifyReportError(
        e,
        fallback: 'Không tải được chi tiết biến động.',
      );
      emit(MovementDetailState(status: r.status, message: r.message));
    }
  }
}
