import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';

enum GrossProfitMode { product, order }

class GrossProfitState extends Equatable {
  const GrossProfitState({
    required this.period,
    this.mode = GrossProfitMode.product,
    this.status = ReportStatus.loading,
    this.byProduct,
    this.byOrder,
    this.message,
  });

  final ReportPeriod period;
  final GrossProfitMode mode;
  final ReportStatus status;
  final GrossProfitByProduct? byProduct;
  final GrossProfitByOrder? byOrder;
  final String? message;

  GrossProfitState copyWith({
    ReportPeriod? period,
    GrossProfitMode? mode,
    ReportStatus? status,
    GrossProfitByProduct? byProduct,
    GrossProfitByOrder? byOrder,
    String? message,
    bool clearMessage = false,
  }) {
    return GrossProfitState(
      period: period ?? this.period,
      mode: mode ?? this.mode,
      status: status ?? this.status,
      byProduct: byProduct ?? this.byProduct,
      byOrder: byOrder ?? this.byOrder,
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [period, mode, status, byProduct, byOrder, message];
}
