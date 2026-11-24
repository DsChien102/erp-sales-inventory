import 'package:equatable/equatable.dart';
import 'package:erp/features/inventory/data/reports/reports_models.dart';
import 'package:erp/features/inventory/logic/reports/report_period.dart';
import 'package:erp/features/inventory/logic/reports/report_status.dart';

class StockCardState extends Equatable {
  const StockCardState({
    required this.period,
    this.status = ReportStatus.loading,
    this.data,
    this.lotId,
    this.message,
  });

  final ReportPeriod period;
  final ReportStatus status;
  final StockCard? data;

  /// `null` = "Tất cả lô".
  final String? lotId;
  final String? message;

  StockCardState copyWith({
    ReportPeriod? period,
    ReportStatus? status,
    StockCard? data,
    String? lotId,
    bool clearLot = false,
    String? message,
    bool clearMessage = false,
  }) {
    return StockCardState(
      period: period ?? this.period,
      status: status ?? this.status,
      data: data ?? this.data,
      lotId: clearLot ? null : (lotId ?? this.lotId),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  List<Object?> get props => [period, status, data, lotId, message];
}
